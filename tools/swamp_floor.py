"""Podłoże Zatopionych podziemi: duże (SIZE x SIZE), nieregularne pole wody z kępkami rzęsy i lilii.

Kafelek płycizny z Watry (../Watra/assets/swamp/ground/shallow.png, 64x64) powtarzany wprost dawał wyraźny wzór
co 64 px (uwaga autora 15.11.2026). Tu z kafelka wycina się kępki (wszystko poza tłem wody i ciemnymi
zmarszczkami), a potem rozrzuca je losowo (z odbiciami) na dużym polu: gęstość zależy od miękkiego szumu, więc
są skupiska i otwarte połacie wody; zmarszczki dorysowuje się osobno. Kępki i szum zawijają się na brzegach, więc
pole powtarza się bez szwów. Na końcu kolory przesuwa się w stronę mętnej, szaroniebieskiej wody (żeby zielone
żabołaki i ciemne topielce odcinały się od tła).

Użycie: python tools/swamp_floor.py [ziarno]  ->  assets/watra/swamp_floor.png
"""
import colorsys
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT.parent / "Watra" / "assets" / "swamp" / "ground" / "shallow.png"
# kopia kafelka w repozytorium (gdy nie ma klonu Watry obok)
SOURCE_COPY = ROOT / "tools" / "data" / "swamp_shallow_src.png"
OUT = ROOT / "assets" / "watra" / "swamp_floor.png"
SIZE = 768
TILE = 64
BG = (17, 61, 50)
RIPPLE = (7, 41, 36)
# ile kępek próbujemy postawić (część odpada przez szum) i ile zmarszczek
CLUMP_TRIES = 5500
RIPPLES = 1600


def load_source() -> Image.Image:
    path = SOURCE if SOURCE.exists() else SOURCE_COPY
    img = Image.open(path).convert("RGB")
    if path == SOURCE:
        SOURCE_COPY.parent.mkdir(parents=True, exist_ok=True)
        img.save(SOURCE_COPY)
    return img


def clumps(tile: Image.Image) -> list[dict]:
    """Kępki z kafelka: spójne grupy pikseli innych niż tło i zmarszczki (kafelek 3x3, żeby nie ucinać na brzegach)."""
    big = Image.new("RGB", (TILE * 3, TILE * 3))
    for i in range(3):
        for j in range(3):
            big.paste(tile, (i * TILE, j * TILE))
    px = big.load()
    w, h = big.size
    seen = set()
    out, keys = [], set()
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or px[x, y] in (BG, RIPPLE):
                continue
            stack, pts = [(x, y)], []
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                pts.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny] not in (BG, RIPPLE):
                            seen.add((nx, ny))
                            stack.append((nx, ny))
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            x0, y0 = min(xs), min(ys)
            if min(xs) == 0 or min(ys) == 0 or max(xs) == w - 1 or max(ys) == h - 1 or len(pts) < 3:
                continue
            key = (x0 % TILE, y0 % TILE, len(pts))
            if key in keys:
                continue
            keys.add(key)
            out.append({"w": max(xs) - x0 + 1, "h": max(ys) - y0 + 1, "px": [(p[0] - x0, p[1] - y0, px[p]) for p in pts]})
    return out


def noise(x: float, y: float, seed: int) -> float:
    """Miękki szum zawijany na brzegach pola (suma sinusów o całkowitych okresach) - wynik 0..1."""
    r = random.Random(seed)
    v = 0.0
    for k in (1, 2, 3):
        for _ in range(2):
            ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
            v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
    return 0.5 + v / 5.0


def recolor(img: Image.Image) -> Image.Image:
    """Mętna, szaroniebieska woda (te same przesunięcia co wcześniej dla kafelka)."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = px[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h, s, v = (h + 0.1) % 1.0, s * 0.5, min(1.0, v * 1.25 + 0.06)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255))
    return img


def main() -> None:
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 15
    rnd = random.Random(seed)
    parts = clumps(load_source())
    img = Image.new("RGB", (SIZE, SIZE), BG)
    px = img.load()
    for _ in range(RIPPLES):
        x, y, n = rnd.randrange(SIZE), rnd.randrange(SIZE), rnd.randint(2, 7)
        for i in range(n):
            px[(x + i) % SIZE, y] = RIPPLE
    big = [c for c in parts if len(c["px"]) >= 12]
    for _ in range(CLUMP_TRIES):
        x, y = rnd.randrange(SIZE), rnd.randrange(SIZE)
        dense = noise(x, y, seed)
        if rnd.random() > dense ** 1.6:
            continue  # otwarta woda tam, gdzie szum niski
        c = rnd.choice(big if rnd.random() < 0.7 else parts)
        fx, fy = rnd.random() < 0.5, rnd.random() < 0.3
        for (dx, dy, col) in c["px"]:
            if fx:
                dx = c["w"] - 1 - dx
            if fy:
                dy = c["h"] - 1 - dy
            px[(x + dx) % SIZE, (y + dy) % SIZE] = col
    OUT.parent.mkdir(parents=True, exist_ok=True)
    recolor(img).save(OUT)
    print(f"{len(parts)} kępek z kafelka -> {OUT}")


if __name__ == "__main__":
    main()
