import CryptoKit
import Darwin
import Foundation

struct ProjectRecoveryRecord: Codable, Equatable, Sendable {
    let version: Int
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
    }

    let directory: URL
    private let key: SymmetricKey
    private let check: @Sendable (SyncPoint) throws -> Void

    init(directory: URL, check: @escaping @Sendable (SyncPoint) throws -> Void = { _ in }) throws {
        self.directory = try Self.privateDirectory(directory)
        self.check = check
        let installationLock = open(self.directory.appending(path: "installation.lock").path,
                                    O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard installationLock >= 0 else { throw SessionIssue("无法打开恢复存储安装锁") }
        defer { close(installationLock) }
        var status: Int32
        repeat { status = flock(installationLock, LOCK_EX) } while status != 0 && errno == EINTR
        guard status == 0 else { throw SessionIssue("无法锁定恢复存储") }

        let keyURL = self.directory.appending(path: "authentication.key")
        if let bytes = try Self.privateData(keyURL) {
            guard bytes.count == 32 else { throw SessionIssue("恢复记录密钥损坏") }
            key = SymmetricKey(data: bytes)
        } else {
            let records = try FileManager.default.contentsOfDirectory(atPath: self.directory.path)
            guard !records.contains(where: { $0.hasSuffix(".risk") }) else {
                throw SessionIssue("待恢复记录缺少原安装密钥")
            }
            let newKey = SymmetricKey(size: .bits256)
            try Self.replace(keyURL, data: newKey.withUnsafeBytes { Data($0) })
            key = newKey
        }
        // Also validate durability if an earlier instance created the key but its sync failed.
        let keyFD = open(keyURL.path, O_RDWR | O_NOFOLLOW | O_CLOEXEC)
        guard keyFD >= 0 else { throw SessionIssue("无法重新打开恢复密钥") }
        defer { close(keyFD) }
        try Self.syncDirectory(self.directory)
        try Self.syncFile(keyFD)
    }

    static func privateDirectory(_ url: URL) throws -> URL {
        let parent = url.deletingLastPathComponent().resolvingSymlinksInPath()
        let target = parent.appending(path: url.lastPathComponent)
        guard mkdir(target.path, 0o700) == 0 || errno == EEXIST else {
            throw SessionIssue("无法创建私有恢复目录")
        }
        var info = stat()
        guard lstat(target.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0 else {
            throw SessionIssue("私有目录的身份或权限无效")
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
            version: 1, projectPath: lease.project.path,
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
        guard let bytes = try Self.privateData(url), try read(url) == expected else {
            throw SessionIssue("待清除的恢复记录缺失或已变化")
        }
        // Keep an open, writable descriptor for the storage barrier after unlink.
        let descriptor = open(url.path, O_RDWR | O_CLOEXEC | O_NOFOLLOW)
        guard descriptor >= 0 else { throw SessionIssue("无法打开待清除的恢复记录") }
        defer { close(descriptor) }
        guard unlink(url.path) == 0 else { throw SessionIssue("无法清除恢复记录") }
        do {
            try check(.removal)
            try Self.syncDirectory(directory)
            try Self.syncFile(descriptor)
        } catch {
            try? Self.replace(url, data: bytes)
            throw error
        }
    }

    func allRecords() throws -> [ProjectRecoveryRecord] {
        let items = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return try items.filter { $0.pathExtension == "risk" }.sorted { $0.path < $1.path }.compactMap { url in
            guard let record = try read(url) else { return nil }
            let expected = recordURL(forRecordedPath: record.projectPath)
            guard url.lastPathComponent == expected.lastPathComponent else {
                throw SessionIssue("恢复记录文件名与项目不匹配")
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
            ) else { throw SessionIssue("恢复记录认证失败") }
            let record = try JSONDecoder().decode(ProjectRecoveryRecord.self, from: envelope.payload)
            guard record.version == 1, record.projectPath.hasPrefix("/"), !record.taskLabel.isEmpty else {
                throw SessionIssue("恢复记录格式或版本无效")
            }
            return record
        } catch {
            throw SessionIssue("恢复记录损坏或认证失败")
        }
    }

    func verifyProject(_ record: ProjectRecoveryRecord, _ project: URL) throws {
        guard record.projectPath == (try ProjectLocation.directory(project)).path,
              record.projectIdentity == (try ProjectLocation.identity(project)) else {
            throw SessionIssue("恢复记录的项目目录已移动或身份已变化")
        }
    }

    func verifyDefinition(_ definition: PreparedTask.Definition, environment: [String: String],
                          record: ProjectRecoveryRecord) throws {
        guard authenticate(try encoded(definition), scope: "definition") == record.definition else {
            throw SessionIssue("原恢复任务定义已变化。请还原命令、参数、工作目录和任务环境后重试")
        }
        let changed = record.variables.keys.sorted().filter { name in
            guard let value = environment[name] else { return true }
            return authenticate(Data(value.utf8), scope: "variable:\(name)") != record.variables[name]
        }
        if !changed.isEmpty {
            throw SessionIssue("恢复任务引用的环境变量已变化：\(changed.joined(separator: "、"))")
        }
    }

    func verifyExecution(_ task: PreparedTask, record: ProjectRecoveryRecord) throws {
        guard authenticate(try execution(task), scope: "execution") == record.execution else {
            throw SessionIssue("原恢复任务的可执行文件、参数或工作目录解析结果已变化")
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
        let fd = open(url.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        if fd == -1 && errno == ENOENT { return nil }
        guard fd >= 0 else { throw SessionIssue("无法读取私有恢复文件") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_uid == geteuid(),
              info.st_mode & 0o077 == 0, info.st_nlink == 1, info.st_size <= 1_048_576 else {
            throw SessionIssue("私有恢复文件身份或长度无效")
        }
        return try handle.readToEnd() ?? Data()
    }

    private static func replace(
        _ url: URL, data: Data, beforeDataSync: () throws -> Void = {},
        beforeDirectorySync: () throws -> Void = {}
    ) throws {
        let parent = url.deletingLastPathComponent()
        let temporary = parent.appending(path: ".\(UUID().uuidString).tmp")
        let fd = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw SessionIssue("无法创建临时恢复文件") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer {
            try? handle.close()
            unlink(temporary.path)
        }
        try handle.write(contentsOf: data)
        try beforeDataSync()
        try syncFile(fd)
        guard rename(temporary.path, url.path) == 0 else { throw SessionIssue("无法原子提交恢复文件") }
        try beforeDirectorySync()
        try syncDirectory(parent)
        try syncFile(fd)
    }

    private static func syncDirectory(_ url: URL) throws {
        let fd = open(url.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw SessionIssue("无法打开待同步的目录") }
        defer { close(fd) }
        var result: Int32
        repeat { result = fsync(fd) } while result == -1 && errno == EINTR
        guard result == 0 else { throw SessionIssue("恢复目录项同步失败") }
    }

    private static func syncFile(_ fd: Int32) throws {
        var result: Int32
        repeat { result = fcntl(fd, F_FULLFSYNC, 0) } while result == -1 && errno == EINTR
        guard result == 0 else { throw SessionIssue("恢复文件持久同步失败") }
    }
}
