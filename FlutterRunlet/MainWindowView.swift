import AppKit
import SwiftUI

struct MainWindowView: View {
    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openSettings: (() -> Void)?
    let openAbout: (() -> Void)?

    @State private var isLogExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PresentationField(title: "项目", value: session?.project?.lastPathComponent ?? presentation.selection?.project, fallback: "未选择项目")

            HStack(alignment: .top, spacing: 16) {
                if let session, session.project != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("配置").foregroundStyle(.secondary)
                        Picker("配置", selection: Binding(get: { session.selectedID }, set: session.select)) {
                            Text("请选择配置").tag(nil as Int?)
                            ForEach(session.choices) { choice in
                                Text(verbatim: choice.issue.map { "\(choice.name) · \($0)" } ?? choice.name)
                                    .tag(choice.id as Int?)
                            }
                        }
                        .labelsHidden()
                        .disabled(session.isBusy || session.configurationIsStale || session.choices.isEmpty)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    PresentationField(title: "配置", value: presentation.selection?.configuration)
                }
                PresentationField(title: "设备", value: session?.selection?.launch?.deviceID ?? presentation.selection?.device)
                    .frame(maxWidth: 240)
            }

            DebugControls(canRun: session?.canRun ?? (presentation.selection != nil),
                          run: session.map { $0.run } ?? run, canStop: session?.canStop ?? false,
                          stop: { session?.stop() })
            sessionDetails
                .layoutPriority(1)
            logs

            if !isLogExpanded {
                Spacer(minLength: 0)
            }

            Divider()
            Text(session?.project == nil && presentation.selection == nil ? "未选择项目" : "已选择项目")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("打开项目", systemImage: "folder", action: openProject)
                    .disabled(session == nil)
                    .overlay {
                        ProjectToolTip()
                            .accessibilityHidden(true)
                    }

                if let session, session.project != nil {
                    Button("重读配置", systemImage: "arrow.clockwise", action: session.reload)
                        .disabled(session.isBusy)
                        .help("重读配置")
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

    private func openProject() {
        guard let session else { return }
        let panel = NSOpenPanel()
        panel.title = "打开 Flutter 项目"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            session.open(url)
        }
    }

    private var sessionDetails: some View {
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
                } else if let session, session.project != nil || session.displayMessage != nil {
                    Text(session.status).fontWeight(.semibold)
                    if let issue = session.displayMessage {
                        Text(verbatim: session.configurationIsStale && !session.choices.isEmpty ? "配置已过期 · " + issue : issue).foregroundStyle(.secondary)
                    }
                    if let issue = session.taskIssue, issue != session.displayMessage {
                        Text(verbatim: issue).foregroundStyle(.secondary)
                    }
                    if let recovery = session.recovery {
                        Text(verbatim: "\(recovery.projectPath) · \(recovery.taskLabel)")
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        if session.recoveryProjectIsOpen {
                            Button("重试恢复", action: session.retryRecovery)
                                .disabled(session.isBusy || session.recoveryStoreIssue != nil)
                        } else {
                            Button("打开待恢复项目") { session.openRecoveryProject() }
                                .disabled(session.isBusy || session.recoveryStoreIssue != nil)
                        }
                    }
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
                if let session {
                    Text(verbatim: session.logs).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
    var canStop = false
    var stop: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            Button("运行", action: run)
                .buttonStyle(.borderedProminent)
                .disabled(!canRun)

            Button("停止", action: stop)
                .disabled(!canStop)
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
