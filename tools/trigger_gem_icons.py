"""Ikony kamieni „rzuć, gdy…” (Odwet, Przebłysk, Stypa) z ikony istniejącego kamienia umiejętności.

Bierze owalny kamień `assets/watra/supports/echo.png` (64 px, piksele 2x2), zamalowuje jego biały znak kolorem
kamienia, przebarwia kamień na nowy kolor i rysuje nowy znak (11x11 komórek po 2 px):
- Odwet (otrzymane obrażenia) - pęknięte serce, czerwony,
- Przebłysk (trafienie krytyczne) - czteroramienna gwiazda, złoty,
- Stypa (zabicie wroga) - czaszka, ciemnozielony.
Wynik: assets/watra/supports/<nazwa>.png. Użycie: python tools/trigger_gem_icons.py
"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "assets/watra/supports/echo.png"
OUT = ROOT / "assets/watra/supports"

GLYPHS = {
	"cast_hurt": (0.0, 1.0, [
		"...........",
		".XXX...XXX.",
		"XXXXX.XXXXX",
		"XXXX.XXXXXX",
		"XXXXX.XXXXX",
		".XXXX.XXXX.",
		"..XXX.XXX..",
		"...XX.XX...",
		"....X.X....",
		".....X.....",
		"...........",
	]),
	"cast_crit": (0.12, 1.15, [
		".....X.....",
		".....X.....",
		"....XXX....",
		".X..XXX..X.",
		"..XXXXXXX..",
		"XXXXXXXXXXX",
		"..XXXXXXX..",
		".X..XXX..X.",
		"....XXX....",
		".....X.....",
		".....X.....",
	]),
	"cast_kill": (0.36, 0.55, [
		"...XXXXX...",
		"..XXXXXXX..",
		".XXXXXXXXX.",
		".XX..X..XX.",
		".XX..X..XX.",
		".XXXXXXXXX.",
		"..XXX.XXX..",
		"...XXXXX...",
		"...X.X.X...",
		"...XXXXX...",
		"...........",
	]),
}
GLYPH_COLOR = (250, 244, 226, 255)


def is_glyph(px) -> bool:
	r, g, b, a = px
	return a > 200 and min(r, g, b) > 200


def main() -> None:
	base = Image.open(BASE).convert("RGBA")
	w, h = base.size
	gem = base.copy()
	pix = gem.load()
	# znak w środku kamienia: jasne, prawie białe piksele (odblask jest w lewym górnym rogu, poza tym polem)
	mask = {(x, y) for y in range(18, 48) for x in range(16, 48) if is_glyph(pix[x, y])}
	todo = set(mask)
	while todo:  # zamalowanie znaku średnią z sąsiadów spoza niego (od brzegów do środka)
		done = []
		for (x, y) in todo:
			near = [pix[x + dx, y + dy] for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)
					if (x + dx, y + dy) not in todo and 0 <= x + dx < w and 0 <= y + dy < h and pix[x + dx, y + dy][3] > 200]
			if len(near) >= 3:
				done.append(((x, y), tuple(sum(c[i] for c in near) // len(near) for i in range(4))))
		if not done:
			break
		for (xy, c) in done:
			pix[xy] = c
			todo.discard(xy)
	for name, (hue, value, rows) in GLYPHS.items():
		im = gem.copy()
		p = im.load()
		for y in range(h):
			for x in range(w):
				r, g, b, a = p[x, y]
				if a == 0:
					continue
				hh, ll, ss = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
				if ss > 0.12:  # kamień (nie obrys i nie odblask) - nowy odcień
					rr, gg, bb = colorsys.hls_to_rgb(hue, min(ll * value, 0.95), min(ss * 1.5, 1.0))
					p[x, y] = (int(rr * 255), int(gg * 255), int(bb * 255), a)
		ox, oy = 32 - 11, 33 - 11
		for gy, row in enumerate(rows):
			for gx, ch in enumerate(row):
				if ch == "X":
					for dx in (0, 1):
						for dy in (0, 1):
							p[ox + gx * 2 + dx, oy + gy * 2 + dy] = GLYPH_COLOR
		im.save(OUT / f"{name}.png")
		print("zapisano", OUT / f"{name}.png")


if __name__ == "__main__":
	main()
