"""Animowane efekty z kreatora efektów PixelLab (vfx_workbench) -> arkusze do gry.

Dane efektów: pixellab_src/vfx/ids.json, np.
  "ciecie_miecza": {"effect": "<id z My effects>", "name": "Cięcie miecza", "frame": [64, 48],
                    "frames": 8, "fps": 16, "anchor": [32, 24]}
("columns" tylko gdy arkusz jest siatką - pixelart_workbench składa najwyżej 1024 px na bok).
Przebarwiony efekt z innego źródła: "source": "<nazwa pliku źródła>", "hue": "#ff8a2a" - każdy piksel dostaje odcień
podanego koloru, a "boost": 1.5 mnoży nasycenie i jasność (blady fioletowy ryk Biesa -> żywy pomarańczowy okrzyk Wodza).
Źródło: pixellab_src/vfx/<nazwa>.png - wynik `pixelart_workbench join <image id> --as sheet --columns <klatki>`
zapisany bez zmian (pasek podpisu u góry ucina ten skrypt, ciemne tło (31, 37, 44) zamienia na przezroczyste).
Zwężenie tyłu smugi: "taper": n - w każdej klatce pierwsze n kolumn od lewej krawędzi efektu przycina się w szpic
ku wysokości zaczepienia (anchor) i obrysowuje ciemnym konturem (smuga pchnięcia glewii miała płaski tył).
Wynik: assets/effects/<nazwa>.png - zawsze jeden rząd klatek. Uruchom: python tools/vfx_art.py"""
import colorsys
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


def recolor(sheet, colour, boost=1.0):
    """Zmienia odcień każdego piksela na odcień `colour` (#rrggbb); `boost` mnoży nasycenie i jasność."""
    target = colorsys.rgb_to_hsv(*(int(colour[i:i + 2], 16) / 255 for i in (1, 3, 5)))[0]
    px = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            _h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            nr, ng, nb = colorsys.hsv_to_rgb(target, min(1.0, s * boost), min(1.0, v * boost))
            px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    return sheet


def taper_left(frame, n, cy):
    """Przycina pierwsze `n` kolumn efektu (od pierwszej niepustej) w szpic ku wierszowi `cy` i obrysowuje go."""
    px = frame.load()
    w, h = frame.size
    cols = [x for x in range(w) if any(px[x, y][3] for y in range(h))]
    if not cols:
        return frame
    left = cols[0]
    dark = min((px[x, y] for x in range(w) for y in range(h) if px[x, y][3]), key=lambda c: sum(c[:3]))
    half = max(abs(y - cy) for x in cols for y in range(h) if px[x, y][3])
    for x in range(left, min(left + n, w)):
        allow = half * (x - left + 1) / n
        for y in range(h):
            if px[x, y][3] and abs(y - cy) > allow:
                px[x, y] = (0, 0, 0, 0)
    for x in range(left, min(left + n, w)):
        ys = [y for y in range(h) if px[x, y][3]]
        if ys:
            px[x, ys[0]] = dark
            px[x, ys[-1]] = dark
    return frame


def main():
    out = os.path.join(ROOT, "assets", "effects")
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(SRC, "ids.json"), encoding="utf-8") as f:
        effects = json.load(f)
    for name, info in effects.items():
        sheet = Image.open(os.path.join(SRC, info.get("source", name) + ".png")).convert("RGBA")
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
        if "taper" in info:
            for i in range(info["frames"]):
                part = taper_left(sheet.crop((i * w, 0, i * w + w, h)), info["taper"], info["anchor"][1])
                sheet.paste(part, (i * w, 0))
        if "hue" in info:
            sheet = recolor(sheet, info["hue"], info.get("boost", 1.0))
        assert sheet.size == (w * info["frames"], h), (name, sheet.size)
        sheet.save(os.path.join(out, name + ".png"))
        print(name, sheet.size)


if __name__ == "__main__":
    main()
