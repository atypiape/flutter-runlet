import Darwin
import Foundation

final class UpdateActivityLease: Sendable {
    enum Issue: Error { case unavailable, busy, workersUnconfirmed }

    static let name = "update-activity.lock"
    private static let workerPrefix = "update-worker-"
    private static let bootSession: UUID? = {
        var bytes = [CChar](repeating: 0, count: 37)
        var count = bytes.count
        guard sysctlbyname("kern.bootsessionuuid", &bytes, &count, nil, 0) == 0, count == bytes.count else {
            return nil
        }
        return bytes.withUnsafeBufferPointer { buffer in
            buffer.baseAddress.flatMap(String.init(validatingCString:)).flatMap(UUID.init(uuidString:))
        }
    }()
    let descriptor: Int32
    let directoryDescriptor: Int32
    private let installing: Bool

    init(directory: URL, installing: Bool = false) throws {
        let parent = open(directory.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard parent >= 0 else { throw Issue.unavailable }
        var keepParent = false
        defer { if !keepParent { close(parent) } }
        var folder = stat()
        guard fstat(parent, &folder) == 0, folder.st_uid == geteuid(), folder.st_mode & 0o077 == 0 else {
            throw Issue.unavailable
        }
        descriptor = try Self.lock(Self.name, in: parent, installing ? LOCK_EX : LOCK_SH, create: true)
        directoryDescriptor = parent
        self.installing = installing
        keepParent = true
    }

    deinit {
        // An inherited reference must retain the lock after the application closes its copy.
        close(descriptor)
        close(directoryDescriptor)
    }

    static func lock(_ name: String, in parent: Int32, _ mode: Int32, create: Bool = false) throws -> Int32 {
        let options = O_RDWR | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK | (create ? O_CREAT : 0)
        let fd = openat(parent, name, options, 0o600)
        guard fd >= 0 else { throw Issue.unavailable }
        var valid = false
        defer { if !valid { close(fd) } }
        var file = stat()
        guard fstat(fd, &file) == 0, file.st_mode & S_IFMT == S_IFREG, file.st_uid == geteuid(),
              file.st_mode & 0o077 == 0, file.st_nlink == 1 else { throw Issue.unavailable }
        guard flock(fd, mode | LOCK_NB) == 0 else {
            if errno == EWOULDBLOCK { throw Issue.busy }
            throw Issue.unavailable
        }
        var current = stat()
        guard fstatat(parent, name, &current, AT_SYMLINK_NOFOLLOW) == 0,
              current.st_dev == file.st_dev, current.st_ino == file.st_ino else { throw Issue.unavailable }
        valid = true
        return fd
    }

    static func legacyProjectLocks(_ names: [String], in directory: Int32) throws -> [Int32] {
        var locks: [Int32] = []
        do {
            for name in names where name.hasSuffix(".lock") && name != "installation.lock" && name != Self.name {
                locks.append(try lock(name, in: directory, LOCK_EX))
            }
            return locks
        } catch {
            locks.forEach { close($0) }
            throw error
        }
    }

    func beginWorker() throws -> String {
        let marker = Self.workerPrefix + UUID().uuidString
        let fd = openat(directoryDescriptor, marker, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw Issue.unavailable }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        do {
            if let boot = Self.bootSession { try handle.write(contentsOf: Data(boot.uuidString.utf8)) }
            guard fcntl(fd, F_FULLFSYNC, 0) == 0, fsync(directoryDescriptor) == 0 else { throw Issue.unavailable }
        } catch {
            _ = Self.finishWorker(marker, in: directoryDescriptor)
            throw error
        }
        return marker
    }

    // Only an earlier OS boot proves that an unconfirmed process and all its descendants are gone.
    // The caller must first rule out durable recovery risks and hold the exclusive namespace lease.
    func reconcileWorkers(_ names: [String]) throws {
        let markers = names.filter { $0.hasPrefix(Self.workerPrefix) }
        guard !markers.isEmpty else { return }
        guard installing, let boot = Self.bootSession else { throw Issue.workersUnconfirmed }
        for marker in markers {
            guard Self.isWorkerMarker(marker), try markerPredatesBoot(marker, boot: boot) else {
                throw Issue.workersUnconfirmed
            }
        }
        for marker in markers {
            guard Self.finishWorker(marker, in: directoryDescriptor) else { throw Issue.workersUnconfirmed }
        }
    }

    private func markerPredatesBoot(_ marker: String, boot: UUID) throws -> Bool {
        let descriptor = openat(directoryDescriptor, marker, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard descriptor >= 0 else { return false }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_uid == geteuid(), info.st_mode & 0o077 == 0, info.st_nlink == 1, info.st_size == 36,
              let data = try handle.read(upToCount: 37), data.count == 36,
              let text = String(data: data, encoding: .utf8), let markerBoot = UUID(uuidString: text) else { return false }
        return markerBoot != boot
    }

    static func finishWorker(_ marker: String, in directory: Int32) -> Bool {
        guard isWorkerMarker(marker) else { return false }
        return unlinkat(directory, marker, 0) == 0 && fsync(directory) == 0
    }

    private static func isWorkerMarker(_ marker: String) -> Bool {
        marker.hasPrefix(workerPrefix) && UUID(uuidString: String(marker.dropFirst(workerPrefix.count))) != nil
    }
}
