"""Podłoże lochu mrozu - Lodowe jaskinie (ustalone z autorem 25.11.2026): duże (SIZE x SIZE) pole bez widocznego wzoru.

Generator na wzór `tools/sky_floor.py` (za darmo zamiast PixelLab). Ziemia to płyty ciemnej, granatowej skały jaskini
(komórki Woronoja zawijane na brzegach - pole powtarza się bez szwów) ze spękaniami i jaśniejszą krawędzią od światła.
Tam, gdzie miękki szum jest wysoko, skałę skuwają tafle lodu: trzy stopnie błękitu (od cienia przy brzegu do jasnego
środka) z białymi rysami i drobnymi połyskami, a przy brzegach lodu - rozsypane drobinki szronu. Ziemia jest średnio ciemna, żeby jasne
duchy zimy (Śnieżnica, Zmarzlak) dobrze się od niej odcinały.

Użycie: python tools/frost_floor.py [ziarno]  ->  assets/watra/frost_floor.png
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "watra" / "frost_floor.png"
SIZE = 768
CELLS = 280
# tony skały jaskini (od ciemnego), spękań, jasnej krawędzi, lodu (cień przy brzegu, środek, jasny), rys i śniegu
SLATE = [(38, 46, 66), (43, 52, 73), (48, 58, 80), (54, 64, 87)]
CRACK = (22, 26, 40)
RIM = (74, 88, 114)
CLOUD = [(58, 92, 124), (78, 124, 158), (98, 150, 182), (120, 172, 200)]
ICE_SCRATCH = (178, 220, 238)
SNOW = [(150, 170, 192)]
CLOUD_SHARE = 0.67  # próg szumu: powyżej - tafla lodu
WARP = 2.0


def noise(x: float, y: float, seed: int, octaves=(1, 2, 3, 5)) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in octaves:
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.5


def wisp(x: float, y: float, seed: int) -> float:
	"""Szum obłoków rozciągnięty w poziomie (niskie częstotliwości w x, wyższe w y) - smugi niesione wiatrem."""
	r = random.Random(seed)
	v = 0.0
	for k in (1, 2, 3, 4):
		for _ in range(2):
			ax, ay, ph = r.randint(-1, 1) * k, r.randint(1, 2 * k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.0


def main() -> None:
	seed = int(sys.argv[1]) if len(sys.argv) > 1 else 35
	rnd = random.Random(seed)
	pts = [(rnd.uniform(0, SIZE), rnd.uniform(0, SIZE)) for _ in range(CELLS)]
	shade = [rnd.randrange(len(SLATE)) for _ in pts]
	B = 12
	bs = SIZE / B
	buckets = {}
	for i, (x, y) in enumerate(pts):
		buckets.setdefault((int(x // bs), int(y // bs)), []).append(i)
	img = Image.new("RGB", (SIZE, SIZE))
	px = img.load()
	cloud = [[0.0] * SIZE for _ in range(SIZE)]
	for y in range(SIZE):
		for x in range(SIZE):
			cloud[y][x] = noise(x, y, seed + 3)
	for y in range(SIZE):
		for x in range(SIZE):
			wx = x + WARP * math.sin(math.tau * 14 * y / SIZE + math.sin(math.tau * 5 * x / SIZE))
			wy = y + WARP * math.sin(math.tau * 12 * x / SIZE + math.sin(math.tau * 6 * y / SIZE))
			bx, by = int(wx // bs) % B, int(wy // bs) % B
			best = (1e9, -1, 0.0, 0.0)
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
							best = (d, i, ddx, ddy)
						elif d < second:
							second = d
			edge = second - best[0]
			if edge < 1.5:
				c = CRACK
			elif edge < 3.0 and best[2] > 0 and best[3] > 0:
				c = RIM  # krawędź płyty od strony światła (środek płyty w prawo-dół)
			else:
				c = SLATE[(shade[best[1]] + (1 if rnd.random() < 0.1 else 0)) % len(SLATE)]
				if rnd.random() < 0.04:
					c = SLATE[0]
			n = cloud[y][x]
			if n > CLOUD_SHARE:
				# obłok: stopień jasności z wysokości szumu, cień od dołu (szum niżej - niżej na ekranie)
				below = cloud[(y + 4) % SIZE][x]
				lvl = min(3, int((n - CLOUD_SHARE) / 0.035) + 1)
				if below < n - 0.006:
					lvl = max(0, lvl - 1)
				if lvl == 1 and rnd.random() < 0.5:
					lvl = 0
				c = CLOUD[lvl]
				if lvl >= 2 and (x * 7 + y * 3) % 53 == 0:
					c = ICE_SCRATCH  # połysk
				elif lvl >= 1 and abs(math.sin((x * 0.9 + y * 1.7) / 9.0 + n * 40.0)) < 0.025:
					c = ICE_SCRATCH  # cienkie rysy w lodzie
			elif n > CLOUD_SHARE - 0.05 and rnd.random() < 0.05:
				c = SNOW[0]  # szron: rozsypane drobinki przy brzegu lodu
			px[x, y] = c
	OUT.parent.mkdir(parents=True, exist_ok=True)
	img.save(OUT)
	print("->", OUT)


if __name__ == "__main__":
	main()
