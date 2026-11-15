import Darwin
import Foundation

final class UpdateActivityLease: Sendable {
    enum Issue: Error { case unavailable, busy, workersUnconfirmed }

    static let name = "update-activity.lock"
    let descriptor: Int32
    let directoryDescriptor: Int32

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

    func beginWorker() throws -> String {
        let marker = "update-worker-\(UUID().uuidString)"
        let fd = openat(directoryDescriptor, marker, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw Issue.unavailable }
        defer { close(fd) }
        guard fcntl(fd, F_FULLFSYNC, 0) == 0, fsync(directoryDescriptor) == 0 else { throw Issue.unavailable }
        return marker
    }

    static func finishWorker(_ marker: String, in directory: Int32) -> Bool {
        let prefix = "update-worker-"
        guard marker.hasPrefix(prefix), UUID(uuidString: String(marker.dropFirst(prefix.count))) != nil else { return false }
        return unlinkat(directory, marker, 0) == 0 && fsync(directory) == 0
    }
}
