import AppKit
import Darwin
import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class UpdateInstallGateTests: XCTestCase {
    func testLegacyProjectLeaseAndUnreadableRecoveryBlockInstallation() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        let canonical = try ProjectLocation.directory(fixture.project)
        var oldLease: ProjectLease? = try ProjectLease(project: canonical, lockDirectory: store.directory)
        XCTAssertEqual(session.updateBlocker, .processUnconfirmed)
        XCTAssertTrue(try store.allRecords().isEmpty)
        XCTAssertNotNil(oldLease)
        oldLease = nil
        XCTAssertNil(session.updateBlocker)

        let corrupt = store.directory.appending(path: "damaged.risk")
        try Data("illegible".utf8).write(to: corrupt)
        XCTAssertEqual(chmod(corrupt.path, 0o600), 0)
        XCTAssertEqual(session.updateBlocker, .recoveryUnreadable)
        try FileManager.default.removeItem(at: corrupt)
        XCTAssertNil(session.updateBlocker)
    }

    func testReservationRejectsRunAndNormalAppKitQuit() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        let termination = AppTermination()
        termination.session = session
        var reservation: UpdateReservation? = try await session.reserveUpdate(productID: XCTUnwrap(RunningUpdateApp()).productID)
        XCTAssertNotNil(reservation)
        XCTAssertEqual(termination.applicationShouldTerminate(.shared), .terminateCancel)
        XCTAssertFalse(session.canRun)
        session.run()
        XCTAssertTrue(try store.allRecords().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        reservation = nil
        session.releaseUpdateReservation()
        XCTAssertTrue(session.canRun)
    }

    func testInheritedWorkerKeepsNamespaceReservedAfterCallerDropsItsProjectLease() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let canonical = try ProjectLocation.directory(fixture.project)
        var lease: ProjectLease? = try store.lease(for: canonical)
        let command = SessionCommand(executable: "/bin/sh", arguments: ["-c", """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """], directory: canonical.path, environment: fixture.environment)
        let process = try SessionProcessRunner.bundled.start(command, lease: XCTUnwrap(lease))
        try await fixture.waitFor("debug-started")
        lease = nil
        XCTAssertThrowsError(try UpdateActivityLease(directory: store.directory, installing: true))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: store.directory.path)
            .contains { $0.hasPrefix("update-worker-") })
        process.stop()
        let result = await process.wait()
        XCTAssertEqual(result.exit, .exited(0))
        XCTAssertNoThrow(try UpdateActivityLease(directory: store.directory, installing: true))
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: store.directory.path)
            .contains { $0.hasPrefix("update-worker-") })
    }
}
