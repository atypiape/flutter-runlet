import AppKit
import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class FlutterDebugSessionTests: XCTestCase {
    private let chinese = Locale(identifier: "zh-Hans")

    private let device = FlutterDevice(id: "ios-fixture", name: "iPhone 测试模拟器",
                                       platform: "ios", isSimulator: true)

    func testF5ShortcutsHaveExactModifiersAndIgnoreRepeats() {
        let expected: [(NSEvent.ModifierFlags, DebugAction?)] = [
            ([], .run), ([.shift], .stop), ([.option], .reload), ([.shift, .command], .restart),
            ([.command], nil), ([.control], nil), ([.option, .shift], nil)
        ]
        for (flags, action) in expected {
            XCTAssertEqual(DebugAction(keyCode: 96, modifiers: flags, isRepeat: false), action, "F5 modifiers: \(flags)")
            XCTAssertNil(DebugAction(keyCode: 96, modifiers: flags, isRepeat: true))
        }
        XCTAssertNil(DebugAction(keyCode: 48, modifiers: [], isRepeat: false), "Tab remains native")
    }

    func testCurrentMachineAppAndVMVerificationGateProdRecovery() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let original = try fixture.configurationBytes()
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: #"""
            printf '%s\n' "$@" > .runlet-fixture/flutter-args
            printf '%s\n' "$PWD" > .runlet-fixture/flutter-cwd
            printf '%s\n' '[{"event":"app.start","params":{"appId":"current","deviceId":"ios-fixture","mode":"debug"}}]'
            printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"old","wsUri":"ws://127.0.0.1:8181/stale=/ws"}}]'
            printf '%s' 'VM Service: http://127.0.0.1:8181/priv'
            printf '%s\n' 'ate=/'
            printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"current","wsUri":"ws://127.0.0.1:8181/private=/ws"}}]'
            : > .runlet-fixture/debug-started
            IFS= read -r command
            printf '%s\n' "$command" > .runlet-fixture/debug-command
            printf '%s\n' '[{"id":1,"result":true}]'
            (
                /bin/sleep 0.25
                /bin/cat .runlet-fixture/firebase-environment > .runlet-fixture/before-group-exit
            ) &
            exit 0
            """#)
        let session = controller(fixture, store: store, executable: executable) { url in
            XCTAssertEqual(url.absoluteString, "ws://127.0.0.1:8181/private=/ws")
            return FileManager.default.fileExists(atPath: fixture.state("verify-vm").path)
        }
        try fixture.select("prod", in: session)
        do {
            try await eventually { session.devices == [self.device] }
            session.selectDevice(device.id)
            XCTAssertTrue(session.canRun)
            session.run()
            session.run()
            try await fixture.waitFor("debug-started")
            XCTAssertNotEqual(session.status, .running)
            XCTAssertEqual(try fixture.marker(), "prod\n")
            XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
            try Data().write(to: fixture.state("verify-vm"))
            try await eventually { session.vmConnected }
            XCTAssertEqual(session.status, .running)
            XCTAssertTrue(session.logs.contains("127.0.0.1:8181"))
            XCTAssertFalse(session.logs.contains("private="))
            XCTAssertFalse(session.logs.contains("stale="))
            session.stop()
            await session.waitUntilIdle()
            let stop = try String(contentsOf: fixture.state("debug-command"), encoding: .utf8)
            XCTAssertTrue(stop.contains("app.stop"))
            XCTAssertTrue(stop.contains("current"))
            let lastBeforeExit = try String(contentsOf: fixture.state("before-group-exit"), encoding: .utf8)
            XCTAssertEqual(lastBeforeExit, "prod\n")
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
            XCTAssertFalse(session.vmConnected)
            XCTAssertEqual(try fixture.configurationBytes(), original)
            let argv = try String(contentsOf: fixture.state("flutter-args"), encoding: .utf8).split(separator: "\n")
            XCTAssertEqual(argv.filter { $0.hasPrefix("--dart-define=") }, [
                "--dart-define=APP_ENV=prod", "--dart-define=ENABLE_SAMPLE_FEATURE=false",
                "--dart-define=DEMO_BUILD_NUMBER=1001",
            ])
            XCTAssertEqual(argv.filter { $0 == "--machine" }.count, 1)
            XCTAssertTrue(argv.contains("ios-fixture"))
            let directory = try ProjectLocation.directory(fixture.project)
            XCTAssertEqual(try String(contentsOf: fixture.state("flutter-cwd"), encoding: .utf8), directory.path + "\n")
        } catch {
            XCTFail("\(session.status) / \(session.displayMessage.map { chinese.appString($0) } ?? "") / \(session.logs)")
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testInvalidPreflightLeavesEnvironmentAndRiskUntouched() async throws {
        for change in ["missing-sdk", "offline", "discovery-error", "conflict", "non-debug", "edited",
                       "application-args", "duplicate-machine"] {
            let fixture = try SessionFixture()
            defer { fixture.remove() }
            let executable = try makeFlutter(in: fixture, script: ": > .runlet-fixture/debug-started")
            let store = try ProjectRecoveryStore(directory: fixture.storage)
            let discovery = DeviceDiscovery([device])
            let toolchain = FlutterToolchain(
                resolve: { _, _ in
                    guard change != "missing-sdk" else { throw SessionIssue("SDK 不可用") }
                    return FlutterSDK(executable: executable, flutterVersion: "test", dartVersion: "test")
                },
                discover: { _, _ in
                    if discovery.fails { throw SessionIssue("扫描失败") }
                    return discovery.devices
                }
            )
            let session = SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                            toolchain: toolchain)
            var source = try String(contentsOf: fixture.config("launch"), encoding: .utf8)
            let prod = #""name": "sample-flutter-app(prod)","#
            switch change {
            case "conflict":
                source = source.replacingOccurrences(of: prod, with: prod + #" "deviceId": "another","#)
            case "non-debug":
                source = source.replacingOccurrences(of: #""flutterMode": "debug""#, with: #""flutterMode": "release""#)
            case "application-args":
                source = source.replacingOccurrences(of: #""--dart-define=APP_ENV=prod","#,
                                                      with: #""ordinary-arg", "--dart-define=APP_ENV=prod","#)
            case "duplicate-machine":
                source = source.replacingOccurrences(of: prod, with: prod + #" "toolArgs": ["--machine"],"#)
            default: break
            }
            try source.write(to: fixture.config("launch"), atomically: true, encoding: .utf8)
            try fixture.select("prod", in: session)
            if change != "missing-sdk" {
                try await eventually { !session.isRefreshingDevices && session.devices == [self.device] }
                session.selectDevice(device.id)
            }
            if change == "offline" { discovery.devices = [] }
            if change == "discovery-error" { discovery.fails = true }
            if change == "edited" {
                let changed = source.replacingOccurrences(of: "--dart-define=APP_ENV=prod", with: "--dart-define=APP_ENV=changed")
                try changed.write(to: fixture.config("launch"), atomically: true, encoding: .utf8)
            }
            let original = try fixture.configurationBytes()
            session.run()
            await session.waitUntilIdle()
            XCTAssertNotNil(session.displayMessage, change)
            XCTAssertEqual(try fixture.marker(), "test\n", change)
            XCTAssertNil(try store.read(project: fixture.project), change)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path), change)
            XCTAssertEqual(try fixture.configurationBytes(), original, change)
        }
    }

    func testRecoveryContinuationRechecksConfigurationAndDeviceBeforeNewPreTask() async throws {
        for change in ["configuration", "device"] {
            let fixture = try SessionFixture()
            defer { fixture.remove() }
            let executable = try makeFlutter(in: fixture, script: ": > .runlet-fixture/debug-started")
            let store = try ProjectRecoveryStore(directory: fixture.storage)
            let discovery = DeviceDiscovery([device])
            let session = controller(fixture, store: store, executable: executable, discovery: discovery) { _ in false }
            try fixture.select("prod", in: session)
            try await eventually { session.canRun }
            try Data().write(to: fixture.state("fail-before-test"))
            session.run()
            await session.waitUntilIdle()
            XCTAssertEqual(session.status, .recoveryFailed)
            try FileManager.default.removeItem(at: fixture.state("debug-started"))
            try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
            session.select("sample-flutter-app(dev)")
            XCTAssertTrue(session.canRunAfterRecovery)

            if change == "configuration" {
                let url = fixture.config("launch")
                let source = try String(contentsOf: url, encoding: .utf8)
                try source.replacingOccurrences(of: "--dart-define=APP_ENV=dev", with: "--dart-define=APP_ENV=edited")
                    .write(to: url, atomically: true, encoding: .utf8)
            } else {
                discovery.devices = []
            }
            session.runAfterRecovery()
            await session.waitUntilIdle()
            XCTAssertEqual(try fixture.marker(), "test\n", change)
            XCTAssertNil(try store.read(project: fixture.project), change)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path), change)
            XCTAssertNotNil(session.displayMessage, change)
        }
    }

    func testHotOperationsWaitForCurrentFlutterResultAndKeepStopAvailable() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            count=0
            while IFS= read -r command; do
                count=$((count + 1))
                printf '%s\n' "$command" > ".runlet-fixture/command-$count"
                case "$command" in
                    *app.stop*) exit 0 ;;
                esac
                if [ "$count" -eq 3 ]; then continue; fi
                printf '%s\n' '[{"id":999,"result":{"code":0}}]'
                while [ ! -f ".runlet-fixture/reply-$count" ]; do /bin/sleep .02; done
                /bin/cat ".runlet-fixture/reply-$count"
            done
            """#)
        let clock = ControlledDebugClock()
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        XCTAssertFalse(session.performDebugAction(.reload))
        XCTAssertFalse(session.performDebugAction(.stop))
        XCTAssertTrue(session.performDebugAction(.run))
        XCTAssertFalse(session.performDebugAction(.run))
        do {
            try await eventually { session.canHotOperate }
            XCTAssertFalse(session.performDebugAction(.run))
            XCTAssertTrue(session.performDebugAction(.reload))
            XCTAssertFalse(session.performDebugAction(.restart))
            try await fixture.waitFor("command-1")
            XCTAssertFalse(session.canHotOperate)
            XCTAssertTrue(session.canStop)
            XCTAssertNil(session.feedback)
            let reload = try request(fixture, number: 1)
            XCTAssertEqual(reload.method, "app.restart")
            XCTAssertEqual(reload.appID, "current")
            XCTAssertEqual(reload.fullRestart, false)
            try reply(fixture, to: reload.id, number: 1, code: 0)
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "已热重载" }
            XCTAssertTrue(session.canHotOperate)
            let preferences = try XCTUnwrap(UserDefaults(suiteName: "FlutterRunletTests.Feedback.\(UUID().uuidString)"))
            let language = AppLanguageSettings(defaults: preferences)
            defer { preferences.removeObject(forKey: AppLanguageSettings.preferenceKey) }
            language.selection = .simplifiedChinese
            let title = try XCTUnwrap(session.feedback?.title)
            let selectedID = session.selectedID
            let logs = session.logs
            XCTAssertEqual(language.locale.appString(title), "已热重载")
            language.selection = .english
            XCTAssertEqual(language.locale.appString(title), "Hot Reload Completed")
            XCTAssertEqual(session.selectedID, selectedID)
            XCTAssertEqual(session.logs, logs)
            XCTAssertTrue(session.vmConnected)
            XCTAssertTrue(session.canStop)
            session.dismissFeedback()

            XCTAssertTrue(session.performDebugAction(.restart))
            try await fixture.waitFor("command-2")
            let restart = try request(fixture, number: 2)
            XCTAssertEqual(restart.appID, reload.appID)
            XCTAssertEqual(restart.fullRestart, true)
            XCTAssertNotEqual(restart.id, reload.id)
            try reply(fixture, to: restart.id, number: 2, code: 1)
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "热重启未完成" }
            let failure = try XCTUnwrap(session.feedback)
            let detail = try XCTUnwrap(failure.detail)
            XCTAssertEqual(language.locale.appString(failure.title), "Hot Restart Incomplete")
            XCTAssertEqual(language.locale.appString(detail), "Flutter returned error code 1. Check the current debug connection and try again.")
            language.selection = .simplifiedChinese
            XCTAssertEqual(language.locale.appString(failure.title), "热重启未完成")
            XCTAssertEqual(language.locale.appString(detail), "Flutter 返回错误码 1。请确认当前调试连接后重试。")
            XCTAssertTrue(session.vmConnected)
            session.dismissFeedback()

            XCTAssertTrue(session.performDebugAction(.reload))
            try await fixture.waitFor("command-3")
            try await eventually { clock.hasSleeper(.seconds(30)) }
            clock.advance(by: .seconds(30))
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "热重载未完成" }
            XCTAssertTrue(session.canStop)
            XCTAssertTrue(session.performDebugAction(.stop))
            XCTAssertFalse(session.performDebugAction(.stop))
            await session.waitUntilIdle()
            XCTAssertNil(session.feedback)
            XCTAssertEqual(try fixture.marker(), "test\n")
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testWaitStartsAtWorkerSpawnAndRemainsStoppableAfterSixtySeconds() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let script = fixture.project.appending(path: "scripts/simulate-firebase-switch.sh")
        let original = try String(contentsOf: script, encoding: .utf8)
        try original.replacingOccurrences(of: "#!/bin/sh\n", with: #"""
            #!/bin/sh
            if [ "$1" = prod ]; then
                : > .runlet-fixture/pre-started
                while [ ! -f .runlet-fixture/pre-finish ]; do /bin/sleep .02; done
            fi

            """#).write(to: script, atomically: true, encoding: .utf8)
        let executable = try makeFlutter(in: fixture, script: #"""
            : > .runlet-fixture/debug-started
            IFS= read -r command
            """#)
        let clock = ControlledDebugClock()
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in false }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await fixture.waitFor("pre-started")
            clock.advance(by: .seconds(80))
            XCTAssertEqual(session.status, .runningPreTask)
            XCTAssertFalse(session.canHotOperate)
            try Data().write(to: fixture.state("pre-finish"))
            try await fixture.waitFor("debug-started")
            try await eventually { session.status == .waitingForVM && clock.hasSleeper(.seconds(60)) }
            clock.advance(by: .seconds(59))
            XCTAssertEqual(session.status, .waitingForVM)
            clock.advance(by: .seconds(1))
            try await eventually { session.status == .waitingLonger }
            XCTAssertTrue(session.canStop)
            XCTAssertFalse(session.canHotOperate)
            session.stop()
            await session.waitUntilIdle()
            clock.advance(by: .seconds(60))
            XCTAssertEqual(session.status, .ready)
            XCTAssertEqual(try fixture.marker(), "test\n")
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            IFS= read -r command
            printf '%s\n' "$command" > .runlet-fixture/command-1
            (
                /bin/sleep .15
                /bin/cat .runlet-fixture/firebase-environment > .runlet-fixture/before-group-exit
            ) &
            """#)
        let clock = ControlledDebugClock()
        let discovery = DeviceDiscovery([device])
        let vm = DeviceDiscovery([device])
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 discovery: discovery) { _ in !vm.devices.isEmpty }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canHotOperate && clock.hasSleeper(.seconds(2)) }
            func scan() async throws {
                try await eventually { clock.hasSleeper(.seconds(5)) }
                clock.advance(by: .seconds(5))
                try await eventually { clock.hasSleeper(.seconds(5)) }
            }
            func assertStillRunning() throws {
                XCTAssertTrue(session.canStop)
                XCTAssertEqual(try fixture.marker(), "prod\n")
                XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("command-1").path))
            }

            // An aggregate query can succeed with an empty result when a platform probe fails.
            discovery.devices = []
            try await scan()
            XCTAssertTrue(session.vmConnected)
            try assertStillRunning()
            discovery.devices = [device]
            try await scan()
            XCTAssertTrue(session.canHotOperate)

            vm.devices = []
            discovery.fails = true
            try await scan()
            try await eventually { session.status == .connectionInterrupted }
            XCTAssertFalse(session.canHotOperate)
            try assertStillRunning()
            vm.devices = [device]
            try await eventually { clock.hasSleeper(.milliseconds(500)) }
            clock.advance(by: .milliseconds(500))
            try await eventually { session.canHotOperate }
            discovery.fails = false
            discovery.devices = []
            vm.devices = []
            try await eventually { clock.hasSleeper(.seconds(2)) }
            clock.advance(by: .seconds(2))
            try await eventually { session.status == .connectionInterrupted }
            try await scan()
            try assertStillRunning()
            discovery.fails = true
            try await scan()
            discovery.fails = false
            try await scan()
            try assertStillRunning()
            try await eventually { clock.hasSleeper(.seconds(5)) }
            clock.advance(by: .seconds(5))
            try await fixture.waitFor("command-1")
            await session.waitUntilIdle()
            XCTAssertTrue(session.displayMessage.map { chinese.appString($0) }?.contains("已断开") == true)
            XCTAssertTrue(session.deviceIsOffline)
            XCTAssertEqual(try request(fixture, number: 1).method, "app.stop")
            XCTAssertEqual(try String(contentsOf: fixture.state("before-group-exit"), encoding: .utf8), "prod\n")
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testNaturalExitKeepsItsReasonThroughFailedRecoveryAndLateVMProbe() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            while [ ! -f .runlet-fixture/natural-exit ]; do /bin/sleep .02; done
            exit 7
            """#)
        try Data().write(to: fixture.state("fail-before-test"))
        let clock = ControlledDebugClock()
        var initialProbe = true
        var lateProbe: CheckedContinuation<Bool, Never>?
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in
            if initialProbe {
                initialProbe = false
                return true
            }
            return await withCheckedContinuation { lateProbe = $0 }
        }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canHotOperate && clock.hasSleeper(.seconds(2)) }
            clock.advance(by: .seconds(2))
            try await eventually { lateProbe != nil }
            try Data().write(to: fixture.state("natural-exit"))
            await session.waitUntilIdle()
            lateProbe?.resume(returning: true)
            lateProbe = nil
            XCTAssertEqual(session.status, .recoveryFailed)
            XCTAssertFalse(session.canHotOperate)
            XCTAssertFalse(session.canStop)
            XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
            try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
            session.retryRecovery()
            await session.waitUntilIdle()
            XCTAssertEqual(session.status, .ready)
            XCTAssertTrue(session.displayMessage.map { chinese.appString($0) }?.contains("退出码 7") == true)
            XCTAssertFalse(session.vmConnected)
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
        } catch {
            lateProbe?.resume(returning: false)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"old","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"https://example.test/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/stale=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/other=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' 'DevTools http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws'
            printf '%s\n' 'invalid reports consumed'
            while [ ! -f .runlet-fixture/browser-ready ]; do /bin/sleep .02; done
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2Fprivate%3D%2Fws"}}]'
            IFS= read -r command
            """#)
        let clock = ControlledDebugClock()
        var vmOnline = true
        var opened: [URL] = []
        var canLaunchBrowser = false
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 flutterVersion: "3.47.4", devToolsVersion: "2.60.0",
                                 openURL: { opened.append($0); return canLaunchBrowser }) { _ in vmOnline }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.vmConnected && session.logs.contains("invalid reports consumed") }
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.inspector)
            XCTAssertTrue(opened.isEmpty)
            try Data().write(to: fixture.state("browser-ready"))
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.devTools)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "无法打开 DevTools")
            canLaunchBrowser = true
            session.openBrowser(.inspector)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开 Inspector")
            let inspector = try XCTUnwrap(opened.last)
            XCTAssertTrue(inspector.path.hasSuffix("/devtools/inspector"))
            XCTAssertEqual(URLComponents(url: inspector, resolvingAgainstBaseURL: false)?
                .queryItems?.first?.value, "ws://127.0.0.1:8181/private=/ws")
            XCTAssertFalse(session.logs.contains("private="))

            vmOnline = false
            try await eventually { clock.hasSleeper(.seconds(2)) }
            clock.advance(by: .seconds(2))
            try await eventually { !session.vmConnected }
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.count, 2)
            vmOnline = true
            try await eventually { clock.hasSleeper(.milliseconds(500)) }
            clock.advance(by: .milliseconds(500))
            try await eventually { session.canOpenBrowser }

            session.stop()
            await session.waitUntilIdle()
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.count, 2)
            let next = Self.machineReady.replacingOccurrences(of: "8181/private=", with: "8182/next=")
            _ = try makeFlutter(in: fixture, script: next + "\n" + #"""
                printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
                printf '%s\n' 'old report consumed'
                while [ ! -f .runlet-fixture/next-browser ]; do /bin/sleep .02; done
                printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8182/next=/devtools/?uri=ws://127.0.0.1:8182/next=/ws"}}]'
                IFS= read -r command
                """#)
            session.run()
            try await eventually { session.vmConnected && session.logs.contains("old report consumed") }
            XCTAssertFalse(session.canOpenBrowser)
            try Data().write(to: fixture.state("next-browser"))
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.last?.port, 8182)
            XCTAssertTrue(opened.last?.path.contains("/next=/devtools") == true)
            session.stop()
            await session.waitUntilIdle()
        } catch {
            try? Data().write(to: fixture.state("browser-ready"))
            try? Data().write(to: fixture.state("next-browser"))
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testChangingNextDeviceKeepsRunningSessionAndItsToolsOnOriginalDevice() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let next = FlutterDevice(id: "ios-next", name: "Next iPhone", platform: "ios", isSimulator: true)
        let discovery = DeviceDiscovery([device, next])
        let executable = try makeFlutter(in: fixture, script: #"""
            case "$5" in
              ios-fixture) app=first; port=8181 ;;
              ios-next) app=second; port=8182 ;;
              *) exit 2 ;;
            esac
            printf '%s\n' "$5" >> .runlet-fixture/launch-devices
            printf '[{"event":"app.start","params":{"appId":"%s","deviceId":"%s","mode":"debug","supportsRestart":true}}]\n' "$app" "$5"
            printf '[{"event":"app.debugPort","params":{"appId":"%s","wsUri":"ws://127.0.0.1:%s/private=/ws"}}]\n' "$app" "$port"
            printf '[{"event":"app.devTools","params":{"appId":"%s","uri":"http://127.0.0.1:%s/private=/devtools/?uri=ws://127.0.0.1:%s/private=/ws"}}]\n' "$app" "$port" "$port"
            while IFS= read -r command; do
                case "$command" in
                  *app.restart*)
                    printf '%s\n' "$command" > .runlet-fixture/command-1
                    while [ ! -f .runlet-fixture/reply-1 ]; do /bin/sleep .02; done
                    /bin/cat .runlet-fixture/reply-1
                    ;;
                  *app.stop*) break ;;
                esac
            done
            """#)
        let clock = ControlledDebugClock()
        var opened: [URL] = []
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 discovery: discovery, flutterVersion: "3.47.4", devToolsVersion: "2.61.0",
                                 openURL: { opened.append($0); return true }) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { !session.isRefreshingDevices }
        session.selectDevice(device.id)
        XCTAssertTrue(session.canRun)
        session.run()
        session.selectDevice(next.id)
        XCTAssertEqual(session.selectedDeviceID, device.id, "启动预检时仍锁定下次选择")
        do {
            try await eventually { session.canOpenBrowser && session.canHotOperate }
            session.selectDevice(next.id)
            XCTAssertEqual(session.selectedDeviceID, next.id)
            XCTAssertEqual(session.activeLaunch?.device, device)
            XCTAssertEqual(session.activeLaunch?.configurationName, "sample-flutter-app(prod)")

            discovery.devices = [device]
            discovery.shutdown = [FlutterSimulator(id: next.id, name: next.name)]
            try await eventually { clock.hasSleeper(.seconds(5)) }
            clock.advance(by: .seconds(5))
            try await eventually { !session.canStop || clock.hasSleeper(.seconds(5)) }
            XCTAssertTrue(session.canStop, "仅 B 关机时，A 的监测不能停止当前调试")
            XCTAssertTrue(session.performDebugAction(.reload))
            try await fixture.waitFor("command-1")
            let request = try request(fixture, number: 1)
            XCTAssertEqual(request.appID, "first")
            XCTAssertEqual(request.fullRestart, false)
            try reply(fixture, to: request.id, number: 1, code: 0)
            try await eventually { session.canHotOperate }
            session.openBrowser(.devTools)
            session.openBrowser(.inspector)
            XCTAssertEqual(opened.map(\.port), [8181, 8181])
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开当前会话的 DevTools，请选择 Inspector。")
            session.stop()
            await session.waitUntilIdle()
            XCTAssertNil(session.activeLaunch)
            XCTAssertEqual(session.selectedDeviceID, next.id)
            XCTAssertEqual(try fixture.marker(), "test\n")

            session.run()
            await session.waitUntilIdle()
            XCTAssertEqual(try fixture.marker(), "test\n", "重新发现 B 离线时不得运行 prod 前置")
            XCTAssertNil(try store.read(project: fixture.project))
            XCTAssertEqual(try String(contentsOf: fixture.state("launch-devices"), encoding: .utf8), "ios-fixture\n")
            XCTAssertFalse(session.canRun)

            discovery.devices = [device, next]
            discovery.shutdown = []
            session.refreshDevices()
            try await eventually { session.canRun }
            session.run()
            try await eventually { session.canOpenBrowser }
            XCTAssertEqual(session.activeLaunch?.device, next)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.last?.port, 8182)
            XCTAssertEqual(try String(contentsOf: fixture.state("launch-devices"), encoding: .utf8), "ios-fixture\nios-next\n")
            session.stop()
            await session.waitUntilIdle()
        } catch {
            try? reply(fixture, to: 0, number: 1, code: 1)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testUntestedInspectorVersionOpensConnectedDevToolsWithFallbackFeedback() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            IFS= read -r command
            """#)
        var opened: URL?
        let session = controller(fixture, store: store, executable: executable,
                                 flutterVersion: "3.47.4", devToolsVersion: "2.61.0",
                                 openURL: { opened = $0; return true }) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.inspector)
            XCTAssertTrue(opened?.path.hasSuffix("/devtools") == true)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开当前会话的 DevTools，请选择 Inspector。")
            session.stop()
            await session.waitUntilIdle()
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    private static let machineReady = #"""
        printf '%s\n' '[{"event":"app.start","params":{"appId":"current","deviceId":"ios-fixture","mode":"debug","supportsRestart":true}}]'
        printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"current","wsUri":"ws://127.0.0.1:8181/private=/ws"}}]'
        """#

    private struct MachineRequest: Decodable {
        struct Params: Decodable {
            let appId: String
            let fullRestart: Bool?
        }
        let id: Int
        let method: String
        let params: Params
        var appID: String { params.appId }
        var fullRestart: Bool? { params.fullRestart }
    }

    private func request(_ fixture: SessionFixture, number: Int) throws -> MachineRequest {
        let data = try Data(contentsOf: fixture.state("command-\(number)"))
        return try XCTUnwrap(JSONDecoder().decode([MachineRequest].self, from: data).first)
    }

    private func reply(_ fixture: SessionFixture, to id: Int, number: Int, code: Int) throws {
        try "[{\"id\":\(id),\"result\":{\"code\":\(code),\"message\":\"fixture\"}}]\n"
            .write(to: fixture.state("reply-\(number)"), atomically: true, encoding: .utf8)
    }

    private func controller(_ fixture: SessionFixture, store: ProjectRecoveryStore, executable: URL,
                            timing: FlutterDebugTiming = .continuous, discovery: DeviceDiscovery? = nil,
                            flutterVersion: String = "test", devToolsVersion: String? = nil,
                            openURL: @escaping (URL) -> Bool = { _ in false },
                            verify: @escaping @MainActor (URL) async -> Bool) -> SessionController {
        let device = self.device
        return SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                 toolchain: FlutterToolchain(
                                    resolve: { _, _ in
                                        FlutterSDK(executable: executable, flutterVersion: flutterVersion,
                                                   dartVersion: "test", devToolsVersion: devToolsVersion)
                                    },
                                    discover: { _, _ in
                                        if discovery?.fails == true { throw SessionIssue("扫描失败") }
                                        return discovery?.devices ?? [device]
                                    },
                                    simulators: { _ in
                                        guard let discovery else { return [] }
                                        return discovery.shutdown
                                    }
                                 ), verifyVM: verify, debugTiming: timing, openURL: openURL)
    }

    private func makeFlutter(in fixture: SessionFixture, script: String) throws -> URL {
        let executable = fixture.base.appending(path: "flutter")
        try ("#!/bin/sh\n" + script + "\n").write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        return executable
    }

    private func eventually(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition() {
            guard .now < deadline else { throw SessionIssue("等待调试状态超时") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    private final class DeviceDiscovery {
        var devices: [FlutterDevice]
        var fails = false
        var shutdown: [FlutterSimulator] = []
        init(_ devices: [FlutterDevice]) { self.devices = devices }
    }

    @MainActor
    private final class ControlledDebugClock {
        private var offset: Duration = .zero
        private var sleepers: [UUID: (Duration, Duration, CheckedContinuation<Void, any Error>)] = [:]

        var timing: FlutterDebugTiming {
            FlutterDebugTiming(elapsedSinceStart: { _ in .zero }, sleep: sleep)
        }

        func hasSleeper(_ duration: Duration) -> Bool {
            sleepers.values.contains { $0.0 == duration }
        }

        func advance(by duration: Duration) {
            offset += duration
            let elapsed = sleepers.filter { $0.value.1 <= offset }
            for (id, sleeper) in elapsed {
                sleepers[id] = nil
                sleeper.2.resume()
            }
        }

        private func sleep(_ duration: Duration) async throws {
            let id = UUID()
            try await withTaskCancellationHandler {
                try Task.checkCancellation()
                try await withCheckedThrowingContinuation { continuation in
                    sleepers[id] = (duration, offset + duration, continuation)
                }
            } onCancel: {
                Task { @MainActor in
                    self.sleepers.removeValue(forKey: id)?.2.resume(throwing: CancellationError())
                }
            }
        }
    }
}
