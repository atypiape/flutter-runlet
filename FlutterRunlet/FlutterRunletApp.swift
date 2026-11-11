import AppKit
import SwiftUI

@main
struct FlutterRunletApp: App {
    private static let mainSceneID = "main"
    private static let mainRoute = "main"
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FlutterRunlet.MainWindow")

    private let presentation = LaunchPresentation.resolve(arguments: Array(CommandLine.arguments.dropFirst()))

    var body: some Scene {
        WindowGroup("FlutterRunlet", id: Self.mainSceneID, for: String.self) { _ in
            MainWindowView(
                presentation: presentation,
                run: Self.showRunDemo,
                openSettings: nil,
                openAbout: nil
            )
            .frame(minWidth: 480, minHeight: 400)
            .background(MainWindowIdentity())
        } defaultValue: {
            Self.mainRoute
        }
        .defaultSize(width: 640, height: 580)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarPanelView(
                presentation: presentation,
                run: Self.showRunDemo,
                openMainWindow: Self.showMainWindow,
                openSettings: nil,
                quit: { NSApp.terminate(nil) }
            )
        } label: {
            Image(nsImage: makeMenuBarTemplate())
                .accessibilityLabel("FlutterRunlet")
        }
        .menuBarExtraStyle(.window)
    }

    private static func showMainWindow(openWindow: OpenWindowAction) {
        if let window = NSApp.windows.first(where: { $0.identifier == mainWindowIdentifier && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: mainSceneID, value: mainRoute)
        }

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
            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                window?.identifier = FlutterRunletApp.mainWindowIdentifier
            }
        }
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
