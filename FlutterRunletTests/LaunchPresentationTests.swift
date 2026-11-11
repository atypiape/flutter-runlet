import XCTest
@testable import FlutterRunlet

final class LaunchPresentationTests: XCTestCase {
    func testOrdinaryArgumentsReturnEmpty() {
        XCTAssertEqual(LaunchPresentation.resolve(arguments: []), .empty)
        XCTAssertEqual(LaunchPresentation.resolve(arguments: ["--unrelated"]), .empty)
    }

    func testExactDebugFlagReturnsCompleteReadySelection() {
        XCTAssertEqual(
            LaunchPresentation.resolve(arguments: ["--unrelated", "--g1-ready"]),
            .ready(.init(
                project: "sample-flutter-app",
                configuration: "sample-flutter-app(dev)",
                device: "iPhone 17 Pro (iOS Simulator)"
            ))
        )
    }

    func testSimilarArgumentsReturnEmpty() {
        XCTAssertEqual(
            LaunchPresentation.resolve(arguments: ["--g1-ready=true", "--g1-ready-extra", " --g1-ready"]),
            .empty
        )
    }
}
