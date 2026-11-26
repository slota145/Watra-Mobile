"""Słoneczna włócznia Dadźboga - broń Prawii (assets/weapons/spear.png), rysowana piksel po pikselu jak rapier, młot
i kosa (pixel-art, styl Watry; ustalona z autorem 26.11.2026): długie drzewce z jasnego jesionu ze złotymi okuciami,
skierowane w prawo, przy grocie złota tarcza słońca z promykami, a na końcu długi grot w kształcie liścia z białozłotą
krawędzią i jaśniejszym grzbietem; po lewej złoty tok. W grze skala 0,5 (ok. 45x9 px).
Uruchom: python tools/spear_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 92, 20
CY = 10  # oś broni
OUTLINE = (34, 22, 10, 255)
WOOD_DARK = (120, 78, 40, 255)
WOOD = (170, 118, 66, 255)
WOOD_LIGHT = (206, 156, 96, 255)
GOLD_DARK = (150, 98, 20, 255)
GOLD = (226, 170, 52, 255)
GOLD_LIGHT = (255, 222, 120, 255)
WHITE = (255, 250, 228, 255)


def main():
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	px = im.load()
	body = {}
	# tok (złota skuwka na końcu drzewca)
	for x in range(1, 5):
		for y in range(CY - 1, CY + 1):
			body[(x, y)] = GOLD_LIGHT if y == CY - 1 else GOLD_DARK
	body[(0, CY - 1)] = GOLD
	body[(0, CY)] = GOLD_DARK
	# drzewce z jesionu, dwa piksele grubości, z jaśniejszym wierzchem
	for x in range(5, 60):
		body[(x, CY - 1)] = WOOD_LIGHT if x % 7 else WOOD
		body[(x, CY)] = WOOD_DARK if x % 5 else WOOD
	# złote okucia (owijki) na drzewcu
	for x0 in (18, 30, 52):
		for x in range(x0, x0 + 2):
			body[(x, CY - 1)] = GOLD_LIGHT
			body[(x, CY)] = GOLD_DARK
	# tarcza słońca przy tulei grotu z promykami
	sx = 62
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if dx * dx + dy * dy <= 10:
				d = dx * dx + dy * dy
				body[(sx + dx, CY + dy)] = WHITE if d <= 1 else (GOLD_LIGHT if d <= 4 else GOLD)
	for dx, dy in ((0, -5), (0, 4), (-4, -4), (4, -4), (-4, 3), (4, 3)):
		body[(sx + dx, CY + dy)] = GOLD_LIGHT
	for x in range(56, 60):  # tuleja
		body[(x, CY - 2)] = GOLD
		body[(x, CY + 1)] = GOLD_DARK
	# grot w kształcie liścia: rozszerza się za tuleją, najszerszy w 1/4, długo zwęża się do szpica
	prof = [0, 1, 2, 3, 3, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0]
	for i, h in enumerate(prof):
		x = 66 + i
		for y in range(CY - 1 - h, CY + 1 + h):
			if y == CY - 1 - h and h > 0:
				c = WHITE  # białozłota krawędź od góry
			elif y < CY - 1:
				c = GOLD_LIGHT
			elif y == CY - 1:
				c = WHITE if i % 4 else GOLD_LIGHT  # jasny grzbiet
			elif y == CY + h and h > 0:
				c = GOLD_DARK
			else:
				c = GOLD
			body[(x, y)] = c
	# kontur (grot - ciepły, złotobrązowy zamiast czarnego)
	for (x, y) in list(body):
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if (nx, ny) not in body and 0 <= nx < W and 0 <= ny < H:
				px[nx, ny] = (110, 70, 16, 235) if nx >= 58 else OUTLINE
	for (x, y), c in body.items():
		px[x, y] = c
	out = os.path.join(ROOT, "assets", "weapons", "spear.png")
	im.save(out)
	print(out)


if __name__ == "__main__":
	main()
