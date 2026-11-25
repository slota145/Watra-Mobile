"""Ozdoby lochu mrozu - Lodowe jaskinie (ustalone z autorem 25.11.2026) -> assets/watra/decor/frost/.

Rysowane generatorem (za darmo zamiast PixelLab) i z grafik Watry przebarwionych na lód:
- `crystal_0..2` - kępy kryształów lodu (ściany z jasną krawędzią od światła z góry-lewej, białe połyski, ciemny
  granatowy kontur), w grze z błękitną poświatą;
- `stalagmite_0..1` - lodowe stalagmity (wysokie stożki z soplami u podstawy);
- `frozen_warrior` - posąg wojownika z katakumb Watry uwięziony w półprzezroczystej bryle lodu;
- `boulder`, `cairn` - głazy z Watry przebarwione na zimny błękit, z czapą śniegu;
- `rubble`, `bones` - gruz i kości z Watry przebarwione, leżą na ziemi;
- `brazier`, `brazier_cold` - koksowniki z katakumb Watry bez zmian (płonący i zgaszony) dla mechaniki wymarzania
  (`ProtoFrost`);
- `assets/effects/frost_breath.png` - mroźne tchnienie Dziada Mroza: zionięcie Żmija (`assets/watra/effects/zmij_breath.png`)
  przebarwione na lodowy błękit i rozjaśnione.

Użycie: python tools/frost_decor.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
"""
import colorsys
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "watra" / "decor" / "frost"
WATRA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Watra" / "assets"
OUTLINE = (20, 30, 52, 255)
ICE = [(70, 120, 170), (104, 162, 206), (146, 202, 232), (200, 236, 250)]  # cień -> światło
WHITE = (245, 252, 255, 255)
SNOW = [(190, 206, 222), (226, 236, 246)]


def outline(img: Image.Image) -> Image.Image:
	"""Ciemny kontur 1 px wokół nieprzezroczystych pikseli."""
	px = img.load()
	w, h = img.size
	out = img.copy()
	o = out.load()
	for y in range(h):
		for x in range(w):
			if px[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 40
					for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
				o[x, y] = OUTLINE
	return out


def shard(d: ImageDraw.ImageDraw, base_x: float, base_y: float, height: float, width: float, lean: float,
		alpha=255) -> None:
	"""Jeden kryształ: wydłużony sześciokąt z lewą (jasną) i prawą (ciemną) ścianą i białym grzbietem."""
	tip = (base_x + lean, base_y - height)
	left = (base_x - width / 2, base_y - height * 0.25)
	right = (base_x + width / 2, base_y - height * 0.25)
	bl = (base_x - width * 0.35, base_y)
	br = (base_x + width * 0.35, base_y)
	mid_top = (base_x + lean * 0.85, base_y - height * 0.85)
	mid_bot = (base_x, base_y)
	d.polygon([tip, left, bl, mid_bot, mid_top], fill=ICE[2] + (alpha,))
	d.polygon([tip, mid_top, mid_bot, br, right], fill=ICE[1] + (alpha,))
	d.line([tip, mid_top, mid_bot], fill=ICE[3] + (alpha,), width=1)
	d.point((round(tip[0] - 1), round(tip[1] + 2)), fill=WHITE)


def crystal(seed: int, count: int) -> Image.Image:
	rnd = random.Random(seed)
	img = Image.new("RGBA", (34, 40), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	shards = []
	for i in range(count):
		x = 17 + rnd.uniform(-9, 9)
		h = rnd.uniform(14, 34) if i else 34
		shards.append((x, h, rnd.uniform(5, 9), rnd.uniform(-6, 6)))
	shards.sort(key=lambda s: -s[1])  # najwyższe z tyłu
	for x, h, w, lean in shards:
		shard(d, x, 38, h, w, lean)
	return outline(img)


def stalagmite(seed: int) -> Image.Image:
	rnd = random.Random(seed)
	img = Image.new("RGBA", (26, 46), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	shard(d, 13, 44, 42, 15, rnd.uniform(-2, 2))
	for x, h in ((6, 10), (20, 12), (9, 7)):
		shard(d, x, 45, h, 6, rnd.uniform(-2, 2))
	return outline(img)


def recolor(img: Image.Image, snow_cap: bool) -> Image.Image:
	"""Zimny błękit z zachowaniem jasności; `snow_cap` - górne piksele każdej kolumny bieleją (czapa śniegu)."""
	img = img.convert("RGBA")
	px = img.load()
	for y in range(img.height):
		for x in range(img.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			_h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			nr, ng, nb = colorsys.hsv_to_rgb(0.6, min(0.4, s * 0.5 + 0.1), min(1.0, v * 1.1 + 0.12))
			px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
	if snow_cap:
		for x in range(img.width):
			ys = [y for y in range(img.height) if px[x, y][3] > 0]
			if len(ys) > 4:
				for k, y in enumerate(ys[1:3]):  # pod konturem
					px[x, y] = SNOW[1 - k] + (255,)
	return img


def frozen_warrior(statue: Image.Image) -> Image.Image:
	"""Posąg przebarwiony na szary błękit w półprzezroczystej bryle lodu z jasnymi krawędziami."""
	inner = recolor(statue, False)
	w, h = inner.width + 12, inner.height + 6
	img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	img.alpha_composite(inner, (6, 4))
	block = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	d = ImageDraw.Draw(block)
	poly = [(1, h - 1), (0, h * 0.35), (5, 2), (w - 8, 0), (w - 1, h * 0.3), (w - 2, h - 1)]
	d.polygon(poly, fill=ICE[2] + (110,))
	d.line(poly + [poly[0]], fill=ICE[3] + (230,), width=1)
	d.line([(5, 6), (4, h * 0.5)], fill=WHITE, width=1)
	d.line([(w - 6, 4), (w - 4, 14)], fill=(255, 255, 255, 200), width=1)
	img.alpha_composite(block)
	return outline(img)


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	for i, (seed, n) in enumerate(((3, 4), (8, 5), (14, 3))):
		crystal(seed, n).save(OUT / f"crystal_{i}.png")
	for i in range(2):
		stalagmite(20 + i).save(OUT / f"stalagmite_{i}.png")
	frozen_warrior(Image.open(WATRA / "dungeons/catacombs/statue_1.png")).save(OUT / "frozen_warrior.png")
	recolor(Image.open(WATRA / "boulder_1.png"), True).save(OUT / "boulder.png")
	recolor(Image.open(WATRA / "mountains/cairn.png"), True).save(OUT / "cairn.png")
	recolor(Image.open(WATRA / "rubble.png"), False).save(OUT / "rubble.png")
	recolor(Image.open(WATRA / "forest/props/bones.png"), False).save(OUT / "bones.png")
	for name in ("brazier", "brazier_cold"):
		Image.open(WATRA / f"dungeons/catacombs/{name}.png").save(OUT / f"{name}.png")
	breath = Image.open(ROOT / "assets/watra/effects/zmij_breath.png").convert("RGBA")
	px = breath.load()
	for y in range(breath.height):
		for x in range(breath.width):
			r, g, b, a = px[x, y]
			if a:
				_h, sat, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
				nr, ng, nb = colorsys.hsv_to_rgb(0.55, sat * 0.55, min(1.0, v * 1.1 + 0.15))
				px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
	breath.save(ROOT / "assets/effects/frost_breath.png")
	print("->", OUT)


if __name__ == "__main__":
	main()
