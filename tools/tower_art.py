"""Grafiki lochu Arkanów - Wieża Kościeja (ustalone z autorem 26.11.2026), bez generacji PixelLab:
- podłoga `assets/watra/tower_floor.png` (768x768, bez szwów): ciemne, chłodne płyty kamienne (kwadraty 48x48
  w rzędach przesuniętych o pół płyty), każda w nieco innym odcieniu z drobnym ziarnem, fioletowe żyłki magii
  płynące przez posadzkę (zawijane na brzegach - bez szwów) i co kilkanaście płyt wyryta, słabo świecąca runa;
- ozdoby `assets/watra/decor/tower/`: regały z księgami, pulpity z księgą, stoły alchemiczne (moździerz, księga
  z czaszką), półka z fiolkami, świeczniki i kępy świec z Ostoi i Katakumb Watry; kocioł z wywarem i kryształy
  (z Kopalni i Kryształu Watry) przebarwione na fiolet Arkanów; rysowane: magiczny krąg na posadzce (2 klatki -
  pulsuje) i unoszące się runy (4 klatki - falują).
Użycie: python tools/tower_art.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
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
PLATE = 48  # płyta posadzki (768 dzieli się przez 48 - pole powtarza się bez szwów)
STONE = [(44, 40, 54), (50, 45, 60), (56, 50, 66), (62, 56, 72)]
MORTAR = (24, 20, 30)
VEIN = [(96, 58, 150), (150, 96, 220), (205, 160, 255)]
RUNE = (118, 80, 170)
ARCANE_HUE = 0.78  # fiolet Arkanów
# ozdoby z Watry: plik źródłowy -> (nazwa w grze, przebarwienie: None - bez zmian, "violet" - nasycone na fiolet,
# "dim" - przyciemnienie chłodne, żeby drewno Ostoi pasowało do ciemnej wieży)
DECOR = {
	"village/bookshelf_0.png": ("bookshelf_0", "dim"),
	"village/bookshelf_1.png": ("bookshelf_1", "dim"),
	"village/lectern.png": ("lectern", "dim"),
	"village/mortar_table.png": ("mortar_table", "dim"),
	"village/shelf.png": ("potion_shelf", "dim"),
	"dungeons/catacombs/table.png": ("alchemy_table", None),
	"village/candle_stand.png": ("candle_stand", None),
	"dungeons/catacombs/candles.png": ("candles", None),
	"village/cauldron.png": ("cauldron", "violet"),
	"dungeons/mine/crystal.png": ("crystal_0", "violet"),
	"crystal/crystal.png": ("crystal_1", "violet"),
}


def violet(c: tuple) -> tuple:
	"""Nasycony piksel (ogień, kryształ, wywar) -> fiolet Arkanów o tej samej jasności; szare zostaje."""
	r, g, b, a = c
	if a == 0:
		return c
	h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
	if s < 0.25:
		return c
	hue = ARCANE_HUE + (0.04 if v > 0.8 else 0.0)  # najjaśniejsze bardziej różowe - błysk
	rr, gg, bb = colorsys.hsv_to_rgb(hue % 1.0, min(1.0, s * 0.9), v)
	return (round(rr * 255), round(gg * 255), round(bb * 255), a)


def dim(c: tuple) -> tuple:
	"""Ciepłe drewno Ostoi -> ciemniejsze i chłodniejsze (półmrok wieży)."""
	r, g, b, a = c
	if a == 0:
		return c
	return (round(r * 0.78), round(g * 0.76), round(min(255, b * 0.86 + 8)), a)


def convert(src: Path, mode) -> Image.Image:
	im = Image.open(src).convert("RGBA")
	if mode is None:
		return im
	px = im.load()
	fn = violet if mode == "violet" else dim
	for y in range(im.height):
		for x in range(im.width):
			px[x, y] = fn(px[x, y])
	return im


def glyph(rng: random.Random, size: int) -> list:
	"""Losowa runa: kilka kresek na siatce 3x3 punktów (pionowa oś + ukośne odnogi) - lista odcinków."""
	pts = [(x, y) for y in range(3) for x in range(3)]
	segs = [((1, 0), (1, 2))]
	for _ in range(rng.randint(2, 3)):
		a, b = rng.sample(pts, 2)
		if a != b:
			segs.append((a, b))
	k = (size - 1) / 2
	return [((a[0] * k, a[1] * k), (b[0] * k, b[1] * k)) for a, b in segs]


def draw_seg(px, ox: float, oy: float, seg: tuple, color: tuple, w: int, h: int, wrap=True) -> None:
	(x0, y0), (x1, y1) = seg
	n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
	for i in range(n + 1):
		t = i / n
		x, y = round(ox + x0 + (x1 - x0) * t), round(oy + y0 + (y1 - y0) * t)
		if wrap:
			px[x % w, y % h] = color
		elif 0 <= x < w and 0 <= y < h:
			px[x, y] = color


def floor() -> None:
	rng = random.Random(51)
	out = Image.new("RGB", (SIZE, SIZE))
	px = out.load()
	n = SIZE // PLATE
	plates = {}
	for row in range(n):
		for col in range(n):
			plates[(row, col)] = (rng.choice(STONE), rng.random() < 0.06, rng.random() < 0.1, rng.randrange(1 << 30))
	for y in range(SIZE):
		row = y // PLATE
		shift = (PLATE // 2) * (row % 2)
		for x in range(SIZE):
			xx = (x + shift) % SIZE
			col = xx // PLATE
			base, _rune, cracked, seed = plates[(row, col)]
			lx, ly = xx % PLATE, y % PLATE
			if lx == 0 or ly == 0:
				px[x, y] = MORTAR
				continue
			nz = ((x * 73856093) ^ (y * 19349663) ^ seed) & 7
			c = tuple(max(0, min(255, v + (nz - 3))) for v in base)
			if lx == 1 or ly == 1:
				c = tuple(min(255, v + 9) for v in c)
			if lx == PLATE - 1 or ly == PLATE - 1:
				c = tuple(max(0, v - 10) for v in c)
			if cracked:
				r2 = random.Random(seed)
				x0, k = r2.randrange(8, PLATE - 8), r2.choice((-1, 1)) * r2.uniform(0.5, 1.3)
				if abs(lx - (x0 + k * (ly - PLATE / 2))) < 0.6 and 4 < ly < PLATE - 4:
					c = tuple(max(0, v - 9) for v in base)
			px[x, y] = c
	# wyryte runy na niektórych płytach (słabo świecące, z ciemniejszym rowkiem pod spodem)
	for (row, col), (_base, rune, _cracked, seed) in plates.items():
		if not rune:
			continue
		r2 = random.Random(seed)
		shift = (PLATE // 2) * (row % 2)
		ox = col * PLATE - shift + PLATE // 2 - 7
		oy = row * PLATE + PLATE // 2 - 7
		for seg in glyph(r2, 15):
			draw_seg(px, ox + 1, oy + 1, seg, MORTAR, SIZE, SIZE)
			draw_seg(px, ox, oy, seg, RUNE, SIZE, SIZE)
	# żyłki magii: błądzące linie (zawijane na brzegach), jasny rdzeń z ciemniejszym brzegiem
	for v in range(9):
		x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
		ang = rng.uniform(0, math.tau)
		for step in range(rng.randint(140, 260)):
			ang += rng.uniform(-0.35, 0.35)
			x += math.cos(ang)
			y += math.sin(ang)
			ix, iy = int(x) % SIZE, int(y) % SIZE
			core = step % 37 > 3  # miejscami żyłka przygasa
			for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
				q = ((ix + dx) % SIZE, (iy + dy) % SIZE)
				if px[q] not in (VEIN[1], VEIN[2]):
					px[q] = VEIN[0]
			px[ix, iy] = VEIN[2] if core and step % 11 == 0 else (VEIN[1] if core else VEIN[0])
			if rng.random() < 0.012:  # odgałęzienie
				ang += rng.choice((-1, 1)) * 0.9
	out.save(ROOT / "assets/watra/tower_floor.png")


def magic_circle() -> Image.Image:
	"""Magiczny krąg na posadzce (spłaszczony jak cienie): podwójny pierścień, runy między nimi, gwiazda w środku;
	2 klatki - druga jaśniejsza (pulsowanie)."""
	w, h = 52, 30
	im = Image.new("RGBA", (w * 2, h))
	px = im.load()
	for f in range(2):
		bright = f == 1
		edge = (200, 150, 255, 235) if bright else (150, 100, 220, 215)
		dark = (100, 62, 160, 200) if bright else (80, 50, 130, 190)
		cx, cy = w / 2 - 0.5, h / 2 - 0.5
		sq = h / w
		for y in range(h):
			for x in range(w):
				dx, dy = x - cx, (y - cy) / sq
				d = math.hypot(dx, dy)
				if 24.0 <= d <= 25.4 or 18.0 <= d <= 19.0:
					px[x + f * w, y] = edge
				elif 19.0 < d < 24.0:
					ang = math.atan2(dy, dx)
					if abs(math.sin(ang * 6)) < 0.18:  # przegródki między runami
						px[x + f * w, y] = dark
		# gwiazda (heksagram) w środku
		for i in range(6):
			a0 = i * math.tau / 6 - math.pi / 2
			a1 = a0 + 2 * math.tau / 6
			p0 = (cx + math.cos(a0) * 16, cy + math.sin(a0) * 16 * sq)
			p1 = (cx + math.cos(a1) * 16, cy + math.sin(a1) * 16 * sq)
			draw_seg(px, f * w, 0, (p0, p1), edge if bright else dark, w * 2, h, wrap=False)
		# kropki run w pierścieniu
		for i in range(6):
			a = (i + 0.5) * math.tau / 6
			x, y = round(cx + math.cos(a) * 21.5), round(cy + math.sin(a) * 21.5 * sq)
			px[x + f * w, y] = (235, 210, 255, 255) if bright else edge
	return im


def floating_runes() -> Image.Image:
	"""Unoszące się runy: trzy świecące znaki nad posadzką, w 4 klatkach falują w górę i w dół (z cieniem)."""
	w, h = 26, 26
	rng = random.Random(5)
	glyphs = [glyph(rng, 7) for _ in range(3)]
	base = [(2, 9), (10, 5), (18, 10)]
	im = Image.new("RGBA", (w * 4, h))
	px = im.load()
	for f in range(4):
		for i, g in enumerate(glyphs):
			bob = round(math.sin((f / 4 + i / 3) * math.tau) * 2)
			ox, oy = base[i][0] + f * w, base[i][1] + bob
			for seg in g:
				draw_seg(px, ox, oy + 1, seg, (70, 40, 120, 160), w * 4, h, wrap=False)
				draw_seg(px, ox, oy, seg, (215, 180, 255, 255), w * 4, h, wrap=False)
		for x in range(6, 20):  # cień pod runami
			px[x + f * w, h - 2] = (0, 0, 0, 70)
	return im


def main() -> None:
	floor()
	dest = ROOT / "assets/watra/decor/tower"
	dest.mkdir(parents=True, exist_ok=True)
	for src, (name, mode) in DECOR.items():
		convert(WATRA / src, mode).save(dest / f"{name}.png")
	magic_circle().save(dest / "magic_circle.png")
	floating_runes().save(dest / "floating_runes.png")
	print("->", dest)


if __name__ == "__main__":
	main()
