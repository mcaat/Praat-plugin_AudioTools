# ============================================================
# Praat AudioTools - Fractal Spectral Hologram
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Fractal Spectral Hologram
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Fractal Spectral Hologram
    comment === Presets ===
    optionmenu Preset 1
        option Custom (use settings below)
        option Subtle Shimmer
        option Crystal Echo
        option Fractal Storm
        option Temporal Shatter
        option Holographic Freeze
        option Quantum Blur
        option Granular Collapse
    
    comment === Analysis ===
    real Window_length_ms 40
    real Time_step_ms 5
    
    comment === Texture Processing ===
    real Blur_strength 0.5
    real Sharpen_strength 0.3
    real Fractal_zoom 1.2
    
    comment === Reconstruction ===
    real Output_gain_dB 0
    real Dry_wet 1.0
    boolean Play_output 1
endform

# --- APPLY PRESETS ---
if preset = 2
    # Subtle Shimmer - gentle crystalline quality
    window_length_ms = 25
    time_step_ms = 6
    blur_strength = 0.25
    sharpen_strength = 0.35
    fractal_zoom = 1.15
elsif preset = 3
    # Crystal Echo - clear holographic reflections
    window_length_ms = 45
    time_step_ms = 4
    blur_strength = 0.4
    sharpen_strength = 0.8
    fractal_zoom = 1.5
elsif preset = 4
    # Fractal Storm - chaotic temporal turbulence
    window_length_ms = 80
    time_step_ms = 25
    blur_strength = 0.75
    sharpen_strength = 1.2
    fractal_zoom = 2.3
elsif preset = 5
    # Temporal Shatter - broken time fragments
    window_length_ms = 35
    time_step_ms = 30
    blur_strength = 0.15
    sharpen_strength = 1.5
    fractal_zoom = 2.8
elsif preset = 6
    # Holographic Freeze - deep frozen texture
    window_length_ms = 150
    time_step_ms = 15
    blur_strength = 0.85
    sharpen_strength = 0.6
    fractal_zoom = 1.9
elsif preset = 7
    # Quantum Blur - extreme smear and zoom
    window_length_ms = 120
    time_step_ms = 40
    blur_strength = 0.95
    sharpen_strength = 0.1
    fractal_zoom = 2.6
elsif preset = 8
    # Granular Collapse - ultra-fragmented
    window_length_ms = 15
    time_step_ms = 12
    blur_strength = 0.5
    sharpen_strength = 1.8
    fractal_zoom = 2.2
endif

# --- SETUP & FORCE MONO ---
orig_sound = selected("Sound")
orig_name$ = selected$("Sound")

selectObject: orig_sound
n_channels = Get number of channels

if n_channels > 1
    input = Convert to mono
else
    input = Copy: "mono_temp"
endif

selectObject: input
duration = Get total duration
sf = Get sampling frequency

# Variables
win_sec = window_length_ms / 1000
step_sec = time_step_ms / 1000

# --- STEP 1: INSTANT ANALYSIS ---
selectObject: input
spectrogram = To Spectrogram: win_sec, 5000, step_sec, 20, "Gaussian"

selectObject: spectrogram
hologram = To Matrix
Rename: "hologram"
removeObject: spectrogram

# Logarithmic scaling
selectObject: hologram
Formula: "if self > 0.000001 then 10 * log10(self) else -100 endif"
Formula: "self + 100"
Formula: "if self < 0 then 0 else self endif"

# --- STEP 2: TEXTURE PROCESSING ---
# 2a. Blur
selectObject: hologram
blurred = Copy: "blurred"

blur_inv = 1 - blur_strength
str_blur$ = string$(blur_strength)
str_inv$ = string$(blur_inv)

form_blur$ = "self * " + str_blur$ + " + (self[row, col-1] * 0.25 + self * 0.5 + self[row, col+1] * 0.25) * " + str_inv$
Formula: form_blur$
form_blur2$ = "self * " + str_blur$ + " + (self[row-1, col] * 0.25 + self * 0.5 + self[row+1, col] * 0.25) * " + str_inv$
Formula: form_blur2$

# 2b. Sharpen
selectObject: hologram
sharpened = Copy: "sharpened"
str_sharp$ = string$(sharpen_strength)
form_sharp$ = "Matrix_hologram[row, col] + " + str_sharp$ + " * (Matrix_hologram[row, col] - Matrix_blurred[row, col])"
Formula: form_sharp$

# 2c. Fractal Zoom
selectObject: sharpened
zoomed = Copy: "zoomed"
nr = Get number of rows
nc = Get number of columns
cr = nr / 2
cc = nc / 2

if fractal_zoom <= 0
    fractal_zoom = 1
endif
inv_zoom = 1 / fractal_zoom

str_cr$ = string$(cr)
str_cc$ = string$(cc)
str_iz$ = string$(inv_zoom)

zoom_form$ = "Matrix_sharpened[" + str_cr$ + " + (row - " + str_cr$ + ") * " + str_iz$ + ", " + str_cc$ + " + (col - " + str_cc$ + ") * " + str_iz$ + "] * 0.7 + self * 0.3"
Formula: zoom_form$

processed = zoomed
selectObject: blurred, sharpened
Remove

# --- STEP 3: RECONSTRUCTION ---
# 1. Create Carrier Noise
noise = Create Sound from formula: "noise", 1, 0, duration, sf, "randomGauss(0, 0.2)"
noise_spec = To Spectrogram: win_sec, 5000, step_sec, 20, "Gaussian"

# 2. Get Dimensions (Explicit Selection)
selectObject: processed
nr_holo = Get number of rows
nc_holo = Get number of columns

selectObject: noise_spec
temp_mat = To Matrix
nr_spec = Get number of rows
nc_spec = Get number of columns
removeObject: temp_mat

# 3. Apply Filter
selectObject: noise_spec

r_ratio = nr_holo / nr_spec
c_ratio = nc_holo / nc_spec

str_rr$ = string$(r_ratio)
str_cr$ = string$(c_ratio)

map_form$ = "self * (10^((Matrix_zoomed[row * " + str_rr$ + ", col * " + str_cr$ + "] - 100)/10))"
Formula: map_form$

# 4. Convert Modified Spectrogram to Sound
selectObject: noise_spec
wet_sound = To Sound: sf
Rename: "wet"
Scale peak: 0.9

# --- STEP 4: MIX & FINISH ---
selectObject: orig_sound
dry_sound = Copy: "dry"
Rename: "dry"

# Trim wet sound
selectObject: wet_sound
dur_wet = Get total duration
if dur_wet > duration
    wet_sound_trim = Extract part: 0, duration, "rectangular", 1, "no"
    removeObject: wet_sound
    wet_sound = wet_sound_trim
    selectObject: wet_sound
    Rename: "wet"
endif

# Mix Calculation
str_wet$ = string$(dry_wet)
str_dry$ = string$(1 - dry_wet)

# Create final sound by copying dry and adding wet to it
selectObject: dry_sound
final = Copy: orig_name$ + "_hologram"
selectObject: final

mix_form$ = "self * " + str_dry$ + " + Sound_wet[] * " + str_wet$
Formula: mix_form$

# Gain
gain_lin = 10^(output_gain_dB / 20)
str_gain$ = string$(gain_lin)
Formula: "self * " + str_gain$

# Cleanup
selectObject: input, hologram, processed, noise, noise_spec, wet_sound, dry_sound
Remove

selectObject: final
if play_output
    Play
endif