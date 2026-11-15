import AppKit
import Carbon
import Foundation
import OSLog

@MainActor
enum InspectorBrowserTabs {
    private static let logger = Logger(subsystem: "com.atypiape.FlutterRunlet", category: "InspectorBrowser")
    private enum Browser: String {
        case edge = "com.microsoft.edgemac"
        case chrome = "com.google.Chrome"
        case safari = "com.apple.Safari"

        var selectTab: String {
            switch self {
            case .edge, .chrome: "set active tab index of browserWindow to tabIndex"
            case .safari: "set current tab of browserWindow to tab tabIndex of browserWindow"
            }
        }
    }

    static func matches(_ candidate: URL, inspector: URL) -> Bool {
        guard let current = URLComponents(url: candidate, resolvingAgainstBaseURL: false),
              let expected = URLComponents(url: inspector, resolvingAgainstBaseURL: false),
              current.scheme == expected.scheme,
              current.host == expected.host, current.port == expected.port,
              current.path == expected.path,
              current.user == nil, current.password == nil else { return false }
        let session = expected.queryItems?.filter { $0.name == "uri" }
        return session?.count == 1 && session?.first?.value != nil &&
            current.queryItems?.filter { $0.name == "uri" } == session
    }

    static func focus(_ inspector: URL) async -> Bool {
        guard let application = NSWorkspace.shared.urlForApplication(toOpen: inspector),
              let bundleID = Bundle(url: application)?.bundleIdentifier,
              let browser = Browser(rawValue: bundleID),
              !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty,
              let scheme = inspector.scheme, ["http", "https"].contains(scheme),
              let host = inspector.host, ["127.0.0.1", "localhost", "::1", "[::1]"].contains(host),
              let port = inspector.port else {
            logger.debug("No running scriptable default browser")
            return false
        }
        // TCC may wait for a user response. Keep the main actor free during permission checking.
        let permission = await Task.detached { permissionToControl(bundleID) }.value
        guard permission == noErr, !Task.isCancelled else {
            if permission != noErr { logger.debug("Browser automation unavailable with code \(permission)") }
            return false
        }

        let address = host == "::1" ? "[::1]" : host
        let origin = "\(scheme)://\(address):\(port)/"
        // Keep URLs off subprocess arguments and return only tabs on this DevTools origin.
        guard let candidates = execute("""
            tell application id "\(browser.rawValue)"
                with timeout of 3 seconds
                    set matchingTabs to {}
                    repeat with browserWindow in windows
                        set tabURLs to URL of every tab of browserWindow
                        set windowID to id of browserWindow as integer
                        repeat with tabIndex from 1 to count of tabURLs
                            set tabURL to item tabIndex of tabURLs
                            if tabURL is not missing value and tabURL starts with "\(origin)" then
                                set end of matchingTabs to {windowID, tabIndex, tabURL}
                            end if
                        end repeat
                    end repeat
                    return matchingTabs
                end timeout
            end tell
            """) else { return false }
        logger.debug("Found \(candidates.numberOfItems) tabs on the DevTools origin")

        for index in 1..<candidates.numberOfItems + 1 {
            guard let tab = candidates.atIndex(index),
                  let rawURL = tab.atIndex(3)?.stringValue, let url = URL(string: rawURL),
                  matches(url, inspector: inspector) else { continue }
            let windowID = tab.atIndex(1)?.int32Value ?? 0
            let tabIndex = tab.atIndex(2)?.int32Value ?? 0
            guard windowID > 0, tabIndex > 0 else { continue }
            let expectedURL = rawURL.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            guard expectedURL.rangeOfCharacter(from: .controlCharacters) == nil else { continue }
            if execute("""
                tell application id "\(browser.rawValue)"
                    with timeout of 3 seconds
                        repeat with browserWindow in windows
                            if (id of browserWindow as integer) is \(windowID) then
                                set tabIndex to \(tabIndex)
                                if tabIndex > (count of tabs of browserWindow) then return false
                                if URL of tab tabIndex of browserWindow is not "\(expectedURL)" then return false
                                \(browser.selectTab)
                                set index of browserWindow to 1
                                activate
                                return true
                            end if
                        end repeat
                        return false
                    end timeout
                end tell
                """)?.booleanValue == true { return true }
        }
        return false
    }

    private nonisolated static func permissionToControl(_ bundleID: String) -> OSStatus {
        var target = AEDesc()
        let result = bundleID.withCString {
            AECreateDesc(DescType(typeApplicationBundleID), $0, bundleID.utf8.count, &target)
        }
        guard result == noErr else { return OSStatus(result) }
        defer { AEDisposeDesc(&target) }
        return AEDeterminePermissionToAutomateTarget(&target, AEEventClass(kAECoreSuite), AEEventID(kAEGetData), true)
    }

    private static func execute(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let code = error?[NSAppleScript.errorNumber] as? Int {
            logger.error("Browser AppleScript failed with code \(code)")
        }
        return error == nil ? result : nil
    }
}
