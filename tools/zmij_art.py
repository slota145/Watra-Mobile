"""Żmij Gorynycz - boss szczytowy: arkusz z Watry i warianty z odciętymi głowami.

Uruchom: python tools/zmij_art.py [ścieżka do Watry, domyślnie ../Watra]
Czyta ../Watra/assets/world_bosses/zmij.png (8 klatek 160x160 machania skrzydłami) i zapisuje
w assets/watra/bosses/:
- zmij.png - trzy głowy (kopia z Watry),
- zmij_2.png - lewa głowa zgasła (faza 2), zmij_1.png - lewa i prawa zgasłe (faza 3);
a do assets/watra/zmij_key.png ikonę klucza: fragment klucza Welesa z Watry (assets/items/pinnacle_fragment_weles.png,
drewniany amulet ze złotym wężem) przebarwiony - wąż ognisty, drewno osmalone.
Głowy śledzi dopasowanie wzorca z klatki 0 (lekko się kołyszą). Pokonana głowa nie znika (zasłania skrzydła -
za nią nie ma rysunku), tylko gaśnie: zieleń zmienia się w popiół, a ogień w pysku i oczy w ciemny żar.
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATRA = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "..", "Watra")
SRC = os.path.join(WATRA, "assets", "world_bosses", "zmij.png")
OUT = os.path.join(ROOT, "assets", "watra", "bosses")
FRAME = 160
FRAMES = 8
## Obrys głów na klatce 0 (lewa i prawa głowa z rogami, bez skrzydeł; szyja zostaje).
HEADS = {
	"left": [(38, 33), (66, 33), (68, 44), (64, 54), (58, 60), (54, 64), (48, 69), (38, 69), (36, 55)],
	"right": [(96, 33), (121, 33), (124, 45), (126, 58), (124, 66), (110, 66), (103, 60), (97, 52), (94, 42)],
}
## Zwęglona głowa: od najciemniejszego do najjaśniejszego (popiół), tlące się szczeliny i zgasłe oczy.
ASH = [(18, 15, 17), (34, 29, 30), (54, 47, 46), (80, 71, 66)]
EMBER = [(70, 22, 14), (122, 40, 18)]
def mask_of(poly, dx=0, dy=0):
	m = Image.new("L", (FRAME, FRAME), 0)
	ImageDraw.Draw(m).polygon([(x + dx, y + dy) for x, y in poly], fill=255)
	return np.array(m) > 0


def track(frames, poly):
	"""Przesunięcie głowy w każdej klatce względem klatki 0 (najmniejsza różnica pikseli w obrysie)."""
	base = frames[0].astype(np.int32)
	m = mask_of(poly)
	ys, xs = np.nonzero(m)
	out = []
	for f in frames:
		fi = f.astype(np.int32)
		best = (1e18, 0, 0)
		for dy in range(-10, 11):
			for dx in range(-10, 11):
				y2, x2 = ys + dy, xs + dx
				ok = (y2 >= 0) & (y2 < FRAME) & (x2 >= 0) & (x2 < FRAME)
				d = np.abs(fi[y2[ok], x2[ok]] - base[ys[ok], xs[ok]]).sum() / max(ok.sum(), 1)
				if d < best[0]:
					best = (d, dx, dy)
		out.append((best[1], best[2]))
	return out


def char(frame, poly, dx, dy):
	"""Zwęgla głowę w obrysie: zieleń -> popiół, ogień w pysku i oczy -> ciemny żar."""
	f = frame.copy()
	m = mask_of(poly, dx, dy) & (f[..., 3] > 0)
	rgb = f[..., :3].astype(np.float32)
	lum = rgb @ np.array([0.3, 0.55, 0.15])
	hot = (rgb[..., 0] > 150) & (rgb[..., 0] > rgb[..., 1] + 30)  # pomarańcz i żółć: ogień, oczy, łuski
	for y, x in zip(*np.nonzero(m)):
		if hot[y, x]:
			f[y, x, :3] = EMBER[1] if lum[y, x] > 150 else EMBER[0]
		else:
			f[y, x, :3] = ASH[min(int(lum[y, x] / 34), len(ASH) - 1)]
	return f


def key_icon():
	"""Ikona klucza: złoty wąż -> ogień (żółć w środku, czerwień na brzegach), drewno ciemniejsze i cieplejsze."""
	img = np.array(Image.open(os.path.join(WATRA, "assets", "items", "pinnacle_fragment_weles.png")).convert("RGBA"))
	rgb = img[..., :3].astype(np.float32)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	gold = (r > 120) & (r - b > 60) & (img[..., 3] > 0)
	lum = (r * 0.3 + g * 0.55 + b * 0.15) / 255.0
	fire = np.stack([np.full_like(lum, 255), 60 + 190 * lum ** 1.6, 20 + 90 * lum ** 3], -1)
	wood = np.stack([r * 0.8 + 18, g * 0.62, b * 0.55], -1)
	out = np.where(gold[..., None], fire, wood)
	img[..., :3] = np.clip(out, 0, 255).astype(np.uint8)
	Image.fromarray(img).save(os.path.join(ROOT, "assets", "watra", "zmij_key.png"))


def main():
	sheet = np.array(Image.open(SRC).convert("RGBA"))
	frames = [sheet[:, i * FRAME:(i + 1) * FRAME].copy() for i in range(FRAMES)]
	offsets = {h: track(frames, HEADS[h]) for h in HEADS}
	print("przesunięcia głów:", offsets)
	two, one = [], []
	for i, f in enumerate(frames):
		a = char(f, HEADS["left"], *offsets["left"][i])
		two.append(a)
		one.append(char(a, HEADS["right"], *offsets["right"][i]))
	os.makedirs(OUT, exist_ok=True)
	Image.fromarray(sheet).save(os.path.join(OUT, "zmij.png"))
	Image.fromarray(np.concatenate(two, 1)).save(os.path.join(OUT, "zmij_2.png"))
	Image.fromarray(np.concatenate(one, 1)).save(os.path.join(OUT, "zmij_1.png"))
	key_icon()
	print("zapisano:", OUT)


if __name__ == "__main__":
	main()
