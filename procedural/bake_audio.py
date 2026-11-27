"""Bake Skybound's original score and effects. Requires NumPy."""
from pathlib import Path
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1] / "audio"
RATE = 32000
RNG = np.random.default_rng(19)


def write(path, samples):
    path = ROOT / path
    path.parent.mkdir(exist_ok=True, parents=True)
    with wave.open(str(path), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())


def time(seconds):
    return np.arange(round(seconds * RATE)) / RATE


def sweep(t, start, finish):
    phase = start * t + (finish - start) * t**2 / (2 * max(t[-1], 1 / RATE))
    return np.sin(2 * np.pi * phase)


def noise(size):
    return RNG.uniform(-1, 1, size)


def effect(name, duration, signal, gain=0.65):
    t = time(duration)
    samples = signal(t) * np.minimum(t * 440, 1) * np.minimum((duration - t) * 260, 1)
    write(f"sfx/{name}.wav", samples * gain / max(np.max(np.abs(samples)), 0.01))


effect("jump", .18, lambda t: (sweep(t, 290, 890) + .28 * sweep(t, 590, 2010)) * np.exp(-15*t))
effect("land", .14, lambda t: (.8 * sweep(t, 115, 43) + .23 * noise(t.size)) * np.exp(-28*t))
effect("punch", .15, lambda t: (.75 * noise(t.size) * np.sin(np.pi*t/.15)**2
                              + .6 * sweep(t, 190, 68)) * np.exp(-17*t))
effect("pound", .28, lambda t: (sweep(t, 112, 38) + .32 * sweep(t, 310, 76)
                              + .35 * noise(t.size) * np.exp(-22*t)) * np.exp(-11*t))
effect("coin", .21, lambda t: np.sin(2*np.pi*(1046*t + 522*np.maximum(0, t-.045)))
       * np.exp(-12*t) + .24*np.sin(2*np.pi*3136*t)*np.exp(-23*t))
effect("stomp", .20, lambda t: (.72 * sweep(t, 280, 88) + .24 * noise(t.size)) * np.exp(-18*t)
       + .33 * sweep(t, 305, 560) * np.exp(-46*(t-.075)**2/.20))
effect("hurt", .28, lambda t: (sweep(t, 420, 165) + .45 * sweep(t, 872, 333)
                              + .28 * sweep(t, 627, 241)) * np.exp(-9*t))
effect("crystal", .40, lambda t: (.58*np.sin(2*np.pi*784*t) + .35*np.sin(2*np.pi*1175*t)
       + .16*np.sin(2*np.pi*1568*t)) * np.exp(-7*t))
effect("heal", .33, lambda t: np.sin(2*np.pi*(523*t + 136*np.maximum(0, t-.07)
       + 125*np.maximum(0, t-.14))) * np.exp(-7*t))
effect("checkpoint", .38, lambda t: (np.sin(2*np.pi*523*t) + .45*np.sin(2*np.pi*784*t)
       + .28*np.sin(2*np.pi*1046*t)) * np.exp(-7.5*t))
effect("crate", .19, lambda t: (.58 * noise(t.size) + sweep(t, 350, 138)
       + .29 * sweep(t, 950, 326)) * np.exp(-23*t))
effect("dash", .22, lambda t: (.51 * noise(t.size) + .65 * sweep(t, 180, 620))
       * np.sin(np.pi*t/.22) * np.exp(-7*t))
effect("ui", .10, lambda t: (.7 * sweep(t, 720, 509) + .26 * sweep(t, 980, 710))
       * np.exp(-30*t))

# Two bars of intro and an eight-bar loop at 100 BPM, with a soft plucked lead,
# bass, chord voicings and brushed percussion.
BEAT = .60
INTRO = 8
LOOP = 32
samples = np.zeros(round((INTRO + LOOP) * BEAT * RATE), dtype=np.float64)
loop_start = round(INTRO * BEAT * RATE)


def add(beat, phrase):
    start = round(beat * BEAT * RATE)
    end = min(loop_start if beat < INTRO else len(samples), start + len(phrase))
    samples[start:end] += phrase[:end-start]
    if beat >= INTRO and start + len(phrase) > len(samples):
        tail = phrase[end-start:]
        samples[loop_start:loop_start+len(tail)] += tail


def note(beat, midi, duration, gain, instrument):
    seconds = duration * BEAT
    t = time(seconds)
    f = 440 * 2**((midi - 69)/12)
    phase = 2*np.pi*f*t
    attack = np.minimum(t*75, 1)
    release = np.minimum((seconds-t)*25, 1)
    if instrument == "lead":
        tone = np.sin(phase) + .32*np.sin(2*phase)*np.exp(-8*t) + .12*np.sin(3*phase)*np.exp(-17*t)
        envelope = np.exp(-4.4*t)
    elif instrument == "bass":
        tone = np.sin(phase) + .18*np.sin(2*phase)
        envelope = np.exp(-2.7*t)
    else:
        tone = .8*np.sin(phase) + .19*np.sin(2*np.pi*(f+.42)*t) + .15*np.sin(2*phase)
        envelope = np.exp(-2*t)
    add(beat, gain * tone * envelope * attack * release)


chords = [
    (55, 59, 62, 66), (57, 61, 64, 67),
    (50, 54, 57, 64), (54, 57, 61, 64), (55, 59, 62, 66), (52, 55, 59, 66),
    (50, 54, 57, 61), (47, 50, 54, 57), (55, 59, 62, 64), (57, 61, 64, 67),
]
melody = [
    [None, 71, 74, 78, 76, None, 74, None],
    [73, None, 76, 79, 76, 73, None, 69],
    [74, None, 76, 78, 81, None, 78, 76],
    [73, None, 76, 78, 81, 83, 81, None],
    [79, 78, 74, None, 71, 74, 78, None],
    [76, None, 78, 79, 83, None, 81, 79],
    [78, 76, 74, None, 69, 73, 74, None],
    [71, None, 74, 78, 81, None, 78, 74],
    [79, 78, 76, None, 74, 71, 74, 76],
    [73, None, 76, 79, 81, 79, 76, 73],
]
for bar, (chord, notes) in enumerate(zip(chords, melody)):
    start = bar*4
    for i, pitch in enumerate(chord * 2):
        note(start+i*.5, pitch+12, .9, .042, "pluck")
    for beat, pitch in ((0, chord[0]-12), (1.5, chord[2]-12), (2.5, chord[0]-12)):
        note(start+beat, pitch, 1.3, .12, "bass")
    for i, pitch in enumerate(notes):
        if pitch is not None:
            note(start+i*.5, pitch, .85, .15, "lead")
    if bar >= 2:
        for i in range(8):
            t = time(.065)
            brush = noise(t.size)
            add(start+i*.5, .027 * np.diff(brush, prepend=0) * np.exp(-75*t) * np.minimum(t*850, 1))
        for beat in (0, 2.5):
            t = time(.15)
            add(start+beat, .073 * sweep(t, 93, 42) * np.exp(-27*t) * np.minimum(t*350, 1))

# Taper the intro ends. The loop begins on its own downbeat with the previous bar's tails.
fade_in = round(.045*RATE)
fade_out = round(.018*RATE)
samples[:fade_in] *= np.linspace(0, 1, fade_in)
samples[loop_start-fade_out:loop_start] *= np.linspace(1, 0, fade_out)
write("music/celestial_gardens_intro.wav", samples[:loop_start]*.88)
write("music/celestial_gardens_loop.wav", samples[loop_start:]*.88)
