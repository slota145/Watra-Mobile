"""Młot bojowy - broń ziemi (assets/weapons/hammer.png), rysowany piksel po pikselu jak kosa i katana (pixel-art,
styl Watry): trzonek w prawo, chwyt po lewej (głowica z brązu, skórzane owijki), na końcu ciężki obuch z ciemnego
granitu okuty brązem, z wykutą runą ziemi świecącą bursztynem (kolor żywiołu ziemi - Elements.COLORS). Obuch
prostopadle do trzonka, obie strony płaskie (młot dwuręczny). W grze skala 0,5 (ok. 36x18 px).
Uruchom: python tools/hammer_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 74, 36
OUTLINE = (20, 14, 10, 255)
WOOD_DARK = (58, 36, 22, 255)
WOOD = (92, 60, 36, 255)
WOOD_LIGHT = (128, 88, 54, 255)
LEATHER_DARK = (44, 28, 22, 255)
LEATHER = (74, 46, 34, 255)
BRONZE_DARK = (116, 72, 34, 255)
BRONZE = (176, 118, 54, 255)
BRONZE_LIGHT = (226, 174, 96, 255)
STONE_DARK = (54, 52, 56, 255)
STONE = (84, 80, 82, 255)
STONE_LIGHT = (118, 112, 110, 255)
STONE_HI = (150, 142, 134, 255)
RUNE = (255, 190, 90, 255)
RUNE_DIM = (214, 130, 52, 255)

SHAFT_Y = 18
HEAD = (50, 71, 3, 33)  # x od, x do, y od, y do


def main():
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	px = im.load()
	body = {}
	# trzonek
	for x in range(3, 52):
		for y in range(SHAFT_Y - 2, SHAFT_Y + 2):
			body[(x, y)] = WOOD_LIGHT if y == SHAFT_Y - 2 else (WOOD if y < SHAFT_Y + 1 else WOOD_DARK)
	# skórzane owijki przy chwycie
	for x in range(6, 20):
		for y in range(SHAFT_Y - 2, SHAFT_Y + 2):
			body[(x, y)] = LEATHER if (x + (y > SHAFT_Y - 1)) % 3 else LEATHER_DARK
	# głowica trzonka z brązu
	for x in range(1, 5):
		for y in range(SHAFT_Y - 3, SHAFT_Y + 3):
			body[(x, y)] = BRONZE_LIGHT if y == SHAFT_Y - 3 else (BRONZE if y < SHAFT_Y + 1 else BRONZE_DARK)
	# obejma pod obuchem
	for x in range(45, 51):
		for y in range(SHAFT_Y - 3, SHAFT_Y + 3):
			body[(x, y)] = BRONZE_LIGHT if y == SHAFT_Y - 3 else (BRONZE if y < SHAFT_Y + 1 else BRONZE_DARK)
	# obuch z granitu: światło z góry-lewej, ciemniej w dół i w prawo
	x0, x1, y0, y1 = HEAD
	for x in range(x0, x1):
		for y in range(y0, y1):
			if (x in (x0, x1 - 1)) and (y in (y0, y1 - 1)):
				continue  # ścięte rogi
			k = (y - y0) / (y1 - y0) + (x - x0) / (x1 - x0) * 0.4
			c = STONE_HI if k < 0.12 else (STONE_LIGHT if k < 0.45 else (STONE if k < 0.9 else STONE_DARK))
			if (x * 7 + y * 13) % 17 == 0:
				c = STONE_DARK if k < 0.9 else STONE  # ziarno kamienia
			body[(x, y)] = c
	# okucia z brązu na obu płaskich końcach obucha (góra i dół) i pas przez środek
	for x in range(x0, x1):
		for y in list(range(y0, y0 + 3)) + list(range(y1 - 3, y1)):
			if (x, y) in body:
				body[(x, y)] = BRONZE_LIGHT if y == y0 else (BRONZE if y < y1 - 1 else BRONZE_DARK)
	for y in range(y0 + 3, y1 - 3):
		for x in (x0, x0 + 1):
			body[(x, y)] = BRONZE if y < SHAFT_Y + 6 else BRONZE_DARK
	# runa ziemi (romb z kreską) świecąca bursztynem
	cx, cy = 61, 18
	for (dx, dy) in [(0, -6), (-1, -5), (1, -5), (-2, -4), (2, -4), (-3, -3), (3, -3), (-3, -2), (3, -2),
			(-2, -1), (2, -1), (-1, 0), (1, 0), (0, 1), (0, -4), (0, -3), (0, -2), (0, -1), (0, 2), (0, 3), (0, 4), (-2, 4), (2, 4)]:
		body[(cx + dx, cy + dy)] = RUNE if dy < 0 else RUNE_DIM
	# kontur
	for (x, y) in list(body):
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if (nx, ny) not in body and 0 <= nx < W and 0 <= ny < H:
				px[nx, ny] = OUTLINE
	for (x, y), c in body.items():
		px[x, y] = c
	out = os.path.join(ROOT, "assets", "weapons", "hammer.png")
	im.save(out)
	print(out)


if __name__ == "__main__":
	main()
