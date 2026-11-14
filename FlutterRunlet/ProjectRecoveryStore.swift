import CryptoKit
import Darwin
import Foundation

struct ProjectRecoveryRecord: Codable, Equatable, Sendable {
    let version: Int
    let id: UUID?
    let projectPath: String
    let projectIdentity: String
    let taskLabel: String
    let definition: Data
    let execution: Data
    let variables: [String: Data]
}

struct ProjectRecoveryStore: Sendable {
    enum SyncPoint: Equatable, Sendable {
        case recordData
        case recordDirectory
        case removal
        case completionDirectory
        case removalCleanup
    }

    let directory: URL
    private let key: SymmetricKey
    private let check: @Sendable (SyncPoint) throws -> Void

    init(directory: URL, check: @escaping @Sendable (SyncPoint) throws -> Void = { _ in }) throws {
        self.directory = try Self.privateDirectory(directory)
        self.check = check
        let installationLock = open(self.directory.appending(path: "installation.lock").path,
                                    O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard installationLock >= 0 else { throw SessionIssue(localized: "Could not open the recovery storage installation lock") }
        defer { close(installationLock) }
        var status: Int32
        repeat { status = flock(installationLock, LOCK_EX) } while status != 0 && errno == EINTR
        guard status == 0 else { throw SessionIssue(localized: "Could not lock the recovery storage") }

        let keyURL = self.directory.appending(path: "authentication.key")
        if let bytes = try Self.privateData(keyURL) {
            guard bytes.count == 32 else { throw SessionIssue(localized: "The recovery record key is damaged") }
            key = SymmetricKey(data: bytes)
        } else {
            let records = try FileManager.default.contentsOfDirectory(atPath: self.directory.path)
            guard !records.contains(where: { $0.hasSuffix(".risk") }) else {
                throw SessionIssue(localized: "Pending recovery records have no original installation key")
            }
            let newKey = SymmetricKey(size: .bits256)
            try Self.replace(keyURL, data: newKey.withUnsafeBytes { Data($0) })
            key = newKey
        }
        // Also validate durability if an earlier instance created the key but its sync failed.
        let keyFD = open(keyURL.path, O_RDWR | O_NOFOLLOW | O_CLOEXEC)
        guard keyFD >= 0 else { throw SessionIssue(localized: "Could not reopen the recovery key") }
        defer { close(keyFD) }
        try Self.syncDirectory(self.directory)
        try Self.syncFile(keyFD)
    }

    static func privateDirectory(_ url: URL) throws -> URL {
        let parent = url.deletingLastPathComponent().resolvingSymlinksInPath()
        let target = parent.appending(path: url.lastPathComponent)
        guard mkdir(target.path, 0o700) == 0 || errno == EEXIST else {
            throw SessionIssue(localized: "Could not create the private recovery directory")
        }
        var info = stat()
        guard lstat(target.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0 else {
            throw SessionIssue(localized: "The private directory identity or permissions are invalid")
        }
        try syncDirectory(parent)
        return target
    }

    func lease(for project: URL) throws -> ProjectLease {
        try ProjectLease(project: ProjectLocation.directory(project), lockDirectory: directory)
    }

    func recordURL(for project: URL) throws -> URL {
        recordURL(forRecordedPath: try ProjectLocation.directory(project).path)
    }

    private func recordURL(forRecordedPath path: String) -> URL {
        let hash = SHA256.hash(data: Data(path.utf8))
        return directory.appending(path: hash.map { String(format: "%02x", $0) }.joined() + ".risk")
    }

    func read(project: URL) throws -> ProjectRecoveryRecord? {
        let url = try recordURL(for: project)
        guard let record = try read(url) else { return nil }
        try verifyProject(record, project)
        return record
    }

    // Call under the project lease so a renamed directory cannot evade its existing risk.
    func pendingRecord(for project: URL) throws -> ProjectRecoveryRecord? {
        if let record = try read(project: project) { return record }
        let identity = try ProjectLocation.identity(project)
        return try allRecords().first { $0.projectIdentity == identity }
    }

    func write(task: PreparedTask, lease: ProjectLease) throws -> ProjectRecoveryRecord {
        try lease.verifyProject()
        let record = ProjectRecoveryRecord(
            version: 1, id: UUID(), projectPath: lease.project.path,
            projectIdentity: lease.identity, taskLabel: task.label,
            definition: authenticate(try encoded(task.definition), scope: "definition"),
            execution: authenticate(try execution(task), scope: "execution"),
            variables: Dictionary(uniqueKeysWithValues: task.references.map {
                    ($0.key, authenticate(Data($0.value.utf8), scope: "variable:\($0.key)"))
            })
        )
        let payload = try JSONEncoder().encode(record)
        let envelope = Envelope(payload: payload, authentication: authenticate(payload, scope: "record"))
        try Self.replace(recordURL(forRecordedPath: record.projectPath), data: JSONEncoder().encode(envelope),
                         beforeDataSync: { try check(.recordData) },
                         beforeDirectorySync: { try check(.recordDirectory) })
        return record
    }

    func remove(_ expected: ProjectRecoveryRecord, lease: ProjectLease) throws {
        try lease.verifyProject()
        try verifyProject(expected, lease.project)
        let url = recordURL(forRecordedPath: expected.projectPath)
        guard try read(url) == expected else {
            throw SessionIssue(localized: "The recovery record to clear is missing or has changed")
        }

        // Leave the original record in place until the authenticated completion is durable.
        let receipt = completionURL(for: url)
        try Self.replace(receipt, data: try completionCode(for: expected),
                         beforeDataSync: { try check(.removal) },
                         beforeDirectorySync: { try check(.completionDirectory) })
        cleanCompletedRecord(url, receipt: receipt)
    }

    private func cleanCompletedRecord(_ record: URL, receipt: URL) {
        do {
            try check(.removalCleanup)
            guard let barrier = try Self.privateFile(receipt, writable: true),
                  unlink(record.path) == 0 else { return }
            try Self.syncDirectory(directory)
            try Self.syncFile(barrier.fileDescriptor)
            // A receipt left behind by interruption cannot clear a future session's record.
            _ = unlink(receipt.path)
        } catch {
            // Keep the durable receipt when the risk file's deletion could not be confirmed.
        }
    }

    private func completionURL(for record: URL) -> URL {
        record.deletingPathExtension().appendingPathExtension("completed")
    }

    private func completionCode(for record: ProjectRecoveryRecord) throws -> Data {
        authenticate(try encoded(record), scope: "completed")
    }

    private func hasDurableCompletion(for record: ProjectRecoveryRecord, at url: URL) -> Bool {
        do {
            guard let file = try Self.privateFile(completionURL(for: url), writable: true),
                  try file.readToEnd() == completionCode(for: record) else { return false }
            try check(.completionDirectory)
            try Self.syncDirectory(directory)
            try Self.syncFile(file.fileDescriptor)
            return true
        } catch {
            // An incomplete receipt is not sufficient evidence to hide the original risk.
            return false
        }
    }

    func allRecords() throws -> [ProjectRecoveryRecord] {
        let items = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return try items.filter { $0.pathExtension == "risk" }.sorted { $0.path < $1.path }.compactMap { url in
            guard let record = try read(url) else { return nil }
            let expected = recordURL(forRecordedPath: record.projectPath)
            guard url.lastPathComponent == expected.lastPathComponent else {
                throw SessionIssue(localized: "The recovery record filename does not match the project")
            }
            return record
        }
    }

    private struct Envelope: Codable {
        let payload: Data
        let authentication: Data
    }

    private func read(_ url: URL) throws -> ProjectRecoveryRecord? {
        guard let data = try Self.privateData(url) else { return nil }
        do {
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            guard HMAC<SHA256>.isValidAuthenticationCode(
                envelope.authentication, authenticating: Data("record\0".utf8) + envelope.payload, using: key
            ) else { throw SessionIssue(localized: "Recovery record authentication failed") }
            let record = try JSONDecoder().decode(ProjectRecoveryRecord.self, from: envelope.payload)
            guard record.version == 1, record.projectPath.hasPrefix("/"), !record.taskLabel.isEmpty else {
                throw SessionIssue(localized: "The recovery record format or version is invalid")
            }
            return hasDurableCompletion(for: record, at: url) ? nil : record
        } catch {
            throw SessionIssue(localized: "The recovery record is damaged or failed authentication")
        }
    }

    func verifyProject(_ record: ProjectRecoveryRecord, _ project: URL) throws {
        guard record.projectPath == (try ProjectLocation.directory(project)).path,
              record.projectIdentity == (try ProjectLocation.identity(project)) else {
            throw SessionIssue(localized: "The project directory in the recovery record moved or changed identity")
        }
    }

    func verifyDefinition(_ definition: PreparedTask.Definition, environment: [String: String],
                          record: ProjectRecoveryRecord) throws {
        guard authenticate(try encoded(definition), scope: "definition") == record.definition else {
            throw SessionIssue(localized: "The original recovery task changed. Restore its command, arguments, working directory and task environment, then try again")
        }
        let changed = record.variables.keys.sorted().filter { name in
            guard let value = environment[name] else { return true }
            return authenticate(Data(value.utf8), scope: "variable:\(name)") != record.variables[name]
        }
        if !changed.isEmpty {
            let variableNames = changed.joined(separator: ", ")
            throw SessionIssue(localized: "Environment variables referenced by the recovery task changed: \(variableNames)")
        }
    }

    func verifyExecution(_ task: PreparedTask, record: ProjectRecoveryRecord) throws {
        guard authenticate(try execution(task), scope: "execution") == record.execution else {
            throw SessionIssue(localized: "The executable, arguments, or working directory resolved by the original recovery task changed")
        }
    }

    private func execution(_ task: PreparedTask) throws -> Data {
        try encoded([task.command.executable, task.command.directory] + task.command.arguments)
    }

    private func encoded(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    private func authenticate(_ data: Data, scope: String) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: Data((scope + "\0").utf8) + data, using: key))
    }

    private static func privateData(_ url: URL) throws -> Data? {
        guard let handle = try privateFile(url) else { return nil }
        return try handle.readToEnd() ?? Data()
    }

    private static func privateFile(_ url: URL, writable: Bool = false) throws -> FileHandle? {
        let access = writable ? O_RDWR : O_RDONLY
        let fd = open(url.path, access | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        if fd == -1 && errno == ENOENT { return nil }
        guard fd >= 0 else { throw SessionIssue(localized: "Could not read the private recovery file") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_uid == geteuid(),
              info.st_mode & 0o077 == 0, info.st_nlink == 1, info.st_size <= 1_048_576 else {
            throw SessionIssue(localized: "The private recovery file identity or length is invalid")
        }
        return handle
    }

    private static func replace(
        _ url: URL, data: Data, beforeDataSync: () throws -> Void = {},
        beforeDirectorySync: () throws -> Void = {}
    ) throws {
        let parent = url.deletingLastPathComponent()
        let temporary = parent.appending(path: ".\(UUID().uuidString).tmp")
        let fd = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw SessionIssue(localized: "Could not create the temporary recovery file") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer {
            try? handle.close()
            unlink(temporary.path)
        }
        try handle.write(contentsOf: data)
        try beforeDataSync()
        try syncFile(fd)
        guard rename(temporary.path, url.path) == 0 else { throw SessionIssue(localized: "Could not atomically save the recovery file") }
        try beforeDirectorySync()
        try syncDirectory(parent)
        try syncFile(fd)
    }

    private static func syncDirectory(_ url: URL) throws {
        let fd = open(url.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw SessionIssue(localized: "Could not open the directory for syncing") }
        defer { close(fd) }
        var result: Int32
        repeat { result = fsync(fd) } while result == -1 && errno == EINTR
        guard result == 0 else { throw SessionIssue(localized: "Could not sync the recovery directory entry") }
    }

    private static func syncFile(_ fd: Int32) throws {
        var result: Int32
        repeat { result = fcntl(fd, F_FULLFSYNC, 0) } while result == -1 && errno == EINTR
        guard result == 0 else { throw SessionIssue(localized: "Could not persist the recovery file to disk") }
    }
}
