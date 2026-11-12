"""Живая проверка игры на http://127.0.0.1:8090 (сервер запущен вне моего дерева процессов)."""

import subprocess
import urllib.request as ur

BASE = "http://127.0.0.1:8090"
PATHS = [
    "/",
    "/flutter_bootstrap.js",
    "/flutter.js",
    "/main.dart.js",
    "/assets/AssetManifest.bin.json",
    "/assets/FontManifest.json",
    "/assets/assets/.keep",
    "/manifest.json",
]

for p in PATHS:
    try:
        with ur.urlopen(BASE + p, timeout=20) as r:
            print(f"{p:38} -> {r.status} len={r.headers.get('Content-Length')}")
    except Exception as exc:  # noqa: BLE001
        print(f"{p:38} -> ERR {exc}")

task = subprocess.run(
    'tasklist /FI "WINDOWTITLE eq Тактика*" /FO CSV',
    shell=True,
    capture_output=True,
    text=True,
)
print("chrome-window-tasklist:", task.stdout.strip().replace("\r", " ") or "<none>")

proc = subprocess.run(
    "tasklist /FI \"IMAGENAME eq chrome.exe\" /FO CSV",
    shell=True,
    capture_output=True,
    text=True,
)
print("chrome.exe count:", proc.stdout.count("chrome.exe"))

srv = subprocess.run(
    "netstat -ano | findstr :8090", shell=True, capture_output=True, text=True
)
print("port 8090:", srv.stdout.strip().replace("\r", "\n") or "<not listening>")
