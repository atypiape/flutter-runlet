import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class SessionLifecycleTests: XCTestCase {
    func testConfirmedQuitWaitsForPausedRecoveryAndCancelsContinuation() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        try Data().write(to: fixture.state("fail-before-test"))
        session.run()
        await session.waitUntilIdle()
        let files = FileManager.default
        try files.removeItem(at: fixture.state("debug-started"))
        try files.removeItem(at: fixture.state("fail-before-test"))
        let pause = fixture.state("pause-after-test")
        try Data().write(to: pause)
        defer { try? files.removeItem(at: pause) }
        session.select("sample-flutter-app(dev)")
        session.runAfterRecovery()
        try await fixture.waitFor("paused-after-test")
        XCTAssertFalse(session.canChangeProject)
        XCTAssertFalse(session.canRunAfterRecovery)
        XCTAssertFalse(session.canPerformRecoveryAction)
        XCTAssertThrowsError(try store.lease(for: fixture.project))
        session.runAfterRecovery()
        session.retryRecovery()

        session.beginFinishingTermination()
        let quit = Task { await session.finishForTermination() }
        XCTAssertNotNil(try store.read(project: fixture.project))
        try files.removeItem(at: pause)
        let exitedSafely = await quit.value
        XCTAssertTrue(exitedSafely)
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertFalse(files.fileExists(atPath: fixture.state("debug-started").path))
    }

    func testConfirmedQuitDuringRecoveryContinuationPreflightPreventsLaunch() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let files = FileManager.default
        let executable = fixture.base.appending(path: "flutter")
        try "#!/bin/sh\n: > .runlet-fixture/debug-started\n".write(to: executable, atomically: true, encoding: .utf8)
        try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let sdk = FlutterSDK(executable: executable, flutterVersion: "test", dartVersion: "test")
        let device = FlutterDevice(id: "fixture", name: "Fixture", platform: "ios", isSimulator: true)
        var holdDiscovery = false
        var continueDiscovery: CheckedContinuation<Void, Never>?
        let toolchain = FlutterToolchain(resolve: { _, _, _ in sdk }, discover: { _, _ in
            if holdDiscovery { await withCheckedContinuation { continueDiscovery = $0 } }
            return [device]
        })
        let session = SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                        toolchain: toolchain)
        try fixture.select("prod", in: session)
        let startDeadline = ContinuousClock.now + .seconds(5)
        while !session.canRun, .now < startDeadline { try await Task.sleep(for: .milliseconds(20)) }
        XCTAssertTrue(session.canRun)
        try Data().write(to: fixture.state("fail-before-test"))
        session.run()
        await session.waitUntilIdle()
        try files.removeItem(at: fixture.state("debug-started"))
        try files.removeItem(at: fixture.state("fail-before-test"))
        session.select("sample-flutter-app(dev)")
        holdDiscovery = true
        session.runAfterRecovery()
        let preflightDeadline = ContinuousClock.now + .seconds(5)
        while continueDiscovery == nil, .now < preflightDeadline { try await Task.sleep(for: .milliseconds(20)) }
        let resume = try XCTUnwrap(continueDiscovery)
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertThrowsError(try store.lease(for: fixture.project))
        session.beginFinishingTermination()
        let quit = Task { await session.finishForTermination() }
        resume.resume()
        let exitedSafely = await quit.value
        XCTAssertTrue(exitedSafely)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertFalse(files.fileExists(atPath: fixture.state("debug-started").path))
    }

    func testPublicProdRunsPreWaitsForGroupExitAndRestoresOriginalPost() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let original = try fixture.configurationBytes()
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let debug = SessionCommand(executable: "/bin/sh", arguments: ["-c", """
            test -f "$1" || exit 91
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """, "fixture", try store.recordURL(for: fixture.project).path], directory: fixture.project.path, environment: fixture.environment)
        let session = SessionController(store: store, runner: .bundled, debugCommand: { _ in debug })
        try fixture.select("prod", in: session)
        XCTAssertTrue(session.canRun, session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) } ?? "无有效配置")
        session.run()
        session.run()
        do {
            try await fixture.waitFor("debug-started")
        } catch {
            XCTFail("\(session.status) / \(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) } ?? "") / \(session.logs)")
            session.stop()
            await session.waitUntilIdle()
            return
        }
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
        session.stop()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.configurationBytes(), original)
    }

    func testStorageSyncFailureBlocksPreAndPostOnlyLaunch() async throws {
        for hasPre in [false, true] {
            for point in [ProjectRecoveryStore.SyncPoint.recordData, .recordDirectory] {
                let fixture = try SessionFixture()
                defer { fixture.remove() }
                if !hasPre { try fixture.removeProdPreTask() }
                let store = try ProjectRecoveryStore(directory: fixture.storage) { current in
                    if current == point { throw SessionIssue("注入同步失败") }
                }
                let session = fixture.session(store: store)
                try fixture.select("prod", in: session)
                session.run()
                await session.waitUntilIdle()
                XCTAssertEqual(try fixture.marker(), "test\n")
                XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
                XCTAssertEqual(try store.read(project: fixture.project) != nil, point == .recordDirectory)
                XCTAssertEqual(session.recovery != nil, point == .recordDirectory)
            }
        }
    }

    func testNoAdapterAndNonDebugLeaveConfigurationAndProjectUntouched() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let ordinary = SessionController(store: store, runner: .bundled)
        try fixture.select("prod", in: ordinary)
        ordinary.run()
        await ordinary.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))

        let launch = try String(contentsOf: fixture.config("launch"), encoding: .utf8)
        try launch.replacingOccurrences(of: #""debug""#, with: #""profile""#).write(
            to: fixture.config("launch"), atomically: true, encoding: .utf8
        )
        let profile = fixture.session(store: store)
        try fixture.select("prod", in: profile)
        profile.run()
        await profile.waitUntilIdle()
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testPostOnlyRecordsRiskAndLaunchFailureRestoresViaRealPost() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        try fixture.removeProdPreTask()
        let debug = fixture.session(store: store, script: """
            test -f "$1" || exit 91
            : > .runlet-fixture/debug-started
            exit 19
            """, arguments: [try store.recordURL(for: fixture.project).path])
        try fixture.select("prod", in: debug)
        debug.run()
        await debug.waitUntilIdle()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertEqual(debug.message.map { Locale(identifier: "zh-Hans").appString($0) }, "调试进程：退出码 19")
        XCTAssertNil(try store.read(project: fixture.project))

        let missing = SessionController(store: store, runner: .bundled) { launch in
            SessionCommand(executable: "/no-such-runlet-test-program", arguments: [],
                           directory: launch.directory, environment: [:])
        }
        try "prod\n".write(to: fixture.state("firebase-environment"), atomically: true, encoding: .utf8)
        try fixture.select("prod", in: missing)
        missing.run()
        await missing.waitUntilIdle()
        XCTAssertTrue(missing.message.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("进程启动失败") == true)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testPreFailureBeforeWriteAndAfterWriteKeepDifferentRisk() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try Data().write(to: fixture.state("fail-before-dev"))
        try fixture.select("dev", in: session)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertTrue(session.message.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("退出码 1") == true)
        try Data().write(to: fixture.state("fail-after-prod"))
        session.select("sample-flutter-app(prod)")
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertNotNil(try store.read(project: fixture.project))
        XCTAssertNotNil(session.recovery)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
    }

    func testFixtureRootRunsPublicSampleAndRejectsModifiedScriptAndLinkedState() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, root: fixture.base)
        try fixture.select("prod", in: session)
        XCTAssertTrue(session.canRun, session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) } ?? "")
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))

        let script = fixture.project.appending(path: "scripts/simulate-firebase-switch.sh")
        try "#!/bin/sh\nexit 0\n".write(to: script, atomically: true, encoding: .utf8)
        let restarted = fixture.session(store: store, root: fixture.base)
        try fixture.select("prod", in: restarted)
        XCTAssertFalse(restarted.canRun)
        let state = fixture.state("firebase-environment")
        try FileManager.default.removeItem(at: state)
        try FileManager.default.createSymbolicLink(at: state, withDestinationURL: fixture.config("tasks"))
        XCTAssertFalse(restarted.open(fixture.project))
    }

    func testFixtureAssemblyRequiresExactFlagAndRejectsOutsideProjectAlias() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let root = fixture.base.appending(path: "projects")
        let alias = root.appending(path: "outside alias")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        XCTAssertFalse(SessionController.fixtureEnabled(arguments: ["--phase-02-fixture=1"]))
        XCTAssertTrue(SessionController.fixtureEnabled(arguments: ["--phase-02-fixture"]))
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, allowedRoot: root, debugCommand: { _ in
            XCTFail("越界项目不得准备进程")
            return nil
        })
        XCTAssertFalse(session.open(fixture.project))
        XCTAssertFalse(session.open(alias))
        session.run()
        XCTAssertNil(session.project)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testRestrictedFixturePausesAfterBothWritesBeforeAcknowledgingSuccess() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let files = FileManager.default
        let prePause = fixture.state("pause-after-prod")
        let postPause = fixture.state("pause-after-test")
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """, root: fixture.base)
        try fixture.select("prod", in: session)
        try Data().write(to: prePause)
        try Data().write(to: postPause)
        session.run()
        do {
            try await fixture.waitFor("paused-after-prod")
            XCTAssertEqual(session.status, .runningPreTask)
            XCTAssertEqual(try fixture.marker(), "prod\n")
            XCTAssertFalse(files.fileExists(atPath: fixture.state("debug-started").path))
            XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
            try files.removeItem(at: prePause)
            try await fixture.waitFor("debug-started")

            session.stop()
            try await fixture.waitFor("paused-after-test")
            XCTAssertEqual(session.status, .restoringEnvironment)
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNotNil(try store.read(project: fixture.project))
            try files.removeItem(at: postPause)
        } catch {
            try? files.removeItem(at: prePause)
            try? files.removeItem(at: postPause)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(session.status, .ready)
    }
}

@MainActor
struct SessionFixture {
    let base: URL
    let project: URL
    let storage: URL
    let environment = ["PATH": "/usr/bin:/bin"]

    init() throws {
        base = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appending(path: "Runlet \(UUID())")
        project = base.appending(path: "Public Flutter Sample", directoryHint: .isDirectory)
        storage = base.appending(path: "storage")
        let files = FileManager.default
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "docs/examples/sample-flutter-app")
        for name in [".vscode", "scripts", "lib", ".runlet-fixture"] {
            try files.createDirectory(at: project.appending(path: name), withIntermediateDirectories: true)
        }
        for name in ["launch", "tasks"] {
            try files.copyItem(at: source.appending(path: "\(name).jsonc"), to: config(name))
        }
        try files.copyItem(at: source.appending(path: "scripts/simulate-firebase-switch.sh"),
                           to: project.appending(path: "scripts/simulate-firebase-switch.sh"))
        try "name: sample\ndependencies:\n  flutter:\n    sdk: flutter\n".write(to: project.appending(path: "pubspec.yaml"), atomically: true, encoding: .utf8)
        try "void main() {}\n".write(to: project.appending(path: "lib/main.dart"), atomically: true, encoding: .utf8)
        try "test\n".write(to: state("firebase-environment"), atomically: true, encoding: .utf8)
    }

    func config(_ name: String) -> URL { project.appending(path: ".vscode/\(name).json") }
    func state(_ name: String) -> URL { project.appending(path: ".runlet-fixture/\(name)") }
    func configurationBytes() throws -> [Data] { try ["launch", "tasks"].map { try Data(contentsOf: config($0)) } }
    func marker() throws -> String { try String(contentsOf: state("firebase-environment"), encoding: .utf8) }
    func remove() { try? FileManager.default.removeItem(at: base) }

    func select(_ mode: String, in session: SessionController) throws {
        XCTAssertTrue(session.open(project))
        session.select("sample-flutter-app(\(mode))")
    }

    func session(store: ProjectRecoveryStore, script: String = ": > .runlet-fixture/debug-started",
                 arguments: [String] = [], root: URL? = nil) -> SessionController {
        SessionController(store: store, runner: .bundled, allowedRoot: root, environment: environment) { launch in
            SessionCommand(executable: "/bin/sh", arguments: ["-c", script, "fixture"] + arguments,
                           directory: launch.project.path, environment: environment)
        }
    }

    func removeProdPreTask() throws {
        let url = config("launch")
        let source = try String(contentsOf: url, encoding: .utf8)
        let line = #"      "preLaunchTask": "sample:select-prod","# + "\n"
        try source.replacingOccurrences(of: line, with: "").write(to: url, atomically: true, encoding: .utf8)
    }

    func waitFor(_ name: String) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !FileManager.default.fileExists(atPath: state(name).path) {
            guard ContinuousClock.now < deadline else {
                throw NSError(domain: "Fixture timeout: \(name)", code: 1)
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
