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
    var prepareForProjectPicker: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FlutterRunlet")
                    .font(.headline)
                Spacer(minLength: 4)
                SessionStatusLabel(session: session, hasDemo: presentation.selection != nil)
                SessionSettingsButton(open: openSettings)
            }

            ProjectControls(session: session, demoName: presentation.selection?.project,
                            prepareForPicker: prepareForProjectPicker)
            DebugControls(session: session, equalWidths: true)
            RunConfigurationControls(session: session, demoConfiguration: presentation.selection?.configuration, runDemo: run)
            PresentationField(field: .device, value: deviceName, originalValue: session?.selectedDeviceName)
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

                Spacer(minLength: 8)

                Button("Quit", action: quit)
            }
            .buttonStyle(.bordered)
        }
        .font(.system(size: 13))
        .padding(16)
        .frame(width: 348, alignment: .leading)
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
#Preview("G1 菜单栏长字段", traits: .fixedLayout(width: 348, height: 320)) {
    MenuBarPanelView(
        presentation: .longFieldsPreview,
        run: {},
        openMainWindow: { _ in },
        openSettings: {},
        quit: {}
    )
}
#endif
