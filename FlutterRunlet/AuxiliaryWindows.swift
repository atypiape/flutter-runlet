import AppKit
import SwiftUI

struct SettingsView: View {
    static let windowSize = CGSize(width: 640, height: 520)

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    var session: SessionController? = nil
    enum Page: CaseIterable {
        case general, flutter, devTools, about

        var title: LocalizedStringResource {
            switch self {
            case .general: "General"
            case .flutter: "Flutter"
            case .devTools: "DevTools"
            case .about: "About"
            }
        }
    }

    @Binding var selection: Page?
    @Bindable var language: AppLanguageSettings
    var appearance: Binding<AppAppearance>? = nil
    var loginItem: LoginItemSettings? = nil
    var updates = UpdatePresentationSource()
    @State private var showsDoctorOutput = false

    private var palette: RunletAppearance { RunletAppearance(scheme) }
    private var page: Page { selection ?? .general }

    static func launchWindowPreference(_ session: SessionController) -> Binding<Bool> {
        Binding(get: { session.showMainWindowOnLaunch }, set: { session.showMainWindowOnLaunch = $0 })
    }

    var body: some View {
        AuxiliaryWindowLayout(title: page.title, kind: .settings) {
            HStack(spacing: 0) {
                sidebar
                palette.divider.frame(width: 1)
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        navigationIcon(page).foregroundStyle(palette.secondary)
                        Text(page.title)
                            .font(RunletType.localized(locale, size: 15, medium: true))
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 47)
                    .background(palette.toolbar)
                    .contentShape(Rectangle())
                    .gesture(WindowDragGesture())
                    palette.divider.frame(height: 1)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 7) {
                            switch page {
                            case .general: generalSettings
                            case .flutter:
                                if let session, session.usesFlutterToolchain { flutterSettings(session) }
                            case .devTools:
                                if let session { devToolsSettings(session) }
                            case .about: settingsAbout
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 14)
                    }
                }
            }
            .focusEffectDisabled()
        }
        .onChange(of: selection, initial: true) {
            if selection == .flutter { session?.checkFlutterSDKIfNeeded() }
            else { loginItem?.refresh() }
        }
        .onChange(of: session?.doctorResult != nil) {
            if session?.doctorResult == nil { showsDoctorOutput = false }
        }
        .sheet(isPresented: $showsDoctorOutput) {
            if let result = session?.doctorResult { doctorPanel(result) }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Color.clear
                .frame(height: 43)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .accessibilityHidden(true)
            ForEach(Page.allCases, id: \.self) { option in
                let selected = page == option
                let prominentGear = page == .about && option == .general
                Button {
                    selection = option
                } label: {
                    HStack(spacing: 8) {
                        navigationIcon(option)
                            .foregroundStyle(selected || prominentGear ? palette.accent : palette.secondary)
                        Text(option.title)
                            .font(option == .flutter || option == .devTools ? .system(size: 13, weight: selected ? .semibold : .regular)
                                  : RunletType.localized(locale, size: 13, medium: selected || prominentGear))
                            .foregroundStyle(selected ? palette.primary : palette.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: option == .about ? 37 : 33)
                }
                .buttonStyle(AuxiliaryButtonStyle(surface: selected ? .selected : .clear, radius: 6))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer()
            if let version = updates.presentation.displayedVersion ?? AboutInformation().versionLabel {
                Text(verbatim: version)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 16)
                    .help(version)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 14)
        .frame(width: 128)
        .frame(maxHeight: .infinity)
        .background(palette.toolbar)
    }

    @ViewBuilder
    private func navigationIcon(_ option: Page) -> some View {
        switch option {
        case .general:
            RunletIcon("Settings", size: 15)
        case .flutter:
            Path { path in
                path.addLines([CGPoint(x: 5, y: 3.75), CGPoint(x: 1.25, y: 7.5), CGPoint(x: 5, y: 11.25)])
                path.addLines([CGPoint(x: 10, y: 3.75), CGPoint(x: 13.75, y: 7.5), CGPoint(x: 10, y: 11.25)])
                path.addLines([CGPoint(x: 8.75, y: 1.875), CGPoint(x: 6.25, y: 13.125)])
            }
            .stroke(style: StrokeStyle(lineWidth: 1.0625, lineCap: .round, lineJoin: .round))
            .frame(width: 15, height: 15)
            .accessibilityHidden(true)
        case .devTools:
            Image(systemName: "hammer")
                .font(.system(size: 13))
                .frame(width: 15, height: 15)
                .accessibilityHidden(true)
        case .about:
            Text(verbatim: "ⓘ").font(.system(size: 14))
                .frame(width: 14, height: 23)
                .accessibilityHidden(true)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 7) {
            groupTitle("Language")
            settingsCard {
                settingsRow("Interface Language") {
                    settingsPicker("Interface Language", selection: $language.selection, choices: AppLanguage.allCases) {
                        Text($0.label)
                    }
                }
            }
            if let appearance {
                groupTitle("Appearance")
                settingsCard {
                    settingsRow("App Appearance") {
                        settingsPicker("App Appearance", selection: appearance, choices: AppAppearance.allCases) {
                            Text($0.label)
                        }
                    }
                }
            }
            groupTitle("Startup & Projects")
            settingsCard {
                if let loginItem {
                    preferenceSwitch("Launch at Login", detail: "Automatically launch FlutterRunlet when you log in to macOS.",
                                     isOn: Binding(get: { loginItem.isRegistered }, set: loginItem.setRegistered),
                                     enabled: loginItem.canChange)
                    if loginItem.statusMessage != nil || loginItem.issue != nil {
                        VStack(alignment: .leading, spacing: 5) {
                            if let status = loginItem.statusMessage { Text(status) }
                            if let issue = loginItem.issue { Text(issue) }
                            settingsAction("Open Login Items in System Settings", action: loginItem.openSystemSettings)
                        }
                        .font(RunletType.localized(locale, size: 11))
                        .foregroundStyle(palette.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                if let session {
                    if loginItem != nil { rule }
                    preferenceSwitch("Show Main Window on Launch", isOn: Self.launchWindowPreference(session))
                    rule
                    preferenceSwitch("Remember Last Opened Project", isOn: Binding(
                        get: { session.rememberRecentProject }, set: { session.rememberRecentProject = $0 }
                    ))
                }
            }
        }
    }

    private func settingsPicker<Option: Hashable>(
        _ title: LocalizedStringResource, selection: Binding<Option>, choices: [Option],
        label: @escaping (Option) -> Text
    ) -> some View {
        settingsMenu(title, value: label(selection.wrappedValue)) {
            ForEach(choices, id: \.self) { option in
                let isSelected = selection.wrappedValue == option
                menuOption(label(option), selected: isSelected) {
                    selection.wrappedValue = option
                }
            }
        }
    }

    private func settingsMenu<Content: View>(
        _ title: LocalizedStringResource, value: Text, @ViewBuilder content: () -> Content
    ) -> some View {
        Menu(content: content) {
            value
        }
        .controlSize(.regular)
        .fixedSize()
        .accessibilityLabel(Text(title))
        .accessibilityValue(value)
    }

    private func menuOption(_ title: Text, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if selected { Label { title } icon: { Image(systemName: "checkmark") } }
            else { title }
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func groupTitle(_ title: LocalizedStringResource, systemFont: Bool = false) -> some View {
        Text(title)
            .font(systemFont ? .system(size: 12, weight: .semibold) : RunletType.localized(locale, size: 12, medium: true))
            .foregroundStyle(palette.secondary)
            .frame(height: 19)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingsCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.field, in: RoundedRectangle(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(palette.divider).allowsHitTesting(false) }
    }

    private var rule: some View { palette.divider.frame(height: 1) }

    private func preferenceSwitch(_ title: LocalizedStringResource, detail: LocalizedStringResource? = nil,
                                  isOn: Binding<Bool>, enabled: Bool = true) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(RunletType.localized(locale, size: 13))
                    .frame(minHeight: 19)
                if let detail {
                    Text(detail)
                        .font(RunletType.localized(locale, size: 11))
                        .foregroundStyle(palette.secondary)
                        .frame(minHeight: 16)
                }
            }
        }
        .toggleStyle(AuxiliarySwitchStyle())
        .accessibilityLabel(Text(title))
        .accessibilityHint(detail.map { Text($0) } ?? Text(verbatim: ""))
        .disabled(!enabled)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var settingsAbout: some View {
        settingsCard {
            HStack(spacing: 10) {
                AboutBrandGlyph(size: 28.35)
                AboutIdentity(updates: updates, inSettings: true)
                Spacer(minLength: 0)
                UpdateButton(updates: updates, backdrop: palette.field)
            }
            .padding(.horizontal, 12)
            .frame(height: 65)
            rule
            UpdateFeedback(updates: updates, inSettings: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
            rule
            AboutLinks()
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
        }
    }

    private func flutterSettings(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            groupTitle("Flutter SDK", systemFont: true)
            settingsCard { sdkSettings(session) }

            groupTitle("FVM", systemFont: true)
            settingsCard {
                preferenceSwitch("Prefer Project FVM", detail: "Prefer the pinned SDK when the project specifies a version.",
                                 isOn: Binding(get: { session.preferProjectFVM }, set: session.setPreferProjectFVM),
                                 enabled: session.canEditFlutterSDK)
            }

            groupTitle("Environment Check")
            settingsCard { environmentCheck(session) }
        }
    }

    private func devToolsSettings(_ session: SessionController) -> some View {
        let path = session.standaloneDevToolsPath
        let version = path == nil ? session.sdk?.devToolsVersion : session.standaloneDevToolsVersion
        return VStack(alignment: .leading, spacing: 7) {
            groupTitle("DevTools", systemFont: true)
            settingsCard {
                settingsRow("DevTools Source") {
                    settingsMenu("DevTools Source", value: path == nil ? Text("Bundled with Flutter") : Text("Standalone Dart SDK")) {
                        menuOption(Text("Bundled with Flutter"), selected: path == nil) {
                            session.selectStandaloneDevTools(nil)
                        }
                        menuOption(Text("Standalone Dart SDK…"), selected: path != nil) {
                            chooseDevToolsSDK(for: session)
                        }
                    }
                    .disabled(!session.canEditFlutterSDK)
                }
                if let version {
                    rule
                    settingsRow("Version") {
                        Text(verbatim: version)
                            .font(.system(size: 12))
                            .foregroundStyle(palette.secondary)
                    }
                }
                rule
                settingsRow("Source Editor") {
                    settingsPicker("Source Editor", selection: Bindable(session).inspectorEditor,
                                   choices: InspectorEditor.allCases) {
                        Text(verbatim: $0.title)
                    }
                }
            }
            if path != nil || session.standaloneDevToolsIssue != nil {
                groupTitle("Dart SDK", systemFont: true)
                settingsCard {
                    if let path {
                        settingsRow("Path") {
                            settingsAction("Change…", emphasized: true) { chooseDevToolsSDK(for: session) }
                                .disabled(!session.canEditFlutterSDK)
                        }
                        rule
                        HStack(spacing: 8) {
                            sdkPathValue(path)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            DartSDKPathDetailsButton(path: path)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    if let issue = session.standaloneDevToolsIssue {
                        Text(issue)
                            .font(RunletType.localized(locale, size: 11))
                            .foregroundStyle(palette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                    }
                }
            }
        }
    }

    private func sdkSettings(_ session: SessionController) -> some View {
        let manualPath = session.manualSDKPath
        let path = session.sdk?.directory.path ?? manualPath
        let effectiveSource: LocalizedStringResource? = switch session.sdk?.source {
        case .projectFVM: "Project FVM"
        case .manual: "Manual SDK"
        case .system: "System PATH"
        case nil: nil
        }
        return VStack(alignment: .leading, spacing: 0) {
            settingsRow("SDK Source") {
                settingsMenu("SDK Source", value: manualPath == nil ? Text("Auto") : Text("Manual SDK")) {
                    menuOption(Text("Auto"), selected: manualPath == nil) {
                        if manualPath != nil { session.clearManualFlutterSDK() }
                        else { session.recheckInvalidFlutterSDK() }
                    }
                    menuOption(Text("Manual SDK…"), selected: manualPath != nil) {
                        chooseSDK(for: session)
                    }
                }
                .disabled(!session.canEditFlutterSDK)
            }
            if let effectiveSource {
                rule
                settingsRow("Effective Source") {
                    Text(effectiveSource)
                        .font(RunletType.localized(locale, size: 12))
                        .foregroundStyle(palette.secondary)
                }
            }
            rule
            settingsRow("Version & Status") {
                if session.isCheckingSDK {
                    ProgressView("Checking Flutter SDK").controlSize(.small)
                        .font(RunletType.localized(locale, size: 11))
                } else if let sdk = session.sdk {
                    Text("Flutter \(sdk.flutterVersion)  ·  Dart \(sdk.dartVersion)")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("SDK Available")
                        .font(RunletType.localized(locale, size: 11, medium: true))
                        .foregroundStyle(palette.success)
                        .fixedSize()
                } else {
                    Text("SDK Unavailable")
                        .font(RunletType.localized(locale, size: 11))
                        .foregroundStyle(palette.warning)
                }
            }

            rule
            if let path {
                if manualPath == path {
                    sdkPath("SDK Path", path: path, enabled: session.canEditFlutterSDK) {
                        chooseSDK(for: session)
                    }
                } else {
                    sdkPath("SDK Path", path: path)
                }
                if let manualPath, manualPath != path {
                    rule
                    sdkPath("Manual SDK Path", path: manualPath, enabled: session.canEditFlutterSDK) {
                        chooseSDK(for: session)
                    }
                }
            } else {
                settingsRow("SDK Path") { Text(verbatim: "—").foregroundStyle(palette.muted) }
            }

            if session.isCheckingSDKSelection || !session.canEditFlutterSDK || session.sdkIssue != nil ||
                session.sdkSelectionIssue != nil {
                rule
                VStack(alignment: .leading, spacing: 5) {
                    if session.isCheckingSDKSelection {
                        ProgressView("Validating Selected Path").controlSize(.small)
                    } else if !session.canEditFlutterSDK {
                        Text("Stop the current session and finish environment recovery to change SDK settings.")
                    }
                    if let issue = session.sdkIssue { Text(issue).foregroundStyle(palette.warning) }
                    if let issue = session.sdkSelectionIssue { Text(issue).foregroundStyle(palette.warning) }
                }
                .font(RunletType.localized(locale, size: 11))
                .foregroundStyle(palette.secondary)
                .padding(8)
                .padding(.horizontal, 4)
            }
        }
    }

    private func sdkPath(_ title: LocalizedStringResource, path: String, enabled: Bool = true,
                         change: (() -> Void)? = nil) -> some View {
        settingsRow(title) {
            sdkPathValue(path).textSelection(.enabled)
            if let change {
                settingsAction("Change…", emphasized: true, action: change)
                    .disabled(!enabled)
            }
        }
    }

    private func sdkPathValue(_ path: String) -> some View {
        let home = NSHomeDirectory()
        let display = path.hasPrefix(home + "/") ? "~" + String(path.dropFirst(home.count)) : path
        return Text(verbatim: display)
            .font(.system(size: 12))
            .foregroundStyle(palette.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(path)
            .accessibilityLabel(Text(verbatim: path))
    }

    private func settingsRow<Trailing: View>(_ title: LocalizedStringResource,
                                             @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(RunletType.localized(locale, size: 13))
                .frame(minHeight: 19)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func settingsAction(_ title: LocalizedStringResource, emphasized: Bool = false,
                                 action: @escaping () -> Void) -> some View {
        AuxiliaryActionButton(emphasized: emphasized, action: action) {
            Text(title)
        }
    }

    private func environmentCheck(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(verbatim: "Flutter Doctor").font(.system(size: 13))
                Spacer(minLength: 0)
                if session.isCheckingEnvironment {
                    ProgressView("Checking Environment").controlSize(.small)
                        .font(RunletType.localized(locale, size: 11))
                    settingsAction("Cancel", action: session.cancelEnvironmentCheck)
                } else {
                    settingsAction(session.doctorResult?.failure == nil ? "Check Environment" : "Retry",
                                   emphasized: true, action: session.checkEnvironment)
                        .disabled(!session.canCheckEnvironment)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            if let result = session.doctorResult {
                rule
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        doctorStatus(result)
                        Spacer(minLength: 0)
                        if !result.stdout.isEmpty || !result.stderr.isEmpty {
                            settingsAction("View Full Output") { showsDoctorOutput = true }
                        }
                    }
                    ForEach(FlutterDoctorResult.Tool.allCases, id: \.self) { tool in
                        if let status = result.summary[tool], result.failure == nil || status != .unknown {
                            HStack(spacing: 8) {
                                Text(tool.title)
                                Spacer()
                                Text(status.title).foregroundStyle(doctorStatusColor(status))
                            }
                        }
                    }
                }
                .font(RunletType.localized(locale, size: 11))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    private func doctorStatus(_ result: FlutterDoctorResult) -> some View {
        Group {
            if let failure = result.failure {
                if failure == .cancelled { Text(failure.reason) }
                else { Text("Environment check could not complete: \(failure.reason). Check the Flutter SDK and try again.") }
            } else {
                Text("Environment check finished.")
            }
        }
        .foregroundStyle(result.failure == nil ? palette.success : palette.warning)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func doctorStatusColor(_ status: FlutterDoctorResult.Status) -> Color {
        switch status {
        case .passed: palette.success
        case .warning: palette.warning
        case .failed: palette.error
        case .unknown: palette.secondary
        }
    }

    private func doctorPanel(_ result: FlutterDoctorResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Environment Check Output")
                .font(RunletType.localized(locale, size: 14, medium: true))
                .frame(height: 23)
                .accessibilityAddTraits(.isHeader)
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 12) {
                    doctorOutput("Standard Output", text: result.stdout)
                    doctorOutput("Standard Error", text: result.stderr)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(palette.console, in: RoundedRectangle(cornerRadius: 5))
            settingsAction("Dismiss") { showsDoctorOutput = false }
                .keyboardShortcut(.cancelAction)
        }
        .padding(13)
        .frame(width: 500, height: 360)
        .foregroundStyle(palette.primary)
        .background(palette.toolbar)
        .environment(\.locale, language.locale)
    }

    private func doctorOutput(_ title: LocalizedStringKey, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            if text.isEmpty {
                Text("No Output").foregroundStyle(.secondary)
            } else {
                Text(verbatim: text)
                    .font(.system(size: 12, design: .monospaced))
                    .fixedSize(horizontal: true, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }

    private func chooseSDK(for session: SessionController) {
        let panel = NSOpenPanel()
        panel.title = locale.appString("Select Flutter SDK Path")
        panel.message = locale.appString("Select the directory containing the Flutter SDK.")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if let path = session.manualSDKPath ?? session.sdk?.directory.path {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        if panel.runModal() == .OK, let url = panel.url {
            session.selectFlutterSDK(url)
        }
    }

    private func chooseDevToolsSDK(for session: SessionController) {
        let panel = NSOpenPanel()
        panel.title = locale.appString("Select Dart SDK…")
        panel.message = locale.appString("Select a Dart SDK directory that includes DevTools.")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if let path = session.standaloneDevToolsPath {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        if panel.runModal() == .OK, let url = panel.url {
            session.selectStandaloneDevTools(url)
        }
    }
}

private struct DartSDKPathDetailsButton: View {
    @Environment(\.locale) private var locale
    @State private var isShowing = false

    let path: String

    var body: some View {
        Button("Show Full Path", systemImage: "ellipsis.circle") {
            isShowing.toggle()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help("Show Full Path")
        .popover(isPresented: $isShowing, arrowEdge: .leading) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Dart SDK Path")
                    .font(RunletType.localized(locale, size: 13, medium: true))
                    .accessibilityAddTraits(.isHeader)

                let pathText = Text(verbatim: path)
                    .font(.system(size: 12, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .vertical) {
                    pathText
                    ScrollView { pathText }
                }
                .frame(maxHeight: 160)

                Button("Copy Path", systemImage: "doc.on.doc") {
                    let clipboard = NSPasteboard.general
                    clipboard.clearContents()
                    clipboard.setString(path, forType: .string)
                }
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .frame(width: 340)
            .environment(\.locale, locale)
        }
    }
}

struct AboutInformation {
    let version: String?
    let buildNumber: String?

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    var versionLabel: String? {
        guard let version else { return nil }
        guard let buildNumber else { return "v\(version)" }
        return "v\(version) (build \(buildNumber))"
    }

    static let upstreamCopyright = "Copyright (c) 2026 huseyiniriss"
    static let license: LocalizedStringResource = "MIT License"
    static let copyright = "Copyright (c) 2026 Svame"

    static func licenseDetails(locale: Locale) -> String {
        [locale.appString(license), copyright, locale.appString("Inspired by Flutter GUI Runner"),
         upstreamCopyright].joined(separator: "\n")
    }

    enum Destination: CaseIterable {
        case project, documentation, license, recentUpdates

        var title: LocalizedStringResource {
            switch self {
            case .project: "Github"
            case .documentation: "Doc"
            case .license: "License"
            case .recentUpdates: "Updates"
            }
        }

        var url: URL {
            switch self {
            case .project: URL(string: "https://github.com/atypiape/flutter-runlet")!
            case .documentation: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/README.md")!
            case .license: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/LICENSE")!
            case .recentUpdates: UpdateRepository.releases
            }
        }
    }
}

struct AboutView: View {
    static let windowSize = CGSize(width: 400, height: 412)

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    let updates: UpdatePresentationSource

    var body: some View {
        let palette = RunletAppearance(scheme)
        AuxiliaryWindowLayout(title: "About FlutterRunlet", kind: .about) {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(spacing: 6) {
                        AboutBrandGlyph(size: 44.1)
                            .frame(width: 66, height: 66)
                            .background(palette.raised, in: RoundedRectangle(cornerRadius: 17))
                            .overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(palette.divider).allowsHitTesting(false) }

                        AboutIdentity(updates: updates, inSettings: false)

                        Text("Lightweight Flutter run and debug tool")
                            .font(RunletType.localized(locale, size: 13))
                            .foregroundStyle(palette.secondary)
                            .multilineTextAlignment(.center)
                            .frame(minHeight: 19)
                    }

                    VStack(spacing: 7) {
                        UpdateButton(updates: updates, backdrop: palette.window)
                        UpdateFeedback(updates: updates, inSettings: false)
                    }

                    palette.divider.frame(height: 1)
                    AboutLinks()
                    VStack(spacing: 3) {
                        Text(AboutInformation.license)
                            .font(RunletType.localized(locale, size: 11))
                            .foregroundStyle(palette.secondary)
                            .frame(height: 17)
                        Text(verbatim: AboutInformation.copyright)
                            .font(.system(size: 11))
                            .foregroundStyle(palette.muted)
                            .frame(height: 17)
                    }
                    .help(AboutInformation.licenseDetails(locale: locale))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            // Keep the centered layout stable when feedback requires scrolling.
            .scrollIndicators(.never, axes: .vertical)
        }
    }
}

private struct AboutBrandGlyph: View {
    let size: CGFloat

    var body: some View {
        Image("BrandGlyph")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("FlutterRunlet Logo")
    }
}

private struct AboutIdentity: View {
    @Environment(\.colorScheme) private var scheme
    let updates: UpdatePresentationSource
    let inSettings: Bool

    var body: some View {
        VStack(alignment: inSettings ? .leading : .center, spacing: inSettings ? 2 : 6) {
            Text(verbatim: "FlutterRunlet")
                .font(.system(size: inSettings ? 14 : 26, weight: .semibold))
                .frame(height: inSettings ? 23 : 32)
                .accessibilityAddTraits(.isHeader)
            if let version = updates.presentation.displayedVersion ?? AboutInformation().versionLabel {
                Text(verbatim: version)
                    .font(.system(size: inSettings ? 11 : 12))
                    .foregroundStyle(RunletAppearance(scheme).secondary)
                    .frame(height: inSettings ? 16 : 18)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(version)
                    .accessibilityLabel(Text(verbatim: version))
            }
        }
    }
}

private struct AboutLinks: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let destinations = AboutInformation.Destination.allCases
        ViewThatFits(in: .horizontal) {
            linkRow(destinations[...])
            VStack(spacing: 8) {
                linkRow(destinations.prefix(2))
                linkRow(destinations.dropFirst(2))
            }
        }
    }

    private func linkRow(_ destinations: ArraySlice<AboutInformation.Destination>) -> some View {
        HStack(spacing: 8) {
            ForEach(destinations, id: \.self) { destination in
                link(destination)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func link(_ destination: AboutInformation.Destination) -> some View {
        let details = AboutInformation.licenseDetails(locale: locale)
        let control = Link(destination: destination.url) {
            HStack(spacing: 6) {
                destination.icon
                    .foregroundStyle(RunletAppearance(scheme).secondary)
                Text(destination.title)
                    .font(destination == .project ? .system(size: 11) : RunletType.localized(locale, size: 11))
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .frame(height: 29)
        }
        .buttonStyle(AuxiliaryButtonStyle(surface: .link, radius: 6))
        if destination == .license {
            control.help(details).accessibilityHint(Text(verbatim: details))
        } else {
            control
        }
    }
}

private extension AboutInformation.Destination {
    @MainActor
    @ViewBuilder
    var icon: some View {
        switch self {
        case .project: RunletIcon("AboutGitHub", size: 15)
        case .documentation: RunletIcon("AboutDocumentation", size: 15)
        case .license: RunletIcon("AboutLicense", size: 15)
        case .recentUpdates:
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 15, height: 15)
                .accessibilityHidden(true)
        }
    }
}

private struct UpdateButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let updates: UpdatePresentationSource
    let backdrop: Color

    var body: some View {
        let presentation = updates.presentation
        let isSpinning = presentation.status == .checking || presentation.status == .updating
        AuxiliaryActionButton(emphasized: true, preservesDisabledSurface: true,
                              action: { updates.perform(.primary) }) {
            HStack(spacing: 5) {
                switch presentation.status {
                case .available, .ready, .waiting: RunletIcon("UpdateDownload", size: 15)
                case .checking, .updating: spinner(presentation.rotation)
                default: RunletIcon("UpdateCheck", size: 15)
                }
                Text(presentation.primaryTitle)
                    .lineLimit(1)
            }
        }
        .modifier(UpdateButtonOpacity(isSpinning: isSpinning, backdrop: backdrop))
        .disabled(!presentation.canPerformPrimary)
        .accessibilityIdentifier("update-primary")
        .accessibilityLabel(Text(presentation.primaryTitle))
        .help(Text(presentation.primaryTitle))
    }

    @ViewBuilder
    private func spinner(_ rotation: UpdatePresentation.Rotation) -> some View {
        if case .animated = rotation, !reduceMotion {
            TimelineView(.animation) { context in
                RunletIcon("UpdateSpinner", size: 15)
                    .rotationEffect(.degrees(rotation.degrees(at: context.date)))
            }
        } else {
            RunletIcon("UpdateSpinner", size: 15)
                .rotationEffect(.degrees(reduceMotion && rotation.isAnimated ? 0 : rotation.degrees(at: .now)))
        }
    }
}

private struct UpdateButtonOpacity: ViewModifier {
    let isSpinning: Bool
    let backdrop: Color

    func body(content: Content) -> some View {
        if isSpinning {
            // Match the approved sRGB blend before the window converts to the display profile.
            content
                .compositingGroup()
                .opacity(0.72)
                .background(backdrop)
                .drawingGroup(opaque: true, colorMode: .nonLinear)
        } else {
            content
        }
    }
}

private extension UpdatePresentation.Rotation {
    var isAnimated: Bool {
        if case .animated = self { return true }
        return false
    }
}

private struct UpdateFeedback: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    let updates: UpdatePresentationSource
    let inSettings: Bool

    var body: some View {
        let presentation = updates.presentation
        let palette = RunletAppearance(scheme)
        HStack(spacing: 8) {
            Text(presentation.feedback)
                .foregroundStyle(inSettings ? palette.primary : palette.secondary)
                .multilineTextAlignment(inSettings ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("update-feedback")
            if presentation.showsReleaseAction {
                Button("View Release") { updates.perform(.showRelease) }
                    .buttonStyle(AuxiliaryButtonStyle(surface: .clear))
                    .foregroundStyle(palette.accent)
                    .fixedSize()
            }
        }
        .font(RunletType.localized(locale, size: inSettings ? 12 : 11))
        .frame(maxWidth: .infinity, minHeight: inSettings ? 19 : 17,
               alignment: inSettings ? .leading : .center)
    }
}

extension UpdatePresentation.Prompt {
    var title: LocalizedStringResource {
        switch self {
        case .confirm: "Install and Restart"
        case .recovery: "Update Recovery"
        }
    }
}

struct UpdatePromptView: View {
    let updates: UpdatePresentationSource

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch updates.presentation.prompt {
            case .confirm(let version):
                Text("Install \(version) and restart FlutterRunlet?")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("The update package is ready.")
                HStack {
                    Spacer()
                    Button("Later") { updates.perform(.later) }
                        .keyboardShortcut(.cancelAction)
                    Button("Install and Restart") { updates.perform(.install) }
                        .keyboardShortcut(.defaultAction)
                }
            case .recovery(let path):
                Text("The previous version was restored but could not open automatically.")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: path)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                HStack {
                    Button("Show in Finder") { updates.perform(.showInFinder) }
                    Button("View Release") { updates.perform(.showRelease) }
                    Spacer()
                    Button("Dismiss") { updates.perform(.dismissRecovery) }
                        .keyboardShortcut(.cancelAction)
                }
            case nil:
                EmptyView()
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

struct AuxiliaryWindowLayout<Content: View>: View {
    enum Kind { case settings, about }

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let title: LocalizedStringResource
    let kind: Kind
    @ViewBuilder let content: () -> Content

    var body: some View {
        let palette = RunletAppearance(scheme)
        let settings = kind == .settings
        let size = settings ? SettingsView.windowSize : AboutView.windowSize
        VStack(spacing: 0) {
            if !settings {
                Text(title)
                    .font(RunletType.localized(locale, size: 12, medium: true))
                    .frame(maxWidth: .infinity)
                    .frame(height: 35)
                    .background(palette.toolbar)
                    .contentShape(Rectangle())
                    .gesture(WindowDragGesture())
                    .accessibilityHidden(true)
                palette.divider.frame(height: 1)
            }
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(1)
        .frame(width: size.width, height: size.height)
        .foregroundStyle(palette.primary)
        .background(palette.window)
        .overlay {
            RoundedRectangle(cornerRadius: settings ? 13 : 14)
                .strokeBorder(settings ? palette.divider : palette.border)
                .allowsHitTesting(false)
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .containerBackground(palette.toolbar, for: .window)
        .background(WindowChrome(title: locale.appString(title), kind: kind))
        .ignoresSafeArea()
    }

    private struct WindowChrome: NSViewRepresentable {
        let title: String
        let kind: Kind

        func makeNSView(context: Context) -> ChromeView { ChromeView() }

        func updateNSView(_ view: ChromeView, context: Context) {
            view.configuration = self
        }

        final class ChromeView: NSView {
            private weak var observedWindow: NSWindow?
            private var titleObservations: [NSKeyValueObservation] = []
            var configuration: WindowChrome? { didSet { updateWindow() } }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                let notifications = NotificationCenter.default
                if let observedWindow {
                    notifications.removeObserver(self, name: NSWindow.didUpdateNotification, object: observedWindow)
                }
                titleObservations.removeAll()
                observedWindow = window
                if let window {
                    notifications.addObserver(self, selector: #selector(restoreTitlebar),
                                              name: NSWindow.didUpdateNotification, object: window)
                    // SwiftUI can restore the system title while Settings is behind another window.
                    titleObservations = [
                        window.observe(\.title) { [weak self] _, _ in
                            DispatchQueue.main.async { self?.restoreTitlebar() }
                        },
                        window.observe(\.titleVisibility) { [weak self] _, _ in
                            DispatchQueue.main.async { self?.restoreTitlebar() }
                        }
                    ]
                }
                updateWindow()
            }

            @objc private func restoreTitlebar() {
                guard let window, let configuration else { return }
                if window.title != configuration.title { window.title = configuration.title }
                if window.titleVisibility != .hidden { window.titleVisibility = .hidden }
                if !window.titlebarAppearsTransparent { window.titlebarAppearsTransparent = true }
            }

            private func updateWindow() {
                DispatchQueue.main.async { [weak self] in self?.configureWindow() }
            }

            private func configureWindow() {
                guard let window, let configuration else { return }
                if !window.styleMask.contains(.fullSizeContentView) {
                    window.styleMask.insert(.fullSizeContentView)
                }
                restoreTitlebar()
                window.titlebarSeparatorStyle = .none
                let size = configuration.kind == .settings ? SettingsView.windowSize : AboutView.windowSize
                if window.frame.size != size {
                    window.setFrame(NSRect(x: window.frame.minX, y: window.frame.maxY - size.height,
                                           width: size.width, height: size.height), display: true)
                }
                if configuration.kind == .about {
                    window.styleMask.remove(.resizable)
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                }
            }
        }
    }
}

private struct AuxiliaryActionButton<Label: View>: View {
    @Environment(\.locale) private var locale
    var emphasized = false
    var preservesDisabledSurface = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .font(RunletType.localized(locale, size: 11, medium: true))
                .padding(.horizontal, 10)
                .frame(height: 24)
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(AuxiliaryButtonStyle(surface: emphasized ? .accent : .raised, radius: 6,
                                           preservesDisabledSurface: preservesDisabledSurface))
    }
}

struct AuxiliaryButtonStyle: ButtonStyle {
    enum Surface { case clear, selected, raised, accent, link }

    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme

    var surface: Surface = .raised
    var radius: CGFloat = 5
    var preservesDisabledSurface = false
    var outlined = false

    func makeBody(configuration: Configuration) -> some View {
        let palette = RunletAppearance(scheme)
        let shape = RoundedRectangle(cornerRadius: radius)
        let fill: Color = switch surface {
        case .clear: .clear
        case .selected: palette.selected
        case .raised: palette.raised
        case .accent: palette.accent
        case .link: palette.field
        }
        let stroke: Color = switch surface {
        case .raised: palette.divider
        case .link: palette.border
        default: outlined ? palette.divider : .clear
        }
        let visuallyEnabled = enabled || preservesDisabledSurface
        configuration.label
            .foregroundStyle(visuallyEnabled ? (surface == .accent ? palette.onAccent : palette.primary) : palette.disabledText)
            .contentShape(Rectangle())
            .background(configuration.isPressed ? fill.opacity(0.75) : (visuallyEnabled ? fill : palette.disabled), in: shape)
            .overlay { shape.strokeBorder(stroke).allowsHitTesting(false) }
            .opacity(visuallyEnabled ? 1 : 0.7)
    }
}

private struct AuxiliarySwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let palette = RunletAppearance(scheme)
        return Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                configuration.label
                Spacer(minLength: 0)
                Capsule()
                    .fill(configuration.isOn ? palette.accent : Color(.sRGB, red: 97/255, green: 102/255, blue: 115/255))
                    .frame(width: 32, height: 18)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(.white)
                            .frame(width: 12, height: 12)
                            .padding(.horizontal, 3)
                    }
                    .opacity(enabled ? 1 : 0.55)
            }
        }
        .buttonStyle(AuxiliaryButtonStyle(surface: .clear))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}
