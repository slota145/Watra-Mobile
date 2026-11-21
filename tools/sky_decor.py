"""Ozdoby Podniebnych wysp z grafik Watry (ustalone z autorem 21.11.2026): kopiuje je do assets/watra/decor/sky/
i przebarwia zieleń - mech i porosty na szaro (wysepki nad chmurami, wiatr zdmuchuje zieleń), świecące runy menhirów
na jasny błękit wiatru (chram Strzyboga). Pozostałe piksele bez zmian.

Użycie: python tools/sky_decor.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
"""
import colorsys
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "watra" / "decor" / "sky"
# plik w Watrze -> nazwa w grze
FILES = {
	"ancient/menhir_0.png": "menhir_0.png",
	"ancient/menhir_1.png": "menhir_1.png",
	"ancient/menhir_2.png": "menhir_2.png",
	"dungeons/catacombs/pillar_2.png": "column.png",
	"dungeons/flooded/pillar_fallen.png": "column_fallen.png",
	"dungeons/catacombs/statue_1.png": "guardian.png",
	"mountains/wind_chime.png": "wind_chime.png",
	"rubble.png": "rubble.png",
	"boulder_1.png": "boulder.png",
}


def recolor(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	for y in range(img.height):
		for x in range(img.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			if 0.17 < h < 0.5 and s > 0.18:  # zieleń
				if v > 0.62 and s > 0.35:  # świecąca runa -> jasny błękit
					nr, ng, nb = colorsys.hsv_to_rgb(0.55, s * 0.75, min(1.0, v * 1.05))
				else:  # mech -> chłodna szarość
					nr, ng, nb = colorsys.hsv_to_rgb(0.6, 0.12, v * 0.95)
				px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
	return img


def main() -> None:
	src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Watra" / "assets"
	OUT.mkdir(parents=True, exist_ok=True)
	for f, name in FILES.items():
		recolor(Image.open(src / f)).save(OUT / name)
		print("->", OUT / name)


if __name__ == "__main__":
	main()
