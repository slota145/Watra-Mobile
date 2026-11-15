"""Podłoże Wulkanicznych równin: duże (SIZE x SIZE) pole bazaltu z popiołem i świecącymi szczelinami lawy.

Rysowane w całości generatorem (decyzja autora 15.11.2026 - za darmo zamiast zestawu PixelLab). Ziemia to płyty
bazaltu: komórki Woronoja z losowych punktów (zawijane na brzegach - pole powtarza się bez szwów), każda płyta
w nieco innym odcieniu ciemnej szarości z drobnym ziarnem. Granice płyt to ciemne spękania; część z nich (tam, gdzie
miękki szum jest wysoko) to szczeliny lawy - żółto-pomarańczowy rdzeń z czerwoną poświatą wokół. Płyty, których
środek wypada w wysokim drugim szumie, pokrywa jaśniejszy popiół. Krawędzie płyt są lekko pofalowane (WARP).
Paleta ograniczona do kilku tonów, bez wygładzania - piksele zostają ostre.

Użycie: python tools/volcano_floor.py [ziarno]  ->  assets/watra/volcano_floor.png
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "watra" / "volcano_floor.png"
SIZE = 768
CELLS = 220
# tony bazaltu (od ciemnego), popiołu, spękań i lawy
BASALT = [(34, 30, 31), (40, 36, 36), (46, 41, 40), (52, 46, 44)]
ASH = [(70, 64, 61), (82, 75, 71)]
CRACK = (18, 15, 16)
LAVA_CORE = (255, 214, 92)
LAVA = (247, 128, 32)
LAVA_GLOW = (150, 52, 26)
LAVA_SHARE = 0.74  # próg szumu: powyżej - szczelina lawy
ASH_SHARE = 0.66  # próg szumu w środku płyty: powyżej - płyta pokryta popiołem
WARP = 2.5  # pofalowanie krawędzi płyt (px)


def noise(x: float, y: float, seed: int) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in (1, 2, 3, 5):
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.5


def main() -> None:
	seed = int(sys.argv[1]) if len(sys.argv) > 1 else 41
	rnd = random.Random(seed)
	pts = [(rnd.uniform(0, SIZE), rnd.uniform(0, SIZE)) for _ in range(CELLS)]
	shade = [rnd.randrange(len(BASALT)) for _ in pts]
	ashy = [noise(x + 300, y + 170, seed + 7) > ASH_SHARE for (x, y) in pts]
	# siatka kubełków dla szybkiego szukania najbliższych punktów (z zawijaniem)
	B = 12
	bs = SIZE / B
	buckets = {}
	for i, (x, y) in enumerate(pts):
		buckets.setdefault((int(x // bs), int(y // bs)), []).append(i)
	img = Image.new("RGB", (SIZE, SIZE))
	px = img.load()
	lava_mask = [[0] * SIZE for _ in range(SIZE)]
	for y in range(SIZE):
		for x in range(SIZE):
			# lekko pofalowany punkt - krawędzie płyt nie są idealnie proste
			# (całkowita liczba fal na bok pola - pofalowanie też zawija się bez szwu)
			wx = x + WARP * math.sin(math.tau * 14 * y / SIZE + math.sin(math.tau * 5 * x / SIZE))
			wy = y + WARP * math.sin(math.tau * 12 * x / SIZE + math.sin(math.tau * 6 * y / SIZE))
			bx, by = int(wx // bs) % B, int(wy // bs) % B
			best = (1e9, -1)
			second = 1e9
			for dx in (-2, -1, 0, 1, 2):
				for dy in (-2, -1, 0, 1, 2):
					for i in buckets.get(((bx + dx) % B, (by + dy) % B), []):
						qx, qy = pts[i]
						ddx = (qx - wx + SIZE / 2) % SIZE - SIZE / 2
						ddy = (qy - wy + SIZE / 2) % SIZE - SIZE / 2
						d = math.hypot(ddx, ddy)
						if d < best[0]:
							second = best[0]
							best = (d, i)
						elif d < second:
							second = d
			edge = second - best[0]
			n = noise(x, y, seed)
			if edge < 1.6:
				if n > LAVA_SHARE:
					lava_mask[y][x] = 2 if edge < 0.8 else 1
					px[x, y] = LAVA_CORE if edge < 0.8 else LAVA
				else:
					px[x, y] = CRACK
				continue
			if ashy[best[1]]:
				c = ASH[1] if rnd.random() < 0.3 else ASH[0]
			else:
				c = BASALT[(shade[best[1]] + (1 if rnd.random() < 0.12 else 0)) % len(BASALT)]
				if rnd.random() < 0.05:
					c = BASALT[0]
			px[x, y] = c
	# czerwona poświata wokół szczelin lawy (2 px)
	glow = img.copy()
	gpx = glow.load()
	for y in range(SIZE):
		for x in range(SIZE):
			if lava_mask[y][x]:
				continue
			near = 0
			for dx in (-2, -1, 0, 1, 2):
				for dy in (-2, -1, 0, 1, 2):
					if lava_mask[(y + dy) % SIZE][(x + dx) % SIZE]:
						near = max(near, 2 if abs(dx) <= 1 and abs(dy) <= 1 else 1)
			if near:
				r, g, b = px[x, y]
				k = 0.6 if near == 2 else 0.3
				gpx[x, y] = (int(r + (LAVA_GLOW[0] - r) * k), int(g + (LAVA_GLOW[1] - g) * k), int(b + (LAVA_GLOW[2] - b) * k))
	OUT.parent.mkdir(parents=True, exist_ok=True)
	glow.save(OUT)
	print("->", OUT)


if __name__ == "__main__":
	main()
