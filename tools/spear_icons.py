"""Ikony umiejętności Słonecznej włóczni Dadźboga - broni Prawii (64x64), jak tools/rapier_icons.py: ramka ikony Watry,
tło nocnego brązu ze złotą poświatą od dołu (motyw "sun" w tools/weapon_icons.py), na nim włócznia
(assets/weapons/spear.png) i klatki jej efektów z kreatora (spear_thrust, spear_hit, sun_ring, sun_spin, sky_beam).
Wynik: assets/skills/spear/p_*.png. Uruchom: python tools/spear_icons.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weapon_icons as wi  # noqa: E402

OUT = os.path.join(wi.ROOT, "assets", "skills", "spear")
SPEAR = wi.load("assets/weapons/spear.png")


def icon_thrust():
    """Promienne Pchnięcie: włócznia po skosie w górę-prawo, przed grotem smuga pchnięcia i gwiazdka trafienia."""
    img, inside = wi.base("sun")
    wi.paste(img, wi.rotated(wi.trim(wi.frame("spear_thrust", 1)), 40), (42, 22))
    wi.paste(img, wi.rotated(wi.scaled(SPEAR, 0.62), 40), (26, 38))
    wi.paste(img, wi.trim(wi.frame("spear_hit", 1)), (52, 13))
    return wi.clip(img, inside, "sun")


def icon_throw():
    """Rzut Dadźboga: włócznia leci w prawo nad wrogiem (gwiazdka trafienia), niżej druga, blada - wraca w lewo."""
    img, inside = wi.base("sun")
    wi.paste(img, wi.trim(wi.frame("spear_thrust", 2)), (22, 22))
    wi.paste(img, wi.scaled(SPEAR, 0.6), (34, 22))
    wi.paste(img, wi.trim(wi.frame("spear_hit", 1)), (52, 22))
    ghost = wi.scaled(SPEAR, 0.5).transpose(0)  # FLIP_LEFT_RIGHT - włócznia wracająca
    ghost.putalpha(ghost.getchannel("A").point(lambda a: a * 6 // 10))
    wi.paste(img, ghost, (32, 44))
    return wi.clip(img, inside, "sun")


def icon_sunrise():
    """Wschód Słońca: włócznia wbita pionowo w ziemię, wokół grotu złoty pierścień światła."""
    img, inside = wi.base("sun")
    wi.paste(img, wi.scaled(wi.trim(wi.frame("sun_ring", 5)), 0.5), (32, 46))
    wi.paste(img, wi.rotated(wi.scaled(SPEAR, 0.55), 90), (32, 30))
    wi.paste(img, wi.trim(wi.frame("spear_hit", 1)), (32, 14))
    return wi.clip(img, inside, "sun")


def icon_wheel():
    """Kołowrót Słońca: włócznia poziomo nad dwoma złotymi okręgami obrotu."""
    img, inside = wi.base("sun")
    spin = wi.trim(wi.frame("sun_spin", 6))
    wi.paste(img, wi.scaled(spin, 0.6), (32, 40))
    wi.paste(img, wi.scaled(wi.trim(wi.frame("sun_ring", 6)), 0.45), (32, 48))
    wi.paste(img, wi.rotated(wi.scaled(SPEAR, 0.6), 15), (32, 24))
    return wi.clip(img, inside, "sun")


def icon_zenith():
    """Zenit: trzy promienie z nieba, w każdym spada włócznia grotem w dół."""
    img, inside = wi.base("sun")
    beam = wi.trim(wi.frame("sky_beam", 9))
    for x, k in ((14, 0.4), (50, 0.4), (32, 0.5)):
        wi.paste(img, wi.scaled(beam, k), (x, 30))
    down = wi.rotated(wi.scaled(SPEAR, 0.4), -90)
    for x, y in ((14, 40), (50, 40), (32, 36)):
        wi.paste(img, down, (x, y))
    for x, y in ((14, 56), (50, 56), (32, 54)):
        wi.paste(img, wi.scaled(wi.trim(wi.frame("sun_ring", 3)), 0.22), (x, y))
    return wi.clip(img, inside, "sun")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("p_thrust", icon_thrust), ("p_throw", icon_throw), ("p_sunrise", icon_sunrise),
                     ("p_wheel", icon_wheel), ("p_zenith", icon_zenith)):
        fn().save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
