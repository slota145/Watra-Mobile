"""Czarna Watra - wejście do Głębin w bazie (Głębiny, decyzja autora 26.11.2026): arkusz zwykłej Watry
(assets/watra/watra.png, 6 klatek) przebarwiony bez generacji - płomienie i żar (ciepłe, nasycone piksele) na zimny
ogień Nawii: jasne końce bladofioletowe, środek fioletowy, ciemne fragmenty prawie czarne; kamienie kręgu
przyciemnione i ochłodzone. Wynik: assets/watra/black_watra.png. Uruchom: python tools/deep_watra_art.py
"""
import colorsys
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ogień Nawii od ciemnego do jasnego (po jasności piksela ognia)
FIRE = [(26, 10, 40), (62, 22, 96), (118, 52, 176), (176, 112, 232), (226, 190, 255), (248, 236, 255)]


def main():
	im = Image.open(os.path.join(ROOT, "assets/watra/watra.png")).convert("RGBA")
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			if s > 0.35 and (h < 0.17 or h > 0.95):  # ogień, żar - na fiolet Nawii
				k = min(len(FIRE) - 1, int(v * len(FIRE)))
				px[x, y] = FIRE[k] + (a,)
			else:  # kamień - ciemniej i chłodniej
				nr, ng, nb = colorsys.hsv_to_rgb(0.72, min(s * 0.6 + 0.08, 1.0), v * 0.72)
				px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
	out = os.path.join(ROOT, "assets/watra/black_watra.png")
	im.save(out)
	print(out)


if __name__ == "__main__":
	main()
