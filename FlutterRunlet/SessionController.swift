import AppKit
import Darwin
import Foundation
import Observation
import os

struct SessionFeedback {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource?
}

enum SessionStatus {
    case idle, ready, checkingToolchain, runningPreTask, startingFlutter, waitingForVM, waitingLonger
    case running, connectionInterrupted, stopping, restoringEnvironment, recoveryPending, recoveryFailed
    case recoveryUnavailable, launchBlocked, preTaskFailed, processUnconfirmed

    var showsLaunchProgress: Bool {
        switch self {
        case .checkingToolchain, .runningPreTask, .startingFlutter, .waitingForVM, .waitingLonger: true
        default: false
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .idle: "No Debug Session"
        case .ready: "Ready"
        case .checkingToolchain: "Checking Flutter SDK and Devices"
        case .runningPreTask: "Running Pre-launch Task"
        case .startingFlutter: "Starting Flutter"
        case .waitingForVM: "Waiting for VM Service"
        case .waitingLonger: "Still Waiting"
        case .running: "Running"
        case .connectionInterrupted: "Connection Interrupted"
        case .stopping: "Stopping"
        case .restoringEnvironment: "Restoring Environment"
        case .recoveryPending: "Environment Recovery Pending"
        case .recoveryFailed: "Environment Recovery Failed"
        case .recoveryUnavailable: "Environment Recovery Record Unavailable"
        case .launchBlocked: "Launch Blocked"
        case .preTaskFailed: "Pre-launch Task Failed"
        case .processUnconfirmed: "Process State Unconfirmed"
        }
    }
}

enum RecoveryAction {
    case openProject, retry

    var title: LocalizedStringResource {
        switch self {
        case .openProject: "Open Project for Recovery"
        case .retry: "Retry Recovery"
        }
    }
}

enum DebugAction {
    case run, stop, reload, restart
}

enum DebugActionSource {
    case mainWindow, menuBar
}

struct RecoveryFailure {
    let taskLabel: String
    let exit: SessionExit

    var message: LocalizedStringResource { "Post-debug task \(taskLabel) failed (\(exit.detail))" }
}

struct ActiveLaunch {
    let configurationName: String
    let device: FlutterDevice
}

struct DeviceChoice: Identifiable {
    enum Kind: Equatable {
        case iOSSimulator, iOSDevice, androidEmulator, androidDevice, macOSDesktop

        var title: LocalizedStringResource {
            switch self {
            case .iOSSimulator: "iOS Simulator"
            case .iOSDevice: "iOS Device"
            case .androidEmulator: "Android Emulator"
            case .androidDevice: "Android Device"
            case .macOSDesktop: "macOS Desktop"
            }
        }
    }

    enum Availability: Equatable {
        case online, offline, starting, unknown
    }

    enum LaunchTarget {
        case iOS(String), android(String)
    }

    let device: FlutterDevice
    let availability: Availability
    var launchTarget: LaunchTarget? = nil
    var id: String { device.id }
    var name: String { device.name }
    var kind: Kind {
        if device.isMacOSDesktop { return .macOSDesktop }
        if device.platform == "ios" {
            return device.isSimulator ? .iOSSimulator : .iOSDevice
        }
        return device.isSimulator ? .androidEmulator : .androidDevice
    }
}

@MainActor
@Observable
final class SessionController {
    private(set) var project: URL?
    private(set) var recentProjects: [URL] = []
    var canChangeProject: Bool {
        !fixtureConfigurationFailed && !updateReserved && !isBusy && !executionIsUnconfirmed && recovery == nil
    }
    private(set) var choices: [LaunchChoice] = []
    private(set) var selectedID: Int?
    private(set) var configurationIsStale = false
    var rememberRecentProject: Bool {
        didSet { preferences?.set(rememberRecentProject, forKey: Self.rememberKey) }
    }
    var showMainWindowOnLaunch: Bool {
        didSet { preferences?.set(showMainWindowOnLaunch, forKey: Self.showMainWindowKey) }
    }
    var inspectorEditor: InspectorEditor = .vsCode {
        didSet { preferences?.set(inspectorEditor.rawValue, forKey: Self.inspectorEditorKey) }
    }
    var shouldPresentMainWindowOnLaunch: Bool {
        showMainWindowOnLaunch || recovery != nil || recoveryStoreIssue != nil
    }
    private(set) var isBusy = false
    private(set) var canStop = false
    private(set) var sdk: FlutterSDK?
    private(set) var sdkIssue: LocalizedStringResource?
    private(set) var isCheckingSDK = false
    private(set) var sdkSelectionIssue: LocalizedStringResource?
    private(set) var isCheckingSDKSelection = false
    private(set) var doctorResult: FlutterDoctorResult?
    private(set) var isCheckingEnvironment = false
    private(set) var preferProjectFVM: Bool
    private(set) var manualSDKPath: String?
    private(set) var devices: [FlutterDevice] = []
    private var knownDevices: [FlutterDevice] = []
    private var deviceSnapshotSDK: FlutterSDK?
    private var devicePreference: FlutterDevice?
    private(set) var activeLaunch: ActiveLaunch?
    private(set) var simulators: [FlutterSimulator] = []
    private(set) var androidEmulators: [AndroidEmulator] = []
    private var androidAVDByDeviceID: [String: String] = [:]
    private var startingDeviceID: String?
    var isStartingSimulator: Bool { startingDeviceID != nil }
    private(set) var simulatorIssue: LocalizedStringResource?
    private(set) var isRefreshingDevices = false
    private(set) var deviceIssue: LocalizedStringResource?
    private(set) var vmConnected = false
    private var hasCurrentDevToolsAddress = false
    var canOpenBrowser: Bool {
        canStop && vmConnected && !executionIsUnconfirmed && (standaloneDevToolsPath != nil || hasCurrentDevToolsAddress)
    }
    private(set) var standaloneDevToolsPath: String?
    private(set) var standaloneDevToolsVersion: String?
    private(set) var standaloneDevToolsIssue: LocalizedStringResource?
    private(set) var feedback: SessionFeedback?
    private(set) var isHotOperationPending = false
    var canHotOperate: Bool {
        canStop && vmConnected && !isHotOperationPending && debug?.supportsRestart == true
    }
    var usesFlutterToolchain: Bool { toolchain != nil }
    var canEditFlutterSDK: Bool {
        toolchain != nil && !isBusy && !executionIsUnconfirmed && recovery == nil && recoveryStoreIssue == nil &&
            !isCheckingSDKSelection
    }
    var canCheckEnvironment: Bool {
        canEditFlutterSDK && sdk != nil && !isCheckingSDK && !isCheckingEnvironment && !isFinishingTermination && !updateReserved
    }
    var hasPendingEnvironmentChecks: Bool { !doctorTasks.isEmpty }
    var canRefreshDevices: Bool {
        toolchain != nil && !isBusy && !executionIsUnconfirmed && recoveryStoreIssue == nil &&
            (recovery == nil || sdk == nil)
    }
    var canStartSimulator: Bool { canRefreshDevices && sdk != nil && !isRefreshingDevices && !isStartingSimulator }
    var canSelectNextDevice: Bool {
        toolchain != nil && project != nil && !isFinishingTermination && !executionIsUnconfirmed &&
            recovery == nil && recoveryStoreIssue == nil && !isStartingSimulator && !isRefreshingDevices &&
            (!isBusy || status == .running || status == .connectionInterrupted)
    }
    var selectedDeviceID: String? { devicePreference?.id }
    var selectedDevice: FlutterDevice? { devices.first { $0.id == selectedDeviceID } }
    var selectedDeviceChoice: DeviceChoice? {
        let choices = deviceChoices
        let id = startingDeviceID ?? selectedDeviceID
        if let choice = choices.first(where: { $0.id == id }) { return choice }
        if id == nil {
            let target = selection?.launch?.deviceID
            return choices.first { $0.id == target } ?? choices.first
        }
        guard let id, let avd = androidAVDByDeviceID[id] else { return nil }
        return choices.first { $0.id == Self.androidChoiceID(avd) }
    }
    var selectedDeviceName: String? { selectedDeviceChoice?.name }
    var deviceIsOffline: Bool { selectedDeviceChoice?.availability == .offline }
    var deviceChoices: [DeviceChoice] {
        let snapshotIsValid = deviceSnapshotSDK != nil && deviceSnapshotSDK == sdk && deviceIssue == nil
        let onlineIDs = Set(devices.map(\.id))
        var listedIDs = Set<String>()
        let onlineSimulators = Set(devices.filter { $0.platform == "ios" && $0.isSimulator }
            .compactMap { UUID(uuidString: $0.id) })
        let shutdown = simulators.filter { simulator in
            UUID(uuidString: simulator.id).map { !onlineSimulators.contains($0) } ?? false
        }.map {
            FlutterDevice(id: $0.id, name: $0.name, platform: "ios", isSimulator: true)
        }
        let online = devices.filter { !$0.isMacOSDesktop } + devices.filter(\.isMacOSDesktop)
        let candidates = online + shutdown + knownDevices + [devicePreference].compactMap { $0 }
        let availableIOS = Set(shutdown.map(\.id))
        let offlineAVDs = Set(androidEmulators.map(\.id))
        let choices: [DeviceChoice] = candidates.compactMap { device in
            guard listedIDs.insert(device.id).inserted else { return nil }
            if !onlineIDs.contains(device.id), let avd = androidAVDByDeviceID[device.id], offlineAVDs.contains(avd) {
                return nil
            }
            let target: DeviceChoice.LaunchTarget? = availableIOS.contains(device.id) ? .iOS(device.id) : nil
            let availability: DeviceChoice.Availability = if startingDeviceID == device.id {
                .starting
            } else if target != nil {
                .offline
            } else if snapshotIsValid {
                onlineIDs.contains(device.id) ? .online : .offline
            } else {
                .unknown
            }
            return DeviceChoice(device: device, availability: availability, launchTarget: target)
        }
        return choices + androidEmulators.map { emulator in
            let id = Self.androidChoiceID(emulator.id)
            let device = FlutterDevice(id: id, name: emulator.name, platform: "android", isSimulator: true)
            return DeviceChoice(device: device, availability: startingDeviceID == id ? .starting : .offline,
                                launchTarget: .android(emulator.id))
        }
    }

    private static func androidChoiceID(_ id: String) -> String { "avd:\(id)" }

    func canChooseDevice(_ device: DeviceChoice) -> Bool {
        canSelectNextDevice && (device.launchTarget == nil || canStartSimulator)
    }

    private(set) var status: SessionStatus = .idle
    private(set) var message: LocalizedStringResource?
    private(set) var taskIssue: LocalizedStringResource?
    private(set) var recovery: ProjectRecoveryRecord?
    private(set) var recoveryFailure: RecoveryFailure?
    private(set) var activeRecoveryTaskLabel: String?
    private var recoveryReason: LocalizedStringResource?
    private(set) var recoveryStoreIssue: LocalizedStringResource?
    private(set) var executionIsUnconfirmed = false
    var canTerminate: Bool { !isBusy && !executionIsUnconfirmed && recovery == nil && recoveryStoreIssue == nil }
    private var isFinishingTermination = false
    var recoveryProjectIsOpen: Bool { recovery?.projectPath == project?.path && recovery != nil }
    var recoveryAction: RecoveryAction? {
        guard recovery != nil else { return nil }
        return recoveryProjectIsOpen ? .retry : .openProject
    }
    var canPerformRecoveryAction: Bool {
        recovery != nil && !isFinishingTermination && !updateReserved && !isBusy && !executionIsUnconfirmed && recoveryStoreIssue == nil
    }
    var recoveryMessage: LocalizedStringResource? {
        recoveryStoreIssue ?? recoveryReason
    }
    private(set) var logs = ""
    private(set) var didClearLogs = false
    private(set) var logGeneration: UInt64 = 0
    private(set) var logTrimmedUTF16 = 0
    private(set) var logSpans: [SessionLogSpan] = []
    @ObservationIgnored private var pendingLogs = ""
    @ObservationIgnored private var pendingLogSpans: [SessionLogSpan] = []
    @ObservationIgnored private var logEndUTF16 = 0
    @ObservationIgnored private var logFlush: Task<Void, Never>?
    var selection: LaunchChoice? { choices.first { $0.id == selectedID } }
    var canRun: Bool { recovery == nil && canStartSelectedConfiguration }
    private var isConfirmingRestart = false
    @ObservationIgnored private var restartDeviceID: String?

    private var restartableLaunch: ActiveLaunch? {
        // Observe the launch phase even before there is an active process.
        switch status {
        case .waitingForVM, .waitingLonger, .running, .connectionInterrupted:
            guard canStop, !isConfirmingRestart, !isFinishingTermination, !updateReserved,
                  !executionIsUnconfirmed, active != nil else { return nil }
            return activeLaunch
        default:
            return nil
        }
    }

    var canRunAfterRecovery: Bool {
        status == .recoveryFailed && recoveryProjectIsOpen && canStartSelectedConfiguration
    }

    func canChangeConfiguration(source: DebugActionSource) -> Bool {
        guard !isFinishingTermination, !isBusy, !executionIsUnconfirmed, recoveryStoreIssue == nil else { return false }
        return recovery == nil || (source == .mainWindow && status == .recoveryFailed && recoveryProjectIsOpen)
    }

    var recoveryRunBlocker: LocalizedStringResource? {
        guard !canRunAfterRecovery, !isBusy else { return nil }
        if let recoveryStoreIssue { return recoveryStoreIssue }
        guard !executionIsUnconfirmed, recoveryProjectIsOpen else { return nil }
        if !runner.isAvailable { return "The session supervisor is unavailable" }
        if configurationIsStale { return message ?? "The previous launch configuration is no longer available" }
        if selection == nil { return "Select a configuration" }
        return selection?.issue ?? sdkStatusIssue ?? deviceSelectionIssue ?? taskIssue
    }

    private var canStartSelectedConfiguration: Bool {
        guard !isFinishingTermination, !updateReserved, !isBusy, !executionIsUnconfirmed, !configurationIsStale, recoveryStoreIssue == nil,
              let launch = selection?.launch, store != nil, runner.isAvailable else { return false }
        if toolchain == nil { return debugCommand != nil }
        return !isCheckingSDKSelection && !isRefreshingDevices && sdk != nil && selectedDevice != nil && deviceSelectionIssue == nil &&
            launch.applicationArguments.isEmpty
    }
    func canPerformDebugAction(_ action: DebugAction, source: DebugActionSource = .menuBar) -> Bool {
        switch action {
        case .run: restartableLaunch != nil || canRun || (source == .mainWindow && canRunAfterRecovery)
        case .stop: canStop
        case .reload, .restart: canHotOperate
        }
    }

    @discardableResult
    func performDebugAction(_ action: DebugAction, source: DebugActionSource = .menuBar,
                            confirmRestart: (ActiveLaunch) -> Bool = { _ in false }) -> Bool {
        guard canPerformDebugAction(action, source: source) else { return false }
        switch action {
        case .run:
            if let launch = restartableLaunch, let process = active {
                isConfirmingRestart = true
                let confirmed = confirmRestart(launch)
                isConfirmingRestart = false
                if confirmed, active === process, restartableLaunch != nil {
                    restartDeviceID = launch.device.id
                    stop()
                }
            } else if source == .mainWindow && canRunAfterRecovery {
                runAfterRecovery()
            } else {
                run()
            }
        case .stop: stop()
        case .reload: hotOperation(.reload)
        case .restart: hotOperation(.restart)
        }
        return true
    }

    var displayMessage: LocalizedStringResource? {
        recoveryMessage ?? message ?? debugStatusMessage ?? debugEndReason ?? selection?.issue ?? sdkStatusIssue ?? deviceSelectionIssue
    }
    private(set) var debugStatusMessage: LocalizedStringResource?
    private var debugEndReason: LocalizedStringResource?
    private var sdkStatusIssue: LocalizedStringResource? { isCheckingSDK ? "Checking Flutter SDK" : sdkIssue }
    private var deviceSelectionIssue: LocalizedStringResource? {
        guard toolchain != nil, project != nil, !isBusy else { return nil }
        if isStartingSimulator { return "Starting Simulator" }
        if isRefreshingDevices { return "Refreshing Devices" }
        if let deviceIssue { return deviceIssue }
        if let target = selection?.launch?.deviceID, target != selectedDeviceID {
            let name = devices.first { $0.id == target }?.name ?? target
            return "This configuration requires \(name). Select that device from the device menu."
        }
        if deviceIsOffline, let name = selectedDeviceName {
            return "\(name) is offline. Reconnect the device."
        }
        if devices.isEmpty { return "No debug devices found. Connect a device or start a simulator, then refresh devices." }
        if selectedDevice == nil { return "Select a debug device" }
        if selection?.launch?.applicationArguments.isEmpty == false {
            return "The current device cannot pass Dart application arguments from args. Move Flutter tool arguments to toolArgs."
        }
        return nil
    }

    private static let rememberKey = "rememberRecentProject"
    private static let showMainWindowKey = "showMainWindowOnLaunch"
    private static let inspectorEditorKey = "inspectorEditor"
    private static let standaloneDevToolsKey = "standaloneDevToolsPath"
    private static let recentKey = "recentProjectPath"
    private static let recentProjectsKey = "recentProjects"
    private static let preferFVMKey = "preferProjectFVM"
    private static let manualSDKKey = "manualFlutterSDKPath"
    @ObservationIgnored private var projectDevices: [String: FlutterDevice] = [:]
    @ObservationIgnored private var preferences: UserDefaults?
    @ObservationIgnored private var store: ProjectRecoveryStore?
    @ObservationIgnored private let runner: SessionProcessRunner
    @ObservationIgnored private let allowedRoot: URL?
    @ObservationIgnored private let allowedRootIdentity: String?
    @ObservationIgnored private let debugCommand: ((PreparedLaunch) -> SessionCommand?)?
    @ObservationIgnored private let toolchain: FlutterToolchain?
    @ObservationIgnored private let verifyVM: FlutterDebugSession.Verification?
    @ObservationIgnored private let debugTiming: FlutterDebugTiming
    @ObservationIgnored private let openURL: (URL) -> Bool
    @ObservationIgnored private let focusInspector: @MainActor (URL) async -> Bool
    @ObservationIgnored private let logBoundary = OSAllocatedUnfairLock(initialState: UInt64(0))
    @ObservationIgnored private let environment: [String: String]
    @ObservationIgnored private var active: SessionProcess?
    @ObservationIgnored private var debug: FlutterDebugSession?
    @ObservationIgnored private var inspectorFocusTask: Task<Void, Never>?
    @ObservationIgnored private var debugLease: ProjectLease?
    @ObservationIgnored private var standaloneServer: StandaloneServer?
    @ObservationIgnored private var standaloneStartupTimeout: Task<Void, Never>?

    private struct StandaloneServer {
        let id: UUID
        let process: SessionProcess
        let version: String
        var address: URL?
        var pendingPage: FlutterBrowserPage?
    }
    @ObservationIgnored private var stopFallback: Task<Void, Never>?
    @ObservationIgnored private var vmWaitTimeout: Task<Void, Never>?
    @ObservationIgnored private var deviceMonitor: Task<Void, Never>?
    @ObservationIgnored private var missingDeviceScans = 0
    @ObservationIgnored private var discoveryID: UUID?
    @ObservationIgnored private var sdkSelectionID: UUID?
    @ObservationIgnored private var doctorRequest: UUID?
    @ObservationIgnored private var doctorTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var simulatorLaunchID: UUID?
    @ObservationIgnored private var fixtureConfigurationFailed = false
    @ObservationIgnored private var blockedLease: ProjectLease?
    @ObservationIgnored private var operation: Task<Void, Never>?
    @ObservationIgnored private var stopRequested = false
    private(set) var updateReserved = false
    @ObservationIgnored private(set) var updateTrial: UpdateAppLaunch?
    @ObservationIgnored private(set) var updateStartupBlocked = false
    @ObservationIgnored private(set) var interruptedUpdate: UpdateJournal?
    @ObservationIgnored private var finishUpdateStartup: (() -> Void)?

    convenience init(
        store: ProjectRecoveryStore?, runner: SessionProcessRunner, allowedRoot: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preferences: UserDefaults? = nil,
        debugCommand: ((PreparedLaunch) -> SessionCommand?)? = nil
    ) {
        self.init(store: store, runner: runner, allowedRoot: allowedRoot, environment: environment,
                  preferences: preferences, toolchain: nil, debugCommand: debugCommand)
    }

    convenience init(
        store: ProjectRecoveryStore?, runner: SessionProcessRunner,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preferences: UserDefaults? = nil, toolchain: FlutterToolchain,
        verifyVM: FlutterDebugSession.Verification? = nil,
        debugTiming: FlutterDebugTiming = .continuous,
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) },
        focusInspector: @escaping @MainActor (URL) async -> Bool = { _ in false }
    ) {
        self.init(store: store, runner: runner, allowedRoot: nil, environment: environment,
                  preferences: preferences, toolchain: toolchain, verifyVM: verifyVM,
                  debugTiming: debugTiming, openURL: openURL, focusInspector: focusInspector, debugCommand: nil)
    }

    private init(
        store: ProjectRecoveryStore?, runner: SessionProcessRunner, allowedRoot: URL?,
        environment: [String: String], preferences: UserDefaults?, toolchain: FlutterToolchain?,
        verifyVM: FlutterDebugSession.Verification? = nil,
        debugTiming: FlutterDebugTiming = .continuous,
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) },
        focusInspector: @escaping @MainActor (URL) async -> Bool = InspectorBrowserTabs.focus,
        debugCommand: ((PreparedLaunch) -> SessionCommand?)?, deferStartup: Bool = false
    ) {
        self.store = store
        self.runner = runner
        let canonicalRoot = allowedRoot.flatMap { try? ProjectLocation.directory($0) }
        self.allowedRoot = canonicalRoot ?? allowedRoot
        allowedRootIdentity = canonicalRoot.flatMap { try? ProjectLocation.identity($0) }
        self.debugCommand = debugCommand
        self.toolchain = toolchain
        self.verifyVM = verifyVM
        self.debugTiming = debugTiming
        self.openURL = openURL
        self.focusInspector = focusInspector
        self.environment = environment
        self.preferences = preferences
        rememberRecentProject = true
        showMainWindowOnLaunch = true
        preferProjectFVM = true
        if !deferStartup { loadStartupPreferences() }
    }

    private func loadStartupPreferences() {
        rememberRecentProject = preferences?.object(forKey: Self.rememberKey) as? Bool ?? true
        showMainWindowOnLaunch = preferences?.object(forKey: Self.showMainWindowKey) as? Bool ?? true
        inspectorEditor = preferences?.string(forKey: Self.inspectorEditorKey).flatMap(InspectorEditor.init(rawValue:)) ?? .vsCode
        standaloneDevToolsPath = preferences?.string(forKey: Self.standaloneDevToolsKey)
        if let path = standaloneDevToolsPath {
            standaloneDevToolsVersion = StandaloneDevToolsSDK(directory: URL(fileURLWithPath: path))?.version
            if standaloneDevToolsVersion == nil { standaloneDevToolsIssue = Self.invalidStandaloneDevTools }
        }
        preferProjectFVM = preferences?.object(forKey: Self.preferFVMKey) as? Bool ?? true
        manualSDKPath = preferences?.string(forKey: Self.manualSDKKey)
        var recentPath = preferences?.string(forKey: Self.recentKey)
        if let paths = preferences?.stringArray(forKey: Self.recentProjectsKey) {
            recentProjects = paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        } else if let legacyPath = recentPath {
            // Leave migration pending when the legacy volume is temporarily unavailable.
            if let canonical = try? validate(URL(fileURLWithPath: legacyPath, isDirectory: true)) {
                recentProjects = [canonical]
                saveRecentProjects()
                preferences?.set(canonical.path, forKey: Self.recentKey)
                recentPath = canonical.path
            }
        } else {
            saveRecentProjects()
        }
        if rememberRecentProject, let path = recentPath {
            _ = loadProject(URL(fileURLWithPath: path, isDirectory: true), remember: false)
        }
        discoverRecovery()
    }

    static var recoveryNamespace: URL {
        IsolatedUpdateBuild.read()?.recovery ?? URL.applicationSupportDirectory.appending(path: "FlutterRunlet")
    }

    func completeUpdateStartup() {
        let finish = finishUpdateStartup
        finishUpdateStartup = nil
        updateTrial = nil
        updateReserved = false
        finish?()
    }

    var updateBlocker: UpdatePresentation.Blocker? {
        if executionIsUnconfirmed { return .processUnconfirmed }
        if recoveryStoreIssue != nil || store == nil { return .recoveryUnreadable }
        if status == .restoringEnvironment { return .recoveryPending }
        if recoveryFailure != nil { return .recoveryFailed }
        if isBusy || isFinishingTermination || updateReserved { return .debugging }
        if recovery != nil { return .recoveryPending }
        guard let store else { return .recoveryUnreadable }
        do {
            if try !store.allRecords().isEmpty { return .recoveryPending }
        } catch { return .recoveryUnreadable }
        let lease: UpdateActivityLease
        do {
            lease = try UpdateActivityLease(directory: store.directory, installing: true)
        } catch UpdateActivityLease.Issue.busy {
            return .debugging
        } catch { return .processUnconfirmed }
        do {
            if try !store.allRecords().isEmpty { return .recoveryPending }
        } catch { return .recoveryUnreadable }
        do {
            let entries = try FileManager.default.contentsOfDirectory(atPath: store.directory.path)
            guard let product = RunningUpdateApp()?.productID else { return .processUnconfirmed }
            let legacy = try UpdateActivityLease.legacyProjectLocks(entries, in: lease.directoryDescriptor)
            defer { legacy.forEach { close($0) }; withExtendedLifetime(lease) {} }
            try UpdateProcessIdentity.requireNoOtherInstances(product, excluding: getpid())
            try lease.reconcileWorkers(entries)
        } catch { return .processUnconfirmed }
        return nil
    }

    func reserveUpdate(productID: String) async throws -> UpdateReservation {
        guard canTerminate, !updateReserved, !isFinishingTermination, let store else { throw UpdateActivityLease.Issue.busy }
        updateReserved = true
        do {
            let checks = Array(doctorTasks.values)
            for check in checks { check.cancel() }
            for check in checks { await check.value }
            guard canTerminate, !hasPendingEnvironmentChecks else { throw UpdateActivityLease.Issue.busy }
            return try UpdateReservation(store: store, productID: productID)
        } catch {
            updateReserved = false
            throw error
        }
    }

    func releaseUpdateReservation() { updateReserved = false }

    static func fixtureEnabled(arguments: [String]) -> Bool {
        #if DEBUG
        arguments.contains("--phase-02-fixture")
        #else
        false
        #endif
    }

    static func app(arguments: [String]) -> SessionController {
        #if DEBUG
        if fixtureEnabled(arguments: arguments) {
            do {
                let location = try fixtureDirectory()
                let namespace = try ProjectRecoveryStore.privateDirectory(location)
                let projects = try ProjectRecoveryStore.privateDirectory(namespace.appending(path: "projects"))
                let store = try ProjectRecoveryStore(directory: namespace.appending(path: "state"))
                return SessionController(
                    store: store, runner: .bundled, allowedRoot: projects,
                    preferences: UserDefaults(suiteName: "com.atypiape.FlutterRunlet.Phase02Fixture")
                ) { launch in
                    SessionCommand(
                        executable: "/bin/sh", arguments: ["-c", """
                        /bin/mkdir -p .runlet-fixture
                        trap 'exit 0' TERM INT
                        : > .runlet-fixture/debug-started
                        while [ ! -f .runlet-fixture/debug-exit ]; do /bin/sleep 0.1; done
                        exit 19
                        """], directory: launch.project.path, environment: ["PATH": "/usr/bin:/bin"]
                    )
                }
            } catch {
                let blocked = SessionController(store: nil, runner: .bundled)
                blocked.fixtureConfigurationFailed = true
                blocked.message = "Could not verify the isolated acceptance directory: \(LocalizedStringResource.appIssue(error))"
                return blocked
            }
        }
        #endif
        let fixture = IsolatedUpdateBuild.read()
        let support = recoveryNamespace
        let trial: UpdateAppLaunch?
        do {
            trial = try UpdateAppLaunch.resolve(arguments: arguments, namespace: support)
        } catch {
            let blocked = SessionController(store: nil, runner: .bundled, preferences: nil)
            blocked.updateStartupBlocked = true
            blocked.updateReserved = true
            blocked.interruptedUpdate = UpdateAppLaunch.interrupted(arguments: arguments, namespace: support)
            return blocked
        }
        if let trial {
            let controller = SessionController(store: nil, runner: .bundled, allowedRoot: fixture?.projects,
                                               environment: ProcessInfo.processInfo.environment, preferences: nil,
                                               toolchain: .production, debugCommand: nil, deferStartup: true)
            controller.updateTrial = trial
            controller.updateReserved = true
            controller.finishUpdateStartup = { [weak controller] in
                guard let controller else { return }
                do {
                    controller.store = try ProjectRecoveryStore(directory: support)
                    controller.preferences = .standard
                    controller.loadStartupPreferences()
                } catch {
                    controller.recoveryStoreIssue = .appIssue(error)
                    controller.status = .recoveryUnavailable
                }
            }
            return controller
        }
        do {
            return try SessionController(
                store: ProjectRecoveryStore(directory: support),
                runner: .bundled, allowedRoot: fixture?.projects, environment: ProcessInfo.processInfo.environment,
                preferences: .standard, toolchain: .production, debugCommand: nil
            )
        } catch {
            let blocked = SessionController(store: nil, runner: .bundled, preferences: .standard)
            blocked.recoveryStoreIssue = .appIssue(error)
            blocked.status = .recoveryUnavailable
            return blocked
        }
    }

    #if DEBUG
    private static func fixtureDirectory() throws -> URL {
        // Foundation's applicationSupportDirectory honors CFFIXED_USER_HOME.
        // The acceptance root is bound to the current OS user account instead.
        var account = passwd()
        var result: UnsafeMutablePointer<passwd>?
        let suggested = sysconf(_SC_GETPW_R_SIZE_MAX)
        var buffer = [CChar](repeating: 0, count: max(4096, suggested))
        let path = try buffer.withUnsafeMutableBufferPointer { bytes -> String in
            let status = getpwuid_r(geteuid(), &account, bytes.baseAddress, bytes.count, &result)
            guard status == 0, result != nil, let home = account.pw_dir,
                  let path = String(validatingCString: home), path.hasPrefix("/") else {
                throw SessionIssue(localized: "Could not determine the current user’s home directory")
            }
            return path
        }
        return URL(fileURLWithPath: path, isDirectory: true)
            .appending(path: "Library/Application Support/FlutterRunlet-Phase02Fixture", directoryHint: .isDirectory)
    }
    #endif

    @discardableResult
    func open(_ url: URL) -> Bool {
        guard requestProjectChange() else { return false }
        return loadProject(url, remember: true)
    }

    func requestProjectChange() -> Bool {
        if !canChangeProject, !fixtureConfigurationFailed, recovery == nil {
            message = "Stop the current session and finish any environment recovery before opening a project"
        }
        return canChangeProject
    }

    func removeRecentProject(_ url: URL) {
        guard recentProjects.contains(url) else { return }
        recentProjects.removeAll { $0 == url }
        saveRecentProjects()
        if let path = preferences?.string(forKey: Self.recentKey),
           path == url.path || (try? ProjectLocation.directory(URL(fileURLWithPath: path, isDirectory: true))) == url {
            preferences?.removeObject(forKey: Self.recentKey)
        }
    }

    private func saveRecentProjects() {
        preferences?.set(recentProjects.map(\.path), forKey: Self.recentProjectsKey)
    }

    private func loadProject(_ url: URL, remember: Bool) -> Bool {
        do {
            let canonical = try validate(url)
            resetEnvironmentCheck()
            if project != canonical {
                resetLogs()
                feedback = nil
                debugEndReason = nil
            }
            project = canonical
            sdk = nil
            sdkIssue = nil
            sdkSelectionID = nil
            sdkSelectionIssue = nil
            isCheckingSDKSelection = false
            devices = []
            knownDevices = []
            deviceSnapshotSDK = nil
            devicePreference = projectDevices[canonical.path]
            simulators = []
            androidEmulators = []
            androidAVDByDeviceID = [:]
            deviceIssue = nil
            choices = []
            selectedID = nil
            apply(configuration(canonical), preserving: nil)
            status = .ready
            if remember {
                recentProjects.removeAll { $0 == canonical }
                recentProjects.insert(canonical, at: 0)
                saveRecentProjects()
                preferences?.set(canonical.path, forKey: Self.recentKey)
            }
            do {
                if let record = try store?.read(project: canonical) {
                    markRecovery(record, "This project has a pending environment recovery", pending: true)
                }
            } catch {
                recoveryStoreIssue = .appIssue(error)
            }
            refreshDevices()
            return true
        } catch {
            message = .appIssue(error)
            return false
        }
    }

    private func discoverRecovery() {
        guard let store else { return }
        do {
            let records = try store.allRecords()
            if let allowedRoot, records.contains(where: {
                !ProjectLocation.contains(URL(fileURLWithPath: $0.projectPath, isDirectory: true), in: allowedRoot)
            }) {
                throw SessionIssue(localized: "The acceptance store contains a recovery record outside its project directory")
            }
            if let record = records.first(where: { $0.projectPath == project?.path }) ?? records.first {
                markRecovery(record, "Found a pending environment recovery", pending: true)
            } else if recovery != nil {
                recovery = nil
                recoveryReason = nil
                recoveryFailure = nil
            }
            recoveryStoreIssue = nil
        } catch {
            recoveryStoreIssue = .appIssue(error)
            status = .recoveryUnavailable
        }
    }

    @discardableResult
    func openRecoveryProject() -> Bool {
        guard canPerformRecoveryAction, let record = recovery, let store else { return false }
        do {
            let directory = try validate(URL(fileURLWithPath: record.projectPath, isDirectory: true))
            try store.verifyProject(record, directory)
            let opened = loadProject(directory, remember: true)
            if opened { markRecovery(record, "Review and retry the original recovery task", pending: true) }
            return opened
        } catch {
            markRecovery(record, .appIssue(error))
            return false
        }
    }

    func retryRecovery() { beginRecovery(thenRun: nil) }

    func runAfterRecovery() {
        guard canRunAfterRecovery, let selection else { return }
        beginRecovery(thenRun: selection)
    }

    private func beginRecovery(thenRun selection: LaunchChoice?) {
        guard canPerformRecoveryAction, recoveryAction == .retry, let expected = recovery,
              let project, let store else { return }
        guard runner.isAvailable else {
            markRecovery(expected, "The session supervisor is unavailable")
            return
        }
        do {
            let canonical = try validate(project)
            let lease = try store.lease(for: canonical)
            guard let record = try store.read(project: canonical) else {
                recovery = nil
                recoveryReason = nil
                recoveryFailure = nil
                status = .ready
                message = "The current project has no pending recovery record"
                discoverRecovery()
                return
            }
            guard record == expected else {
                markRecovery(record, "The recovery record changed. Review it and try again", pending: true)
                return
            }
            let task = try configuration(canonical).prepareTask(record.taskLabel) { definition in
                try store.verifyDefinition(definition, environment: environment, record: record)
            }
            try store.verifyExecution(task, record: record)
            let deviceID = selectedDeviceID
            let options = sdkOptions
            cancelEnvironmentCheck()
            isBusy = true
            canStop = false
            stopRequested = false
            status = .restoringEnvironment
            message = nil
            operation = Task { [self] in
                defer { finishOperation() }
                guard await restore(task, record: record, project: canonical, store: store, lease: lease),
                      let selection, canContinueAfterRecovery(in: canonical),
                      self.selection == selection, selectedDeviceID == deviceID else { return }
                if let toolchain, let deviceID {
                    await runOnFlutter(project: canonical, selection: selection, deviceID: deviceID, options: options,
                                       store: store, lease: lease, toolchain: toolchain, resumedAfterRecovery: true)
                } else if let debugCommand {
                    do {
                        guard let launch = try revalidate(selection, project: canonical, lease: lease, store: store),
                              let command = debugCommand(launch) else { return }
                        canStop = true
                        await execute(launch, command: command, store: store, lease: lease)
                    } catch {
                        message = .appIssue(error)
                    }
                }
            }
        } catch {
            markRecovery(expected, .appIssue(error))
        }
    }

    private func canContinueAfterRecovery(in project: URL) -> Bool {
        guard !stopRequested, !isFinishingTermination, !executionIsUnconfirmed, self.project == project else { return false }
        // This also checks risks for other projects and fails closed if their records cannot be read.
        discoverRecovery()
        return recovery == nil && recoveryStoreIssue == nil
    }

    func performRecoveryAction() {
        switch recoveryAction {
        case .openProject: openRecoveryProject()
        case .retry: retryRecovery()
        case nil: break
        }
    }

    func reload() {
        guard !isBusy else {
            message = "Stop the current session and finish any environment recovery before reloading the configuration"
            return
        }
        guard let project else { return }
        do {
            let canonical = try validate(project)
            apply(configuration(canonical), preserving: selection?.name)
        } catch {
            configurationIsStale = true
            message = .appIssue(error)
        }
    }

    private func apply(_ config: ProjectConfiguration, preserving name: String?) {
        taskIssue = config.taskIssue
        message = config.launchIssue
        configurationIsStale = config.launchIssue != nil
        if configurationIsStale { return }
        choices = config.choices
        let defaultChoice = choices.first { $0.launch != nil } ?? choices.first
        if let name {
            let matches = choices.filter { $0.name == name }
            selectedID = (matches.only ?? defaultChoice)?.id
            if matches.isEmpty {
                message = "The previous launch configuration is no longer available"
            } else if matches.count > 1 {
                message = "Multiple configurations have the previous name. Rename them in launch.json"
            }
        } else {
            selectedID = defaultChoice?.id
        }
        chooseInitialDevice()
    }

    func select(_ name: String) {
        select(choices.filter { $0.name == name }.only?.id)
    }

    func select(_ id: Int?) {
        guard !isBusy, !configurationIsStale, let id, choices.contains(where: { $0.id == id }) else { return }
        selectedID = id
        chooseInitialDevice()
        if !choices.isEmpty { message = nil }
    }

    func selectDevice(_ id: String) {
        guard canSelectNextDevice, let project, let choice = deviceChoices.first(where: { $0.id == id }) else { return }
        switch choice.launchTarget {
        case .iOS(let id):
            startSimulator(id)
            return
        case .android(let id):
            startAndroidEmulator(id)
            return
        case nil:
            storeDevice(choice.device, for: project)
        }
        if !isBusy { message = nil }
    }

    private func storeDevice(_ device: FlutterDevice, for project: URL) {
        devicePreference = device
        projectDevices[project.path] = device
    }

    private func chooseInitialDevice() {
        guard devicePreference == nil, let project else { return }
        let online = deviceChoices.filter { $0.availability == .online }
        let target = selection?.launch?.deviceID
        let choice = target == nil ? online.first : online.first { $0.id == target }
        if let choice {
            storeDevice(choice.device, for: project)
        }
    }

    private var sdkOptions: FlutterSDKOptions {
        FlutterSDKOptions(preferProjectFVM: preferProjectFVM, manualPath: manualSDKPath)
    }

    func setPreferProjectFVM(_ enabled: Bool) {
        guard canEditFlutterSDK, enabled != preferProjectFVM else { return }
        resetEnvironmentCheck()
        preferProjectFVM = enabled
        preferences?.set(enabled, forKey: Self.preferFVMKey)
        refreshDevices()
    }

    func selectFlutterSDK(_ directory: URL) {
        guard canEditFlutterSDK, let toolchain else { return }
        let request = UUID()
        let project = project
        sdkSelectionID = request
        isCheckingSDKSelection = true
        sdkSelectionIssue = nil
        Task { [weak self, environment] in
            let result: Result<FlutterSDK, any Error>
            do { result = .success(try await toolchain.validateManual(directory, project, environment)) }
            catch { result = .failure(error) }
            guard let self, self.sdkSelectionID == request, self.project == project else { return }
            self.sdkSelectionID = nil
            self.isCheckingSDKSelection = false
            guard self.canEditFlutterSDK else { return }
            switch result {
            case .success(let candidate):
                self.resetEnvironmentCheck()
                self.manualSDKPath = candidate.directory.path
                self.preferences?.set(candidate.directory.path, forKey: Self.manualSDKKey)
                self.refreshDevices()
            case .failure(let error):
                self.sdkSelectionIssue = "Could not use the selected path: \(LocalizedStringResource.appIssue(error)). The previous setting was kept."
            }
        }
    }

    func clearManualFlutterSDK() {
        guard canEditFlutterSDK, manualSDKPath != nil else { return }
        resetEnvironmentCheck()
        manualSDKPath = nil
        sdkSelectionIssue = nil
        preferences?.removeObject(forKey: Self.manualSDKKey)
        refreshDevices()
    }

    func checkFlutterSDKIfNeeded() {
        guard !isCheckingSDK, sdk == nil, sdkIssue == nil else { return }
        refreshDevices()
    }

    func recheckInvalidFlutterSDK() {
        guard !isCheckingSDK, sdkIssue != nil else { return }
        refreshDevices()
    }

    func checkEnvironment() {
        guard canCheckEnvironment, let sdk else { return }
        let activity: UpdateActivityLease?
        do {
            activity = try store.map { try UpdateActivityLease(directory: $0.directory) }
        } catch { return }
        let project = project
        let request = UUID()
        doctorRequest = request
        doctorResult = nil
        isCheckingEnvironment = true
        doctorTasks[request] = Task { [weak self, environment, activity] in
            defer { withExtendedLifetime(activity) {} }
            let result = await FlutterToolchain.doctor(using: sdk, environment: environment, project: project, activity: activity)
            guard let self else { return }
            self.doctorTasks.removeValue(forKey: request)
            guard self.doctorRequest == request, self.project == project, self.sdk == sdk else { return }
            self.doctorResult = result
            self.doctorRequest = nil
            self.isCheckingEnvironment = false
        }
    }

    func cancelEnvironmentCheck() {
        guard let doctorRequest else { return }
        doctorTasks[doctorRequest]?.cancel()
    }

    private func resetEnvironmentCheck() {
        cancelEnvironmentCheck()
        doctorRequest = nil
        doctorResult = nil
        isCheckingEnvironment = false
    }

    func refreshDevices() {
        guard canRefreshDevices, let toolchain else { return }
        if isCheckingEnvironment { resetEnvironmentCheck() }
        let project = project
        let options = sdkOptions
        let request = UUID()
        discoveryID = request
        simulatorLaunchID = nil
        startingDeviceID = nil
        simulatorIssue = nil
        isCheckingSDK = true
        isRefreshingDevices = project != nil
        Task { [weak self, environment] in
            let sdk: FlutterSDK
            do {
                sdk = try await toolchain.resolve(project, environment, options)
            } catch {
                guard let self, self.discoveryID == request, self.project == project else { return }
                self.updateSDK(nil, issue: .appIssue(error))
                self.isRefreshingDevices = false
                return
            }
            guard let self, self.discoveryID == request, self.project == project else { return }
            self.updateSDK(sdk, issue: nil)
            guard let project else { return }
            let probeEnvironment = FlutterToolchain.probeEnvironment(environment, project)
            do {
                let devices = try await toolchain.discover(sdk, probeEnvironment)
                guard self.discoveryID == request, self.project == project else { return }
                self.applyDeviceSnapshot(devices, project: project)
            } catch {
                guard self.discoveryID == request, self.project == project else { return }
                self.updateDeviceIssue(error)
            }
            do {
                let simulators = try await toolchain.simulators(probeEnvironment)
                guard self.discoveryID == request, self.project == project else { return }
                self.simulators = simulators
            } catch {
                guard self.discoveryID == request, self.project == project else { return }
                self.simulators = []
                self.simulatorIssue = "Could not list iOS simulators: \(LocalizedStringResource.appIssue(error)). Refresh devices and try again."
            }
            do {
                let emulators = try await toolchain.androidEmulators(sdk, probeEnvironment)
                guard self.discoveryID == request, self.project == project else { return }
                self.applyAndroidEmulatorSnapshot(emulators)
            } catch {
                guard self.discoveryID == request, self.project == project else { return }
                self.androidEmulators = []
                self.simulatorIssue = "Could not list Android emulators: \(LocalizedStringResource.appIssue(error)). Refresh devices and try again."
            }
            self.isRefreshingDevices = false
        }
    }

    private func applyAndroidEmulatorSnapshot(_ emulators: [AndroidEmulator]) {
        for emulator in emulators {
            if let id = emulator.deviceID { androidAVDByDeviceID[id] = emulator.id }
        }
        androidEmulators = emulators.filter { $0.deviceID == nil }
    }

    private func applyDeviceSnapshot(_ devices: [FlutterDevice], project: URL) {
        self.devices = devices
        let discoveredIDs = Set(devices.map(\.id))
        knownDevices.removeAll { discoveredIDs.contains($0.id) }
        knownDevices.append(contentsOf: devices)
        deviceSnapshotSDK = sdk
        updateDeviceIssue(nil)
        if let device = selectedDevice {
            storeDevice(device, for: project)
        } else {
            chooseInitialDevice()
        }
    }

    private func updateDeviceIssue(_ error: (any Error)?) {
        if message == deviceIssue { message = nil }
        deviceIssue = error.map { "Could not refresh devices: \(LocalizedStringResource.appIssue($0)). Check the devices and try again." }
    }

    private func startSimulator(_ id: String) {
        guard canStartSimulator, let toolchain, let sdk, let project, let target = UUID(uuidString: id),
              simulators.contains(where: { $0.id == id }) else { return }
        let request = UUID()
        simulatorLaunchID = request
        startingDeviceID = id
        simulatorIssue = nil
        let environment = FlutterToolchain.probeEnvironment(environment, project)
        Task { [weak self] in
            guard let self, self.simulatorLaunchID == request, self.project == project else { return }
            defer {
                if self.simulatorLaunchID == request {
                    self.simulatorLaunchID = nil
                    self.startingDeviceID = nil
                }
            }
            do {
                try await toolchain.bootSimulator(id, environment)
                let deadline = ContinuousClock.now + .seconds(90)
                while self.simulatorLaunchID == request, self.project == project, .now < deadline {
                    let discovered = try? await toolchain.discover(sdk, environment)
                    guard self.simulatorLaunchID == request, self.project == project else { return }
                    if let discovered, let device = discovered.first(where: {
                        $0.platform == "ios" && $0.isSimulator && UUID(uuidString: $0.id) == target
                    }) {
                        self.applyDeviceSnapshot(discovered, project: project)
                        self.simulators.removeAll { $0.id == id }
                        self.storeDevice(device, for: project)
                        return
                    }
                    try await Task.sleep(for: .seconds(2))
                }
                throw SessionIssue(localized: "Flutter has not found the selected simulator")
            } catch {
                guard self.simulatorLaunchID == request, self.project == project else { return }
                self.simulatorIssue = "Could not start the iOS simulator: \(LocalizedStringResource.appIssue(error)). Check the simulator and try again."
            }
        }
    }

    private func startAndroidEmulator(_ id: String) {
        guard canStartSimulator, let toolchain, let sdk, let project,
              androidEmulators.contains(where: { $0.id == id }) else { return }
        let request = UUID()
        simulatorLaunchID = request
        startingDeviceID = Self.androidChoiceID(id)
        simulatorIssue = nil
        let environment = FlutterToolchain.probeEnvironment(environment, project)
        Task { [weak self] in
            guard let self, self.simulatorLaunchID == request, self.project == project else { return }
            defer {
                if self.simulatorLaunchID == request {
                    self.simulatorLaunchID = nil
                    self.startingDeviceID = nil
                }
            }
            do {
                try await toolchain.bootAndroidEmulator(id, sdk, environment)
                let deadline = ContinuousClock.now + .seconds(90)
                while self.simulatorLaunchID == request, self.project == project, .now < deadline {
                    let emulators = try await toolchain.androidEmulators(sdk, environment)
                    let discovered = try await toolchain.discover(sdk, environment)
                    guard self.simulatorLaunchID == request, self.project == project else { return }
                    if let deviceID = emulators.first(where: { $0.id == id })?.deviceID,
                       discovered.contains(where: { $0.id == deviceID && $0.isSimulator && $0.platform.hasPrefix("android") }) {
                        self.applyDeviceSnapshot(discovered, project: project)
                        if let device = discovered.first(where: { $0.id == deviceID }) {
                            self.storeDevice(device, for: project)
                        }
                        self.applyAndroidEmulatorSnapshot(emulators)
                        return
                    }
                    try await Task.sleep(for: .seconds(2))
                }
                throw SessionIssue(localized: "Flutter has not found the selected simulator")
            } catch {
                guard self.simulatorLaunchID == request, self.project == project else { return }
                self.simulatorIssue = "Could not start the Android emulator: \(LocalizedStringResource.appIssue(error)). Check the emulator and try again."
            }
        }
    }

    private func updateSDK(_ sdk: FlutterSDK?, issue: LocalizedStringResource?) {
        if message == sdkIssue { message = nil }
        if self.sdk != sdk { resetEnvironmentCheck() }
        self.sdk = sdk
        sdkIssue = issue
        isCheckingSDK = false
    }

    func run() {
        guard !isFinishingTermination, !updateReserved, !isBusy, !executionIsUnconfirmed, !configurationIsStale,
              recovery == nil, recoveryStoreIssue == nil, let project, let selection else { return }
        guard let store, (debugCommand != nil || toolchain != nil), runner.isAvailable else {
            message = "The Flutter debug process or recovery storage is unavailable in this build"
            return
        }
        if let toolchain {
            guard canRun, let id = selectedDeviceID else { return }
            beginFlutterRun(project, selection: selection, deviceID: id, store: store, toolchain: toolchain)
            return
        }
        guard let debugCommand else { return }
        do {
            let current = try validate(project)
            let lease = try store.lease(for: current)
            guard let launch = try revalidate(selection, project: current, lease: lease, store: store) else { return }
            guard let command = debugCommand(launch) else { throw SessionIssue(localized: "Debug runner adapter unavailable") }
            isBusy = true
            canStop = true
            stopRequested = false
            message = nil
            operation = Task { [self] in
                defer { finishOperation() }
                await execute(launch, command: command, store: store, lease: lease)
            }
        } catch {
            message = .appIssue(error)
        }
    }

    private func revalidate(_ selected: LaunchChoice, project: URL, lease: ProjectLease,
                            store: ProjectRecoveryStore) throws -> PreparedLaunch? {
        try lease.verifyProject()
        if let existing = try store.pendingRecord(for: project) {
            markRecovery(existing, "This project has a pending environment recovery")
            return nil
        }
        apply(configuration(project), preserving: selected.launch?.name)
        guard !configurationIsStale, let launch = selection?.launch, launch.mode == "debug" else {
            message = displayMessage ?? "The previous launch configuration is no longer available"
            return nil
        }
        guard selected.launch?.executionMatches(launch) == true else {
            message = "The launch configuration or a referenced task changed. Review it and click Run again"
            return nil
        }
        return launch
    }

    private func beginFlutterRun(_ project: URL, selection: LaunchChoice, deviceID: String, store: ProjectRecoveryStore,
                                 toolchain: FlutterToolchain) {
        cancelEnvironmentCheck()
        isBusy = true
        canStop = true
        stopRequested = false
        status = .checkingToolchain
        message = nil
        let options = sdkOptions
        operation = Task { [self] in
            defer { finishOperation() }
            do {
                guard !stopRequested else { return }
                let current = try validate(project)
                let lease = try store.lease(for: current)
                await runOnFlutter(project: current, selection: selection, deviceID: deviceID, options: options,
                                   store: store, lease: lease, toolchain: toolchain)
            } catch {
                if !stopRequested { message = .appIssue(error) }
            }
        }
    }

    private func runOnFlutter(project: URL, selection: LaunchChoice, deviceID: String, options: FlutterSDKOptions,
                              store: ProjectRecoveryStore, lease: ProjectLease, toolchain: FlutterToolchain,
                              resumedAfterRecovery: Bool = false) async {
        canStop = true
        status = .checkingToolchain
        do {
            let sdk: FlutterSDK
            do {
                sdk = try await toolchain.resolve(project, environment, options)
            } catch {
                if !stopRequested { updateSDK(nil, issue: .appIssue(error)) }
                throw error
            }
            guard !stopRequested else { return }
            updateSDK(sdk, issue: nil)
            let devices: [FlutterDevice]
            do {
                devices = try await toolchain.discover(sdk, FlutterToolchain.probeEnvironment(environment, project))
            } catch {
                if !stopRequested { updateDeviceIssue(error) }
                return
            }
            guard !stopRequested else { return }
            if resumedAfterRecovery {
                guard canContinueAfterRecovery(in: project), self.selection == selection,
                      selectedDeviceID == deviceID else { return }
            }
            applyDeviceSnapshot(devices, project: project)
            guard let device = devices.first(where: { $0.id == deviceID }) else { return }
            guard let launch = try revalidate(selection, project: project, lease: lease, store: store) else { return }
            let command = try FlutterToolchain.command(sdk: sdk, device: device, launch: launch)
            await execute(launch, command: command, store: store, lease: lease, device: device)
        } catch {
            if !stopRequested { message = .appIssue(error) }
        }
    }

    private func finishOperation() {
        active = nil
        debug = nil
        vmConnected = false
        canStop = false
        isBusy = false
        operation = nil
        if status == .checkingToolchain || status == .stopping { status = .ready }

        let deviceID = restartDeviceID
        restartDeviceID = nil
        guard let deviceID, status == .ready, recovery == nil, recoveryStoreIssue == nil,
              !isFinishingTermination, !updateReserved, !executionIsUnconfirmed,
              !configurationIsStale, let project, let selection, let store, let toolchain else { return }
        beginFlutterRun(project, selection: selection, deviceID: deviceID, store: store, toolchain: toolchain)
    }

    func stop() {
        stop(disconnectedDevice: nil)
    }

    private func stop(disconnectedDevice device: FlutterDevice?) {
        guard canStop else { return }
        canStop = false
        stopRequested = true
        status = .stopping
        message = nil
        debugStatusMessage = nil
        feedback = nil
        isHotOperationPending = false
        if let device {
            debugStatusMessage = "Debug device \(device.name) disconnected. The session is stopping. Reconnect the device to run again."
            debugEndReason = "Debug device \(device.name) disconnected. Reconnect the device to run again."
        }
        vmWaitTimeout?.cancel()
        deviceMonitor?.cancel()
        inspectorFocusTask?.cancel()
        inspectorFocusTask = nil
        standaloneStartupTimeout?.cancel()
        standaloneStartupTimeout = nil
        standaloneServer?.process.stop()
        if let active, let request = debug?.stopRequest(), active.send(request) {
            stopFallback = Task { [weak active] in
                do { try await Task.sleep(for: .seconds(2)) }
                catch { return }
                active?.stop()
            }
        } else {
            active?.stop()
        }
    }

    func hotOperation(_ operation: FlutterHotOperation) {
        guard canHotOperate, let debug, let active else { return }
        feedback = nil
        isHotOperationPending = true
        debug.hotOperation(operation, send: active.send) { [weak self, weak debug] result in
            guard let self, let debug, self.debug === debug, self.canStop else { return }
            self.isHotOperationPending = false
            switch result {
            case .success:
                self.feedback = SessionFeedback(title: operation == .reload ? "Hot Reload Completed" : "Hot Restart Completed",
                                                detail: "The current debug session is still running.")
            case .failure(let issue):
                self.feedback = SessionFeedback(title: operation == .reload ? "Hot Reload Incomplete" : "Hot Restart Incomplete",
                                                detail: "\(LocalizedStringResource.appIssue(issue)). Check the current debug connection and try again.")
            }
        }
    }

    func dismissFeedback() {
        feedback = nil
    }

    func clearLogs() {
        resetLogs(clearedByUser: true)
    }

    func copyLogs(using write: (String) -> Bool = { text in
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        return clipboard.setString(text, forType: .string)
    }) {
        flushLogs()
        guard !logs.isEmpty else { return }
        if write(logs) {
            feedback = SessionFeedback(title: "Run Logs Copied", detail: nil)
        } else {
            feedback = SessionFeedback(title: "Could Not Copy Run Logs",
                                       detail: "Could not write the run logs to the clipboard. Choose Copy Logs again.")
        }
    }

    private func resetLogs(clearedByUser: Bool = false) {
        logFlush?.cancel()
        logFlush = nil
        pendingLogs = ""
        pendingLogSpans = []
        logEndUTF16 = 0
        logGeneration = logBoundary.withLock { value in
            value &+= 1
            return value
        }
        logs = ""
        logSpans = []
        logTrimmedUTF16 = 0
        didClearLogs = clearedByUser
    }

    private static let invalidStandaloneDevTools: LocalizedStringResource = "Select a Dart SDK directory that includes DevTools."

    func selectStandaloneDevTools(_ directory: URL?) {
        guard canEditFlutterSDK else { return }
        let sdk = directory.flatMap(StandaloneDevToolsSDK.init(directory:))
        guard directory == nil || sdk != nil else {
            standaloneDevToolsIssue = Self.invalidStandaloneDevTools
            return
        }
        standaloneDevToolsPath = sdk?.directory.path
        standaloneDevToolsVersion = sdk?.version
        standaloneDevToolsIssue = nil
        preferences?.set(standaloneDevToolsPath, forKey: Self.standaloneDevToolsKey)
    }

    func openBrowser(_ page: FlutterBrowserPage) {
        guard canOpenBrowser, let debug else { return }
        if let path = standaloneDevToolsPath {
            openStandaloneDevTools(page, for: debug, path: path)
        } else if let destination = debug.browserDestination(page) {
            presentBrowser(page, destination: destination)
        }
    }

    private func openStandaloneDevTools(_ page: FlutterBrowserPage, for debug: FlutterDebugSession, path: String) {
        guard debug.hasActiveVMService, let lease = debugLease, let project else { return }
        if let server = standaloneServer {
            if let address = server.address {
                if let destination = debug.standaloneBrowserDestination(page, server: address, version: server.version) {
                    presentBrowser(page, destination: destination)
                }
            } else if standaloneStartupTimeout != nil {
                standaloneServer?.pendingPage = page
            }
            return
        }
        guard let sdk = StandaloneDevToolsSDK(directory: URL(fileURLWithPath: path)) else {
            standaloneDevToolsVersion = nil
            standaloneDevToolsIssue = Self.invalidStandaloneDevTools
            showStandaloneDevToolsFailure()
            return
        }
        standaloneDevToolsVersion = sdk.version
        standaloneDevToolsIssue = nil
        let id = UUID()
        let lines = SessionLineStream { [weak self, weak debug] line, isError, _ in
            guard let self, let debug, self.debug === debug, self.standaloneServer?.id == id,
                  self.standaloneStartupTimeout != nil, !isError,
                  let page = self.standaloneServer?.pendingPage,
                  let address = StandaloneDevToolsSDK.serverAddress(from: line) else { return }
            self.standaloneStartupTimeout?.cancel()
            self.standaloneStartupTimeout = nil
            self.standaloneServer?.address = address
            self.standaloneServer?.pendingPage = nil
            if let destination = debug.standaloneBrowserDestination(page, server: address, version: sdk.version) {
                self.presentBrowser(page, destination: destination)
            } else {
                self.feedback = SessionFeedback(title: "Standalone DevTools is ready",
                                                detail: "Open Inspector or DevTools again after the debug session reconnects.")
            }
        }
        let command = SessionCommand(executable: sdk.dart.path,
                                     arguments: ["devtools", "--no-launch-browser", "--machine", "--host=127.0.0.1", "--port=0"],
                                     directory: project.path, environment: environment)
        do {
            let process = try runner.start(command, lease: lease, output: { data, isError, generation in
                lines.receive(data, isError: isError, generation: generation)
            })
            standaloneServer = StandaloneServer(id: id, process: process, version: sdk.version, pendingPage: page)
            feedback = SessionFeedback(title: "Starting standalone DevTools…", detail: nil)
            standaloneStartupTimeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(15)) }
                catch { return }
                guard let self, self.standaloneServer?.id == id else { return }
                self.standaloneStartupTimeout = nil
                process.stop()
                self.showStandaloneDevToolsFailure()
            }
            Task { [weak self, weak debug] in
                let result = await process.wait()
                guard let self, let server = self.standaloneServer, server.id == id else { return }
                let awaitingStartup = self.standaloneStartupTimeout != nil
                self.standaloneStartupTimeout?.cancel()
                self.standaloneStartupTimeout = nil
                self.standaloneServer = nil
                self.inspectorFocusTask?.cancel()
                self.inspectorFocusTask = nil
                debug?.openedInspector = nil
                if result.exit == .unconfirmed {
                    self.executionIsUnconfirmed = true
                    self.blockedLease = lease
                }
                if self.canStop, debug?.hasActiveVMService == true {
                    if awaitingStartup {
                        self.showStandaloneDevToolsFailure()
                    } else if server.address != nil {
                        self.feedback = SessionFeedback(title: "Standalone DevTools stopped",
                                                        detail: "Open Inspector or DevTools to start it again.")
                    }
                }
            }
        } catch {
            showStandaloneDevToolsFailure()
        }
    }

    private func showStandaloneDevToolsFailure() {
        feedback = SessionFeedback(title: "Could not start standalone DevTools",
                                   detail: "Check the Dart SDK in DevTools settings and try again.")
    }

    private func presentBrowser(_ page: FlutterBrowserPage, destination: (url: URL, inspectorFallback: Bool)) {
        let canReuse = page == .inspector && !destination.inspectorFallback
        if canReuse, let debug, debug.openedInspector == destination.url {
            guard inspectorFocusTask == nil else { return }
            inspectorFocusTask = Task { [weak self, weak debug, focusInspector] in
                let reused = await focusInspector(destination.url)
                guard let self, !Task.isCancelled else { return }
                self.inspectorFocusTask = nil
                guard let debug, self.debug === debug, self.canOpenBrowser,
                      debug.openedInspector == destination.url else { return }
                self.finishPresentingBrowser(page, destination: destination, reused: reused)
            }
        } else {
            finishPresentingBrowser(page, destination: destination, reused: false)
        }
    }

    private func finishPresentingBrowser(_ page: FlutterBrowserPage,
                                         destination: (url: URL, inspectorFallback: Bool), reused: Bool) {
        if !reused && !openURL(destination.url) {
            feedback = SessionFeedback(title: "Could not open \(page.title)",
                                       detail: "The system could not open this address. Check the default browser and current connection, then try again.")
        } else if destination.inspectorFallback {
            feedback = SessionFeedback(title: "Opened DevTools for the current session. Select Inspector.", detail: nil)
        } else {
            if page == .inspector { debug?.openedInspector = destination.url }
            feedback = SessionFeedback(title: "Opened \(page.title)", detail: nil)
        }
    }

    func waitUntilIdle() async { await operation?.value }

    func beginFinishingTermination() {
        isFinishingTermination = true
        stop()
    }

    func finishForTermination() async -> Bool {
        beginFinishingTermination()
        defer { isFinishingTermination = false }
        let checks = Array(doctorTasks.values)
        for check in checks { check.cancel() }
        for check in checks { await check.value }
        await waitUntilIdle()
        return canTerminate
    }

    private func execute(_ launch: PreparedLaunch, command: SessionCommand,
                         store: ProjectRecoveryStore, lease: ProjectLease, device: FlutterDevice? = nil) async {
        guard !stopRequested else {
            status = .ready
            return
        }
        activeLaunch = device.map { ActiveLaunch(configurationName: launch.name, device: $0) }
        defer { activeLaunch = nil }
        debugEndReason = nil
        feedback = nil
        var record: ProjectRecoveryRecord?
        do {
            if let post = launch.post {
                record = try store.write(task: post, lease: lease)
            }
        } catch {
            if let visible = try? store.read(project: launch.project) {
                markRecovery(visible, "Could not confirm that the recovery record was saved: \(LocalizedStringResource.appIssue(error))")
            } else {
                status = .launchBlocked
                message = .appIssue(error)
            }
            return
        }
        if let pre = launch.pre, !stopRequested {
            status = .runningPreTask
            let result: SessionExit
            do {
                try validateFixtureExecution(pre, in: launch.project)
                result = await execute(pre.command, lease: lease, startsRun: true)
            } catch {
                if let record { markRecovery(record, .appIssue(error)) }
                else { status = .launchBlocked; message = .appIssue(error) }
                return
            }
            if result != .exited(0) {
                let reason: LocalizedStringResource = "Pre-launch task \(pre.label) failed (\(result.detail))"
                if let record { markRecovery(record, reason) }
                else { status = .preTaskFailed; message = reason }
                return
            }
        }

        if !stopRequested, let toolchain, let device, device.platform == "ios", device.isSimulator {
            do {
                try await toolchain.showSimulator(device.id, FlutterToolchain.probeEnvironment(environment, launch.project))
            } catch {
                if !stopRequested {
                    feedback = SessionFeedback(title: "Could not open the iOS simulator window", detail: nil)
                }
            }
        }

        if !stopRequested {
            guard launch.mode == "debug" else {
                if let record { markRecovery(record, "Execution blocked because the configuration is not in Debug mode") }
                else { message = "Execution blocked because the configuration is not in Debug mode" }
                return
            }
            let flutter = device.map { device in
                FlutterDebugSession(deviceID: device.id, verifyVM: verifyVM, timing: debugTiming, sdk: sdk,
                                    connectionChanged: { [weak self] ready in
                    guard let self else { return }
                    self.vmConnected = ready
                    guard !self.stopRequested else { return }
                    if ready {
                        self.missingDeviceScans = 0
                        self.vmWaitTimeout?.cancel()
                        self.status = .running
                        self.debugStatusMessage = nil
                    } else {
                        self.status = .connectionInterrupted
                        self.debugStatusMessage = "The VM Service connection was interrupted. Reconnecting. You can stop the current session."
                    }
                }, browserAvailabilityChanged: { [weak self] available in
                    self?.hasCurrentDevToolsAddress = available
                }, openSource: { [weak self, project = launch.project] notification, opensOnSelection in
                    guard let self, !self.stopRequested, self.vmConnected,
                          let location = InspectorSourceLocation(notification: notification, project: project,
                                                                 opensOnSelection: opensOnSelection && !(self.standaloneDevToolsVersion
                                                                     .map(StandaloneDevToolsSDK.hasSourceLinks) ?? false)) else { return }
                    self.inspectorEditor.open(location) { [weak self] in
                        self?.feedback = SessionFeedback(title: "Could not open the source editor",
                                                         detail: "Check that the editor selected in Settings is installed.")
                    }
                })
            }
            debug = flutter
            status = flutter == nil ? .running : .startingFlutter
            let result = await execute(command, lease: lease, flutter: flutter, device: device, startsRun: launch.pre == nil)
            if result == .unconfirmed {
                if let record { markRecovery(record, result.detail) }
                else { status = .processUnconfirmed; message = result.detail }
                return
            }
            if !stopRequested {
                if flutter != nil {
                    debugEndReason = result == .exited(0)
                        ? "The debug process exited (\(result.detail))"
                        : "The debug process failed: \(result.detail). Check the run logs and try again."
                } else if result != .exited(0) {
                    message = "Debug process: \(result.detail)"
                }
            }
        }
        canStop = false
        if let record, let post = launch.post {
            _ = await restore(post, record: record, project: launch.project, store: store, lease: lease)
        } else {
            status = .ready
        }
    }

    private func restore(_ post: PreparedTask, record: ProjectRecoveryRecord, project: URL,
                         store: ProjectRecoveryStore, lease: ProjectLease) async -> Bool {
        activeRecoveryTaskLabel = post.label
        defer { activeRecoveryTaskLabel = nil }
        status = .restoringEnvironment
        recoveryFailure = nil
        do {
            try lease.verifyProject()
            try store.verifyProject(record, project)
            try validateFixtureExecution(post, in: project)
        } catch {
            markRecovery(record, .appIssue(error))
            return false
        }
        let result = await execute(post.command, lease: lease)
        guard result == .exited(0) else {
            let failure = RecoveryFailure(taskLabel: post.label, exit: result)
            markRecovery(record, failure.message, failure: failure)
            return false
        }
        do {
            try store.remove(record, lease: lease)
            recovery = nil
            recoveryReason = nil
            status = .ready
            discoverRecovery()
            return recovery == nil && recoveryStoreIssue == nil
        } catch {
            markRecovery(record, .appIssue(error))
            return false
        }
    }

    private func validateFixtureExecution(_ task: PreparedTask, in project: URL) throws {
        guard allowedRoot != nil else { return }
        let directory = try validate(project)
        let command = task.command
        let cwd = try ProjectLocation.directory(URL(fileURLWithPath: command.directory, isDirectory: true))
        try ProjectLocation.validateFixtureTask(executable: command.executable, arguments: command.arguments,
                                                cwd: cwd, project: directory)
    }

    private func execute(_ command: SessionCommand, lease: ProjectLease, flutter: FlutterDebugSession? = nil,
                         device: FlutterDevice? = nil, startsRun: Bool = false) async -> SessionExit {
        let lines = SessionLineStream { [weak self, weak flutter] line, isError, generation in
            guard let self else { return }
            let publish: (String, SessionLogTone?) -> Void = { text, tone in
                guard generation == self.logGeneration else { return }
                self.appendLog(FlutterLogRedaction.clean(text), tone: tone)
            }
            if let flutter {
                flutter.receive(line, isError: isError, output: publish)
            } else {
                publish(line, isError ? .diagnostic : nil)
            }
        }
        defer {
            lines.finish()
            flushLogs()
            flutter?.finish()
            if flutter != nil {
                inspectorFocusTask?.cancel()
                inspectorFocusTask = nil
                debug = nil
                debugLease = nil
                hasCurrentDevToolsAddress = false
                debugStatusMessage = nil
                feedback = nil
                isHotOperationPending = false
                vmWaitTimeout?.cancel()
                vmWaitTimeout = nil
                deviceMonitor?.cancel()
                deviceMonitor = nil
                missingDeviceScans = 0
                stopFallback?.cancel()
                stopFallback = nil
            }
        }
        do {
            if flutter != nil { debugLease = lease }
            let process = try runner.start(command, lease: lease, output: { data, isError, generation in
                lines.receive(data, isError: isError, generation: generation)
            }, outputGeneration: { [logBoundary] in
                logBoundary.withLock { $0 }
            }, machineProtocol: flutter != nil, childStarted: { [weak self, weak flutter] time in
                guard let self else { return }
                if startsRun { self.resetLogs() }
                guard let flutter, let device, self.debug === flutter, !self.stopRequested else { return }
                self.monitorDebugProcess(startedAt: time, flutter: flutter, device: device)
            })
            active = process
            let result = await process.wait()
            active = nil
            var exit = result.exit
            if let flutter {
                flutter.finish()
                standaloneStartupTimeout?.cancel()
                standaloneStartupTimeout = nil
                if let server = standaloneServer {
                    server.process.stop()
                    let standaloneResult = await server.process.wait()
                    if standaloneResult.exit == .unconfirmed { exit = .unconfirmed }
                }
                standaloneServer = nil
            }
            if exit == .unconfirmed || executionIsUnconfirmed {
                executionIsUnconfirmed = true
                blockedLease = lease
                return .unconfirmed
            }
            return exit
        } catch let failure as SessionSpawn.SpawnError {
            return .launchFailed(failure.code)
        } catch {
            return .launchFailed(EIO)
        }
    }

    private func monitorDebugProcess(startedAt time: UInt64, flutter: FlutterDebugSession, device: FlutterDevice) {
        if status == .startingFlutter {
            status = .waitingForVM
            let delay = max(.zero, .seconds(60) - debugTiming.elapsedSinceStart(time))
            vmWaitTimeout = Task { [weak self, weak flutter, debugTiming] in
                do { try await debugTiming.sleep(delay) }
                catch { return }
                guard let self, let flutter, !Task.isCancelled, self.debug === flutter,
                      !self.stopRequested, self.status == .waitingForVM else { return }
                self.status = .waitingLonger
                self.debugStatusMessage = "Still waiting for VM Service. You can keep waiting or stop the session."
            }
        }
        guard let toolchain, let sdk else { return }
        deviceMonitor = Task { [weak self, weak flutter, debugTiming, environment, project] in
            while !Task.isCancelled {
                do { try await debugTiming.sleep(.seconds(5)) }
                catch { return }
                let availability = await toolchain.availability(of: device, using: sdk,
                                                                environment: environment, project: project)
                guard let self, let flutter, !Task.isCancelled, self.debug === flutter, !self.stopRequested else { return }
                switch availability {
                case .disconnected:
                    break
                case .missing where flutter.hasVerifiedVM && !self.vmConnected:
                    self.missingDeviceScans += 1
                    guard self.missingDeviceScans >= 2 else { continue }
                default:
                    self.missingDeviceScans = 0
                    continue
                }
                self.devices.removeAll { $0.id == device.id }
                self.stop(disconnectedDevice: device)
                return
            }
        }
    }

    private func appendLog(_ output: String, tone: SessionLogTone?) {
        guard !output.isEmpty else { return }
        let end = logEndUTF16 + output.utf16.count
        if let tone { pendingLogSpans.append(SessionLogSpan(range: logEndUTF16..<end, tone: tone)) }
        logEndUTF16 = end
        pendingLogs += output
        guard logFlush == nil else { return }
        logFlush = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(100)) }
            catch { return }
            self?.flushLogs()
        }
    }

    private func flushLogs() {
        logFlush?.cancel()
        logFlush = nil
        guard !pendingLogs.isEmpty else { return }
        let combined = logs + pendingLogs
        pendingLogs = ""
        let spans = logSpans + pendingLogSpans
        pendingLogSpans = []
        let bytes = combined.utf8
        guard bytes.count > 64 * 1024 else {
            logSpans = spans
            logs = combined
            return
        }
        var start = bytes.index(bytes.endIndex, offsetBy: -64 * 1024)
        while bytes[start] & 0xc0 == 0x80 { bytes.formIndex(after: &start) }
        logTrimmedUTF16 += String(decoding: bytes[..<start], as: UTF8.self).utf16.count
        logSpans = Array(spans.drop { $0.range.upperBound <= logTrimmedUTF16 })
        logs = String(decoding: bytes[start...], as: UTF8.self)
    }

    private func markRecovery(_ record: ProjectRecoveryRecord, _ reason: LocalizedStringResource,
                              pending: Bool = false, failure: RecoveryFailure? = nil) {
        recovery = record
        recoveryFailure = failure
        status = pending ? .recoveryPending : .recoveryFailed
        recoveryReason = reason
        message = reason
    }

    private func validate(_ url: URL) throws -> URL {
        if let allowedRoot {
            guard let allowedRootIdentity,
                  try ProjectLocation.identity(allowedRoot) == allowedRootIdentity,
                  try ProjectLocation.directory(allowedRoot).path == allowedRoot.path else {
                throw SessionIssue(localized: "The acceptance directory identity has changed")
            }
        }
        return try ProjectLocation.project(url, inside: allowedRoot)
    }

    private func configuration(_ project: URL) -> ProjectConfiguration {
        ProjectConfiguration(project: project, environment: environment, restricted: allowedRoot != nil)
    }
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
