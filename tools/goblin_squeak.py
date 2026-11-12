"""Pisk uciekającego goblina (gdy gracz przyzwie bossa): krótki, piskliwy skowyt opadający w dół z drżeniem.

Uruchom: python tools/goblin_squeak.py -> assets/sounds/goblin_squeak_<n>.ogg (3 odmiany, potrzebny ffmpeg).
Tylko numpy, bez dodatkowych bibliotek.
"""
import os
import subprocess
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def squeak(seed: int) -> np.ndarray:
	rng = np.random.default_rng(seed)
	dur = 0.32 + 0.06 * rng.random()
	t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
	start = 1500 + 300 * rng.random()
	# wysoki ton: szybki skok w górę i opadanie w dół, z drżeniem (trzęsący się goblin)
	freq = start * (1 + 0.25 * np.exp(-t / 0.03)) * (1 - 0.45 * t / dur)
	freq *= 1 + 0.06 * np.sin(2 * np.pi * 28 * t)
	phase = 2 * np.pi * np.cumsum(freq) / RATE
	tone = np.sin(phase) + 0.35 * np.sin(2 * phase) + 0.15 * np.sin(3 * phase)
	breath = rng.standard_normal(t.size) * 0.08
	env = np.minimum(1, t / 0.012) * np.exp(-t / (dur * 0.45))
	sig = (tone + breath) * env
	return sig / np.abs(sig).max() * 0.6


def main() -> None:
	os.makedirs(OUT, exist_ok=True)
	for n in range(3):
		data = (squeak(n) * 32767).astype(np.int16)
		tmp = os.path.join(OUT, "_tmp.wav")
		with wave.open(tmp, "wb") as w:
			w.setnchannels(1)
			w.setsampwidth(2)
			w.setframerate(RATE)
			w.writeframes(data.tobytes())
		dst = os.path.join(OUT, "goblin_squeak_%d.ogg" % n)
		subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", dst], check=True)
		os.remove(tmp)
		print(dst)


if __name__ == "__main__":
	main()
