#if DEBUG
import AppKit
#endif

enum LaunchPresentation: Equatable {
    struct Selection: Equatable {
        let project: String
        let configuration: String
        let device: String
    }

    case empty
    case ready(Selection)

    var selection: Selection? {
        guard case .ready(let selection) = self else { return nil }
        return selection
    }

    #if DEBUG
    static let longFieldsPreview: Self = .ready(Selection(
        project: String(repeating: "sample-flutter-app-", count: 7) + "PROJECT-END",
        configuration: String(repeating: "sample-flutter-app(dev)-", count: 6) + "CONFIG-END",
        device: String(repeating: "iOS-Simulator-Preview-", count: 6) + "DEVICE-END"
    ))
    #endif

    static func resolve(arguments: [String]) -> Self {
        #if DEBUG
        if arguments.contains("--g1-ready") {
            return .ready(Selection(
                project: "sample-flutter-app",
                configuration: "sample-flutter-app(dev)",
                device: "iPhone 17 Pro (iOS Simulator)"
            ))
        }
        #endif

        return .empty
    }
}

#if DEBUG
struct Phase07Scene {
    enum Destination: String {
        case general, flutter, settingsAbout = "settings-about", about, both
        case confirmation = "install-confirm", recovery = "recovery-feedback"
    }

    enum Flow: String {
        case update, current, noRelease = "no-release", checkFailed = "check-failed"
        case downloadFailed = "download-failed", verifyFailed = "verify-failed"
        case replaceFailed = "replace-failed", newLaunchFailed = "new-launch-failed"
        case oldReopenFailed = "old-reopen-failed", confirmRace = "confirm-race"
    }

    enum State: String, CaseIterable {
        case idle, check1 = "check-1", check2 = "check-2", check3 = "check-3", check4 = "check-4"
        case available, update1 = "update-1", update2 = "update-2", update3 = "update-3", update4 = "update-4"
        case complete, current, noRelease = "no-release", checkFailed = "check-failed"
        case waitDebugging = "wait-debugging", waitRecovery = "wait-recovery-pending"
        case waitRecoveryFailed = "wait-recovery-failed", waitProcess = "wait-process-unconfirmed"
        case waitRecord = "wait-recovery-unreadable", later, confirm, confirmRace = "confirm-race"
        case downloadFailed = "download-failed", verifyFailed = "verify-failed", replaceFailed = "replace-failed"
        case newLaunchFailed = "new-launch-failed", oldReopenFailed = "old-reopen-failed"
        case loginUnavailable = "login-unavailable"

        var blocker: UpdatePresentation.Blocker? {
            switch self {
            case .waitDebugging: .debugging
            case .waitRecovery: .recoveryPending
            case .waitRecoveryFailed: .recoveryFailed
            case .waitProcess: .processUnconfirmed
            case .waitRecord: .recoveryUnreadable
            default: nil
            }
        }

        var frozenAngle: Double? {
            switch self {
            case .check1, .update1: 0
            case .check2, .update2: -90
            case .check3, .update3: 180
            case .check4, .update4: 90
            default: nil
            }
        }
    }

    let destination: Destination
    let state: State
    let flow: Flow
    let initialBlocker: UpdatePresentation.Blocker?
    let language: AppLanguage?
    let appearance: NSAppearance.Name?
    let fixtureRoot: URL?
    let version: String

    static func resolve(arguments: [String]) -> Self? {
        let keys: Set<String> = [
            "--phase-07-scene", "--phase-07-state", "--phase-07-flow", "--phase-07-blocker",
            "--phase-07-language", "--phase-07-appearance", "--phase-07-fixtures", "--phase-07-version"
        ]
        var options: [String: String] = [:]
        var args = arguments[...]
        while let argument = args.popFirst() {
            guard argument.hasPrefix("--phase-07-") else { continue }
            guard keys.contains(argument), options[argument] == nil,
                  let value = args.popFirst(), !value.hasPrefix("-") else { return nil }
            options[argument] = value
        }
        guard let destination = options["--phase-07-scene"].flatMap(Destination.init(rawValue:)) else { return nil }
        let defaultState: State = switch destination {
        case .confirmation: .confirm
        case .recovery: .oldReopenFailed
        default: .idle
        }
        guard let state = State(rawValue: options["--phase-07-state"] ?? defaultState.rawValue),
              let flow = Flow(rawValue: options["--phase-07-flow"] ?? Flow.update.rawValue) else { return nil }
        let blocker = options["--phase-07-blocker"].flatMap(UpdatePresentation.Blocker.init(rawValue:))
        let language = options["--phase-07-language"].flatMap(AppLanguage.init(rawValue:))
        let appearance: NSAppearance.Name? = switch options["--phase-07-appearance"] {
        case "dark": .darkAqua
        case "light": .aqua
        default: nil
        }
        guard (options["--phase-07-blocker"] == nil || blocker != nil),
              (options["--phase-07-language"] == nil || language == .simplifiedChinese || language == .english),
              (options["--phase-07-appearance"] == nil || appearance != nil) else { return nil }
        let fixtureRoot = options["--phase-07-fixtures"].map { URL(fileURLWithPath: $0, isDirectory: true) }
        if let path = options["--phase-07-fixtures"], !path.hasPrefix("/") { return nil }
        let version = options["--phase-07-version"] ?? "v1.5.0"
        return Self(destination: destination, state: state, flow: flow, initialBlocker: blocker,
                    language: language, appearance: appearance, fixtureRoot: fixtureRoot, version: version)
    }
}

@MainActor
final class Phase07UpdateDemo {
    private let scene: Phase07Scene
    private let stageDuration: Duration
    private var blocker: UpdatePresentation.Blocker?
    private var hasPrompted = false
    private var delay: Task<Void, Never>?
    lazy var source = UpdatePresentationSource(presentation: initialPresentation) { [weak self] action in
        self?.perform(action)
    }

    init(scene: Phase07Scene, stageDuration: Duration = .seconds(3)) {
        self.scene = scene
        self.stageDuration = stageDuration
        self.blocker = scene.state.blocker ?? scene.initialBlocker
        self.hasPrompted = [.later, .confirm, .confirmRace].contains(scene.state)
    }

    private var recoveredApp: URL {
        scene.fixtureRoot?.appending(path: "Recovered FlutterRunlet.app", directoryHint: .isDirectory) ?? Bundle.main.bundleURL
    }

    private var initialPresentation: UpdatePresentation {
        let status: UpdatePresentation.Status
        var prompt: UpdatePresentation.Prompt?
        switch scene.state {
        case .idle, .loginUnavailable: status = .idle
        case .check1, .check2, .check3, .check4: status = .checking
        case .available: status = .available(scene.version)
        case .update1, .update2, .update3, .update4: status = .updating
        case .complete, .current: status = .current
        case .noRelease: status = .noRelease
        case .checkFailed: status = .failed(.check)
        case .downloadFailed: status = .failed(.download)
        case .verifyFailed: status = .failed(.verification)
        case .replaceFailed: status = .failed(.replacement)
        case .newLaunchFailed: status = .failed(.newLaunch)
        case .waitDebugging: status = .waiting(.debugging)
        case .waitRecovery: status = .waiting(.recoveryPending)
        case .waitRecoveryFailed: status = .waiting(.recoveryFailed)
        case .waitProcess: status = .waiting(.processUnconfirmed)
        case .waitRecord: status = .waiting(.recoveryUnreadable)
        case .later: status = .ready
        case .confirm, .confirmRace:
            status = .ready
            prompt = .confirm(version: scene.version)
        case .oldReopenFailed:
            status = .failed(.newLaunch)
            prompt = .recovery(path: recoveredApp.path)
        }
        return .init(status: status, rotation: scene.state.frozenAngle.map(UpdatePresentation.Rotation.frozen) ?? .stationary,
                     displayedVersion: scene.state == .complete ? scene.version : nil, prompt: prompt)
    }

    func setBlocker(_ blocker: UpdatePresentation.Blocker?) {
        self.blocker = blocker
        guard source.presentation.prompt == nil else { return }
        switch source.presentation.status {
        case .ready, .waiting: makeReady()
        default: break
        }
    }

    private func perform(_ action: UpdatePresentationSource.Action) {
        switch action {
        case .primary:
            switch source.presentation.status {
            case .idle, .current, .noRelease, .failed(.check): check()
            case .available, .failed: download()
            case .ready:
                if blocker == nil { showConfirmation() }
                else { makeReady() }
            case .checking, .updating, .waiting: break
            }
        case .install:
            guard case .confirm = source.presentation.prompt else { return }
            let newBlocker = blocker ?? (scene.flow == .confirmRace || scene.state == .confirmRace ? .recoveryPending : nil)
            if let newBlocker {
                blocker = newBlocker
                source.present(.init(status: .waiting(newBlocker)))
            } else {
                stage(.updating) { demo in
                    switch demo.scene.flow {
                    case .replaceFailed: demo.source.present(.init(status: .failed(.replacement)))
                    case .newLaunchFailed: demo.source.present(.init(status: .failed(.newLaunch)))
                    case .oldReopenFailed:
                        demo.source.present(.init(status: .failed(.newLaunch), prompt: .recovery(path: demo.recoveredApp.path)))
                    default: demo.source.present(.init(status: .current, displayedVersion: demo.scene.version))
                    }
                }
            }
        case .later:
            guard case .confirm = source.presentation.prompt else { return }
            makeReady()
        case .dismissRecovery:
            guard case .recovery = source.presentation.prompt else { return }
            source.present(.init(status: .failed(.newLaunch)))
        case .showRelease:
            guard let root = scene.fixtureRoot else { return }
            openLocalFixture(root.appending(path: "release.html"), in: root)
        case .showInFinder:
            if let root = scene.fixtureRoot {
                guard isLocalFixture(recoveredApp, in: root) else { return }
            }
            NSWorkspace.shared.activateFileViewerSelecting([recoveredApp])
        }
    }

    private func check() {
        stage(.checking) { demo in
            let status: UpdatePresentation.Status = switch demo.scene.flow {
            case .current: .current
            case .noRelease: .noRelease
            case .checkFailed: .failed(.check)
            default: .available(demo.scene.version)
            }
            demo.source.present(.init(status: status, displayedVersion: demo.source.presentation.displayedVersion))
        }
    }

    private func download() {
        hasPrompted = false
        stage(.updating) { demo in
            switch demo.scene.flow {
            case .downloadFailed: demo.source.present(.init(status: .failed(.download)))
            case .verifyFailed: demo.source.present(.init(status: .failed(.verification)))
            default: demo.makeReady()
            }
        }
    }

    private func stage(_ status: UpdatePresentation.Status, complete: @escaping (Phase07UpdateDemo) -> Void) {
        delay?.cancel()
        source.present(.init(status: status, rotation: .animated(.now),
                             displayedVersion: source.presentation.displayedVersion))
        delay = Task { [weak self, stageDuration] in
            try? await Task.sleep(for: stageDuration)
            guard !Task.isCancelled, let self else { return }
            complete(self)
        }
    }

    private func makeReady() {
        if let blocker { source.present(.init(status: .waiting(blocker))) }
        else if !hasPrompted { showConfirmation() }
        else { source.present(.init(status: .ready)) }
    }

    private func showConfirmation() {
        hasPrompted = true
        source.present(.init(status: .ready, prompt: .confirm(version: scene.version)))
    }

    private func openLocalFixture(_ url: URL, in root: URL) {
        if isLocalFixture(url, in: root) { NSWorkspace.shared.open(url) }
    }

    private func isLocalFixture(_ url: URL, in root: URL) -> Bool {
        let target = url.resolvingSymlinksInPath().standardizedFileURL
        return target.deletingLastPathComponent().path == root.resolvingSymlinksInPath().standardizedFileURL.path &&
            FileManager.default.fileExists(atPath: target.path)
    }
}
#endif
