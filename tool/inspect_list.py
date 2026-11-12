import collections
names = open(r"E:\dev\list.txt", encoding="utf-8", errors="ignore").read().splitlines()
pats = ["artifacts/engine/web", "flutter_web_sdk", "font-subset", "material_fonts",
        "artifacts/engine/windows-x64/", "artifacts/engine/common",
        "cache/pkg", "sky_engine", "flutter_tools.snapshot", "bin/cache/dart-sdk/bin/",
        "bin/cache/flutter.version.json", "bin/internal", "release-candidate"]
for p in pats:
    hits = [n for n in names if p in n]
    print(f"{p:45} {len(hits):5}")
print("\nengine top dirs:")
tops = collections.Counter()
for n in names:
    if n.startswith("flutter/bin/cache/artifacts/engine/"):
        tops[n.split("/")[5] if len(n.split("/")) > 5 else "(files)"] += 1
for k, v in tops.items():
    print(f"  {k}: {v}")
print("\nall artifacts top:", sorted({n.split('/')[4] for n in names if n.startswith('flutter/bin/cache/artifacts/')}))
print("web engine files:", [n for n in names if "web" in n and "engine" in n][:8])
