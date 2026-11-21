"""Mroczna kosa (assets/weapons/scythe.png) - rysowana piksel po pikselu jak katana (pixel-art, drzewce w prawo,
chwyt po lewej, ostrze na końcu wygięte w górę i z powrotem nad drzewce). Kolory czarno-białe z przewagą czerni
(decyzja autora 21.11.2026): czarne drzewce z białymi owijkami z kości, ostrze z czarnej stali z jasną krawędzią
tnącą, przy ostrzu białe pasemka mgły Nawii. W grze skala 0,5.
Uruchom: python tools/scythe_art.py"""
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 100, 44
OUTLINE = (6, 5, 9, 255)
WOOD_DARK = (18, 16, 22, 255)
WOOD = (34, 31, 40, 255)
WOOD_LIGHT = (58, 54, 66, 255)
BONE_DARK = (150, 146, 140, 255)
BONE = (214, 210, 200, 255)
STEEL_DARK = (16, 15, 20, 255)
STEEL = (40, 39, 48, 255)
STEEL_LIGHT = (76, 76, 90, 255)
EDGE = (226, 228, 236, 255)
EDGE_HOT = (255, 255, 255, 255)
MIST = (236, 236, 244, 150)
MIST_DIM = (200, 200, 214, 80)

SHAFT_Y = 35
SHAFT_FROM = 4
SHAFT_TO = 88
# ostrze: grzbiet to krzywa Béziera od nasady (koniec drzewca) w górę i z powrotem nad drzewce do wolnego czubka;
# szerokie przy nasadzie, zwęża się ku czubkowi, krawędź tnąca po wklęsłej (dolnej) stronie
BLADE_P = [(88.0, 31.0), (97.0, 2.0), (34.0, 9.0)]
BLADE_W = (10.0, 1.0)


def shaft_y(x):
    """Drzewce lekko wygięte (jak kosisko)."""
    k = (x - SHAFT_FROM) / (SHAFT_TO - SHAFT_FROM)
    return SHAFT_Y - 2.0 * math.sin(k * math.pi)


def bezier(t):
    (x0, y0), (x1, y1), (x2, y2) = BLADE_P
    u = 1.0 - t
    return (u * u * x0 + 2 * u * t * x1 + t * t * x2, u * u * y0 + 2 * u * t * y1 + t * t * y2)


def blade_pixels():
    """Piksel -> głębokość od krawędzi tnącej (0 - sama krawędź). Krawędź po stronie wklęsłej (ku środkowi łuku)."""
    out = {}
    steps = 400
    for i in range(steps + 1):
        t = i / steps
        x, y = bezier(t)
        x2, y2 = bezier(min(t + 0.002, 1.0)) if t < 1.0 else bezier(t)
        x1, y1 = bezier(max(t - 0.002, 0.0))
        tx, ty = x2 - x1, y2 - y1
        n = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / n, tx / n  # od krawędzi tnącej (wnętrze łuku) ku grzbietowi
        w = BLADE_W[0] + (BLADE_W[1] - BLADE_W[0]) * t ** 0.8
        for k in range(int(w * 4) + 1):
            d = k / 4.0  # od krawędzi tnącej (wewnątrz) ku grzbietowi
            px, py = x - nx * (w / 2) + nx * d, y - ny * (w / 2) + ny * d
            key = (int(px), int(py))
            if 0 <= key[0] < W and 0 <= key[1] < H:
                out[key] = min(out.get(key, 99.0), d)
    return out


def main():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    body = {}
    # drzewce
    for x in range(SHAFT_FROM, SHAFT_TO + 1):
        cy = shaft_y(x)
        for y in range(H):
            d = y - cy
            if -1.6 <= d <= 1.6:
                body[(x, y)] = WOOD_LIGHT if d < -0.6 else (WOOD if d < 0.6 else WOOD_DARK)
    # ostrze
    for (x, y), inner in blade_pixels().items():
        if inner < 1.1:
            body[(x, y)] = EDGE_HOT if (x + y) % 7 == 0 else EDGE
        elif inner < 2.2:
            body[(x, y)] = STEEL_LIGHT
        elif inner < 4.0:
            body[(x, y)] = STEEL
        else:
            body[(x, y)] = STEEL_DARK
    # oprawa ostrza na końcu drzewca i owijki z kości
    for x in range(84, 92):
        for y in range(29, 38):
            if abs(y - shaft_y(min(x, SHAFT_TO))) <= 2.6:
                body[(x, y)] = BONE if y < 33 else BONE_DARK
    for wrap in (14, 20, 48):
        cy = shaft_y(wrap)
        for x in range(wrap, wrap + 3):
            for y in range(round(cy) - 2, round(cy) + 3):
                body[(x, y)] = BONE if y <= cy else BONE_DARK
    # kontur
    for (x, y) in list(body):
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in body and 0 <= nx < W and 0 <= ny < H:
                px[nx, ny] = OUTLINE
    for (x, y), c in body.items():
        px[x, y] = c
    # pasemka mgły Nawii przy ostrzu (półprzezroczyste)
    for i, (x, y) in enumerate([(60, 3), (66, 2), (72, 2), (78, 3), (95, 9), (97, 14), (48, 5), (43, 6)]):
        if px[x, y][3] == 0:
            px[x, y] = MIST if i % 2 == 0 else MIST_DIM
    out = os.path.join(ROOT, "assets", "weapons", "scythe.png")
    im.save(out)
    print(out)


if __name__ == "__main__":
    main()
