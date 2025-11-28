# ============================================================
# Praat AudioTools - Karplus-Strong Modulator .praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Karplus-Strong Modulator  script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# ============================================================
# Karplus-Strong Modulator 
# ============================================================

form Karplus-Strong Modulation
    comment --- Quick Presets ---
    choice Preset 1
        button Custom (Use settings below)
        button Deep Bass Pluck
        button Sci-Fi Siren
        button Metallic Chime
        button Warp Drive Engine
    
    comment --- Custom Settings ---
    positive Ks_Base_Freq 220
    comment (Frequency of the resonator in Hz)
    
    positive Ks_Mod_Rate 0.5
    real Ks_Mod_Depth 12
    
    real Ks_Decay 0.95
    comment (0.99 = Long sustain, 0.5 = Short pluck)

    comment --- Output ---
    real Ks_Mix 0.5
    boolean Play_result 1
endform

# --- 1. Input Check ---
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# --- 2. Apply Presets ---
# If user chooses anything other than "Custom", we override the values.

if preset == 2
    # Deep Bass Pluck
    ks_Base_Freq = 80
    ks_Mod_Rate = 0.2
    ks_Mod_Depth = 1.0
    ks_Decay = 0.85
    ks_Mix = 0.6
elsif preset == 3
    # Sci-Fi Siren
    ks_Base_Freq = 440
    ks_Mod_Rate = 0.3
    ks_Mod_Depth = 12
    ks_Decay = 0.96
    ks_Mix = 0.5
elsif preset == 4
    # Metallic Chime
    ks_Base_Freq = 880
    ks_Mod_Rate = 6.0
    ks_Mod_Depth = 0.5
    ks_Decay = 0.99
    ks_Mix = 0.4
elsif preset == 5
    # Warp Drive
    ks_Base_Freq = 150
    ks_Mod_Rate = 8.0
    ks_Mod_Depth = 24
    ks_Decay = 0.92
    ks_Mix = 0.8
endif

id_orig = selected("Sound")
orig_name$ = selected$("Sound")
sr = Get sampling frequency

# --- 3. Create Temp Reference ---
selectObject: id_orig
Copy: "RefSource"
id_ref = selected("Sound")

# --- 4. Create Output Container ---
selectObject: id_orig
Copy: "OutputContainer"
id_out = selected("Sound")
Formula: "0"

# --- 5. Prepare Math Strings (Atomic Method) ---
# We calculate constants here to prevent formula errors

val_pi = 3.14159265359
val_2pi = 2 * val_pi
s_2pi$ = string$(val_2pi)
s_dt$ = string$(1/sr)

# User params to strings
s_freq$ = string$(ks_Base_Freq)
s_depth$ = string$(ks_Mod_Depth)
s_rate$ = string$(ks_Mod_Rate)
s_decay$ = string$(ks_Decay)

# --- Construct the Delay Math ---
# 1. Sine Wave
math_sine$ = "sin(" + s_2pi$ + " * " + s_rate$ + " * x)"

# 2. Pitch Modulation (2 ^ semitones/12)
math_mod$ = "(2 ^ (" + s_depth$ + " * " + math_sine$ + " / 12))"

# 3. Frequency
math_freq$ = "(" + s_freq$ + " * " + math_mod$ + ")"

# 4. Delay Time (T = 1/F)
math_delay$ = "(1 / " + math_freq$ + ")"

# --- 6. The Final Formula ---
# Output = Input + Decay * ((Self(t-delay) + Self(t-delay-dt))/2)

f$ = "Sound_RefSource[] + (" + s_decay$ + " * (self(x - " + math_delay$ + ") + self(x - " + math_delay$ + " - " + s_dt$ + ")) / 2)"

# Run Formula
selectObject: id_out
Formula: f$

# --- 7. Mix Dry/Wet ---
if ks_Mix < 1.0
    s_mix$ = string$(ks_Mix)
    mix_f$ = "self * " + s_mix$ + " + Sound_RefSource[] * (1 - " + s_mix$ + ")"
    Formula: mix_f$
endif

# --- 8. Cleanup ---
selectObject: id_ref
Remove

selectObject: id_out
Scale peak: 0.99
Rename: orig_name$ + "_KS_Mod"

if play_result
    Play
endif