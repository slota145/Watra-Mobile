"""Animowane efekty z kreatora efektów PixelLab (vfx_workbench) -> arkusze do gry.

Dane efektów: pixellab_src/vfx/ids.json, np.
  "ciecie_miecza": {"effect": "<id z My effects>", "name": "Cięcie miecza", "frame": [64, 48],
                    "frames": 8, "fps": 16, "anchor": [32, 24]}
("columns" tylko gdy arkusz jest siatką - pixelart_workbench składa najwyżej 1024 px na bok).
Źródło: pixellab_src/vfx/<nazwa>.png - wynik `pixelart_workbench join <image id> --as sheet --columns <klatki>`
zapisany bez zmian (pasek podpisu u góry ucina ten skrypt, ciemne tło (31, 37, 44) zamienia na przezroczyste).
Wynik: assets/effects/<nazwa>.png - zawsze jeden rząd klatek. Uruchom: python tools/vfx_art.py"""
import json
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "vfx")
BACKGROUND = (31, 37, 44)


def clear(sheet):
    """Usuwa tło (kolor tła nie występuje w efektach, więc znika też w szczelinach między iskrami)."""
    px = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, _a = px[x, y]
            if abs(r - BACKGROUND[0]) + abs(g - BACKGROUND[1]) + abs(b - BACKGROUND[2]) <= 6:
                px[x, y] = (0, 0, 0, 0)
    return sheet


def main():
    out = os.path.join(ROOT, "assets", "effects")
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(SRC, "ids.json"), encoding="utf-8") as f:
        effects = json.load(f)
    for name, info in effects.items():
        sheet = Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")
        w, h = info["frame"]
        columns = info.get("columns", info["frames"])
        rows = -(-info["frames"] // columns)
        top = sheet.height - h * rows  # pasek podpisu nad klatkami (0, gdy już ucięty)
        sheet = clear(sheet.crop((0, top, w * columns, sheet.height)))
        if columns < info["frames"]:
            row = Image.new("RGBA", (w * info["frames"], h))
            for i in range(info["frames"]):
                x, y = (i % columns) * w, (i // columns) * h
                row.alpha_composite(sheet.crop((x, y, x + w, y + h)), (i * w, 0))
            sheet = row
        assert sheet.size == (w * info["frames"], h), (name, sheet.size)
        sheet.save(os.path.join(out, name + ".png"))
        print(name, sheet.size)


if __name__ == "__main__":
    main()
