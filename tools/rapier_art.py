"""Lodowy rapier - broń lodu (assets/weapons/rapier.png), rysowany piksel po pikselu jak młot i kosa (pixel-art, styl
Watry; wygląd ustalony z autorem 25.11.2026): cienka, długa klinga z przezroczystego, bladoniebieskiego lodu skierowana
w prawo (jaśniejszy grzbiet, białe refleksy, szron przy nasadzie), srebrny kosz rękojeści osłaniający dłoń, owijka
z ciemnej skóry i srebrna gałka po lewej. W grze skala 0,5 (ok. 34x9 px).
Uruchom: python tools/rapier_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 70, 20
CY = 10  # oś broni
OUTLINE = (16, 22, 34, 255)
ICE_EDGE = (120, 190, 230, 200)
ICE = (168, 226, 250, 190)
ICE_LIGHT = (214, 246, 255, 220)
ICE_WHITE = (250, 255, 255, 255)
FROST = (230, 250, 255, 255)
SILVER_DARK = (96, 104, 122, 255)
SILVER = (164, 172, 190, 255)
SILVER_LIGHT = (222, 228, 240, 255)
LEATHER_DARK = (34, 30, 44, 255)
LEATHER = (58, 52, 72, 255)


def main():
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	px = im.load()
	body = {}
	# gałka
	for x in range(1, 5):
		for y in range(CY - 2, CY + 2):
			body[(x, y)] = SILVER_LIGHT if y == CY - 2 else (SILVER if y < CY + 1 else SILVER_DARK)
	# owijka trzonu
	for x in range(5, 13):
		for y in range(CY - 1, CY + 1):
			body[(x, y)] = LEATHER if (x + y) % 2 else LEATHER_DARK
	# kosz rękojeści: łukowata osłona od jelca nad i pod trzonem (srebrne pręty)
	for y in range(CY - 6, CY + 6):
		body[(13, y)] = SILVER if y < CY else SILVER_DARK
		body[(14, y)] = SILVER_LIGHT if y < CY - 2 else SILVER
	for dx, dy in ((-1, -6), (-2, -5), (-3, -4), (-4, -3), (-1, 5), (-2, 4), (-3, 3), (-4, 2)):
		body[(13 + dx, CY + dy)] = SILVER if dy < 0 else SILVER_DARK
	for x in range(6, 10):  # pałąk wracający do gałki
		body[(x, CY - 3)] = SILVER_LIGHT
		body[(x, CY + 2)] = SILVER_DARK
	# jelec na krzyż (krótkie ramiona)
	for y in (CY - 7, CY + 6):
		body[(14, y)] = SILVER_LIGHT
	# klinga z lodu: grubsza przy nasadzie, zwęża się do szpica
	for x in range(15, 68):
		k = (x - 15) / 53
		half = 2 if k < 0.35 else (1 if k < 0.9 else 0)
		for y in range(CY - half, CY + half):
			c = ICE_LIGHT if y == CY - half else (ICE if y < CY else ICE_EDGE)
			body[(x, y)] = c
		if half == 0:
			body[(x, CY - 1)] = ICE_LIGHT
	# białe refleksy wzdłuż grzbietu i szron przy nasadzie
	for x in (20, 21, 31, 32, 33, 46, 47, 58):
		body[(x, CY - 2 if x < 34 else CY - 1)] = ICE_WHITE
	for x, y in ((15, CY - 3), (16, CY + 2), (17, CY - 3), (18, CY + 2), (16, CY - 4)):
		body[(x, y)] = FROST
	# kontur (klinga - jaśniejszy, lodowy brzeg zamiast czarnego)
	for (x, y) in list(body):
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if (nx, ny) not in body and 0 <= nx < W and 0 <= ny < H:
				px[nx, ny] = (60, 110, 150, 230) if nx >= 15 else OUTLINE
	for (x, y), c in body.items():
		px[x, y] = c
	out = os.path.join(ROOT, "assets", "weapons", "rapier.png")
	im.save(out)
	print(out)


if __name__ == "__main__":
	main()
