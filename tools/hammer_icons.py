"""Ikony umiejętności młota - broni ziemi (64x64), jak tools/scythe_icons.py: ramka ikony Watry, tło ciemnego brązu
z bursztynową poświatą od dołu (motyw "earth" w tools/weapon_icons.py), na nim młot (assets/weapons/hammer.png)
i klatki efektów z kreatora (boss_slam, slam_spikes, cleaver_impact); Rozłupanie Ziemi (przeniesione z miecza)
dostaje własną ikonę z młotem. Wynik: assets/skills/hammer/m_*.png. Uruchom: python tools/hammer_icons.py
"""
import math
import os
import sys

from PIL import ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapon_icons as wi  # noqa: E402

OUT = os.path.join(wi.ROOT, "assets", "skills", "hammer")
HAMMER = wi.load("assets/weapons/hammer.png")
DUST = (214, 150, 80, 255)


def icon_smash():
    img, inside = wi.base("earth")
    wi.paste(img, wi.scaled(wi.trim(wi.frame("boss_slam", 3)), 0.75), (32, 46))
    wi.paste(img, wi.rotated(wi.scaled(HAMMER, 0.62), -60), (34, 26))
    return wi.clip(img, inside, "earth")


def icon_throw():
    img, inside = wi.base("earth")
    d = ImageDraw.Draw(img)
    for r in (17, 13):  # łuki obrotu lecącego młota
        d.arc((32 - r, 30 - r, 32 + r, 30 + r), 200, 330, fill=(230, 170, 90, 220), width=1)
    d.line(((10, 50), (22, 40)), fill=DUST, width=1)
    d.line(((54, 50), (44, 40)), fill=DUST, width=1)
    wi.paste(img, wi.rotated(wi.scaled(HAMMER, 0.5), 35), (32, 30))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("cleaver_impact", 3)), 0.6), (12, 50))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("cleaver_impact", 3)), 0.6), (52, 50))
    return wi.clip(img, inside, "earth")


def icon_leap():
    img, inside = wi.base("earth")
    d = ImageDraw.Draw(img)
    pts = [(8 + i * 4, round(48 - 34 * math.sin(i / 8 * math.pi))) for i in range(9)]  # tor skoku
    for i in range(0, len(pts) - 1, 2):
        d.line(pts[i:i + 2], fill=(240, 200, 130, 255), width=2)
    wi.paste(img, wi.scaled(wi.trim(wi.frame("boss_slam", 4)), 0.62), (44, 48))
    wi.paste(img, wi.rotated(wi.scaled(HAMMER, 0.48), -70), (44, 30))
    return wi.clip(img, inside, "earth")


def icon_quake():
    img, inside = wi.base("earth")
    d = ImageDraw.Draw(img)
    for r, a in ((26, 120), (19, 180), (12, 255)):  # fale wstrząsu
        d.ellipse((32 - r, 40 - r * 0.55, 32 + r, 40 + r * 0.55), outline=(230, 160, 80, a), width=2)
    wi.paste(img, wi.scaled(wi.trim(wi.frame("slam_spikes", 6)), 0.5), (14, 40))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("slam_spikes", 6)), 0.5), (50, 40))
    wi.paste(img, wi.rotated(wi.scaled(HAMMER, 0.5), -90), (32, 24))
    return wi.clip(img, inside, "earth")


def icon_slam():
    """Rozłupanie Ziemi przy młocie (dawniej ikona z Watry z mieczem): szczelina z kolcami i młot obuchem w dół."""
    img, inside = wi.base("earth")
    d = ImageDraw.Draw(img)
    pts = [(14, 50), (22, 44), (27, 46), (34, 38), (40, 39), (47, 30), (54, 26)]
    d.line(pts, fill=(18, 10, 6, 255), width=3)
    d.line(pts, fill=(255, 176, 80, 255), width=1)
    for x, y in ((30, 40), (44, 32)):
        wi.paste(img, wi.scaled(wi.trim(wi.frame("slam_spikes", 7)), 0.42), (x, y))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("boss_slam", 3)), 0.5), (16, 48))
    wi.paste(img, wi.rotated(wi.scaled(HAMMER, 0.5), -90), (16, 26))
    return wi.clip(img, inside, "earth")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("m_smash", icon_smash), ("m_throw", icon_throw), ("m_leap", icon_leap), ("m_quake", icon_quake),
               ("slam", icon_slam)):
        fn().save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
