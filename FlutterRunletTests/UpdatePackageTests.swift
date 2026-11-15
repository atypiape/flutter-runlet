import Foundation
import XCTest
@testable import FlutterRunlet

final class UpdatePackageTests: XCTestCase {
    func testMatchingAssetWithoutAPIDigestIsRejected() throws {
        let release = try packageRelease()
        XCTAssertThrowsError(try UpdateDownload(release: release)) {
            XCTAssertEqual($0 as? UpdatePackageIssue, .missingDigest)
        }
    }
}

private func packageRelease(tag: String = "v7.3.0", digest: String? = nil, size: Int64 = 256) throws -> GitHubRelease {
    let api = UpdateRepository.api.absoluteString
    let site = UpdateRepository.releases.absoluteString
    let assetName = "FlutterRunlet-\(tag)-macOS-universal.dmg"
    let asset: [String: Any] = [
        "id": 123, "name": assetName, "state": "uploaded", "size": size,
        "digest": (digest.map { "sha256:\($0)" } as Any?) ?? NSNull(),
        "url": "\(api)/releases/assets/123", "browser_download_url": "\(site)/download/\(tag)/\(assetName)"
    ]
    let json: [String: Any] = [
        "id": 42, "tag_name": tag, "immutable": true, "draft": false, "prerelease": false,
        "url": "\(api)/releases/42", "assets_url": "\(api)/releases/42/assets",
        "html_url": "\(site)/tag/\(tag)", "assets": [asset]
    ]
    return try JSONDecoder().decode(GitHubRelease.self, from: JSONSerialization.data(withJSONObject: json))
}

// RED-only stand-in for the absent asset preflight.
private struct UpdateDownload {
    init(release: GitHubRelease) throws {}
}

private enum UpdatePackageIssue: Error { case missingDigest }
