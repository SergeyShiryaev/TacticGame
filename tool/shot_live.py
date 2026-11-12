"""Скриншот + попиксельная проверка ЖИВОЙ игры на 127.0.0.1:8090 (dev-сервер flutter run).

Смысл: dev-сервер живёт вне моего дерева процессов, поэтому снимаю реальный
рендер и разбираю PNG вручную (фильтры Паста), не полагаясь на PIL.
"""

import collections
import struct
import subprocess
import sys
import zlib

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
OUT = r"e:\AI Projects\First\preview_live.png"
URL = "http://127.0.0.1:8090/"


def shoot() -> None:
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        f"--window-size=430,930",
        "--virtual-time-budget=25000",
        f"--screenshot={OUT}",
        URL,
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    print("chrome rc", res.returncode, (res.stderr or "")[-300:])


def analyse(path: str) -> None:
    with open(path, "rb") as fh:
        data = fh.read()
    print("file bytes:", len(data))
    pos, w, h, ct, depth, idat = 8, 0, 0, 0, 0, b""
    while pos < len(data):
        (ln,) = struct.unpack(">I", data[pos : pos + 4])
        typ = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + ln]
        if typ == b"IHDR":
            w, h, depth, ct = struct.unpack(">IIBB", chunk[:10])
        elif typ == b"IDAT":
            idat += chunk
        elif typ == b"IEND":
            break
        pos += 12 + ln
    print(f"png: {w} x {h} colortype={ct} depth={depth}")
    if (w, h, ct, depth) != (430, 930, 2, 8):
        print("!! unexpected format")
        return
    raw = zlib.decompress(idat)
    bpp, stride = 3, w * 3
    prev = bytearray(stride)
    colors = collections.Counter()
    sat_rows = collections.Counter()
    off = 0
    for y in range(h):
        f = raw[off]
        off += 1
        line = bytearray(raw[off : off + stride])
        off += stride
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            x = i - bpp if i >= bpp else i
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
            col = (line[x], line[x + 1], line[x + 2]) if x + 2 <= i + 2 else (0, 0, 0)
        for i in range(0, stride, 3):
            r, g, bl = line[i], line[i + 1], line[i + 2]
            colors[(r, g, bl)] += 1
            mx, mn = max(r, g, bl), min(r, g, bl)
            if mx > 60 and mx - mn > 25:
                sat_rows[y // 10] += 1
        prev = line
    print("distinct colors:", len(colors))
    for col, cnt in colors.most_common(6):
        print(f"   {cnt:>7} {col}")
    print("rows(y//10): saturated pixels")
    print("   top:", ", ".join(str(y) for y, _ in sat_rows.most_common(12)))
    print("   0-29 :", [sat_rows.get(y, 0) for y in range(30)])
    print("   26-71:", sum(sat_rows.get(y, 0) for y in range(26, 72)))
    print("   72-92:", [sat_rows.get(y, 0) for y in range(72, 93)])


if __name__ == "__main__":
    if "--no-shot" not in sys.argv:
        shoot()
    analyse(OUT)
