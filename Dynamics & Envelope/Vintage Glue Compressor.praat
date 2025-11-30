# ============================================================
# Praat AudioTools - Vintage Glue Compressor.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Vintage Glue Compressor
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Vintage Glue Compressor 
# Emulates Analog VCA compression by adding Soft-Clipping (Saturation).
# The "Warmth" parameter acts like the 'Range/Clip' on analog gear.

form Vintage Glue Compressor
    comment Preset Selection:
    optionmenu Preset 4
        option Custom
        option Vocal Opto (Slow & Warm)
        option Drum VCA (Snappy)
        option Mix Bus Glue (The Classic)
        option Tape Squeeze (Heavy Saturation)
    
    comment --- Dynamics ---
    real Threshold_dB -15.0
    positive Ratio 4.0
    positive Attack_Release_window_(s) 0.05
    
    comment --- Analog Modeling ---
    positive Analog_Warmth 0.2
    comment (0.0 = Digital Clean. 0.5 = Tube Saturation. 1.0 = Distortion)
    
    comment --- Output ---
    real Makeup_Gain_dB 2.0
    positive Scale_peak 0.99
    boolean Play_result 1
    boolean Keep_original 1
endform

# --- 1. PRESETS ---
if preset = 2
    # Vocal Opto (LA-2A Style)
    threshold_dB = -20
    ratio = 3.0
    attack_Release_window = 0.1
    makeup_Gain_dB = 3.0
    analog_Warmth = 0.3
    suf$ = "_Opto"
elsif preset = 3
    # Drum VCA (SSL Style)
    threshold_dB = -18
    ratio = 10.0
    attack_Release_window = 0.015
    makeup_Gain_dB = 4.0
    analog_Warmth = 0.5
    suf$ = "_VCA"
elsif preset = 4
    # Bus Glue (Gentle)
    threshold_dB = -10
    ratio = 2.0
    attack_Release_window = 0.1
    makeup_Gain_dB = 2.0
    analog_Warmth = 0.1
    suf$ = "_Glue"
elsif preset = 5
    # Tape Squeeze
    threshold_dB = -12
    ratio = 4.0
    attack_Release_window = 0.05
    makeup_Gain_dB = 5.0
    analog_Warmth = 0.8
    suf$ = "_Tape"
else
    suf$ = ""
endif

# --- 2. SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
original_name$ = selected$("Sound")

# Measure Input (Calibration)
in_max = Get maximum: 0, 0, "Sinc70"
in_db = 20 * log10(abs(in_max) + 0.000001)

# --- 3. RMS ENVELOPE ---
detect_freq = 3.2 / attack_Release_window
if detect_freq < 10
    detect_freq = 10
endif

selectObject: sound
intensity = To Intensity: detect_freq, 0, "yes"

# Auto-Calibration
env_max = Get maximum: 0, 0, "Parabolic"
offset = in_db - env_max
Formula: "self + offset"

# --- 4. GAIN REDUCTION ---
control_mat = Down to Matrix
t = threshold_dB
r = ratio
mkp = makeup_Gain_dB

# Digital Compression Formula
Formula: "if self > t then 10^((-1 * (self - t) * (1 - 1/r)) / 20) else 1 fi"

# Apply Makeup Gain
Formula: "self * 10^(mkp/20)"

# --- 5. APPLY COMPRESSION & SATURATION ---
selectObject: control_mat
control_sig = To Sound
Rename: "Control_Voltage"

selectObject: sound
compressed = Copy: original_name$ + "_Comp"

# Step A: Apply Gain Reduction (VCA)
Formula: "self * object(""Sound Control_Voltage"", x)"

# Step B: Analog Saturation (The "Glue")
# We use tanh() (Hyperbolic Tangent) to round off peaks nicely
if analog_Warmth > 0
    # Drive the signal into the saturator
    drive_amt = 1.0 + (analog_Warmth * 2.0)
    
    # Formula: Tanh(x * drive) / drive
    # This keeps volume roughly same but squares off the corners
    Formula: "tanh(self * drive_amt) / (drive_amt * 0.8)"
endif

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