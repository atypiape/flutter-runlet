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

    var detail: String {
        switch self {
        case .exited(let code): "退出码 \(code)"
        case .signaled(let signal): "信号 \(signal)"
        case .launchFailed(let code): "进程启动失败（\(code)）"
        case .unconfirmed: "无法确认受管进程的退出结果"
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
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

final class ProjectLease: Sendable {
    let descriptor: Int32
    let project: URL
    let identity: String
    private let projectDescriptor: Int32

    init(project: URL, lockDirectory: URL) throws {
        let root = open(project.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard root >= 0 else { throw SessionIssue("无法打开项目目录") }
        var info = stat()
        guard fstat(root, &info) == 0 else {
            close(root)
            throw SessionIssue("无法确认项目目录身份")
        }
        let identity = "\(info.st_dev)-\(info.st_ino)"
        let path = lockDirectory.appending(path: "\(identity).lock").path
        let fd = open(path, O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else {
            close(root)
            throw SessionIssue("无法打开项目锁")
        }
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0, info.st_nlink == 1,
              flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            close(fd)
            close(root)
            throw SessionIssue("项目正由另一个会话使用，或项目锁不可用")
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
            throw SessionIssue("项目目录已移动或身份已变化")
        }
    }

    func openWorkingDirectory(_ path: String) throws -> Int32 {
        try verifyProject()
        let directory = path == project.path
            ? fcntl(projectDescriptor, F_DUPFD_CLOEXEC, STDERR_FILENO + 1)
            : open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard directory >= 0 else { throw SessionIssue("任务工作目录不可用") }
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
    func start(_ command: SessionCommand, lease: ProjectLease) throws -> SessionProcess {
        let payload = try JSONEncoder().encode(command)
        let directoryFD = try lease.openWorkingDirectory(command.directory)
        defer { close(directoryFD) }
        let control = Pipe()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        let report = Pipe()
        let inputFD = input.fileHandleForReading.fileDescriptor
        let reportFD = report.fileHandleForWriting.fileDescriptor
        let handle = input.fileHandleForWriting
        guard fcntl(handle.fileDescriptor, F_SETNOSIGPIPE, 1) == 0 else {
            throw SessionIssue("无法配置监督进程管道")
        }
        let result = SessionSpawn.spawn(
            worker.path,
            arguments: [String(lease.descriptor), String(inputFD), String(reportFD), String(directoryFD)],
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
            for fd in [lease.descriptor, inputFD, reportFD, directoryFD] {
                let code = posix_spawn_file_actions_addinherit_np(&actions, fd)
                if code != 0 { return code }
            }
            return 0
        }
        let pid = try result.get()
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
                              report: report.fileHandleForReading)
    }
}

@MainActor
final class SessionProcess {
    private let control: FileHandle
    private let result: Task<SessionResult, Never>
    let pid: pid_t

    init(pid: pid_t, control: FileHandle, stdout: FileHandle, stderr: FileHandle, report: FileHandle) {
        self.pid = pid
        self.control = control
        result = Task.detached {
            async let out = Self.drain(stdout, limit: 64 * 1024)
            async let err = Self.drain(stderr, limit: 64 * 1024)
            async let status = Self.drain(report, limit: 1024)
            let workerOK = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    var status: Int32 = 0
                    var reaped: pid_t
                    repeat { reaped = waitpid(pid, &status, 0) } while reaped == -1 && errno == EINTR
                    continuation.resume(returning: reaped == pid && status == 0)
                }
            }
            let decoded = try? await JSONDecoder().decode(SessionExit.self, from: status)
            return await SessionResult(
                exit: workerOK ? decoded ?? .unconfirmed : .unconfirmed,
                stdout: String(decoding: out, as: UTF8.self),
                stderr: String(decoding: err, as: UTF8.self)
            )
        }
    }

    func stop() { try? control.close() }

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
}
