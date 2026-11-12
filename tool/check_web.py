"""Проверка, что dev-сервер Flutter отдаёт приложение."""

import urllib.request

BASE = "http://127.0.0.1:8080/"
PATHS = [
    "",
    "flutter_bootstrap.js",
    "flutter.js",
    "main.dart.js",
    "assets/AssetManifest.bin.json",
    "assets/FontManifest.json",
    "manifest.json",
]

for p in PATHS:
    url = BASE + p
    try:
        with urllib.request.urlopen(url, timeout=40) as r:
            body = r.read()
        print(f"{r.status:>3}  {len(body):>10}  {p or '/'}")
    except Exception as exc:  # noqa: BLE001
        print(f"ERR  {'-' * 10}  {p or '/'}  {exc}")

with urllib.request.urlopen(BASE, timeout=40) as r:
    html = r.read().decode("utf-8", "replace")

print("\n--- checks ---")
print("has bootstrap script:", "flutter_bootstrap.js" in html)
print("has loading artefact:", "flutter-loader" in html or "loading" in html)
print("title:", [ln.strip() for ln in html.splitlines() if "<title>" in ln])
