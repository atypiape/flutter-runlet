enum LaunchPresentation: Equatable {
    struct Selection: Equatable {
        let project: String
        let configuration: String
        let device: String
    }

    case empty
    case ready(Selection)

    var selection: Selection? {
        guard case .ready(let selection) = self else { return nil }
        return selection
    }

    #if DEBUG
    static let longFieldsPreview: Self = .ready(Selection(
        project: String(repeating: "sample-flutter-app-", count: 7) + "PROJECT-END",
        configuration: String(repeating: "sample-flutter-app(dev)-", count: 6) + "CONFIG-END",
        device: String(repeating: "iOS-Simulator-Preview-", count: 6) + "DEVICE-END"
    ))
    #endif

    static func resolve(arguments: [String]) -> Self {
        #if DEBUG
        if arguments.contains("--g1-ready") {
            return .ready(Selection(
                project: "sample-flutter-app",
                configuration: "sample-flutter-app(dev)",
                device: "iPhone 17 Pro (iOS Simulator)"
            ))
        }
        #endif

        return .empty
    }
}
