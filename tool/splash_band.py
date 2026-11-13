"""Профили плотности содержимого в постере, чтобы найти поле как связный участок.

Показывает по строкам и столбцам число пикселей, отличающихся от фона, внутри
горизонтальной полосы. Нужен один запуск: tool/splash_band.py [y0 y1].
"""

import sys

from PIL import Image

SRC = "assets/splash/splash.png"
BG = (0, 10, 68)  # модальный фон полосы, снят tool/splash_android12.py
DIFF = 45


def main() -> None:
    y0, y1 = (int(a) for a in sys.argv[1:3]) if len(sys.argv) > 2 else (300, 940)
    im = Image.open(SRC).convert("RGB")
    w, h = im.size
    px = im.load()

    def differs(x: int, y: int) -> bool:
        p = px[x, y]
        return abs(p[0] - BG[0]) + abs(p[1] - BG[1]) + abs(p[2] - BG[2]) > DIFF

    rows = [(y, sum(1 for x in range(0, w, 4) if differs(x, y))) for y in range(0, h, 20)]
    print("ROWS y=count (step 20):")
    print(", ".join(f"{y}:{c}" for y, c in rows if c > 0))

    cols = [(x, sum(1 for y in range(y0, y1, 4) if differs(x, y))) for x in range(0, w, 8)]
    print(f"COLS x=count inside y {y0}..{y1} (step 8):")
    print(", ".join(f"{x}:{c}" for x, c in cols if c > 0))


if __name__ == "__main__":
    main()
