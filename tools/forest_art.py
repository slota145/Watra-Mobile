"""Grafiki lochu natury - Prastary Bór (ustalone z autorem 25.11.2026) z Prastarego Lasu Watry (bez generacji):
- podłoga `assets/watra/forest_floor.png` (768x768, bez szwów): kafelki mchu z Watry, a tam, gdzie miękki szum jest
  wysoko - plamy opadłych liści, gdzie nisko - gołej ziemi (kafelki Watry są powtarzalne, więc składanie po kafelkach
  nie robi szwów; brzegi plam ostre, piksel w piksel);
- ozdoby `assets/watra/decor/forest/` (dęby, sosny, pnie, kłody, omszałe głazy, menhiry, świecące grzyby, krąg grzybów,
  ciernisty krzak, szponiaste drzewo) - kopie z Watry;
- boss Leszy `assets/watra/bosses/leshy.png` (arkusz używany w Watrze - `leshy_pl.png`, 4x5 klatek 90x84; uwaga
  autora 25.11.2026: `leshy.png` w Watrze to stary, nieużywany arkusz) i jego efekty `assets/watra/effects/leshy_roots.png`,
  `leshy_leaves.png`.
Użycie: python tools/forest_art.py [ścieżka do assets Watry, domyślnie ../Watra/assets]
"""
import math
import random
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WATRA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Watra" / "assets"
SIZE = 768
TILE = 64
DECOR = {
	"tree_oak_0": "oak_0", "tree_oak_3": "oak_1", "tree_oak_7": "oak_2", "tree_pine_0": "pine_0", "tree_pine_2": "pine_1",
	"ancient_stump": "ancient_stump", "rotten_stump": "rotten_stump", "fallen_log": "fallen_log",
	"mossy_rock": "mossy_rock", "v2_mossy_rocks": "mossy_rocks", "v2_boulder": "boulder", "menhir_0": "menhir_0",
	"menhir_1": "menhir_1", "glow_shroom": "glow_shroom", "v2_mushroom_ring": "mushroom_ring",
	"tree_thorn_bush": "thorn_bush", "v2_claw_tree": "claw_tree", "v2_hollow_log": "hollow_log", "v2_stump": "stump",
}


def noise(x: float, y: float, seed: int) -> float:
	"""Miękki szum zawijany na brzegach (suma sinusów o całkowitych okresach), wynik około 0..1."""
	r = random.Random(seed)
	v = 0.0
	for k in (1, 2, 3, 5):
		for _ in range(2):
			ax, ay, ph = r.randint(-k, k), r.randint(-k, k), r.random() * math.tau
			v += math.sin(math.tau * (ax * x + ay * y) / SIZE + ph) / k
	return 0.5 + v / 5.5


def floor() -> None:
	moss = Image.open(WATRA / "ancient/ground/moss.png").convert("RGB")
	leaves = Image.open(WATRA / "ancient/ground/leaves.png").convert("RGB")
	soil = Image.open(WATRA / "ancient/ground/soil.png").convert("RGB")
	out = Image.new("RGB", (SIZE, SIZE))
	px = out.load()
	m, l, s = moss.load(), leaves.load(), soil.load()
	for y in range(SIZE):
		for x in range(SIZE):
			n = noise(x, y, 40)
			tx, ty = x % TILE, y % TILE
			px[x, y] = l[tx, ty] if n > 0.7 else (s[tx, ty] if n < 0.24 else m[tx, ty])
	out.save(ROOT / "assets/watra/forest_floor.png")


def main() -> None:
	floor()
	dest = ROOT / "assets/watra/decor/forest"
	dest.mkdir(parents=True, exist_ok=True)
	for src, name in DECOR.items():
		shutil.copyfile(WATRA / f"ancient/{src}.png", dest / f"{name}.png")
	(ROOT / "assets/watra/bosses").mkdir(parents=True, exist_ok=True)
	shutil.copyfile(WATRA / "ancient/leshy_pl.png", ROOT / "assets/watra/bosses/leshy.png")
	for fx in ("leshy_roots", "leshy_leaves"):
		shutil.copyfile(WATRA / f"effects/{fx}.png", ROOT / f"assets/watra/effects/{fx}.png")
	print("->", dest)


if __name__ == "__main__":
	main()
