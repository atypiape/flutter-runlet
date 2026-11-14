import AppKit
import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class SessionLogTests: XCTestCase {
    func testIncompleteAndQueuedLinesKeepTheirOriginalClearBoundary() {
        var generation: UInt64 = 0
        var visible = ""
        let lines = SessionLineStream { line, _, received in
            if received == generation { visible += FlutterLogRedaction.clean(line) }
        }
        lines.receive(Data("old complete\nold partial ws://127.0.0.1:8181/sec".utf8), isError: false, generation: 0)
        XCTAssertEqual(visible, "old complete\n")
        generation = 1
        visible = ""
        lines.receive(Data("queued stderr\n".utf8), isError: true, generation: 0)
        lines.receive(Data("ret=/ws\nnew stdout\n".utf8), isError: false, generation: 1)
        lines.receive(Data("new stderr without newline".utf8), isError: true, generation: 1)
        lines.finish()
        XCTAssertEqual(visible, "new stdout\nnew stderr without newline")
    }

    func testRedactionPreservesOrdinaryTextAndLocalAddressWhileRemovingNestedCredentials() {
        let raw = """
        A Dart VM Service is available at: http://127.0.0.1:8181/noPadding/
        DevTools http://localhost:8181/devToken/devtools/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2Fnested%253D%2Fws&theme=dark
        DevTools http://[::1]:8181/devtools/?uri=ws://[::1]:8181/plainToken/ws
        Ordinary http://localhost:8181/health and UTF-8 日志
        """
        XCTAssertEqual(FlutterLogRedaction.clean(raw), """
        A Dart VM Service is available at: http://127.0.0.1:8181/[已遮罩]/
        DevTools http://localhost:8181/[已遮罩]/devtools/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2F[已遮罩]%2Fws&theme=dark
        DevTools http://[::1]:8181/devtools/?uri=ws://[::1]:8181/[已遮罩]/ws
        Ordinary http://localhost:8181/health and UTF-8 日志
        """)
    }

    func testLiveTaskAndDebugLogsClearAndCopyWithoutChangingProdRecovery() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let script = fixture.project.appending(path: "scripts/simulate-firebase-switch.sh")
        let original = try String(contentsOf: script, encoding: .utf8)
        try original.replacingOccurrences(of: "#!/bin/sh\n", with: #"""
            #!/bin/sh
            if [ "$1" = prod ]; then
                printf '%s\n' 'pre task streamed'
                while [ ! -f .runlet-fixture/pre-finish ]; do /bin/sleep .02; done
            fi
            if [ "$1" = test ]; then
                printf '%s\n' 'post task streamed' >&2
                while [ ! -f .runlet-fixture/post-finish ]; do /bin/sleep .02; done
            fi

            """#).write(to: script, atomically: true, encoding: .utf8)
        let session = fixture.session(store: store, script: #"""
            printf '%s' 'VM Service ws://127.0.0.1:8181/split'
            /bin/sleep .04
            printf '%s\n' 'Secret/ws'
            while [ ! -f .runlet-fixture/next-output ]; do /bin/sleep .02; done
            printf '%s\n' 'same worker new log' >&2
            exec /bin/sleep 60
            """#)
        try fixture.select("prod", in: session)
        session.run()
        do {
            try await eventually { session.logs.contains("pre task streamed") }
            XCTAssertEqual(session.status, .runningPreTask)
            try Data().write(to: fixture.state("pre-finish"))
            try await eventually { session.logs.contains("127.0.0.1:8181/[已遮罩]/ws") }
            XCTAssertFalse(session.logs.contains("splitSecret"))
            XCTAssertEqual(try fixture.marker(), "prod\n")
            let record = try XCTUnwrap(store.read(project: fixture.project))
            session.copyLogs { _ in false }
            XCTAssertEqual(session.feedback.map { Locale(identifier: "zh-Hans").appString($0.title) }, "无法复制运行日志")
            var copied = ""
            session.copyLogs { copied = $0; return true }
            XCTAssertEqual(session.feedback.map { Locale(identifier: "zh-Hans").appString($0.title) }, "已复制运行日志")
            XCTAssertEqual(copied, session.logs)
            XCTAssertFalse(copied.contains("splitSecret"))
            session.clearLogs()
            XCTAssertTrue(session.logs.isEmpty)
            XCTAssertTrue(session.didClearLogs)
            XCTAssertTrue(session.canStop)
            XCTAssertEqual(try store.read(project: fixture.project), record)
            try Data().write(to: fixture.state("next-output"))
            try await eventually { session.logs == "same worker new log\n" }
            session.stop()
            try await eventually { session.logs.contains("post task streamed") }
            XCTAssertEqual(session.status, .restoringEnvironment)
            XCTAssertEqual(try fixture.marker(), "prod\n")
            try Data().write(to: fixture.state("post-finish"))
            await session.waitUntilIdle()
            XCTAssertEqual(session.logs, "same worker new log\npost task streamed\n")
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
        } catch {
            try? Data().write(to: fixture.state("pre-finish"))
            try? Data().write(to: fixture.state("post-finish"))
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testLogsSurvivePreflightAndFailedProjectSwitchAndResetOnlyOnExecutionOrNewProject() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: #"""
            if [ -f .runlet-fixture/second ]; then
                printf '%s\n' 'second run log'
            else
                printf '%s\n' 'first run log'
            fi
            """#)
        try fixture.select("prod", in: session)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(session.logs, "first run log\n")

        let launch = fixture.config("launch")
        let source = try String(contentsOf: launch, encoding: .utf8)
        try source.replacingOccurrences(of: "APP_ENV=prod", with: "APP_ENV=changed")
            .write(to: launch, atomically: true, encoding: .utf8)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(session.logs, "first run log\n")
        XCTAssertTrue(session.requestProjectChange())
        XCTAssertFalse(session.open(fixture.base.appending(path: "nonexistent")))
        XCTAssertEqual(session.logs, "first run log\n")
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertEqual(session.logs, "first run log\n")
        try fixture.select("prod", in: session)
        try Data().write(to: fixture.state("second"))
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(session.logs, "second run log\n")
        XCTAssertFalse(session.didClearLogs)
        XCTAssertTrue(session.open(other.project))
        XCTAssertTrue(session.logs.isEmpty)
        XCTAssertFalse(session.didClearLogs)
    }

    func testWorkerSpawnFailureBeforeFirstTaskKeepsPreviousLogs() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: "printf '%s\\n' 'previous run'")
        try fixture.select("prod", in: session)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(session.logs, "previous run\n")
        let generation = session.logGeneration

        let bad = fixture.project.appending(path: "scripts/invalid-interpreter")
        try "#!/nonexistent-runlet-test-interpreter\n".write(to: bad, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: bad.path)
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: bad.path))
        let tasks = fixture.config("tasks")
        let original = try String(contentsOf: tasks, encoding: .utf8)
        let label = try XCTUnwrap(original.range(of: #""label": "sample:select-prod","#))
        let start = try XCTUnwrap(original.range(of: #""type": "shell","#, range: label.upperBound..<original.endIndex))
        let end = try XCTUnwrap(original.range(of: #""prod", "--quiet"],"#, range: start.upperBound..<original.endIndex))
        let broken = #"""
            "type": "process",
                  "command": "${workspaceFolder}/scripts/invalid-interpreter",
            """#
        var updated = original
        updated.replaceSubrange(start.lowerBound..<end.upperBound, with: broken)
        try updated.write(to: tasks, atomically: true, encoding: .utf8)
        session.reload()
        XCTAssertTrue(session.canRun)
        session.run()
        await session.waitUntilIdle()

        XCTAssertTrue(session.displayMessage.map { Locale(identifier: "zh-Hans").appString($0) }?.contains("进程启动失败（2）") == true)
        XCTAssertEqual(session.logs, "previous run\n")
        XCTAssertEqual(session.logGeneration, generation)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNotNil(try store.read(project: fixture.project))
    }

    func testTrimmingLiveLogPreservesTheVisibleLineAndSelection() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let prefix = String(repeating: "较早😀 " + String(repeating: "a", count: 68) + "\n", count: 480)
        let reading = "retained reading line and selection"
        let first = prefix + reading + "\n" + String(repeating: String(repeating: "b", count: 68) + "\n", count: 250)
        let later = String(repeating: String(repeating: "c", count: 68) + "\n", count: 320)
        XCTAssertLessThan(first.utf8.count, 64 * 1024)
        XCTAssertGreaterThan((first + later).utf8.count, 64 * 1024)
        try first.write(to: fixture.state("first-output"), atomically: true, encoding: .utf8)
        try later.write(to: fixture.state("later-output"), atomically: true, encoding: .utf8)
        let session = fixture.session(store: store, script: #"""
            /bin/cat .runlet-fixture/first-output
            while [ ! -f .runlet-fixture/continue ]; do /bin/sleep .02; done
            /bin/cat .runlet-fixture/later-output
            """#)
        try fixture.select("prod", in: session)
        session.run()
        do {
            try await eventually { session.logs == first }
            let scroll = SessionLogScrollView()
            scroll.setFrameSize(NSSize(width: 580, height: 108))
            scroll.layoutSubtreeIfNeeded()
            scroll.show("尚无运行日志", trimmedUTF16: 0)
            scroll.show(session.logs, trimmedUTF16: session.logTrimmedUTF16)
            let text = try XCTUnwrap(scroll.documentView as? NSTextView)
            let layout = try XCTUnwrap(text.layoutManager)
            let storage = try XCTUnwrap(text.textStorage)
            let selected = (text.string as NSString).range(of: reading)
            text.setSelectedRange(selected)
            func lineTop(of index: Int) -> CGFloat {
                let glyph = layout.glyphIndexForCharacter(at: index)
                return layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil).minY
                    + text.textContainerOrigin.y
            }
            scroll.contentView.scroll(to: CGPoint(x: 0, y: lineTop(of: selected.location) + 3))
            scroll.reflectScrolledClipView(scroll.contentView)
            let readingOffset = scroll.documentVisibleRect.minY - lineTop(of: selected.location)
            try Data().write(to: fixture.state("continue"))
            await session.waitUntilIdle()
            let trimmed = session.logTrimmedUTF16
            XCTAssertGreaterThan(trimmed, 0)
            XCTAssertLessThan(trimmed, selected.location)
            XCTAssertLessThanOrEqual(session.logs.utf8.count, 64 * 1024)
            scroll.show(session.logs, trimmedUTF16: trimmed)
            let retained = (text.string as NSString).range(of: reading)
            XCTAssertEqual(retained.location, selected.location - trimmed)
            XCTAssertEqual(text.selectedRange(), retained)
            XCTAssertEqual(scroll.documentVisibleRect.minY - lineTop(of: retained.location), readingOffset, accuracy: 2)
            let retainedFont = try XCTUnwrap(storage.attribute(.font, at: retained.location, effectiveRange: nil) as? NSFont)
            let appendedFont = try XCTUnwrap(storage.attribute(.font, at: storage.length - 2, effectiveRange: nil) as? NSFont)
            XCTAssertEqual(retainedFont.fontName, "RobotoMono-Regular")
            XCTAssertEqual(retainedFont.pointSize, 11)
            XCTAssertEqual(appendedFont, retainedFont)
            // A reading anchor and selection that were actually removed clamp to the retained start.
            scroll.contentView.scroll(to: .zero)
            text.setSelectedRange(NSRange(location: 0, length: 1))
            let old = text.string as NSString
            let removed = NSMaxRange(old.lineRange(for: NSRange(location: 0, length: 1)))
            scroll.show(old.substring(from: removed) + "next row\n", trimmedUTF16: trimmed + removed)
            XCTAssertEqual(scroll.documentVisibleRect.minY, 0, accuracy: 2)
            XCTAssertEqual(text.selectedRange(), NSRange(location: 0, length: 0))
        } catch {
            try? Data().write(to: fixture.state("continue"))
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testLogViewReplacesCanonicallyEquivalentTextBeforeTrimmingAgain() throws {
        let first = "heading\n" + String(repeating: "가 e\u{301} e\u{301} e\u{301}\n", count: 32)
        let replacement = "heading\n" + String(repeating: "가 é é é\n", count: 32)
        XCTAssertEqual(first, replacement)
        XCTAssertEqual(first.utf8.count, replacement.utf8.count)
        XCTAssertNotEqual(first.utf16.count, replacement.utf16.count)

        let scroll = SessionLogScrollView()
        let text = try XCTUnwrap(scroll.documentView as? NSTextView)
        scroll.show(first, trimmedUTF16: 0)
        scroll.show(replacement, trimmedUTF16: first.utf16.count)
        guard text.string.utf8.elementsEqual(replacement.utf8) else {
            XCTFail("The log view retained the old encoding")
            return
        }

        let next = String(replacement.dropFirst(8)) + "new row\n"
        scroll.show(next, trimmedUTF16: first.utf16.count + 8)
        XCTAssertTrue(text.string.utf8.elementsEqual(next.utf8))
    }

    private func eventually(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition() {
            guard .now < deadline else { throw SessionIssue("等待运行日志超时") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
