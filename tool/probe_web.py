"""Диагностика рендера: где CanvasKit и что пишет Chrome."""

import glob
import re
import subprocess
import urllib.request as ur

BASE = "http://127.0.0.1:8080/"

boot = ur.urlopen(BASE + "flutter_bootstrap.js", timeout=30).read().decode()
urls = re.findall(r"['\"]([^'\"]*(?:canvaskit|wasm|\.js)[^'\"]*)['\"]", boot)
print("bootstrap refs:", sorted(set(urls))[:12])
print("needs internet:", ("http" in "".join(urls) and "127.0.0.1" not in "".join(u for u in urls if u.startswith("http"))))

for pat in [
    r"e:\AI Projects\First\build\web\canvaskit\*",
    r"E:\dev\flutter\bin\cache\artifacts\engine\**\canvaskit\*.wasm",
]:
    hits = glob.glob(pat, recursive=True)
    print(f"{pat}\n   -> {len(hits)}:", [h.split('canvaskit')[-1] for h in hits][:8])

chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
cmd = [
    chrome, "--headless=new", "--disable-gpu", "--enable-unsafe-swiftshader",
    f"--user-data-dir=E:\\dev\\chrome3", "--enable-logging=stderr", "--v=1",
    "--virtual-time-budget=45000", "--timeout=120000", "--dump-dom", BASE,
]
try:
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=170, errors="replace")
    dom, err = r.stdout, r.stderr
except subprocess.TimeoutExpired:
    dom, err = "", "TIMEOUT"

print("dom len:", len(dom))
for m in ["flt-glass-pane", "flt-scene-host", "canvas", "canvaskit", "flutter-view"]:
    print(f"  mark {m}: {dom.count(m)}")
keys = ("CONSOLE", "ERROR", "canvaskit", "wasm", "net::", "Failed")
lines = [l for l in err.splitlines() if any(k in l for k in keys)]
print("chrome log (%d lines):" % len(lines))
for l in lines[:15]:
    print("  ", l[:190])
