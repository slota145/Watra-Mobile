"""Ikony umiejętności mrocznej kosy (64x64) - jak tools/weapon_icons.py: ramka ikony Watry, ciemne tło (tu czarno-
szare z bladą poświatą od dołu - Nawia, kolory czarno-białe z przewagą czerni, decyzja autora 21.11.2026), na nim
kosa (assets/weapons/scythe.png) i klatki jej efektów z kreatora (assets/effects/scythe_*.png).
Wynik: assets/skills/scythe/s_*.png. Uruchom: python tools/scythe_icons.py
"""
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapon_icons as wi  # noqa: E402

OUT = os.path.join(wi.ROOT, "assets", "skills", "scythe")
SCYTHE = wi.load("assets/weapons/scythe.png")
## Głowica kosy (ostrze z kawałkiem drzewca) w pełnej rozdzielczości.
HEAD = wi.trim(SCYTHE.crop((30, 0, 100, 40)))


def base():
    """Ramka i tło Nawii: interfejs ramki ze stalowej ikony, wnętrze przerobione na czerń z szarą poświatą."""
    img, inside = wi.base("steel")
    px = img.load()
    for x, y in inside:
        r, g, b, a = px[x, y]
        v = int((r + g + b) / 3 * 0.75)
        px[x, y] = (v, v, min(v + 6, 255), a)
    return img, inside


def clip(img, inside):
    frame_img, _ = base()
    out = frame_img.copy()
    px, src = out.load(), img.load()
    for x, y in inside:
        px[x, y] = src[x, y]
    return out


def icon_reap():
    img, inside = base()
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_swing", 5)), 0.8), (32, 34))
    wi.paste(img, wi.scaled(HEAD, 0.75), (34, 28))
    return clip(img, inside)


def icon_square():
    img, inside = base()
    d = ImageDraw.Draw(img)
    for w, c in ((5, (6, 5, 10, 255)), (1, (236, 238, 246, 255))):
        d.rectangle((15, 15, 48, 48), outline=c, width=w)
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_hit", 4)), 0.5), (15, 15))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_hit", 4)), 0.5), (48, 48))
    wi.paste(img, wi.rotated(wi.scaled(HEAD, 0.45), 20), (32, 32))
    return clip(img, inside)


def icon_mow():
    img, inside = base()
    d = ImageDraw.Draw(img)
    d.polygon([(26, 52), (38, 52), (58, 12), (6, 12)], fill=(14, 13, 20, 255), outline=(220, 222, 232, 255))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_blast", 4)), 0.22), (22, 22))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_blast", 4)), 0.22), (42, 22))
    wi.paste(img, wi.scaled(HEAD, 0.5), (32, 40))
    return clip(img, inside)


def icon_dance():
    img, inside = base()
    wi.paste(img, wi.scaled(wi.trim(wi.frame("scythe_whirl", 4)), 0.55), (32, 18))
    wi.paste(img, wi.rotated(wi.scaled(HEAD, 0.45), 160), (32, 16))
    wi.paste(img, wi.rotated(wi.scaled(wi.trim(wi.frame("scythe_diag", 5)), 0.7), 35), (34, 42))
    return clip(img, inside)


def icon_mara():
    img, inside = base()
    d = ImageDraw.Draw(img)
    pts = [(8 + i * 3, round(54 - i * 2.4 - 6 * math.sin(i * 0.6))) for i in range(12)]  # ogon wpada w chmurę
    for i in range(len(pts) - 1):  # zwęża się ku końcowi: biały brzeg, czarny środek
        w = 2 + i // 2
        d.line(pts[i:i + 2], fill=(232, 234, 242, 255), width=w + 2)
    for i in range(len(pts) - 1):
        d.line(pts[i:i + 2], fill=(6, 5, 10, 255), width=1 + i // 2)
    for cx, cy, r in ((44, 22, 9), (50, 18, 6), (38, 18, 6), (46, 28, 6)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(6, 5, 10, 255))
    for x, y in ((42, 20), (47, 21)):
        d.point((x, y), fill=(250, 250, 255, 255))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("mara_curse", 0)), 0.7), (20, 18))
    return clip(img, inside)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("s_reap", icon_reap), ("s_square", icon_square), ("s_mow", icon_mow), ("s_dance", icon_dance),
                     ("s_mara", icon_mara)):
        fn().save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
