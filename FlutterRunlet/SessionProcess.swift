import Darwin
import Foundation

struct SessionCommand: Codable, Equatable, Sendable {
    let executable: String
    let arguments: [String]
    let directory: String
    let environment: [String: String]
}

enum SessionExit: Codable, Equatable, Sendable {
    case exited(Int32)
    case signaled(Int32)
    case launchFailed(Int32)
    case unconfirmed

    var detail: LocalizedStringResource {
        switch self {
        case .exited(let code): "Exit code \(String(code))"
        case .signaled(let signal): "Signal \(String(signal))"
        case .launchFailed(let code): "Process launch failed (\(String(code)))"
        case .unconfirmed: "Could not confirm that the managed process exited"
        }
    }

    init(waitStatus status: Int32) {
        let signal = status & 0x7f
        self = signal == 0 ? .exited((status >> 8) & 0xff) : .signaled(signal)
    }
}

struct SessionResult: Sendable {
    let exit: SessionExit
    let stdout: String
    let stderr: String
}

struct SessionIssue: Error, LocalizedError, Equatable, Sendable {
    let resource: LocalizedStringResource

    init(_ message: String) { resource = .verbatim(message) }
    init(localized resource: LocalizedStringResource) { self.resource = resource }

    var errorDescription: String? { String(localized: resource) }
}

extension LocalizedStringResource {
    static func verbatim(_ value: String) -> Self {
        .init("verbatim", defaultValue: "\(value)")
    }

    static func appIssue(_ error: any Error) -> Self {
        (error as? SessionIssue)?.resource ?? .verbatim(error.localizedDescription)
    }
}

final class ProjectLease: Sendable {
    let descriptor: Int32
    let project: URL
    let identity: String
    private let projectDescriptor: Int32

    init(project: URL, lockDirectory: URL) throws {
        let root = open(project.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard root >= 0 else { throw SessionIssue(localized: "Could not open the project directory") }
        var info = stat()
        guard fstat(root, &info) == 0 else {
            close(root)
            throw SessionIssue(localized: "Could not verify the project directory identity")
        }
        let identity = "\(info.st_dev)-\(info.st_ino)"
        let path = lockDirectory.appending(path: "\(identity).lock").path
        let fd = open(path, O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else {
            close(root)
            throw SessionIssue(localized: "Could not open the project lock")
        }
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0, info.st_nlink == 1,
              flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            close(fd)
            close(root)
            throw SessionIssue(localized: "The project is in use by another session or the project lock is unavailable")
        }
        self.project = project
        self.identity = identity
        projectDescriptor = root
        descriptor = fd
        try verifyProject()
    }

    func verifyProject() throws {
        var info = stat()
        guard lstat(project.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR,
              "\(info.st_dev)-\(info.st_ino)" == identity else {
            throw SessionIssue(localized: "The project directory moved or changed identity")
        }
    }

    func openWorkingDirectory(_ path: String) throws -> Int32 {
        try verifyProject()
        let directory = path == project.path
            ? fcntl(projectDescriptor, F_DUPFD_CLOEXEC, STDERR_FILENO + 1)
            : open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard directory >= 0 else { throw SessionIssue(localized: "The task working directory is unavailable") }
        do {
            try verifyProject()
            return directory
        } catch {
            close(directory)
            throw error
        }
    }

    deinit {
        close(projectDescriptor)
        close(descriptor)
    }
}

enum SessionSpawn {
    static func spawn(
        _ executable: String, arguments: [String], environment: [String: String],
        flags: Int16, configure: (inout posix_spawn_file_actions_t?) -> Int32
    ) -> Result<pid_t, SpawnError> {
        var actions: posix_spawn_file_actions_t?
        var attrs: posix_spawnattr_t?
        let actionResult = posix_spawn_file_actions_init(&actions)
        guard actionResult == 0 else { return .failure(.init(code: actionResult)) }
        defer { posix_spawn_file_actions_destroy(&actions) }
        let attrResult = posix_spawnattr_init(&attrs)
        guard attrResult == 0 else { return .failure(.init(code: attrResult)) }
        defer { posix_spawnattr_destroy(&attrs) }

        let configured = configure(&actions)
        guard configured == 0 else { return .failure(.init(code: configured)) }
        let setup = posix_spawnattr_setflags(&attrs, flags)
        guard setup == 0 else { return .failure(.init(code: setup)) }
        if flags & Int16(POSIX_SPAWN_SETPGROUP) != 0 {
            let group = posix_spawnattr_setpgroup(&attrs, 0)
            guard group == 0 else { return .failure(.init(code: group)) }
        }

        let argv = ([executable] + arguments).map { strdup($0) }
        let envp = environment.map { strdup("\($0.key)=\($0.value)") }
        defer {
            argv.forEach { free($0) }
            envp.forEach { free($0) }
        }
        guard !argv.contains(nil), !envp.contains(nil) else { return .failure(.init(code: ENOMEM)) }
        var pid: pid_t = 0
        let status = posix_spawn(&pid, executable, &actions, &attrs, argv + [nil], envp + [nil])
        return status == 0 ? .success(pid) : .failure(.init(code: status))
    }

    struct SpawnError: Error {
        let code: Int32
    }
}

struct SessionProcessRunner: Sendable {
    let worker: URL
    var isAvailable: Bool { FileManager.default.isExecutableFile(atPath: worker.path) }

    static var bundled: Self {
        Self(worker: Bundle.main.bundleURL.appending(path: "Contents/Helpers/FlutterRunletSessionWorker"))
    }

    @MainActor
    func start(_ command: SessionCommand, lease: ProjectLease,
               output receiveOutput: SessionProcess.Output? = nil,
               outputGeneration: @escaping @Sendable () -> UInt64 = { 0 },
               machineProtocol: Bool = false,
               childStarted: SessionProcess.Started? = nil) throws -> SessionProcess {
        let payload = try JSONEncoder().encode(command)
        let directoryFD = try lease.openWorkingDirectory(command.directory)
        defer { close(directoryFD) }
        let control = Pipe()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        let report = Pipe()
        let machineInput = machineProtocol ? Pipe() : nil
        let machineReader = machineInput?.fileHandleForReading
        let machineWriter = machineInput?.fileHandleForWriting
        let inputFD = input.fileHandleForReading.fileDescriptor
        let reportFD = report.fileHandleForWriting.fileDescriptor
        let handle = input.fileHandleForWriting
        guard fcntl(handle.fileDescriptor, F_SETNOSIGPIPE, 1) == 0 else {
            throw SessionIssue(localized: "Could not configure the supervisor process pipe")
        }
        if let machineWriter {
            let fd = machineWriter.fileDescriptor
            guard fcntl(fd, F_SETNOSIGPIPE, 1) == 0, fcntl(fd, F_SETFL, O_NONBLOCK) == 0 else {
                throw SessionIssue(localized: "Could not configure the Flutter command pipe")
            }
        }
        let machineFD = machineReader.map { [$0.fileDescriptor] } ?? []
        let inherited = [lease.descriptor, inputFD, reportFD, directoryFD] + machineFD
        let result = SessionSpawn.spawn(
            worker.path,
            arguments: inherited.map(String.init),
            environment: [:], flags: Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)
        ) { actions in
            for (source, target) in [
                (control.fileHandleForReading.fileDescriptor, STDIN_FILENO),
                (output.fileHandleForWriting.fileDescriptor, STDOUT_FILENO),
                (errors.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
            ] {
                let code = posix_spawn_file_actions_adddup2(&actions, source, target)
                if code != 0 { return code }
            }
            for fd in inherited {
                let code = posix_spawn_file_actions_addinherit_np(&actions, fd)
                if code != 0 { return code }
            }
            return 0
        }
        let pid = try result.get()
        try? machineReader?.close()
        for handle in [control.fileHandleForReading, input.fileHandleForReading,
                       output.fileHandleForWriting, errors.fileHandleForWriting, report.fileHandleForWriting] {
            try? handle.close()
        }
        DispatchQueue.global(qos: .utility).async {
            defer { try? handle.close() }
            try? handle.write(contentsOf: payload)
        }

        return SessionProcess(pid: pid, control: control.fileHandleForWriting,
                              stdout: output.fileHandleForReading, stderr: errors.fileHandleForReading,
                              report: report.fileHandleForReading,
                              machineInput: machineWriter, output: receiveOutput, outputGeneration: outputGeneration,
                              childStarted: childStarted)
    }
}

@MainActor
final class SessionProcess {
    typealias Output = @MainActor @Sendable (Data, Bool, UInt64) -> Void
    typealias Started = @MainActor @Sendable (UInt64) -> Void

    private let control: FileHandle
    private var machineInput: FileHandle?
    private let result: Task<SessionResult, Never>
    let pid: pid_t

    init(pid: pid_t, control: FileHandle, stdout: FileHandle, stderr: FileHandle, report: FileHandle,
         machineInput: FileHandle?, output: Output?, outputGeneration: @escaping @Sendable () -> UInt64,
         childStarted: Started?) {
        self.pid = pid
        self.control = control
        self.machineInput = machineInput
        result = Task.detached {
            // Wait for the private start receipt before tagging any output with a log generation.
            // The worker reports as soon as spawn returns, independently of stdout/stderr.
            let start = await Self.readStartReport(report)
            if let time = start?.time { await childStarted?(time) }
            async let out = Self.drainOutput(stdout, isError: false, output: output, generation: outputGeneration)
            async let err = Self.drainOutput(stderr, isError: true, output: output, generation: outputGeneration)
            async let status = Self.readExitReport(report, prefix: start?.exitPrefix, started: start?.time != nil)
            let workerOK = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    var status: Int32 = 0
                    var reaped: pid_t
                    repeat { reaped = waitpid(pid, &status, 0) } while reaped == -1 && errno == EINTR
                    continuation.resume(returning: reaped == pid && status == 0)
                }
            }
            return await SessionResult(
                exit: workerOK ? status ?? .unconfirmed : .unconfirmed,
                stdout: String(decoding: out, as: UTF8.self),
                stderr: String(decoding: err, as: UTF8.self)
            )
        }
    }

    func send(_ message: Data) -> Bool {
        // Keep each non-blocking write atomic, even if Flutter is busy building.
        guard let machineInput, !message.isEmpty, message.count <= PIPE_BUF else { return false }
        return message.withUnsafeBytes { bytes in
            write(machineInput.fileDescriptor, bytes.baseAddress, bytes.count) == bytes.count
        }
    }

    func stop() {
        try? control.close()
        try? machineInput?.close()
        machineInput = nil
    }

    func wait() async -> SessionResult {
        let value = await result.value
        stop()
        return value
    }

    nonisolated private static func drain(_ handle: FileHandle, limit: Int) async -> Data {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                defer { try? handle.close() }
                var tail = Data()
                while let chunk = try? handle.read(upToCount: 4096), !chunk.isEmpty {
                    tail.append(chunk)
                    if tail.count > limit { tail.removeFirst(tail.count - limit) }
                }
                continuation.resume(returning: tail)
            }
        }
    }

    nonisolated private static func drainOutput(_ handle: FileHandle, isError: Bool, output: Output?,
                                                generation: @escaping @Sendable () -> UInt64) async -> Data {
        guard let output else { return await drain(handle, limit: 64 * 1024) }
        defer { try? handle.close() }
        while let chunk = await readChunk(handle.fileDescriptor, generation: generation) {
            await output(chunk.data, isError, chunk.generation)
        }
        return Data()
    }

    nonisolated private static func readStartReport(_ handle: FileHandle) async -> (time: UInt64?, exitPrefix: Data)? {
        var bytes = Data()
        while let chunk = await readChunk(handle.fileDescriptor) {
            guard bytes.count + chunk.data.count <= 1024 else { return nil }
            bytes.append(chunk.data)
            if let newline = bytes.firstIndex(of: 0x0a) {
                guard let time = UInt64(String(decoding: bytes[..<newline], as: UTF8.self)), time > 0 else { return nil }
                bytes.removeSubrange(...newline)
                return (time, bytes)
            }
        }
        // Failed spawns send the exit result alone.
        return (nil, bytes)
    }

    nonisolated private static func readExitReport(_ handle: FileHandle, prefix: Data?, started: Bool) async -> SessionExit? {
        defer { try? handle.close() }
        guard var bytes = prefix else { return nil }
        while let chunk = await readChunk(handle.fileDescriptor) {
            guard bytes.count + chunk.data.count <= 1024 else { return nil }
            bytes.append(chunk.data)
        }
        guard let exit = try? JSONDecoder().decode(SessionExit.self, from: bytes) else { return nil }
        switch exit {
        case .launchFailed: return started ? nil : exit
        default: return started ? exit : nil
        }
    }

    nonisolated private static func readChunk(_ fd: Int32, generation: @escaping @Sendable () -> UInt64 = { 0 })
        async -> (data: Data, generation: UInt64)? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var bytes = [UInt8](repeating: 0, count: 4096)
                var count: Int
                repeat { count = read(fd, &bytes, bytes.count) } while count == -1 && errno == EINTR
                // Tag bytes before queuing delivery to the main actor.
                continuation.resume(returning: count > 0 ? (Data(bytes.prefix(count)), generation()) : nil)
            }
        }
    }
}
