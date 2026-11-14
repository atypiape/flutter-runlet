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

    init(defaults: UserDefaults = .standard, preferredLanguages: @escaping () -> [String] = { Locale.preferredLanguages }) {
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        selection = defaults.string(forKey: Self.preferenceKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var locale: Locale { Locale(identifier: selection.resolve(preferredLanguages: preferredLanguages()).rawValue) }
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

    private(set) var status: SMAppService.Status
    private(set) var issue: LocalizedStringResource?

    convenience init() {
        let service = SMAppService.mainApp
        self.init(readStatus: { service.status }, register: { try service.register() },
                  unregister: { try service.unregister() })
    }

    init(readStatus: @escaping () -> SMAppService.Status, register: @escaping () throws -> Void,
         unregister: @escaping () throws -> Void) {
        self.readStatus = readStatus
        self.register = register
        self.unregister = unregister
        status = readStatus()
    }

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }
    var canChange: Bool {
        switch status {
        case .enabled, .requiresApproval, .notRegistered, .notFound: true
        @unknown default: false
        }
    }
    var statusMessage: LocalizedStringResource? {
        switch status {
        case .enabled, .notRegistered, .notFound: nil
        case .requiresApproval: "Allow FlutterRunlet to launch at login in System Settings."
        @unknown default: "The login item status is unavailable. Check Login Items in System Settings."
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
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FlutterRunlet.MainWindow")

    @NSApplicationDelegateAdaptor(AppTermination.self) private var termination
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var panelWindow: PanelWindowReference
    @State private var settingsPage: SettingsView.Page? = .general
    @State private var language: AppLanguageSettings
    @State private var loginItem: LoginItemSettings
    @State private var windowKeys: WindowKeys

    private let presentation: LaunchPresentation
    private let presentsMainWindowOnLaunch: Bool
    @State private var session: SessionController

    init() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        presentation = SessionController.fixtureEnabled(arguments: arguments) ? .empty : LaunchPresentation.resolve(arguments: arguments)
        let controller = SessionController.app(arguments: arguments)
        let presentsMainWindow = presentation.selection != nil || controller.shouldPresentMainWindowOnLaunch
        presentsMainWindowOnLaunch = presentsMainWindow
        _session = State(initialValue: controller)
        let language = AppLanguageSettings()
        _language = State(initialValue: language)
        let loginItem = LoginItemSettings()
        _loginItem = State(initialValue: loginItem)
        let panelWindow = PanelWindowReference()
        _panelWindow = State(initialValue: panelWindow)
        _windowKeys = State(initialValue: WindowKeys(session: presentation.selection == nil ? controller : nil))
        termination.session = presentation.selection == nil ? controller : nil
        termination.language = language
        termination.loginItem = loginItem
        termination.launchActivationPolicy = presentsMainWindow ? .regular : .accessory
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
            .background(PanelWindowAnchor(reference: panelWindow, windowKeys: windowKeys))
            .environment(\.locale, language.locale)
        } label: {
            Image(nsImage: makeMenuBarTemplate())
                .accessibilityLabel("FlutterRunlet")
                .onAppear {
                    termination.installMainWindowHandler(presentOnLaunch: presentsMainWindowOnLaunch) {
                        Self.showMainWindow(openWindow: openWindow, activatesApp: false)
                    }
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(session: liveSession, selection: $settingsPage, language: language, loginItem: loginItem)
                .background(WindowTitle(title: language.locale.appString("FlutterRunlet Settings")))
                .environment(\.locale, language.locale)
        }
        .defaultSize(width: 672, height: 520)
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
            AboutView()
                .background(WindowTitle(title: language.locale.appString("About FlutterRunlet")))
                .environment(\.locale, language.locale)
        }
        .defaultSize(width: 440, height: 480)
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
    }

    fileprivate static func setActivationPolicy(_ policy: NSApplication.ActivationPolicy) {
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

    private struct WindowTitle: NSViewRepresentable {
        let title: String

        func makeNSView(context: Context) -> TitleView { TitleView() }

        func updateNSView(_ view: TitleView, context: Context) {
            view.title = title
        }

        final class TitleView: NSView {
            var title = "" {
                didSet { updateTitle() }
            }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                updateTitle()
            }

            private func updateTitle() {
                guard !title.isEmpty else { return }
                window?.title = title
            }
        }
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

    private struct PanelWindowAnchor: NSViewRepresentable {
        let reference: PanelWindowReference
        let windowKeys: WindowKeys

        func makeNSView(context: Context) -> NSView {
            let anchor = PanelAnchorView(windowKeys: windowKeys)
            reference.anchor = anchor
            return anchor
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        private final class PanelAnchorView: NSView {
            private let windowKeys: WindowKeys

            init(windowKeys: WindowKeys) {
                self.windowKeys = windowKeys
                super.init(frame: .zero)
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) { fatalError() }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                if let window { windowKeys.register(window, source: .menuBar) }
            }
        }
    }
}

@MainActor
private final class WindowKeys {
    private weak var session: SessionController?
    private let mainWindows = NSHashTable<NSWindow>.weakObjects()
    private let menuPanels = NSHashTable<NSWindow>.weakObjects()
    private var monitor: Any?

    init(session: SessionController?) { self.session = session }

    func register(_ window: NSWindow, source: DebugActionSource) {
        switch source {
        case .mainWindow: mainWindows.add(window)
        case .menuBar: menuPanels.add(window)
        }
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
        let source: DebugActionSource
        if mainWindows.contains(window) {
            source = .mainWindow
        } else if menuPanels.contains(window) {
            source = .menuBar
        } else {
            return false
        }
        if event.keyCode == kVK_Tab,
           event.modifierFlags.intersection([.command, .option, .control]).isEmpty {
            return true
        }
        guard let session, let action = DebugAction(keyCode: event.keyCode, modifiers: event.modifierFlags,
                                                    isRepeat: event.isARepeat) else {
            return false
        }
        return session.performDebugAction(action, source: source)
    }
}

@MainActor
private final class AppTermination: NSObject, NSApplicationDelegate {
    var session: SessionController?
    var language: AppLanguageSettings?
    var loginItem: LoginItemSettings?
    var launchActivationPolicy: NSApplication.ActivationPolicy = .regular
    private var reopenMainWindow: (() -> Void)?
    private var replying = false

    private var locale: Locale { language?.locale ?? .current }

    func applicationWillFinishLaunching(_ notification: Notification) {
        FlutterRunletApp.setActivationPolicy(launchActivationPolicy)
    }

    func installMainWindowHandler(presentOnLaunch: Bool, open: @escaping () -> Void) {
        let firstAppearance = reopenMainWindow == nil
        reopenMainWindow = open
        guard firstAppearance, presentOnLaunch else { return }
        // The menu bar scene can appear at login even when SwiftUI skips its default window.
        Task { @MainActor in
            reopenMainWindow?()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let reopenMainWindow else { return true }
        reopenMainWindow()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        loginItem?.refresh()
        session?.recheckInvalidFlutterSDK()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session else { return .terminateNow }
        guard !replying else { return .terminateLater }
        if session.canTerminate && !session.hasPendingEnvironmentChecks { return .terminateNow }
        guard session.isBusy || session.canTerminate else {
            showBlocked(session)
            return .terminateCancel
        }
        replying = true
        if session.isBusy && !confirmStoppingSession() {
            replying = false
            return .terminateCancel
        }
        session.beginFinishingTermination()
        Task {
            let completed = await session.finishForTermination()
            sender.reply(toApplicationShouldTerminate: completed)
            replying = false
            if !completed { showBlocked(session) }
        }
        return .terminateLater
    }

    private func confirmStoppingSession() -> Bool {
        let alert = NSAlert()
        alert.messageText = locale.appString("Stop the session and quit FlutterRunlet?")
        alert.informativeText = locale.appString("FlutterRunlet will wait for managed processes to exit and run the project’s recovery task.")
        alert.addButton(withTitle: locale.appString("Stop and Quit"))
        alert.addButton(withTitle: locale.appString("Cancel"))
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showBlocked(_ session: SessionController) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = locale.appString("FlutterRunlet Cannot Quit Right Now")
        alert.informativeText = locale.appString(session.displayMessage ?? "Finish environment recovery in the main window first.")
        alert.addButton(withTitle: locale.appString("Dismiss"))
        alert.runModal()
    }
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
