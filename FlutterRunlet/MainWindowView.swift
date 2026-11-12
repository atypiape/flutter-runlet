import AppKit
import SwiftUI

struct MainWindowView: View {
    let presentation: LaunchPresentation
    let run: () -> Void
    let openSettings: (() -> Void)?
    let openAbout: (() -> Void)?

    @State private var isLogExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PresentationField(title: "项目", value: presentation.selection?.project, fallback: "未选择项目")

            HStack(alignment: .top, spacing: 16) {
                PresentationField(title: "配置", value: presentation.selection?.configuration)
                PresentationField(title: "设备", value: presentation.selection?.device)
                    .frame(maxWidth: 240)
            }

            DebugControls(canRun: presentation.selection != nil, run: run)
            session
                .layoutPriority(1)
            logs

            if !isLogExpanded {
                Spacer(minLength: 0)
            }

            Divider()
            Text(presentation.selection == nil ? "未选择项目" : "已选择项目")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("打开项目", systemImage: "folder") {}
                    .disabled(true)
                    .overlay {
                        ProjectToolTip()
                            .accessibilityHidden(true)
                    }

                Button {
                    openSettings?()
                } label: {
                    Image(systemName: "gearshape")
                }
                .disabled(openSettings == nil)
                .help("设置")
                .accessibilityLabel("设置")

                Button {
                    openAbout?()
                } label: {
                    Image(systemName: "info.circle")
                }
                .disabled(openAbout == nil)
                .help("关于 FlutterRunlet")
                .accessibilityLabel("关于 FlutterRunlet")
            }
        }
    }

    private var session: some View {
        GroupBox("调试会话") {
            VStack(alignment: .leading, spacing: 8) {
                if let selection = presentation.selection {
                    Text("就绪")
                        .fontWeight(.semibold)
                    Text(verbatim: selection.configuration)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: selection.device)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("VM Service 未连接")
                        .foregroundStyle(.secondary)
                } else {
                    Text("无调试会话")
                        .foregroundStyle(.secondary)
                }

                BrowserControls()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var logs: some View {
        DisclosureGroup("运行日志", isExpanded: $isLogExpanded) {
            ScrollView([.horizontal, .vertical]) {
                EmptyView()
            }
            .font(.system(size: 12, design: .monospaced))
            .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(nsColor: .separatorColor))
            }
            .padding(.top, 8)
        }
    }
}

private struct ProjectToolTip: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ToolTipView()
        view.toolTip = "打开项目"
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ToolTipView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}

struct PresentationField: View {
    let title: LocalizedStringKey
    let value: String?
    var fallback = "—"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)

            Text(verbatim: value ?? fallback)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(value ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DebugControls: View {
    let canRun: Bool
    let run: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("运行", action: run)
                .buttonStyle(.borderedProminent)
                .disabled(!canRun)

            Button("停止") {}
                .disabled(true)
            Button("热重载") {}
                .disabled(true)
            Button("热重启") {}
                .disabled(true)
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct BrowserControls: View {
    var body: some View {
        HStack(spacing: 8) {
            Button("打开 DevTools") {}
                .disabled(true)
            Button("打开 Inspector") {}
                .disabled(true)
        }
        .buttonStyle(.bordered)
    }
}

#if DEBUG
#Preview("G1 主窗长字段", traits: .fixedLayout(width: 640, height: 580)) {
    MainWindowView(
        presentation: .longFieldsPreview,
        run: {},
        openSettings: {},
        openAbout: {}
    )
}
#endif
