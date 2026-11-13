"""Готовит квадратный арт для system splash на Android 12+ (windowSplashScreenAnimatedIcon).

Постер assets/splash/splash.png (1048x1501) в system splash не годится: на API 31+
картинка кадрируется системой в круг, а подпись «ТАКТИКА» внизу всё равно нечитаема.

Поле ищется по яркости (фишки и лунки светлые, фон тёмный; замеры — tool/splash_layout.py:
bbox x 176..879, y 344..903). Берётся КВАДРАТНЫЙ кроп постера вокруг центра поля, поэтому
локальный градиент фона сохраняется без подделок. Кромка квадрата плавно растворяется в
сплошной цвет, который и подставляется в windowSplashScreenBackground /
windowSplashScreenIconBackground — шва между иконкой и фоном системы не видно при любой
форме маски. Заодно печатает HEX этих цветов для pubspec.yaml.

Запуск:  python tool/splash_android12.py [--size 1024]
"""

import argparse
import math
from pathlib import Path

from PIL import Image, ImageEnhance

SRC = Path("assets/splash/splash.png")
OUT_LIGHT = Path("assets/splash/splash_android12.png")
OUT_DARK = Path("assets/splash/splash_android12_dark.png")

# Диапазон поиска поля (доля от высоты): поле лежит в y 344..903, подпись — ниже y~1150.
BAND_TOP = 0.18
BAND_BOTTOM = 0.68
# Порог яркости (среднее по RGB), выше которого пиксель = фишка или лунка.
LUMA_MIN = 120
# Запас под маску: сторона квадрата = большая сторона поля / BOARD_FILL.
BOARD_FILL = 0.68
# Кромка: растворение начинается от этой доли половины стороны и кончается у той.
FEATHER_FROM = 0.62
FEATHER_TO = 0.99
# Множитель яркости тёмного варианта.
DARK_FACTOR = 0.42


def board_bbox(px, w: int, h: int) -> tuple[int, int, int, int]:
    """Прямоугольник поля по светлым пикселям внутри полосы поиска."""
    y0, y1 = int(h * BAND_TOP), int(h * BAND_BOTTOM)

    def bright(x: int, y: int) -> bool:
        p = px[x, y]
        return (p[0] + p[1] + p[2]) / 3 >= LUMA_MIN

    xs = [x for x in range(w) if any(bright(x, y) for y in range(y0, y1, 3))]
    ys = [y for y in range(y0, y1) if any(bright(x, y) for x in range(0, w, 3))]
    if not xs or not ys:
        raise SystemExit("поле не найдено: полоса однотонная")
    return min(xs), min(ys), max(xs), max(ys)


def rim_color(px, cx: float, cy: float, radius: float, w: int, h: int):
    """Средний цвет по окружности: это и есть фон вокруг поля."""
    acc = [0, 0, 0]
    n = 0
    ang = 0.0
    while ang < 360.0:
        a = math.radians(ang)
        x = min(max(int(round(cx + radius * math.cos(a))), 0), w - 1)
        y = min(max(int(round(cy + radius * math.sin(a))), 0), h - 1)
        p = px[x, y]
        for i in range(3):
            acc[i] += p[i]
        n += 1
        ang += 2.0
    return tuple(round(v / n) for v in acc)


def feather(square: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    """Растворяет кромку квадрата в сплошной цвет плавным (smoothstep^2) градиентом."""
    side = square.width
    c = side / 2
    r_in = c * FEATHER_FROM
    r_out = c * FEATHER_TO
    solid = Image.new("RGB", (side, side), bg)
    mask = Image.new("L", (side, side))
    mp = mask.load()
    for y in range(side):
        dy = y - c + 0.5
        for x in range(side):
            dx = x - c + 0.5
            r = math.hypot(dx, dy)
            if r <= r_in:
                mp[x, y] = 255
            elif r >= r_out:
                mp[x, y] = 0
            else:
                t = (r - r_in) / (r_out - r_in)
                mp[x, y] = round(255 * (1 - t) * (1 - t))
    return Image.composite(square, solid, mask)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--in", dest="src", type=Path, default=SRC)
    ap.add_argument("--size", type=int, default=1024, help="сторона итогового квадрата")
    args = ap.parse_args()

    src = Image.open(args.src).convert("RGB")
    w, h = src.size
    px = src.load()
    bx0, by0, bx1, by1 = board_bbox(px, w, h)
    bw, bh = bx1 - bx0 + 1, by1 - by0 + 1
    cx, cy = (bx0 + bx1) / 2, (by0 + by1) / 2

    side_src = round(max(bw, bh) / BOARD_FILL)
    # Кроп не должен вылезать за постер и не должен цепать подпись под полем.
    side_src = min(side_src, w, h)
    half = side_src / 2
    cx = min(max(cx, half), w - half)
    cy = min(max(cy, half), h - half)
    crop = src.crop(
        (
            int(round(cx - half)),
            int(round(cy - half)),
            int(round(cx + half)),
            int(round(cy + half)),
        )
    )
    square = crop.resize((args.size, args.size), Image.LANCZOS)
    sp = square.load()
    bg = rim_color(sp, args.size / 2, args.size / 2, args.size / 2 * FEATHER_TO, args.size, args.size)
    light = feather(square, bg)
    dark_px = ImageEnhance.Brightness(light).enhance(DARK_FACTOR)
    dark = dark_px

    light.save(OUT_LIGHT)
    dark.save(OUT_DARK)

    def hex_of(t):
        return "#{:02x}{:02x}{:02x}".format(*t)

    dark_bg = tuple(round(v * DARK_FACTOR) for v in bg)
    print(f"board bbox      : x {bx0}-{bx1}  y {by0}-{by1}   {bw}x{bh}")
    print(f"crop square     : side {side_src}px -> {args.size}px  center ({cx:.0f},{cy:.0f})")
    print(f"light bg {hex_of(bg)}  -> {OUT_LIGHT}  {light.size} {light.mode}")
    print(f"dark  bg {hex_of(dark_bg)}  -> {OUT_DARK}  {dark.size} {dark.mode}")
    print("pubspec:")
    print(f"  color: \"{hex_of(bg)}\"")
    print(f"  color_dark: \"{hex_of(dark_bg)}\"")


if __name__ == "__main__":
    main()
