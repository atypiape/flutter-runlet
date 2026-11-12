import AppKit
import SwiftUI

@main
struct FlutterRunletApp: App {
    private static let mainSceneID = "main"
    private static let mainRoute = "main"
    private static let aboutSceneID = "about"
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FlutterRunlet.MainWindow")

    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var panelWindow = PanelWindowReference()

    private let presentation: LaunchPresentation
    @State private var session: SessionController

    init() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        presentation = SessionController.fixtureEnabled(arguments: arguments) ? .empty : LaunchPresentation.resolve(arguments: arguments)
        _session = State(initialValue: SessionController.app(arguments: arguments))
    }

    private var liveSession: SessionController? { presentation.selection == nil ? session : nil }

    var body: some Scene {
        WindowGroup("FlutterRunlet", id: Self.mainSceneID, for: String.self) { _ in
            MainWindowView(
                presentation: presentation,
                session: liveSession,
                run: Self.showRunDemo,
                openSettings: showSettings,
                openAbout: showAbout
            )
            .frame(minWidth: 480, minHeight: 400)
            .background(MainWindowIdentity())
        } defaultValue: {
            Self.mainRoute
        }
        .defaultSize(width: 640, height: 580)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                Button("关于 FlutterRunlet", action: showAbout)
            }
        }

        MenuBarExtra {
            MenuBarPanelView(
                presentation: presentation,
                session: liveSession,
                run: Self.showRunDemo,
                openMainWindow: { action in
                    panelWindow.close()
                    Self.showMainWindow(openWindow: action)
                },
                openSettings: {
                    panelWindow.close()
                    showSettings()
                },
                quit: { NSApp.terminate(nil) }
            )
            .background(PanelWindowAnchor(reference: panelWindow))
        } label: {
            Image(nsImage: makeMenuBarTemplate())
                .accessibilityLabel("FlutterRunlet")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(session: liveSession)
        }
        .defaultSize(width: 672, height: 520)

        Window("关于 FlutterRunlet", id: Self.aboutSceneID) {
            AboutView()
        }
        .defaultSize(width: 440, height: 480)
        .commandsRemoved()
    }

    private static func showMainWindow(openWindow: OpenWindowAction) {
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

        activateAppIfNeeded()
    }

    private func showSettings() {
        openSettings()
        Self.activateAppIfNeeded()
    }

    private func showAbout() {
        openWindow(id: Self.aboutSceneID)
    }

    private static func setActivationPolicy(_ policy: NSApplication.ActivationPolicy) {
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

    private static func showRunDemo() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "演示模式"
        alert.informativeText = "当前为运行演示。"
        alert.addButton(withTitle: "关闭提示")
        alert.runModal()
    }

    private struct MainWindowIdentity: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            WindowMarker()
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        private final class WindowMarker: NSView {
            private weak var observedWindow: NSWindow?

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
    }

    private struct PanelWindowAnchor: NSViewRepresentable {
        let reference: PanelWindowReference

        func makeNSView(context: Context) -> NSView {
            let anchor = NSView()
            reference.anchor = anchor
            return anchor
        }

        func updateNSView(_ nsView: NSView, context: Context) {}
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
