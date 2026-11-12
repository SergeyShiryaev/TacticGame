import zipfile, collections

z = zipfile.ZipFile(r"E:\dev\flutter.zip")
tot = collections.defaultdict(int)
cnt = collections.Counter()
for i in z.infolist():
    if i.is_dir():
        continue
    p = i.filename
    if not p.startswith("flutter/bin/cache/"):
        continue
    parts = p.split("/")
    key = "/".join(parts[:4]) if len(parts) >= 4 else p
    tot[key] += i.file_size
    cnt[key] += 1

for k, v in sorted(tot.items(), key=lambda kv: -kv[1]):
    print(f"{v/1e6:9.1f} MB  {cnt[k]:6}  {k}")

print("--- engine subfolders ---")
eng = collections.defaultdict(int)
for i in z.infolist():
    if i.is_dir():
        continue
    p = i.filename
    if not p.startswith("flutter/bin/cache/artifacts/engine/"):
        continue
    parts = p.split("/")
    key = parts[5] if len(parts) > 5 else "(root files)"
    eng[key] += i.file_size
for k, v in sorted(eng.items(), key=lambda kv: -kv[1]):
    print(f"{v/1e6:9.1f} MB  {k}")
