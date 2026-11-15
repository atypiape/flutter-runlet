import CoreFoundation
import CryptoKit
import Darwin
import Foundation
import Security

enum UpdatePackageIssue: Error, Equatable {
    case mutableRelease, publisherNotConfigured, invalidRelease, missingAsset, ambiguousAsset
    case invalidAsset, missingDigest, assetTooLarge, releaseChanged, download, sizeMismatch, digestMismatch
    case invalidSidecar, invalidImage, detachFailed, invalidBundle, invalidSignature, unsupportedArchitecture
    case versionMismatch, notNewer, systemAssessment, staging
}

struct UpdateDownload: Equatable, Sendable {
    struct Asset: Equatable, Sendable {
        let id: Int64
        let name: String
        let size: Int64
        let digest: String

        var apiURL: URL { UpdateRepository.api.appending(path: "releases/assets/\(id)") }

        fileprivate init(_ asset: GitHubRelease.Asset, tag: String, limit: Int64) throws {
            id = asset.id
            name = asset.name
            size = asset.size
            let browserURL = UpdateRepository.releases.appending(path: "download/\(tag)/\(name)")
            guard id > 0, size > 0, asset.state == "uploaded",
                  asset.url == UpdateRepository.api.appending(path: "releases/assets/\(asset.id)").absoluteString,
                  asset.browserDownloadURL == browserURL.absoluteString else {
                throw UpdatePackageIssue.invalidAsset
            }
            guard size <= limit else { throw UpdatePackageIssue.assetTooLarge }
            guard let value = asset.digest, value.hasPrefix("sha256:"),
                  value.dropFirst(7).utf8.count == 64,
                  value.dropFirst(7).utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
                throw UpdatePackageIssue.missingDigest
            }
            digest = String(value.dropFirst(7))
        }
    }

    static let maximumImageBytes: Int64 = 128 * 1024 * 1024
    let repository = UpdateRepository.name
    let releaseID: Int64
    let tag: String
    let immutable: Bool
    let version: ReleaseVersion
    let releasePage: URL
    let image: Asset
    let sidecar: Asset?

    init(release: GitHubRelease) throws {
        guard release.hasExpectedIdentity, release.isFormal, let version = release.version else {
            throw UpdatePackageIssue.invalidRelease
        }
        self.version = version
        releaseID = release.id
        tag = release.tag
        immutable = release.immutable == true
        releasePage = release.releasePage
        let packageTag = tag.hasPrefix("v") ? tag : "v" + tag
        let name = "FlutterRunlet-\(packageTag)-macOS-universal.dmg"
        let images = release.assets.filter { $0.name == name }
        guard let asset = images.first else { throw UpdatePackageIssue.missingAsset }
        guard images.count == 1, release.assets.filter({ $0.id == asset.id }).count == 1 else {
            throw UpdatePackageIssue.ambiguousAsset
        }
        image = try Asset(asset, tag: tag, limit: Self.maximumImageBytes)
        let sidecars = release.assets.filter { $0.name == name + ".sha256" }
        if let checksum = sidecars.first {
            guard sidecars.count == 1, release.assets.filter({ $0.id == checksum.id }).count == 1 else {
                throw UpdatePackageIssue.ambiguousAsset
            }
            sidecar = try Asset(checksum, tag: tag, limit: 1024)
        } else {
            sidecar = nil
        }
    }

    static func permitsAssetRedirect(from: URL, to: URL) -> Bool {
        guard let target = URLComponents(url: to, resolvingAgainstBaseURL: false),
              target.scheme == "https", target.host == "release-assets.githubusercontent.com",
              target.port == nil, target.user == nil, target.password == nil, target.fragment == nil,
              target.percentEncodedPath.hasPrefix("/github-production-release-asset-") else { return false }
        return from.host == UpdateRepository.api.host || from.host == target.host
    }
}

struct RunningUpdateApp: Codable, Equatable, Sendable {
    let productID: String
    let version: String
    let build: String

    init?(bundle: Bundle = .main) {
        guard let product = bundle.bundleIdentifier,
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
              ReleaseVersion(version) != nil, ReleaseVersion(build) != nil else { return nil }
        self.init(productID: product, version: version, build: build)
    }

    init(productID: String, version: String, build: String) {
        self.productID = productID
        self.version = version
        self.build = build
    }
}

struct PreparedUpdate: Sendable {
    struct SignedIdentity: Codable, Equatable, Sendable {
        let app: RunningUpdateApp
        let appCodeHashes: [String: String]
        let workerCodeHashes: [String: String]
        let helperCodeHashes: [String: String]
    }

    let download: UpdateDownload
    let runningApp: RunningUpdateApp
    let signed: SignedIdentity
    let imageURL: URL
    fileprivate let directory: URL

    func discard() throws {
        try UpdatePackageService.removeStage(directory, image: imageURL)
    }
}

struct IsolatedUpdateBuild: Sendable {
    static let productID = "com.atypiape.FlutterRunlet.Phase07Update"
    let root: URL
    let origin: URL
    let imageSHA256: String
    let version: String
    let build: String

    static func read(_ bundle: Bundle = .main, helper: Bool = false) -> Self? {
        #if PHASE07_UPDATE
        guard bundle.bundleIdentifier == (helper ? UpdatePackageService.helperIdentifier : productID),
              let config = bundle.object(forInfoDictionaryKey: "RunletIsolatedUpdate") as? [String: String],
              let path = config["root"], path.hasPrefix("/"), path.hasSuffix("/.private/phase-07/update"),
              let port = config["port"].flatMap(UInt16.init), port > 1024,
              let origin = URL(string: "http://127.0.0.1:\(port)"),
              let digest = config["sha256"], let version = config["version"], let build = config["build"] else {
            return nil
        }
        let root = URL(filePath: path, directoryHint: .isDirectory)
        var status = stat()
        guard root.resolvingSymlinksInPath().path == path, lstat(path, &status) == 0,
              status.st_mode & S_IFMT == S_IFDIR, status.st_mode & 0o077 == 0, status.st_uid == geteuid() else {
            return nil
        }
        return Self(root: root, origin: origin, imageSHA256: digest, version: version, build: build)
        #else
        return nil
        #endif
    }

    var target: URL { root.appending(path: "target/FlutterRunlet.app", directoryHint: .isDirectory) }
    var recovery: URL { root.appending(path: "state", directoryHint: .isDirectory) }

    func trusts(_ download: UpdateDownload) -> Bool {
        imageSHA256 == download.image.digest && ReleaseVersion(version) == download.version && ReleaseVersion(build) != nil
    }

    func request(_ remote: URL) -> (URL, URLRequest) {
        let local = origin.appending(path: String(remote.path.dropFirst()))
        return (local, UpdateRepository.request(local))
    }
}

struct UpdatePackageService: Sendable {
    // The public publisher can be enabled only by a reviewed build after the release freeze.
    private static let publicTeamID: String? = nil
    private static let publicProductID = "com.atypiape.FlutterRunlet"
    static let helperIdentifier = "com.atypiape.FlutterRunlet.UpdateHelper"
    static let helperPath = "Contents/Helpers/FlutterRunletUpdateHelper.app"
    static let helperExecutable = "Contents/MacOS/FlutterRunletUpdateHelper"

    static var installsEnabled: Bool { publicTeamID != nil || IsolatedUpdateBuild.read() != nil }

    static func installationIdentity(at app: URL, productID: String,
                                     fixture: IsolatedUpdateBuild? = nil) throws -> PreparedUpdate.SignedIdentity {
        let trust = try installationTrust(productID: productID, fixture: fixture)
        return try signedIdentity(at: app, productID: productID, trust: trust)
    }

    private static func installationTrust(productID: String, fixture: IsolatedUpdateBuild?) throws -> Trust {
        #if PHASE07_UPDATE
        if let fixture, productID == IsolatedUpdateBuild.productID {
            return .isolated(fixture)
        }
        #endif
        guard let publicTeamID, productID == publicProductID else { throw UpdatePackageIssue.publisherNotConfigured }
        return .developerID(publicTeamID)
    }

    static func stage(_ update: PreparedUpdate, replacing installed: URL, in directory: URL)
        throws -> PreparedUpdate.SignedIdentity {
        let fixture = IsolatedUpdateBuild.read()
        let trust = try installationTrust(productID: update.runningApp.productID, fixture: fixture)
        let old = try signedIdentity(at: installed, productID: update.runningApp.productID, trust: trust)
        guard old.app == update.runningApp else { throw UpdatePackageIssue.invalidBundle }
        let staged = directory.appending(path: "FlutterRunlet.app", directoryHint: .isDirectory)
        try verifyFile(update.imageURL, asset: update.download.image)
        let signed = try inspect(image: update.imageURL, directory: update.directory, running: old.app,
                                 download: update.download, trust: trust, copyingTo: staged)
        try verifyFile(update.imageURL, asset: update.download.image)
        guard update.signed == signed,
              try signedIdentity(at: staged, productID: old.app.productID, trust: trust) == signed else {
            throw UpdatePackageIssue.invalidSignature
        }
        return old
    }

    func check(runningVersion: String) async throws -> ReleaseCheckResult {
        #if PHASE07_UPDATE
        if let fixture = IsolatedUpdateBuild.read() {
            return try await ReleaseClient { remote in
                let (local, request) = fixture.request(remote)
                let (bytes, response) = try await BoundedUpdateHTTP.get(request, limit: 8 * 1024 * 1024, timeout: 15)
                guard response.url == local,
                      let canonical = HTTPURLResponse(url: remote, statusCode: response.statusCode,
                                                      httpVersion: nil, headerFields: nil) else {
                    throw ReleaseClient.Issue.invalidResponse
                }
                return (bytes, canonical)
            }.check(runningVersion: runningVersion)
        }
        #endif
        return try await ReleaseClient().check(runningVersion: runningVersion)
    }

    func availability(for release: GitHubRelease) -> Result<UpdateDownload, UpdatePackageIssue> {
        guard release.immutable == true else { return .failure(.mutableRelease) }
        #if PHASE07_UPDATE
        if let fixture = IsolatedUpdateBuild.read() {
            return Result { try UpdateDownload(release: release) }
                .mapError { $0 as? UpdatePackageIssue ?? .invalidAsset }
                .flatMap { fixture.trusts($0) ? .success($0) : .failure(.digestMismatch) }
        }
        #endif
        guard Self.publicTeamID != nil else { return .failure(.publisherNotConfigured) }
        do {
            return .success(try UpdateDownload(release: release))
        } catch {
            return .failure(error as? UpdatePackageIssue ?? .invalidAsset)
        }
    }

    func prepare(_ download: UpdateDownload, running: RunningUpdateApp) async throws -> PreparedUpdate {
        guard download.immutable else { throw UpdatePackageIssue.mutableRelease }
        #if PHASE07_UPDATE
        if let fixture = IsolatedUpdateBuild.read() {
            guard running.productID == IsolatedUpdateBuild.productID, fixture.trusts(download) else {
                throw UpdatePackageIssue.digestMismatch
            }
            return try await Self.prepare(download, running: running, trust: .isolated(fixture),
                                          stagingRoot: fixture.root, fetch: { asset, output in
                let (local, request) = fixture.request(asset.apiURL)
                let (_, response) = try await BoundedUpdateHTTP.get(request, limit: asset.size, timeout: 60, output: output)
                guard response.statusCode == 200, response.url == local else { throw UpdatePackageIssue.download }
            }) {
                let remote = UpdateRepository.api.appending(path: "releases/\(download.releaseID)")
                let (local, request) = fixture.request(remote)
                let (data, response) = try await BoundedUpdateHTTP.get(request, limit: 8 * 1024 * 1024, timeout: 15)
                guard response.statusCode == 200, response.url == local else { throw UpdatePackageIssue.releaseChanged }
                return try JSONDecoder().decode(GitHubRelease.self, from: data)
            }
        }
        #endif
        guard let team = Self.publicTeamID else { throw UpdatePackageIssue.publisherNotConfigured }
        guard running.productID == Self.publicProductID else { throw UpdatePackageIssue.invalidBundle }

        return try await Self.prepare(download, running: running, trust: .developerID(team), fetch: Self.fetchAsset) {
            let url = UpdateRepository.api.appending(path: "releases/\(download.releaseID)")
            let (data, response) = try await BoundedUpdateHTTP.get(UpdateRepository.request(url),
                                                                   limit: 8 * 1024 * 1024, timeout: 15)
            guard response.statusCode == 200, response.url == url else { throw UpdatePackageIssue.releaseChanged }
            return try JSONDecoder().decode(GitHubRelease.self, from: data)
        }
    }

    private typealias FetchAsset = @Sendable (UpdateDownload.Asset, FileHandle) async throws -> Void

    private enum Trust: Sendable {
        case developerID(String)
        #if PHASE07_UPDATE
        case isolated(IsolatedUpdateBuild)
        #endif
        #if DEBUG
        case fixture(FixtureTrust)
        #endif
    }

    #if DEBUG
    struct FixtureTrust: Sendable {
        let imageSHA256: String
        let signed: PreparedUpdate.SignedIdentity
    }

    // This injection point has no call site in the app and is absent in Release builds.
    static func prepareFixture(_ download: UpdateDownload, running: RunningUpdateApp, trust: FixtureTrust,
                               refresh: @Sendable () async throws -> GitHubRelease,
                               fetch: @escaping @Sendable (UpdateDownload.Asset, FileHandle) async throws -> Void) async throws -> PreparedUpdate {
        try await prepare(download, running: running, trust: .fixture(trust), fetch: fetch, refresh: refresh)
    }
    #endif

    private static func prepare(_ download: UpdateDownload, running: RunningUpdateApp, trust: Trust, stagingRoot: URL? = nil,
                                fetch: FetchAsset,
                                refresh: @Sendable () async throws -> GitHubRelease) async throws -> PreparedUpdate {
        try Task.checkCancellation()
        let fresh: UpdateDownload
        do {
            fresh = try await UpdateDownload(release: refresh())
        } catch {
            try Task.checkCancellation()
            throw UpdatePackageIssue.releaseChanged
        }
        guard fresh == download else { throw UpdatePackageIssue.releaseChanged }

        #if DEBUG
        if case .fixture(let expected) = trust, fresh.image.digest != expected.imageSHA256 {
            throw UpdatePackageIssue.digestMismatch
        }
        #endif

        guard let resolvedTemp = realpath((stagingRoot ?? FileManager.default.temporaryDirectory).path, nil) else {
            throw UpdatePackageIssue.staging
        }
        defer { free(resolvedTemp) }
        let directory = URL(fileURLWithPath: String(cString: resolvedTemp), isDirectory: true)
            .appending(path: "FlutterRunlet-Update-\(UUID().uuidString)", directoryHint: .isDirectory)
        guard mkdir(directory.path, 0o700) == 0 else { throw UpdatePackageIssue.staging }
        let image = directory.appending(path: download.image.name)
        var prepared = false
        defer {
            if !prepared {
                do { try removeStage(directory, image: image) }
                catch { UpdateRepository.log.error("Could not clear private update staging") }
            }
        }

        try await receive(download.image, at: image, using: fetch)
        if let checksum = download.sidecar {
            let sidecarURL = directory.appending(path: checksum.name)
            try await receive(checksum, at: sidecarURL, using: fetch)
            let contents = try String(contentsOf: sidecarURL, encoding: .utf8)
            let expected = "\(download.image.digest)  \(download.image.name)"
            guard contents == expected || contents == expected + "\n" else { throw UpdatePackageIssue.invalidSidecar }
            try FileManager.default.removeItem(at: sidecarURL)
        }
        try Task.checkCancellation()

        let signed = try inspect(image: image, directory: directory, running: running, download: download, trust: trust)
        try verifyFile(image, asset: download.image)
        try Task.checkCancellation()
        prepared = true
        return PreparedUpdate(download: download, runningApp: running, signed: signed, imageURL: image, directory: directory)
    }

    private static func fetchAsset(_ asset: UpdateDownload.Asset, _ output: FileHandle) async throws {
        var request = UpdateRepository.request(asset.apiURL, accept: "application/octet-stream")
        request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        _ = try await BoundedUpdateHTTP.get(request, limit: asset.size, timeout: 90, output: output,
                                            allowedRedirect: UpdateDownload.permitsAssetRedirect)
    }

    private static func receive(_ asset: UpdateDownload.Asset, at url: URL, using fetch: FetchAsset) async throws {
        try Task.checkCancellation()
        let fd = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw UpdatePackageIssue.staging }
        do {
            let output = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
            defer { try? output.close() }
            try await fetch(asset, output)
            try Task.checkCancellation()
            guard fchmod(fd, 0o400) == 0 else { throw UpdatePackageIssue.staging }
        } catch is CancellationError {
            throw CancellationError()
        } catch let issue as UpdatePackageIssue {
            throw issue
        } catch let issue as BoundedUpdateHTTP.Issue where issue == .sizeLimit {
            throw UpdatePackageIssue.sizeMismatch
        } catch {
            throw UpdatePackageIssue.download
        }
        try verifyFile(url, asset: asset)
    }

    private static func verifyFile(_ url: URL, asset: UpdateDownload.Asset) throws {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { throw UpdatePackageIssue.staging }
        let file = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? file.close() }
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG,
              before.st_nlink == 1, before.st_uid == geteuid() else { throw UpdatePackageIssue.staging }
        guard before.st_size == asset.size else { throw UpdatePackageIssue.sizeMismatch }

        var digest = SHA256()
        var size: Int64 = 0
        while let data = try file.read(upToCount: 256 * 1024), !data.isEmpty {
            try Task.checkCancellation()
            size += Int64(data.count)
            guard size <= asset.size else { throw UpdatePackageIssue.sizeMismatch }
            digest.update(data: data)
        }
        var after = stat()
        guard lstat(url.path, &after) == 0, after.st_dev == before.st_dev, after.st_ino == before.st_ino,
              after.st_size == size, before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
              before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec else {
            throw UpdatePackageIssue.staging
        }
        guard size == asset.size else { throw UpdatePackageIssue.sizeMismatch }
        guard hexadecimal(digest.finalize()) == asset.digest else { throw UpdatePackageIssue.digestMismatch }
    }

    private static func inspect(image: URL, directory: URL, running: RunningUpdateApp,
                                download: UpdateDownload, trust: Trust, copyingTo destination: URL? = nil)
        throws -> PreparedUpdate.SignedIdentity {
        let mount = directory.appending(path: "Volume", directoryHint: .isDirectory)
        guard mkdir(mount.path, 0o700) == 0 else { throw UpdatePackageIssue.staging }

        let result = Result<PreparedUpdate.SignedIdentity, Error> {
            try Task.checkCancellation()
            // Let attach finish within its deadline so cancellation cannot race a new mount.
            let info = try NativeUpdateTool.run("/usr/bin/hdiutil", [
                "attach", "-readonly", "-nobrowse", "-noautoopen", "-noautofsck",
                "-verify", "-plist", "-mountpoint", mount.path, image.path
            ], failure: .invalidImage, cancellable: false)
            let entities = try plist(info)["system-entities"] as? [[String: Any]] ?? []
            let disks = wholeDisks(in: entities)
            let mounted = entities.filter { $0["mount-point"] != nil }
            guard disks.count == 1, let disk = disks.first, mounted.count == 1, let entry = mounted.first,
                  entry["mount-point"] as? String == mount.path,
                  let device = entry["dev-entry"] as? String,
                  device.hasPrefix(disk + "s"), isReadOnlyMount(mount, device: device) else {
                throw UpdatePackageIssue.invalidImage
            }
            try Task.checkCancellation()
            let identity = try inspectApp(at: mount, running: running, download: download, trust: trust)
            if let destination {
                let source = mount.appending(path: "FlutterRunlet.app", directoryHint: .isDirectory)
                try copyBundle(from: source, to: destination)
            }
            return identity
        }
        try detachImage(at: image)
        guard !isMountPoint(mount), rmdir(mount.path) == 0 else { throw UpdatePackageIssue.detachFailed }
        return try result.get()
    }

    static func copyBundle(from source: URL, to destination: URL) throws {
        let flags = COPYFILE_ALL | COPYFILE_RECURSIVE | COPYFILE_EXCL | COPYFILE_NOFOLLOW_SRC | COPYFILE_NOFOLLOW_DST
        guard copyfile(source.path, destination.path, nil, copyfile_flags_t(flags)) == 0 else {
            throw UpdatePackageIssue.staging
        }
    }

    private static func inspectApp(at mount: URL, running: RunningUpdateApp,
                                   download: UpdateDownload, trust: Trust) throws -> PreparedUpdate.SignedIdentity {
        let app = mount.appending(path: "FlutterRunlet.app", directoryHint: .isDirectory)
        let entries = try FileManager.default.contentsOfDirectory(atPath: mount.path)
        guard entries.contains("FlutterRunlet.app"), entries.allSatisfy({ ["FlutterRunlet.app", "Applications"].contains($0) }) else {
            throw UpdatePackageIssue.invalidBundle
        }
        if entries.contains("Applications") {
            let shortcut = mount.appending(path: "Applications")
            guard try FileManager.default.destinationOfSymbolicLink(atPath: shortcut.path) == "/Applications" else {
                throw UpdatePackageIssue.invalidBundle
            }
        }
        let signed = try signedIdentity(at: app, productID: running.productID, trust: trust)
        switch trust {
        case .developerID:
            _ = try NativeUpdateTool.run("/usr/bin/syspolicy_check", ["distribution", app.path], failure: .systemAssessment)
        #if PHASE07_UPDATE
        case .isolated(let fixture):
            guard fixture.trusts(download), signed.app.version == fixture.version, signed.app.build == fixture.build else {
                throw UpdatePackageIssue.invalidSignature
            }
        #endif
        #if DEBUG
        case .fixture(let expected):
            guard signed == expected.signed else { throw UpdatePackageIssue.invalidSignature }
        #endif
        }
        guard let numericVersion = ReleaseVersion(signed.app.version), numericVersion == download.version else {
            throw UpdatePackageIssue.versionMismatch
        }
        guard let current = ReleaseVersion(running.version), numericVersion > current else { throw UpdatePackageIssue.notNewer }
        return signed
    }

    private static func signedIdentity(at app: URL, productID: String,
                                       trust: Trust) throws -> PreparedUpdate.SignedIdentity {
        let worker = app.appending(path: "Contents/Helpers/FlutterRunletSessionWorker")
        let executable = app.appending(path: "Contents/MacOS/FlutterRunlet")
        let helper = app.appending(path: helperPath, directoryHint: .isDirectory)
        let helperBinary = helper.appending(path: helperExecutable)
        try validateBundleTree(app)
        try requireFile(executable)
        try requireFile(worker)
        try requireFile(app.appending(path: "Contents/Info.plist"))
        try requireFile(helperBinary)
        try requireFile(helper.appending(path: "Contents/Info.plist"))

        let appSigner: String?
        let workerSigner: String?
        switch trust {
        case .developerID(let team):
            guard team.utf8.count == 10, team.utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) }) else {
                throw UpdatePackageIssue.publisherNotConfigured
            }
            workerSigner = """
            anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists
            and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = "\(team)"
            """
            appSigner = workerSigner.map { $0 + " and identifier \"\(publicProductID)\"" }
        #if PHASE07_UPDATE
        case .isolated:
            appSigner = nil
            workerSigner = nil
        #endif
        #if DEBUG
        case .fixture:
            appSigner = nil
            workerSigner = nil
        #endif
        }

        let (appHashes, signedInfo) = try verifyCode(app, executable: executable, requirement: appSigner, nested: true)
        let (workerHashes, _) = try verifyCode(worker, executable: worker, requirement: workerSigner, nested: false)
        let helperSigner = workerSigner.map { $0 + " and identifier \"\(helperIdentifier)\"" }
        let (helperHashes, helperInfo) = try verifyCode(helper, executable: helperBinary, requirement: helperSigner, nested: true)
        guard helperInfo?["CFBundleIdentifier"] as? String == helperIdentifier,
              helperInfo?["CFBundleExecutable"] as? String == "FlutterRunletUpdateHelper",
              helperInfo?["CFBundlePackageType"] as? String == "APPL",
              let signedInfo, let product = signedInfo["CFBundleIdentifier"] as? String, product == productID,
              signedInfo["CFBundleExecutable"] as? String == "FlutterRunlet",
              signedInfo["CFBundlePackageType"] as? String == "APPL",
              let version = signedInfo["CFBundleShortVersionString"] as? String, ReleaseVersion(version) != nil,
              let build = signedInfo["CFBundleVersion"] as? String, ReleaseVersion(build) != nil else {
            throw UpdatePackageIssue.invalidBundle
        }
        return .init(app: .init(productID: product, version: version, build: build),
                     appCodeHashes: appHashes, workerCodeHashes: workerHashes, helperCodeHashes: helperHashes)
    }

    private static func verifyCode(_ url: URL, executable: URL, requirement: String?,
                                   nested: Bool) throws -> ([String: String], [String: Any]?) {
        let architectures = ["arm64": Int32(CPU_TYPE_ARM64), "x86_64": Int32(CPU_TYPE_X86_64)]
        guard let actual = CFBundleCopyExecutableArchitecturesForURL(executable as CFURL) as? [Int32],
              Set(actual) == Set(architectures.values) else { throw UpdatePackageIssue.unsupportedArchitecture }

        var required: SecRequirement?
        if let requirement {
            guard SecRequirementCreateWithString(requirement as CFString, [], &required) == errSecSuccess else {
                throw UpdatePackageIssue.publisherNotConfigured
            }
        }
        let strict = kSecCSStrictValidate | kSecCSRestrictSymlinks
        let combined = SecCSFlags(rawValue: strict | kSecCSCheckAllArchitectures | (nested ? kSecCSCheckNestedCode : 0))
        var all: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &all) == errSecSuccess, let all,
              SecStaticCodeCheckValidity(all, combined, required) == errSecSuccess else {
            throw UpdatePackageIssue.invalidSignature
        }

        var hashes: [String: String] = [:]
        var info: [String: Any]?
        for arch in architectures.keys.sorted() {
            var slice: SecStaticCode?
            let attributes = [kSecCodeAttributeArchitecture as String: arch] as CFDictionary
            guard SecStaticCodeCreateWithPathAndAttributes(url as CFURL, [], attributes, &slice) == errSecSuccess,
                  let slice, SecStaticCodeCheckValidity(slice, SecCSFlags(rawValue: strict), required) == errSecSuccess else {
                throw UpdatePackageIssue.invalidSignature
            }
            var details: CFDictionary?
            guard SecCodeCopySigningInformation(slice, SecCSFlags(rawValue: kSecCSSigningInformation), &details) == errSecSuccess,
                  let details = details as? [String: Any],
                  let hash = details[kSecCodeInfoUnique as String] as? Data else { throw UpdatePackageIssue.invalidSignature }
            if nested {
                guard let signed = details[kSecCodeInfoPList as String] as? [String: Any],
                      details[kSecCodeInfoIdentifier as String] as? String == signed["CFBundleIdentifier"] as? String else {
                    throw UpdatePackageIssue.invalidSignature
                }
                if let info, !NSDictionary(dictionary: info).isEqual(to: signed) { throw UpdatePackageIssue.invalidSignature }
                info = signed
            }
            hashes[arch] = hexadecimal(hash)
        }
        return (hashes, info)
    }

    private static func validateBundleTree(_ root: URL) throws {
        var status = stat()
        guard lstat(root.path, &status) == 0, status.st_mode & S_IFMT == S_IFDIR else { throw UpdatePackageIssue.invalidBundle }
        var readFailed = false
        let keys: [URLResourceKey] = [.isAliasFileKey, .isSymbolicLinkKey, .isRegularFileKey, .isDirectoryKey]
        guard let paths = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys,
                                                         errorHandler: { _, _ in readFailed = true; return false }) else {
            throw UpdatePackageIssue.invalidBundle
        }
        var count = 0
        var total: Int64 = 0
        for case let url as URL in paths {
            try Task.checkCancellation()
            count += 1
            let values = try url.resourceValues(forKeys: Set(keys))
            var entry = stat()
            guard count <= 20_000, lstat(url.path, &entry) == 0, values.isAliasFile == false,
                  values.isSymbolicLink == false, entry.st_dev == status.st_dev,
                  entry.st_mode & (S_ISUID | S_ISGID) == 0 else { throw UpdatePackageIssue.invalidBundle }
            switch entry.st_mode & S_IFMT {
            case S_IFDIR: continue
            case S_IFREG:
                guard entry.st_nlink == 1, entry.st_size >= 0, entry.st_size <= 512 * 1024 * 1024 - total else {
                    throw UpdatePackageIssue.invalidBundle
                }
                total += entry.st_size
            default: throw UpdatePackageIssue.invalidBundle
            }
        }
        guard !readFailed else { throw UpdatePackageIssue.invalidBundle }
    }

    private static func requireFile(_ url: URL) throws {
        var info = stat()
        guard lstat(url.path, &info) == 0, info.st_mode & S_IFMT == S_IFREG else { throw UpdatePackageIssue.invalidBundle }
    }

    private static func isReadOnlyMount(_ mount: URL, device: String) -> Bool {
        var info = statfs()
        let flags = UInt32(MNT_RDONLY | MNT_NOSUID | MNT_NODEV)
        guard statfs(mount.path, &info) == 0, info.f_flags & flags == flags else { return false }
        return mountField(info.f_mntonname) == mount.path && mountField(info.f_mntfromname) == device
    }

    private static func isMountPoint(_ mount: URL) -> Bool {
        var info = statfs()
        return statfs(mount.path, &info) == 0 && mountField(info.f_mntonname) == mount.path
    }

    private static func mountField<Value>(_ field: Value) -> String {
        withUnsafeBytes(of: field) { String(decoding: $0.prefix(while: { $0 != 0 }), as: UTF8.self) }
    }

    private static func plist(_ data: Data) throws -> [String: Any] {
        guard let result = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw UpdatePackageIssue.invalidImage
        }
        return result
    }

    private static func wholeDisks(in entities: [[String: Any]]) -> Set<String> {
        Set(entities.compactMap { $0["dev-entry"] as? String }.filter {
            $0.range(of: #"^/dev/disk[0-9]+$"#, options: .regularExpression) != nil
        })
    }

    private static func detach(_ disk: String) throws {
        do {
            _ = try NativeUpdateTool.run("/usr/bin/hdiutil", ["detach", disk], failure: .detachFailed, cancellable: false)
        } catch {
            _ = try NativeUpdateTool.run("/usr/bin/hdiutil", ["detach", disk, "-force"], failure: .detachFailed, cancellable: false)
        }
    }

    private static func detachImage(at image: URL) throws {
        let data = try NativeUpdateTool.run("/usr/bin/hdiutil", ["info", "-plist"], failure: .detachFailed, cancellable: false)
        guard let images = try plist(data)["images"] as? [[String: Any]] else { throw UpdatePackageIssue.detachFailed }
        for attached in images where attached["image-path"] as? String == image.path {
            guard let entities = attached["system-entities"] as? [[String: Any]] else { throw UpdatePackageIssue.detachFailed }
            let disks = wholeDisks(in: entities)
            guard !disks.isEmpty else { throw UpdatePackageIssue.detachFailed }
            for disk in disks { try detach(disk) }
        }
    }

    fileprivate static func removeStage(_ directory: URL, image: URL) throws {
        let mount = directory.appending(path: "Volume")
        if FileManager.default.fileExists(atPath: mount.path) {
            try detachImage(at: image)
            guard !isMountPoint(mount) else { throw UpdatePackageIssue.detachFailed }
        }
        do { try FileManager.default.removeItem(at: directory) }
        catch let error as CocoaError where error.code == .fileNoSuchFile { }
    }

    private static func hexadecimal<Bytes: Sequence>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

private enum NativeUpdateTool {
    static func run(_ path: String, _ arguments: [String], failure: UpdatePackageIssue,
                    cancellable: Bool = true) throws -> Data {
        if cancellable { try Task.checkCancellation() }
        let process = Process()
        let pipe = Pipe()
        let input = pipe.fileHandleForReading
        guard fcntl(input.fileDescriptor, F_SETFL, O_NONBLOCK) == 0 else { throw failure }
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C"]
        process.currentDirectoryURL = URL(fileURLWithPath: "/", isDirectory: true)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() }
        catch { throw failure }
        defer {
            if process.isRunning {
                kill(process.processIdentifier, SIGKILL)
                process.waitUntilExit()
            }
            try? input.close()
        }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        let deadline = ContinuousClock.now + .seconds(40)
        while .now < deadline {
            if cancellable { try Task.checkCancellation() }
            let count = read(input.fileDescriptor, &buffer, buffer.count)
            if count > 0 {
                guard data.count + count <= 1024 * 1024 else { throw failure }
                data.append(contentsOf: buffer.prefix(count))
            } else if count == 0, !process.isRunning {
                guard process.terminationStatus == 0 else { throw failure }
                return data
            } else if count < 0, errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
                throw failure
            } else {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        throw failure
    }
}
