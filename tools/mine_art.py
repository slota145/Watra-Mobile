"""Grafiki dziesiątego lochu - Kopalnia karłów (ustalone z autorem 26.11.2026), bez generacji PixelLab:
- podłoga `assets/watra/mine_floor.png` (768x768, bez szwów): ubita ziemia chodnika w barwach podłogi kopalni Watry
  (assets/dungeons/mine.png) - miękkie plamy jaśniejszej i ciemniejszej (wilgotnej) ziemi z drobnym ziarnem, kamyki
  z jasnym wierzchem i cieniem, rysy, błyski kruszcu (złoto, miedź) i okruchy niebieskich kryształów. Wszystko liczone
  z zawijaniem na brzegach, więc pole powtarza się bez szwów;
- ozdoby `assets/watra/decor/mine/`: gotowe grafiki kopalni Watry (assets/dungeons/mine/ - podpory z belek, wózki,
  kuźnia, kowadło, miechy, kopce rudy, kryształy, tory, kilofy...) bez goblińskich chorągwi i czaszek, do tego
  fioletowy kryształ (przebarwiony niebieski) i jaśniejsza kupka rudy;
- głazy Osuwiska `assets/watra/decor/mine/fallen_rock.png` (3 warianty w jednym pliku, rysowane - ProtoRockfall,
  odłamki Króla Karłów) i kamień z procy `sling_stone.png` (ProtoProcarz) - nie są losowane jako ozdoby.
Użycie: python tools/mine_art.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
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
# ubita ziemia chodnika (od ciemnej do jasnej) - z podłogi kopalni Watry
EARTH = [(84, 59, 35), (98, 70, 42), (110, 79, 47), (121, 87, 51), (131, 95, 56), (140, 103, 61)]
CRACK = (66, 45, 27)
PEBBLE = [(70, 62, 56), (104, 94, 84), (138, 126, 112), (172, 160, 142)]
GOLD = [(196, 140, 44), (246, 204, 92)]
COPPER = [(160, 86, 46), (214, 128, 70)]
CRYSTAL = [(70, 130, 190), (150, 214, 250)]
# ozdoby z kopalni Watry przenoszone bez zmian (plik = nazwa w grze)
DECOR = ["anvil", "bellows", "boulders", "broken_beams", "bucket", "cart", "cart_tipped", "crack", "crystal",
	"forge", "ingot_shelf", "lantern", "lumber", "nuggets", "ore_bits", "ore_heap", "ore_sacks", "pick", "picks",
	"pillar", "planks", "puddle", "rails", "rubble", "support", "tool_rack", "trough", "vein", "windlass"]


def noise(x: float, y: float, seed: int, octaves=(1, 2, 3, 5)) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in octaves:
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.5


def hash01(x: int, y: int) -> float:
	"""Losowa liczba 0..1 dla piksela (dobrze wymieszany skrót - bez wzoru kratki)."""
	h = (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def floor() -> None:
	rng = random.Random(46)
	out = Image.new("RGB", (SIZE, SIZE))
	px = out.load()
	# tablice szumów (liczone raz - sinusy dla każdego piksela w Pythonie są wolne, więc co 4 px i interpolacja)
	step = 4
	n = SIZE // step
	big = [[noise(x * step, y * step, 7) for x in range(n)] for y in range(n)]
	clods = [[noise(x * step + 53, y * step + 11, 23, (6, 9, 13, 17)) for x in range(n)] for y in range(n)]
	damp = [[noise(x * step + 211, y * step + 97, 19, (3, 5, 7, 9)) for x in range(n)] for y in range(n)]

	def sample(grid, x, y):
		gx, gy = x / step, y / step
		x0, y0 = int(gx) % n, int(gy) % n
		x1, y1 = (x0 + 1) % n, (y0 + 1) % n
		fx, fy = gx - int(gx), gy - int(gy)
		a = grid[y0][x0] * (1 - fx) + grid[y0][x1] * fx
		b = grid[y1][x0] * (1 - fx) + grid[y1][x1] * fx
		return a * (1 - fy) + b * fy

	for y in range(SIZE):
		for x in range(SIZE):
			v = sample(big, x, y) * 0.6 + sample(clods, x, y) * 0.9
			grain = hash01(x, y) - 0.5
			k = v * 4.0 + 0.2 + grain * 1.3
			if sample(damp, x, y) + (hash01(y, x) - 0.5) * 0.06 > 0.72:  # wilgotne, ciemniejsze plamy (postrzępiony brzeg)
				k -= 1.5
			k = max(0, min(len(EARTH) - 1, int(k)))
			px[x, y] = EARTH[k]

	def put(x, y, c):
		px[x % SIZE, y % SIZE] = c

	# rysy: krótkie łamane błądzenie
	for _ in range(34):
		x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
		ang = rng.uniform(0, math.tau)
		for _ in range(rng.randint(10, 26)):
			ang += rng.uniform(-0.7, 0.7)
			x += math.cos(ang)
			y += math.sin(ang) * 0.7
			put(int(x), int(y), CRACK)
	# kamyki z jasnym wierzchem i cieniem
	for _ in range(1100):
		cx, cy = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
		r = rng.choice((0.8, 1.2, 1.6, 2.2, 2.8))
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				d = math.hypot(dx, dy * 1.3)
				if d <= r:
					c = PEBBLE[2] if dy < 0 else PEBBLE[1]
					if dy <= -r * 0.5 and r > 1.5:
						c = PEBBLE[3]
					put(int(cx) + dx, int(cy) + dy, c)
				elif d <= r + 0.9 and dy > 0:
					put(int(cx) + dx, int(cy) + dy, EARTH[0])  # cień pod kamykiem
	# błyski kruszcu i kryształów
	for pal, count in ((GOLD, 150), (COPPER, 90), (CRYSTAL, 45)):
		for _ in range(count):
			x, y = rng.randrange(SIZE), rng.randrange(SIZE)
			put(x, y, pal[1])
			if rng.random() < 0.6:
				put(x + 1, y, pal[0])
				put(x, y + 1, pal[0])
	out.save(ROOT / "assets/watra/mine_floor.png")


def recolor_crystal(src: Path) -> Image.Image:
	"""Niebieski kryształ Watry -> fioletowy (ametyst); kamień u podstawy zostaje."""
	im = Image.open(src).convert("RGBA")
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			if 0.45 < h < 0.7 and s > 0.15:
				nr, ng, nb = colorsys.hsv_to_rgb((h + 0.22) % 1.0, min(1.0, s * 1.05), v)
				px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
	return im


def rock(seed: int, w: int, h: int) -> Image.Image:
	"""Głaz ze stropu: nieregularna bryła (spłaszczona elipsa z garbami), jasny wierzch, ciemny spód, rysy."""
	rng = random.Random(seed)
	im = Image.new("RGBA", (w, h))
	px = im.load()
	bumps = [(rng.uniform(0, math.tau), rng.uniform(0.92, 1.08)) for _ in range(6)]
	cx, cy = w / 2, h * 0.56
	rx, ry = w / 2 - 1.5, h * 0.44
	dark = (46, 38, 34)
	tones = [(74, 64, 58), (98, 86, 76), (124, 110, 96), (152, 138, 120), (178, 166, 146)]

	def inside(x, y):
		ang = math.atan2((y - cy) / ry, (x - cx) / rx)
		k = 1.0
		for a0, m in bumps:
			k += (m - 1.0) * max(0.0, math.cos(ang - a0)) ** 3
		return math.hypot((x - cx) / rx, (y - cy) / ry) <= k * 0.95

	for y in range(h):
		for x in range(w):
			if not inside(x + 0.5, y + 0.5):
				continue
			edge = not all(inside(x + 0.5 + dx, y + 0.5 + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
			if edge:
				px[x, y] = dark + (255,)
				continue
			# światło z lewej góry
			lx, ly = (x - cx) / rx, (y - cy) / ry
			l = -0.6 * lx - 0.8 * ly + rng.uniform(-0.15, 0.15)
			t = max(0, min(len(tones) - 1, int((l + 1.0) / 2.0 * len(tones) + 0.3)))
			px[x, y] = tones[t] + (255,)
	# rysa
	x, y = rng.uniform(w * 0.3, w * 0.6), h * 0.3
	for _ in range(int(h * 0.5)):
		x += rng.uniform(-0.8, 0.8)
		y += 1
		xi, yi = int(x), int(y)
		if 0 <= xi < w and 0 <= yi < h and px[xi, yi][3] > 0 and px[xi, yi][:3] != dark:
			px[xi, yi] = (62, 52, 46, 255)
	return im


def rocks() -> Image.Image:
	w, h = 26, 22
	sheet = Image.new("RGBA", (w * 3, h))
	for i in range(3):
		sheet.alpha_composite(rock(100 + i * 7, w, h), (w * i, 0))
	return sheet


def sling_stone() -> Image.Image:
	im = Image.new("RGBA", (7, 6))
	px = im.load()
	for y in range(6):
		for x in range(7):
			d = math.hypot(x - 3, (y - 2.6) * 1.2)
			if d <= 3.0:
				px[x, y] = (54, 44, 38, 255) if d > 2.2 else ((182, 168, 148, 255) if y < 2 and x < 4 else (128, 114, 100, 255))
	return im


def main() -> None:
	floor()
	dest = ROOT / "assets/watra/decor/mine"
	dest.mkdir(parents=True, exist_ok=True)
	src = WATRA / "dungeons/mine"
	for name in DECOR:
		Image.open(src / f"{name}.png").convert("RGBA").save(dest / f"{name}.png")
	recolor_crystal(src / "crystal.png").save(dest / "crystal_violet.png")
	rocks().save(dest / "fallen_rock.png")
	sling_stone().save(dest / "sling_stone.png")
	print("->", dest)


if __name__ == "__main__":
	main()
