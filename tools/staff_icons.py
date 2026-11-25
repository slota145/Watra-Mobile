"""Ikony umiejętności Kostura Leszego - broni natury (64x64), jak tools/rapier_icons.py: ramka ikony Watry, tło ciemnej
zieleni lasu z jasną poświatą od dołu (motyw "nature" w tools/weapon_icons.py), na nim kostur (assets/weapons/staff.png),
korzenie, żołądź, ciernie, zarodniki i drzewiec rysowane w kodzie (klatki efektów z kreatora, gdy są: root_burst,
acorn, entangle, spores). Wynik: assets/skills/staff/l_*.png. Uruchom: python tools/staff_icons.py
"""
import math
import os
import sys

from PIL import ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapon_icons as wi  # noqa: E402

OUT = os.path.join(wi.ROOT, "assets", "skills", "staff")
STAFF = wi.load("assets/weapons/staff.png")
ROOT_DARK = (60, 38, 22, 255)
ROOT = (118, 80, 46, 255)
ROOT_LIGHT = (160, 116, 70, 255)
LEAF = (110, 190, 70, 255)
POISON = (150, 230, 80, 255)


def has_fx(name):
    return os.path.exists(os.path.join(wi.ROOT, "assets", "effects", name + ".png"))


def root_spike(d, x, y, h, lean=0):
    """Korzeń wyrastający z ziemi: zwężający się, zakrzywiony kolec z jaśniejszym grzbietem."""
    pts = [(x - 3, y), (x + lean * 0.5 - 1, y - h * 0.6), (x + lean, y - h), (x + lean * 0.5 + 2, y - h * 0.55), (x + 3, y)]
    d.polygon(pts, fill=ROOT, outline=ROOT_DARK)
    d.line([(x - 1, y - 1), (x + lean * 0.5 - 0.5, y - h * 0.6), (x + lean, y - h + 1)], fill=ROOT_LIGHT, width=1)


def icon_roots():
    img, inside = wi.base("nature")
    d = ImageDraw.Draw(img)
    pts = [(10, 50), (22, 44), (34, 48), (46, 40), (54, 44)]
    d.line(pts, fill=ROOT_DARK, width=3)
    d.line(pts, fill=ROOT, width=1)
    for x, y, h, lean in ((22, 44, 18, -3), (34, 48, 22, 2), (46, 40, 18, 3)):
        root_spike(d, x, y, h, lean)
    wi.paste(img, wi.rotated(wi.scaled(STAFF, 0.55), 45), (16, 20))
    return wi.clip(img, inside, "nature")


def icon_acorn():
    img, inside = wi.base("nature")
    d = ImageDraw.Draw(img)
    for i in range(5):
        d.ellipse((10 + i * 5, 40 - i * 4, 13 + i * 5, 43 - i * 4), fill=(120, 200, 90, 120 + i * 25))
    d.ellipse((30, 16, 48, 36), fill=(170, 110, 50, 255), outline=ROOT_DARK)
    d.chord((28, 12, 50, 26), 180, 360, fill=(110, 76, 40, 255), outline=ROOT_DARK)
    d.line([(39, 12), (40, 8)], fill=ROOT_DARK, width=2)
    d.point((35, 22), fill=(230, 180, 110, 255))
    for x in (20, 40, 54):  # sadzonka na końcu
        pass
    d.line([(48, 54), (48, 46)], fill=(70, 120, 40, 255), width=2)
    d.ellipse((42, 42, 48, 47), fill=LEAF)
    d.ellipse((48, 40, 55, 45), fill=LEAF)
    return wi.clip(img, inside, "nature")


def icon_grasp():
    """Uścisk Boru: ciemna sylwetka wroga oplątana cierniowymi pnączami, które wyrastają z ziemi (bez czerwonego kółka -
    uwaga autora 25.11.2026); gdy jest efekt `entangle` z kreatora - jego klatka na sylwetce."""
    img, inside = wi.base("nature")
    d = ImageDraw.Draw(img)
    d.ellipse((24, 12, 40, 26), fill=(30, 36, 28, 255))  # głowa
    d.rounded_rectangle((22, 24, 42, 52), 5, fill=(30, 36, 28, 255))  # tułów
    for k in range(5):  # pnącza owijające się spiralnie od ziemi w górę
        y0 = 54 - k * 8
        pts = [(18 + i * 7, y0 - math.sin(i * 1.2 + k) * 3 - i * 1.2) for i in range(5)]
        d.line(pts, fill=ROOT_DARK, width=4)
        d.line(pts, fill=(84, 120, 48, 255), width=2)
        for x, y in pts[1::2]:
            d.line([(x, y), (x + 2, y - 3)], fill=(210, 228, 160, 255), width=1)
    if has_fx("entangle"):
        wi.paste(img, wi.scaled(wi.trim(wi.frame("entangle", 3)), 1.3), (32, 36))
    for x in (10, 54):  # korzenie z ziemi po bokach
        root_spike(d, x, 58, 12, 4 if x < 32 else -4)
    return wi.clip(img, inside, "nature")


def icon_spores():
    img, inside = wi.base("nature")
    d = ImageDraw.Draw(img)
    for r, a in ((24, 90), (17, 150), (10, 220)):
        d.ellipse((32 - r, 36 - r * 0.65, 32 + r, 36 + r * 0.65), fill=(120, 200, 60, a // 3), outline=POISON[:3] + (a,))
    for x, y in ((18, 22), (44, 18), (30, 12), (50, 30), (12, 34), (38, 26)):
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(200, 240, 120, 255))
    d.line([(32, 54), (32, 44)], fill=(70, 120, 40, 255), width=2)
    d.ellipse((26, 42, 32, 47), fill=LEAF)
    d.ellipse((32, 40, 39, 45), fill=LEAF)
    return wi.clip(img, inside, "nature")


def icon_treants():
    img, inside = wi.base("nature")
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((22, 20, 42, 50), 5, fill=(110, 74, 42, 255), outline=ROOT_DARK)  # pień
    d.line([(26, 24), (26, 46)], fill=(140, 98, 60, 255), width=1)
    d.line([(22, 30), (12, 22), (8, 26)], fill=ROOT_DARK, width=4)  # ramiona-gałęzie
    d.line([(42, 30), (52, 22), (56, 26)], fill=ROOT_DARK, width=4)
    d.line([(22, 30), (12, 22)], fill=ROOT, width=2)
    d.line([(42, 30), (52, 22)], fill=ROOT, width=2)
    d.ellipse((16, 8, 48, 26), fill=(70, 130, 50, 255), outline=(30, 60, 24, 255))  # korona liści
    d.ellipse((22, 10, 36, 20), fill=LEAF)
    d.rectangle((27, 30, 29, 32), fill=(180, 255, 140, 255))  # oczy
    d.rectangle((35, 30, 37, 32), fill=(180, 255, 140, 255))
    d.line([(26, 50), (22, 56)], fill=ROOT_DARK, width=3)
    d.line([(38, 50), (42, 56)], fill=ROOT_DARK, width=3)
    return wi.clip(img, inside, "nature")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("l_roots", icon_roots), ("l_acorn", icon_acorn), ("l_grasp", icon_grasp),
               ("l_spores", icon_spores), ("l_treants", icon_treants)):
        fn().save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
