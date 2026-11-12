import Darwin
import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class ProjectConcurrencyTests: XCTestCase {
    func testStopWaitsForSameGroupDescendantAndBlocksAliasSwitchAndRetry() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: Self.wrapper)
        let competitor = fixture.session(store: store)
        let alias = fixture.base.appending(path: "Project Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        XCTAssertTrue(competitor.open(alias))
        competitor.select("sample-flutter-app(prod)")

        try fixture.select("prod", in: session)
        session.run()
        try await fixture.waitFor("debug-started")
        try await fixture.waitFor("descendant-active")
        session.run()
        XCTAssertFalse(session.open(other.project))
        session.stop()
        try await fixture.waitFor("wrapper-exited")
        let descendant = try XCTUnwrap(Int32(String(contentsOf: fixture.state("descendant-pid"), encoding: .utf8)))
        XCTAssertGreaterThan(getpgid(descendant), 0)
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertTrue(session.isBusy)
        competitor.run()
        XCTAssertFalse(competitor.isBusy)
        XCTAssertTrue(competitor.message?.contains("项目锁") == true)

        let retry = fixture.session(store: store)
        XCTAssertTrue(retry.openRecoveryProject())
        retry.retryRecovery()
        XCTAssertFalse(retry.isBusy)
        XCTAssertTrue(retry.message?.contains("项目锁") == true)
        XCTAssertEqual(try fixture.marker(), "prod\n")

        try Data().write(to: fixture.state("release-descendant"))
        await session.waitUntilIdle()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("descendant-exited").path))
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(session.project?.path, try ProjectLocation.directory(fixture.project).path)
        XCTAssertTrue(session.open(other.project))
    }

    func testClosedParentControlPipeKeepsWorkerLeaseUntilDescendantExits() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let root = try ProjectLocation.directory(fixture.project)
        let alias = fixture.base.appending(path: "Project Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        var lease: ProjectLease? = try store.lease(for: root)
        let command = SessionCommand(executable: "/bin/sh", arguments: ["-c", Self.wrapper],
                                     directory: root.path, environment: fixture.environment)
        let process = try SessionProcessRunner.bundled.start(command, lease: XCTUnwrap(lease))
        try await fixture.waitFor("descendant-active")
        try await fixture.waitFor("debug-started")
        // Drop the launching process's lease and signal EOF on its control channel.
        lease = nil
        process.stop()
        try await fixture.waitFor("wrapper-exited")
        XCTAssertThrowsError(try store.lease(for: alias))
        try Data().write(to: fixture.state("release-descendant"))
        let result = await process.wait()
        XCTAssertEqual(result.exit, .exited(0))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("descendant-exited").path))
        XCTAssertNoThrow(try store.lease(for: alias))
    }

    func testNormalTerminationWaitsForPostAndRejectsUnresolvedRisk() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """)
        try fixture.select("prod", in: session)
        try Data().write(to: fixture.state("fail-before-test"))
        session.run()
        try await fixture.waitFor("debug-started")
        let rejected = await session.finishForTermination()
        XCTAssertFalse(rejected)
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertNotNil(session.recovery)
        try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
        session.retryRecovery()
        let accepted = await session.finishForTermination()
        XCTAssertTrue(accepted)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(session.recovery)
    }

    func testStopBeforeDispatchLeavesEnvironmentAndRecordUntouched() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try "dev\n".write(to: fixture.state("firebase-environment"), atomically: true, encoding: .utf8)
        try fixture.select("prod", in: session)
        session.run()
        session.stop()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "dev\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testAlreadyOpenSecondInstanceCannotRunRenamedProjectWithOutstandingRisk() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let second = fixture.session(store: store)
        let first = fixture.session(store: store)
        try Data().write(to: fixture.state("fail-after-prod"))
        try fixture.select("prod", in: first)
        first.run()
        await first.waitUntilIdle()
        XCTAssertNotNil(first.recovery)
        let renamed = fixture.base.appending(path: "Renamed Flutter Sample", directoryHint: .isDirectory)
        try FileManager.default.moveItem(at: fixture.project, to: renamed)
        try FileManager.default.removeItem(at: renamed.appending(path: ".runlet-fixture/fail-after-prod"))
        XCTAssertTrue(second.open(renamed))
        second.select("sample-flutter-app(prod)")
        second.run()
        await second.waitUntilIdle()
        XCTAssertEqual(second.recovery?.projectPath, first.recovery?.projectPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: renamed.appending(path: ".runlet-fixture/debug-started").path))
        XCTAssertEqual(try String(contentsOf: renamed.appending(path: ".runlet-fixture/firebase-environment"), encoding: .utf8), "prod\n")
    }

    private static let wrapper = """
        (
            trap '' TERM
            : > .runlet-fixture/descendant-active
            n=0
            while [ ! -f .runlet-fixture/release-descendant ] && [ "$n" -lt 100 ]; do
                /bin/sleep 0.05
                n=$((n + 1))
            done
            : > .runlet-fixture/descendant-exited
        ) &
        printf '%s' "$!" > .runlet-fixture/descendant-pid
        trap ': > .runlet-fixture/wrapper-exited; exit 0' TERM
        : > .runlet-fixture/debug-started
        while :; do /bin/sleep 0.05; done
        """
}
