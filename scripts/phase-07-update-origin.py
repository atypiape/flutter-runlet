#!/usr/bin/env python3
"""Supply the real isolated DMG over loopback with GitHub-shaped release metadata."""
import argparse
from datetime import datetime, timezone
from functools import partial
from hashlib import file_digest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from urllib.parse import urlsplit

REPO_PATH = "/repos/atypiape/flutter-runlet"
API = "https://api.github.com" + REPO_PATH
HTML = "https://github.com/atypiape/flutter-runlet/releases"
RELEASE_ID = 7005
IMAGE_ID = 70051
SIDECAR_ID = 70052


def digest(path):
    with path.open("rb") as source:
        return file_digest(source, "sha256").hexdigest()


def asset(asset_id, path, tag):
    return {
        "id": asset_id, "name": path.name, "state": "uploaded", "size": path.stat().st_size,
        "digest": f"sha256:{digest(path)}", "url": f"{API}/releases/assets/{asset_id}",
        "browser_download_url": f"{HTML}/download/{tag}/{path.name}",
    }


class Origin(BaseHTTPRequestHandler):
    def __init__(self, *args, files, release, events, fault, **kwargs):
        self.files = files
        self.release = release
        self.events = events
        self.fault = fault
        super().__init__(*args, **kwargs)

    def log_message(self, *_):
        pass

    def record(self, status, body_bytes):
        row = {
            "time": datetime.now(timezone.utc).isoformat(),
            "method": self.command, "path": self.path, "status": status, "bytes": body_bytes,
        }
        with self.events.open("a") as output:
            output.write(json.dumps(row) + "\n")

    def json_response(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/vnd.github+json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        self.record(status, len(body))

    def do_GET(self):
        parsed = urlsplit(self.path)
        if not parsed.path.startswith(REPO_PATH) or self.headers.get("Authorization"):
            self.json_response(404, {"message": "Not found"})
            return
        fault = self.fault.read_text().strip() if self.fault.is_file() else "none"
        route = parsed.path.removeprefix(REPO_PATH)
        if route == "/releases/latest":
            if fault == "check-error":
                self.json_response(503, {"message": "Unavailable"})
            elif fault == "no-release":
                self.json_response(404, {"message": "Not found"})
            else:
                self.json_response(200, self.release)
            return
        if route == f"/releases/{RELEASE_ID}":
            self.json_response(200, self.release)
            return
        if route == "":
            self.json_response(200, {"id": 7000, "full_name": "atypiape/flutter-runlet",
                                     "private": False, "visibility": "public", "url": API})
            return
        if route == "/releases":
            self.json_response(200, [] if fault == "no-release" else [self.release])
            return
        if not route.startswith("/releases/assets/"):
            self.json_response(404, {"message": "Not found"})
            return
        data = self.files.get(route.rsplit("/", 1)[-1])
        image = data is not None and data.suffix == ".dmg"
        if data is None or (image and fault == "download-error"):
            self.json_response(503 if data else 404, {"message": "Asset unavailable"})
            return
        with data.open("rb") as file:
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(data.stat().st_size))
            self.end_headers()
            count = 0
            try:
                while chunk := file.read(64 * 1024):
                    if count == 0 and image and fault == "bad-bytes":
                        chunk = bytes([chunk[0] ^ 1]) + chunk[1:]
                    self.wfile.write(chunk)
                    count += len(chunk)
            except (BrokenPipeError, ConnectionResetError):
                pass
            self.record(200, count)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workspace", type=lambda p: Path(p).resolve(strict=True))
    parser.add_argument("image", type=lambda p: Path(p).resolve(strict=True))
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()
    if tuple(args.workspace.parts[-3:]) != (".private", "phase-07", "update") or not args.image.is_relative_to(args.workspace):
        parser.error("use only a DMG under the private phase 07 update workspace")
    match = re.fullmatch(r"FlutterRunlet-(v[0-9]+(?:\.[0-9]+)*)-macOS-universal\.dmg", args.image.name)
    if not match or not 1024 < args.port <= 65535:
        parser.error("expected an isolated versioned update DMG and non-privileged port")
    tag = match[1]
    sidecar = args.image.with_name(args.image.name + ".sha256")
    files = {str(IMAGE_ID): args.image}
    if sidecar.is_file():
        if (sidecar.read_text() not in {f"{digest(args.image)}  {args.image.name}\n",
                                      f"{digest(args.image)}  {args.image.name}"}):
            parser.error("incorrect sidecar for this update DMG")
        files[str(SIDECAR_ID)] = sidecar
    release = {
        "id": RELEASE_ID, "tag_name": tag, "draft": False, "prerelease": False, "immutable": True,
        "url": f"{API}/releases/{RELEASE_ID}", "assets_url": f"{API}/releases/{RELEASE_ID}/assets",
        "html_url": f"{HTML}/tag/{tag}", "assets": [asset(int(key), path, tag) for key, path in files.items()],
    }
    origin = partial(Origin, files=files, release=release, events=args.workspace / "loopback-events.jsonl",
                     fault=args.workspace / "transport-fault")
    with ThreadingHTTPServer(("127.0.0.1", args.port), origin) as server:
        print(f"Loopback listening on {server.server_port}; {tag} {release['assets'][0]['digest']}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
