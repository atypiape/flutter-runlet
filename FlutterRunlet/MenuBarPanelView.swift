import SwiftUI

struct MenuBarPanelView: View {
    @Environment(\.openWindow) private var openWindow

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openMainWindow: (OpenWindowAction) -> Void
    let openSettings: (() -> Void)?
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FlutterRunlet")
                    .font(.headline)

                Spacer(minLength: 12)

                Text(session?.status ?? (presentation.selection == nil ? "无调试会话" : "就绪"))
                    .foregroundStyle(.secondary)
            }

            PresentationField(title: "项目", value: session?.project?.lastPathComponent ?? presentation.selection?.project, fallback: "未选择项目")

            HStack(alignment: .top, spacing: 12) {
                PresentationField(title: "配置", value: session?.selection?.name ?? presentation.selection?.configuration)
                PresentationField(title: "设备", value: session?.selection?.launch?.deviceID ?? presentation.selection?.device)
            }

            Divider()
            DebugControls(canRun: session?.canRun ?? (presentation.selection != nil),
                          run: session.map { $0.run } ?? run, canStop: session?.canStop ?? false,
                          stop: { session?.stop() })
            BrowserControls()
            if let session, session.recovery != nil || session.recoveryStoreIssue != nil,
               let reason = session.displayMessage {
                Text(verbatim: reason)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            Divider()

            HStack(spacing: 8) {
                Button("打开主窗口") { openMainWindow(openWindow) }
                Button("设置") { openSettings?() }
                    .disabled(openSettings == nil)

                Spacer(minLength: 8)

                Button("退出", action: quit)
            }
            .buttonStyle(.bordered)
        }
        .font(.system(size: 13))
        .padding(16)
        .frame(width: 404, alignment: .leading)
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
