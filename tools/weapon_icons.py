"""Ikony umiejętności broni (64x64) złożone z grafik gry - decyzja autora 14.11.2026 (zamiast PixelLab AI).

Każda ikona: ramka z ikony Watry (assets/watra/skills/lunge.png - zaokrąglony kwadrat), w środku ciemne tło w barwie
żywiołu broni (ogień - żar od dołu, woda - turkusowa poświata), a na nim broń (assets/weapons/) i klatki jej efektów
z kreatora (assets/effects/). Glewia ognia -> assets/skills/glaive/g_*.png, hydrosfera -> assets/skills/hydro/h_*.png,
elektryczna katana (tło burzowe - fiolet z błękitną poświatą) -> assets/skills/katana/k_*.png, nowe umiejętności miecza
(tło stalowe) -> assets/skills/sword/*.png.
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
        if theme == "steel":  # stalowy granat z chłodną, szarą poświatą od dołu
            r = int(22 + 10 * t + 44 * glow)
            g = int(26 + 12 * t + 50 * glow)
            b = int(36 + 16 * t + 62 * glow)
        elif theme == "storm":  # burzowy fiolet z błękitną poświatą od dołu
            r = int(18 + 10 * t + 30 * glow)
            g = int(16 + 14 * t + 56 * glow)
            b = int(42 + 26 * t + 100 * glow)
        elif theme == "earth":  # ciemny brąz ziemi z bursztynową poświatą od dołu (młot)
            r = int(24 + 14 * t + 90 * glow)
            g = int(18 + 10 * t + 52 * glow)
            b = int(14 + 4 * t + 16 * glow)
        elif theme == "nature":  # ciemna zieleń lasu z jasnozieloną poświatą od dołu (Kostur Leszego)
            r = int(14 + 8 * t + 40 * glow)
            g = int(28 + 16 * t + 100 * glow)
            b = int(16 + 6 * t + 34 * glow)
        elif theme == "frost":  # nocny granat z bladą, lodową poświatą od dołu (lodowy rapier)
            r = int(14 + 8 * t + 70 * glow)
            g = int(22 + 14 * t + 100 * glow)
            b = int(38 + 22 * t + 120 * glow)
        elif theme == "water":  # granat z turkusową poświatą od dołu
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
    paste(img, scaled(trim(frame("hydro_wave", 3)), 0.9), (38, 32))
    paste(img, scaled(ORB, 0.75), (16, 34))
    return clip(img, inside, "water")


def icon_vortex():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_vortex", 2)), 0.62), (32, 34))
    return clip(img, inside, "water")


def icon_geyser():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_geyser", 5)), 0.62), (32, 34))
    return clip(img, inside, "water")


def icon_guardian():
    img, inside = base("water")
    paste(img, scaled(trim(frame("hydro_geyser", 3)), 0.55), (32, 46))
    paste(img, scaled(load("assets/weapons/hydrosphere.png"), 1.6), (32, 28))
    bolt = trim(frame("hydro_bolt", 2))
    paste(img, rotated(bolt, 20), (50, 16))
    paste(img, rotated(bolt, 160), (14, 16))
    return clip(img, inside, "water")


KATANA = load("assets/weapons/katana.png")


def zigzag(img, a, b, seed, colour=(150, 220, 255, 255), core=(245, 252, 255, 255)):
    """Zygzak pioruna od a do b (dwie linie: jasny rdzeń na błękitnej poświacie)."""
    import random
    rnd = random.Random(seed)
    pts = [a]
    for i in range(1, 5):
        k = i / 5
        pts.append((a[0] + (b[0] - a[0]) * k + rnd.randint(-3, 3), a[1] + (b[1] - a[1]) * k + rnd.randint(-3, 3)))
    pts.append(b)
    d = ImageDraw.Draw(img)
    d.line(pts, fill=colour, width=3)
    d.line(pts, fill=core, width=1)


def icon_slash():
    img, inside = base("storm")
    paste(img, scaled(trim(frame("katana_cut", 3)), 0.7), (34, 30))
    zigzag(img, (16, 22), (50, 40), 3)
    paste(img, rotated(KATANA, 40), (30, 34))
    return clip(img, inside, "storm")


def icon_dance():
    img, inside = base("storm")
    cut = trim(frame("katana_cut", 3))
    for deg, at in ((0, (22, 42)), (-60, (34, 30)), (0, (46, 18))):
        paste(img, rotated(scaled(cut, 0.42), deg), at)
    zigzag(img, (16, 48), (30, 30), 4)
    zigzag(img, (30, 30), (50, 16), 5)
    return clip(img, inside, "storm")


def icon_riposte():
    img, inside = base("storm")
    paste(img, scaled(trim(frame("katana_riposte", 6)), 0.55), (32, 40))
    d = ImageDraw.Draw(img)
    d.ellipse((8, 26, 56, 48), outline=(245, 252, 255, 255), width=1)
    paste(img, rotated(scaled(KATANA, 0.8), 0), (32, 24))
    return clip(img, inside, "storm")


def icon_perun():
    img, inside = base("storm")
    paste(img, rotated(scaled(trim(frame("katana_line", 3)), 0.5), 37), (32, 34))
    paste(img, rotated(scaled(KATANA, 0.7), 37), (18, 48))
    zigzag(img, (44, 8), (48, 22), 9)
    return clip(img, inside, "storm")


def icon_flash():
    img, inside = base("storm")
    paste(img, rotated(trim(frame("katana_trail", 1)), 25), (28, 40))
    zigzag(img, (10, 50), (50, 22), 11)
    zigzag(img, (12, 46), (52, 26), 12)
    paste(img, rotated(scaled(KATANA, 0.7), 25), (44, 22))
    return clip(img, inside, "storm")


SWORD = load("assets/watra/iron_sword.png")


def icon_steel_ring():
    img, inside = base("steel")
    d = ImageDraw.Draw(img)
    d.ellipse((10, 20, 54, 46), outline=(150, 190, 230, 255), width=1)
    ghost = scaled(SWORD, 0.55)
    px = ghost.load()
    for y in range(ghost.height):
        for x in range(ghost.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (min(255, int(r * 0.8 + 40)), min(255, int(g * 0.9 + 50)), min(255, b + 70), a)
    for deg in (90, 210, 330):
        rad = math.radians(deg)
        paste(img, rotated(ghost, deg), (32 + 13 * math.cos(rad), 33 - 9 * math.sin(rad)))
    return clip(img, inside, "steel")


def icon_spectral_blades():
    """Widmowe ostrza: dwa błękitne, półprzezroczyste miecze lecą od postaci (kropka) w dwóch wrogów (cięcia)."""
    img, inside = base("steel")
    d = ImageDraw.Draw(img)
    ghost = scaled(SWORD, 0.6)
    px = ghost.load()
    for y in range(ghost.height):
        for x in range(ghost.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (min(255, int(r * 0.6 + 70)), min(255, int(g * 0.8 + 90)), min(255, b + 110), int(a * 0.85))
    for (x0, y0), (x1, y1) in (((32, 46), (14, 16)), ((32, 46), (50, 18))):
        d.line(((x0, y0), (x1, y1)), fill=(120, 170, 230, 160), width=1)
    d.ellipse((28, 42, 36, 50), fill=(200, 230, 255, 255))
    paste(img, rotated(ghost, 125), (20, 24))
    paste(img, rotated(ghost, 55), (44, 26))
    for cx, cy in ((12, 13), (52, 15)):
        d.line(((cx - 4, cy - 4), (cx + 4, cy + 4)), fill=(235, 245, 255, 255), width=2)
    return clip(img, inside, "steel")


ICONS = {
    "sword": (("steel_ring", icon_steel_ring), ("spectral_blades", icon_spectral_blades)),
    "glaive": (("g_thrust", icon_thrust), ("g_sweep", icon_sweep), ("g_trail", icon_trail), ("g_pillar", icon_pillar),
               ("g_dance", icon_dance)),
    "hydro": (("h_bolt", icon_bolt), ("h_wave", icon_wave), ("h_vortex", icon_vortex), ("h_geyser", icon_geyser),
              ("h_guardian", icon_guardian)),
    "katana": (("k_slash", icon_slash), ("k_dance", icon_dance), ("k_riposte", icon_riposte), ("k_perun", icon_perun),
               ("k_flash", icon_flash)),
}


def main():
    for folder, icons in ICONS.items():
        os.makedirs(os.path.join(OUT, folder), exist_ok=True)
        for name, make in icons:
            make().save(os.path.join(OUT, folder, name + ".png"))
            print(folder, name)


if __name__ == "__main__":
    main()
