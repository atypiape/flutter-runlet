import CryptoKit
import Foundation
import Network
import XCTest
@testable import FlutterRunlet

final class UpdatePackageTests: XCTestCase {
    func testMatchingAssetWithoutAPIDigestIsRejected() throws {
        let release = try packageRelease()
        XCTAssertThrowsError(try UpdateDownload(release: release)) {
            XCTAssertEqual($0 as? UpdatePackageIssue, .missingDigest)
        }
    }

    func testAmbiguousForeignUnfinishedAndOversizedAssetsAreRejected() throws {
        let digest = String(repeating: "a", count: 64)
        let cases: [(GitHubRelease, UpdatePackageIssue)] = [
            (try packageRelease(digest: digest, copies: 2), .ambiguousAsset),
            (try packageRelease(digest: digest, state: "new"), .invalidAsset),
            (try packageRelease(digest: digest, foreignAsset: true), .invalidAsset),
            (try packageRelease(digest: digest, size: UpdateDownload.maximumImageBytes + 1), .assetTooLarge)
        ]
        for (release, issue) in cases {
            XCTAssertThrowsError(try UpdateDownload(release: release)) {
                XCTAssertEqual($0 as? UpdatePackageIssue, issue)
            }
        }
    }

    func testFrozenPublicTrustDoesNotDownloadMutableOrUnconfiguredReleases() async throws {
        let digest = String(repeating: "a", count: 64)
        let immutable = try packageRelease(digest: digest)
        let mutable = try packageRelease(digest: digest, immutable: false)
        let service = UpdatePackageService()
        for (release, issue) in [(immutable, UpdatePackageIssue.publisherNotConfigured), (mutable, .mutableRelease)] {
            XCTAssertThrowsError(try service.availability(for: release).get()) {
                XCTAssertEqual($0 as? UpdatePackageIssue, issue)
            }
            do {
                _ = try await service.prepare(UpdateDownload(release: release), running: XCTUnwrap(RunningUpdateApp()))
                XCTFail("The frozen public trust must reject before download")
            } catch {
                XCTAssertEqual(error as? UpdatePackageIssue, issue)
            }
        }
    }

    func testAssetRedirectIsRestrictedToGitHubReleaseCDN() {
        let source = UpdateRepository.api.appending(path: "releases/assets/123")
        let path = "/github-production-release-asset-2e65be/123"
        XCTAssertTrue(UpdateDownload.permitsAssetRedirect(from: source,
            to: URL(string: "https://release-assets.githubusercontent.com" + path + "?signature=example")!))
        for address in [
            "http://release-assets.githubusercontent.com" + path,
            "https://release-assets.githubusercontent.com.attacker.invalid" + path,
            "https://release-assets.githubusercontent.com:8443" + path,
            "https://guest@release-assets.githubusercontent.com" + path,
            "https://release-assets.githubusercontent.com/other",
            "https://api.github.com/repos/other/repository/releases/assets/124"
        ] {
            XCTAssertFalse(UpdateDownload.permitsAssetRedirect(from: source, to: URL(string: address)!), address)
        }
    }

    #if DEBUG
    func testSignedDMGWithoutUpdateHelperIsRejected() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let app = try fixture.makeApp(folder: "without-helper", version: "7.3.0", build: "73", hasHelper: false)
        let artifact = try fixture.makeArtifact(app: app)
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(artifact.bytes)])
        defer { server.stop() }
        let release = try packageRelease(digest: artifact.trust.imageSHA256, size: Int64(artifact.bytes.count))
        let running = RunningUpdateApp(productID: PackageFixture.productID, version: "7.2.0", build: "1")
        await expectIssue(.invalidBundle) {
            try await prepare(release, running: running, trust: artifact.trust, server: server)
        }
    }

    func testSignedDMGIsDownloadedAndPreparedWithoutChangingRunningApp() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let appA = try fixture.makeApp(folder: "A", version: "7.2.0", build: "902")
        let original = try fixture.hashes(of: appA)
        let appB = try fixture.makeApp(folder: "B", version: "7.3.0", build: "73")
        let artifact = try fixture.makeArtifact(app: appB)
        let sidecar = Data("\(artifact.trust.imageSHA256)  FlutterRunlet-v7.3.0-macOS-universal.dmg\n".utf8)
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(artifact.bytes), "/sidecar": .ok(sidecar)])
        defer { server.stop() }
        let running = RunningUpdateApp(productID: PackageFixture.productID, version: "7.2.0", build: "902")
        let release = try packageRelease(digest: artifact.trust.imageSHA256, size: Int64(artifact.bytes.count), sidecar: sidecar)
        let prepared = try await prepare(release, running: running, trust: artifact.trust, server: server)
        defer { try? prepared.discard() }

        XCTAssertEqual(prepared.signed, artifact.trust.signed)
        XCTAssertEqual(prepared.runningApp, running)
        XCTAssertEqual(prepared.download.releaseID, 42)
        XCTAssertEqual(prepared.download.image.id, 123)
        XCTAssertEqual(try Data(contentsOf: prepared.imageURL), artifact.bytes)
        let modes = try FileManager.default.attributesOfItem(atPath: prepared.imageURL.deletingLastPathComponent().path)
        XCTAssertEqual(modes[.posixPermissions] as? Int, 0o700)
        XCTAssertFalse(try fixture.isMounted(prepared.imageURL))
        XCTAssertEqual(try fixture.hashes(of: appA), original)
        try fixture.verify(appA)
        let receipt = XCTAttachment(string: """
        Release \(prepared.download.tag), asset \(prepared.download.image.id), bytes \(artifact.bytes.count)
        DMG SHA-256 \(artifact.trust.imageSHA256)
        A on disk \(try XCTUnwrap(Bundle(url: appA)).bundleIdentifier ?? "") \(running.version) build \(running.build)
        A code hashes \(original)
        B signed app \(prepared.signed.app) code hashes \(prepared.signed.appCodeHashes)
        B signed worker code hashes \(prepared.signed.workerCodeHashes)
        B signed update helper code hashes \(prepared.signed.helperCodeHashes)
        """)
        receipt.name = "Isolated A and pinned DMG B"
        receipt.lifetime = .keepAlways
        add(receipt)
        try prepared.discard()
        try prepared.discard()
        XCTAssertFalse(FileManager.default.fileExists(atPath: prepared.imageURL.path))
    }

    func testValidSignaturesDoNotAuthorizeTagMismatchSameVersionOrDowngrade() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let app = try fixture.makeApp(folder: "B", version: "7.3.0", build: "77")
        let artifact = try fixture.makeArtifact(app: app)
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(artifact.bytes)])
        defer { server.stop() }
        let before = try fixture.stagingFolders()
        for (tag, activeVersion, issue) in [
            ("v7.3.1", "7.2.0", UpdatePackageIssue.versionMismatch),
            ("v7.3.0", "7.3", .notNewer),
            ("v7.3.0", "7.4", .notNewer)
        ] {
            let running = RunningUpdateApp(productID: PackageFixture.productID, version: activeVersion, build: "1")
            let release = try packageRelease(tag: tag, digest: artifact.trust.imageSHA256, size: Int64(artifact.bytes.count))
            await expectIssue(issue) {
                try await prepare(release, running: running, trust: artifact.trust, server: server)
            }
        }
        XCTAssertEqual(try fixture.stagingFolders(), before)
    }

    func testTamperedBytesReplacedAssetAndReplacedNetworkDigestAreRejected() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let app = try fixture.makeApp(folder: "B", version: "7.3.0", build: "73")
        let artifact = try fixture.makeArtifact(app: app)
        let running = RunningUpdateApp(productID: PackageFixture.productID, version: "7.2.0", build: "1")
        var changed = artifact.bytes
        changed[0] ^= 1
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(changed)])
        defer { server.stop() }
        let size = Int64(artifact.bytes.count)
        let original = try packageRelease(digest: artifact.trust.imageSHA256, size: size)
        let replaced = try packageRelease(digest: artifact.trust.imageSHA256, size: size, assetID: 456)
        let forged = try packageRelease(digest: hex(SHA256.hash(data: changed)), size: size)
        let before = try fixture.stagingFolders()
        await expectIssue(.digestMismatch) { try await prepare(original, running: running, trust: artifact.trust, server: server) }
        await expectIssue(.releaseChanged) {
            try await prepare(original, running: running, trust: artifact.trust, server: server, refresh: replaced)
        }
        await expectIssue(.digestMismatch) { try await prepare(forged, running: running, trust: artifact.trust, server: server) }
        XCTAssertEqual(try fixture.stagingFolders(), before)
    }

    func testValidImageWithWrongSignedIdentityIsRejected() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let trusted = try fixture.makeApp(folder: "trusted", version: "7.3.0", build: "73")
        let other = try fixture.makeApp(folder: "other", version: "7.3.0", build: "74")
        let artifact = try fixture.makeArtifact(app: other)
        let pin = UpdatePackageService.FixtureTrust(imageSHA256: artifact.trust.imageSHA256,
                                                      signed: try fixture.signedIdentity(of: trusted))
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(artifact.bytes)])
        defer { server.stop() }
        let release = try packageRelease(digest: artifact.trust.imageSHA256, size: Int64(artifact.bytes.count))
        let running = RunningUpdateApp(productID: PackageFixture.productID, version: "7.2.0", build: "1")
        await expectIssue(.invalidSignature) { try await prepare(release, running: running, trust: pin, server: server) }
    }

    func testValidImageWithRootAppLinkIsRejected() async throws {
        let fixture = try PackageFixture()
        defer { fixture.cleanUp() }
        let app = try fixture.makeApp(folder: "B", version: "7.3.0", build: "73")
        let artifact = try fixture.makeArtifact(app: app, linkApp: true)
        let server = try await AssetHTTPServer.start(replies: ["/asset": .ok(artifact.bytes)])
        defer { server.stop() }
        let release = try packageRelease(digest: artifact.trust.imageSHA256, size: Int64(artifact.bytes.count))
        let running = RunningUpdateApp(productID: PackageFixture.productID, version: "7.2.0", build: "1")
        await expectIssue(.invalidBundle) { try await prepare(release, running: running, trust: artifact.trust, server: server) }
    }

    private func prepare(_ release: GitHubRelease, running: RunningUpdateApp,
                         trust: UpdatePackageService.FixtureTrust, server: AssetHTTPServer,
                         refresh: GitHubRelease? = nil) async throws -> PreparedUpdate {
        let download = try UpdateDownload(release: release)
        return try await UpdatePackageService.prepareFixture(download, running: running, trust: trust, refresh: { refresh ?? release }) {
            asset, file in
            let path = asset.name.hasSuffix(".sha256") ? "sidecar" : "asset"
            let request = URLRequest(url: server.url.appending(path: path))
            _ = try await BoundedUpdateHTTP.get(request, limit: asset.size, timeout: 5, output: file)
        }
    }

    private func expectIssue(_ expected: UpdatePackageIssue,
                             run: () async throws -> PreparedUpdate) async {
        do {
            let prepared = try await run()
            try prepared.discard()
            XCTFail("Expected \(expected)")
        } catch {
            XCTAssertEqual(error as? UpdatePackageIssue, expected, String(describing: error))
        }
    }
    #endif

    func testRealHTTPRefusesRedirectAndStreamingOverLimit() async throws {
        let server = try await AssetHTTPServer.start(replies: [
            "/redirect": .redirect("/body"),
            "/body": .ok(Data(repeating: 5, count: 64), includeLength: false),
            "/header": .ok(Data(repeating: 5, count: 64))
        ])
        defer { server.stop() }
        for (path, expected) in [
            ("redirect", BoundedUpdateHTTP.Issue.redirect), ("body", .sizeLimit), ("header", .sizeLimit)
        ] {
            do {
                _ = try await BoundedUpdateHTTP.get(URLRequest(url: server.url.appending(path: path)), limit: 32, timeout: 3)
                XCTFail("Expected \(expected)")
            } catch {
                XCTAssertEqual(error as? BoundedUpdateHTTP.Issue, expected)
            }
        }
    }

    func testRealHTTPStopsAtRedirectLimitAndWhenCancelled() async throws {
        let server = try await AssetHTTPServer.start(replies: [
            "/one": .redirect("/two"), "/two": .redirect("/three"),
            "/three": .redirect("/four"), "/four": .redirect("/five"),
            "/five": .ok(Data("results".utf8)), "/slow": .ok(Data("slow".utf8), delay: 1)
        ])
        defer { server.stop() }
        let followsOnlyLoopback: @Sendable (URL, URL) -> Bool = { $0.host == $1.host && $0.port == $1.port }
        do {
            _ = try await BoundedUpdateHTTP.get(URLRequest(url: server.url.appending(path: "one")), limit: 128, timeout: 3,
                                                allowedRedirect: followsOnlyLoopback)
            XCTFail("Expected the fourth redirect to be rejected")
        } catch {
            XCTAssertEqual(error as? BoundedUpdateHTTP.Issue, .redirect)
        }

        let request = URLRequest(url: server.url.appending(path: "slow"))
        let pending = Task { try await BoundedUpdateHTTP.get(request, limit: 128, timeout: 3) }
        try await Task.sleep(for: .milliseconds(100))
        pending.cancel()
        do {
            _ = try await pending.value
            XCTFail("Expected in-flight HTTP cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError, String(describing: error))
        }
    }

}

private func packageRelease(tag: String = "v7.3.0", digest: String? = nil, size: Int64 = 256,
                            assetID: Int64 = 123, copies: Int = 1, state: String = "uploaded",
                            immutable: Bool = true, foreignAsset: Bool = false, sidecar: Data? = nil) throws -> GitHubRelease {
    let api = UpdateRepository.api.absoluteString
    let site = UpdateRepository.releases.absoluteString
    let packageTag = tag.hasPrefix("v") ? tag : "v" + tag
    let assetName = "FlutterRunlet-\(packageTag)-macOS-universal.dmg"
    let asset: [String: Any] = [
        "id": assetID, "name": assetName, "state": state, "size": size,
        "digest": (digest.map { "sha256:\($0)" } as Any?) ?? NSNull(),
        "url": "\(foreignAsset ? "https://example.invalid" : api)/releases/assets/\(assetID)",
        "browser_download_url": "\(site)/download/\(tag)/\(assetName)"
    ]
    var assets = Array(repeating: asset, count: copies)
    if let sidecar {
        let name = assetName + ".sha256"
        let id = assetID + 1
        assets.append([
            "id": id, "name": name, "state": "uploaded", "size": sidecar.count,
            "digest": "sha256:\(hex(SHA256.hash(data: sidecar)))", "url": "\(api)/releases/assets/\(id)",
            "browser_download_url": "\(site)/download/\(tag)/\(name)"
        ])
    }
    let json: [String: Any] = [
        "id": 42, "tag_name": tag, "immutable": immutable, "draft": false, "prerelease": false,
        "url": "\(api)/releases/42", "assets_url": "\(api)/releases/42/assets",
        "html_url": "\(site)/tag/\(tag)", "assets": assets
    ]
    return try JSONDecoder().decode(GitHubRelease.self, from: JSONSerialization.data(withJSONObject: json))
}

private func hex<Bytes: Sequence>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
    bytes.map { String(format: "%02x", $0) }.joined()
}

#if DEBUG
private struct PackageFixture {
    enum Issue: Error { case tool(String), signature }
    static let productID = "com.atypiape.FlutterRunlet.PackageFixture"
    let root: URL
    private let tool: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appending(path: "UpdatePackageTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        tool = root.appending(path: "sample")
        do {
            let source = root.appending(path: "sample.c")
            try "int main(void) { return 0; }\n".write(to: source, atomically: true, encoding: .utf8)
            _ = try run("/usr/bin/clang", ["-arch", "arm64", "-arch", "x86_64", source.path, "-o", tool.path])
        } catch {
            cleanUp()
            throw error
        }
    }

    func cleanUp() { try? FileManager.default.removeItem(at: root) }

    func makeApp(folder: String, version: String, build: String, hasHelper: Bool = true) throws -> URL {
        let app = root.appending(path: "\(folder)/FlutterRunlet.app", directoryHint: .isDirectory)
        let contents = app.appending(path: "Contents", directoryHint: .isDirectory)
        let macOS = contents.appending(path: "MacOS", directoryHint: .isDirectory)
        let helpers = contents.appending(path: "Helpers", directoryHint: .isDirectory)
        for directory in [macOS, helpers] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let plist: [String: Any] = [
            "CFBundleIdentifier": Self.productID, "CFBundleName": "FlutterRunlet", "CFBundleExecutable": "FlutterRunlet",
            "CFBundlePackageType": "APPL", "CFBundleShortVersionString": version, "CFBundleVersion": build
        ]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: contents.appending(path: "Info.plist"))
        try FileManager.default.copyItem(at: tool, to: macOS.appending(path: "FlutterRunlet"))
        let worker = helpers.appending(path: "FlutterRunletSessionWorker")
        try FileManager.default.copyItem(at: tool, to: worker)
        _ = try run("/usr/bin/codesign", ["--force", "--sign", "-", "--identifier", "FlutterRunletSessionWorker", worker.path])
        if hasHelper {
            let helper = helpers.appending(path: "FlutterRunletUpdateHelper.app")
            let helperExecutable = helper.appending(path: "Contents/MacOS/FlutterRunletUpdateHelper")
            try FileManager.default.createDirectory(at: helperExecutable.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let info: [String: Any] = [
                "CFBundleIdentifier": "com.atypiape.FlutterRunlet.UpdateHelper", "CFBundlePackageType": "APPL",
                "CFBundleExecutable": "FlutterRunletUpdateHelper"
            ]
            try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
                .write(to: helper.appending(path: "Contents/Info.plist"))
            try FileManager.default.copyItem(at: tool, to: helperExecutable)
            _ = try run("/usr/bin/codesign", ["--force", "--sign", "-", helper.path])
        }
        _ = try run("/usr/bin/codesign", ["--force", "--sign", "-", app.path])
        try verify(app)
        return app
    }

    func verify(_ app: URL) throws {
        _ = try run("/usr/bin/codesign", ["--verify", "--strict", "--deep", "--all-architectures", app.path])
    }

    struct Artifact {
        let bytes: Data
        let trust: UpdatePackageService.FixtureTrust
    }

    func makeArtifact(app: URL, linkApp: Bool = false) throws -> Artifact {
        let payload = root.appending(path: "payload-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: payload, withIntermediateDirectories: false)
        let entry = payload.appending(path: "FlutterRunlet.app")
        if linkApp { try FileManager.default.createSymbolicLink(at: entry, withDestinationURL: app) }
        else { try FileManager.default.copyItem(at: app, to: entry) }
        try FileManager.default.createSymbolicLink(atPath: payload.appending(path: "Applications").path, withDestinationPath: "/Applications")
        let file = root.appending(path: "fixture-\(UUID().uuidString).dmg")
        _ = try run("/usr/bin/hdiutil", ["create", "-quiet", "-srcfolder", payload.path, "-fs", "HFS+",
                                        "-format", "UDZO", "-volname", "FlutterRunlet Test", file.path])
        // Expectations are pinned from the local signed source before publishing any bytes.
        let bytes = try Data(contentsOf: file)
        return Artifact(bytes: bytes, trust: .init(imageSHA256: hex(SHA256.hash(data: bytes)),
                                                     signed: try signedIdentity(of: app)))
    }

    func signedIdentity(of app: URL) throws -> PreparedUpdate.SignedIdentity {
        let bundle = try XCTUnwrap(Bundle(url: app))
        let helper = app.appending(path: "Contents/Helpers/FlutterRunletUpdateHelper.app")
        return .init(app: try XCTUnwrap(RunningUpdateApp(bundle: bundle)), appCodeHashes: try hashes(of: app),
                     workerCodeHashes: try hashes(of: app.appending(path: "Contents/Helpers/FlutterRunletSessionWorker")),
                     helperCodeHashes: FileManager.default.fileExists(atPath: helper.path) ? try hashes(of: helper) : [:])
    }

    func hashes(of path: URL) throws -> [String: String] {
        var values: [String: String] = [:]
        for arch in ["arm64", "x86_64"] {
            let details = try run("/usr/bin/codesign", ["--display", "--verbose=3", "--arch", arch, path.path])
            guard let line = details.split(separator: "\n").first(where: { $0.hasPrefix("CDHash=") }) else { throw Issue.signature }
            values[arch] = String(line.dropFirst("CDHash=".count))
        }
        return values
    }

    func isMounted(_ image: URL) throws -> Bool {
        try run("/usr/bin/hdiutil", ["info", "-plist"]).contains(image.path)
    }

    func stagingFolders() throws -> Set<String> {
        let path = FileManager.default.temporaryDirectory.path
        return Set(try FileManager.default.contentsOfDirectory(atPath: path).filter { $0.hasPrefix("FlutterRunlet-Update-") })
    }

    private func run(_ path: String, _ arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw Issue.tool("\(path): \(output)") }
        return output
    }
}
#endif

private final class AssetHTTPServer: Sendable {
    struct Reply: Sendable {
        let bytes: Data
        var delay: TimeInterval = 0

        static func ok(_ body: Data, includeLength: Bool = true, delay: TimeInterval = 0) -> Self {
            let length = includeLength ? "Content-Length: \(body.count)\r\n" : ""
            return Self(bytes: Data("HTTP/1.1 200 OK\r\n\(length)Connection: close\r\n\r\n".utf8) + body, delay: delay)
        }

        static func redirect(_ location: String) -> Self {
            Self(bytes: Data("HTTP/1.1 302 Found\r\nLocation: \(location)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8))
        }
    }

    private let listener: NWListener
    let url: URL

    private init(listener: NWListener, port: NWEndpoint.Port) {
        self.listener = listener
        url = URL(string: "http://127.0.0.1:\(port.rawValue)")!
    }

    static func start(replies: [String: Reply]) async throws -> AssetHTTPServer {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        let queue = DispatchQueue(label: "UpdatePackageTests.localHTTP")
        let listener = try NWListener(using: parameters)
        listener.newConnectionHandler = { connection in
            connection.start(queue: queue)
            readRequest(connection, data: Data(), replies: replies)
        }
        let (states, updates) = AsyncThrowingStream<NWEndpoint.Port, Error>.makeStream()
        listener.stateUpdateHandler = { [weak listener] state in
            switch state {
            case .ready:
                if let port = listener?.port { updates.yield(port); updates.finish() }
                else { updates.finish(throwing: URLError(.cannotConnectToHost)) }
            case .failed(let error): updates.finish(throwing: error)
            default: break
            }
        }
        listener.start(queue: queue)
        var iterator = states.makeAsyncIterator()
        guard let port = try await iterator.next() else { throw URLError(.cannotConnectToHost) }
        return AssetHTTPServer(listener: listener, port: port)
    }

    func stop() { listener.cancel() }

    private static func readRequest(_ connection: NWConnection, data: Data, replies: [String: Reply]) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { chunk, _, ended, error in
            let data = data + (chunk ?? Data())
            guard error == nil, data.count <= 8192 else { connection.cancel(); return }
            if data.range(of: Data("\r\n\r\n".utf8)) != nil {
                let line = String(decoding: data, as: UTF8.self).split(separator: "\r\n", maxSplits: 1).first
                if let path = line?.split(separator: " ").dropFirst().first,
                   let reply = replies[String(path)] {
                    DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay) {
                        connection.send(content: reply.bytes, contentContext: .finalMessage, isComplete: true,
                                        completion: .contentProcessed { _ in connection.cancel() })
                    }
                } else {
                    connection.cancel()
                }
            } else if !ended {
                readRequest(connection, data: data, replies: replies)
            } else {
                connection.cancel()
            }
        }
    }
}
