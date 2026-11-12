import json

d = json.load(open(r"E:\dev\rel.json", encoding="utf-8"))
h = d["current_release"]["stable"]
for r in d["releases"]:
    if r["hash"] == h:
        print("VERSION=" + r["version"])
        print("URL=" + d["base_url"] + "/" + r["archive"])
        break
