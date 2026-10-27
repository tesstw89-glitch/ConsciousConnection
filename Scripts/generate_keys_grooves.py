#!/usr/bin/env python3
"""Generate 8 original, royalty-free demo drum WAV loops per metre (4/4, 5/4, 6/8).
No external packages, services or downloads. Replace the WAVs with produced grooves later.
"""
from array import array
from math import exp, pi, sin
from pathlib import Path
import random
import wave
import sys

RATE = 44100
TEMPOS = (70, 80, 90, 100, 110, 120, 130, 140)
METERS = {"4_4": 4, "5_4": 5, "6_8": 2}


def generate(path, bpm, meter, pulses):
    beats = pulses * 2
    duration = beats * 60.0 / bpm
    frames = int(round(duration * RATE))
    samples = array("f", [0.0]) * frames
    rng = random.Random(1729 + bpm * 17 + pulses)

    def sound(start, kind, strength):
        count = min(int(RATE * (0.28 if kind == 'kick' else 0.17 if kind == 'snare' else 0.08)), frames - start)
        if count <= 0:
            return
        for i in range(count):
            t = i / RATE
            if kind == 'kick':
                phase = 2 * pi * (54 * t + 25 * (1 - exp(-28*t)) / 28)
                v = (sin(phase) * exp(-17*t) + 0.17 * rng.uniform(-1, 1) * exp(-115*t)) * 0.67
            elif kind == 'snare':
                v = (rng.uniform(-1, 1) * exp(-28*t) * 0.49 + sin(2*pi*190*t)*exp(-30*t)*0.14)
            else:
                v = rng.uniform(-1,1) * exp(-70*t) * 0.13
            samples[start + i] += v * strength

    interval = 60.0 / bpm
    for beat in range(beats):
        index = beat % pulses
        if meter == '6_8':
            sound(round(beat * interval * RATE), 'kick', 0.85 if index == 0 else 0.38)
            if index == 1:
                sound(round(beat * interval * RATE), 'snare', 0.52)
            for division in (0, 1/3, 2/3):
                sound(round((beat + division)*interval*RATE), 'hat', 0.8 if division == 0 else 0.58)
        else:
            if index == 0 or (meter == '4_4' and index == 2) or (meter == '5_4' and index == 3):
                sound(round(beat * interval * RATE), 'kick', 0.85 if index == 0 else 0.53)
            if index in (1, 3):
                sound(round(beat * interval * RATE), 'snare', 0.62 if index == 1 else 0.83)
            for division in (0, 0.5):
                sound(round((beat + division)*interval*RATE), 'hat', 0.83 if division == 0 else 0.54)

    output = array('h')
    for value in samples:
        integer = round(max(-1, min(1, value * 0.82)) * 32767)
        output.append(integer)
        output.append(integer)
    with wave.open(str(path), 'wb') as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(output.tobytes())


def main():
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    folder.mkdir(parents=True, exist_ok=True)
    existing = 0
    made = 0
    for meter, pulses in METERS.items():
        for bpm in TEMPOS:
            target = folder / f'KeysGroove_{meter}_{bpm}.wav'
            if target.exists():
                with wave.open(str(target)) as f:
                    if f.getnchannels() != 2 or f.getframerate() != RATE:
                        raise SystemExit(f'STOP: Existing groove is incompatible: {target}')
                existing += 1
                continue
            generate(target, bpm, meter, pulses)
            made += 1
    print(f'Drum WAVs ready: {made} new, {existing} existing (8 BPM choices, 3 metres).')
    print('These are generated demonstration grooves, not final produced drum tracks.')


if __name__ == '__main__':
    main()
