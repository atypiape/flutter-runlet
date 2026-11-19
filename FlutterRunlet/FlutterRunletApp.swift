import AppKit
import Carbon.HIToolbox
import Observation
import ServiceManagement
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var label: LocalizedStringResource {
        switch self {
        case .system: "Follow System"
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }

    func resolve(preferredLanguages: [String]) -> Self {
        guard self == .system else { return self }
        for identifier in preferredLanguages {
            let language = Locale(identifier: identifier).language
            switch language.languageCode?.identifier {
            case "en": return .english
            case "zh" where language.script?.identifier == "Hans": return .simplifiedChinese
            default: continue
            }
        }
        return .english
    }
}

@MainActor
@Observable
final class AppLanguageSettings {
    static let preferenceKey = "appLanguage"

    private let defaults: UserDefaults
    private let preferredLanguages: () -> [String]
    var selection: AppLanguage {
        didSet { defaults.set(selection.rawValue, forKey: Self.preferenceKey) }
    }

    init(defaults: UserDefaults = .standard, preferredLanguages: @escaping () -> [String] = { Locale.preferredLanguages },
         initialSelection: AppLanguage? = nil) {
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        selection = initialSelection ?? defaults.string(forKey: Self.preferenceKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var locale: Locale { Locale(identifier: selection.resolve(preferredLanguages: preferredLanguages()).rawValue) }
}

enum AppAppearance: String, CaseIterable {
    case system, light, dark

    var label: LocalizedStringResource {
        switch self {
        case .system: "Follow System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var name: NSAppearance.Name? {
        switch self {
        case .system: nil
        case .light: .aqua
        case .dark: .darkAqua
        }
    }
}

@MainActor
@Observable
final class AppAppearanceSettings {
    static let preferenceKey = "appAppearance"

    private let defaults: UserDefaults
    private let apply: (NSAppearance.Name?) -> Void
    var selection: AppAppearance {
        didSet {
            defaults.set(selection.rawValue, forKey: Self.preferenceKey)
            apply(selection.name)
        }
    }

    init(defaults: UserDefaults = .standard, initialOverride: NSAppearance.Name? = nil,
         apply: @escaping (NSAppearance.Name?) -> Void = { name in
             NSApplication.shared.appearance = name.flatMap { NSAppearance(named: $0) }
         }) {
        self.defaults = defaults
        self.apply = apply
        selection = defaults.string(forKey: Self.preferenceKey).flatMap(AppAppearance.init(rawValue:)) ?? .dark
        apply(initialOverride ?? selection.name)
    }
}

extension Locale {
    func appString(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = self
        return String(localized: resource)
    }
}

@MainActor
@Observable
final class LoginItemSettings {
    private let readStatus: () -> SMAppService.Status
    private let register: () throws -> Void
    private let unregister: () throws -> Void
    private let appServiceAvailable: Bool

    private(set) var status: SMAppService.Status
    private(set) var issue: LocalizedStringResource?

    convenience init() {
        let service = SMAppService.mainApp
        self.init(readStatus: { service.status }, register: { try service.register() },
                  unregister: { try service.unregister() })
    }

    init(readStatus: @escaping () -> SMAppService.Status, register: @escaping () throws -> Void,
         unregister: @escaping () throws -> Void, appServiceAvailable: Bool = true) {
        self.readStatus = readStatus
        self.register = register
        self.unregister = unregister
        self.appServiceAvailable = appServiceAvailable
        status = readStatus()
    }

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }
    var canChange: Bool {
        guard appServiceAvailable else { return false }
        return switch status {
        case .enabled, .requiresApproval, .notRegistered, .notFound: true
        @unknown default: false
        }
    }
    var statusMessage: LocalizedStringResource? {
        let unavailable: LocalizedStringResource = "The login item status is unavailable. Check Login Items in System Settings."
        guard appServiceAvailable else { return unavailable }
        return switch status {
        case .enabled, .notRegistered, .notFound: nil
        case .requiresApproval: "Allow FlutterRunlet to launch at login in System Settings."
        @unknown default: unavailable
        }
    }

    func refresh() {
        let current = readStatus()
        if current != status { issue = nil }
        status = current
    }

    func setRegistered(_ enabled: Bool) {
        refresh()
        guard canChange, enabled != isRegistered else { return }
        issue = nil
        do {
            if enabled { try register() }
            else { try unregister() }
        } catch {
            status = readStatus()
            issue = "Could not change the login item: \(LocalizedStringResource.appIssue(error)). Check Login Items in System Settings and try again."
            return
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

extension DebugAction {
    init?(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, isRepeat: Bool) {
        guard keyCode == kVK_F5, !isRepeat else { return nil }
        switch modifiers.intersection([.shift, .control, .option, .command]) {
        case []: self = .run
        case [.shift]: self = .stop
        case [.option]: self = .reload
        case [.shift, .command]: self = .restart
        default: return nil
        }
    }
}

@main
struct FlutterRunletApp: App {
    private static let mainSceneID = "main"
    private static let mainRoute = "main"
    private static let aboutSceneID = "about"
    private static let updatePromptSceneID = "update-prompt"
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FlutterRunlet.MainWindow")

    @NSApplicationDelegateAdaptor(AppTermination.self) private var termination
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var panelWindow: PanelWindowReference
    @State private var settingsPage: SettingsView.Page? = .general
    @State private var language: AppLanguageSettings
    @State private var appearance: AppAppearanceSettings
    @State private var loginItem: LoginItemSettings
    @State private var windowKeys: WindowKeys

    private let presentation: LaunchPresentation
    private let presentsMainWindowOnLaunch: Bool
    @State private var session: SessionController
    @State private var updates: UpdatePresentationSource
    #if DEBUG
    private let captureScene: Phase07Scene?
    private let updateDemo: Phase07UpdateDemo?
    @State private var didOpenCaptureScene = false
    #endif

    init() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let legacyFixture = SessionController.fixtureEnabled(arguments: arguments)
        let launchPresentation = legacyFixture ? .empty : LaunchPresentation.resolve(arguments: arguments)
        #if DEBUG
        let scene = legacyFixture || launchPresentation.selection != nil ? nil : Phase07Scene.resolve(arguments: arguments)
        let demo = scene.map { Phase07UpdateDemo(scene: $0) }
        captureScene = scene
        updateDemo = demo
        _updates = State(initialValue: demo?.source ?? UpdatePresentationSource())
        let language = AppLanguageSettings(initialSelection: scene?.language)
        let appearance = AppAppearanceSettings(initialOverride: scene?.appearance)
        let loginItem = scene?.state == .loginUnavailable
            ? LoginItemSettings(readStatus: { .notFound }, register: {}, unregister: {}, appServiceAvailable: false)
            : LoginItemSettings()
        let capturesAuxiliaryWindow = scene != nil
        #else
        _updates = State(initialValue: UpdatePresentationSource())
        let language = AppLanguageSettings()
        let appearance = AppAppearanceSettings()
        let loginItem = LoginItemSettings()
        let capturesAuxiliaryWindow = false
        #endif
        presentation = launchPresentation
        let controller = SessionController.app(arguments: arguments)
        let presentsMainWindow = !capturesAuxiliaryWindow && (presentation.selection != nil || controller.shouldPresentMainWindowOnLaunch)
        presentsMainWindowOnLaunch = presentsMainWindow
        _session = State(initialValue: controller)
        _language = State(initialValue: language)
        _appearance = State(initialValue: appearance)
        _loginItem = State(initialValue: loginItem)
        let panelWindow = PanelWindowReference()
        _panelWindow = State(initialValue: panelWindow)
        _windowKeys = State(initialValue: WindowKeys(session: presentation.selection == nil ? controller : nil, language: language))
        termination.session = presentation.selection == nil ? controller : nil
        termination.language = language
        termination.loginItem = loginItem
        termination.launchActivationPolicy = presentsMainWindow || capturesAuxiliaryWindow ? .regular : .accessory
    }

    private var liveSession: SessionController? { presentation.selection == nil ? session : nil }

    var body: some Scene {
        WindowGroup("FlutterRunlet", id: Self.mainSceneID, for: String.self) { _ in
            MainWindowView(
                presentation: presentation,
                session: liveSession,
                run: { Self.showRunDemo(locale: language.locale) },
                openSettings: showSettings,
                openFlutterSettings: showFlutterSettings
            )
            .frame(minWidth: 480, minHeight: 400)
            .background(MainWindowIdentity(windowKeys: windowKeys))
            .environment(\.locale, language.locale)
        } defaultValue: {
            Self.mainRoute
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 640, height: 520)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                Button(action: showAbout) {
                    Text(verbatim: language.locale.appString("About FlutterRunlet"))
                }
            }
            #if DEBUG
            if let updateDemo {
                CommandMenu("Phase 07") {
                    Button("Clear Update Blocker") { updateDemo.setBlocker(nil) }
                    ForEach(UpdatePresentation.Blocker.allCases, id: \.self) { blocker in
                        Button(action: { updateDemo.setBlocker(blocker) }) {
                            Text(verbatim: language.locale.appString(blocker.explanation))
                        }
                    }
                }
            }
            #endif
        }

        MenuBarExtra {
            MenuBarPanelView(
                presentation: presentation,
                session: liveSession,
                run: { Self.showRunDemo(locale: language.locale) },
                openMainWindow: { action in
                    panelWindow.close()
                    Self.showMainWindow(openWindow: action)
                },
                openSettings: {
                    panelWindow.close()
                    showSettings()
                },
                quit: { NSApp.terminate(nil) },
                openFlutterSettings: {
                    panelWindow.close()
                    showFlutterSettings()
                },
                prepareForProjectPicker: {
                    let restore = panelWindow.suspendForProjectPicker()
                    Self.showMainWindow(openWindow: openWindow)
                    return restore
                }
            )
            .background(WindowKeyAnchor(reference: panelWindow, windowKeys: windowKeys))
            .environment(\.locale, language.locale)
        } label: {
            Image(nsImage: makeMenuBarTemplate())
                .accessibilityLabel("FlutterRunlet")
                .onAppear {
                    termination.installMainWindowHandler(presentOnLaunch: presentsMainWindowOnLaunch) {
                        Self.showMainWindow(openWindow: openWindow, activatesApp: false)
                    }
                    #if DEBUG
                    openCaptureScene()
                    #endif
                }
                .onChange(of: updates.presentation.prompt, initial: true) { old, new in
                    if new != nil { openWindow(id: Self.updatePromptSceneID) }
                    else if old != nil { dismissWindow(id: Self.updatePromptSceneID) }
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            // Let AppKit size the full-height content without adding another title-bar inset.
            GeometryReader { _ in
                SettingsView(session: liveSession, selection: $settingsPage, language: language,
                             appearance: Bindable(appearance).selection, loginItem: loginItem, updates: updates)
                    .environment(\.locale, language.locale)
                    .background(WindowKeyAnchor(windowKeys: windowKeys))
            }
            .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: SettingsView.windowSize.width, height: SettingsView.windowSize.height)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(action: showSettings) {
                    Text(verbatim: language.locale.appString("Settings…"))
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Window(language.locale.appString("About FlutterRunlet"), id: Self.aboutSceneID) {
            GeometryReader { _ in
                AboutView(updates: updates)
                    .environment(\.locale, language.locale)
            }
            .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: AboutView.windowSize.width, height: AboutView.windowSize.height)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .commandsRemoved()

        Window(language.locale.appString(updates.presentation.prompt?.title ?? "Install and Restart"),
               id: Self.updatePromptSceneID) {
            UpdatePromptView(updates: updates)
                .environment(\.locale, language.locale)
                .onDisappear {
                    switch updates.presentation.prompt {
                    case .confirm: updates.perform(.later)
                    case .recovery: updates.perform(.dismissRecovery)
                    case nil: break
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .commandsRemoved()
    }

    private static func showMainWindow(openWindow: OpenWindowAction, activatesApp: Bool = true) {
        setActivationPolicy(.regular)
        if let window = NSApp.windows.first(where: {
            $0.identifier == mainWindowIdentifier && ($0.isVisible || $0.isMiniaturized)
        }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: mainSceneID, value: mainRoute)
        }

        if activatesApp { activateAppIfNeeded() }
    }

    private func showSettings() {
        openSettings()
        if !NSApp.isActive { NSApp.activate() }
    }

    private func showFlutterSettings() {
        settingsPage = .flutter
        showSettings()
    }

    private func showAbout() {
        openWindow(id: Self.aboutSceneID)
        if !NSApp.isActive { NSApp.activate() }
    }

    #if DEBUG
    private func openCaptureScene() {
        guard let captureScene, !didOpenCaptureScene else { return }
        didOpenCaptureScene = true
        Task { @MainActor in
            switch captureScene.destination {
            case .general: settingsPage = .general; showSettings()
            case .flutter: showFlutterSettings()
            case .settingsAbout: settingsPage = .about; showSettings()
            case .about: showAbout()
            case .both:
                settingsPage = .about
                showSettings()
                showAbout()
            case .confirmation, .recovery: break
            }
        }
    }
    #endif

    static func setActivationPolicy(_ policy: NSApplication.ActivationPolicy) {
        if NSApp.activationPolicy() != policy, !NSApp.setActivationPolicy(policy) {
            NSLog("FlutterRunlet could not change the application activation policy.")
        }
    }

    private static func activateAppIfNeeded() {
        if !NSApp.isActive {
            // A status panel can receive clicks while another app is active.
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = false
            configuration.allowsRunningApplicationSubstitution = false
            configuration.addsToRecentItems = false
            NSWorkspace.shared.openApplication(
                at: Bundle.main.bundleURL,
                configuration: configuration,
                completionHandler: nil
            )
        }
    }

    private static func showRunDemo(locale: Locale) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = locale.appString("Demo Mode")
        alert.informativeText = locale.appString("This is a run demonstration.")
        alert.addButton(withTitle: locale.appString("Dismiss"))
        alert.runModal()
    }

    private struct MainWindowIdentity: NSViewRepresentable {
        let windowKeys: WindowKeys

        func makeNSView(context: Context) -> NSView {
            WindowMarker(windowKeys: windowKeys)
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        private final class WindowMarker: NSView {
            private weak var observedWindow: NSWindow?
            private let windowKeys: WindowKeys

            init(windowKeys: WindowKeys) {
                self.windowKeys = windowKeys
                super.init(frame: .zero)
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) { fatalError() }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                guard window !== observedWindow else { return }

                let notifications = NotificationCenter.default
                if let observedWindow {
                    notifications.removeObserver(self, name: NSWindow.willCloseNotification, object: observedWindow)
                }
                observedWindow = window
                if let window {
                    window.identifier = FlutterRunletApp.mainWindowIdentifier
                    windowKeys.register(window, source: .mainWindow)
                    notifications.addObserver(
                        self, selector: #selector(windowWillClose),
                        name: NSWindow.willCloseNotification, object: window
                    )
                    FlutterRunletApp.setActivationPolicy(.regular)
                }
            }

            @objc private func windowWillClose() {
                FlutterRunletApp.setActivationPolicy(.accessory)
            }
        }
    }

    @MainActor
    private final class PanelWindowReference {
        weak var anchor: NSView?

        func close() {
            anchor?.window?.close()
        }

        func suspendForProjectPicker() -> (() -> Void)? {
            guard let window = anchor?.window else { return nil }
            // Keep the menu bar content alive so the picker can return to the panel.
            window.orderOut(nil)
            return { [weak self] in
                guard self?.anchor?.window === window else { return }
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private struct WindowKeyAnchor: NSViewRepresentable {
        var reference: PanelWindowReference? = nil
        let windowKeys: WindowKeys

        func makeNSView(context: Context) -> NSView {
            let anchor = KeyAnchorView(windowKeys: windowKeys, isMenuBar: reference != nil)
            reference?.anchor = anchor
            return anchor
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        private final class KeyAnchorView: NSView {
            private let windowKeys: WindowKeys
            private let isMenuBar: Bool

            init(windowKeys: WindowKeys, isMenuBar: Bool) {
                self.windowKeys = windowKeys
                self.isMenuBar = isMenuBar
                super.init(frame: .zero)
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) { fatalError() }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                if let window {
                    if isMenuBar { windowKeys.register(window, source: .menuBar) }
                    else { windowKeys.registerSettings(window) }
                }
            }
        }
    }
}

@MainActor
private final class WindowKeys {
    private weak var session: SessionController?
    private let language: AppLanguageSettings
    private let mainWindows = NSHashTable<NSWindow>.weakObjects()
    private let menuPanels = NSHashTable<NSWindow>.weakObjects()
    private let settingsWindows = NSHashTable<NSWindow>.weakObjects()
    private var monitor: Any?

    init(session: SessionController?, language: AppLanguageSettings) {
        self.session = session
        self.language = language
    }

    func register(_ window: NSWindow, source: DebugActionSource) {
        switch source {
        case .mainWindow: mainWindows.add(window)
        case .menuBar: menuPanels.add(window)
        }
        installMonitor()
    }

    func registerSettings(_ window: NSWindow) {
        settingsWindows.add(window)
        installMonitor()
    }

    private func installMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated { self?.handleKey(event) == true }
            return handled ? nil : event
        }
    }

    isolated deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard NSApp.modalWindow == nil, let window = NSApp.keyWindow,
              event.window == nil || event.window === window,
              window.isVisible, window.attachedSheet == nil else {
            return false
        }
        let inMainWindow = mainWindows.contains(window)
        let inMenuPanel = menuPanels.contains(window)
        guard inMainWindow || inMenuPanel || settingsWindows.contains(window) else { return false }
        if event.keyCode == kVK_Tab,
           event.modifierFlags.intersection([.command, .option, .control]).isEmpty {
            return true
        }
        guard inMainWindow || inMenuPanel, let session,
              let action = DebugAction(keyCode: event.keyCode, modifiers: event.modifierFlags,
                                                    isRepeat: event.isARepeat) else {
            return false
        }
        return session.performDebugAction(action, source: inMainWindow ? .mainWindow : .menuBar) { launch in
            confirmSessionRestart(launch, locale: language.locale)
        }
    }
}

@MainActor
func confirmSessionRestart(_ launch: ActiveLaunch, locale: Locale) -> Bool {
    let alert = NSAlert()
    alert.messageText = locale.appString("\(launch.configurationName) (\(launch.device.name)) is already running. Restart this session?")
    alert.addButton(withTitle: locale.appString("Restart"))
    alert.addButton(withTitle: locale.appString("Cancel")).keyEquivalent = "\u{1B}"
    return alert.runModal() == .alertFirstButtonReturn
}

@MainActor
private func makeMenuBarTemplate() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let template = NSImage(size: size)

    for scale in ["1x", "2x"] {
        if let url = Bundle.main.url(forResource: "flutterrunlet-menubar-template@\(scale)", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let representation = NSBitmapImageRep(data: data) {
            representation.size = size
            template.addRepresentation(representation)
        }
    }

    template.isTemplate = true
    return template
}
