"""Ikony umiejętności broni (64x64) złożone z grafik gry - decyzja autora 14.11.2026 (zamiast PixelLab AI).

Każda ikona: ramka z ikony Watry (assets/watra/skills/lunge.png - zaokrąglony kwadrat), w środku ciemne tło w barwie
żywiołu broni (ogień - żar od dołu, woda - turkusowa poświata), a na nim broń (assets/weapons/) i klatki jej efektów
z kreatora (assets/effects/). Glewia ognia -> assets/skills/glaive/g_*.png, hydrosfera -> assets/skills/hydro/h_*.png.
Uruchom: python tools/weapon_icons.py
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FX = os.path.join(ROOT, "assets", "effects")
OUT = os.path.join(ROOT, "assets", "skills")
SIZE = 64
BORDER = 4  # grubość ramki (piksele od krawędzi kształtu)


def load(path):
    return Image.open(os.path.join(ROOT, path)).convert("RGBA")


def frame(name, i):
    """Klatka `i` arkusza efektu (jeden rząd klatek, wymiary z pixellab_src/vfx/ids.json)."""
    import json
    with open(os.path.join(ROOT, "pixellab_src", "vfx", "ids.json"), encoding="utf-8") as f:
        w, h = json.load(f)[name]["frame"]
    return load(f"assets/effects/{name}.png").crop((i * w, 0, i * w + w, h))


def trim(im):
    box = im.getbbox()
    return im.crop(box) if box else im


def scaled(im, k):
    return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)


def rotated(im, deg):
    """Obrót o dowolny kąt bez wygładzania (pixel art), z zapasem płótna."""
    return trim(im.rotate(deg, resample=Image.NEAREST, expand=True))


## Kolory ramki od zewnątrz (czarny kontur, łupkowy pas, jaśniejsza krawędź) - jak ramki ikon Watry.
RING = [(2, 1, 1, 255), (40, 44, 58, 255), (40, 44, 58, 255), (72, 78, 98, 255)]


def base(theme="fire"):
    """Ramka (kształt ikony Watry, kolory RING) i ciemne tło z żarem od dołu. Zwraca obraz i piksele wnętrza."""
    alpha = load("assets/watra/skills/lunge.png").getchannel("A")
    dist = {}
    frontier = [(x, y) for y in range(SIZE) for x in range(SIZE) if alpha.getpixel((x, y)) != 0
                and any(not (0 <= x + dx < SIZE and 0 <= y + dy < SIZE) or alpha.getpixel((x + dx, y + dy)) == 0
                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for p in frontier:
        dist[p] = 0
    while frontier:
        nxt = []
        for x, y in frontier:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                q = (x + dx, y + dy)
                if 0 <= q[0] < SIZE and 0 <= q[1] < SIZE and alpha.getpixel(q) != 0 and q not in dist:
                    dist[q] = dist[(x, y)] + 1
                    nxt.append(q)
        frontier = nxt
    out = Image.new("RGBA", (SIZE, SIZE))
    o = out.load()
    inside = []
    for (x, y), d in dist.items():
        if d < len(RING):
            o[x, y] = RING[d]
            continue
        inside.append((x, y))
        t = y / SIZE  # od góry ciemny granat, ku dołowi bordowy żar
        glow = max(0.0, 1.0 - math.hypot(x - 32, y - 60) / 42.0)
        if theme == "water":  # granat z turkusową poświatą od dołu
            r = int(10 + 6 * t + 20 * glow)
            g = int(20 + 20 * t + 70 * glow)
            b = int(40 + 30 * t + 90 * glow)
        else:
            r = int(20 + 34 * t + 96 * glow)
            g = int(16 + 8 * t + 34 * glow)
            b = int(28 - 12 * t)
        if (x * 3 + y * 2) % 11 == 0:  # pasy jak pociągnięcia pędzla w ikonach Watry
            r, g, b = r + 6, g + 4, b + 4
        o[x, y] = (min(r, 255), min(g, 255), max(b, 0), 255)
    return out, inside


def paste(img, sprite, center):
    img.alpha_composite(sprite, (round(center[0] - sprite.width / 2), round(center[1] - sprite.height / 2)))


def clip(img, inside, theme="fire"):
    """Usuwa to, co wyszło na ramkę lub poza nią (ramka zostaje na wierzchu)."""
    frame_img, _ = base(theme)
    keep = set(inside)
    out = frame_img.copy()
    px, src = out.load(), img.load()
    for x, y in keep:
        px[x, y] = src[x, y]
    return out


GLAIVE = load("assets/weapons/glaive.png")
## Głowica glewii w pełnej rozdzielczości (oprawa, frędzel, ostrze i kawałek drzewca) - pomniejszona cała glewia
## miała drzewce cienkie jak nitka.
HEAD = trim(GLAIVE.crop((34, 0, 96, 20)))


def icon_thrust():
    img, inside = base()
    streak = trim(frame("glaive_thrust", 1))
    paste(img, rotated(streak, 35), (30, 36))
    paste(img, rotated(HEAD, 35), (34, 32))
    paste(img, scaled(trim(frame("glaive_hit", 2)), 0.9), (50, 14))
    return clip(img, inside)


def icon_sweep():
    img, inside = base()
    paste(img, scaled(trim(frame("glaive_sweep", 3)), 0.45), (36, 32))
    paste(img, rotated(HEAD, 60), (30, 30))
    return clip(img, inside)


def icon_trail():
    img, inside = base()
    fire = trim(frame("glaive_ground_fire", 3))
    for i in range(4):
        paste(img, fire, (12 + i * 8, 54 - i * 6))
    cut = trim(frame("glaive_cut", 7))
    for deg in (-70, -45, -20):  # wachlarz w górę w prawo (kąt na ekranie, y w dół)
        r = math.radians(deg)
        paste(img, rotated(scaled(cut, 0.75), -deg), (30 + 20 * math.cos(r), 34 + 20 * math.sin(r)))
    paste(img, rotated(HEAD, -120), (22, 44))
    return clip(img, inside)


def icon_pillar():
    img, inside = base()
    paste(img, scaled(trim(frame("glaive_blast", 5)), 0.8), (32, 44))
    paste(img, rotated(HEAD, -90), (32, 24))
    return clip(img, inside)


def icon_dance():
    img, inside = base()
    slash = trim(frame("glaive_dance_slash", 4))
    for deg, at in ((0, (30, 14)), (240, (50, 38)), (120, (14, 40))):
        paste(img, rotated(scaled(slash, 0.6), deg), at)
    paste(img, rotated(HEAD, 25), (32, 33))
    return clip(img, inside)


ORB = scaled(load("assets/weapons/hydrosphere.png"), 2)


def icon_bolt():
    img, inside = base("water")
    bolt = trim(frame("hydro_bolt", 2))
    paste(img, rotated(scaled(bolt, 1.6), 30), (40, 26))
    paste(img, ORB, (20, 44))
    paste(img, scaled(trim(frame("hydro_splash", 4)), 0.7), (50, 16))
    return clip(img, inside, "water")


def icon_wave():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_wave", 6)), 0.95), (40, 32))
    paste(img, scaled(ORB, 0.75), (18, 34))
    return clip(img, inside, "water")


def icon_vortex():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_vortex", 3)), 0.8), (32, 40))
    swirl = trim(frame("hydro_swirl", 4))
    paste(img, scaled(swirl, 0.75), (32, 30))
    paste(img, rotated(scaled(swirl, 0.75), 180), (32, 44))
    return clip(img, inside, "water")


def icon_geyser():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_geyser", 5)), 0.62), (32, 34))
    return clip(img, inside, "water")


def icon_rain():
    img, inside = base("water")
    drop = rotated(trim(frame("hydro_drop", 2)), -90)  # ostrzem w dół
    for x, y in ((18, 20), (34, 14), (48, 24), (26, 36)):
        paste(img, drop, (x, y))
    paste(img, scaled(trim(frame("hydro_splash", 5)), 0.7), (40, 50))
    return clip(img, inside, "water")


ICONS = {
    "glaive": (("g_thrust", icon_thrust), ("g_sweep", icon_sweep), ("g_trail", icon_trail), ("g_pillar", icon_pillar),
               ("g_dance", icon_dance)),
    "hydro": (("h_bolt", icon_bolt), ("h_wave", icon_wave), ("h_vortex", icon_vortex), ("h_geyser", icon_geyser),
              ("h_rain", icon_rain)),
}


def main():
    for folder, icons in ICONS.items():
        os.makedirs(os.path.join(OUT, folder), exist_ok=True)
        for name, make in icons:
            make().save(os.path.join(OUT, folder, name + ".png"))
            print(folder, name)


if __name__ == "__main__":
    main()
