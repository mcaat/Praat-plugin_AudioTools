# ============================================================
# Praat AudioTools - Frequency-Dependent Phase Manipulation
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Frequency-Dependent Phase Manipulation
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Frequency-Dependent Phase Manipulation - STEREO
# Creates wide stereo by using different phase functions for L/R

form Phase Manipulation Stereo
    positive Phase_amount 50.0
    comment Higher values = more dramatic effect
    positive Stereo_width 0.2
    comment Stereo_width: difference between L/R (0.1-1.0)
    optionmenu Phase_mode: 1
        option Comb filter (periodic notches)
        option Chaotic texture (multiple periods)
        option Spectral blur (randomized)
        option Formant-like resonances
endform

# --- 1. GET SOUND ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif
original_name$ = selected$("Sound")
original_id = selected("Sound")

# Convert to mono if stereo
selectObject: original_id
n_channels = Get number of channels
if n_channels > 1
    mono_sound = Convert to mono
else
    mono_sound = Copy: "mono_temp"
endif

writeInfoLine: "=== STEREO PHASE MANIPULATION ==="
appendInfoLine: ""

# --- 2. PROCESS LEFT CHANNEL ---
selectObject: mono_sound
spectrum_L = To Spectrum: "yes"
selectObject: spectrum_L
matrix_L = To Matrix

selectObject: matrix_L
Copy: "phase_L"
matrix_L_shifted = selected("Matrix")

selectObject: matrix_L_shifted
id_L_str$ = string$(matrix_L)

# Left channel uses base phase amount
if phase_mode = 1
    Formula: "if row = 1 then sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * cos(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * sin(2 * pi * x / 200)) else sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * sin(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * sin(2 * pi * x / 200)) fi"
elsif phase_mode = 2
    Formula: "if row = 1 then sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * cos(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * (sin(2 * pi * x / 147) + 0.7 * sin(2 * pi * x / 283) + 0.4 * sin(2 * pi * x / 521))) else sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * sin(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * (sin(2 * pi * x / 147) + 0.7 * sin(2 * pi * x / 283) + 0.4 * sin(2 * pi * x / 521))) fi"
elsif phase_mode = 3
    Formula: "if row = 1 then sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * cos(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * sin(x / 37) * sin(x / 113)) else sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * sin(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * sin(x / 37) * sin(x / 113)) fi"
elsif phase_mode = 4
    Formula: "if row = 1 then sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * cos(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * (exp(-((x - 800) / 300)^2) + exp(-((x - 1500) / 400)^2) + exp(-((x - 2500) / 500)^2))) else sqrt(object['id_L_str$', 1, col]^2 + object['id_L_str$', 2, col]^2) * sin(arctan2(object['id_L_str$', 2, col], object['id_L_str$', 1, col]) + 'phase_amount' * (exp(-((x - 800) / 300)^2) + exp(-((x - 1500) / 400)^2) + exp(-((x - 2500) / 500)^2))) fi"
endif

selectObject: matrix_L_shifted
spectrum_L_mod = To Spectrum
selectObject: spectrum_L_mod
sound_L = To Sound

appendInfoLine: "Left channel processed"

# --- 3. PROCESS RIGHT CHANNEL ---
selectObject: mono_sound
spectrum_R = To Spectrum: "yes"
selectObject: spectrum_R
matrix_R = To Matrix

selectObject: matrix_R
Copy: "phase_R"
matrix_R_shifted = selected("Matrix")

selectObject: matrix_R_shifted
id_R_str$ = string$(matrix_R)

# Right channel uses phase amount + stereo offset
phase_R = phase_amount * (1 + stereo_width)

if phase_mode = 1
    Formula: "if row = 1 then sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * cos(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * sin(2 * pi * x / 200)) else sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * sin(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * sin(2 * pi * x / 200)) fi"
elsif phase_mode = 2
    Formula: "if row = 1 then sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * cos(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * (sin(2 * pi * x / 147) + 0.7 * sin(2 * pi * x / 283) + 0.4 * sin(2 * pi * x / 521))) else sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * sin(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * (sin(2 * pi * x / 147) + 0.7 * sin(2 * pi * x / 283) + 0.4 * sin(2 * pi * x / 521))) fi"
elsif phase_mode = 3
    Formula: "if row = 1 then sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * cos(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * sin(x / 37) * sin(x / 113)) else sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * sin(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * sin(x / 37) * sin(x / 113)) fi"
elsif phase_mode = 4
    Formula: "if row = 1 then sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * cos(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * (exp(-((x - 800) / 300)^2) + exp(-((x - 1500) / 400)^2) + exp(-((x - 2500) / 500)^2))) else sqrt(object['id_R_str$', 1, col]^2 + object['id_R_str$', 2, col]^2) * sin(arctan2(object['id_R_str$', 2, col], object['id_R_str$', 1, col]) + 'phase_R' * (exp(-((x - 800) / 300)^2) + exp(-((x - 1500) / 400)^2) + exp(-((x - 2500) / 500)^2))) fi"
endif

selectObject: matrix_R_shifted
spectrum_R_mod = To Spectrum
selectObject: spectrum_R_mod
sound_R = To Sound

appendInfoLine: "Right channel processed"

# --- 4. COMBINE TO STEREO ---
selectObject: sound_L
plusObject: sound_R
stereo_sound = Combine to stereo

selectObject: stereo_sound
if phase_mode = 1
    mode_name$ = "Comb"
elsif phase_mode = 2
    mode_name$ = "Chaos"
elsif phase_mode = 3
    mode_name$ = "Blur"
else
    mode_name$ = "Formant"
endif
Rename: original_name$ + "_StereoPhase_" + mode_name$ + "_" + string$(phase_amount)
Scale peak: 0.99
Play

appendInfoLine: ""
appendInfoLine: "Done! Stereo width: ", stereo_width

# --- 5. CLEANUP ---
removeObject: mono_sound, spectrum_L, matrix_L, matrix_L_shifted, spectrum_L_mod, sound_L
removeObject: spectrum_R, matrix_R, matrix_R_shifted, spectrum_R_mod, sound_R