"""Разбор постера заставки: где именно нарисована доска, чтобы безопасно
скроить квадратную версию для system splash на Android 12+ (windowSplashScreenAnimatedIcon).

Запуск:  python tool/splash_probe.py [путь к png]
"""

import sys

from PIL import Image

PATH = sys.argv[1] if len(sys.argv) > 1 else r"assets/splash/splash.png"
STEP = 6  # шаг сэмплирования при поиске границ содержимого

im = Image.open(PATH).convert("RGBA")
w, h = im.size
px = im.load()
bg = px[0, 0]
print(f"src: {w}x{h}  corner/bg = {tuple(bg)}  fully_transparent_corner={bg[3] == 0}")


def diff(x: int, y: int) -> int:
    p = px[x, y]
    if p[3] < 8:
        return 255  # прозрачный пиксель считаем содержимым, если фон непрозрачен
    return abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2])


THRESH = 45
xs = [x for x in range(w) for y in range(0, h, STEP) if diff(x, y) > THRESH]
ys = [y for y in range(h) for x in range(0, w, STEP) if diff(x, y) > THRESH]
if not (xs and ys):
    sys.exit("contents not found: poster is flat")
box = (min(xs), min(ys), max(xs), max(ys))
print(f"content bbox vs corner: {box}  size={box[2] - box[0] + 1}x{box[3] - box[1] + 1}")
print(f"content center: {(box[0] + box[2]) / 2:.0f}, {(box[1] + box[3]) / 2:.0f}  (poster center = {w / 2:.0f}, {h / 2:.0f})")

# ASCII-карта яркости: сразу видно, где поле, где надпись, где пустой фон.
cols, rows = 60, 40
print(f"\nbrightness map ({cols}x{rows}), '#' = bright, '.' = dark:")
ramp = " .:-=+*#%@"
for r in range(rows):
    line = []
    for c in range(cols):
        x0, x1 = w * c // cols, w * (c + 1) // cols
        y0, y1 = h * r // rows, h * (r + 1) // rows
        n = 0
        tot = 0
        for y in range(y0, max(y1, y0 + 1), 4):
            for x in range(x0, max(x1, x0 + 1), 4):
                p = px[x, y]
                tot += (p[0] + p[1] + p[2]) / 3
                n += 1
        line.append(ramp[min(int(tot / max(n, 1)) * len(ramp) // 256, len(ramp) - 1)])
    print("".join(line))

# Насколько постер шире/выше квадрата по содержимому — нужно ли растягивать фон.
cw, ch = box[2] - box[0] + 1, box[3] - box[1] + 1
print(f"\ncontent ratio w/h = {cw / ch:.2f};  poster ratio w/h = {w / h:.2f}")
print(f"needed padding to square around content: {max(ch - cw, 0)}px horizontally")
