"""Ikony umiejętności lodowego rapiera - broni lodu (64x64), jak tools/hammer_icons.py: ramka ikony Watry, tło nocnego
granatu z lodową poświatą od dołu (motyw "frost" w tools/weapon_icons.py), na nim rapier (assets/weapons/rapier.png)
i klatki efektów z kreatora przebarwionych na lód (rapier_thrust, ice_spikes, rapier_hit, rapier_trail).
Wynik: assets/skills/rapier/r_*.png. Uruchom: python tools/rapier_icons.py
"""
import math
import os
import sys

from PIL import ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapon_icons as wi  # noqa: E402

OUT = os.path.join(wi.ROOT, "assets", "skills", "rapier")
RAPIER = wi.load("assets/weapons/rapier.png")
ICE = (200, 240, 255, 255)
ICE_DIM = (120, 190, 230, 200)


def icon_thrust():
    """Pchnięcie Szronu: rapier po skosie w górę-prawo, przed szpicem smuga pchnięcia i gwiazdka trafienia."""
    img, inside = wi.base("frost")
    wi.paste(img, wi.rotated(wi.scaled(wi.trim(wi.frame("rapier_thrust2", 1)), 1.0), 40), (40, 24))
    wi.paste(img, wi.rotated(wi.scaled(RAPIER, 0.75), 40), (26, 38))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("rapier_hit2", 3)), 0.9), (50, 14))
    return wi.clip(img, inside, "frost")


def icon_lunge():
    """Wypad: postać (kropka) i długa lodowa smuga w prawo, rapier na czele, szron na ziemi."""
    img, inside = wi.base("frost")
    d = ImageDraw.Draw(img)
    for x in range(8, 46, 5):
        d.rectangle((x, 46 + (x // 5) % 2 * 2, x + 1, 47 + (x // 5) % 2 * 2), fill=ICE)
    d.line(((8, 44), (46, 44)), fill=ICE_DIM, width=3)
    wi.paste(img, wi.scaled(wi.trim(wi.frame("rapier_lunge", 2)), 0.9), (20, 30))
    wi.paste(img, wi.scaled(RAPIER, 0.85), (38, 30))
    return wi.clip(img, inside, "frost")


def icon_riposte():
    """Riposta Morozka: szronowy krąg riposty na ziemi, rapier pionowo w nim i błysk odbicia."""
    img, inside = wi.base("frost")
    wi.paste(img, wi.scaled(wi.trim(wi.frame("riposte_circle", 0)), 0.55), (32, 46))
    wi.paste(img, wi.rotated(wi.scaled(RAPIER, 0.75), 90), (30, 28))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("riposte_flash", 3)), 0.8), (46, 18))
    return wi.clip(img, inside, "frost")


def icon_flurry():
    """Grad Pchnięć: wachlarz pięciu smug pchnięć z jednego punktu."""
    img, inside = wi.base("frost")
    thrust = wi.scaled(wi.trim(wi.frame("rapier_thrust2", 1)), 0.8)
    for ang in (-50, -25, 0, 25, 50):
        a = math.radians(ang - 30)
        wi.paste(img, wi.rotated(thrust, ang + 30), (22 + math.cos(a) * 18, 42 + math.sin(a) * 18))
    wi.paste(img, wi.rotated(wi.scaled(RAPIER, 0.6), 30), (18, 46))
    return wi.clip(img, inside, "frost")


def icon_swarm():
    """Rój Sopli: mroźna chmura u góry, z niej lecą w dół-prawo trzy sople."""
    img, inside = wi.base("frost")
    wi.paste(img, wi.scaled(wi.trim(wi.frame("ice_cloud", 0)), 1.0), (26, 18))
    icicle = wi.trim(wi.frame("icicle", 0))
    for x, y in ((24, 40), (38, 44), (50, 34)):
        wi.paste(img, wi.rotated(icicle, -55), (x, y))
    return wi.clip(img, inside, "frost")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("r_thrust", icon_thrust), ("r_lunge", icon_lunge), ("r_riposte", icon_riposte),
               ("r_flurry", icon_flurry), ("r_swarm", icon_swarm)):
        fn().save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
