import SwiftUI

struct MenuBarPanelView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openMainWindow: (OpenWindowAction) -> Void
    let openSettings: (() -> Void)?
    let quit: () -> Void
    var openFlutterSettings: (() -> Void)? = nil
    var prepareForProjectPicker: (() -> (() -> Void)?)? = nil

    private var palette: RunletAppearance { RunletAppearance(scheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                SessionBrand()
                Spacer(minLength: 4)
                if let session { RecoveryRetryButton(session: session) }
                SessionStatusLabel(session: session, hasDemo: presentation.selection != nil)
                SessionSettingsButton(open: openSettings)
            }
            .padding(.horizontal, 15)
            .frame(height: 45)
            palette.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: 10) {
                ProjectControls(session: session, demoName: presentation.selection?.project,
                                prepareForPicker: prepareForProjectPicker)
                DebugControls(session: session)
                RunConfigurationControls(session: session, demoConfiguration: presentation.selection?.configuration, runDemo: run)
                DeviceSelectionControls(session: session, demoDevice: presentation.selection?.device)
                BrowserControls(session: session)
                SessionFeedbackView(session: session)
                if let session, session.status != .restoringEnvironment {
                    let showsQuickRetry = session.status == .recoveryFailed && session.recoveryAction == .retry
                    RecoveryDetails(session: session, showMessage: !showsQuickRetry, showRetry: !showsQuickRetry)
                }
                if let session, session.recoveryMessage == nil, let reason = session.displayMessage {
                    Text(reason)
                        .lineLimit(2)
                        .foregroundStyle(palette.secondary)
                }
                if session?.sdkIssue != nil, let openFlutterSettings {
                    Button("Open Flutter Settings", action: openFlutterSettings)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            palette.divider.frame(height: 1)
            HStack {
                footerButton("Main Window", label: "Open Main Window", icon: "Window") { openMainWindow(openWindow) }
                Spacer(minLength: 8)
                footerButton("Quit", label: "Quit", icon: "Quit", action: quit)
            }
            .padding(.horizontal, 15)
            .frame(height: 46)
            .background(palette.toolbar)
        }
        .font(.system(size: 12))
        .foregroundStyle(palette.primary)
        .background(palette.window)
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(palette.border).allowsHitTesting(false) }
        .clipShape(.rect(cornerRadius: 14))
        .frame(width: 348, alignment: .leading)
    }

    private func footerButton(_ title: LocalizedStringResource, label: LocalizedStringResource,
                              icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                RunletIcon(icon, size: 14)
                Text(title).font(RunletType.localized(locale, size: 12))
            }
            .foregroundStyle(palette.secondary)
            .frame(minHeight: 30)
        }
        .buttonStyle(RunletButtonStyle())
        .accessibilityLabel(Text(label))
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
