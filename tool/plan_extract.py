import collections, json, os, zipfile

z = zipfile.ZipFile(r"E:\dev\flutter.zip")
need = {}
for i in z.infolist():
    if i.is_dir():
        continue
    need[i.filename] = i.file_size

groups = collections.defaultdict(int)
for name, size in need.items():
    p = name.split("/")
    key = "/".join(p[:3]) if len(p) >= 3 else name
    groups[key] += size

print("=== top-3 groups (MB) ===")
for k, v in sorted(groups.items(), key=lambda kv: -kv[1]):
    if v > 3e6:
        print(f"{v/1e6:9.1f}  {k}")

print("\n=== dart-sdk subgroups ===")
d = collections.defaultdict(int)
for name, size in need.items():
    if name.startswith("flutter/bin/cache/dart-sdk/"):
        p = name.split("/")
        d["/".join(p[:4])] += size
for k, v in sorted(d.items(), key=lambda kv: -kv[1]):
    print(f"{v/1e6:9.1f}  {k}")

print("\n=== what is already on disk (vs zip) ===")
ok = missing = partial = 0
for name, size in need.items():
    path = os.path.join(r"E:\dev", name.replace("/", "\\"))
    if os.path.exists(path):
        try:
            if os.path.getsize(path) == size:
                ok += 1
            else:
                partial += 1
        except OSError:
            missing += 1
    else:
        missing += 1
print(f"ok={ok} partial={partial} missing={missing} total={len(need)}")

tot = 0
cnt = 0
for name, size in need.items():
    path = os.path.join(r"E:\dev", name.replace("/", "\\"))
    if not (os.path.exists(path) and os.path.getsize(path) == size):
        tot += size
        cnt += 1
print(f"still_to_extract={tot/1e6:.0f} MB in {cnt} files")
