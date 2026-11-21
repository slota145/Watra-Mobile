"""Ikony trzecich baz przedmiotów (Items.BASES): przebarwione linie przedmiotów z Watry (assets/watra/items/),
bo Watra nie ma trzeciej linii dla każdego miejsca. Każdy plik linii (5 stopni, wersje zwykła/_magic/_rare) dostaje
nowy odcień w kolorowych pikselach (szare i ciemne kontury zostają). Wynik: assets/items/<baza>_t<1-5>[_magic|_rare].png.
Użycie: python tools/item_bases_art.py
"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/watra/items"
OUT = ROOT / "assets/items"
# baza -> (pliki linii źródłowej na stopnie 1-5, odcień docelowy 0-1, mnożnik nasycenia)
RECOLORS = {
    "tooth": (["fang_earring", "fang_t2", "fang_t3", "fang_t4", "fang_t5"], 0.0, 1.2),  # czerwonawy ząb
    "horned": (["iron_helmet", "helm_t2", "helm_t3", "helm_t4", "helm_t5"], 0.08, 1.3),  # brązowo-miedziany
    "bast": (["leather_boots", "boots_t2", "boots_t3", "boots_t4", "boots_t5"], 0.25, 1.1),  # łyko - zielonkawe
    "gold": (["copper_ring", "band_t2", "band_t3", "band_t4", "band_t5"], 0.13, 1.4),  # złoto
    "runic": (["amber_necklace", "amulet_t2", "amulet_t3", "amulet_t4", "amulet_t5"], 0.75, 1.2),  # fiolet
}


def recolor(im: Image.Image, hue: float, sat: float) -> Image.Image:
    out = im.convert("RGBA").copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.12 or v < 0.15:  # kontury i stal zostają
                continue
            rr, gg, bb = colorsys.hsv_to_rgb(hue, min(1.0, s * sat), v)
            px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for base, (files, hue, sat) in RECOLORS.items():
        for i, name in enumerate(files):
            for suffix in ("", "_magic", "_rare"):
                src = SRC / f"{name}{suffix}.png"
                recolor(Image.open(src), hue, sat).save(OUT / f"{base}_t{i + 1}{suffix}.png")
        print(base, "<-", files[0])


if __name__ == "__main__":
    main()
