# ============================================================
# Praat AudioTools - Phase Shaper
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Phase Shaper
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Phase Shaper
# 10 Extreme Impulse Responses for Convolution Sound Design.
# Features: "Bouncing Ball", "Cyber Glitch", "Spectral Freeze".

form Phase Shaper (Expanded)
    comment Select Radical Mode:
    optionmenu Mode 1
        option Hyper-Dispersion (5s Drone)
        option Quantum Rain (Rhythmic Smear)
        option Fractal Zap (FM Texture)
        option Reverse Black Hole (Sucking)
        option Alien Resonator (Metallic Chord)
        option Cyber Glitch (8-Bit Data)
        option The Bouncing Ball (Acceleration)
        option Deep Space (Low Rumble)
        option Spectral Freeze (Infinite Pad)
        option Demon Growl (AM Texture)
    
    comment --- Parameters ---
    positive Intensity 1.0
    comment (Controls Length, Density, or Aggression depending on mode)
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_result 1
    boolean Keep_original 1
endform

# --- 1. SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

original = selected("Sound")
original_name$ = selected$("Sound")
original_sr = Get sampling frequency
original_dur = Get total duration
num_channels = Get number of channels

# Handle Stereo
if num_channels > 1
    selectObject: original
    sound = Convert to mono
    Rename: "Mono_Temp"
else
    sound = original
endif

writeInfoLine: "Processing Phase Shaper..."

# --- 2. GENERATE IR ---
val$ = string$(intensity)
nyquist = original_sr / 2

if mode = 1
    # === HYPER DISPERSION ===
    ir_dur = 3.0 * intensity
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "0.5 * sin(2*3.14 * (50 + (" + string$(nyquist) + " - 50)/2 * x/" + string$(ir_dur) + ") * x)"
    Formula: "self * (1 - (x / " + string$(ir_dur) + "))"
    suffix$ = "_Hyper"

elsif mode = 2
    # === QUANTUM RAIN ===
    ir_dur = 2.0
    dens$ = string$(15 * intensity)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "randomGauss(0,0.5)"
    Formula: "self * (if sin(" + dens$ + " * x) > 0.9 then 1 else 0 fi) * exp(-2 * x)"
    suffix$ = "_Rain"

elsif mode = 3
    # === FRACTAL ZAP ===
    ir_dur = 0.5
    mr$ = string$(500 * intensity)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "sin(2*3.14 * (20 + 1000 * x) * x) * sin(2*3.14 * " + mr$ + " * x)"
    Formula: "self * (1 - x/" + string$(ir_dur) + ")"
    suffix$ = "_Fractal"

elsif mode = 4
    # === REVERSE BLACK HOLE ===
    ir_dur = 1.0 * intensity
    dur$ = string$(ir_dur)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "randomGauss(0, 0.2)"
    Formula: "self * exp(5 * (x - " + dur$ + "))"
    suffix$ = "_BlackHole"

elsif mode = 5
    # === ALIEN RESONATOR ===
    ir_dur = 1.0
    fb = 500 * intensity
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "(sin(2*3.14*" + string$(fb) + "*x) + sin(2*3.14*" + string$(fb*1.5) + "*x) + sin(2*3.14*" + string$(fb*2.3) + "*x)) * exp(-5*x)"
    suffix$ = "_Resonator"

elsif mode = 6
    # === CYBER GLITCH ===
    # A square wave chirp.
    # Logic: round(sin(...)) forces values to be -1 or +1 (Square Wave).
    ir_dur = 0.5 * intensity
    freq_rate$ = string$(50 * intensity)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "round(sin(2*3.14 * (100 * x + " + freq_rate$ + " * x^2)))"
    Formula: "self * (1 - x/" + string$(ir_dur) + ")"
    suffix$ = "_Glitch"

elsif mode = 7
    # === BOUNCING BALL ===
    # An accelerating impulse train.
    # sin(x^3) creates waves that get faster and faster exponentially.
    ir_dur = 1.0 * intensity
    speed$ = string$(200 * intensity)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "sin(2*3.14 * " + speed$ + " * x^3)"
    # Apply a "Gate" to turn the sine waves into tight "bounces"
    Formula: "if self > 0.9 then 1 else 0 fi"
    suffix$ = "_Bounce"

elsif mode = 8
    # === DEEP SPACE DRONE ===
    # Heavy Low-Pass filtered noise.
    ir_dur = 3.0
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "randomGauss(0,1)"
    # Filter out everything above 200Hz
    Filter (pass Hann band): 0, 200, 100
    # Long fade
    Formula: "self * (1 - x/" + string$(ir_dur) + ")"
    suffix$ = "_Space"

elsif mode = 9
    # === SPECTRAL FREEZE ===
    # Very long White Noise.
    # Convolving with long noise destroys all timing info, leaving only the "average" spectrum.
    ir_dur = 5.0 * intensity
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "randomGauss(0,0.1)"
    # Gentle envelope
    Formula: "self * (1 - x/" + string$(ir_dur) + ")"
    suffix$ = "_Freeze"

elsif mode = 10
    # === DEMON GROWL ===
    # Noise modulated by a fast, angry sub-bass (30Hz AM).
    ir_dur = 1.0
    rate$ = string$(30 * intensity)
    Create Sound from formula: "IR", 1, 0, ir_dur, original_sr, "randomGauss(0,0.5) * sin(2*3.14 * " + rate$ + " * x)"
    suffix$ = "_Demon"

endif

ir_id = selected("Sound")

# --- 3. CONVOLUTION ---
selectObject: sound
plusObject: ir_id
convolved = Convolve: "sum", "zero"
Rename: original_name$ + suffix$

# --- 4. CLEANUP ---
Scale peak: scale_peak

removeObject: ir_id
if num_channels > 1
    removeObject: sound
endif

if keep_original = 0
    selectObject: original
    Remove
endif

appendInfoLine: "Done! Applied " + suffix$

if play_result
    selectObject: convolved
    Play
endif