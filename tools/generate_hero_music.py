"""Compose nine original instrumental loops. No sampled or transcribed songs.

Run: python tools/generate_hero_music.py (requires numpy).
The motifs below were written for this project; WAVs are committed for players.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets/audio/heroes"
TRACKS = [
    ("ember", 116, 48, [0, 2, 4, 7, 9], [0, 2, 1, 4, 3, 1, 2, 0]),
    ("moon", 94, 45, [0, 2, 3, 7, 10], [3, 1, 0, 4, 2, 1, 3, 0]),
    ("sun", 124, 50, [0, 2, 4, 7, 9], [1, 3, 4, 2, 0, 2, 4, 3]),
    ("tide", 102, 43, [0, 2, 5, 7, 9], [0, 3, 2, 1, 4, 2, 3, 1]),
    ("comet", 128, 47, [0, 3, 5, 7, 10], [2, 4, 1, 3, 0, 4, 2, 1]),
    ("thread", 118, 52, [0, 2, 4, 7, 9], [4, 2, 0, 1, 3, 1, 4, 2]),
    ("cipher", 106, 46, [0, 2, 3, 7, 10], [0, 2, 4, 1, 2, 3, 1, 0]),
    ("prism", 90, 51, [0, 2, 5, 7, 9], [3, 4, 1, 0, 2, 4, 0, 1]),
    ("copper", 110, 41, [0, 2, 4, 7, 9], [0, 1, 3, 2, 4, 3, 1, 2]),
]

def add_tone(mix, start, duration, midi, gain, bright=0.2):
    n = int(duration * RATE)
    t = np.arange(n) / RATE
    f = 440 * 2 ** ((midi - 69) / 12)
    signal = np.sin(2*np.pi*f*t) + bright*np.sin(4*np.pi*f*t)
    envelope = np.minimum(t / 0.015, 1) * np.minimum((duration-t) / 0.08, 1)
    envelope *= np.exp(-t / max(duration, 0.1))
    indexes = (int(start * RATE) + np.arange(n)) % len(mix)
    np.add.at(mix, indexes, signal * envelope * gain)

def compose(name, bpm, root, scale, motif):
    beat = 60 / bpm
    mix = np.zeros(round(32 * beat * RATE))
    rng = np.random.default_rng(sum(map(ord, name)))
    for bar in range(8):
        chord = [0, 7, 5, 2, 0, 5, 7, 0][bar]
        for interval in [0, 7, 12]:
            add_tone(mix, bar*4*beat, beat*3.8, root+chord+interval, 0.075, 0.1)
        for pulse in range(8):
            degree = motif[(pulse+bar//2) % 8]
            note = root+12+scale[degree]
            if bar in [3,7] and pulse > 4:
                note -= 12
            add_tone(mix, (bar*4+pulse/2)*beat, beat*(0.7 if pulse % 3 else 1.1), note, 0.19, 0.25)
        for pulse in range(4):
            at = (bar*4+pulse)*beat
            add_tone(mix, at, beat*0.7, root-12+chord, 0.20)
            n = int(RATE*0.14)
            t = np.arange(n)/RATE
            drum = np.sin(2*np.pi*(70*t-90*t*t))*np.exp(-t*33)*0.28
            if pulse % 2:
                drum += rng.uniform(-1,1,n)*np.exp(-t*43)*0.13
            indexes = (int(at*RATE)+np.arange(n)) % len(mix)
            np.add.at(mix,indexes,drum)
    # Deterministic quiet echoes with wraparound keep the loop continuous.
    mix += np.roll(mix, int(beat*0.75*RATE))*0.12
    mix = np.tanh(mix)
    mix *= 0.78 / max(0.78, np.max(np.abs(mix)))
    with wave.open(str(ROOT / (name+".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((mix*32767).astype("<i2").tobytes())
    print(name, round(len(mix)/RATE, 2), "seconds")

if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    for track in TRACKS:
        compose(*track)
