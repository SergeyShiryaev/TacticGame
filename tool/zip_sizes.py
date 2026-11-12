import zipfile, collections

z = zipfile.ZipFile(r"E:\dev\flutter.zip")
tot = collections.defaultdict(int)
cnt = collections.Counter()
for i in z.infolist():
    if i.is_dir():
        continue
    parts = i.filename.split("/")
    key = "/".join(parts[:3]) if len(parts) >= 3 else i.filename
    tot[key] += i.file_size
    cnt[key] += 1

for k, v in sorted(tot.items(), key=lambda kv: -kv[1])[:14]:
    print(f"{v/1e6:9.1f} MB  {cnt[k]:6}  {k}")
