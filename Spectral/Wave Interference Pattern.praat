# ============================================================
# Praat AudioTools - Wave Interference Pattern.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Wave Interference Pattern 
# Speed: Instant (Matrix Math).

form Wave Interference Pattern (Fast)
    comment === INTERFERENCE PARAMETERS ===
    optionmenu Preset: 1
        option Default
        option Strong Interference
        option Subtle Interference
        option Alien Radio
        option Phaser
    
    comment Pattern shape:
    positive Frequency_cutoff_hz 11000
    positive Sine_divisor 800
    positive Cosine_divisor 1200
    positive Cosine_weight 0.5
    
    comment === TONE ===
    positive Brightness_compensation 1.2
    comment (Boosts highs to prevent "dark" sound)
    
    comment === OUTPUT ===
    positive Scale_peak 0.99
    boolean Play_after_processing 1
    boolean Keep_original 1
endform

# --- 1. APPLY PRESETS ---
if preset = 2
    # Strong
    sine_divisor = 400
    cosine_divisor = 600
    cosine_weight = 0.8
    brightness_compensation = 1.5
elsif preset = 3
    # Subtle
    sine_divisor = 1200
    cosine_divisor = 2000
    cosine_weight = 0.2
    brightness_compensation = 1.1
elsif preset = 4
    # Alien Radio
    sine_divisor = 150
    cosine_divisor = 160
    cosine_weight = 0.9
    brightness_compensation = 2.0
elsif preset = 5
    # Phaser
    sine_divisor = 2000
    cosine_divisor = 2005
    cosine_weight = 1.0
    brightness_compensation = 1.0
endif

# --- 2. SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

sound = selected("Sound")
originalName$ = selected$("Sound")
original_sr = Get sampling frequency
original_dur = Get total duration

writeInfoLine: "Processing Wave Interference (Matrix Mode)..."

# --- 3. ANALYZE ---
selectObject: sound
# Force FFT for speed
spectrum = To Spectrum: "yes"

# Get resolution so we can convert Hz cutoff to Bins
dx = Get bin width
nx = Get number of bins

# Calculate Cutoff in Bins (so the math works correctly)
cutoff_bin = round(frequency_cutoff_hz / dx)
c_bin$ = fixed$(cutoff_bin, 0)

# --- 4. CONVERT TO MATRIX ---
mat_src = To Matrix
Rename: "SpectralMatrix"

# --- 5. APPLY INTERFERENCE (Matrix Formula) ---
# Prepare strings
s_div$ = fixed$(sine_divisor, 2)
c_div$ = fixed$(cosine_divisor, 2)
c_wgt$ = fixed$(cosine_weight, 4)
bright$ = fixed$(brightness_compensation, 2)
n_bins$ = string$(nx)

# The Math:
# 1. Check if we are below Cutoff Bin
# 2. Apply Interference Pattern: abs(sin(col/A) + w*cos(col/B))
# 3. Apply Brightness Compensation: (1 + (col/max)*boost)

Formula: "if col < " + c_bin$ + " then self * (abs(sin(col / " + s_div$ + ") + " + c_wgt$ + " * cos(col / " + c_div$ + "))) * (1 + (col/" + n_bins$ + ") * (" + bright$ + " - 1)) else self fi"

# --- 6. RECONSTRUCT (Robust Method) ---
# Convert Matrix -> Spectrum -> Sound
# (This initially produces a sound with the Wrong Pitch/Duration)
selectObject: mat_src
spec_out = To Spectrum
sound_tmp = To Sound

# Fix Pitch: Override sample rate to match original
selectObject: sound_tmp
Override sampling frequency: original_sr

# Fix Duration: Trim FFT padding
Extract part: 0, original_dur, "rectangular", 1, "no"
finalID = selected("Sound")

Rename: originalName$ + "_Interference"
Scale peak: scale_peak

# --- 7. CLEANUP ---
removeObject: spectrum, mat_src, spec_out, sound_tmp

if keep_original = 0
    selectObject: sound
    Remove
endif

appendInfoLine: "Done!"

if play_after_processing
    selectObject: finalID
    Play
endif