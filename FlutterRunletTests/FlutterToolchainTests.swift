import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class FlutterToolchainTests: XCTestCase {
    func testEnvironmentCheckLabelsArePackagedInBothLanguages() throws {
        for (language, expected) in [("en", "Check Environment"), ("zh-Hans", "检查环境")] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            XCTAssertEqual(bundle.localizedString(forKey: "Check Environment", value: "<missing>", table: nil),
                           expected)
        }
    }

    func testNextDeviceAndAvailabilityLabelsInBothLanguages() throws {
        let labels = [
            "Device for Next Run": "下次运行设备",
            "The selected device is used for the next run.": "所选设备用于下一次运行。",
            "Showing the last device scan.": "显示上次设备扫描结果。",
            "iOS Simulator": "iOS 模拟器", "iOS Device": "iOS 实体设备",
            "Android Emulator": "Android 模拟器", "Android Device": "Android 实体设备",
            "Online": "在线", "Offline": "离线", "Unknown": "未知"
        ]
        for language in ["en", "zh-Hans"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            for (key, translation) in labels {
                XCTAssertEqual(bundle.localizedString(forKey: key, value: "<missing>", table: nil),
                               language == "en" ? key : translation)
            }
        }
    }

    func testDoctorUsesResolvedSDKAndPreservesWarningsAndBothStreams() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        var environment = try sdkEnvironment(fixture)
        let sdkDirectory = fixture.base.appending(path: "cache/3.43.0")
        let executable = try makeSDK(sdkDirectory, version: "3.43.0")
        _ = try pinFVM("3.43.0", to: sdkDirectory, in: fixture)
        let projectBin = fixture.project.appending(path: "bin").path
        environment["PATH"] = "relative:\(projectBin):" + (environment["PATH"] ?? "")
        let sdk = try await FlutterToolchain.production.resolve(fixture.project, environment, .init())
        let body = #"""
        printf '%s\n' "$0" "$@" "$PWD" "$PATH"
        printf '\033[32m[  +12 ms] [✓] Flutter (Channel stable)\033[0m\n[!] Android toolchain - details\n'
        printf '[✗] Chrome - details\n[?] Xcode - details\n原始诊断\n' >&2
        """#
        try ("#!/bin/sh\n" + body).write(to: executable, atomically: false, encoding: .utf8)
        let result = await FlutterToolchain.doctor(using: sdk, environment: environment, project: fixture.project)
        let lines = result.stdout.components(separatedBy: "\n")
        XCTAssertNil(result.failure)
        XCTAssertEqual(Array(lines.prefix(4)), [executable.path, "--no-version-check", "doctor", "-v"])
        let workingDirectory = try XCTUnwrap(lines.dropFirst(4).first)
        XCTAssertTrue(workingDirectory.contains("/FlutterRunlet-doctor-"))
        XCTAssertFalse(workingDirectory.hasPrefix(fixture.project.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: workingDirectory))
        XCTAssertEqual(lines.dropFirst(5).first, FlutterToolchain.probeEnvironment(environment, fixture.project)["PATH"])
        XCTAssertTrue(result.stdout.contains("\u{1b}[32m"))
        XCTAssertEqual(result.stderr, "[✗] Chrome - details\n[?] Xcode - details\n原始诊断\n")
        XCTAssertEqual(result.summary, [.flutter: .passed, .xcode: .unknown, .android: .warning])
    }

    func testDoctorBoundsDualOutputAndRetainsItOnFailure() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let executable = try makeSDK(fixture.base.appending(path: "Diagnostic SDK"), version: "3.43.0")
        let sdk = FlutterSDK(executable: executable, flutterVersion: "3.43.0", dartVersion: "3.12.0")
        func use(_ body: String) throws {
            try ("#!/bin/sh\n" + body).write(to: executable, atomically: false, encoding: .utf8)
        }
        try use("""
        /usr/bin/yes a | /usr/bin/head -c 70000
        /usr/bin/yes b | /usr/bin/head -c 80000 >&2
        exit 7
        """)
        let failed = await FlutterToolchain.doctor(using: sdk, environment: fixture.environment, project: nil)
        XCTAssertEqual(failed.failure, .exit(7))
        XCTAssertEqual(failed.stdout.utf8.count, 70_000)
        XCTAssertEqual(failed.stderr.utf8.count, 80_000)
        let bounded = await FlutterToolchain.doctor(using: sdk, environment: fixture.environment,
                                                    project: nil, outputLimit: 100_000)
        XCTAssertEqual(bounded.failure, .truncated)
        XCTAssertEqual(bounded.stdout.utf8.count + bounded.stderr.utf8.count, 100_000)
        XCTAssertFalse(bounded.stderr.isEmpty)

        try use("printf 'before timeout'; /bin/sleep 5")
        let timedOut = await FlutterToolchain.doctor(using: sdk, environment: fixture.environment,
                                                     project: nil, timeout: .milliseconds(500))
        XCTAssertEqual(timedOut.failure, .timeout)
        XCTAssertEqual(timedOut.stdout, "before timeout")

        try FileManager.default.removeItem(at: executable)
        let missing = await FlutterToolchain.doctor(using: sdk, environment: fixture.environment, project: nil)
        XCTAssertEqual(missing.failure, .launch)
    }

    func testChangingProjectsCancelsAndDiscardsObsoleteDoctorProcess() async throws {
        let old = try SessionFixture()
        let new = try SessionFixture()
        defer { old.remove(); new.remove() }
        let oldSDK = try makeSDK(old.base.appending(path: "Old SDK"), version: "3.42.0")
        let newSDK = try makeSDK(new.base.appending(path: "New SDK"), version: "3.43.0")
        let startMarker = old.state("doctor-started")
        let oldBody = """
        #!/bin/sh
        trap '' TERM
        printf '%s' "$$" > "\(startMarker.path)"
        /bin/sleep 10 &
        wait
        printf 'old result'
        """
        try oldBody.write(to: oldSDK, atomically: false, encoding: .utf8)
        try "#!/bin/sh\nprintf '[✓] Flutter (current result)\\n'\n".write(to: newSDK, atomically: false, encoding: .utf8)
        let oldPath = try ProjectLocation.directory(old.project)
        let session = SessionController(store: nil, runner: .bundled, environment: old.environment,
                                        toolchain: FlutterToolchain(resolve: { project, _ in
            let isOld = project == oldPath
            return FlutterSDK(executable: isOld ? oldSDK : newSDK, flutterVersion: isOld ? "3.42.0" : "3.43.0",
                              dartVersion: "3.12.0")
        }, discover: { _, _ in [] }))
        XCTAssertTrue(session.open(old.project))
        try await eventually { session.canCheckEnvironment }
        session.checkEnvironment()
        try await old.waitFor("doctor-started")
        let pid = try XCTUnwrap(Int32(String(contentsOf: startMarker, encoding: .utf8)))
        XCTAssertTrue(session.open(new.project))
        try await eventually { session.canCheckEnvironment }
        session.checkEnvironment()
        try await eventually { session.doctorResult != nil }
        try await eventually { kill(pid, 0) == -1 && errno == ESRCH }
        XCTAssertEqual(session.doctorResult?.stdout, "[✓] Flutter (current result)\n")

        XCTAssertTrue(session.open(old.project))
        try await eventually { session.canCheckEnvironment }
        try FileManager.default.removeItem(at: startMarker)
        session.checkEnvironment()
        try await old.waitFor("doctor-started")
        session.cancelEnvironmentCheck()
        try await eventually { session.doctorResult?.failure == .cancelled }
        XCTAssertTrue(session.canCheckEnvironment)
    }

    func testTerminationWaitsForCurrentAndCancelledDoctorCleanup() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let executable = try makeSDK(fixture.base.appending(path: "Diagnostic SDK"), version: "3.43.0")
        let marker = fixture.state("doctor-started")
        try """
        #!/bin/sh
        trap '' TERM
        printf '%s\\n' "$$" "$PWD" > "\(marker.path)"
        /bin/sleep 10 &
        wait
        """.write(to: executable, atomically: false, encoding: .utf8)
        let sdk = FlutterSDK(executable: executable, flutterVersion: "3.43.0", dartVersion: "3.12.0")
        let session = SessionController(store: nil, runner: .bundled, environment: fixture.environment,
                                        toolchain: FlutterToolchain(resolve: { _, _ in sdk }, discover: { _, _ in [] }))
        XCTAssertTrue(session.open(fixture.project))
        for resetBeforeQuitting in [false, true] {
            try await eventually { session.canCheckEnvironment }
            session.checkEnvironment()
            try await fixture.waitFor("doctor-started")
            let lines = try String(contentsOf: marker, encoding: .utf8).split(separator: "\n")
            let pid = try XCTUnwrap(lines.first.flatMap { Int32($0) })
            let directory = try XCTUnwrap(lines.dropFirst().first.map(String.init))
            defer {
                if kill(pid, 0) == 0 { _ = kill(-pid, SIGKILL) }
            }
            if resetBeforeQuitting {
                session.refreshDevices()
            }
            let completed = await session.finishForTermination()
            XCTAssertTrue(completed)
            XCTAssertFalse(session.isCheckingEnvironment)
            let processStatus = kill(pid, 0)
            XCTAssertEqual(processStatus, -1)
            if processStatus == -1 { XCTAssertEqual(errno, ESRCH) }
            XCTAssertFalse(FileManager.default.fileExists(atPath: directory))
            try FileManager.default.removeItem(at: marker)
        }
    }

    func testProductionSDKPriorityAndInvalidExplicitSourcesNeverFallBack() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let environment = try sdkEnvironment(fixture)
        let manual = fixture.base.appending(path: "Manual SDK")
        let manualExecutable = try makeSDK(manual, version: "3.42.0")
        let cacheSDK = fixture.base.appending(path: "cache/3.43.0")
        let fvmExecutable = try makeSDK(cacheSDK, version: "3.43.0")
        let link = try pinFVM("3.43.0", to: cacheSDK, in: fixture)
        let toolchain = FlutterToolchain.production

        let fvm = try await toolchain.resolve(fixture.project, environment, .init(manualPath: manual.path))
        XCTAssertEqual(fvm.source, .projectFVM)
        XCTAssertEqual(fvm.executable.path, fvmExecutable.path)
        XCTAssertEqual(fvm.flutterVersion, "3.43.0")
        XCTAssertEqual(fvm.dartVersion, "3.12.0")
        XCTAssertEqual(fvm.projectFVMVersion, "3.43.0")

        let overridden = try await toolchain.resolve(
            fixture.project, environment, .init(preferProjectFVM: false, manualPath: manual.path)
        )
        XCTAssertEqual(overridden.source, .manual)
        XCTAssertEqual(overridden.executable.path, manualExecutable.path)
        XCTAssertEqual(overridden.flutterVersion, "3.42.0")
        XCTAssertEqual(overridden.projectFVMVersion, "3.43.0")
        let system = try await toolchain.resolve(fixture.project, environment, .init(preferProjectFVM: false))
        XCTAssertEqual(system.source, .system)
        XCTAssertEqual(system.flutterVersion, "3.41.0")

        try FileManager.default.removeItem(at: manual)
        await expectIssue("手动", from: {
            try await toolchain.resolve(fixture.project, environment, .init(preferProjectFVM: false, manualPath: manual.path))
        })
        try FileManager.default.removeItem(at: link)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.base.appending(path: "missing"))
        let before = try probeLog(fixture)
        for preferFVM in [true, false] {
            await expectIssue("FVM", from: {
                try await toolchain.resolve(fixture.project, environment, .init(preferProjectFVM: preferFVM))
            })
        }
        XCTAssertEqual(try probeLog(fixture), before)
    }

    func testProjectScriptsAndSDKLinksOutsideTrustedRootsAreNeverProbed() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        var environment = try sdkEnvironment(fixture)
        let replacement = fixture.project.appending(path: "3.43.0")
        _ = try makeSDK(replacement, version: "evil")
        let link = try pinFVM("3.43.0", to: replacement, in: fixture)
        await expectIssue("FVM", from: {
            try await FlutterToolchain.production.resolve(fixture.project, environment, .init())
        })
        let escaped = fixture.base.appending(path: "cache/3.43.0")
        try FileManager.default.createDirectory(at: escaped.appending(path: "bin"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: escaped.appending(path: "bin/flutter"),
                                                  withDestinationURL: replacement.appending(path: "bin/flutter"))
        try FileManager.default.removeItem(at: link)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: escaped)
        await expectIssue("FVM", from: {
            try await FlutterToolchain.production.resolve(fixture.project, environment, .init())
        })
        XCTAssertEqual(try probeLog(fixture), "")

        try FileManager.default.removeItem(at: fixture.project.appending(path: ".fvm"))
        try FileManager.default.removeItem(at: fixture.project.appending(path: ".fvmrc"))
        environment["PATH"] = replacement.appending(path: "bin").path + ":" + (environment["PATH"] ?? "")
        let sdk = try await FlutterToolchain.production.resolve(fixture.project, environment, .init())
        XCTAssertEqual(sdk.flutterVersion, "3.41.0")
        XCTAssertFalse(try probeLog(fixture).contains("evil"))
        XCTAssertTrue(try probeLog(fixture).contains("3.41.0:/"))
    }

    func testValidatedSettingsPersistAndKeepTheActualSDKLockedThroughRecovery() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let environment = try sdkEnvironment(fixture)
        let preferencesName = "FlutterToolchainTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: preferencesName))
        defer { preferences.removePersistentDomain(forName: preferencesName) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, environment: environment,
                                        preferences: preferences, toolchain: .production)
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        let manual = fixture.base.appending(path: "Manual SDK")
        let executable = try makeSDK(manual, version: "3.42.0")
        session.selectFlutterSDK(manual)
        try await eventually { session.sdk?.source == .manual && session.canRun }
        session.selectFlutterSDK(fixture.base.appending(path: "Missing SDK"))
        try await eventually { session.sdkSelectionIssue != nil }
        XCTAssertEqual(session.manualSDKPath, manual.path)
        XCTAssertEqual(session.sdk?.executable.path, executable.path)
        session.setPreferProjectFVM(false)
        try await eventually { session.canRun }
        let reopened = SessionController(store: store, runner: .bundled, environment: environment,
                                         preferences: preferences, toolchain: .production)
        XCTAssertFalse(reopened.preferProjectFVM)
        XCTAssertEqual(reopened.manualSDKPath, manual.path)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("sdk-used").path))

        try "".write(to: fixture.state("fail-before-test"), atomically: true, encoding: .utf8)
        session.run()
        XCTAssertFalse(session.canEditFlutterSDK)
        session.setPreferProjectFVM(true)
        session.selectFlutterSDK(fixture.base.appending(path: "Other SDK"))
        await session.waitUntilIdle()
        XCTAssertNotNil(session.recovery)
        XCTAssertFalse(session.canEditFlutterSDK)
        session.refreshDevices()
        XCTAssertFalse(session.isCheckingSDK)
        session.setPreferProjectFVM(true)
        XCTAssertFalse(session.preferProjectFVM)
        XCTAssertEqual(session.manualSDKPath, manual.path)
        XCTAssertEqual(session.sdk?.executable.path, executable.path)
        XCTAssertEqual(try String(contentsOf: fixture.state("sdk-used"), encoding: .utf8), executable.path)
        try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
        session.retryRecovery()
        await session.waitUntilIdle()
        XCTAssertTrue(session.canEditFlutterSDK)
        XCTAssertEqual(try fixture.marker(), "test\n")
    }

    func testActivationRechecksBrokenFVMWithoutLaunchingAndDropsObsoleteProjectResult() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let environment = try sdkEnvironment(fixture)
        let cacheSDK = fixture.base.appending(path: "cache/3.43.0")
        _ = try pinFVM("3.43.0", to: cacheSDK, in: fixture)
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, environment: environment, toolchain: .production)
        try fixture.select("prod", in: session)
        try await eventually { session.sdkIssue != nil }
        XCTAssertFalse(session.canRun)
        XCTAssertEqual(try probeLog(fixture), "")
        _ = try makeSDK(cacheSDK, version: "3.43.0")
        session.recheckInvalidFlutterSDK()
        try await eventually(diagnostic: session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) } ?? "没有状态消息") { session.canRun }
        XCTAssertEqual(session.sdk?.source, .projectFVM)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("sdk-used").path))

        let firstProbe = PausedProbe()
        let firstPath = try ProjectLocation.directory(fixture.project).path
        let otherPath = try ProjectLocation.directory(other.project).path
        let delayed = SessionController(store: store, runner: .bundled, environment: environment, toolchain: FlutterToolchain(
            resolve: { project, _ in
                let isFirst = project.path == firstPath
                if isFirst { await firstProbe.wait() }
                return FlutterSDK(executable: project.appending(path: "bin/flutter"),
                                  flutterVersion: isFirst ? "old" : "current", dartVersion: "3")
            }, discover: { _, _ in [] }
        ))
        XCTAssertTrue(delayed.open(fixture.project))
        try await eventually { firstProbe.continuation != nil }
        XCTAssertTrue(delayed.open(other.project))
        try await eventually { delayed.sdk?.flutterVersion == "current" }
        firstProbe.release()
        try await eventually { firstProbe.didResume }
        XCTAssertEqual(delayed.project?.path, otherPath)
        XCTAssertEqual(delayed.sdk?.flutterVersion, "current")
    }

    func testAvailabilityDistinguishesAggregateOmissionFromTheSelectedSimulatorShutdown() async {
        let device = FlutterDevice(id: "selected", name: "iPhone 17", platform: "ios", isSimulator: true)
        let sdk = FlutterSDK(executable: URL(fileURLWithPath: "/bin/sh"), flutterVersion: "3", dartVersion: "3")
        var shutdown = [FlutterSimulator(id: "neighbor", name: "另一个模拟器")]
        let toolchain = FlutterToolchain(resolve: { _, _ in sdk }, discover: { _, _ in [] },
                                        simulators: { _ in shutdown })
        let absent = await toolchain.availability(of: device, using: sdk, environment: [:])
        XCTAssertEqual(absent, .missing)
        shutdown.append(FlutterSimulator(id: device.id, name: device.name))
        let confirmed = await toolchain.availability(of: device, using: sdk, environment: [:])
        XCTAssertEqual(confirmed, .disconnected)
    }

    func testSelectionPreservesConflictOfflineAndPerProjectHistory() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let first = FlutterDevice(id: "ios", name: "iPhone 17", platform: "ios", isSimulator: true)
        let second = FlutterDevice(id: "emulator-5560", name: "Android 名称保持原样", platform: "android-arm64", isSimulator: true)
        let scanner = DeviceScanner()
        let toolchain = FlutterToolchain(
            resolve: { _, _ in FlutterSDK(executable: URL(fileURLWithPath: "/bin/sh"),
                                          flutterVersion: "3", dartVersion: "3") },
            discover: { _, _ in try scanner.scan() }
        )
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, environment: fixture.environment, toolchain: toolchain)
        try fixture.select("prod", in: session)
        try await eventually { !session.isRefreshingDevices }
        XCTAssertNil(session.selectedDeviceID)
        XCTAssertFalse(session.canRun)
        scanner.devices = [first]
        session.refreshDevices()
        try await eventually { !session.isRefreshingDevices }
        XCTAssertEqual(session.selectedDeviceID, first.id)
        XCTAssertTrue(session.canRun)

        scanner.devices = [first, second]
        session.refreshDevices()
        try await eventually { !session.isRefreshingDevices }
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == second.id })?.availability, .online)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == second.id })?.kind, .androidEmulator)
        let path = fixture.config("launch")
        let original = try String(contentsOf: path, encoding: .utf8)
        try original.replacingOccurrences(of: #""name": "sample-flutter-app(prod)","#,
            with: #""name": "sample-flutter-app(prod)", "deviceId": "emulator-5560","#)
            .write(to: path, atomically: true, encoding: .utf8)
        session.reload()
        XCTAssertEqual(session.selectedDeviceID, first.id)
        XCTAssertTrue(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) }?.contains(second.name) == true)
        XCTAssertFalse(session.canRun)
        session.selectDevice(second.id)
        XCTAssertTrue(session.canRun)

        scanner.devices = [first]
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(session.selectedDeviceID, second.id)
        XCTAssertEqual(session.selectedDeviceName, second.name)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == second.id })?.availability, .offline)
        XCTAssertTrue(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("离线") == true)
        XCTAssertFalse(session.canRun)
        let sdk = try XCTUnwrap(session.sdk)
        let absent = await toolchain.availability(of: second, using: sdk, environment: fixture.environment)
        XCTAssertEqual(absent, .missing)
        scanner.fails = true
        let unknown = await toolchain.availability(of: second, using: sdk, environment: fixture.environment)
        XCTAssertEqual(unknown, .unknown)
        session.refreshDevices()
        try await eventually { !session.isRefreshingDevices }
        XCTAssertTrue(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("无法刷新设备") == true)
        XCTAssertEqual(session.selectedDeviceID, second.id)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == second.id })?.availability, .unknown)

        scanner.fails = false
        scanner.devices = [first, second]
        session.refreshDevices()
        try await eventually { session.canRun }
        XCTAssertEqual(session.selectedDeviceID, second.id)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == second.id })?.availability, .online)
        XCTAssertTrue(session.open(other.project))
        try await eventually { !session.isRefreshingDevices }
        XCTAssertNil(session.selectedDeviceID)
        session.selectDevice(first.id)
        let alias = fixture.base.appending(path: "Project Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        XCTAssertTrue(session.open(alias))
        try await eventually { !session.isRefreshingDevices }
        XCTAssertEqual(session.selectedDeviceID, second.id)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("sdk-used").path))

        let reopened = SessionController(store: store, runner: .bundled, environment: fixture.environment, toolchain: toolchain)
        XCTAssertTrue(reopened.open(alias))
        try await eventually { !reopened.isRefreshingDevices }
        XCTAssertNil(reopened.selectedDeviceID)
    }

    func testSimulatorStartWaitsForFlutterAndNeverLaunchesDebug() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let candidate = FlutterSimulator(id: UUID().uuidString, name: "iPhone 18 Pro")
        let other = FlutterSimulator(id: UUID().uuidString, name: "iPhone 17")
        let device = FlutterDevice(id: candidate.id, name: candidate.name, platform: "ios", isSimulator: true)
        let scanner = DeviceScanner()
        let bootDiscovery = PausedProbe()
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, environment: fixture.environment, toolchain: FlutterToolchain(
            resolve: { _, _ in FlutterSDK(executable: URL(fileURLWithPath: "/bin/sh"), flutterVersion: "3", dartVersion: "3") },
            discover: { _, _ in
                if scanner.boots.last == candidate.id {
                    await bootDiscovery.wait()
                    return [device]
                }
                return []
            }, simulators: { _ in [candidate, other] }, bootSimulator: { id, _ in
                scanner.boots.append(id)
                if id == other.id { throw SessionIssue("模拟器启动失败") }
            }
        ))
        try fixture.select("prod", in: session)
        try await eventually { session.simulators.count == 2 && !session.isRefreshingDevices }
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == candidate.id })?.availability, .offline)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == candidate.id })?.kind, .iOSSimulator)
        session.startSimulator(other.id)
        try await eventually { session.simulatorIssue != nil }
        XCTAssertTrue(session.canStartSimulator)
        session.startSimulator(candidate.id)
        try await eventually { bootDiscovery.continuation != nil }
        XCTAssertTrue(session.isStartingSimulator)
        XCTAssertFalse(session.canRun)
        XCTAssertEqual(scanner.boots, [other.id, candidate.id])
        bootDiscovery.release()
        try await eventually { session.canRun }
        XCTAssertEqual(session.selectedDeviceID, candidate.id)
        XCTAssertEqual(session.deviceChoices.filter { $0.id == candidate.id }.count, 1)
        XCTAssertEqual(session.deviceChoices.first(where: { $0.id == candidate.id })?.availability, .online)
        XCTAssertFalse(session.isStartingSimulator)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("sdk-used").path))
    }

    func testObsoleteDeviceScanCannotReplaceTheNewProjectsSelection() async throws {
        let old = try SessionFixture()
        let new = try SessionFixture()
        defer { old.remove(); new.remove() }
        let oldDevice = FlutterDevice(id: "old", name: "旧设备", platform: "ios", isSimulator: true)
        let newDevice = FlutterDevice(id: "new", name: "新设备", platform: "ios", isSimulator: true)
        let oldDiscovery = PausedProbe()
        let oldPath = try ProjectLocation.directory(old.project).path
        let store = try ProjectRecoveryStore(directory: new.storage)
        let session = SessionController(store: store, runner: .bundled, environment: new.environment, toolchain: FlutterToolchain(
            resolve: { project, _ in
                FlutterSDK(executable: URL(fileURLWithPath: "/bin/sh"),
                           flutterVersion: project.path == oldPath ? "old" : "new", dartVersion: "3")
            }, discover: { sdk, _ in
                if sdk.flutterVersion == "old" {
                    await oldDiscovery.wait()
                    return [oldDevice]
                }
                return [newDevice]
            }
        ))
        XCTAssertTrue(session.open(old.project))
        try await eventually { oldDiscovery.continuation != nil }
        try new.select("prod", in: session)
        try await eventually { session.canRun }
        oldDiscovery.release()
        try await eventually { oldDiscovery.didResume }
        XCTAssertEqual(session.devices, [newDevice])
        XCTAssertEqual(session.selectedDeviceID, newDevice.id)
        XCTAssertEqual(try new.marker(), "test\n")
        XCTAssertNil(try store.read(project: new.project))
    }

    func testAndroidUsesExactDeviceAndDefinesAndBlocksUnsupportedApplicationArguments() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let environment = try sdkEnvironment(fixture)
        let devices = """
        [{"id":"emulator-5560","name":"Android 名称","targetPlatform":"android-arm64","emulator":true,"isSupported":true},
         {"id":"physical-ios","name":"iPhone 真机","targetPlatform":"ios","emulator":false,"isSupported":true},
         {"id":"unsupported","name":"离线","targetPlatform":"ios","emulator":false,"isSupported":false},
         {"id":"macos","name":"macOS","targetPlatform":"darwin","emulator":false,"isSupported":true}]
        """
        _ = try makeSDK(fixture.base.appending(path: "System SDK"), version: "3.41.0", devices: devices)
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, environment: environment, toolchain: .production)
        try fixture.select("physical", in: session)
        try await eventually { !session.isRefreshingDevices }
        XCTAssertEqual(session.devices.map(\.id), ["emulator-5560", "physical-ios"])
        XCTAssertEqual(session.devices.map(\.name), ["Android 名称", "iPhone 真机"])
        XCTAssertNil(session.selectedDeviceID)
        session.selectDevice("emulator-5560")
        XCTAssertTrue(session.canRun)
        let originalBytes = try fixture.configurationBytes()
        session.run()
        await session.waitUntilIdle()
        let args = try String(contentsOf: fixture.state("sdk-args"), encoding: .utf8).split(separator: "\n").map(String.init)
        XCTAssertEqual(Array(args.prefix(5)), ["run", "--machine", "--debug", "-d", "emulator-5560"])
        XCTAssertEqual(args.filter { $0.hasPrefix("--dart-define=") },
                       session.selection?.launch?.toolArguments.filter { $0.hasPrefix("--dart-define=") })
        XCTAssertEqual(try fixture.marker(), "dev\n")
        XCTAssertEqual(try fixture.configurationBytes(), originalBytes)

        try FileManager.default.removeItem(at: fixture.state("sdk-used"))
        let path = fixture.config("launch")
        let launch = try String(contentsOf: path, encoding: .utf8)
        try launch.replacingOccurrences(of: #""--dart-define=APP_ENV=prod","#,
                                       with: #""ordinary-arg", "--dart-define=APP_ENV=prod","#)
            .write(to: path, atomically: true, encoding: .utf8)
        session.reload()
        session.select("sample-flutter-app(prod)")
        XCTAssertFalse(session.canRun)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "dev\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("sdk-used").path))
    }

    @MainActor
    private final class DeviceScanner {
        var devices: [FlutterDevice] = []
        var fails = false
        var boots: [String] = []

        func scan() throws -> [FlutterDevice] {
            if fails { throw SessionIssue("设备扫描失败") }
            return devices
        }
    }

    @MainActor
    private final class PausedProbe {
        var continuation: CheckedContinuation<Void, Never>?
        var didResume = false
        func wait() async {
            await withCheckedContinuation { continuation = $0 }
            didResume = true
        }

        func release() {
            continuation?.resume()
            continuation = nil
        }
    }

    private func sdkEnvironment(_ fixture: SessionFixture) throws -> [String: String] {
        let system = fixture.base.appending(path: "System SDK")
        _ = try makeSDK(system, version: "3.41.0")
        return ["PATH": system.appending(path: "bin").path + ":/usr/bin:/bin",
                "FVM_CACHE_PATH": fixture.base.appending(path: "cache").path,
                "RUNLET_PROBE_LOG": fixture.base.appending(path: "probes").path]
    }

    private func makeSDK(_ directory: URL, version: String, devices: String =
        #"[{"id":"iOS","name":"iPhone","targetPlatform":"ios","emulator":true,"isSupported":true}]"#) throws -> URL {
        let bin = directory.appending(path: "bin")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        let executable = bin.appending(path: "flutter")
        try """
        #!/bin/sh
        case "$1" in
          --version)
            printf '%s\\n' "\(version):$PWD" >> "$RUNLET_PROBE_LOG"
            printf '%s\\n' '{"flutterVersion":"\(version)","dartSdkVersion":"3.12.0"}'
            ;;
          devices)
            printf '%s\\n' '\(devices)'
            ;;
          run)
            printf '%s' "$0" > .runlet-fixture/sdk-used
            printf '%s\\n' "$@" > .runlet-fixture/sdk-args
            ;;
        esac
        """.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        return executable
    }

    private func pinFVM(_ version: String, to sdk: URL, in fixture: SessionFixture) throws -> URL {
        let fvm = fixture.project.appending(path: ".fvm")
        try FileManager.default.createDirectory(at: fvm, withIntermediateDirectories: true)
        try #"{"flutter":"\#(version)"}"#.write(to: fixture.project.appending(path: ".fvmrc"),
                                              atomically: true, encoding: .utf8)
        let link = fvm.appending(path: "flutter_sdk")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: sdk)
        return link
    }

    private func probeLog(_ fixture: SessionFixture) throws -> String {
        let path = fixture.base.appending(path: "probes")
        return FileManager.default.fileExists(atPath: path.path) ? try String(contentsOf: path, encoding: .utf8) : ""
    }

    private func expectIssue(_ text: String, from resolve: () async throws -> FlutterSDK) async {
        do {
            _ = try await resolve()
            XCTFail("应阻断 SDK 解析")
        } catch {
            let message = Locale(identifier: "zh-Hans").appString(.appIssue(error))
            XCTAssertTrue(message.contains(text), message)
        }
    }

    private func eventually(line: UInt = #line, diagnostic: @autoclosure () -> String = "",
                            _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition() {
            guard .now < deadline else { throw SessionIssue("第 \(line) 行等待 SDK 或设备状态超时。\(diagnostic())") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
