import Darwin
import Foundation
import XCTest
@testable import FlutterRunlet

final class UpdateTransactionTests: XCTestCase {
    func testInstallReservationBlocksProjectActivityInAnotherStore() throws {
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let recovery = root.appending(path: "Recovery", directoryHint: .isDirectory)
        let project = root.appending(path: "Project", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: false)
        let store = try ProjectRecoveryStore(directory: recovery)
        let peer = try ProjectRecoveryStore(directory: recovery)
        let lock = open(store.directory.appending(path: "update-activity.lock").path,
                        O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
        XCTAssertGreaterThanOrEqual(lock, 0)
        guard lock >= 0 else { return }
        defer { close(lock) }
        XCTAssertEqual(flock(lock, LOCK_EX | LOCK_NB), 0)
        XCTAssertThrowsError(try peer.lease(for: project), "An install reservation must block project activity")
        XCTAssertEqual(flock(lock, LOCK_UN), 0)
        XCTAssertNoThrow(try peer.lease(for: project))
    }
}
