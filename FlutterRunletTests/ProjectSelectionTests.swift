import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class ProjectSelectionTests: XCTestCase {
    func testBrokenReloadRetainsStaleSelectionAndDeletingOrDuplicatingNameClearsIt() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let session = fixture.session(store: try ProjectRecoveryStore(directory: fixture.storage))
        try fixture.select("prod", in: session)
        let oldNames = session.choices.map(\.name)
        try fixture.writeLaunch("{ broken")
        session.reload()
        XCTAssertTrue(session.configurationIsStale)
        XCTAssertEqual(session.selection?.name, "sample-flutter-app(prod)")
        XCTAssertEqual(session.choices.map(\.name), oldNames)
        XCTAssertFalse(session.canRun)
        session.select("sample-flutter-app(test)")
        XCTAssertEqual(session.selection?.name, "sample-flutter-app(prod)")

        try fixture.writeLaunch(names: ["other"])
        session.reload()
        XCTAssertFalse(session.configurationIsStale)
        XCTAssertNil(session.selection)
        XCTAssertTrue(session.message.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("不存在") == true)
        session.select("other")
        try fixture.writeLaunch(names: ["other", "other"])
        session.reload()
        XCTAssertNil(session.selection)
        XCTAssertEqual(session.choices.map(\.name), ["other", "other"])
        XCTAssertTrue(session.choices.allSatisfy { $0.launch == nil })
    }

    func testOpeningValidFlutterProjectWithMissingLaunchAndInitialChoiceRules() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let session = fixture.session(store: try ProjectRecoveryStore(directory: fixture.storage))
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNil(session.selection)
        try FileManager.default.removeItem(at: fixture.config("launch"))
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNotNil(session.project)
        XCTAssertTrue(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("launch.json") == true)
        XCTAssertFalse(session.canRun)
        try fixture.writeLaunch(names: ["唯一配置"])
        session.reload()
        XCTAssertEqual(session.selection?.name, "唯一配置")
        try fixture.writeLaunch(names: [])
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNil(session.selection)
    }

    func testRunRequiresSecondClickAfterEffectiveChangeButIgnoresCommentAndUnrelatedTask() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        let launch = try String(contentsOf: fixture.config("launch"), encoding: .utf8)
        let changed = launch.replacingOccurrences(of: "APP_ENV=prod", with: "APP_ENV=changed")
        try fixture.writeLaunch(changed)
        session.run()
        await session.waitUntilIdle()
        XCTAssertTrue(session.message.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("再次") == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertNil(try store.read(project: fixture.project))

        let tasks = try String(contentsOf: fixture.config("tasks"), encoding: .utf8)
        try fixture.writeLaunch("// comment\n" + changed)
        try tasks.replacingOccurrences(of: "select-dev", with: "unrelated-task").write(
            to: fixture.config("tasks"), atomically: true, encoding: .utf8
        )
        session.run()
        await session.waitUntilIdle()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertEqual(try fixture.marker(), "test\n")
    }

    func testRecentProjectPreferenceReadsDiskAndNeverRunsTasks() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let name = "FlutterRunletTests.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertTrue(session.open(fixture.project))
        try fixture.writeLaunch(names: ["重新读取"])
        let restarted = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertEqual(restarted.project?.path, session.project?.path)
        XCTAssertEqual(restarted.selection?.name, "重新读取")
        restarted.rememberRecentProject = false
        XCTAssertNotNil(restarted.project)
        let disabled = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertNil(disabled.project)
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.marker(), "test\n")
    }

    func testRecentHistoryMigratesAndRemembersCanonicalProjectsInOpeningOrder() throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let suite = "FlutterRunletTests.History.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let alias = fixture.base.appending(path: "Project Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        let first = try ProjectLocation.directory(fixture.project)
        let second = try ProjectLocation.directory(other.project)
        preferences.set(false, forKey: "rememberRecentProject")
        preferences.set(alias.path, forKey: "recentProjectPath")

        func restart() -> SessionController {
            SessionController(store: store, runner: .bundled, preferences: preferences)
        }

        let session = restart()
        XCTAssertTrue(session.canChangeProject)
        XCTAssertNil(session.project)
        XCTAssertEqual(session.recentProjects.map(\.path), [first.path])
        XCTAssertTrue(session.open(other.project))
        XCTAssertTrue(session.open(alias))
        XCTAssertEqual(session.recentProjects.map(\.path), [first.path, second.path])
        XCTAssertTrue(session.open(session.recentProjects[1]))
        XCTAssertEqual(session.project?.path, second.path)
        XCTAssertEqual(session.recentProjects.map(\.path), [second.path, first.path])

        let unremembered = restart()
        XCTAssertNil(unremembered.project)
        XCTAssertEqual(unremembered.recentProjects.map(\.path), [second.path, first.path])
        unremembered.rememberRecentProject = true
        XCTAssertEqual(restart().project?.path, second.path)

        session.removeRecentProject(second)
        XCTAssertEqual(session.project?.path, second.path)
        XCTAssertEqual(session.recentProjects.map(\.path), [first.path])
        XCTAssertNil(restart().project)
        session.removeRecentProject(first)
        XCTAssertEqual(session.project?.path, second.path)
        XCTAssertTrue(restart().recentProjects.isEmpty)
        XCTAssertNil(try store.read(project: first))
        XCTAssertNil(try store.read(project: second))
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertEqual(try other.marker(), "test\n")
    }

    func testInvalidDirectoryDoesNotReplaceProjectOrEnterHistory() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let session = fixture.session(store: try ProjectRecoveryStore(directory: fixture.storage))
        XCTAssertTrue(session.open(fixture.project))
        let project = session.project
        XCTAssertFalse(session.open(fixture.base))
        XCTAssertEqual(session.project, project)
        XCTAssertEqual(session.recentProjects, [try XCTUnwrap(project)])
    }

    func testUnavailableLegacyProjectMigratesWhenItsDirectoryReturns() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let suite = "FlutterRunletTests.History.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let canonical = try ProjectLocation.directory(fixture.project)
        let displaced = fixture.base.appending(path: "Unmounted Project")
        preferences.set(canonical.path, forKey: "recentProjectPath")
        try FileManager.default.moveItem(at: canonical, to: displaced)

        func restart() -> SessionController {
            SessionController(store: store, runner: .bundled, preferences: preferences)
        }

        let unavailable = restart()
        XCTAssertNil(unavailable.project)
        XCTAssertTrue(unavailable.recentProjects.isEmpty)
        try FileManager.default.moveItem(at: displaced, to: canonical)

        let restored = restart()
        XCTAssertEqual(restored.project, canonical)
        XCTAssertEqual(restored.recentProjects, [canonical])
        restored.removeRecentProject(canonical)
        let afterRemoval = restart()
        XCTAssertNil(afterRemoval.project)
        XCTAssertTrue(afterRemoval.recentProjects.isEmpty)
    }

    func testProjectSwitchRemainsBlockedWhileRunningAndAfterRecoveryFailure() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """)
        XCTAssertTrue(session.open(other.project))
        try fixture.select("prod", in: session)
        let project = try XCTUnwrap(session.project)
        let history = session.recentProjects
        try Data().write(to: fixture.state("fail-before-test"))
        session.run()
        try await fixture.waitFor("debug-started")

        XCTAssertFalse(session.canChangeProject)
        XCTAssertFalse(session.open(history[1]))
        XCTAssertEqual(session.project, project)
        session.stop()
        await session.waitUntilIdle()

        let risk = try XCTUnwrap(store.read(project: project))
        XCTAssertFalse(session.canChangeProject)
        XCTAssertFalse(session.open(history[1]))
        XCTAssertEqual(session.recentProjects, history)
        session.removeRecentProject(project)
        XCTAssertEqual(session.project, project)
        XCTAssertEqual(session.recentProjects, [history[1]])
        XCTAssertEqual(try store.read(project: project), risk)
    }
}

extension SessionFixture {
    func writeLaunch(_ source: String) throws {
        try source.write(to: config("launch"), atomically: true, encoding: .utf8)
    }

    func writeLaunch(names: [String]) throws {
        let items = names.map { ["name": $0, "type": "dart", "request": "launch"] }
        try JSONSerialization.data(withJSONObject: ["configurations": items]).write(to: config("launch"))
    }
}
