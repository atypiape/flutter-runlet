import Darwin
import Foundation
import Security

struct UpdateObjectIdentity: Codable, Equatable, Sendable {
    let device: Int32
    let inode: UInt64

    init(_ info: stat) {
        device = info.st_dev
        inode = info.st_ino
    }
}

final class UpdateDirectory: Sendable {
    enum Issue: Error {
        case path, privatePermissions, volume, creation, identity, exchange, durability, record
    }

    let url: URL
    let descriptor: Int32
    let identity: UpdateObjectIdentity

    init(_ url: URL, privateAccess: Bool = false) throws {
        guard url.isFileURL, url.path.hasPrefix("/") else { throw Issue.path }
        let parts = url.path.split(separator: "/").map(String.init)
        guard !parts.isEmpty, parts.allSatisfy(Self.validName) else { throw Issue.path }
        var fd = open("/", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw Issue.path }
        var owned = false
        defer { if !owned { close(fd) } }
        for part in parts {
            let next = openat(fd, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard next >= 0 else { throw Issue.path }
            close(fd)
            fd = next
        }
        var info = stat()
        guard fstat(fd, &info) == 0 else { throw Issue.identity }
        if privateAccess {
            guard info.st_uid == geteuid(), info.st_mode & 0o077 == 0 else { throw Issue.privatePermissions }
        }
        self.url = url
        descriptor = fd
        identity = UpdateObjectIdentity(info)
        owned = true
    }

    deinit { close(descriptor) }

    func verify() throws {
        guard try UpdateDirectory(url).identity == identity else { throw Issue.identity }
    }

    func requireLocalAPFS() throws {
        var fs = statfs()
        guard fstatfs(descriptor, &fs) == 0, fs.f_flags & UInt32(MNT_LOCAL) != 0,
              fs.f_flags & UInt32(MNT_RDONLY) == 0 else { throw Issue.volume }
        let type = withUnsafeBytes(of: fs.f_fstypename) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        guard type == "apfs" else { throw Issue.volume }
    }

    func createPrivateDirectory(_ name: String) throws -> UpdateDirectory {
        guard Self.validName(name), mkdirat(descriptor, name, 0o700) == 0 else { throw Issue.creation }
        let child = url.appending(path: name, directoryHint: .isDirectory)
        let opened = try UpdateDirectory(child, privateAccess: true)
        guard opened.identity.device == identity.device, try directoryIdentity(name) == opened.identity else {
            throw Issue.identity
        }
        try synchronize()
        return opened
    }

    func directoryIdentity(_ name: String) throws -> UpdateObjectIdentity {
        guard Self.validName(name) else { throw Issue.path }
        var info = stat()
        guard fstatat(descriptor, name, &info, AT_SYMLINK_NOFOLLOW) == 0,
              info.st_mode & S_IFMT == S_IFDIR, info.st_dev == identity.device else { throw Issue.identity }
        return UpdateObjectIdentity(info)
    }

    func exchange(_ name: String, expected: UpdateObjectIdentity,
                  with peer: UpdateDirectory, name peerName: String, expected other: UpdateObjectIdentity) throws {
        guard identity.device == peer.identity.device, expected != other else { throw Issue.volume }
        try verify()
        try peer.verify()
        guard try directoryIdentity(name) == expected, try peer.directoryIdentity(peerName) == other else { throw Issue.identity }
        guard renameatx_np(descriptor, name, peer.descriptor, peerName, UInt32(RENAME_SWAP)) == 0 else { throw Issue.exchange }
        try synchronize()
        try peer.synchronize()
        try verify()
        try peer.verify()
        guard try directoryIdentity(name) == other, try peer.directoryIdentity(peerName) == expected else { throw Issue.identity }
    }

    func write<Value: Encodable>(_ value: Value, to name: String) throws {
        guard Self.validName(name) else { throw Issue.path }
        let data = try JSONEncoder().encode(value)
        guard data.count <= 65_536 else { throw Issue.record }
        let temporary = ".\(UUID().uuidString)"
        let fd = openat(descriptor, temporary, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw Issue.creation }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close(); unlinkat(descriptor, temporary, 0) }
        try handle.write(contentsOf: data)
        guard fcntl(fd, F_FULLFSYNC, 0) == 0,
              renameat(descriptor, temporary, descriptor, name) == 0 else { throw Issue.durability }
        try synchronize()
    }

    func read<Value: Decodable>(_ name: String, as type: Value.Type = Value.self) throws -> Value? {
        guard Self.validName(name) else { throw Issue.path }
        let fd = openat(descriptor, name, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        if fd == -1 && errno == ENOENT { return nil }
        guard fd >= 0 else { throw Issue.record }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0, info.st_nlink == 1,
              info.st_size > 0, info.st_size <= 65_536,
              let data = try handle.read(upToCount: 65_537), data.count == info.st_size else { throw Issue.record }
        return try JSONDecoder().decode(type, from: data)
    }

    func remove(_ name: String) throws {
        guard Self.validName(name) else { throw Issue.path }
        guard unlinkat(descriptor, name, 0) == 0 || errno == ENOENT else { throw Issue.record }
        try synchronize()
    }

    private func synchronize() throws {
        guard fsync(descriptor) == 0 else { throw Issue.durability }
    }

    private static func validName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.utf8.contains(0)
    }
}

struct UpdateProcessIdentity: Codable, Equatable, Sendable {
    let pid: pid_t
    let seconds: UInt64
    let microseconds: UInt64
    let executable: String

    init?(_ pid: pid_t) {
        guard pid > 0 else { return nil }
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size,
              info.pbi_uid == geteuid(), let executable = Self.path(pid) else { return nil }
        self.pid = pid
        seconds = info.pbi_start_tvsec
        microseconds = info.pbi_start_tvusec
        self.executable = executable
    }

    var isRunning: Bool { Self(pid) == self }

    var hasExited: Bool {
        if let process = Self(pid) { return process.seconds != seconds || process.microseconds != microseconds }
        return kill(pid, 0) == -1 && errno == ESRCH
    }

    static func path(_ pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return buffer.withUnsafeBufferPointer { bytes in String(validatingCString: bytes.baseAddress!) }
    }

    static func requireNoOtherInstances(_ product: String, excluding excluded: pid_t?) throws {
        let type = UInt32(PROC_UID_ONLY)
        let required = proc_listpids(type, geteuid(), nil, 0)
        let width = MemoryLayout<pid_t>.stride
        guard required > 0, required < 1_048_576 else { throw UpdateActivityLease.Issue.workersUnconfirmed }
        var pids = [pid_t](repeating: 0, count: Int(required) / width + 256)
        let capacity = Int32(pids.count * width)
        let size = proc_listpids(type, geteuid(), &pids, capacity)
        guard size > 0, size < capacity else { throw UpdateActivityLease.Issue.workersUnconfirmed }
        for pid in pids.prefix(Int(size) / width) where pid > 0 && pid != excluded {
            guard let path = path(pid) else {
                var name = [CChar](repeating: 0, count: 128)
                if proc_name(pid, &name, UInt32(name.count)) > 0,
                   name.withUnsafeBufferPointer({ String(validatingCString: $0.baseAddress!) })?.hasPrefix("FlutterRunlet") == true {
                    throw UpdateActivityLease.Issue.workersUnconfirmed
                }
                continue
            }
            let binary = URL(filePath: path)
            let worker = binary.lastPathComponent == "FlutterRunletSessionWorker"
            guard worker || binary.lastPathComponent == "FlutterRunlet" else { continue }
            let app = binary.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            guard let identifier = Bundle(url: app)?.bundleIdentifier, app.pathExtension == "app" else {
                throw UpdateActivityLease.Issue.workersUnconfirmed
            }
            if identifier == product { throw UpdateActivityLease.Issue.workersUnconfirmed }
        }
    }
}

#if !RUNLET_UPDATE_HELPER
final class UpdateReservation: Sendable {
    let recovery: UpdateDirectory
    let activity: UpdateActivityLease
    private let legacy: [Int32]

    init(store: ProjectRecoveryStore, productID: String) throws {
        recovery = try UpdateDirectory(store.directory, privateAccess: true)
        activity = try UpdateActivityLease(directory: store.directory, installing: true)
        // Old versions take this lock at startup before they can open any project.
        // Holding it through the exchange also fences an old process launched after the scan.
        let initialization = try UpdateActivityLease.lock("installation.lock", in: recovery.descriptor, LOCK_EX)
        var held = [initialization]
        var keep = false
        defer { if !keep { held.forEach { close($0) } } }
        let entries = try FileManager.default.contentsOfDirectory(atPath: recovery.url.path)
        guard try store.allRecords().isEmpty, !entries.contains(where: { $0.hasPrefix("update-worker-") }) else {
            throw UpdateActivityLease.Issue.workersUnconfirmed
        }
        for name in entries where name.hasSuffix(".lock") && name != "installation.lock" && name != UpdateActivityLease.name {
            held.append(try UpdateActivityLease.lock(name, in: recovery.descriptor, LOCK_EX))
        }
        try UpdateProcessIdentity.requireNoOtherInstances(productID, excluding: getpid())
        legacy = held
        keep = true
    }

    var inherited: [Int32] { [activity.descriptor] + legacy }

    deinit { legacy.forEach { close($0) } }
}
#endif

struct UpdateJournal: Codable, Sendable {
    enum Phase: String, Codable, Sendable {
        case prepared, waitingForNew, restoring, committed, restored, preserved
    }

    static let pending = "update-pending.json"
    static let receipt = "update-receipt.json"
    static let appName = "FlutterRunlet.app"
    static let stagedHelper = "FlutterRunletUpdateHelper.app"
    static let intent = "intent.json"

    let id: UUID
    let target: URL
    let stage: URL
    let parentIdentity: UpdateObjectIdentity
    let stageIdentity: UpdateObjectIdentity
    let recoveryIdentity: UpdateObjectIdentity
    let originalObject: UpdateObjectIdentity
    let candidateObject: UpdateObjectIdentity
    let oldProcess: UpdateProcessIdentity
    let original: PreparedUpdate.SignedIdentity
    let candidate: PreparedUpdate.SignedIdentity
    let releaseTag: String
    let language: String
    var phase: Phase = .prepared
    var helperProcess: UpdateProcessIdentity?
    var attemptedProcess: UpdateProcessIdentity?
    var candidateProcess: UpdateProcessIdentity?
    var reopenedProcess: UpdateProcessIdentity?
    var candidateExitConfirmed: Bool?
    var deliveryFailure: String?

    var product: String { original.app.productID }
    var releaseURL: URL { UpdateRepository.releases.appending(path: "tag/\(releaseTag)") }
    var stageApp: URL { stage.appending(path: Self.appName, directoryHint: .isDirectory) }
    var copiedHelper: URL { stage.appending(path: Self.stagedHelper, directoryHint: .isDirectory) }
    var socket: URL { stage.appending(path: "peer") }
    var targetExecutable: String { target.appending(path: "Contents/MacOS/FlutterRunlet").path }

    func validate(fixture: IsolatedUpdateBuild?) throws -> (parent: UpdateDirectory, staging: UpdateDirectory) {
        guard target.lastPathComponent == Self.appName,
              stage.deletingLastPathComponent().path == target.deletingLastPathComponent().path,
              stage.lastPathComponent.hasPrefix(".update-"),
              oldProcess.executable == targetExecutable,
              original.app.productID == candidate.app.productID,
              let old = ReleaseVersion(original.app.version), let new = ReleaseVersion(candidate.app.version), new > old,
              let release = ReleaseVersion(releaseTag.hasPrefix("v") ? String(releaseTag.dropFirst()) : releaseTag),
              release == new else {
            throw UpdateDirectory.Issue.identity
        }
        if let fixture {
            guard target.path == fixture.target.path, fixture.version == candidate.app.version,
                  fixture.build == candidate.app.build else { throw UpdateDirectory.Issue.identity }
        }
        let parent = try UpdateDirectory(target.deletingLastPathComponent())
        let staging = try UpdateDirectory(stage, privateAccess: true)
        try parent.requireLocalAPFS()
        guard parent.identity == parentIdentity, staging.identity == stageIdentity,
              parent.identity.device == staging.identity.device else { throw UpdateDirectory.Issue.identity }
        return (parent, staging)
    }

    func verifyArrangement(_ exchanged: Bool, fixture: IsolatedUpdateBuild?) throws {
        let (parent, staging) = try validate(fixture: fixture)
        let active = exchanged ? candidate : original
        let retained = exchanged ? original : candidate
        guard try parent.directoryIdentity(Self.appName) == (exchanged ? candidateObject : originalObject),
              try staging.directoryIdentity(Self.appName) == (exchanged ? originalObject : candidateObject),
              try UpdatePackageService.installationIdentity(at: target, productID: product, fixture: fixture) == active,
              try UpdatePackageService.installationIdentity(at: stageApp, productID: product, fixture: fixture) == retained else {
            throw UpdateDirectory.Issue.identity
        }
    }

    func exchange(restoring: Bool, fixture: IsolatedUpdateBuild?) throws {
        try verifyArrangement(restoring, fixture: fixture)
        let (parent, staging) = try validate(fixture: fixture)
        try parent.exchange(Self.appName, expected: restoring ? candidateObject : originalObject,
                            with: staging, name: Self.appName, expected: restoring ? originalObject : candidateObject)
        try verifyArrangement(!restoring, fixture: fixture)
    }

    static func fault(_ fixture: IsolatedUpdateBuild?, _ name: String) -> Bool {
        #if PHASE07_UPDATE
        guard let fixture, let root = try? UpdateDirectory(fixture.root, privateAccess: true),
              let value = try? root.read("install-fault.json", as: String.self) else { return false }
        return value.split(separator: ",").contains { $0 == name }
        #else
        return false
        #endif
    }
}

extension UpdateProcessIdentity {
    func verifies(_ expected: PreparedUpdate.SignedIdentity, executable path: String) -> Bool {
        guard executable == path, isRunning else { return false }
        var code: SecCode?
        let attributes = [kSecGuestAttributePid as String: pid] as CFDictionary
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &code) == errSecSuccess, let code,
              SecCodeCheckValidity(code, [], nil) == errSecSuccess else { return false }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return false }
        var details: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &details) == errSecSuccess,
              let info = details as? [String: Any], let hash = info[kSecCodeInfoUnique as String] as? Data,
              info[kSecCodeInfoIdentifier as String] as? String == expected.app.productID else { return false }
        return isRunning && expected.appCodeHashes.values.contains(hash.map { String(format: "%02x", $0) }.joined())
    }
}

final class UpdateChannel: Sendable {
    enum Issue: Error { case channel, deadline, peer, closed }
    let descriptor: Int32

    init(taking descriptor: Int32) throws {
        guard descriptor >= 0 else { throw Issue.channel }
        guard fcntl(descriptor, F_SETNOSIGPIPE, 1) == 0,
              fcntl(descriptor, F_SETFL, O_NONBLOCK) == 0 else {
            close(descriptor)
            throw Issue.channel
        }
        self.descriptor = descriptor
    }

    deinit { close(descriptor) }

    func send(_ byte: UInt8) throws {
        var value = byte
        guard write(descriptor, &value, 1) == 1 else { throw Issue.closed }
    }

    func receive(until deadline: ContinuousClock.Instant) async throws -> UInt8 {
        while .now < deadline {
            var value: UInt8 = 0
            let count = read(descriptor, &value, 1)
            if count == 1 { return value }
            if count == 0 { throw Issue.closed }
            guard errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR else { throw Issue.channel }
            try await Task.sleep(for: .milliseconds(25))
        }
        throw Issue.deadline
    }

    func matchesPeer(_ process: UpdateProcessIdentity) -> Bool {
        var pid: pid_t = 0
        var size = socklen_t(MemoryLayout<pid_t>.size)
        var uid: uid_t = 0
        var gid: gid_t = 0
        return getsockopt(descriptor, SOL_LOCAL, LOCAL_PEERPID, &pid, &size) == 0 && pid == process.pid
            && getpeereid(descriptor, &uid, &gid) == 0 && uid == geteuid() && process.isRunning
    }

    static func connect(_ address: URL) throws -> UpdateChannel {
        let channel = try UpdateChannel(taking: socket(AF_UNIX, SOCK_STREAM, 0))
        guard try socketAddress(address, { Darwin.connect(channel.descriptor, $0, $1) }) == 0 else { throw Issue.channel }
        return channel
    }

    static func listen(_ address: URL) throws -> UpdateChannel {
        let channel = try UpdateChannel(taking: socket(AF_UNIX, SOCK_STREAM, 0))
        guard try socketAddress(address, { bind(channel.descriptor, $0, $1) }) == 0,
              Darwin.listen(channel.descriptor, 4) == 0 else { throw Issue.channel }
        return channel
    }

    func accept(until deadline: ContinuousClock.Instant, peer: UpdateProcessIdentity) async throws -> UpdateChannel {
        while .now < deadline && peer.isRunning {
            let fd = Darwin.accept(descriptor, nil, nil)
            if fd >= 0 {
                let channel = try UpdateChannel(taking: fd)
                if channel.matchesPeer(peer) { return channel }
            } else if errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
                throw Issue.channel
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        throw Issue.deadline
    }

    private static func socketAddress(_ address: URL, _ run: (UnsafePointer<sockaddr>, socklen_t) -> Int32) throws -> Int32 {
        var socket = sockaddr_un()
        let bytes = Array(address.path.utf8CString)
        guard bytes.count <= MemoryLayout.size(ofValue: socket.sun_path) else { throw Issue.channel }
        socket.sun_family = sa_family_t(AF_UNIX)
        let length = socklen_t(MemoryLayout<sockaddr_un>.size)
        socket.sun_len = UInt8(length)
        withUnsafeMutableBytes(of: &socket.sun_path) { target in
            target.copyBytes(from: bytes.map { UInt8(bitPattern: $0) })
        }
        return withUnsafePointer(to: &socket) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { run($0, length) }
        }
    }
}

enum UpdateMessage {
    static let ready: UInt8 = 82
    static let verify: UInt8 = 86
    static let verified: UInt8 = 65
    static let proceed: UInt8 = 71
}

struct UpdateReceipt: Codable, Sendable {
    enum Failure: String, Codable, Sendable { case replacement, newLaunch }
    let transaction: UUID
    let failure: Failure
    let active: PreparedUpdate.SignedIdentity
    let version: String
    let releaseTag: String
}

#if !RUNLET_UPDATE_HELPER
extension IsolatedUpdateBuild {
    var projects: URL { root.deletingLastPathComponent().appending(path: "flutter-fixtures", directoryHint: .isDirectory) }
}

final class UpdateHandoff: Sendable {
    let reservation: UpdateReservation
    let journal: UpdateJournal
    let channel: UpdateChannel
    let helperPID: pid_t

    fileprivate init(reservation: UpdateReservation, journal: UpdateJournal, channel: UpdateChannel, helperPID: pid_t) {
        self.reservation = reservation
        self.journal = journal
        self.channel = channel
        self.helperPID = helperPID
    }

    static func prepare(_ update: PreparedUpdate, reservation: UpdateReservation, language: String) async throws -> UpdateHandoff {
        let fixture = IsolatedUpdateBuild.read()
        let target = Bundle.main.bundleURL.resolvingSymlinksInPath()
        guard (fixture == nil || target.path == fixture?.target.path), target.lastPathComponent == UpdateJournal.appName,
              let process = UpdateProcessIdentity(getpid()) else { throw UpdateDirectory.Issue.path }
        let parent = try UpdateDirectory(target.deletingLastPathComponent())
        try parent.requireLocalAPFS()
        let object = try parent.directoryIdentity(UpdateJournal.appName)
        let id = UUID()
        let staging = try parent.createPrivateDirectory(".update-" + String(id.uuidString.prefix(8)))
        let recovery = reservation.recovery
        var keep = false
        var marked = false
        defer {
            if !keep {
                if marked { try? recovery.remove(UpdateJournal.pending) }
                if (try? staging.verify()) != nil { try? FileManager.default.removeItem(at: staging.url) }
            }
        }
        guard try recovery.read(UpdateJournal.pending, as: UpdateJournal.self) == nil else { throw UpdateDirectory.Issue.record }
        let original = try UpdatePackageService.stage(update, replacing: target, in: staging.url)
        guard process.verifies(original, executable: target.appending(path: "Contents/MacOS/FlutterRunlet").path) else {
            throw UpdateDirectory.Issue.identity
        }
        let staged = try staging.directoryIdentity(UpdateJournal.appName)
        let record = UpdateJournal(id: id, target: target, stage: staging.url, parentIdentity: parent.identity,
                                   stageIdentity: staging.identity, recoveryIdentity: recovery.identity, originalObject: object,
                                   candidateObject: staged, oldProcess: process, original: original, candidate: update.signed,
                                   releaseTag: update.download.tag, language: language)
        try UpdatePackageService.copyBundle(from: target.appending(path: UpdatePackageService.helperPath), to: record.copiedHelper)
        guard try UpdatePackageService.copiedHelperHashes(at: record.copiedHelper, productID: record.product, fixture: fixture)
                == original.helperCodeHashes else { throw UpdateDirectory.Issue.identity }
        try record.verifyArrangement(false, fixture: fixture)
        try staging.write(record, to: UpdateJournal.intent)
        try recovery.write(record, to: UpdateJournal.pending)
        marked = true

        var sockets = [Int32](repeating: -1, count: 2)
        guard socketpair(AF_UNIX, SOCK_STREAM, 0, &sockets) == 0 else { throw UpdateChannel.Issue.channel }
        var child = sockets[1]
        defer { if child >= 0 { close(child) } }
        let channel = try UpdateChannel(taking: sockets[0])
        let inherited = reservation.inherited
        let helper = try SessionSpawn.spawn(
            record.copiedHelper.appending(path: UpdatePackageService.helperExecutable).path,
            arguments: [staging.url.path, recovery.url.path] + inherited.map(String.init), environment: [:],
            flags: Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETPGROUP)
        ) { actions in
            let control = posix_spawn_file_actions_adddup2(&actions, child, STDIN_FILENO)
            guard control == 0 else { return control }
            for descriptor in inherited {
                let action = posix_spawn_file_actions_addinherit_np(&actions, descriptor)
                if action != 0 { return action }
            }
            return 0
        }.get()
        close(child)
        child = -1
        guard try await channel.receive(until: .now + .seconds(8)) == UpdateMessage.ready,
              let peer = UpdateProcessIdentity(helper), peer.isRunning,
              peer.executable == record.copiedHelper.appending(path: UpdatePackageService.helperExecutable).path else {
            throw UpdateChannel.Issue.peer
        }
        keep = true
        return UpdateHandoff(reservation: reservation, journal: record, channel: channel, helperPID: helper)
    }

    func authorizeExit() -> Bool {
        guard UpdateProcessIdentity(helperPID)?.isRunning == true else { return false }
        do { try channel.send(UpdateMessage.proceed); return true }
        catch { return false }
    }

    func abandon() {
        if let pending = try? reservation.recovery.read(UpdateJournal.pending, as: UpdateJournal.self), pending.id == journal.id {
            try? reservation.recovery.remove(UpdateJournal.pending)
        }
    }
}

struct UpdateAppLaunch: Sendable {
    let journal: UpdateJournal
    let role: UpdateJournal.Phase
    var fixture: IsolatedUpdateBuild? { IsolatedUpdateBuild.read() }

    static func resolve(arguments: [String], namespace: URL) throws -> UpdateAppLaunch? {
        guard UpdatePackageService.installsEnabled else { return nil }
        let marker = arguments.firstIndex(of: "--runlet-update-trial")
        if marker == nil && !FileManager.default.fileExists(atPath: namespace.appending(path: UpdateJournal.pending).path) {
            return nil
        }
        let recovery = try UpdateDirectory(namespace, privateAccess: true)
        guard let journal = try recovery.read(UpdateJournal.pending, as: UpdateJournal.self),
              let marker, arguments.indices.contains(marker + 1), UUID(uuidString: arguments[marker + 1]) == journal.id,
              let helper = journal.helperProcess, helper.isRunning,
              recovery.identity == journal.recoveryIdentity, Bundle.main.bundleURL.resolvingSymlinksInPath().path == journal.target.path,
              journal.phase == .waitingForNew || journal.phase == .restoring else { throw UpdateDirectory.Issue.record }
        return Self(journal: journal, role: journal.phase)
    }

    func awaitCommit() async throws {
        let prefix = role == .waitingForNew ? "b" : "a"
        if UpdateJournal.fault(fixture, "exit-" + prefix) { Darwin.exit(71) }
        if UpdateJournal.fault(fixture, "hold-" + prefix) {
            // Remain in restricted startup so the assistant observes a live process with no response.
            try await Task.sleep(for: .seconds(120))
        }
        guard let helper = journal.helperProcess else { throw UpdateChannel.Issue.peer }
        let channel = try UpdateChannel.connect(journal.socket)
        guard channel.matchesPeer(helper) else { throw UpdateChannel.Issue.peer }
        try channel.send(UpdateJournal.fault(fixture, "wrong-" + prefix) ? 88 : UpdateMessage.ready)
        if role == .waitingForNew {
            guard try await channel.receive(until: .now + .seconds(15)) == UpdateMessage.verify else {
                throw UpdateChannel.Issue.peer
            }
            if UpdateJournal.fault(fixture, "exit-before-commit") { Darwin.exit(72) }
            try channel.send(UpdateMessage.verified)
        }
        guard try await channel.receive(until: .now + .seconds(35)) == UpdateMessage.proceed else { throw UpdateChannel.Issue.peer }
    }
}
#endif
