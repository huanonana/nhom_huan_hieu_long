"""Local-only masked Gemini key setup and HHL Stay web/Android builder."""

from __future__ import annotations

import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.request import urlopen


PROJECT = Path(__file__).resolve().parents[1]
BUILD_DIR = PROJECT / "build" / "web"
APK_FILE = PROJECT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
LOG_DIR = PROJECT / ".tmp"
LOG_FILE = LOG_DIR / "gemini_build.log"
SETUP_PORT = 8099
APP_PORT = 8083

PAGE = r"""<!doctype html>
<html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bật Gemini cho HHL Stay</title>
<style>
body{margin:0;background:#f5f7fb;color:#172033;font:16px system-ui,Segoe UI,sans-serif;display:grid;place-items:center;min-height:100vh}
main{box-sizing:border-box;width:min(560px,calc(100% - 32px));background:#fff;border:1px solid #dce3ef;border-radius:20px;padding:28px;box-shadow:0 16px 45px #14234b18}
h1{font-size:24px;margin:0 0 8px}p{color:#64748b;line-height:1.55}.hint{font-size:13px}
input{box-sizing:border-box;width:100%;height:48px;border:1px solid #cbd5e1;border-radius:12px;padding:0 14px;font:inherit;outline-color:#5648ee}
button{margin-top:14px;background:#5145e8;border:0;border-radius:12px;color:white;font:600 15px system-ui;padding:13px 18px;cursor:pointer}button:disabled{opacity:.6;cursor:wait}
#status{min-height:26px;margin-top:16px;font-weight:600}.safe{background:#f1f5ff;border-radius:12px;padding:12px;font-size:13px;color:#475569}
</style>
<main><h1>Bật Gemini cho HHL Stay</h1>
<p>Nhập API key trong ô được che rồi bấm nút. Key chỉ gửi đến tiện ích đang chạy trên máy này để build localhost:8083 và APK Android.</p>
<form id="form"><label for="key">Gemini API key</label><p><input id="key" type="password" autocomplete="off" spellcheck="false" required></p><button id="go">Build Web + Android và bật Gemini</button></form>
<div id="status" role="status"></div>
<div class="safe">Không gửi key vào chat. Key được nhúng vào bản Web và APK demo để gọi Gemini, nên chỉ dùng trong đồ án/local demo; không phát hành công khai.</div>
</main>
<script>
const form=document.querySelector('#form'), keyInput=document.querySelector('#key'), button=document.querySelector('#go'), statusBox=document.querySelector('#status');
form.addEventListener('submit',async event=>{event.preventDefault();const key=keyInput.value.trim();button.disabled=true;statusBox.textContent='Đang build, vui lòng đợi...';
 try{const response=await fetch('/build',{method:'POST',headers:{'Content-Type':'application/json','X-HHL-Local-Setup':'1'},body:JSON.stringify({apiKey:key})});const result=await response.json();statusBox.textContent=result.message;if(response.ok){keyInput.value='';}else{button.disabled=false;}}
 catch(_){statusBox.textContent='Không kết nối được tiện ích build trên máy này. Key vẫn được giữ trong ô để thử lại.';button.disabled=false;}});
</script></html>"""


class Handler(BaseHTTPRequestHandler):
    server_version = "HHLLocalSetup/1"

    def log_message(self, _format: str, *args: object) -> None:
        # Never log request bodies or key-related details.
        return

    def _send(self, status: int, content_type: str, body: bytes) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/" or self.headers.get("Host", "").split(":")[0] not in {"127.0.0.1", "localhost"}:
            self._send(404, "text/plain; charset=utf-8", b"Not found")
            return
        self._send(200, "text/html; charset=utf-8", PAGE.encode("utf-8"))

    def do_POST(self) -> None:  # noqa: N802
        if (
            self.path != "/build"
            or self.headers.get("Host", "").split(":")[0] not in {"127.0.0.1", "localhost"}
            or self.headers.get("Origin") != f"http://127.0.0.1:{SETUP_PORT}"
            or self.headers.get("X-HHL-Local-Setup") != "1"
        ):
            self._send(403, "application/json; charset=utf-8", '{"message":"Yêu cầu bị từ chối."}'.encode("utf-8"))
            return

        try:
            size = int(self.headers.get("Content-Length", "0"))
            if size < 2 or size > 8192:
                raise ValueError("empty")
            payload = json.loads(self.rfile.read(size))
            key = payload.get("apiKey", "")
            if not isinstance(key, str) or len(key.strip()) < 20 or len(key) > 512:
                self._send(400, "application/json; charset=utf-8", '{"message":"Key không hợp lệ hoặc còn trống."}'.encode("utf-8"))
                return
            message = build_with_key(key.strip())
            self._send(200, "application/json; charset=utf-8", json.dumps({"message": message}, ensure_ascii=False).encode("utf-8"))
        except Exception as exc:
            # Record diagnostics without ever writing the submitted key or request body.
            try:
                LOG_DIR.mkdir(exist_ok=True)
                with open(LOG_FILE, "a", encoding="utf-8") as log:
                    log.write(f"\n[setup error] {type(exc).__name__}: {exc}\n")
            except OSError:
                pass
            self._send(500, "application/json; charset=utf-8", '{"message":"Build lỗi. Kiểm tra .tmp/gemini_build.log."}'.encode("utf-8"))


def stop_flutter_dev_server() -> None:
    build_dir = str(BUILD_DIR).replace("'", "''")
    script = r"""
$expectedBuild = '__EXPECTED_BUILD__'
$listeners = Get-NetTCPConnection -LocalPort 8083 -State Listen -ErrorAction SilentlyContinue
foreach ($listener in $listeners) {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)" -ErrorAction SilentlyContinue
  $isFlutterWeb = $p -and $p.CommandLine -match 'flutter_tools\.snapshot.*run.*web-port 8083'
  $isHhlStaticServer = $p -and $p.Name -match '^python(w)?\.exe$' -and $p.CommandLine -match '-m http\.server 8083' -and $p.CommandLine.Contains($expectedBuild)
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
    log = open(LOG_FILE, "ab")
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
    """Bust browser caches when a fresh local demo build is installed."""
    version = str(time.time_ns())
    bootstrap_path = BUILD_DIR / "flutter_bootstrap.js"
    bootstrap = bootstrap_path.read_text(encoding="utf-8")
    bootstrap, bootstrap_count = re.subn(
        r'("mainJsPath"\s*:\s*)"main\.dart\.js(?:\?[^\"]*)?"',
        lambda match: f'{match.group(1)}"main.dart.js?v={version}"',
        bootstrap,
        count=1,
    )
    if bootstrap_count != 1:
        raise RuntimeError("Không thể cập nhật phiên bản cache của main.dart.js.")
    bootstrap_path.write_text(bootstrap, encoding="utf-8")

    index_path = BUILD_DIR / "index.html"
    index = index_path.read_text(encoding="utf-8")
    index, index_count = re.subn(
        r"bootstrap\.src = 'flutter_bootstrap\.js(?:\?[^']*)?';",
        f"bootstrap.src = 'flutter_bootstrap.js?v={version}';",
        index,
        count=1,
    )
    if index_count != 1:
        raise RuntimeError("Không thể cập nhật phiên bản cache của Flutter bootstrap.")
    index_path.write_text(index, encoding="utf-8")


def build_with_key(key: str) -> str:
    LOG_DIR.mkdir(exist_ok=True)
    flutter = shutil.which("flutter")
    if not flutter:
        # The helper can be launched from a hidden process with a stale PATH.
        candidates = [
            Path.home() / "Downloads" / "flutter_windows_3.35.2-stable" / "flutter" / "bin" / "flutter.bat",
            Path(r"C:\src\flutter\bin\flutter.bat"),
        ]
        flutter = next((str(candidate) for candidate in candidates if candidate.is_file()), None)
    if not flutter:
        raise RuntimeError("Không tìm thấy Flutter SDK trong PATH hoặc vị trí cài đặt phổ biến.")
    # Keep the short-lived define file on the project drive, which may differ
    # from the Windows system temp drive. It is always removed after both builds.
    fd, define_path = tempfile.mkstemp(prefix="hhl-gemini-", suffix=".json", dir=PROJECT / ".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as define_file:
            json.dump({"GEMINI_API_KEY": key}, define_file)
        web_command = [
            flutter, "build", "web", f"--dart-define-from-file={define_path}",
            "--base-href", "/", "--output", str(BUILD_DIR), "--pwa-strategy=none",
        ]
        with open(LOG_FILE, "w", encoding="utf-8") as log:
            result = subprocess.run(web_command, cwd=PROJECT, stdout=log, stderr=subprocess.STDOUT)
        if result.returncode != 0:
            raise RuntimeError("Flutter build web thất bại.")

        apk_command = [
            flutter, "build", "apk", "--release", f"--dart-define-from-file={define_path}",
        ]
        with open(LOG_FILE, "a", encoding="utf-8") as log:
            result = subprocess.run(apk_command, cwd=PROJECT, stdout=log, stderr=subprocess.STDOUT)
        if result.returncode != 0 or not APK_FILE.is_file():
            raise RuntimeError("Flutter build Android APK thất bại.")
    finally:
        try:
            os.remove(define_path)
        except FileNotFoundError:
            pass

    version_web_assets()
    stop_flutter_dev_server()
    start_static_server()
    return "Build xong cả Web và Android APK. Bản Web đang chạy ở localhost:8083; APK ở build/app/outputs/flutter-apk/app-release.apk."


if __name__ == "__main__":
    print(f"Open http://127.0.0.1:{SETUP_PORT} to enter the key securely.", flush=True)
    HTTPServer(("127.0.0.1", SETUP_PORT), Handler).serve_forever()
