import SwiftUI

struct MenuBarPanelView: View {
    @Environment(\.openWindow) private var openWindow

    let presentation: LaunchPresentation
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

                Text(presentation.selection == nil ? "无调试会话" : "就绪")
                    .foregroundStyle(.secondary)
            }

            PresentationField(title: "项目", value: presentation.selection?.project, fallback: "未选择项目")

            HStack(alignment: .top, spacing: 12) {
                PresentationField(title: "配置", value: presentation.selection?.configuration)
                PresentationField(title: "设备", value: presentation.selection?.device)
            }

            Divider()
            DebugControls(canRun: presentation.selection != nil, run: run)
            BrowserControls()
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
