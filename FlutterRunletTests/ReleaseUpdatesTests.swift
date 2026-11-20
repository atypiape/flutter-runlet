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

    func testCurrentOrNewerRunningVersionUsesNumericEqualityAndNeverUsesBuild() async throws {
        for running in ["0.10", "0.10.0.0", "1"] {
            let http = ReleaseHTTPFixture([.init("/releases/latest", json: releaseJSON(tag: "v0.10.0"))])
            let result = try await ReleaseClient(get: { try await http.get($0) }).check(runningVersion: running)
            guard case .current = result else { return XCTFail("Expected current for \(running)") }
        }
        XCTAssertLessThan(try XCTUnwrap(ReleaseVersion("0.10.0.999999999999999999999999")),
                          try XCTUnwrap(ReleaseVersion("0.10.1")))
        XCTAssertLessThan(try XCTUnwrap(ReleaseVersion("1.0.2")),
                          try XCTUnwrap(ReleaseVersion("1.0.20")))
        for text in ["1.", "1..2", "-1", " 1", "١.٠", "v1.0", ""] {
            XCTAssertNil(ReleaseVersion(text), text)
        }
    }

    func testLatestCannotUseDraftPrereleaseMalformedTagOrForeignReleaseIdentity() async {
        for json in [releaseJSON(tag: "v1", draft: true), releaseJSON(tag: "v1", prerelease: true),
                     releaseJSON(tag: "v1.0-rc"), releaseJSON(tag: "v1").replacingOccurrences(of: project, with: "https://example.invalid")] {
            await expectIssue(.invalidResponse, replies: [.init("/releases/latest", json: json)])
        }
        let foreign = URL(string: "https://example.invalid/releases/latest")!
        await expectIssue(.invalidResponse, replies: [.init("/releases/latest", json: releaseJSON(tag: "v1"), servedFrom: foreign)])
    }

    func testNotFoundRequiresAnonymousPublicRepositoryAndEveryReleasePage() async throws {
        let http = ReleaseHTTPFixture([
            .init("/releases/latest", status: 404),
            .init("", json: repositoryJSON),
            .init("/releases?per_page=100&page=1", json: "[{\"draft\":false,\"prerelease\":true}]",
                  link: "<https://api.github.com/repositories/123/releases?page=2>; rel=\"next\""),
            .init("/releases?per_page=100&page=2", json: "[]")
        ])
        let result = try await ReleaseClient(get: { try await http.get($0) }).check(runningVersion: "0.1")
        guard case .noRelease = result else { return XCTFail("Expected confirmed no formal releases") }
        let requests = await http.requests
        XCTAssertEqual(requests, ["/releases/latest", "", "/releases?per_page=100&page=1", "/releases?per_page=100&page=2"])
    }

    func testNotFoundWithPrivateRepositoryContradictionOrUnreachableListIsFailure() async {
        let latest = ReleaseHTTPFixture.Stub("/releases/latest", status: 404)
        let repo = ReleaseHTTPFixture.Stub("", json: repositoryJSON)
        await expectIssue(.unexpectedStatus(404), replies: [latest, .init("", status: 404)])
        await expectIssue(.invalidResponse, replies: [latest, .init("", json: repositoryJSON.replacingOccurrences(of: "public", with: "private"))])
        await expectIssue(.inconsistentLatest, replies: [
            latest, repo, .init("/releases?per_page=100&page=1", json: "[{\"draft\":false,\"prerelease\":false}]")
        ])
        await expectIssue(.unexpectedStatus(403), replies: [latest, repo, .init("/releases?per_page=100&page=1", status: 403)])
        await expectIssue(.incompleteListing, replies: [
            latest, repo, .init("/releases?per_page=100&page=1", json: "[]",
                                link: "<https://example.invalid/>; rel=\"next\"")
        ])
    }

    func testRateLimitRedirectAndBadDataAreFailures() async {
        for status in [302, 403, 429, 503] {
            await expectIssue(.unexpectedStatus(status), replies: [.init("/releases/latest", status: status)])
        }
        let http = ReleaseHTTPFixture([.init("/releases/latest", json: "null")])
        do {
            _ = try await ReleaseClient(get: { try await http.get($0) }).check(runningVersion: "0.1")
            XCTFail("Malformed JSON was accepted")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testClientRefusesInvalidRunningVersionBeforeNetwork() async {
        await expectIssue(.invalidRunningVersion, replies: [], runningVersion: "unknown")
    }

    @MainActor
    func testTwoEntriesCoalesceExplicitChecksAndKeepValidatedReleasePage() async throws {
        let reply = try JSONDecoder().decode(GitHubRelease.self, from: Data(releaseJSON(tag: "v7.0").utf8))
        let check = HeldReleaseCheck()
        var destinations: [URL] = []
        let source = UpdatePresentationSource(makeCoordinator: { source in
            UpdateCoordinator(source: source, operations: .init(
                check: { await check.read(runningVersion: $0) },
                availability: { _ in .failure(.mutableRelease) },
                prepare: { _, _ in throw UpdatePackageIssue.mutableRelease }
            ), openRelease: { destinations.append($0) })
        })
        let settingsAbout = source
        let independentAbout = source

        let running = try XCTUnwrap(RunningUpdateApp())
        XCTAssertEqual(settingsAbout.presentation.status, .idle)
        let before = await check.versions
        XCTAssertEqual(before, [])
        independentAbout.perform(.showRelease)
        XCTAssertEqual(destinations, [])
        settingsAbout.perform(.primary)
        XCTAssertEqual(independentAbout.presentation.status, .checking)
        independentAbout.perform(.primary)
        try await waitUntil { await check.versions == [running.version] }
        await check.complete(.newer(reply))
        let unavailable = UpdatePresentation.Status.unavailable(version: "v7.0", reason: .mutableRelease, canRetry: false)
        try await waitUntil { independentAbout.presentation.status == unavailable }
        XCTAssertEqual(settingsAbout.presentation, independentAbout.presentation)
        XCTAssertTrue(settingsAbout.presentation.showsReleaseAction)
        independentAbout.perform(.showRelease)
        XCTAssertEqual(destinations, [URL(string: project + "/releases/tag/v7.0")!])
        let after = await check.versions
        XCTAssertEqual(after, [running.version])

        independentAbout.perform(.primary)
        settingsAbout.perform(.primary)
        try await waitUntil { await check.versions == [running.version, running.version] }
        await check.complete(.current)
        try await waitUntil { settingsAbout.presentation.status == .current }
        XCTAssertEqual(independentAbout.presentation.status, .current)
    }

    @MainActor
    func testPackageVerificationFailureOffersRetryAndReleaseOnSharedSource() async throws {
        let package = releaseJSON(tag: "v7.0").replacingOccurrences(of: "\"assets\":[]", with: """
        "assets":[{"id":123,"name":"FlutterRunlet-v7.0-macOS-universal.dmg","state":"uploaded","size":256,
        "digest":"sha256:\(String(repeating: "a", count: 64))","url":"\(api)/releases/assets/123",
        "browser_download_url":"\(project)/releases/download/v7.0/FlutterRunlet-v7.0-macOS-universal.dmg"}]
        """)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: Data(package.utf8))
        let offer = try UpdateDownload(release: release)
        let attempts = PackageAttempts()
        var destinations: [URL] = []
        let settings = UpdatePresentationSource(makeCoordinator: { source in
            UpdateCoordinator(source: source, operations: .init(
                check: { _ in .newer(release) },
                availability: { _ in .success(offer) },
                prepare: { _, _ in try await attempts.rejectedPackage() }
            ), openRelease: { destinations.append($0) })
        })
        let about = settings
        settings.perform(.primary)
        try await waitUntil { about.presentation.status == .available("v7.0") }
        about.perform(.primary)
        XCTAssertEqual(settings.presentation.status, .updating)
        settings.perform(.primary)
        let mismatch = UpdatePresentation.Status.unavailable(version: "v7.0", reason: .versionMismatch, canRetry: true)
        try await waitUntil { settings.presentation.status == mismatch }
        XCTAssertEqual(settings.presentation, about.presentation)
        XCTAssertTrue(about.presentation.showsReleaseAction)
        settings.perform(.showRelease)
        XCTAssertEqual(destinations, [release.releasePage])
        settings.perform(.primary)
        try await waitUntil { about.presentation.status == .failed(.verification) }
        let count = await attempts.count
        XCTAssertEqual(count, 2)
    }

    @MainActor
    func testUnavailableVersionUsesLocalizedReasonAndReusesExistingActions() {
        let presentation = UpdatePresentation(status: .unavailable(version: "v7.0", reason: .mutableRelease, canRetry: false))
        let english = Locale(identifier: "en")
        let chinese = Locale(identifier: "zh-Hans")
        XCTAssertEqual(english.appString(presentation.feedback), "New version v7.0 cannot be installed safely. Please download and install manually:")
        XCTAssertEqual(chinese.appString(presentation.feedback), "发现新版 v7.0，暂无法安全安装。请手动下载安装：")
        XCTAssertTrue(presentation.showsReleaseAction)
        XCTAssertTrue(presentation.canPerformPrimary)
        XCTAssertEqual(english.appString(presentation.primaryTitle), "Check for Updates")
    }

    @MainActor
    private func waitUntil(_ predicate: () async -> Bool) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(3)
        while !(await predicate()) {
            guard clock.now < deadline else { throw URLError(.timedOut) }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func expectIssue(_ expected: ReleaseClient.Issue, replies: [ReleaseHTTPFixture.Stub],
                             runningVersion: String = "0.1") async {
        let http = ReleaseHTTPFixture(replies)
        do {
            _ = try await ReleaseClient(get: { try await http.get($0) }).check(runningVersion: runningVersion)
            XCTFail("Expected \(expected)")
        } catch {
            XCTAssertEqual(error as? ReleaseClient.Issue, expected)
        }
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

private let repositoryJSON = """
{"id":123,"full_name":"atypiape/flutter-runlet","private":false,"visibility":"public","url":"\(api)"}
"""

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
        let link: String?

        init(_ path: String, status: Int = 200, json: String = "{}", servedFrom: URL? = nil, link: String? = nil) {
            self.path = path
            self.status = status
            self.json = json
            self.servedFrom = servedFrom
            self.link = link
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
                                       httpVersion: "HTTP/1.1", headerFields: stub.link.map { ["Link": $0] })!
        return (Data(stub.json.utf8), response)
    }
}

private actor HeldReleaseCheck {
    private(set) var versions: [String] = []
    private var pending: CheckedContinuation<ReleaseCheckResult, Never>?

    func read(runningVersion: String) async -> ReleaseCheckResult {
        versions.append(runningVersion)
        return await withCheckedContinuation { pending = $0 }
    }

    func complete(_ result: ReleaseCheckResult) {
        pending?.resume(returning: result)
        pending = nil
    }
}

private actor PackageAttempts {
    private(set) var count = 0

    func rejectedPackage() throws -> PreparedUpdate {
        count += 1
        throw count == 1 ? UpdatePackageIssue.versionMismatch : UpdatePackageIssue.digestMismatch
    }
}
