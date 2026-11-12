"""Рендер игры «Тактика»: static-сервер в потоке + headless Chrome (скриншот)."""

import functools
import http.server
import os
import socketserver
import subprocess
import threading
import urllib.request as ur

ROOT = r"e:\AI Projects\First\build\web"
SHOT = r"e:\AI Projects\First\preview_game.png"
PORT = 8093
BASE = "http://127.0.0.1:%d/" % PORT

os.chdir(ROOT)
Handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=ROOT)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


httpd = Server(("127.0.0.1", PORT), Handler)
threading.Thread(target=httpd.serve_forever, daemon=True).start()

for path in ("", "flutter_bootstrap.js", "flutter_build/build_config.json"):
    try:
        code = ur.urlopen(BASE + path, timeout=20).getcode()
    except Exception as exc:  # noqa: BLE001
        code = repr(exc)
    print("GET %-34s -> %s" % (path or "index.html", code))

chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if os.path.exists(SHOT):
    os.remove(SHOT)

cmd = [
    chrome,
    "--headless=new",
    "--disable-gpu",
    "--enable-unsafe-swiftshader",
    "--no-sandbox",
    "--hide-scrollbars",
    "--user-data-dir=E:\\dev\\chrome_shot",
    "--window-size=430,930",
    "--force-device-scale-factor=1",
    "--virtual-time-budget=90000",
    "--timeout=240000",
    "--screenshot=" + SHOT,
    BASE,
]
r = subprocess.run(cmd, capture_output=True, text=True, timeout=280, errors="replace")
print("chrome rc:", r.returncode)

httpd.shutdown()

keys = ("CONSOLE", "ERROR", "error", "net::", "Failed", "Uncaught")
lines = [ln for ln in (r.stderr or "").splitlines() if any(k in ln for k in keys)]
print("chrome log lines:", len(lines))
for ln in lines[:20]:
    print("  " + ln.strip()[:220])

if os.path.exists(SHOT):
    print("SHOT OK:", SHOT, os.path.getsize(SHOT), "bytes")
else:
    print("SHOT MISSING")
