#!/usr/bin/env python3
"""Original arcade SFX + BGM. Inspired by 1980s beat-em-ups, not copied."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SR = 22050
RNG = np.random.default_rng(1989)


def write_wav(path: Path, samples: np.ndarray, sr: int = SR) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    x = np.clip(samples, -1.0, 1.0)
    pcm = (x * 32767.0).astype(np.int16)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(f"wrote {path.relative_to(ROOT)} ({len(samples) / sr:.2f}s)")


def env(n: int, attack: float, release: float) -> np.ndarray:
    e = np.ones(n, dtype=np.float64)
    a = min(n, max(1, int(SR * attack)))
    r = min(n, max(1, int(SR * release)))
    e[:a] *= np.linspace(0.0, 1.0, a)
    e[-r:] *= np.linspace(1.0, 0.0, r)
    return e


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    if len(x) == 0:
        return x
    rc = 1.0 / (2.0 * math.pi * max(cutoff, 20.0))
    dt = 1.0 / SR
    a = dt / (rc + dt)
    y = np.empty_like(x)
    acc = 0.0
    for i, s in enumerate(x):
        acc += a * (s - acc)
        y[i] = acc
    return y


def highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    return x - lowpass(x, cutoff)


def sine(n: int, hz: float | np.ndarray) -> np.ndarray:
    t = np.arange(n) / SR
    if np.isscalar(hz):
        return np.sin(2.0 * np.pi * hz * t)
    return np.sin(2.0 * np.pi * np.cumsum(hz) / SR)


def tri(n: int, hz: float) -> np.ndarray:
    t = np.arange(n) / SR
    p = np.mod(t * hz, 1.0)
    return 2.0 * np.abs(2.0 * p - 1.0) - 1.0


def pulse(n: int, hz: float, duty: float = 0.25) -> np.ndarray:
    t = np.arange(n) / SR
    return np.where(np.mod(t * hz, 1.0) < duty, 1.0, -1.0).astype(np.float64)


def noise(n: int) -> np.ndarray:
    return RNG.uniform(-1.0, 1.0, n)


def place(buf: np.ndarray, start: int, wave: np.ndarray) -> None:
    if start >= len(buf) or start < 0:
        return
    end = min(len(buf), start + len(wave))
    buf[start:end] += wave[: end - start]


def make_swoosh() -> np.ndarray:
    dur = 0.22
    n = int(SR * dur)
    t = np.arange(n) / SR
    whoosh = noise(n)
    # closing filter: air rushing then tightening
    cut = np.linspace(4200.0, 380.0, n)
    acc = 0.0
    filtered = np.empty(n)
    for i in range(n):
        a = 1.0 / (1.0 + SR / (2.0 * math.pi * cut[i]))
        acc += a * (whoosh[i] - acc)
        filtered[i] = acc
    filtered = highpass(filtered, 180.0)
    amp = np.exp(-t * 14.0) * (1.0 - np.exp(-t * 90.0))
    blade = sine(n, np.linspace(1400.0, 220.0, n)) * np.exp(-t * 18.0)
    out = filtered * amp * 0.95 + blade * 0.28
    peak = np.max(np.abs(out)) or 1.0
    return out / peak * 0.92


def make_music() -> np.ndarray:
    bpm = 126.0
    beat = 60.0 / bpm
    bars = 16
    total_beats = bars * 4
    n = int(SR * total_beats * beat)
    drums = np.zeros(n)
    bass = np.zeros(n)
    stabs = np.zeros(n)
    lead = np.zeros(n)
    pad = np.zeros(n)

    # A minor / urban dorian palette
    pitch = {
        "E1": 41.20, "A1": 55.00, "B1": 61.74, "C2": 65.41, "D2": 73.42, "E2": 82.41,
        "F2": 87.31, "G2": 98.00, "A2": 110.00, "B2": 123.47, "C3": 130.81, "D3": 146.83,
        "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00, "B3": 246.94, "C4": 261.63,
        "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
        "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00,
    }

    def kick(nn: int) -> np.ndarray:
        t = np.arange(nn) / SR
        hz = np.linspace(138.0, 36.0, nn)
        body = np.sin(2.0 * np.pi * np.cumsum(hz) / SR)
        click = highpass(noise(nn), 1800.0) * np.exp(-t * 70.0) * 0.25
        return (body * 0.95 + click) * np.exp(-t * 16.0)

    def snare(nn: int) -> np.ndarray:
        t = np.arange(nn) / SR
        return (highpass(noise(nn), 900.0) * 0.8 + sine(nn, 190.0) * 0.22) * np.exp(-t * 20.0)

    def hat(nn: int, open_: bool = False) -> np.ndarray:
        t = np.arange(nn) / SR
        decay = 22.0 if open_ else 70.0
        return highpass(noise(nn), 5000.0) * np.exp(-t * decay) * (0.22 if open_ else 0.16)

    def bass_note(hz: float, beats: float, vol: float) -> np.ndarray:
        nn = int(SR * beats * beat)
        w = (tri(nn, hz) * 0.7 + pulse(nn, hz, 0.18) * 0.3)
        w = np.tanh(w * 1.6)
        return w * env(nn, 0.006, min(0.12, beats * beat * 0.55)) * vol

    def chord_stab(names: list[str], beats: float, vol: float) -> np.ndarray:
        nn = int(SR * beats * beat)
        w = np.zeros(nn)
        for i, nm in enumerate(names):
            det = 1.0 + (i - 1) * 0.004
            w += pulse(nn, pitch[nm] * det, 0.2) * (0.45 if i == 0 else 0.28)
        return np.tanh(w) * env(nn, 0.004, min(0.18, beats * beat * 0.7)) * vol

    def lead_note(hz: float, beats: float, vol: float) -> np.ndarray:
        nn = int(SR * beats * beat)
        w = pulse(nn, hz, 0.125) * 0.7 + pulse(nn, hz * 2.005, 0.125) * 0.18
        return w * env(nn, 0.005, min(0.14, beats * beat * 0.5)) * vol

    # Drums
    for b in range(total_beats):
        t0 = int(b * beat * SR)
        if b % 4 == 0:
            place(drums, t0, kick(int(SR * 0.16)))
        if b % 4 == 2:
            place(drums, t0, snare(int(SR * 0.12)))
        # extra kick on the 'and' of 3 in odd bars — Double Dragon push
        if b % 8 == 6:
            place(drums, t0 + int(0.5 * beat * SR), kick(int(SR * 0.10)) * 0.7)
        for sub, open_hat in ((0.0, False), (0.5, b % 4 == 3)):
            place(drums, t0 + int(sub * beat * SR), hat(int(SR * (0.09 if open_hat else 0.05)), open_hat))
        if b % 16 == 0:
            # crash-ish
            place(drums, t0, highpass(noise(int(SR * 0.45)), 2000.0) * env(int(SR * 0.45), 0.002, 0.9) * 0.18)

    # Bass ostinato
    groove = ["A2", "A2", "-", "C3", "A2", "-", "G2", "E2"]
    fill = ["E2", "G2", "A2", "C3", "D3", "C3", "B2", "G2"]
    for bar in range(bars):
        pattern = fill if bar % 4 == 3 else groove
        for i, nm in enumerate(pattern):
            if nm == "-":
                continue
            start = (bar * 4 + i * 0.5) * beat * SR
            place(bass, int(start), bass_note(pitch[nm], 0.46, 0.34))

    # Brass-ish stabs: i – VII – VI – V
    chords = [
        ["A3", "C4", "E4"],
        ["G3", "B3", "D4"],
        ["F3", "A3", "C4"],
        ["E3", "G3", "B3"],
    ]
    for bar in range(bars):
        ch = chords[bar % 4]
        # beat 1
        place(stabs, int(bar * 4 * beat * SR), chord_stab(ch, 0.45, 0.16))
        # offbeat of 2
        place(stabs, int((bar * 4 + 1.5) * beat * SR), chord_stab(ch, 0.28, 0.12))
        if bar % 2 == 1:
            place(stabs, int((bar * 4 + 3.0) * beat * SR), chord_stab(ch, 0.22, 0.10))

    # Quiet fifth pad
    for bar in range(bars):
        root = ["A2", "G2", "F2", "E2"][bar % 4]
        fifth = {"A2": "E3", "G2": "D3", "F2": "C3", "E2": "B2"}[root]
        nn = int(SR * 3.6 * beat)
        w = (tri(nn, pitch[root]) + tri(nn, pitch[fifth])) * 0.5
        place(pad, int(bar * 4 * beat * SR), w * env(nn, 0.2, 0.8) * 0.06)

    # Lead riffs on the back 8 bars, call-and-response
    riffs = [
        [("E4", 0.5), ("G4", 0.5), ("A4", 1.0), ("G4", 0.5), ("E4", 0.5), ("D4", 1.0)],
        [("C4", 0.5), ("D4", 0.5), ("E4", 1.0), ("A4", 0.5), ("G4", 0.5), ("E4", 1.0)],
        [("A4", 0.5), ("C5", 0.5), ("D5", 1.0), ("C5", 0.5), ("A4", 0.5), ("G4", 1.0)],
        [("E4", 0.5), ("D4", 0.5), ("C4", 1.0), ("A3", 2.0)],
        [("G4", 0.5), ("A4", 0.5), ("C5", 1.0), ("A4", 0.5), ("G4", 0.5), ("E4", 1.0)],
        [("D4", 0.5), ("E4", 0.5), ("G4", 1.0), ("A4", 1.0), ("E4", 1.0)],
        [("C5", 0.5), ("A4", 0.5), ("G4", 0.5), ("E4", 0.5), ("G4", 1.0), ("A4", 1.0)],
        [("E4", 1.0), ("D4", 0.5), ("C4", 0.5), ("A3", 2.0)],
    ]
    for i, riff in enumerate(riffs):
        t = (8 + i) * 4  # start at bar 9, in beats
        for name, ln in riff:
            place(lead, int(t * beat * SR), lead_note(pitch[name], ln * 0.92, 0.20))
            t += ln

    mix = drums * 0.95 + bass * 1.0 + stabs * 0.9 + lead * 0.85 + pad
    mix = np.tanh(mix * 1.15)
    # tiny loop-safe fades so the seam doesn't click
    fade = min(int(SR * 0.008), n // 8)
    mix[:fade] *= np.linspace(0.0, 1.0, fade)
    mix[-fade:] *= np.linspace(1.0, 0.0, fade)
    peak = np.max(np.abs(mix)) or 1.0
    return mix / peak * 0.88


def main() -> None:
    write_wav(ROOT / "assets" / "sfx" / "swoosh.wav", make_swoosh())
    write_wav(ROOT / "assets" / "music" / "brooklyn_fight.wav", make_music())


if __name__ == "__main__":
    main()
