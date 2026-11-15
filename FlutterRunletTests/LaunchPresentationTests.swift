import ServiceManagement
import SwiftUI
import XCTest
@testable import FlutterRunlet

final class LaunchPresentationTests: XCTestCase {
    @MainActor
    func testGeneralSettingsGeometryAndLaunchSwitchUseHostedPreference() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let suite = "FlutterRunletTests.Settings.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, preferences: defaults)
        let settings = SettingsView(session: session, selection: .constant(.general),
                                    language: AppLanguageSettings(defaults: defaults))
        let host = NSHostingView(rootView: settings)
        XCTAssertEqual(host.fittingSize, CGSize(width: 520, height: 520))
        let launchSwitch = Binding(get: { settings.session?.showMainWindowOnLaunch ?? false },
                                   set: { settings.session?.showMainWindowOnLaunch = $0 })
        XCTAssertTrue(launchSwitch.wrappedValue)
        launchSwitch.wrappedValue = false
        let restarted = SessionController(store: store, runner: .bundled, preferences: defaults)
        XCTAssertFalse(restarted.shouldPresentMainWindowOnLaunch)
    }

    func testAboutInformationUsesHostedAppBundleAndConfirmedLinks() throws {
        let information = AboutInformation()
        XCTAssertEqual(try XCTUnwrap(information.version),
                       try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String))
        XCTAssertEqual(try XCTUnwrap(information.buildNumber),
                       try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String))
        XCTAssertEqual(AboutInformation.upstreamCopyright, "Copyright (c) 2026 huseyiniriss")

        for (destination, expected) in [
            (AboutInformation.Destination.project, "https://github.com/atypiape/flutter-runlet"),
            (.documentation, "https://github.com/atypiape/flutter-runlet/blob/main/README.md"),
            (.license, "https://github.com/atypiape/flutter-runlet/blob/main/LICENSE")
        ] {
            XCTAssertEqual(destination.url.absoluteString, expected)
            XCTAssertEqual(destination.url.scheme, "https")
        }
    }

    func testAboutWindowHasBothBundleTranslations() throws {
        let english = try XCTUnwrap(Bundle.main.url(forResource: "en", withExtension: "lproj"))
        let chinese = try XCTUnwrap(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let englishBundle = try XCTUnwrap(Bundle(url: english))
        let chineseBundle = try XCTUnwrap(Bundle(url: chinese))
        for (key, translation) in [
            ("Lightweight Flutter debugging for macOS.", "macOS 上的轻量 Flutter 调试工具。"),
            ("Inspired by Flutter GUI Runner", "灵感来自 Flutter GUI Runner"),
            ("MIT License", "MIT 许可证"),
            ("Project Home", "项目主页"),
            ("Documentation", "使用文档"),
            ("Project License", "项目许可证")
        ] {
            XCTAssertEqual(englishBundle.localizedString(forKey: key, value: "<missing>", table: nil), key)
            XCTAssertEqual(chineseBundle.localizedString(forKey: key, value: "<missing>", table: nil), translation)
        }
    }

    func testMainWindowLaunchPreferenceHasBothBundleTranslations() throws {
        for (language, expected) in [
            ("en", "Show Main Window on Launch"), ("zh-Hans", "启动后显示主窗口")
        ] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            XCTAssertEqual(bundle.localizedString(forKey: "Show Main Window on Launch", value: "<missing>", table: nil),
                           expected)
        }
    }

    func testLoginItemPendingApprovalHasActionableCopy() throws {
        let key = "Allow FlutterRunlet to launch at login in System Settings."
        for (language, expected) in [
            ("en", key), ("zh-Hans", "请在系统设置中允许 FlutterRunlet 登录时启动。")
        ] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            XCTAssertEqual(bundle.localizedString(forKey: key, value: "<missing>", table: nil), expected)
        }
    }

    @MainActor
    func testLoginItemUsesSystemStatusAndOnlyWritesOnExplicitChanges() {
        var systemStatus = SMAppService.Status.notRegistered
        var calls: [String] = []
        let loginItem = LoginItemSettings(
            readStatus: { systemStatus },
            register: { calls.append("register"); systemStatus = .requiresApproval },
            unregister: { calls.append("unregister"); systemStatus = .notRegistered }
        )
        XCTAssertFalse(loginItem.isRegistered)
        XCTAssertTrue(loginItem.canChange)
        XCTAssertTrue(calls.isEmpty)
        loginItem.setRegistered(false)
        XCTAssertTrue(calls.isEmpty)

        loginItem.setRegistered(true)
        XCTAssertEqual(calls, ["register"])
        XCTAssertEqual(loginItem.status, .requiresApproval)
        XCTAssertTrue(loginItem.isRegistered)
        XCTAssertNotNil(loginItem.statusMessage)
        XCTAssertNil(loginItem.issue)
        systemStatus = .enabled
        loginItem.refresh()
        XCTAssertTrue(loginItem.isRegistered)
        XCTAssertNil(loginItem.statusMessage)
        XCTAssertEqual(calls, ["register"])

        systemStatus = .requiresApproval
        loginItem.setRegistered(false)
        XCTAssertEqual(calls, ["register", "unregister"])
        XCTAssertFalse(loginItem.isRegistered)
        systemStatus = .notFound
        loginItem.refresh()
        XCTAssertTrue(loginItem.canChange)
        XCTAssertFalse(loginItem.isRegistered)
        XCTAssertEqual(calls, ["register", "unregister"])
        loginItem.setRegistered(true)
        XCTAssertEqual(calls, ["register", "unregister", "register"])
        XCTAssertEqual(loginItem.status, .requiresApproval)
    }

    @MainActor
    func testLoginItemFailureDoesNotOptimisticallyChangeRegistration() throws {
        let loginItem = LoginItemSettings(
            readStatus: { .notFound },
            register: { throw SessionIssue("test failure") },
            unregister: { XCTFail("Unexpected unregister call") }
        )
        loginItem.setRegistered(true)
        loginItem.refresh()
        XCTAssertFalse(loginItem.isRegistered)
        let issue = try XCTUnwrap(loginItem.issue)
        XCTAssertEqual(Locale(identifier: "zh-Hans").appString(issue),
                       "无法更改登录项：test failure。请检查系统设置中的登录项后重试。")
    }

    @MainActor
    func testMainWindowLaunchPreferencePersistsAndRecoveryTakesPriority() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let suite = "FlutterRunletTests.Startup.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)

        func restart() -> SessionController {
            SessionController(store: store, runner: .bundled, preferences: preferences)
        }

        let first = restart()
        XCTAssertTrue(first.rememberRecentProject)
        XCTAssertTrue(first.showMainWindowOnLaunch)
        XCTAssertTrue(first.shouldPresentMainWindowOnLaunch)
        XCTAssertTrue(first.open(other.project))
        first.showMainWindowOnLaunch = false
        let suppressed = restart()
        XCTAssertFalse(suppressed.shouldPresentMainWindowOnLaunch)
        XCTAssertEqual(suppressed.project, first.project)

        try Data().write(to: fixture.state("fail-before-test"))
        let producer = fixture.session(store: store)
        try fixture.select("prod", in: producer)
        producer.run()
        await producer.waitUntilIdle()
        let record = try XCTUnwrap(producer.recovery)
        XCTAssertEqual(try fixture.marker(), "prod\n")

        let different = restart()
        XCTAssertFalse(different.showMainWindowOnLaunch)
        XCTAssertTrue(different.shouldPresentMainWindowOnLaunch)
        XCTAssertEqual(different.project, first.project)
        XCTAssertEqual(different.recoveryAction, .openProject)
        XCTAssertEqual(different.recovery, record)
        different.rememberRecentProject = false

        let unremembered = restart()
        XCTAssertTrue(unremembered.shouldPresentMainWindowOnLaunch)
        XCTAssertNil(unremembered.project)
        XCTAssertEqual(unremembered.recoveryAction, .openProject)
        unremembered.performRecoveryAction()
        XCTAssertEqual(unremembered.project, producer.project)
        XCTAssertEqual(unremembered.recoveryAction, .retry)
        XCTAssertFalse(unremembered.isBusy)

        unremembered.rememberRecentProject = true
        preferences.set(producer.project?.path, forKey: "recentProjectPath")
        let matching = restart()
        XCTAssertTrue(matching.shouldPresentMainWindowOnLaunch)
        XCTAssertEqual(matching.project, producer.project)
        XCTAssertEqual(matching.recoveryAction, .retry)
        XCTAssertFalse(matching.isBusy)
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertEqual(try store.read(project: fixture.project), record)
    }

    @MainActor
    func testLanguageSelectionBindingUpdatesSharedRunCopyAndPersists() throws {
        let suite = "FlutterRunletTests.Language.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let language = AppLanguageSettings(defaults: defaults, preferredLanguages: { ["fr-CA", "zh-SG", "en"] })
        let settings = SettingsView(selection: .constant(.general), language: language)

        XCTAssertEqual(language.selection, .system)
        XCTAssertEqual(language.locale.appString(DebugControls.runTitle), "运行")
        XCTAssertEqual(language.locale.appString(DebugControls.runAccessibilityLabel), "运行当前调试配置")

        let pickerSelection = Bindable(settings.language).selection
        pickerSelection.wrappedValue = .english
        XCTAssertEqual(language.locale.appString(DebugControls.runTitle), "Run")
        XCTAssertEqual(language.locale.appString(DebugControls.runAccessibilityLabel), "Run Current Debug Configuration")
        XCTAssertEqual(AppLanguageSettings(defaults: defaults, preferredLanguages: { ["zh-Hans"] }).selection, .english)

        pickerSelection.wrappedValue = .simplifiedChinese
        XCTAssertEqual(AppLanguageSettings(defaults: defaults).selection, .simplifiedChinese)
        defaults.set("unknown", forKey: AppLanguageSettings.preferenceKey)
        XCTAssertEqual(AppLanguageSettings(defaults: defaults).selection, .system)
    }

    func testFollowSystemSelectsFirstSupportedLanguageOrEnglish() {
        XCTAssertEqual(AppLanguage.system.resolve(preferredLanguages: ["fr", "en-GB", "zh-Hans"]), .english)
        XCTAssertEqual(AppLanguage.system.resolve(preferredLanguages: ["zh-Hant", "zh-CN", "en"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.system.resolve(preferredLanguages: ["zh-Hant-CN", "zh-HK", "fr"]), .english)
        XCTAssertEqual(AppLanguage.system.resolve(preferredLanguages: ["zh-Hans-TW"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.system.resolve(preferredLanguages: []), .english)
    }

    func testLocalizedMessagesKeepDeviceAndDiagnosticArgumentsVerbatim() {
        let name = "Device \(String(repeating: "长名称", count: 20)) %1$@"
        let diagnostic = "/tmp/项目/Flutter SDK: code %2$d"
        let offline: LocalizedStringResource = "\(name) · Offline"
        let error: LocalizedStringResource = "Could not use the selected path: \(LocalizedStringResource.verbatim(diagnostic)). The previous setting was kept."
        let chinese = Locale(identifier: "zh-Hans")
        let english = Locale(identifier: "en")

        XCTAssertEqual(chinese.appString(offline), "\(name) · 离线")
        XCTAssertEqual(english.appString(offline), "\(name) · Offline")
        XCTAssertEqual(chinese.appString(error), "无法使用所选路径：\(diagnostic)。原设置已保留。")
        XCTAssertEqual(english.appString(error), "Could not use the selected path: \(diagnostic). The previous setting was kept.")
    }

    func testAppBundleContainsEnglishAndSimplifiedChineseRunCopy() throws {
        let translations = [
            "en": ["Run": "Run", "Run Current Debug Configuration": "Run Current Debug Configuration"],
            "zh-Hans": ["Run": "运行", "Run Current Debug Configuration": "运行当前调试配置"]
        ]
        for (language, messages) in translations {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            for (key, expected) in messages {
                XCTAssertEqual(bundle.localizedString(forKey: key, value: "<missing>", table: nil), expected)
            }
        }
    }

    @MainActor
    func testProjectAndSettingsIconNamesUseBothBundleLanguages() {
        let names: [(LocalizedStringResource, String, String)] = [
            (ProjectControls.historyTitle, "Recent Projects", "历史项目"),
            (ProjectControls.folderTitle, "Open Project", "打开项目"),
            (ProjectControls.removeTitle("App%2$@"), "Remove App%2$@ from Recent Projects", "从历史项目中移除 App%2$@"),
            ("No recent projects", "No recent projects", "暂无历史项目"),
            ("Settings", "Settings", "设置")
        ]
        for (title, english, chinese) in names {
            XCTAssertEqual(Locale(identifier: "en").appString(title), english)
            XCTAssertEqual(Locale(identifier: "zh-Hans").appString(title), chinese)
        }
    }

    func testOrdinaryArgumentsReturnEmpty() {
        XCTAssertEqual(LaunchPresentation.resolve(arguments: []), .empty)
        XCTAssertEqual(LaunchPresentation.resolve(arguments: ["--unrelated"]), .empty)
    }

    @MainActor
    func testRecoveryAndLogButtonsUseBothBundleLanguages() {
        let names: [(LocalizedStringResource, String, String)] = [
            (RecoveryAction.retry.title, "Retry Recovery", "重试恢复"),
            (RecoveryRetryButton.runHint, "Click Run to try recovery and start debugging", "点运行按钮，可尝试恢复并启动"),
            ("Copy Logs", "Copy Logs", "复制日志"),
            ("Clear Logs", "Clear Logs", "清空日志"),
            (MainWindowView.collapseLogsTitle, "Collapse Logs", "折叠日志"),
            (MainWindowView.expandLogsTitle, "Expand Logs", "展开日志")
        ]
        for (title, english, chinese) in names {
            XCTAssertEqual(Locale(identifier: "en").appString(title), english)
            XCTAssertEqual(Locale(identifier: "zh-Hans").appString(title), chinese)
        }
    }

    func testExactDebugFlagReturnsCompleteReadySelection() {
        XCTAssertEqual(
            LaunchPresentation.resolve(arguments: ["--unrelated", "--g1-ready"]),
            .ready(.init(
                project: "sample-flutter-app",
                configuration: "sample-flutter-app(dev)",
                device: "iPhone 17 Pro (iOS Simulator)"
            ))
        )
    }

    func testSimilarArgumentsReturnEmpty() {
        XCTAssertEqual(
            LaunchPresentation.resolve(arguments: ["--g1-ready=true", "--g1-ready-extra", " --g1-ready"]),
            .empty
        )
    }
}
