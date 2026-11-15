import Foundation
import OSLog

struct ReleaseVersion: Comparable, Sendable {
    private let segments: [String]

    init?(_ text: String) {
        guard text.utf8.count <= 128 else { return nil }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty, parts.allSatisfy({ part in
            !part.isEmpty && part.utf8.allSatisfy { (48...57).contains($0) }
        }) else { return nil }

        var digits = parts.map { String($0.drop(while: { $0 == "0" })) }
        while digits.last == "" { digits.removeLast() }
        segments = digits
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        for (left, right) in zip(lhs.segments, rhs.segments) where left != right {
            if left.count != right.count { return left.count < right.count }
            return left < right
        }
        return lhs.segments.count < rhs.segments.count
    }
}

enum UpdateRepository {
    static let name = "atypiape/flutter-runlet"
    static let api = URL(string: "https://api.github.com/repos/\(name)")!
    static let releases = URL(string: "https://github.com/\(name)/releases")!
    static let log = Logger(subsystem: "com.atypiape.FlutterRunlet", category: "ReleaseUpdates")

    static func request(_ url: URL, accept: String = "application/vnd.github+json") -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("FlutterRunlet", forHTTPHeaderField: "User-Agent")
        return request
    }
}

struct GitHubRelease: Decodable, Sendable {
    struct Asset: Decodable, Equatable, Sendable {
        let id: Int64
        let name: String
        let state: String
        let size: Int64
        let digest: String?
        let url: String
        let browserDownloadURL: String

        enum CodingKeys: String, CodingKey {
            case id, name, state, size, digest, url
            case browserDownloadURL = "browser_download_url"
        }
    }

    let id: Int64
    let tag: String
    let draft: Bool
    let prerelease: Bool
    let immutable: Bool?
    let url: String
    let assetsURL: String
    let htmlURL: String
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case id, draft, prerelease, immutable, url, assets
        case tag = "tag_name"
        case assetsURL = "assets_url"
        case htmlURL = "html_url"
    }

    var version: ReleaseVersion? {
        ReleaseVersion(tag.hasPrefix("v") ? String(tag.dropFirst()) : tag)
    }

    var isFormal: Bool { !draft && !prerelease }

    var releasePage: URL { UpdateRepository.releases.appending(path: "tag/\(tag)") }

    var hasExpectedIdentity: Bool {
        id > 0 && version != nil
            && url == UpdateRepository.api.appending(path: "releases/\(id)").absoluteString
            && assetsURL == UpdateRepository.api.appending(path: "releases/\(id)/assets").absoluteString
            && htmlURL == releasePage.absoluteString
    }
}

enum ReleaseCheckResult: Sendable {
    case current, noRelease, newer(GitHubRelease)
}

struct ReleaseClient: Sendable {
    enum Issue: Error, Equatable {
        case invalidRunningVersion, invalidResponse, unexpectedStatus(Int), inconsistentLatest, incompleteListing
    }

    private struct Repository: Decodable {
        let id: Int64
        let full_name: String
        let `private`: Bool
        let visibility: String
        let url: String
    }

    private struct ListedRelease: Decodable {
        let draft: Bool
        let prerelease: Bool
    }

    private let get: @Sendable (URL) async throws -> (Data, HTTPURLResponse)

    init(get: @escaping @Sendable (URL) async throws -> (Data, HTTPURLResponse) = { url in
        try await BoundedUpdateHTTP.get(UpdateRepository.request(url), limit: 8 * 1024 * 1024, timeout: 15)
    }) {
        self.get = get
    }

    func check(runningVersion: String) async throws -> ReleaseCheckResult {
        guard let running = ReleaseVersion(runningVersion) else { throw Issue.invalidRunningVersion }
        UpdateRepository.log.notice("Checking latest release")
        let (data, response) = try await read(UpdateRepository.api.appending(path: "releases/latest"))
        UpdateRepository.log.notice("Latest release HTTP \(response.statusCode, privacy: .public)")
        switch response.statusCode {
        case 200:
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            guard release.isFormal, release.hasExpectedIdentity, let version = release.version else {
                throw Issue.invalidResponse
            }
            UpdateRepository.log.notice("Latest formal tag \(release.tag, privacy: .public)")
            return version > running ? .newer(release) : .current
        case 404:
            return try await corroborateMissingRelease()
        default:
            throw Issue.unexpectedStatus(response.statusCode)
        }
    }

    private func read(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        try Task.checkCancellation()
        let (data, response) = try await get(url)
        guard response.url == url else { throw Issue.invalidResponse }
        return (data, response)
    }

    private func corroborateMissingRelease() async throws -> ReleaseCheckResult {
        let (repoData, repoResponse) = try await read(UpdateRepository.api)
        guard repoResponse.statusCode == 200 else { throw Issue.unexpectedStatus(repoResponse.statusCode) }
        let repo = try JSONDecoder().decode(Repository.self, from: repoData)
        guard repo.id > 0, repo.full_name == UpdateRepository.name, !repo.private,
              repo.visibility == "public", repo.url == UpdateRepository.api.absoluteString else {
            throw Issue.invalidResponse
        }

        for page in 1...10 {
            let perPage = 100
            var parts = URLComponents(url: UpdateRepository.api.appending(path: "releases"), resolvingAgainstBaseURL: false)!
            parts.queryItems = [.init(name: "per_page", value: String(perPage)), .init(name: "page", value: String(page))]
            let (data, response) = try await read(parts.url!)
            guard response.statusCode == 200 else { throw Issue.unexpectedStatus(response.statusCode) }
            let listed = try JSONDecoder().decode([ListedRelease].self, from: data)
            guard listed.count <= perPage else { throw Issue.invalidResponse }
            guard listed.allSatisfy({ $0.draft || $0.prerelease }) else { throw Issue.inconsistentLatest }

            let link = response.value(forHTTPHeaderField: "Link")
            let next = link?.range(of: #"\brel\s*=\s*(?:"next"|next\b)"#, options: .regularExpression) != nil
            // Build every URL locally. A Link field can signal more data but does not select a URL.
            if listed.count < perPage, !next { return .noRelease }
            guard !listed.isEmpty else { throw Issue.incompleteListing }
        }
        throw Issue.incompleteListing
    }
}

// Each request owns a session and its serialized delegate. All mutable transfer state is
// used only on that queue. Task cancellation goes to the thread-safe URLSessionTask.
final class BoundedUpdateHTTP: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    enum Issue: Error, Equatable { case response, redirect, sizeLimit, status(Int) }

    private typealias Reply = (Data, HTTPURLResponse)
    private let result: AsyncThrowingStream<Reply, Error>.Continuation
    private let output: FileHandle?
    private let limit: Int64
    private let allowedRedirect: (@Sendable (URL, URL) -> Bool)?
    private var expectedURL: URL
    private var response: HTTPURLResponse?
    private var failure: Error?
    private var data = Data()
    private var received: Int64 = 0
    private var redirects = 0

    private init(url: URL, limit: Int64, output: FileHandle?, allowedRedirect: (@Sendable (URL, URL) -> Bool)?,
                 result: AsyncThrowingStream<Reply, Error>.Continuation) {
        expectedURL = url
        self.limit = limit
        self.output = output
        self.allowedRedirect = allowedRedirect
        self.result = result
    }

    static func get(_ request: URLRequest, limit: Int64, timeout: TimeInterval, output: FileHandle? = nil,
                    allowedRedirect: (@Sendable (URL, URL) -> Bool)? = nil,
                    configuration: URLSessionConfiguration = .ephemeral) async throws -> (Data, HTTPURLResponse) {
        try Task.checkCancellation()
        guard let url = request.url else { throw Issue.response }
        let (stream, result) = AsyncThrowingStream<Reply, Error>.makeStream()
        let delegate = BoundedUpdateHTTP(url: url, limit: limit, output: output,
                                        allowedRedirect: allowedRedirect, result: result)
        configuration.timeoutIntervalForRequest = min(timeout, 12)
        configuration.timeoutIntervalForResource = timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let task = session.dataTask(with: request)
        return try await withTaskCancellationHandler {
            task.resume()
            // The stream's iterator can return nil immediately when the Swift task is
            // cancelled. Wait for the delegate before returning the writer to the caller.
            let completion = Task.detached {
                var replies = stream.makeAsyncIterator()
                guard let reply = try await replies.next() else { throw Issue.response }
                return reply
            }
            do {
                let reply = try await completion.value
                try Task.checkCancellation()
                return reply
            } catch {
                try Task.checkCancellation()
                throw error
            }
        } onCancel: {
            task.cancel()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        guard redirects < 3, [301, 302, 303, 307, 308].contains(response.statusCode),
              response.url == expectedURL, let target = request.url,
              allowedRedirect?(expectedURL, target) == true, request.httpMethod == "GET" else {
            failure = Issue.redirect
            completionHandler(nil)
            task.cancel()
            return
        }
        redirects += 1
        expectedURL = target
        // Reconstruct the CDN request without credentials or API headers.
        completionHandler(URLRequest(url: target, cachePolicy: .reloadIgnoringLocalCacheData))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        guard failure == nil else { completionHandler(.cancel); return }
        guard let http = response as? HTTPURLResponse, http.url == expectedURL else {
            failure = Issue.response
            completionHandler(.cancel)
            return
        }
        guard output == nil || http.statusCode == 200 else {
            failure = Issue.status(http.statusCode)
            completionHandler(.cancel)
            return
        }
        guard response.expectedContentLength <= limit else {
            failure = Issue.sizeLimit
            completionHandler(.cancel)
            return
        }
        self.response = http
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive chunk: Data) {
        guard failure == nil else { return }
        guard Int64(chunk.count) <= limit - received else {
            failure = Issue.sizeLimit
            dataTask.cancel()
            return
        }
        do {
            if let output { try output.write(contentsOf: chunk) }
            else { data.append(chunk) }
            received += Int64(chunk.count)
        } catch {
            failure = error
            dataTask.cancel()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = failure ?? error {
            result.finish(throwing: error)
        } else if let response {
            result.yield((data, response))
            result.finish()
        } else {
            result.finish(throwing: Issue.response)
        }
    }
}
