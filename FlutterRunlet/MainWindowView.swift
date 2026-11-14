import AppKit
import SwiftUI

struct MainWindowView: View {
    @Environment(\.locale) private var locale

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openSettings: (() -> Void)?
    let openAbout: (() -> Void)?
    var openFlutterSettings: (() -> Void)? = nil

    @State private var isLogExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PresentationField(field: .project, value: session?.project?.lastPathComponent ?? presentation.selection?.project,
                              fallback: "No project selected")

            HStack(alignment: .top, spacing: 16) {
                if let session, session.project != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configuration").foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Picker("Configuration", selection: Binding(get: { session.selectedID }, set: session.select)) {
                                Text("Select a configuration").tag(nil as Int?)
                                ForEach(session.choices) { choice in
                                    Text(choice.issue.map { "\(choice.title) · \($0)" } ?? choice.title)
                                        .tag(choice.id as Int?)
                                }
                            }
                            .labelsHidden()
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .help(session.selection.map { locale.appString($0.title) } ?? "")
                            .disabled(session.isBusy || session.configurationIsStale || session.choices.isEmpty)

                            FullNameButton(field: .configuration, name: session.selection.map { locale.appString($0.title) })
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    PresentationField(field: .configuration, value: presentation.selection?.configuration)
                }
                Group {
                    if let session, session.usesFlutterToolchain, session.project != nil {
                        deviceField(session)
                    } else {
                        PresentationField(field: .device, value: session?.selection?.launch?.deviceID ?? presentation.selection?.device)
                    }
                }
                .frame(maxWidth: 240)
            }

            DebugControls(session: session, canRunDemo: presentation.selection != nil, runDemo: run)
            sessionDetails
                .layoutPriority(1)
            logs

            if !isLogExpanded {
                Spacer(minLength: 0)
            }

            Divider()
            Text(session?.project == nil && presentation.selection == nil ? "No project selected" : "Project Selected")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Open Project", systemImage: "folder", action: openProject)
                    .disabled(session == nil)
                    .overlay {
                        ProjectToolTip()
                            .accessibilityHidden(true)
                    }

                if let session, session.project != nil {
                    Button("Reload Configuration", systemImage: "arrow.clockwise", action: session.reload)
                        .disabled(session.isBusy)
                        .help("Reload Configuration")
                }

                Button {
                    openSettings?()
                } label: {
                    Image(systemName: "gearshape")
                }
                .disabled(openSettings == nil)
                .help("Settings")
                .accessibilityLabel("Settings")

                Button {
                    openAbout?()
                } label: {
                    Image(systemName: "info.circle")
                }
                .disabled(openAbout == nil)
                .help("About FlutterRunlet")
                .accessibilityLabel("About FlutterRunlet")
            }
        }
    }

    private func deviceField(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Device").foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Picker("Device", selection: Binding(get: { session.selectedDeviceID }, set: session.selectDevice)) {
                    Text("Select a debug device").tag(nil as String?)
                    if let id = session.selectedDeviceID, session.selectedDevice == nil {
                        let name = session.selectedDeviceName ?? id
                        Text(verbatim: session.deviceIsOffline ? locale.appString("\(name) · Offline") : name)
                            .tag(id as String?)
                    }
                    ForEach(session.devices) { device in
                        Text(verbatim: device.name).tag(device.id as String?)
                    }
                }
                .labelsHidden()
                .lineLimit(1)
                .truncationMode(.tail)
                .help(session.selectedDeviceName ?? "")
                .disabled(session.isBusy || session.isStartingSimulator || session.isRefreshingDevices || session.devices.isEmpty)
                FullNameButton(field: .device, name: session.selectedDeviceName)
                Button("Refresh Devices", systemImage: "arrow.clockwise", action: session.refreshDevices)
                    .labelStyle(.iconOnly)
                    .help("Refresh Devices")
                    .disabled(!session.canRefreshDevices || session.isStartingSimulator || session.isRefreshingDevices)
            }
            if !session.simulators.isEmpty {
                Menu("Start iOS Simulator", systemImage: "iphone") {
                    ForEach(session.simulators) { simulator in
                        Button {
                            session.startSimulator(simulator.id)
                        } label: {
                            Text(verbatim: simulator.name)
                        }
                    }
                }
                .disabled(!session.canStartSimulator)
            }
            if session.isStartingSimulator {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Starting iOS Simulator")
            }
            if let issue = session.simulatorIssue {
                Text(issue).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(session.selectedDeviceName ?? "")
    }

    private func openProject() {
        guard let session, session.requestProjectChange() else { return }
        let panel = NSOpenPanel()
        panel.title = locale.appString("Open Flutter Project")
        panel.message = locale.appString("Select the folder for a Flutter project.")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            session.open(url)
        }
    }

    private var sessionDetails: some View {
        GroupBox("Debug Session") {
            VStack(alignment: .leading, spacing: 8) {
                if let selection = presentation.selection {
                    Text("Ready")
                        .fontWeight(.semibold)
                    Text(verbatim: selection.configuration)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: selection.device)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("VM Service Disconnected")
                        .foregroundStyle(.secondary)
                } else if let session, session.project != nil || session.displayMessage != nil {
                    Text(session.status.title).fontWeight(.semibold)
                    if session.isBusy, let configuration = session.selection?.name, let device = session.selectedDevice {
                        Text(verbatim: "\(configuration) · \(device.name)")
                            .lineLimit(2)
                        Text(session.vmConnected ? "VM Service Connected" : "VM Service Disconnected")
                            .foregroundStyle(.secondary)
                    }
                    if let issue = session.displayMessage, session.recoveryMessage == nil {
                        Text(session.configurationIsStale && !session.choices.isEmpty ? "Configuration Out of Date · \(issue)" : issue)
                            .foregroundStyle(.secondary)
                    }
                    RecoveryDetails(session: session)
                    if session.sdkIssue != nil, let openFlutterSettings {
                        Button("Open Flutter Settings", action: openFlutterSettings)
                    }
                    if let issue = session.taskIssue, issue != session.displayMessage {
                        Text(issue).foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Debug Session")
                        .foregroundStyle(.secondary)
                }

                BrowserControls(session: session)
                SessionFeedbackView(session: session)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var logs: some View {
        DisclosureGroup(isExpanded: $isLogExpanded) {
            SessionLogView(contents: logContents, trimmedUTF16: session?.logTrimmedUTF16 ?? 0)
                .id(session?.logGeneration)
                .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
                .clipShape(.rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(nsColor: .separatorColor))
                        .allowsHitTesting(false)
                }
                .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Text("Run Logs")
                Spacer(minLength: 0)
                Button("Copy Logs") { session?.copyLogs() }
                    .disabled(session?.logs.isEmpty != false)
                Button("Clear Logs") { session?.clearLogs() }
                    .disabled(session?.logs.isEmpty != false)
            }
            .buttonStyle(.borderless)
        }
    }

    private var logContents: String {
        if let session, !session.logs.isEmpty { return session.logs }
        if session?.didClearLogs == true { return locale.appString("Logs cleared. New output will appear here.") }
        return locale.appString("No run logs yet. Output will appear here after debugging starts.")
    }
}

struct RecoveryDetails: View {
    let session: SessionController

    var body: some View {
        if let message = session.recoveryMessage {
            Text(message)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let record = session.recovery, let action = session.recoveryAction {
            Text(verbatim: "\(record.projectPath) · \(record.taskLabel)")
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .help("\(record.projectPath) · \(record.taskLabel)")
            Button(action: session.performRecoveryAction) {
                Text(action.title)
            }
            .disabled(!session.canPerformRecoveryAction)
        }
    }
}

private struct SessionLogView: NSViewRepresentable {
    let contents: String
    let trimmedUTF16: Int

    func makeNSView(context: Context) -> SessionLogScrollView {
        SessionLogScrollView()
    }

    func updateNSView(_ scrollView: SessionLogScrollView, context: Context) {
        scrollView.setLogAccessibilityLabel(context.environment.locale.appString("Run Logs"))
        scrollView.scheduleUpdate(contents, trimmedUTF16: trimmedUTF16)
    }
}

final class SessionLogScrollView: NSScrollView {
    private struct ReadingAnchor {
        let character: Int
        let offset: CGPoint
    }

    private let logText = NSTextView(frame: .zero)
    private let logFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private var trimmedUTF16 = 0
    private var lastUpdate: ContinuousClock.Instant?
    private var pendingUpdate: (contents: String, trimmedUTF16: Int)?
    private var updateTask: Task<Void, Never>?

    init() {
        super.init(frame: .zero)
        drawsBackground = false
        hasHorizontalScroller = true
        hasVerticalScroller = true
        autohidesScrollers = true
        logText.drawsBackground = false
        logText.isEditable = false
        logText.isSelectable = true
        logText.isRichText = false
        logText.font = logFont
        logText.textColor = .textColor
        logText.textContainerInset = NSSize(width: 6, height: 4)
        logText.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        logText.textContainer?.containerSize = logText.maxSize
        logText.textContainer?.widthTracksTextView = false
        documentView = logText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setLogAccessibilityLabel(_ label: String) {
        logText.setAccessibilityLabel(label)
    }

    override func layout() {
        let visible = documentVisibleRect
        let follow = followsBottom(visible)
        super.layout()
        sizeDocument(origin: visible.origin, follow: follow)
    }

    func scheduleUpdate(_ contents: String, trimmedUTF16: Int) {
        pendingUpdate = (contents, trimmedUTF16)
        guard updateTask == nil else { return }
        let now = ContinuousClock.now
        guard let deadline = lastUpdate?.advanced(by: .milliseconds(100)), now < deadline else {
            applyPendingUpdate()
            return
        }
        updateTask = Task { [weak self] in
            try? await ContinuousClock().sleep(until: deadline)
            self?.applyPendingUpdate()
        }
    }

    private func applyPendingUpdate() {
        updateTask = nil
        guard let update = pendingUpdate else { return }
        pendingUpdate = nil
        lastUpdate = .now
        show(update.contents, trimmedUTF16: update.trimmedUTF16)
    }

    func show(_ contents: String, trimmedUTF16: Int) {
        let old = logText.string as NSString
        let textChanged = !old.isEqual(to: contents)
        guard textChanged || self.trimmedUTF16 != trimmedUTF16 else { return }
        let visible = documentVisibleRect
        let follow = followsBottom(visible)
        let removed = max(0, trimmedUTF16 - self.trimmedUTF16)
        self.trimmedUTF16 = trimmedUTF16
        let retained = removed <= old.length ? old.substring(from: removed) : nil
        let retainsText = retained.map { contents.utf16.starts(with: $0.utf16) } ?? false
        let oldAnchor = !follow && removed > 0 ? readingAnchor(in: visible) : nil
        let selection: [NSValue] = retainsText ? logText.selectedRanges.compactMap { value in
            let range = value.rangeValue
            guard NSMaxRange(range) >= removed else { return nil }
            let start = max(range.location, removed)
            return NSValue(range: NSRange(location: start - removed, length: NSMaxRange(range) - start))
        } : []
        if textChanged, let storage = logText.textStorage {
            let attributes: [NSAttributedString.Key: Any] = [.font: logFont, .foregroundColor: NSColor.textColor]
            if retainsText, let retained {
                let suffix = (contents as NSString).substring(from: retained.utf16.count)
                storage.beginEditing()
                if removed > 0 { storage.deleteCharacters(in: NSRange(location: 0, length: removed)) }
                storage.append(NSAttributedString(string: suffix, attributes: attributes))
                storage.endEditing()
            } else {
                storage.setAttributedString(NSAttributedString(string: contents, attributes: attributes))
            }
        }
        if selection.isEmpty {
            logText.setSelectedRange(NSRange(location: 0, length: 0))
        } else {
            logText.selectedRanges = selection
        }
        let anchor: ReadingAnchor?
        if retainsText, let oldAnchor, oldAnchor.character >= removed {
            anchor = ReadingAnchor(character: oldAnchor.character - removed, offset: oldAnchor.offset)
        } else {
            anchor = nil
        }
        let origin = removed > 0 && !follow ? .zero : visible.origin
        sizeDocument(origin: origin, follow: follow, anchor: anchor)
    }

    private func followsBottom(_ visible: NSRect) -> Bool {
        visible.height == 0 || visible.maxY >= logText.bounds.maxY - 2
    }

    private func readingAnchor(in visible: NSRect) -> ReadingAnchor? {
        guard let layout = logText.layoutManager, let container = logText.textContainer else { return nil }
        let origin = logText.textContainerOrigin
        let glyphs = layout.glyphRange(forBoundingRect: visible.offsetBy(dx: -origin.x, dy: -origin.y), in: container)
        guard glyphs.length > 0 else { return nil }
        let first = glyphOrigin(glyphs.location, in: layout)
        return ReadingAnchor(character: layout.characterIndexForGlyph(at: glyphs.location),
                             offset: CGPoint(x: visible.minX - first.x, y: visible.minY - first.y))
    }

    private func glyphOrigin(_ glyph: Int, in layout: NSLayoutManager) -> CGPoint {
        let line = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        let origin = logText.textContainerOrigin
        return CGPoint(x: origin.x + line.minX + layout.location(forGlyphAt: glyph).x, y: origin.y + line.minY)
    }

    private func sizeDocument(origin: CGPoint, follow: Bool, anchor: ReadingAnchor? = nil) {
        guard let layout = logText.layoutManager, let container = logText.textContainer else { return }
        layout.ensureLayout(for: container)
        let used = layout.usedRect(for: container).integral
        let viewport = contentView.bounds.size
        let size = NSSize(width: max(viewport.width, used.maxX + logText.textContainerInset.width * 2),
                          height: max(viewport.height, used.maxY + logText.textContainerInset.height * 2))
        if logText.frame.size != size { logText.setFrameSize(size) }
        let maxY = max(0, size.height - viewport.height)
        var target = origin
        if let anchor, anchor.character < (logText.textStorage?.length ?? 0) {
            let glyph = glyphOrigin(layout.glyphIndexForCharacter(at: anchor.character), in: layout)
            target = CGPoint(x: glyph.x + anchor.offset.x, y: glyph.y + anchor.offset.y)
        }
        contentView.scroll(to: CGPoint(x: min(max(0, target.x), max(0, size.width - viewport.width)),
                                       y: follow ? maxY : min(max(0, target.y), maxY)))
        reflectScrolledClipView(contentView)
    }
}

private struct ProjectToolTip: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ToolTipView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = context.environment.locale.appString("Open Project")
    }

    private final class ToolTipView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}

enum SessionField {
    case project, configuration, device

    var title: LocalizedStringResource {
        switch self {
        case .project: "Project"
        case .configuration: "Configuration"
        case .device: "Device"
        }
    }

    var fullNameAction: LocalizedStringResource {
        switch self {
        case .project: "Show Full Project Name"
        case .configuration: "Show Full Configuration Name"
        case .device: "Show Full Device Name"
        }
    }
}

struct PresentationField: View {
    let field: SessionField
    let value: String?
    var fallback: LocalizedStringResource = "—"
    var originalValue: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.title)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Group {
                    if let value {
                        Text(verbatim: value)
                    } else {
                        Text(fallback)
                    }
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .help(originalValue ?? value ?? "")

                FullNameButton(field: field, name: originalValue ?? value)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FullNameButton: View {
    let field: SessionField
    let name: String?
    @State private var isShowing = false

    var body: some View {
        if let name {
            Button {
                isShowing = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(field.fullNameAction))
            .help(Text(field.fullNameAction))
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                Text(verbatim: name)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 360, alignment: .leading)
                    .padding()
            }
        }
    }
}

struct DebugControls: View {
    @Environment(\.locale) private var locale

    static let runTitle: LocalizedStringResource = "Run"
    static let runAccessibilityLabel: LocalizedStringResource = "Run Current Debug Configuration"

    let session: SessionController?
    let canRunDemo: Bool
    let runDemo: () -> Void

    private var canRun: Bool { session?.canPerformDebugAction(.run) ?? canRunDemo }

    var body: some View {
        HStack(spacing: 8) {
            if canRun {
                runButton.buttonStyle(.borderedProminent)
            } else {
                runButton.buttonStyle(.bordered)
            }

            debugButton("Stop", action: .stop)
            debugButton("Hot Reload", action: .reload)
            debugButton("Hot Restart", action: .restart)
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var runButton: some View {
        Button {
            if let session {
                session.performDebugAction(.run)
            } else {
                runDemo()
            }
        } label: {
            Text(verbatim: locale.appString(Self.runTitle))
        }
        .accessibilityLabel(Text(verbatim: locale.appString(Self.runAccessibilityLabel)))
        .disabled(!canRun)
    }

    private func debugButton(_ title: LocalizedStringResource, action: DebugAction) -> some View {
        Button {
            session?.performDebugAction(action)
        } label: {
            Text(title)
        }
        .disabled(session?.canPerformDebugAction(action) != true)
    }
}

struct SessionFeedbackView: View {
    let session: SessionController?

    var body: some View {
        if let session, let feedback = session.feedback {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedback.title).fontWeight(.semibold)
                    if let detail = feedback.detail {
                        Text(detail)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Button("Dismiss", action: session.dismissFeedback)
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct BrowserControls: View {
    let session: SessionController?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button("Open DevTools") { session?.openBrowser(.devTools) }
                Button("Open Inspector") { session?.openBrowser(.inspector) }
            }
            .buttonStyle(.bordered)
            .disabled(session?.canOpenBrowser != true)
            if let session, session.vmConnected, !session.canOpenBrowser {
                Text("No DevTools address is available for the current session")
                    .foregroundStyle(.secondary)
            }
        }
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
