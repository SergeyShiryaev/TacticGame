"""Замеры готовых иконок и постера: размеры, режим, цвета углов и центра.

Запуск: python tool/img_info.py [путь ...]
"""

import sys

from PIL import Image

DEFAULTS = [
    "assets/splash/splash.png",
    "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    "android/app/src/main/res/drawable-xxhdpi/splash.png",
    "assets/splash/splash_android12.png",
]


def main() -> None:
    for path in (sys.argv[1:] or DEFAULTS):
        try:
            im = Image.open(path)
        except OSError as exc:
            print(f"{path}: {exc}")
            continue
        px = im.convert("RGBA").load()
        w, h = im.size
        print(f"{im.mode} {w:>5}x{h:<5} corner={px[0, 0]} center={px[w // 2, h // 2]}  {path}")


if __name__ == "__main__":
    main()
