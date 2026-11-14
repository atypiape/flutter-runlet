import SwiftUI

struct MenuBarPanelView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.locale) private var locale

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openMainWindow: (OpenWindowAction) -> Void
    let openSettings: (() -> Void)?
    let quit: () -> Void
    var openFlutterSettings: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FlutterRunlet")
                    .font(.headline)

                Spacer(minLength: 12)

                Text((session?.status ?? (presentation.selection == nil ? .idle : .ready)).title)
                    .foregroundStyle(.secondary)
            }

            PresentationField(field: .project, value: session?.project?.lastPathComponent ?? presentation.selection?.project,
                              fallback: "No project selected")

            HStack(alignment: .top, spacing: 12) {
                PresentationField(field: .configuration, value: session?.selection.map { locale.appString($0.title) }
                                  ?? presentation.selection?.configuration)
                PresentationField(field: .device, value: deviceName, originalValue: session?.selectedDeviceName)
            }

            Divider()
            DebugControls(session: session, canRunDemo: presentation.selection != nil, runDemo: run)
            BrowserControls(session: session)
            SessionFeedbackView(session: session)
            if let session {
                RecoveryDetails(session: session)
            }
            if let session, session.recoveryMessage == nil, let reason = session.displayMessage {
                Text(reason)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            if session?.sdkIssue != nil, let openFlutterSettings {
                Button("Open Flutter Settings", action: openFlutterSettings)
            }
            Divider()

            HStack(spacing: 8) {
                Button("Open Main Window") { openMainWindow(openWindow) }
                Button("Settings") { openSettings?() }
                    .disabled(openSettings == nil)

                Spacer(minLength: 8)

                Button("Quit", action: quit)
            }
            .buttonStyle(.bordered)
        }
        .font(.system(size: 13))
        .padding(16)
        .frame(width: 404, alignment: .leading)
    }

    private var deviceName: String? {
        if let session, session.usesFlutterToolchain {
            guard let name = session.selectedDeviceName else { return nil }
            return session.deviceIsOffline ? locale.appString("\(name) · Offline") : name
        }
        return session?.selection?.launch?.deviceID ?? presentation.selection?.device
    }
}

#if DEBUG
#Preview("G1 菜单栏长字段", traits: .fixedLayout(width: 404, height: 278)) {
    MenuBarPanelView(
        presentation: .longFieldsPreview,
        run: {},
        openMainWindow: { _ in },
        openSettings: {},
        quit: {}
    )
}
#endif
