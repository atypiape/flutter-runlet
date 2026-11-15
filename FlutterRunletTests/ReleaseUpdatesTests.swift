import Foundation
import XCTest
@testable import FlutterRunlet

final class ReleaseUpdatesTests: XCTestCase {
    func testLatestComparesNumericSegmentsAndIgnoresReleaseNotes() async throws {
        let http = ReleaseHTTPFixture([.init("/releases/latest", json: releaseJSON(tag: "v0.10.0"))])
        let result = try await ReleaseClient(get: { try await http.get($0) }).check(runningVersion: "0.9.99")
        XCTAssertEqual(result.newerTag, "v0.10.0")
        let requests = await http.requests
        XCTAssertEqual(requests, ["/releases/latest"])
    }
}

private extension ReleaseCheckResult {
    var newerTag: String? {
        if case .newer(let release) = self { return release.tag }
        return nil
    }
}

private let api = "https://api.github.com/repos/atypiape/flutter-runlet"
private let project = "https://github.com/atypiape/flutter-runlet"

private func releaseJSON(tag: String, draft: Bool = false, prerelease: Bool = false) -> String {
    """
    {"id":42,"tag_name":"\(tag)","draft":\(draft),"prerelease":\(prerelease),"immutable":false,
     "url":"\(api)/releases/42","assets_url":"\(api)/releases/42/assets",
     "html_url":"\(project)/releases/tag/\(tag)","assets":[],"body":"Preview build"}
    """
}

private actor ReleaseHTTPFixture {
    struct Stub {
        let path: String
        let status: Int
        let json: String
        let servedFrom: URL?

        init(_ path: String, status: Int = 200, json: String = "{}", servedFrom: URL? = nil) {
            self.path = path
            self.status = status
            self.json = json
            self.servedFrom = servedFrom
        }
    }

    private var replies: [Stub]
    private(set) var requests: [String] = []

    init(_ replies: [Stub]) { self.replies = replies }

    func get(_ url: URL) throws -> (Data, HTTPURLResponse) {
        let path = String(url.absoluteString.dropFirst(api.count))
        requests.append(path)
        guard let stub = replies.first, api + stub.path == url.absoluteString else {
            throw URLError(.badURL)
        }
        replies.removeFirst()
        let response = HTTPURLResponse(url: stub.servedFrom ?? url, statusCode: stub.status,
                                       httpVersion: "HTTP/1.1", headerFields: nil)!
        return (Data(stub.json.utf8), response)
    }
}

// RED-only stand-in for the absent release client. The pre-feature app has no remote result.
private struct ReleaseClient {
    let get: @Sendable (URL) async throws -> (Data, HTTPURLResponse)

    func check(runningVersion: String) async throws -> ReleaseCheckResult {
        .current
    }
}

private enum ReleaseCheckResult {
    struct Release { let tag: String }
    case current, newer(Release)
}
