"""Разбор постера по яркости: фишки и лунки светлые, фон тёмный градиент.

Даёт сегменты светлых полос, самые крупные связные светлые блоки (самый
большой = «доска») и ASCII-карту яркости.

Запуск: python tool/splash_layout.py [путь_к_постеру] [порог_яркости]
"""

import sys
from collections import deque

from PIL import Image

PATH = sys.argv[1] if len(sys.argv) > 1 else "assets/splash/splash.png"
LUMA_MIN = int(sys.argv[2]) if len(sys.argv) > 2 else 120

im = Image.open(PATH).convert("RGB")
w, h = im.size
px = im.load()
print(f"image={PATH} size={w}x{h} luma_min={LUMA_MIN}")

STEP = 8
small_w = w // STEP
small_h = h // STEP
grid = [[False] * small_w for _ in range(small_h)]
for gy in range(small_h):
    y = gy * STEP
    for gx in range(small_w):
        x = gx * STEP
        p = px[x, y]
        grid[gy][gx] = (p[0] + p[1] + p[2]) / 3 >= LUMA_MIN

counts = [sum(row) for row in grid]
print("bright bands (y-range, x-range):")
runs = []
start = None
gap = 0
for gy, c in enumerate(counts):
    if c > 0:
        if start is None:
            start = gy
        gap = 0
    elif start is not None:
        gap += 1
        if gap >= 3:
            runs.append((start, gy - gap))
            start = None
            gap = 0
if start is not None:
    runs.append((start, small_h - 1))
for a, b in runs:
    xs = [gx for gx in range(small_w) if any(grid[gy][gx] for gy in range(a, b + 1))]
    if not xs:
        continue
    print(
        f"  y {a * STEP:5d}-{(b + 1) * STEP - 1:5d}   x "
        f"{min(xs) * STEP:5d}-{(max(xs) + 1) * STEP - 1:5d}"
    )

seen = [[False] * small_w for _ in range(small_h)]
comps = []
for gy in range(small_h):
    for gx in range(small_w):
        if not grid[gy][gx] or seen[gy][gx]:
            continue
        q = deque([(gx, gy)])
        seen[gy][gx] = True
        cells = []
        while q:
            cx, cy = q.popleft()
            cells.append((cx, cy))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < small_w and 0 <= ny < small_h:
                        if grid[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            q.append((nx, ny))
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]
        comps.append(
            (
                len(cells),
                min(xs) * STEP,
                min(ys) * STEP,
                (max(xs) + 1) * STEP - 1,
                (max(ys) + 1) * STEP - 1,
            )
        )

comps.sort(reverse=True)
print("top components: cells, x0 y0 - x1 y1, w x h")
for c in comps[:8]:
    n, x0, y0, x1, y1 = c
    print(f"  {n:6d}  {x0:5d},{y0:5d} - {x1:5d},{y1:5d}   {x1 - x0 + 1}x{y1 - y0 + 1}")

cols, rows = 70, 40
ramp = " .:-=+*#%@"
print(f"\nbrightness map ({cols}x{rows}):")
for r in range(rows):
    line = []
    for c in range(cols):
        x0 = w * c // cols
        x1 = max(w * (c + 1) // cols, x0 + 1)
        y0 = h * r // rows
        y1 = max(h * (r + 1) // rows, y0 + 1)
        tot = 0
        n = 0
        for y in range(y0, y1, 6):
            for x in range(x0, x1, 6):
                p = px[x, y]
                tot += (p[0] + p[1] + p[2]) / 3
                n += 1
        line.append(ramp[min(int(tot / max(n, 1)) * len(ramp) // 256, len(ramp) - 1)])
    print("".join(line))
