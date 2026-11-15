"""Podłoga Katakumb: duże (SIZE x SIZE) pole kamiennych płyt bez widocznego powtarzania.

Płyty układa sam generator: rzędy różnej wysokości, w każdym płyty różnej szerokości (przesunięte jak w prawdziwej
posadzce), ciemna fuga z jaśniejszym brzegiem. Ziarno kamienia losuje się z kolorów pełnego kafelka podłogi katakumb
Watry (assets/dungeons/catacombs.png, kafelek (2, 2) siatki 64 px; kopia w tools/data/catacombs_floor_src.png) -
bez jego charakterystycznych znaków, które przy powtarzaniu kafelka tworzyły wzór. Każda płyta ma trochę inną
jasność. Na wierzch idą przygaszone ślady z wystroju katakumb
Watry (tools/data/catacombs_decals/: pęknięcia, gruz, rzadko kości i krew) w losowych miejscach,
a miękki szum przyciemnia całe połacie (wilgoć, kurz). Ślady i szum zawijają się na brzegach - pole powtarza
się bez szwów (uwaga autora 15.11.2026 o zbyt powtarzalnym podłożu podziemi).

Użycie: python tools/catacombs_floor.py [ziarno]  ->  assets/watra/catacombs_floor.png
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "tools" / "data"
OUT = ROOT / "assets" / "watra" / "catacombs_floor.png"
SIZE = 768
# ślady: plik, waga losowania, krycie
DECALS = [("crack", 5, 0.55), ("rubble", 3, 0.6), ("skull_pile", 0.5, 0.7), ("blood", 0.4, 0.4)]
DECAL_COUNT = 40


def noise(x: float, y: float, seed: int) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in (1, 2, 3):
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.0


def paste_wrapped(dst: Image.Image, src: Image.Image, x: int, y: int) -> None:
	for ox in (0, -SIZE):
		for oy in (0, -SIZE):
			dst.alpha_composite(src, (x + ox, y + oy)) if x + ox + src.width > 0 and y + oy + src.height > 0 else None


def main() -> None:
	seed = int(sys.argv[1]) if len(sys.argv) > 1 else 21
	rnd = random.Random(seed)
	tile = Image.open(DATA / "catacombs_floor_src.png").convert("RGB")
	# kolory ziarna: jasne piksele kafelka (bez fug); fuga - najciemniejsze
	pixels = tile.get_flattened_data() if hasattr(tile, "get_flattened_data") else tile.getdata()
	cols = sorted(pixels, key=lambda c: sum(c))
	joint = cols[len(cols) // 40]
	grain = cols[len(cols) // 5:]
	img = Image.new("RGBA", (SIZE, SIZE))
	px = img.load()
	# rzędy płyt: wysokości sumują się do SIZE (szew w pionie znika)
	heights = []
	while sum(heights) < SIZE - 34:
		heights.append(rnd.randint(22, 32))
	heights.append(SIZE - sum(heights))
	y0 = 0
	for h in heights:
		# szerokości płyt w rzędzie (zawijane w poziomie od losowego przesunięcia)
		widths = []
		while sum(widths) < SIZE - 48:
			widths.append(rnd.randint(26, 48))
		widths.append(SIZE - sum(widths))
		x0 = rnd.randrange(SIZE)
		for w in widths:
			k = rnd.uniform(0.88, 1.1)
			for yy in range(h):
				for xx in range(w):
					x, y = (x0 + xx) % SIZE, y0 + yy
					if yy == 0 or xx == 0:
						c = joint
					elif yy == 1 or xx == 1:
						c = tuple(min(255, int(v * 1.12)) for v in rnd.choice(grain))  # jasny brzeg płyty
					elif yy == h - 1 or xx == w - 1:
						c = tuple(int(v * 0.8) for v in rnd.choice(grain))  # cień przy fudze
					else:
						c = rnd.choice(grain)
					px[x, y] = (min(255, int(c[0] * k)), min(255, int(c[1] * k)), min(255, int(c[2] * k)), 255)
			x0 += w
		y0 += h
	weights = [d[1] for d in DECALS]
	for _ in range(DECAL_COUNT):
		name, _w, alpha = rnd.choices(DECALS, weights)[0]
		d = Image.open(DATA / "catacombs_decals" / (name + ".png")).convert("RGBA")
		if rnd.random() < 0.5:
			d = d.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
		a = d.getchannel("A").point(lambda v, k=alpha: int(v * k))
		d.putalpha(a)
		paste_wrapped(img, d, rnd.randrange(SIZE), rnd.randrange(SIZE))
	px = img.load()
	for y in range(SIZE):
		for x in range(SIZE):
			k = 0.82 + 0.25 * noise(x, y, seed)
			r, g, b, a = px[x, y]
			px[x, y] = (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), 255)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	img.convert("RGB").save(OUT)
	print("->", OUT)


if __name__ == "__main__":
	main()
