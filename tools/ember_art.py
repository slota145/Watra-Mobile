"""Iskra żaru do podnoszenia (prototyp lochu): assets/effects/ember.png.

Dwa rzędy po 4 klatki migotania: mała iskra (1 żaru, klatka 9x9) i duża (5 żaru, klatka 13x13 w rzędzie 13 px).
Rysowana w pikselach: biało-żółty środek, pomarańczowy żar, czerwony brzeg (kolory płomienia Watry).
Uruchom: python tools/ember_art.py
"""
from PIL import Image

CORE = (255, 246, 196, 255)
HOT = (255, 206, 92, 255)
EMBER = (243, 128, 40, 255)
EDGE = (176, 56, 30, 255)
CELL = 13


def ember(r: float, phase: int) -> Image.Image:
	"""Jedna klatka: koło żaru o promieniu `r`, środek przesunięty o fazę migotania."""
	img = Image.new("RGBA", (CELL, CELL))
	c = (CELL - 1) / 2
	wob = [0.0, 0.35, 0.15, -0.2][phase]
	for y in range(CELL):
		for x in range(CELL):
			# lekko spłaszczona kropla: wyższa niż szersza, czubek u góry
			dx = (x - c) / r
			dy = (y - c - 0.4) / (r * (1.25 if y < c else 1.0))
			d = (dx * dx + dy * dy) ** 0.5
			if d <= 1.0:
				col = EDGE if d > 0.8 else EMBER if d > 0.55 + wob * 0.2 else HOT if d > 0.25 + wob * 0.15 else CORE
				img.putpixel((x, y), col)
	return img


def main() -> None:
	sheet = Image.new("RGBA", (CELL * 4, CELL * 2))
	for row, r in enumerate([3.2, 4.9]):
		for f in range(4):
			sheet.alpha_composite(ember(r, f), (f * CELL, row * CELL))
	sheet.save("assets/effects/ember.png")


if __name__ == "__main__":
	main()
