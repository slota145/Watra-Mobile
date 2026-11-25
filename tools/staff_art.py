"""Kostur Leszego - broń natury (assets/weapons/staff.png), rysowany piksel po pikselu jak rapier i młot (pixel-art,
styl Watry; pomysł autora 25.11.2026): długi, sękaty kij z ciemnego drewna skierowany w prawo (chwyt po lewej),
owinięty pnączem z listkami, na końcu rozwidlenie jak małe poroże Leszego, które trzyma świecący zielony kamień
(kolor natury - Elements.COLORS), z kępką mchu u nasady. W grze skala 0,5 (ok. 38x13 px).
Uruchom: python tools/staff_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 78, 30
CY = 17  # oś kija
OUTLINE = (22, 16, 10, 255)
WOOD_DARK = (62, 40, 24, 255)
WOOD = (96, 64, 38, 255)
WOOD_LIGHT = (134, 94, 58, 255)
VINE = (58, 110, 40, 255)
LEAF = (98, 170, 62, 255)
LEAF_LIGHT = (150, 214, 92, 255)
MOSS = (76, 128, 52, 255)
GEM_DARK = (40, 140, 60, 255)
GEM = (110, 230, 110, 255)
GEM_LIGHT = (214, 255, 196, 255)


def main():
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	px = im.load()
	body = {}
	# kij: lekko falujący, grubszy przy chwycie, z sękami
	for x in range(2, 60):
		wave = round(1.2 * __import__("math").sin(x / 7.0))
		y0 = CY + wave
		half = 2 if x < 40 else 1
		for y in range(y0 - half, y0 + half):
			body[(x, y)] = WOOD_LIGHT if y == y0 - half else (WOOD if y < y0 + half - 1 else WOOD_DARK)
		if x in (14, 31, 47):  # sęki
			body[(x, y0 - half - 1)] = WOOD
			body[(x, y0 + half)] = WOOD_DARK
	# pnącze owinięte wokół kija z listkami
	for x in range(8, 56, 2):
		y = CY + round(1.2 * __import__("math").sin(x / 7.0)) + (-2 if (x // 4) % 2 else 1)
		body[(x, y)] = VINE
	for x, up in ((18, True), (27, False), (38, True), (50, False)):
		y = CY + round(1.2 * __import__("math").sin(x / 7.0)) + (-4 if up else 3)
		for dx, dy in ((0, 0), (1, 0), (0, -1 if up else 1), (1, -1 if up else 1)):
			body[(x + dx, y + dy)] = LEAF if dx == 0 else LEAF_LIGHT
	# rozwidlenie - małe poroże trzymające kamień
	for i, (dx, dy) in enumerate(((0, 0), (1, -1), (2, -2), (3, -3), (4, -4), (5, -6), (5, -7), (3, -5), (6, -8))):
		body[(59 + dx, CY - 1 + dy)] = WOOD if i % 2 else WOOD_LIGHT
	for i, (dx, dy) in enumerate(((0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 6), (5, 7), (3, 5), (6, 8))):
		body[(59 + dx, CY + dy)] = WOOD_DARK if i % 2 else WOOD
	for dx, dy in ((7, -9), (8, -9), (7, 9), (8, 9), (2, -4), (2, 4)):
		body[(59 + dx, CY + dy)] = WOOD
	# kępka mchu u nasady rozwidlenia
	for dx in range(-3, 3):
		for dy in (-2, -1, 1, 2):
			if abs(dx) + abs(dy) < 4:
				body[(57 + dx, CY + dy)] = MOSS if (dx + dy) % 2 else LEAF
	# świecący kamień w rozwidleniu
	cx, cy = 68, CY
	for dx in range(-4, 5):
		for dy in range(-4, 5):
			d = abs(dx) + abs(dy)
			if d <= 4:
				body[(cx + dx, cy + dy)] = GEM_LIGHT if d <= 1 and dx <= 0 else (GEM if d <= 3 else GEM_DARK)
	body[(cx - 2, cy - 2)] = GEM_LIGHT
	# kontur
	for (x, y) in list(body):
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if (nx, ny) not in body and 0 <= nx < W and 0 <= ny < H:
				px[nx, ny] = OUTLINE
	for (x, y), c in body.items():
		if 0 <= x < W and 0 <= y < H:
			px[x, y] = c
	out = os.path.join(ROOT, "assets", "weapons", "staff.png")
	im.save(out)
	print(out)


if __name__ == "__main__":
	main()
