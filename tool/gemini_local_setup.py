"""Local-only Gemini proxy and HHL Stay Web/Android demo builder.

The Gemini API key stays in this process' memory. It is never written to a
file, build argument, Web bundle, APK, or log. This is for a local classroom
demo only; the proxy binds to loopback and is not a production backend.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import socket
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


PROJECT = Path(__file__).resolve().parents[1]
BUILD_DIR = PROJECT / "build" / "web"
APK_FILE = PROJECT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
LOG_DIR = PROJECT / ".tmp"
LOG_FILE = LOG_DIR / "gemini_build.log"
WEB_SERVER_LOG_FILE = LOG_DIR / "hhl_web_server.log"
SETUP_PORT = 8099
APP_PORT = 8083
MODEL = "gemini-3.6-flash"
MAX_BODY_BYTES = 256 * 1024
GEMINI_API_KEY = ""  # Process memory only; deliberately never persisted.
ALLOWED_APP_ORIGINS = {
    "http://127.0.0.1:8083",
    "http://localhost:8083",
    "http://127.0.0.1:8086",
    "http://localhost:8086",
}
LOCAL_HOSTS = {"127.0.0.1", "localhost", "10.0.2.2"}

PAGE = r"""<!doctype html>
<html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bật Gemini cho HHL Stay</title>
<style>
body{margin:0;background:#f5f7fb;color:#172033;font:16px system-ui,Segoe UI,sans-serif;display:grid;place-items:center;min-height:100vh}
main{box-sizing:border-box;width:min(620px,calc(100% - 32px));background:#fff;border:1px solid #dce3ef;border-radius:20px;padding:28px;box-shadow:0 16px 45px #14234b18}
h1{font-size:24px;margin:0 0 8px}p{color:#64748b;line-height:1.55}.hint{font-size:13px}
input{box-sizing:border-box;width:100%;height:48px;border:1px solid #cbd5e1;border-radius:12px;padding:0 14px;font:inherit;outline-color:#5648ee}
button{margin-top:14px;background:#5145e8;border:0;border-radius:12px;color:white;font:600 15px system-ui;padding:13px 18px;cursor:pointer}button:disabled{opacity:.6;cursor:wait}
#status{min-height:26px;margin-top:16px;font-weight:600}.safe{background:#f1f5ff;border-radius:12px;padding:12px;font-size:13px;color:#475569}
</style>
<main><h1>Bật Gemini cho HHL Stay</h1>
<p>Nhập key một lần để bật Gemini cho localhost và Medium Phone emulator. Key chỉ được giữ trong bộ nhớ của tiện ích đang chạy trên máy này.</p>
<form id="form"><label for="key">Gemini API key</label><p><input id="key" type="password" autocomplete="off" spellcheck="false" required></p><button id="go">Bật Gemini + cập nhật Web và Android</button></form>
<div id="status" role="status">Đang kiểm tra trạng thái…</div>
<div class="safe">Key không được ghi xuống ổ đĩa, đưa vào Web, APK, log hoặc Git. Chỉ chạy với server local trên máy demo; nếu đóng server hoặc khởi động lại máy, hãy nhập key lại.</div>
</main>
<script>
const form=document.querySelector('#form'), keyInput=document.querySelector('#key'), button=document.querySelector('#go'), statusBox=document.querySelector('#status');
async function refresh(){try{const r=await fetch('/status',{cache:'no-store'});const s=await r.json();statusBox.textContent=s.ready?'Gemini đã được cấu hình trong bộ nhớ local.':'Gemini chưa được cấu hình.';}catch(_){statusBox.textContent='Không kiểm tra được trạng thái tiện ích local.';}}
refresh();
form.addEventListener('submit',async event=>{event.preventDefault();const key=keyInput.value.trim();button.disabled=true;statusBox.textContent='Đang bật Gemini và cập nhật Web + APK, vui lòng đợi…';
 try{const response=await fetch('/activate',{method:'POST',headers:{'Content-Type':'application/json','X-HHL-Local-Setup':'1'},body:JSON.stringify({apiKey:key})});const result=await response.json();statusBox.textContent=result.message;if(response.ok)keyInput.value='';}
 catch(_){statusBox.textContent='Không kết nối được tiện ích local. Nếu build đang chạy, chờ một chút rồi tải lại trang.';}
 button.disabled=false;});
</script></html>"""


def _json_bytes(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False).encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    server_version = "HHLLocalDemo/2"

    def log_message(self, _format: str, *args: object) -> None:
        # Default HTTP logs contain paths and client details; keep this local
        # helper quiet so no prompt, key, or user data reaches terminal/logs.
        return

    def _send(
        self,
        status: int,
        content_type: str,
        body: bytes,
        *,
        cors: bool = False,
    ) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Length", str(len(body)))
        if cors:
            origin = self.headers.get("Origin", "")
            if origin in ALLOWED_APP_ORIGINS:
                self.send_header("Access-Control-Allow-Origin", origin)
                self.send_header("Vary", "Origin")
        self.end_headers()
        self.wfile.write(body)

    def _is_local_host(self) -> bool:
        return self.headers.get("Host", "").split(":")[0] in LOCAL_HOSTS

    def _read_json(self, maximum: int = MAX_BODY_BYTES) -> dict:
        size = int(self.headers.get("Content-Length", "0"))
        if size < 2 or size > maximum:
            raise ValueError("invalid body length")
        payload = json.loads(self.rfile.read(size))
        if not isinstance(payload, dict):
            raise ValueError("object expected")
        return payload

    def do_GET(self) -> None:  # noqa: N802
        if not self._is_local_host():
            self._send(404, "text/plain; charset=utf-8", b"Not found")
        elif self.path == "/":
            self._send(200, "text/html; charset=utf-8", PAGE.encode("utf-8"))
        elif self.path == "/status":
            self._send(200, "application/json; charset=utf-8", _json_bytes({"ready": bool(GEMINI_API_KEY)}))
        else:
            self._send(404, "text/plain; charset=utf-8", b"Not found")

    def do_OPTIONS(self) -> None:  # noqa: N802
        if (
            not self._is_local_host()
            or self.path != f"/v1beta/models/{MODEL}:generateContent"
            or self.headers.get("Origin") not in ALLOWED_APP_ORIGINS
        ):
            self._send(403, "text/plain; charset=utf-8", b"Forbidden")
            return
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", self.headers["Origin"])
        self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Max-Age", "600")
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802
        if not self._is_local_host():
            self._send(404, "text/plain; charset=utf-8", b"Not found")
            return

        if self.path == "/activate":
            self._activate()
            return

        expected_path = f"/v1beta/models/{MODEL}:generateContent"
        origin = self.headers.get("Origin", "")
        if self.path != expected_path or (origin and origin not in ALLOWED_APP_ORIGINS):
            self._send(403, "application/json; charset=utf-8", _json_bytes({"error": {"status": "PERMISSION_DENIED", "message": "Origin or endpoint not allowed."}}), cors=bool(origin))
            return
        if not GEMINI_API_KEY:
            self._send(503, "application/json; charset=utf-8", _json_bytes({"error": {"status": "HHL_AI_NOT_CONFIGURED", "message": "Local demo key has not been configured."}}), cors=bool(origin))
            return
        try:
            payload = self._read_json()
        except (ValueError, json.JSONDecodeError):
            self._send(400, "application/json; charset=utf-8", _json_bytes({"error": {"status": "INVALID_ARGUMENT", "message": "Invalid request body."}}), cors=bool(origin))
            return

        request = Request(
            f"https://generativelanguage.googleapis.com{expected_path}",
            data=_json_bytes(payload),
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": GEMINI_API_KEY,
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=45) as response:
                body = response.read(MAX_BODY_BYTES + 1)
                status = response.status
        except HTTPError as error:
            status = error.code
            body = error.read(MAX_BODY_BYTES + 1)
        except (TimeoutError, URLError, OSError):
            status = 502
            body = _json_bytes({"error": {"status": "UNAVAILABLE", "message": "Could not reach Gemini. Check internet connection."}})

        if len(body) > MAX_BODY_BYTES:
            status = 502
            body = _json_bytes({"error": {"status": "RESOURCE_EXHAUSTED", "message": "Gemini response exceeded local limit."}})
        self._send(status, "application/json; charset=utf-8", body, cors=bool(origin))

    def _activate(self) -> None:
        global GEMINI_API_KEY
        if (
            self.headers.get("Origin") != f"http://127.0.0.1:{SETUP_PORT}"
            or self.headers.get("X-HHL-Local-Setup") != "1"
        ):
            self._send(403, "application/json; charset=utf-8", _json_bytes({"message": "Yêu cầu bị từ chối."}))
            return
        try:
            payload = self._read_json(maximum=8192)
        except (ValueError, json.JSONDecodeError):
            self._send(400, "application/json; charset=utf-8", _json_bytes({"message": "Yêu cầu không hợp lệ."}))
            return
        key = payload.get("apiKey", "")
        if not isinstance(key, str) or len(key.strip()) < 20 or len(key) > 512:
            self._send(400, "application/json; charset=utf-8", _json_bytes({"message": "Key không hợp lệ hoặc còn trống."}))
            return

        # Use only memory, and never include this value in process args/logs.
        GEMINI_API_KEY = key.strip()
        try:
            results = build_demo()
            message = "Đã giữ key trong RAM local; Web localhost:8083 và APK Android đã build. Hãy gửi tin nhắn trong app để xác nhận Google chấp nhận key."
            if results.get("android") is not True:
                message = "Web localhost:8083 đã build; APK Android build lỗi. Key vẫn chỉ ở RAM local. Xem .tmp/gemini_build.log."
            self._send(200, "application/json; charset=utf-8", _json_bytes({"message": message}))
        except Exception as error:
            # Build logs contain compiler output only. Do not log arbitrary
            # exception text, because this route handles secret-bearing input.
            try:
                LOG_DIR.mkdir(exist_ok=True)
                with open(LOG_FILE, "a", encoding="utf-8") as log:
                    log.write(f"\n[setup error] {type(error).__name__}: build failed\n")
            except OSError:
                pass
            self._send(500, "application/json; charset=utf-8", _json_bytes({"message": "Build lỗi. Kiểm tra .tmp/gemini_build.log; key vẫn chỉ được giữ trong bộ nhớ của tiện ích."}))


def stop_flutter_dev_server() -> None:
    build_dir = str(BUILD_DIR).replace("'", "''")
    script = r"""
$expectedBuild = '__EXPECTED_BUILD__'
$listeners = Get-NetTCPConnection -LocalPort 8083 -State Listen -ErrorAction SilentlyContinue
foreach ($listener in $listeners) {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)" -ErrorAction SilentlyContinue
  $isFlutterWeb = $p -and $p.CommandLine -match 'flutter_tools\.snapshot.*run.*web-port 8083'
  $servesExpectedBuild = $p -and ($p.CommandLine.Contains($expectedBuild) -or $p.CommandLine -match '--directory\s+build[\\/]web(?:\s|$)')
  $isHhlStaticServer = $p -and $p.Name -match '^python(w)?\.exe$' -and $p.CommandLine -match '-m http\.server 8083' -and $servesExpectedBuild
  if ($isFlutterWeb -or $isHhlStaticServer) { Stop-Process -Id $p.ProcessId -Force }
}
""".replace("__EXPECTED_BUILD__", build_dir)
    subprocess.run(["powershell.exe", "-NoProfile", "-Command", script], check=True, capture_output=True)
    deadline = time.time() + 12
    while time.time() < deadline:
        with socket.socket() as probe:
            if probe.connect_ex(("127.0.0.1", APP_PORT)) != 0:
                return
        time.sleep(0.25)
    raise RuntimeError("Cổng localhost:8083 vẫn đang được sử dụng.")


def start_static_server() -> None:
    LOG_DIR.mkdir(exist_ok=True)
    log = open(WEB_SERVER_LOG_FILE, "ab")
    flags = getattr(subprocess, "CREATE_NO_WINDOW", 0) | getattr(subprocess, "DETACHED_PROCESS", 0)
    subprocess.Popen(
        [sys.executable, "-m", "http.server", str(APP_PORT), "--bind", "127.0.0.1", "--directory", str(BUILD_DIR)],
        cwd=PROJECT,
        stdin=subprocess.DEVNULL,
        stdout=log,
        stderr=log,
        creationflags=flags,
    )
    log.close()
    deadline = time.time() + 10
    while time.time() < deadline:
        try:
            with urlopen(f"http://127.0.0.1:{APP_PORT}/", timeout=1) as response:
                if response.status == 200:
                    return
        except Exception:
            time.sleep(0.25)
    raise RuntimeError("Bản web đã build nhưng localhost:8083 chưa khởi động.")


def version_web_assets() -> None:
    version = str(time.time_ns())
    bootstrap_path = BUILD_DIR / "flutter_bootstrap.js"
    bootstrap = bootstrap_path.read_text(encoding="utf-8")
    bootstrap, count = re.subn(r'("mainJsPath"\s*:\s*)"main\.dart\.js(?:\?[^"]*)?"', lambda m: f'{m.group(1)}"main.dart.js?v={version}"', bootstrap, count=1)
    if count != 1:
        raise RuntimeError("Could not version the Flutter JS asset.")
    bootstrap_path.write_text(bootstrap, encoding="utf-8")
    index_path = BUILD_DIR / "index.html"
    index = index_path.read_text(encoding="utf-8")
    index, count = re.subn(r"bootstrap\.src = 'flutter_bootstrap\.js(?:\?[^']*)?';", f"bootstrap.src = 'flutter_bootstrap.js?v={version}';", index, count=1)
    if count != 1:
        raise RuntimeError("Could not version the Flutter bootstrap asset.")
    index_path.write_text(index, encoding="utf-8")


def _flutter_executable() -> str:
    flutter = shutil.which("flutter")
    if flutter:
        return flutter
    candidates = [
        Path.home() / "Downloads" / "flutter_windows_3.35.2-stable" / "flutter" / "bin" / "flutter.bat",
        Path(r"C:\src\flutter\bin\flutter.bat"),
    ]
    flutter = next((str(candidate) for candidate in candidates if candidate.is_file()), None)
    if not flutter:
        raise RuntimeError("Flutter SDK not found.")
    return flutter


def _run_build(command: list[str], *, append: bool = False) -> None:
    LOG_DIR.mkdir(exist_ok=True)
    mode = "a" if append else "w"
    with open(LOG_FILE, mode, encoding="utf-8") as log:
        result = subprocess.run(command, cwd=PROJECT, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode != 0:
        raise RuntimeError("Flutter build failed.")


def build_demo() -> dict[str, bool]:
    flutter = _flutter_executable()
    proxy_defines = [
        "--dart-define=AI_PROXY_WEB=http://127.0.0.1:8099",
        "--dart-define=AI_PROXY_ANDROID=http://10.0.2.2:8099",
    ]
    _run_build([
        flutter, "build", "web", *proxy_defines,
        "--base-href", "/", "--output", str(BUILD_DIR), "--pwa-strategy=none",
    ])
    version_web_assets()
    stop_flutter_dev_server()
    start_static_server()

    android_ok = False
    try:
        _run_build([flutter, "build", "apk", "--release", *proxy_defines], append=True)
        android_ok = APK_FILE.is_file()
    except Exception:
        # Keep the now-working Web demo served even if Android packaging fails.
        android_ok = False
    return {"web": True, "android": android_ok}


if __name__ == "__main__":
    print(f"Open http://127.0.0.1:{SETUP_PORT} to enable local Gemini.", flush=True)
    ThreadingHTTPServer(("127.0.0.1", SETUP_PORT), Handler).serve_forever()
