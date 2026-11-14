"""Ikony unikalnych kamieni umiejętności (Gems.UNIQUE): ikony kamieni wsparcia z Watry (`../Watra/assets/items/supports/`)
przebarwione na złoto, z jasnozłotą otoczką 1 px za czarnym konturem - żeby odróżniały się od zwykłych kamieni.
Wynik: assets/watra/unique_gems/<umiejętność>.png. Użycie: python tools/unique_gem_art.py [ścieżka do Watry]
"""
import colorsys
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WATRA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Watra"
# umiejętność -> ikona z Watry (symbol pasuje do działania kamienia)
SOURCES = {"strike": "fury", "whirl": "momentum", "throw": "chain", "slam": "herald", "blink": "storm_edge",
           "g_thrust": "split", "g_sweep": "ember", "g_trail": "echo", "g_pillar": "area", "g_dance": "discharge"}
HUE = 42 / 360.0  # złoto
# ikony z prawie bezbarwnym kamieniem (szary) - złocone po jasności, nie po nasyceniu
FORCE = {"g_thrust"}
GLOW = (255, 214, 110, 255)


def gold(im: Image.Image, force: bool = False) -> Image.Image:
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > 0.18 or (force and 0.12 < v < 0.8):  # kamień - na złoto; biały symbol i czarny kontur zostają
                r2, g2, b2 = colorsys.hsv_to_rgb(HUE, min(1.0, max(s * 1.15 + 0.15, 0.7 if force else 0.0)), min(1.0, v * 1.1))
                px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    # otoczka: przezroczyste piksele przy nieprzezroczystych
    src = out.copy().load()
    for y in range(out.height):
        for x in range(out.width):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < out.width and 0 <= ny < out.height and src[nx, ny][3] != 0:
                    px[x, y] = GLOW
                    break
    return out


def main() -> None:
    dst = ROOT / "assets/watra/unique_gems"
    dst.mkdir(parents=True, exist_ok=True)
    for skill, name in SOURCES.items():
        im = Image.open(WATRA / "assets/items/supports" / f"{name}.png").convert("RGBA")
        gold(im, skill in FORCE).save(dst / f"{skill}.png")
        print(skill, "<-", name)


if __name__ == "__main__":
    main()
