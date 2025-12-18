# ============================================================
# Praat AudioTools - Compressor.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Dynamic range or envelope control script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Studio Dynamic Compressor 
# A professional, transparent RMS compressor with Auto-Calibration.

form Studio Dynamic Compressor
    comment Preset Selection:
    optionmenu Preset 2
        option Custom
        option Vocal Leveler (Smooth)
        option Drum Punch (Fast & Hard)
        option Mix Bus Glue (Gentle)
        option Hard Limiter (Peak Control)
        option Squash (Heavy Effect)
        option NUKE (Very Aggressive)
    
    comment --- Custom Dynamics ---
    real Threshold_dB -20.0
    positive Ratio 4.0
    
    comment --- Time Constants ---
    positive Attack_Release_window_(s) 0.05
    
    comment --- Output ---
    real Makeup_Gain_dB 2.0
    positive Scale_peak 0.99
    boolean Play_result 1
    boolean Keep_original 1
endform

# --- 1. SETUP & PRESETS ---
# Default suffix for Custom
suf$ = ""

if preset = 2
    # Vocal
    threshold_dB = -24.0
    ratio = 2.5
    attack_Release_window = 0.08
    makeup_Gain_dB = 4.0
    suf$ = "_Vocal"
elsif preset = 3
    # Drum
    threshold_dB = -18.0
    ratio = 6.0
    attack_Release_window = 0.02
    makeup_Gain_dB = 3.0
    suf$ = "_Drum"
elsif preset = 4
    # Bus
    threshold_dB = -12.0
    ratio = 1.5
    attack_Release_window = 0.1
    makeup_Gain_dB = 1.0
    suf$ = "_Bus"
elsif preset = 5
    # Limit
    threshold_dB = -6.0
    ratio = 20.0
    attack_Release_window = 0.005
    makeup_Gain_dB = 0.0
    suf$ = "_Lim"
elsif preset = 6
    # Squash
    threshold_dB = -30.0
    ratio = 10.0
    attack_Release_window = 0.05
    makeup_Gain_dB = 8.0
    suf$ = "_Squash"
elsif preset = 7
    # NUKE
    threshold_dB = -40.0
    ratio = 100.0
    attack_Release_window = 0.015
    makeup_Gain_dB = 12.0
    suf$ = "_NUKE"
endif

# --- 2. CHECK SELECTION ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
original_name$ = selected$("Sound")
dur = Get total duration

# Measure Input for Auto-Calibration
in_max = Get maximum: 0, 0, "Sinc70"
in_db = 20 * log10(abs(in_max) + 0.000001)

# --- 3. ENVELOPE GENERATION ---
detect_freq = 3.2 / attack_Release_window
if detect_freq < 10
    detect_freq = 10
endif

selectObject: sound
intensity = To Intensity: detect_freq, 0, "yes"

# [AUTO-CALIBRATION]
# Shift envelope to match Digital Scale (dBFS)
env_max = Get maximum: 0, 0, "Parabolic"
offset = in_db - env_max
Formula: "self + offset"

# --- 4. GAIN REDUCTION ---
control_mat = Down to Matrix

# Variables for Formula
t = threshold_dB
r = ratio
mkp = makeup_Gain_dB

# Compression Formula
Formula: "if self > t then 10^((-1 * (self - t) * (1 - 1/r)) / 20) else 1 fi"

# Apply Makeup Gain
Formula: "self * 10^(mkp/20)"

# --- 5. APPLY TO AUDIO ---
selectObject: control_mat
control_sig = To Sound
Rename: "Control_Voltage"

selectObject: sound
compressed = Copy: original_name$ + "_Comp"
Formula: "self * object(""Sound Control_Voltage"", x)"

# --- 6. FINALIZE ---
Scale peak: scale_peak
Rename: original_name$ + suf$

# Cleanup
removeObject: intensity, control_mat, control_sig

if play_result
    Play
endif

if keep_original = 0
    selectObject: sound
    Remove
endif

selectObject: compressed