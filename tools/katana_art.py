"""Elektryczna katana (assets/weapons/katana.png) - rysowana piksel po pikselu (pixel-art, ostrze w prawo,
rękojeść po lewej, jak glewia). Stalowe ostrze lekko wygięte ku górze, granatowa owijka z wzorem w romby, złota
tsuba i niebieskie iskry na ostrzu (wybór autora 15.11.2026: „stal + niebieskie iskry”). W grze skala 0,5.
Uruchom: python tools/katana_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 76, 16
OUTLINE = (24, 22, 34, 255)
STEEL_DARK = (92, 104, 124, 255)
STEEL = (158, 172, 190, 255)
STEEL_LIGHT = (222, 232, 242, 255)
EDGE = (250, 252, 255, 255)
WRAP = (36, 46, 92, 255)
WRAP_LIGHT = (70, 92, 160, 255)
SKIN = (226, 214, 190, 255)
GOLD = (214, 168, 64, 255)
GOLD_LIGHT = (252, 222, 120, 255)
SPARK = (120, 210, 255, 255)
SPARK_HOT = (240, 252, 255, 255)
SPARK_YELLOW = (255, 236, 120, 255)

BLADE_FROM = 25
BLADE_TO = 72
GRIP_Y = 8


def curve(x):
    """Środek ostrza (y) w kolumnie x - łagodne wygięcie ku górze przy czubku."""
    k = (x - BLADE_FROM) / (BLADE_TO - BLADE_FROM)
    return GRIP_Y - round(3.0 * k * k)


def main():
    img = Image.new("RGBA", (W, H))
    px = img.load()
    # ostrze: grzbiet (dół, ciemny), środek, jasna krawędź tnąca (góra); czubek zwęża się
    for x in range(BLADE_FROM, BLADE_TO + 1):
        c = curve(x)
        left = BLADE_TO - x
        thick = 3 if left > 4 else (2 if left > 1 else 1)
        rows = list(range(c - 1, c - 1 + thick))
        for i, y in enumerate(rows):
            if len(rows) == 1:
                col = EDGE
            elif i == 0:
                col = EDGE if x % 7 else STEEL_LIGHT
            elif i == len(rows) - 1:
                col = STEEL_DARK
            else:
                col = STEEL
            px[x, y] = col
        # linia hartowania (hamon) - jaśniejsza falka w środku ostrza
        if thick == 3 and x % 5 in (1, 2):
            px[x, c] = STEEL_LIGHT
    # habaki (złota tulejka przy ostrzu)
    for x in range(BLADE_FROM - 2, BLADE_FROM):
        for y in range(GRIP_Y - 1, GRIP_Y + 2):
            px[x, y] = GOLD_LIGHT if y == GRIP_Y - 1 else GOLD
    # tsuba (jelec - okrągła złota tarczka)
    for x in range(BLADE_FROM - 4, BLADE_FROM - 2):
        for y in range(GRIP_Y - 4, GRIP_Y + 5):
            px[x, y] = GOLD_LIGHT if x == BLADE_FROM - 4 and y < GRIP_Y else GOLD
    # rękojeść: owijka w romby (granat i skóra), na końcu złota kashira
    for x in range(3, BLADE_FROM - 4):
        for y in range(GRIP_Y - 1, GRIP_Y + 2):
            d = (x + (y - GRIP_Y)) % 4
            col = SKIN if d == 0 and y == GRIP_Y else (WRAP_LIGHT if y == GRIP_Y - 1 else WRAP)
            px[x, y] = col
    for y in range(GRIP_Y - 1, GRIP_Y + 2):
        px[2, y] = GOLD
        px[1, y] = GOLD_LIGHT if y == GRIP_Y - 1 else GOLD
    # kontur: każdy pusty piksel stykający się z rysunkiem
    filled = {(x, y) for x in range(W) for y in range(H) if px[x, y][3]}
    for x in range(W):
        for y in range(H):
            if (x, y) in filled:
                continue
            if any((x + dx, y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = OUTLINE
    # iskry na ostrzu i tuż obok (nad konturem)
    for x, dy, col in ((34, -3, SPARK), (35, -4, SPARK_HOT), (44, 3, SPARK), (52, -3, SPARK_YELLOW),
            (53, -4, SPARK), (61, -3, SPARK_HOT), (62, -4, SPARK), (67, 2, SPARK)):
        y = curve(x) + dy
        if 0 <= y < H:
            px[x, y] = col
    out = os.path.join(ROOT, "assets", "weapons", "katana.png")
    img.save(out)
    print(out, img.size, "chwyt:", (BLADE_FROM - 9, GRIP_Y))


if __name__ == "__main__":
    main()
