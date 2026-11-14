import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.locale) private var locale

    var session: SessionController? = nil
    enum Page: CaseIterable {
        case general
        case flutter

        var title: LocalizedStringKey {
            switch self {
            case .general: "General"
            case .flutter: "Flutter"
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .flutter: "hammer"
            }
        }
    }

    @Binding var selection: Page?
    @Bindable var language: AppLanguageSettings
    var loginItem: LoginItemSettings? = nil
    @State private var showsDoctorOutput = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Page.allCases, id: \.self) { page in
                    Label(page.title, systemImage: page.symbol)
                        .tag(page)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(142)
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                Text((selection ?? .general).title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                if (selection ?? .general) == .general {
                    Picker("Language", selection: $language.selection) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    if let loginItem {
                        loginItemControls(loginItem)
                    }
                    if let session {
                        Toggle("Show Main Window on Launch", isOn: Binding(
                            get: { session.showMainWindowOnLaunch },
                            set: { session.showMainWindowOnLaunch = $0 }
                        ))
                        Toggle("Remember Last Opened Project", isOn: Binding(
                            get: { session.rememberRecentProject },
                            set: { session.rememberRecentProject = $0 }
                        ))
                    }
                }
                if selection == .flutter, let session, session.usesFlutterToolchain {
                    ScrollView {
                        flutterSettings(session)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .navigationTitle(locale.appString("FlutterRunlet Settings"))
        }
        .toolbar(removing: .sidebarToggle)
        .onChange(of: selection, initial: true) {
            if selection == .flutter { session?.checkFlutterSDKIfNeeded() }
            else { loginItem?.refresh() }
        }
        .onChange(of: session?.doctorResult != nil) {
            if session?.doctorResult == nil { showsDoctorOutput = false }
        }
        .sheet(isPresented: $showsDoctorOutput) {
            if let result = session?.doctorResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Environment Check Output").font(.headline)
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 12) {
                            doctorOutput("Standard Output", text: result.stdout)
                            doctorOutput("Standard Error", text: result.stderr)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Spacer()
                        Button("Dismiss") { showsDoctorOutput = false }
                            .keyboardShortcut(.cancelAction)
                    }
                }
                .padding(20)
                .frame(width: 560, height: 360)
                .environment(\.locale, language.locale)
            }
        }
    }

    private func loginItemControls(_ loginItem: LoginItemSettings) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Launch at Login", isOn: Binding(
                get: { loginItem.isRegistered }, set: loginItem.setRegistered
            ))
            .disabled(!loginItem.canChange)
            if let status = loginItem.statusMessage {
                Text(status).foregroundStyle(.secondary)
            }
            if let issue = loginItem.issue {
                Text(issue).foregroundStyle(.secondary)
            }
            if loginItem.statusMessage != nil || loginItem.issue != nil {
                Button("Open Login Items in System Settings", action: loginItem.openSystemSettings)
            }
        }
    }

    private func flutterSettings(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if session.isCheckingSDK {
                ProgressView("Checking Flutter SDK")
                    .controlSize(.small)
            }
            if let sdk = session.sdk {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    sdkRow("Source", value: locale.appString(sdk.source.title))
                    sdkRow("Path", value: sdk.directory.path)
                    sdkRow("Flutter", value: sdk.flutterVersion)
                    sdkRow("Dart", value: sdk.dartVersion)
                    if let fvmVersion = sdk.projectFVMVersion {
                        sdkRow("Project FVM Version", value: fvmVersion)
                    }
                }
            }
            if let issue = session.sdkIssue {
                Text(issue).foregroundStyle(.secondary)
            }

            Toggle("Prefer Project FVM", isOn: Binding(
                get: { session.preferProjectFVM }, set: session.setPreferProjectFVM
            ))
            .disabled(!session.canEditFlutterSDK)

            if let path = session.manualSDKPath, session.sdk?.source != .manual {
                Text(verbatim: path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(path)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Button("Select Flutter SDK Path") { chooseSDK(for: session) }
                if session.manualSDKPath != nil {
                    Button("Clear Manual Path", action: session.clearManualFlutterSDK)
                }
            }
            .disabled(!session.canEditFlutterSDK)
            if session.isCheckingSDKSelection {
                ProgressView("Validating Selected Path").controlSize(.small)
            } else if !session.canEditFlutterSDK {
                Text("Stop the current session and finish environment recovery to change SDK settings.")
                    .foregroundStyle(.secondary)
            }
            if let issue = session.sdkSelectionIssue {
                Text(issue).foregroundStyle(.secondary)
            }
            Divider()
            environmentCheck(session)
        }
    }

    private func environmentCheck(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if session.isCheckingEnvironment {
                    ProgressView("Checking Environment").controlSize(.small)
                    Button("Cancel", action: session.cancelEnvironmentCheck)
                } else {
                    Button(action: session.checkEnvironment) {
                        if session.doctorResult?.failure != nil { Text("Retry") }
                        else { Text("Check Environment") }
                    }
                    .disabled(!session.canCheckEnvironment)
                }
                if let result = session.doctorResult, !result.stdout.isEmpty || !result.stderr.isEmpty {
                    Button("View Full Output") { showsDoctorOutput = true }
                }
            }
            if let result = session.doctorResult {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    ForEach(FlutterDoctorResult.Tool.allCases, id: \.self) { tool in
                        GridRow {
                            Text(tool.title)
                            Text((result.summary[tool] ?? .unknown).title).foregroundStyle(.secondary)
                        }
                    }
                }
                if let failure = result.failure {
                    Text("Environment check could not complete: \(failure.reason). Check the Flutter SDK and try again.")
                        .foregroundStyle(.secondary)
                }
            }
        }
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

    private func sdkRow(_ title: LocalizedStringKey, value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(verbatim: value)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
                .textSelection(.enabled)
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
}

private extension FlutterSDK.Source {
    var title: LocalizedStringResource {
        switch self {
        case .projectFVM: "Project FVM"
        case .manual: "Manual"
        case .system: "System PATH"
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

    static let upstreamCopyright = "Copyright (c) 2026 huseyiniriss"

    enum Destination: CaseIterable {
        case project, documentation, license

        var title: LocalizedStringResource {
            switch self {
            case .project: "Project Home"
            case .documentation: "Documentation"
            case .license: "Project License"
            }
        }

        var url: URL {
            switch self {
            case .project: URL(string: "https://github.com/atypiape/flutter-runlet")!
            case .documentation: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/README.md")!
            case .license: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/LICENSE")!
            }
        }
    }
}

struct AboutView: View {
    private let information = AboutInformation()

    var body: some View {
        VStack(spacing: 12) {
            Image("BrandGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("FlutterRunlet Logo")

            Text("FlutterRunlet")
                .font(.title.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Lightweight Flutter debugging for macOS.")
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                if let version = information.version {
                    Text("Version \(version)")
                }
                if let buildNumber = information.buildNumber {
                    Text("Build \(buildNumber)")
                }
            }
            .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Inspired by Flutter GUI Runner")
                Text(verbatim: AboutInformation.upstreamCopyright)
                Text("MIT License")
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(AboutInformation.Destination.allCases, id: \.self) { destination in
                    Link(destination: destination.url) {
                        Text(destination.title)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
