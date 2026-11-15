"""Podłoże Górskich równin: duże (SIZE x SIZE) pole łąki z plamami piargu i kwiatów, z gotowych przejść Wang.

Dwa zestawy Wang z PixelLab użyte w Wietrznych Turniach Watry (pixellab_src/alpine/: scree - łąka -> piarg, flowers -
łąka -> łąka z kwiatami; po 16 kafelków 64 px z rogami „lower” / „upper”; kopie w tools/data/plains/wang_*.png
i .json). Każdy róg siatki (co 64 px) dostaje teren z miękkiego szumu (piarg - niskie wartości, kwiaty - wysokie,
pomiędzy łąka), a każde pole bierze kafelek o pasujących rogach - bez obracania kafelków (uwaga autora: obrócona
trawa wyglądała źle). Pole z piargiem bierze zestaw piargu, z kwiatami - zestaw kwiatów; róg z kwiatami, który
spotkałby piarg w jednym polu, zamienia się na łąkę w samej siatce rogów (inaczej plama kwiatów urywała się prostą
kreską na granicy pól - uwaga autora); czysta łąka losuje jeden z dwóch kafelków łąki. Szum zawija się na
brzegach - pole powtarza się bez szwów.

Użycie: python tools/plains_floor.py [ziarno]  ->  assets/watra/plains_floor.png
"""
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "tools" / "data" / "plains"
OUT = ROOT / "assets" / "watra" / "plains_floor.png"
TILE = 64
CELLS = 12
SIZE = TILE * CELLS
# progi szumu w rogach: poniżej SCREE - piarg, powyżej FLOWERS - kwiaty
SCREE = 0.38
FLOWERS = 0.64
MEADOW, GRAVEL, BLOOM = 0, 1, 2


def noise(x: float, y: float, seed: int) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in (1, 2, 3, 4):
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.0


def load_set(name: str) -> dict:
	"""Kafelki zestawu: (NW, NE, SW, SE) - True dla „upper” -> wycinek 64x64."""
	sheet = Image.open(DATA / ("wang_%s.png" % name)).convert("RGB")
	meta = json.load(open(DATA / ("wang_%s.json" % name), encoding="utf-8"))
	tiles = {}
	for t in meta["tileset_data"]["tiles"]:
		c = t["corners"]
		b = t["bounding_box"]
		key = tuple(c[k] == "upper" for k in ("NW", "NE", "SW", "SE"))
		tiles[key] = sheet.crop((b["x"], b["y"], b["x"] + b["width"], b["y"] + b["height"]))
	return tiles


def main() -> None:
	seed = int(sys.argv[1]) if len(sys.argv) > 1 else 31
	rnd = random.Random(seed)
	sets = {GRAVEL: load_set("scree"), BLOOM: load_set("flowers")}
	corners = {}
	for cy in range(CELLS):
		for cx in range(CELLS):
			v = noise(cx * TILE, cy * TILE, seed)
			corners[(cx, cy)] = GRAVEL if v < SCREE else (BLOOM if v > FLOWERS else MEADOW)
	# piarg i kwiaty nie mogą spotkać się w jednym polu (zestawy znają tylko łąkę + jeden teren): róg z kwiatami
	# przy piargu staje się łąką - w siatce rogów, więc wszystkie cztery pola wokół niego widzą to samo
	changed = True
	while changed:
		changed = False
		for cy in range(CELLS):
			for cx in range(CELLS):
				keys = [((cx + dx) % CELLS, (cy + dy) % CELLS) for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1))]
				vals = [corners[k] for k in keys]
				if GRAVEL in vals and BLOOM in vals:
					for k in keys:
						if corners[k] == BLOOM:
							corners[k] = MEADOW
							changed = True
	img = Image.new("RGB", (SIZE, SIZE))
	for cy in range(CELLS):
		for cx in range(CELLS):
			c = [corners[((cx + dx) % CELLS, (cy + dy) % CELLS)] for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1))]
			kind = GRAVEL if GRAVEL in c else (BLOOM if BLOOM in c else MEADOW)
			if kind == MEADOW:
				tile = rnd.choice([sets[GRAVEL], sets[BLOOM]])[(False, False, False, False)]
			else:
				tile = sets[kind][tuple(v == kind for v in c)]
			img.paste(tile, (cx * TILE, cy * TILE))
	OUT.parent.mkdir(parents=True, exist_ok=True)
	img.save(OUT)
	print("->", OUT)


if __name__ == "__main__":
	main()
