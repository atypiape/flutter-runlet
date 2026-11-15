#!/usr/bin/env python3
"""Exercise and verify transactions only in the phase 07 private APFS workspace."""

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import signal
import socket
import subprocess
import sys
from types import SimpleNamespace
from urllib.request import urlopen
from urllib.parse import unquote
from PIL import Image

if not __debug__:
    raise RuntimeError("update acceptance requires Python assertions to be enabled")

REPO = Path(__file__).resolve().parent.parent
PHASE = REPO / ".private/phase-07"
PRODUCT = "com.atypiape.FlutterRunlet.Phase07Update"
HELPER_ID = "com.atypiape.FlutterRunlet.UpdateHelper"
APP = "FlutterRunlet.app"
BINARY = Path("Contents/MacOS/FlutterRunlet")
WORKER = Path("Contents/Helpers/FlutterRunletSessionWorker")
HELPER = Path("Contents/Helpers/FlutterRunletUpdateHelper.app")
VERSION_A, BUILD_A = "7.5.0", "750"
VERSION_B, BUILD_B = "7.5.1", "751"


def run(*args, **options):
    return subprocess.run([str(arg) for arg in args], check=True, **options)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def preserve_prior_target(root, target, output):
    if not target.exists() and not target.is_symlink():
        return
    require(not target.is_symlink() and target.parent.resolve(strict=True) == root / "target",
            "refusing to move an unsafe update target")
    require(signed(target)["id"] == PRODUCT, "refusing to move a non-isolated application")
    target.rename(output / "prior-target.app")


def dump(path, payload):
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    path.chmod(0o600)


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def signed(app):
    run("/usr/bin/codesign", "--verify", "--strict", "--deep", "--all-architectures", app,
        stdout=subprocess.DEVNULL)
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    return {"id": info["CFBundleIdentifier"], "version": info["CFBundleShortVersionString"],
            "build": info["CFBundleVersion"], "sha256": digest(app / BINARY), "inode": app.stat().st_ino,
            "device": app.stat().st_dev}


def legacy_candidate(into):
    legacy = into / "legacy" / APP
    legacy.parent.mkdir()
    run("/usr/bin/ditto", PHASE / "07-04/Release-title-observation" / APP, legacy)
    info = legacy / "Contents/Info.plist"
    plist = plistlib.loads(info.read_bytes())
    plist["CFBundleIdentifier"] = PRODUCT
    info.write_bytes(plistlib.dumps(plist))
    run("/usr/bin/codesign", "--force", "--sign", "-", "--identifier", PRODUCT, legacy)
    return legacy


def sign_candidate(source, destination, root, port, version, build, pin):
    run("/usr/bin/ditto", source, destination)
    config = dict(root=str(root), port=str(port), version=VERSION_B, build=BUILD_B, sha256=pin)
    for bundle, identifier in [(destination / HELPER, HELPER_ID), (destination, PRODUCT)]:
        plist = bundle / "Contents/Info.plist"
        data = plistlib.loads(plist.read_bytes())
        data.update(CFBundleIdentifier=identifier, CFBundleShortVersionString=version, CFBundleVersion=build,
                    RunletIsolatedUpdate=config)
        plist.write_bytes(plistlib.dumps(data))
        run("/usr/bin/codesign", "--force", "--sign", "-", "--identifier", identifier, bundle)
    for relative in [BINARY, WORKER, HELPER / "Contents/MacOS/FlutterRunletUpdateHelper"]:
        architectures = subprocess.check_output(["/usr/bin/lipo", "-archs", destination / relative], text=True).split()
        assert set(architectures) == {"arm64", "x86_64"}, (relative, architectures)
    return signed(destination)


def build_candidates(root, receipt_dir, port):
    derived = root / "isolated-build"
    with (receipt_dir / "build.log").open("w") as log:
        run("xcodebuild", "-project", "FlutterRunlet.xcodeproj", "-scheme", "FlutterRunlet", "-configuration", "Release",
            "-destination", "generic/platform=macOS", "-derivedDataPath", derived, "ARCHS=arm64 x86_64", "ONLY_ACTIVE_ARCH=NO",
            "OTHER_SWIFT_FLAGS=$(inherited) -D PHASE07_UPDATE", "build", cwd=REPO, stdout=log, stderr=subprocess.STDOUT)
    source = derived / "Build/Products/Release" / APP
    b_dir = receipt_dir / "B"
    a_dir = receipt_dir / "A"
    b_dir.mkdir()
    a_dir.mkdir()
    b = sign_candidate(source, b_dir / APP, root, port, VERSION_B, BUILD_B, "")
    image = receipt_dir / f"FlutterRunlet-v{VERSION_B}-macOS-universal.dmg"
    run("/usr/bin/hdiutil", "create", "-quiet", "-srcfolder", b_dir, "-volname", "FlutterRunlet Acceptance",
        "-fs", "HFS+", "-format", "UDZO", image)
    run("/usr/bin/hdiutil", "verify", "-quiet", image)
    pinned = digest(image)
    image.with_suffix(".dmg.sha256").write_text(f"{pinned}  {image.name}\n")
    a = sign_candidate(source, a_dir / APP, root, port, VERSION_A, BUILD_A, pinned)
    dump(receipt_dir / "candidates.json", {"A": a, "B": b, "image": image.name, "sha256": pinned, "port": port})
    return a_dir / APP, image, b


def port_available():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def read_json(path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return None


def path_for_pid(pid):
    import ctypes
    proc = ctypes.CDLL("/usr/lib/libproc.dylib")
    output = ctypes.create_string_buffer(4096)
    if proc.proc_pidpath(pid, output, len(output)) > 0:
        return Path(output.value.decode())
    return None


def matching_processes(root):
    pids = subprocess.check_output(["/bin/ps", "-U", str(os.getuid()), "-o", "pid="], text=True).split()
    return {int(pid): path for pid in pids if (path := path_for_pid(int(pid))) and path.is_relative_to(root)
            and path.name in {"FlutterRunlet", "FlutterRunletUpdateHelper", "FlutterRunletSessionWorker"}}


def clean_candidates(root):
    # Clean up only processes whose executable remains in the isolated workspace.
    contacted = set()

    def cleanup():
        running = matching_processes(root)
        for pid, path in running.items():
            if (pid, path) in contacted or path_for_pid(pid) != path:
                continue
            contacted.add((pid, path))
            try:
                if path.name == "FlutterRunletUpdateHelper":
                    desk = Desktop(None, SimpleNamespace(pid=pid), {"steps": []}, "en")
                    for label in ("Dismiss", "关闭"):
                        buttons = desk.elements(label, role="AXButton")
                        if buttons:
                            desk.command("press", buttons[0]["index"])
                            break
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        return not running

    wait(cleanup, "isolated application and helper exit", timeout=12)


@contextmanager
def origin(root, image, port, output):
    with (output / "origin.log").open("w") as log:
        server = subprocess.Popen([sys.executable, REPO / "scripts/phase-07-update-origin.py", root, image, "--port", str(port)],
                                  stdout=log, stderr=subprocess.STDOUT)
        try:
            def ready():
                if server.poll() is not None:
                    raise RuntimeError("loopback server failed to start")
                try:
                    with urlopen(f"http://127.0.0.1:{port}/repos/atypiape/flutter-runlet/releases/latest", timeout=1) as response:
                        return json.load(response).get("tag_name") == f"v{VERSION_B}"
                except OSError:
                    return False
            wait(ready, "loopback origin", timeout=10)
            yield
        finally:
            server.terminate()
            server.wait(timeout=5)


def capture(desktop, binary, output, name, surface, number=None):
    if number is None:
        number = desktop.await_window(surface)["kCGWindowNumber"]
    shot = output / f"{name}.png"
    run(sys.executable, PHASE / "preflight/capture.py", desktop.proc.pid, number, shot, "--candidate", binary)
    return shot.name


def open_about(desktop, surface):
    desktop.command("activate").check_returncode()
    desktop.show(surface)
    if surface == "settings":
        desktop.press(desktop.say("关于", "About"), surface="settings")


def wait_update(desktop, text, surface="about", timeout=30):
    def find():
        return next((row for row in desktop.elements(surface=surface)
                     if text in " ".join(str(row.get(key, "")) for key in ("AXValue", "AXTitle", "AXDescription"))), None)
    return wait(find, text, timeout=timeout)


def new_intent(parent, existing, expected):
    for stage in sorted(parent.glob(".update-*")):
        if stage in existing:
            continue
        current = read_json(stage / "intent.json")
        if current and current.get("phase") == expected:
            return stage, current
    return None


def observed_version(desktop, surface, expected_version, expected_build):
    expected = f"v{expected_version} (build {expected_build})"
    wait_update(desktop, expected, surface)
    rows = [row for row in desktop.elements(surface=surface)
            if expected in {row.get("AXValue"), row.get("AXTitle"), row.get("AXDescription")}]
    assert len(rows) == (2 if surface == "settings" else 1), rows
    return rows


def run_install(root, a_source, image, b, into, name, fault, expected, language="en"):
    into.mkdir()
    parent = root / "target"
    target = parent / APP
    home = root / "home"
    support = home / "Library/Application Support"
    support.mkdir(parents=True, exist_ok=True)
    clean_candidates(root)
    preserve_prior_target(root, target, into)
    if (support / "FlutterRunlet").exists():
        (support / "FlutterRunlet").rename(into / "prior-recovery")
    transport_fault = root / "transport-fault"
    transport_fault.unlink(missing_ok=True)
    if fault == "bad-bytes":
        transport_fault.write_text(fault)
    install_fault = root / "install-fault.json"
    dump(install_fault, fault)
    (root / "helper-refused.json").unlink(missing_ok=True)
    (root / "mutation-ready.json").unlink(missing_ok=True)
    (root / "mutation-done.json").unlink(missing_ok=True)
    run("/usr/bin/ditto", a_source, target)
    original = signed(target)
    before = set(parent.glob(".update-*"))
    log_file = root / "loopback-events.jsonl"
    log_offset = log_file.stat().st_size
    result = {"case": name, "fault": fault, "expected": expected, "language": language, "before": original,
              "startedAt": stamp(), "steps": []}
    logs = (into / "process.log").open("w")
    def launch_original_path():
        return subprocess.Popen([target / BINARY, "-appLanguage", language, "-showMainWindowOnLaunch", "YES",
                                 "-rememberRecentProject", "NO"], env=dict(os.environ, CFFIXED_USER_HOME=str(home), HOME=str(home)),
                                stdin=subprocess.DEVNULL, stdout=logs, stderr=subprocess.STDOUT, start_new_session=True)

    process = launch_original_path()
    reentry = None
    late_legacy = None
    result["oldPID"] = process.pid
    desk = Desktop(None, process, result, language)
    try:
        desk.await_window("main")
        open_about(desk, "about")
        desk.press("update-primary", surface="about")
        wait_update(desk, f"v{VERSION_B}")
        desk.press("update-primary", surface="about")
        if expected == "download-rejected":
            wait_update(desk, "Verification failed. The package checksum did not match.")
            assert process.poll() is None and signed(target) == original
            assert set(parent.glob(".update-*")) == before and not desk.window("prompt")
            result["screenshots"] = [capture(desk, target / BINARY, into, "checksum-refused", "about")]
        else:
            wait(lambda: desk.window("prompt"), "install prompt", timeout=45)
            capture(desk, target / BINARY, into, "confirm", "prompt")
            desk.press(desk.say("安装并重启", "Install and Restart"), role="AXButton", modal=True)
        if expected == "untouched":
            if "observe-reservation" in fault:
                wait(lambda: read_json(root / "helper-refused.json"), "helper holds reservation without reporting ready", timeout=25)
                desk.command("activate").check_returncode()
                desk.key(12, "command")
                desk.key(96)
                assert process.poll() is None and signed(target) == original
                assert not any(path.name == "FlutterRunletSessionWorker" for path in matching_processes(root).values())
                result["reservedAStillRunning"] = path_for_pid(process.pid) == target / BINARY
            wait_update(desk, desk.say("更新包无法存储", "The package could not be stored."), timeout=45)
            assert process.poll() is None and signed(target) == original
            assert not (support / "FlutterRunlet/update-pending.json").exists()
            refused = read_json(root / "helper-refused.json")
            assert refused["phase"] == "prepared" and refused["oldProcess"]["pid"] == process.pid
            assert refused["helperProcess"]["pid"] != process.pid
            result["helperRefusal"] = refused
            result["screenshots"] = [capture(desk, target / BINARY, into, "handoff-refused", "about")]
        elif expected != "download-rejected":
            assert wait(lambda: process.poll() is not None, "normal A exit", timeout=45)
            assert process.returncode == 0, process.returncode
            pending = support / "FlutterRunlet/update-pending.json"
            if fault.startswith("interrupt-"):
                earlier = "committed" if fault == "interrupt-after-commit" else "waitingForNew"
                def interrupted():
                    item = read_json(pending)
                    if item and item["phase"] == earlier and not path_for_pid(item["helperProcess"]["pid"]):
                        trial = item.get("candidateProcess")
                        if not trial or not path_for_pid(trial["pid"]):
                            return item
                    return None
                record = wait(interrupted, "interrupted helper and trial have exited", timeout=45)
                result.update(interruption=record, interruptedDisk=signed(target))
                reentry = launch_original_path()
                assert wait(lambda: reentry.poll() is not None, "normal exit of the recovery bootstrap", timeout=50)
                assert reentry.returncode == 0
            if fault.startswith("pause-"):
                identity = wait(lambda: read_json(root / "mutation-ready.json"), "signed helper ready to test path replacement")
                record = read_json(pending)
                assert record["id"] == identity
                if fault == "pause-compatibility":
                    legacy = legacy_candidate(into)
                    late_legacy = subprocess.Popen([legacy / BINARY, "-appLanguage", language, "-rememberRecentProject", "NO"],
                                                   env=dict(os.environ, CFFIXED_USER_HOME=str(home), HOME=str(home)),
                                                   stdin=subprocess.DEVNULL, stdout=logs, stderr=subprocess.STDOUT)
                    assert wait(lambda: path_for_pid(late_legacy.pid) == legacy / BINARY, "late old process started")
                    result["lateLegacy"] = dict(pid=late_legacy.pid, signed=signed(legacy), oldAppExited=process.returncode,
                                                targetBeforeHelperRecheck=signed(target))
                    assert result["lateLegacy"]["targetBeforeHelperRecheck"] == original
                else:
                    stage_path = Path(unquote(record["stage"].removeprefix("file://")))
                    to_move = target if fault == "pause-before-swap" else stage_path / APP
                    retained_location = into / "displaced-original.app"
                    assert signed(to_move) == original
                    to_move.rename(retained_location)
                    if fault == "pause-before-swap":
                        run("/usr/bin/ditto", retained_location, target)
                dump(root / "mutation-done.json", identity)
            def completed():
                observed = read_json(pending)
                if expected != "preserved" and observed and observed["phase"] == "preserved":
                    raise AssertionError(f"unexpected preserved transaction {observed['id']}: {observed.get('deliveryFailure')}")
                if expected != "preserved" and pending.exists():
                    return None
                return new_intent(parent, before, expected)
            stage, journal = wait(completed, f"journal {expected}", timeout=75)
            if reentry:
                assert journal["reentryProcess"]["pid"] == reentry.pid
            if expected == "preserved":
                helper_pid = journal["helperProcess"]["pid"]
                helper = Desktop(None, SimpleNamespace(pid=helper_pid), result, language)
                window = wait(lambda: next(iter(helper.windows()), None), "independent unconfirmed recovery alert", timeout=12)
                assert any("Automatic update recovery could not be confirmed" in str(row) for row in helper.read())
                result["screenshots"] = [capture(helper, path_for_pid(helper_pid), into, "preserved-without-success", "prompt",
                                                  number=window["kCGWindowNumber"])]
                assert signed(retained_location) == original
                result.update(journal=journal, journalPath=str((stage / "intent.json").relative_to(root)),
                              after=signed(target), retained=signed(retained_location))
                if fault == "pause-before-swap":
                    assert result["after"]["sha256"] == original["sha256"] and result["after"]["inode"] != original["inode"]
                else:
                    assert result["after"]["sha256"] == b["sha256"] and not (stage / APP).exists()
            else:
                record_install_result(result, expected, root, stage, journal, original, b, language, into, target, desk, process, fault)
        with log_file.open() as entries:
            entries.seek(log_offset)
            observed = [json.loads(row) for row in entries]
        assert any(row["status"] == 200 and row["path"].endswith("/releases/assets/70051")
                   and row["bytes"] == image.stat().st_size for row in observed), observed
        result.update(transport=observed, result="passed", finishedAt=stamp())
    finally:
        dump(into / "result.json", result)
        install_fault.unlink(missing_ok=True)
        transport_fault.unlink(missing_ok=True)
        if late_legacy and late_legacy.poll() is None:
            late_legacy.terminate()
            late_legacy.wait(timeout=12)
        clean_candidates(root)
        process.wait(timeout=8)
        if reentry:
            reentry.wait(timeout=8)
        logs.close()


def record_install_result(result, expected, root, stage, journal, original, b, language, into, target, desk, process, fault):
    retained = signed(stage / APP)
    result.update(journal=journal, journalPath=str((stage / "intent.json").relative_to(root)), after=signed(target), retained=retained)
    assert result["after"]["device"] == retained["device"] == original["device"]
    if expected == "committed":
        assert result["after"]["sha256"] == b["sha256"] and retained["inode"] == original["inode"]
        new_pid = journal["attemptedProcess"]["pid"]
        assert new_pid != process.pid and path_for_pid(new_pid) == target / BINARY
        new = Desktop(None, SimpleNamespace(pid=new_pid), result, language)
        new.await_window("main")
        open_about(new, "settings")
        result["settingsVersion"] = observed_version(new, "settings", VERSION_B, BUILD_B)
        first = capture(new, target / BINARY, into, "new-settings-about-and-sidebar", "settings")
        open_about(new, "about")
        result["aboutVersion"] = observed_version(new, "about", VERSION_B, BUILD_B)
        second = capture(new, target / BINARY, into, "new-about", "about")
        result["screenshots"] = [first, second]
        return
    assert expected == "restored"
    assert result["after"] == original and retained["sha256"] == b["sha256"]
    if fault == "hold-b":
        assert journal["deliveryFailure"] == "candidate-timeout" and journal["candidateExitConfirmed"]
        assert journal["candidateProcess"]["pid"] != journal["reopenedProcess"]["pid"]
    if fault == "exit-before-commit":
        assert journal["deliveryFailure"] == "candidate-exited-before-commit" and journal["candidateExitConfirmed"]
    if any(item in {"exit-a", "hold-a", "wrong-a", "launch-a"} for item in fault.split(",")):
        helper_pid = journal["helperProcess"]["pid"]
        helper = Desktop(None, SimpleNamespace(pid=helper_pid), result, language)
        window = wait(lambda: next(iter(helper.windows()), None), "independent recovery alert", timeout=12)
        assert any(str(target) in str(row) for row in helper.read())
        finder = desk.say("在访达中显示", "Show in Finder")
        release = desk.say("查看发布页", "View Release")
        assert helper.element(finder, role="AXButton") and helper.element(release, role="AXButton")
        result["screenshots"] = [capture(helper, path_for_pid(helper_pid), into, "independent-recovery", "prompt",
                                          number=window["kCGWindowNumber"])]
        if "hold-a" in fault:
            assert path_for_pid(journal["attemptedProcess"]["pid"]) == target / BINARY
            assert 29_500 <= journal["originalWaitMilliseconds"] <= 30_500, journal["originalWaitMilliseconds"]
        if "wrong-a" in fault or "launch-a" in fault:
            from collect import browser_url, frontmost
            helper.press(finder, role="AXButton", modal=True)
            def finder_selection():
                script = 'tell application "Finder" to return POSIX path of (item 1 of (get selection) as alias)'
                selected = subprocess.run(["/usr/bin/osascript", "-e", script], capture_output=True, text=True, timeout=4)
                return selected.stdout.strip().rstrip("/") if selected.returncode == 0 else None
            selected = wait(lambda: finder_selection() == str(target), "Finder actually selected restored app", timeout=20)
            assert selected
            helper.press(release, role="AXButton", modal=True)
            link = f"https://github.com/atypiape/flutter-runlet/releases/tag/v{VERSION_B}"
            def opened_release():
                browser = frontmost()
                actual = browser_url(browser)
                if actual == link:
                    return {"browser": browser, "url": actual}
                return None
            result["actions"] = {"finder": str(target), "release": wait(opened_release, "browser received release link", timeout=25)}
    else:
        restored = journal["attemptedProcess"]["pid"]
        assert path_for_pid(restored) == target / BINARY
        old = Desktop(None, SimpleNamespace(pid=restored), result, language)
        old.await_window("main")
        for surface in ("about", "settings"):
            open_about(old, surface)
            wait_update(old, desk.say("已恢复旧版本", "The previous version was restored."), surface)
        result["screenshots"] = [capture(old, target / BINARY, into, "rollback-about", "about"),
                                 capture(old, target / BINARY, into, "rollback-settings", "settings")]


def gate_scenario(root, source, image, into):
    import time
    sys.path.insert(0, str(PHASE / "final-tools"))
    from flutter_session import enabled, observations, select, wait_state

    into.mkdir()
    clean_candidates(root)
    product_target = root / "target" / APP
    home = root / "home"
    support = home / "Library/Application Support"
    support.mkdir(parents=True, exist_ok=True)
    namespace = support / "FlutterRunlet"
    preserve_prior_target(root, product_target, into)
    if namespace.exists():
        namespace.rename(into / "prior-recovery")
    run("/usr/bin/ditto", source, product_target)
    original = signed(product_target)
    before_stages = set(product_target.parent.glob(".update-*"))
    projects = PHASE / "flutter-fixtures"
    sdk = Path(os.environ.get("RUNLET_PHASE07_FLUTTER_SDK", str(Path.home() / "fvm/default"))).resolve(strict=True)
    assert (sdk / "bin/flutter").is_file()
    device = os.environ.get("RUNLET_PHASE07_IOS_DEVICE", "Runlet P5 A29 Isolated")
    active_project = projects / "Update Project A"
    other_project = projects / "Update Project B"
    mark = active_project / ".runlet-fixture"
    fail = mark / "fail-before-test"
    pause = mark / "pause-after-test"
    paused = mark / "paused-after-test"
    assert not fail.exists() and not pause.exists() and not paused.exists()
    output = {"case": "flutter-and-legacy", "steps": [], "screenshots": [], "before": original, "startedAt": stamp()}
    logs = []
    processes = []
    frozen_worker = None
    events = root / "loopback-events.jsonl"
    log_offset = events.stat().st_size

    def launch(app, project, label):
        log = (into / f"{label}.log").open("w")
        logs.append(log)
        binary = app / BINARY
        env = dict(os.environ, CFFIXED_USER_HOME=str(home), FVM_CACHE_PATH=str(sdk.parent),
                   PATH=str(sdk / "bin") + os.pathsep + os.environ["PATH"])
        args = ["-appLanguage", "en", "-showMainWindowOnLaunch", "YES", "-rememberRecentProject", "YES",
                "-recentProjectPath", str(project), "-manualFlutterSDKPath", str(sdk)]
        process = subprocess.Popen([binary, *args], env=env, stdout=log, stderr=subprocess.STDOUT,
                                   stdin=subprocess.DEVNULL, start_new_session=True)
        processes.append(process)
        desktop = Desktop(None, process, output, "en")
        desktop.await_window("main")
        return desktop

    def debug(desktop, project, mode):
        desktop.command("activate").check_returncode()
        enabled(desktop, "Configuration")
        select(desktop, "Configuration", f"({mode})")
        enabled(desktop, "Device for Next Run")
        desktop.press("Device for Next Run", surface="main", role="AXButton")
        choice = wait(lambda: next((row for row in desktop.elements(role="AXButton")
                                    if row.get("AXEnabled") and device in row.get("AXDescription", "")), None),
                      "online isolated simulator", timeout=70)
        desktop.command("press", choice["index"]).check_returncode()
        desktop.observe("selected online isolated simulator", choice)
        enabled(desktop, "Run Current Debug Configuration")
        desktop.key(96)
        return wait_state(desktop, SimpleNamespace(project=project, output=into), "managed Flutter process",
                          lambda value: value["flutter"] and value["workers"], timeout=90)

    def activity(desktop, project):
        value = observations(desktop, SimpleNamespace(project=project, output=into))
        value["risks"] = len(list(namespace.glob("*.risk")))
        return value

    def shot(desk, label, surface, app=product_target):
        output["screenshots"].append(capture(desk, app / BINARY, into, label, surface))

    try:
        desk = launch(product_target, active_project, "current")
        debug(desk, active_project, "prod")
        initial = activity(desk, active_project)
        assert initial["risks"] == 1 and initial["fixtureEnvironment"] == "prod", initial
        output["active"] = initial
        open_about(desk, "about")
        open_about(desk, "settings")
        desk.press("update-primary", surface="about")
        wait_update(desk, f"v{VERSION_B}")
        desk.press("update-primary", surface="about")
        wait_update(desk, "Wait for the debug session to finish.")
        desk.update("about", "Continue Installation", False)
        desk.update("settings", "Continue Installation", False)
        shot(desk, "download-during-prod", "about")
        assert activity(desk, active_project)["flutter"] == initial["flutter"]
        fail.touch(exist_ok=False)
        desk.press("Stop", surface="main", role="AXButton")
        enabled(desk, "Retry Recovery")
        wait_update(desk, "Retry the failed environment recovery.")
        output["failedRecovery"] = activity(desk, active_project)
        assert output["failedRecovery"]["risks"] == 1 and not output["failedRecovery"]["flutter"]
        shot(desk, "failed-recovery-blocks", "about")
        desk.close("settings")
        desk.close("about")
        fail.unlink()
        pause.touch(exist_ok=False)
        desk.press("Retry Recovery", surface="main", role="AXButton")
        output["restoring"] = wait(lambda: (state if (state := activity(desk, active_project))["pausedAfterTest"]
                                                       and state["risks"] == 1 and state["workers"] else None),
                                     "pending managed restoration", timeout=35)
        assert not desk.window("prompt")
        shot(desk, "managed-restoration", "main")
        pause.unlink()
        wait(lambda: desk.window("prompt"), "auto confirm after recovery", timeout=40)
        assert not desk.window("about") and not desk.window("settings") and not list(namespace.glob("*.risk"))
        shot(desk, "prompt-with-about-windows-closed", "prompt")
        desk.press("Later", role="AXButton")
        time.sleep(1.6)
        assert not desk.window("prompt")
        for surface in ("about", "settings"):
            open_about(desk, surface)
            desk.update(surface, "Continue Installation", True)
            desk.press("update-primary", surface=surface)
            wait(lambda: desk.window("prompt"), f"continue from {surface}")
            shot(desk, f"continue-from-{surface}", "prompt")
            desk.press("Later", role="AXButton")
        damaged = namespace / "gate-damaged.risk"
        damaged.touch(mode=0o600, exist_ok=False)
        wait_update(desk, "The environment recovery record cannot be read.")
        shot(desk, "unreadable-recovery-blocks", "about")
        damaged.unlink()
        desk.update("about", "Continue Installation", True)
        desk.press("update-primary", surface="about")
        wait(lambda: desk.window("prompt"), "confirmation before legacy activity")

        legacy = legacy_candidate(into)
        output["legacyBundle"] = signed(legacy)
        older = launch(legacy, other_project, "legacy")
        wait(lambda: not desk.window("prompt"), "same-product legacy instance invalidates confirmation")
        debug(older, other_project, "dev")
        legacy_activity = activity(older, other_project)
        output["legacyActivity"] = legacy_activity
        assert legacy_activity["risks"] == 0 and legacy_activity["flutter"], legacy_activity
        assert not list(namespace.glob("update-worker-*")), "old worker must lack the current namespace lease"
        wait_update(desk, "Wait until the managed process has exited.")
        shot(desk, "cross-project-legacy-blocks", "about")
        worker_pid = legacy_activity["workers"][0]
        assert path_for_pid(worker_pid) == legacy / WORKER
        os.kill(worker_pid, signal.SIGSTOP)
        frozen_worker = worker_pid
        older.proc.terminate()
        older.proc.wait(timeout=10)
        assert path_for_pid(worker_pid) == legacy / WORKER and any(path_for_pid(pid) for pid in legacy_activity["flutter"])
        desk.update("about", "Continue Installation", False)
        shot(desk, "orphaned-legacy-worker-blocks", "about")
        output["orphanedWorker"] = {"worker": worker_pid, "legacyAppExited": older.proc.returncode,
                                    "flutter": legacy_activity["flutter"]}
        os.kill(worker_pid, signal.SIGCONT)
        frozen_worker = None
        wait(lambda: path_for_pid(worker_pid) is None, "legacy worker drained its children", timeout=25)
        desk.update("about", "Continue Installation", True)

        peer_copy = into / "peer" / APP
        peer_copy.parent.mkdir()
        run("/usr/bin/ditto", source, peer_copy)
        peer = launch(peer_copy, other_project, "peer")
        debug(peer, other_project, "dev")
        output["peerActivity"] = activity(peer, other_project)
        wait_update(desk, "Wait for the debug session to finish.")
        shot(desk, "cross-project-current-blocks", "about")
        peer.press("Stop", surface="main", role="AXButton")
        wait(lambda: not activity(peer, other_project)["workers"], "second current instance drains workers", timeout=35)
        peer.proc.terminate()
        peer.proc.wait(timeout=8)
        desk.update("about", "Continue Installation", True)

        assert signed(product_target) == original and set(product_target.parent.glob(".update-*")) == before_stages
        with events.open() as log:
            log.seek(log_offset)
            rows = [json.loads(row) for row in log]
        assert sum(row["bytes"] == image.stat().st_size and row["path"].endswith("/70051") for row in rows) == 1
        output.update(after=signed(product_target), transport=rows, result="passed", finishedAt=stamp())
    finally:
        dump(into / "result.json", output)
        fail.unlink(missing_ok=True)
        pause.unlink(missing_ok=True)
        paused.unlink(missing_ok=True)
        if frozen_worker and path_for_pid(frozen_worker):
            os.kill(frozen_worker, signal.SIGCONT)
        for process in processes:
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=12)
        clean_candidates(root)
        for log in logs:
            log.close()


def signed_application(identity):
    return {key: identity[key] for key in ("id", "version", "build", "sha256")}


def verify_capture(path, expected_pid, executable_digest, expected_size=None):
    receipt = read_json(path.with_suffix(".json"))
    require(isinstance(receipt, dict), f"missing capture receipt: {path.name}")
    with Image.open(path) as image:
        require(image.format == "PNG" and list(image.size) == receipt["pixel_size"],
                f"invalid native PNG or dimensions: {path.name}")
        if expected_size is not None:
            require(image.size == expected_size, f"incorrect surface dimensions: {path.name}")
        image.verify()
    window = receipt["window"]
    require(receipt["png_sha256"] == digest(path) and receipt["candidate_pid"] == expected_pid
            and window["kCGWindowOwnerPID"] == expected_pid and window["kCGWindowIsOnscreen"] is True
            and receipt["candidate_executable_sha256"] == executable_digest,
            f"capture identity mismatch: {path.name}")
    return receipt


def verify_installation(result, expected, root, original, candidate):
    journal_path = (root / result["journalPath"]).resolve(strict=True)
    require(journal_path.name == "intent.json" and journal_path.parent.name.startswith(".update-")
            and journal_path.parent.parent == root / "target", "journal is not in an isolated stage")
    journal = read_json(journal_path)
    expected_app = {"productID": PRODUCT, "version": VERSION_A, "build": BUILD_A}
    successor = {"productID": PRODUCT, "version": VERSION_B, "build": BUILD_B}
    require(journal == result["journal"] and journal["phase"] == expected
            and journal["oldProcess"]["pid"] == result["oldPID"]
            and journal["original"]["app"] == expected_app and journal["candidate"]["app"] == successor,
            "transaction receipt differs from the expected operation")
    target = root / "target" / APP
    require(Path(unquote(journal["target"].removeprefix("file://"))) == target
            and Path(unquote(journal["stage"].removeprefix("file://"))) == journal_path.parent,
            "transaction paths do not match the isolated target")
    before, after, retained = (result[key] for key in ("before", "after", "retained"))
    require(before["device"] == after["device"] == retained["device"], "transaction changed volumes")
    if expected == "committed":
        require(signed_application(after) == signed_application(candidate) and retained == before
                and after["inode"] == journal["candidateObject"]["inode"],
                "no actual A-to-B replacement with A retained")
    elif expected == "restored":
        require(after == before and signed_application(retained) == signed_application(candidate),
                "the signed original was not restored")
    else:
        require(retained == before and signed_application(after) in (signed_application(original),
                                                                       signed_application(candidate)),
                "unconfirmed recovery did not retain the original application")
    return journal


def verify_manifest(path, specifications):
    root = path.parents[1]
    manifest = read_json(path)
    require(manifest["result"] == "passed" and [row["case"] for row in manifest["scenarios"]]
            == [name for name, _, _ in specifications], "incorrect or incomplete manifest")
    candidates = read_json(path.parent / "candidates.json")
    a = path.parent / "A" / APP
    b = path.parent / "B" / APP
    original, candidate = signed(a), signed(b)
    require(candidates["A"] == original and candidates["B"] == candidate
            and (original["id"], original["version"], original["build"]) == (PRODUCT, VERSION_A, BUILD_A)
            and (candidate["id"], candidate["version"], candidate["build"]) == (PRODUCT, VERSION_B, BUILD_B),
            "manifest candidate signatures or identity do not match")
    helper_digest = digest(a / HELPER / "Contents/MacOS/FlutterRunletUpdateHelper")
    seen_captures = set()
    for row, (name, fault, expected) in zip(manifest["scenarios"], specifications):
        result_path = (path.parent / row["path"]).resolve(strict=True)
        require(result_path == path.parent / name / "result.json", "result path does not match its case")
        result = read_json(result_path)
        require(result["case"] == name and result["result"] == "passed"
                and signed_application(result["before"]) == signed_application(original),
                f"result or original application mismatch: {name}")
        require(expected == "blocked" or (result["expected"] == expected and result["fault"] == fault),
                f"unexpected scenario disposition: {name}")
        digest_for_capture = original["sha256"]
        expected_sizes = {}
        if expected == "blocked":
            require(result["before"] == result["after"] and result["active"]["flutter"]
                    and result["failedRecovery"]["risks"] == 1 and result["legacyActivity"]["flutter"]
                    and result["legacyActivity"]["risks"] == 0
                    and result["orphanedWorker"]["worker"] in result["legacyActivity"]["workers"]
                    and result["peerActivity"]["flutter"], "missing cross-instance gate evidence")
            expected_pid = result["active"]["application"]
            expected_sizes = {
                "download-during-prod.png": (400, 412), "failed-recovery-blocks.png": (400, 412),
                "managed-restoration.png": (640, 520), "prompt-with-about-windows-closed.png": (420, 152),
                "continue-from-about.png": (420, 152), "continue-from-settings.png": (420, 152),
                "unreadable-recovery-blocks.png": (400, 412), "cross-project-legacy-blocks.png": (400, 412),
                "orphaned-legacy-worker-blocks.png": (400, 412), "cross-project-current-blocks.png": (400, 412),
            }
        elif expected in ("untouched", "download-rejected"):
            require("journalPath" not in result, "rejected handoff recorded a disk transaction")
            expected_pid = result["oldPID"]
            if expected == "untouched":
                require(result["helperRefusal"]["oldProcess"]["pid"] == expected_pid
                        and result["helperRefusal"]["phase"] == "prepared", "missing readiness-failure evidence")
                expected_sizes = {"handoff-refused.png": (400, 412)}
            else:
                expected_sizes = {"checksum-refused.png": (400, 412)}
        else:
            journal = verify_installation(result, expected, root, original, candidate)
            if expected == "committed":
                expected_pid = journal["attemptedProcess"]["pid"]
                require(expected_pid != result["oldPID"], "new version did not get a new process")
                digest_for_capture = candidate["sha256"]
                expected_sizes = {"new-settings-about-and-sidebar.png": (520, 520), "new-about.png": (400, 412)}
            elif expected == "preserved" or any(action in fault.split(",") for action in
                                                ("exit-a", "hold-a", "wrong-a", "launch-a")):
                expected_pid = journal["helperProcess"]["pid"]
                digest_for_capture = helper_digest
                expected_sizes = {
                    "preserved-without-success.png" if expected == "preserved" else "independent-recovery.png": None
                }
            else:
                expected_pid = journal["reopenedProcess"]["pid"]
                expected_sizes = {"rollback-about.png": (400, 412), "rollback-settings.png": (520, 520)}
        require(set(result["screenshots"]) == set(expected_sizes)
                and len(result["screenshots"]) == len(expected_sizes), f"incomplete native capture evidence: {name}")
        for filename, size in expected_sizes.items():
            shot = (result_path.parent / filename).resolve(strict=True)
            require(shot == result_path.parent / filename, f"capture is outside its case: {filename}")
            receipt = verify_capture(shot, expected_pid, digest_for_capture, size)
            capture_id = receipt["capture_id"]
            require(capture_id not in seen_captures, "native capture reused across results")
            seen_captures.add(capture_id)
            if expected == "committed":
                version = f"v{VERSION_B} (build {BUILD_B})"
                count = sum(version in (node.get("AXValue"), node.get("AXTitle"), node.get("AXDescription"))
                            for node in receipt["accessibility_after_capture"])
                require(count >= (2 if size == (520, 520) else 1), f"visible version missing: {filename}")


def main():
    argument = argparse.ArgumentParser(description=__doc__)
    argument.add_argument("--scenario", choices=("bootstrap-safety", "success", "gate", "rollback"), required=True)
    argument.add_argument("--workspace", type=Path, required=True)
    argument.add_argument("--verify-manifest", type=Path)
    config = argument.parse_args()
    root = config.workspace.resolve(strict=True)
    if root != PHASE / "update" or config.workspace.is_symlink() or root.stat().st_mode & 0o077 or root.stat().st_uid != os.geteuid():
        argument.error("use the repository's private phase 07 update directory with owner-only permissions")
    sys.path.insert(0, str(PHASE / "07-03-trials"))
    global Desktop, wait, stamp
    from collect import Desktop, wait, stamp
    scenarios = {
        "bootstrap-safety": [("helper-not-ready", "helper-no-ready,observe-reservation", "untouched"),
                             ("candidate-timeout", "hold-b", "restored"),
                             ("original-early-exit", "launch-b,exit-a", "restored"),
                             ("original-timeout", "launch-b,hold-a", "restored")],
        "success": [("upgrade", "", "committed")],
        "rollback": [("bad-bytes", "bad-bytes", "download-rejected"),
                     ("before-exchange", "exchange-before", "restored"), ("candidate-early-exit", "exit-b", "restored"),
                     ("candidate-wrong-reply", "wrong-b", "restored"), ("candidate-dies-before-commit", "exit-before-commit", "restored"),
                     ("target-replaced", "pause-before-swap", "preserved"), ("retained-object-moved", "pause-after-swap", "preserved"),
                     ("legacy-raced-after-confirmation", "pause-compatibility", "restored"),
                     ("interrupted-before-exchange", "interrupt-before-exchange", "restored"),
                     ("interrupted-after-exchange", "interrupt-after-exchange", "restored"),
                     ("interrupted-after-commit", "interrupt-after-commit", "committed"),
                     ("original-wrong-reply", "launch-b,wrong-a", "restored"),
                     ("original-launch-failed", "launch-b,launch-a", "restored")],
    }
    specifications = [("flutter-and-legacy", "", "blocked")] if config.scenario == "gate" else scenarios[config.scenario]
    if config.verify_manifest:
        manifest = config.verify_manifest.resolve(strict=True)
        if not manifest.is_relative_to(root) or read_json(manifest).get("scenario") != config.scenario:
            argument.error("manifest is outside the update workspace or belongs to a different scenario")
        verify_manifest(manifest, specifications)
        print(manifest)
        return
    parent = root / "target"
    parent.mkdir(mode=0o700, exist_ok=True)
    if parent.is_symlink() or parent.stat().st_mode & 0o077:
        raise RuntimeError("unsafe isolated target parent")
    when = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output = root / f"{config.scenario}-{when}"
    output.mkdir(mode=0o700)
    port = port_available()
    a, image, b = build_candidates(root, output, port)
    rows = []
    with origin(root, image, port, output):
        if config.scenario == "gate":
            name = "flutter-and-legacy"
            gate_scenario(root, a, image, output / name)
            rows.append({"case": name, "path": f"{name}/result.json"})
        else:
            for name, fault, expected in scenarios[config.scenario]:
                print(f"{config.scenario} / {name}", flush=True)
                run_install(root, a, image, b, output / name, name, fault, expected,
                            language="zh-Hans" if name == "original-launch-failed" else "en")
                rows.append({"case": name, "path": f"{name}/result.json"})
    manifest = output / "manifest.json"
    dump(manifest, {"scenario": config.scenario, "scenarios": rows, "result": "passed"})
    verify_manifest(manifest, specifications)
    print(manifest)


if __name__ == "__main__":
    main()
