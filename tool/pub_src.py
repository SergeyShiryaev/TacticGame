"""Печатает фрагменты исходников flutter_native_splash из pub-кэша для разбора."""

import re
import sys

LIB = r"C:\Users\serge\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_native_splash-2.4.7\lib"


def main() -> None:
    name, pattern = sys.argv[1], sys.argv[2]
    context = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    text = open(f"{LIB}\\{name}", encoding="utf-8", errors="replace").read()
    if context:
        for m in re.finditer(pattern, text):
            print("---", name, m.start())
            print(text[max(0, m.start() - context) : m.end() + context])
    else:
        for i, line in enumerate(text.splitlines(), 1):
            if re.search(pattern, line):
                print(i, "|", line.rstrip())


if __name__ == "__main__":
    main()
