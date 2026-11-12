"""Проверка, что превью — это нарисованная игра, а не пустой экран."""

import collections
import struct
import zlib

PATH = r"e:\AI Projects\First\preview_game.png"

with open(PATH, "rb") as fh:
    data = fh.read()

pos, idat, w, h, ctype = 8, b"", 0, 0, 0
while pos < len(data):
    (n,) = struct.unpack(">I", data[pos : pos + 4])
    typ, chunk = data[pos + 4 : pos + 8], data[pos + 8 : pos + 8 + n]
    if typ == b"IHDR":
        w, h, depth, ctype = struct.unpack(">IIBB", chunk[:10])
    elif typ == b"IDAT":
        idat += chunk
    elif typ == b"IEND":
        break
    pos += 12 + n

print("png:", w, "x", h, "colortype", ctype, "depth", depth)
raw = zlib.decompress(idat)
channels = {0: 1, 2: 3, 6: 4}[ctype]
bpp = channels
step = (w * bpp * (depth // 8)) + 1

prev = bytearray(w * bpp)
counts = collections.Counter()
rows = []
for y in range(h):
    line = bytearray(raw[y * step + 1 : (y + 1) * step])
    fb = raw[y * step]
    for i in range(len(line)):
        a = line[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        x = line[i]
        if fb == 1:
            line[i] = (x + a) & 255
        elif fb == 2:
            line[i] = (x + b) & 255
        elif fb == 3:
            line[i] = (x + ((a + b) >> 1)) & 255
        elif fb == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
            line[i] = (x + pred) & 255
    prev = line
    for x in range(w):
        col = tuple(line[x * bpp : x * bpp + 3 if bpp >= 3 else 1] * (1 if bpp >= 3 else 3))
        counts[col] += 1
    rows.append(sum(1 for x in range(w) if max(line[x * bpp : x * bpp + 3]) - min(line[x * bpp : x * bpp + 3]) > 60))

print("distinct colors:", len(counts))
for col, k in counts.most_common(8):
    print("  ", k, col)
sat = [(k, col) for col, k in counts.items() if max(col) - min(col) > 60 and k > 40]
sat.sort(reverse=True)
print("saturated colors:", len(sat))
for k, col in sat[:10]:
    print("  ", k, col)

band = 20
print("saturated px per 20px band:")
for i in range(0, h, band):
    print("  rows %4d-%4d: %d" % (i, min(i + band, h) - 1, sum(rows[i : i + band])))
