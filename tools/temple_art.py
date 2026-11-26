"""Grafiki lochu światła - Zajęta Świątynia Słońca (ustalone z autorem 26.11.2026), bez generacji PixelLab:
- podłoga `assets/watra/temple_floor.png` (768x768, bez szwów): płyty z piaskowca w rzędach przesuniętych o pół płyty
  (jak cegły), każda w nieco innym odcieniu z drobnym ziarnem, ciemniejsze spoiny, pęknięcia; co kilkanaście płyt
  płyta ze złotą intarsją słońca (krążek i promienie);
- ozdoby `assets/watra/decor/temple/`: kolumny, posągi bogów i misy z ogniem z Katakumb Watry oraz złamane kolumny
  z Zatopionych podziemi - przebarwione z szarego kamienia na ciepły piaskowiec (piksele ognia zostają), do tego
  rysowana płaska mozaika słońca na posadzce i kupka gruzu.
Użycie: python tools/temple_art.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
"""
import colorsys
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WATRA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Watra" / "assets"
SIZE = 768
PLATE_W, PLATE_H = 48, 32  # płyta posadzki (768 dzieli się przez obie - pole powtarza się bez szwów)
SAND = [(166, 136, 94), (178, 147, 102), (188, 157, 110), (198, 168, 118)]
MORTAR = (112, 88, 60)
CRACK = (128, 102, 70)
GOLD = [(176, 124, 40), (222, 172, 66), (252, 214, 112)]
# piaskowiec ozdób od cienia do światła (mapowany po jasności szarego kamienia Watry)
STONE = [(54, 40, 30), (96, 74, 52), (140, 112, 78), (182, 150, 104), (216, 186, 134), (242, 220, 170)]
# ozdoby z Watry: plik źródłowy -> nazwa w grze, czy przebarwiać też nasycone piksele (zielony kamień zatopionych ruin)
DECOR = {
	"dungeons/catacombs/pillar_0.png": ("pillar_0", False),
	"dungeons/catacombs/pillar_2.png": ("pillar_2", False), "dungeons/catacombs/statue_0.png": ("statue_0", False),
	"dungeons/catacombs/statue_1.png": ("statue_1", False), "dungeons/catacombs/statue_2.png": ("statue_2", False),
	"dungeons/catacombs/brazier.png": ("brazier", False), "dungeons/flooded/pillar_fallen.png": ("pillar_fallen", True),
	"dungeons/flooded/pillar_stump.png": ("pillar_stump", True),
}


def stone(c: tuple, force: bool) -> tuple:
	"""Szary (albo przy `force` każdy) piksel kamienia -> piaskowiec o tej samej jasności; ogień zostaje."""
	r, g, b, a = c
	if a == 0:
		return c
	h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
	if s > 0.32 and not force:
		return c  # ogień, żar - zostaje
	if force and s > 0.32 and 0.04 < h < 0.18 and v > 0.55:
		return c  # w zatopionych ruinach nie ma ognia, ale na wszelki wypadek ciepłe jasne zostaje
	k = min(len(STONE) - 1, int(v * 1.15 * len(STONE)))
	return STONE[k] + (a,)


def recolor(src: Path, force: bool) -> Image.Image:
	im = Image.open(src).convert("RGBA")
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			px[x, y] = stone(px[x, y], force)
	return im


def floor() -> None:
	rng = random.Random(41)
	out = Image.new("RGB", (SIZE, SIZE))
	px = out.load()
	rows = SIZE // PLATE_H
	cols = SIZE // PLATE_W
	plates = {}
	for row in range(rows):
		for col in range(cols):
			plates[(row, col)] = (rng.choice(SAND), rng.random() < 0.07, rng.random() < 0.25, rng.randrange(1 << 30))
	for y in range(SIZE):
		row = y // PLATE_H
		shift = (PLATE_W // 2) * (row % 2)
		for x in range(SIZE):
			xx = (x + shift) % SIZE
			col = xx // PLATE_W
			base, gold, cracked, seed = plates[(row, col)]
			lx, ly = xx % PLATE_W, y % PLATE_H
			if lx == 0 or ly == 0:
				px[x, y] = MORTAR
				continue
			n = ((x * 73856093) ^ (y * 19349663) ^ seed) & 15
			c = tuple(max(0, min(255, v + (n - 7))) for v in base)
			if lx in (1,) or ly in (1,):  # jasny brzeg płyty od góry i z lewej - lekka rzeźba
				c = tuple(min(255, v + 10) for v in c)
			if lx == PLATE_W - 1 or ly == PLATE_H - 1:
				c = tuple(max(0, v - 14) for v in c)
			if gold:  # złota intarsja słońca w środku płyty
				dx, dy = lx - PLATE_W / 2, (ly - PLATE_H / 2) * 1.4
				d = math.hypot(dx, dy)
				ang = math.atan2(dy, dx)
				if d <= 4.5:
					c = GOLD[2] if d <= 2.5 else GOLD[1]
				elif d <= 10.5 and abs(math.sin(ang * 4)) < 0.22:
					c = GOLD[0] if d > 8.5 else GOLD[1]
			if cracked:  # rysa po skosie przez płytę
				r2 = random.Random(seed)
				x0, k = r2.randrange(6, PLATE_W - 6), r2.choice((-1, 1)) * r2.uniform(0.6, 1.4)
				if abs(lx - (x0 + k * (ly - PLATE_H / 2))) < 0.6 and 3 < ly < PLATE_H - 3:
					c = CRACK
			px[x, y] = c
	out.save(ROOT / "assets/watra/temple_floor.png")


def mosaic() -> Image.Image:
	"""Płaska mozaika słońca na posadzce: złoty krążek z promieniami w spłaszczonym kole (perspektywa z góry 3/4)."""
	w, h = 44, 26
	im = Image.new("RGBA", (w, h))
	px = im.load()
	for y in range(h):
		for x in range(w):
			dx, dy = x - w / 2 + 0.5, (y - h / 2 + 0.5) * w / h
			d = math.hypot(dx, dy)
			ang = math.atan2(dy, dx)
			if d > w / 2 - 0.5:
				continue
			c = None
			if d > w / 2 - 2.0:
				c = GOLD[0]
			elif d <= 6.0:
				c = GOLD[2] if d <= 3.5 else GOLD[1]
			elif abs(math.sin(ang * 6)) < 0.25 and d < w / 2 - 4:
				c = GOLD[1] if d < 13 else GOLD[0]
			if c:
				px[x, y] = c + (235,)
	return im


def rubble() -> Image.Image:
	"""Kupka gruzu z piaskowca (płaska)."""
	rng = random.Random(7)
	im = Image.new("RGBA", (30, 16))
	px = im.load()
	for _ in range(9):
		cx, cy, r = rng.uniform(5, 25), rng.uniform(5, 12), rng.uniform(2.0, 4.0)
		for y in range(16):
			for x in range(30):
				d = math.hypot(x - cx, (y - cy) * 1.4)
				if d <= r:
					px[x, y] = STONE[1] if d > r - 1.0 else (STONE[4] if y < cy - 0.5 else STONE[3])
	return im


def main() -> None:
	floor()
	dest = ROOT / "assets/watra/decor/temple"
	dest.mkdir(parents=True, exist_ok=True)
	for src, (name, force) in DECOR.items():
		recolor(WATRA / src, force).save(dest / f"{name}.png")
	mosaic().save(dest / "sun_mosaic.png")
	rubble().save(dest / "rubble.png")
	print("->", dest)


if __name__ == "__main__":
	main()
