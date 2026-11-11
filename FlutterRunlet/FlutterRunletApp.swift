import AppKit
import SwiftUI

@main
struct FlutterRunletApp: App {
    private static let mainSceneID = "main"
    private static let mainRoute = "main"
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FlutterRunlet.MainWindow")

    var body: some Scene {
        WindowGroup("FlutterRunlet", id: Self.mainSceneID, for: String.self) { _ in
            Text("未选择项目")
                .frame(minWidth: 480, minHeight: 360)
                .background(MainWindowIdentity())
        } defaultValue: {
            Self.mainRoute
        }
        .defaultSize(width: 640, height: 580)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            EmptyMenuBarPanel()
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

    private struct EmptyMenuBarPanel: View {
        @Environment(\.openWindow) private var openWindow

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("未选择项目")
                Button("打开主窗口") {
                    FlutterRunletApp.showMainWindow(openWindow: openWindow)
                }
                Button("退出") { NSApp.terminate(nil) }
            }
            .padding(16)
            .frame(width: 404, alignment: .leading)
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
