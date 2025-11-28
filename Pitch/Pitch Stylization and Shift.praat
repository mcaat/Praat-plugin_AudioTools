# ============================================================
# Praat AudioTools - Pitch Stylization and Shift.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-based transformation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Pitch Stylization and Shift
    comment Preset configurations:
    optionmenu Preset 1
        option Manual (Use settings below)
        option Gentle Smoothing
        option Stepwise Quantize (Autotune style)
        option Robot Voice (Monotone)
        option Pitch Down (-1 Octave)
        option Pitch Up (+1 Octave)
        option Strong Stylize
    
    comment --- Manual Parameters ---
    real Manual_Stylize_Hz 2
    real Manual_Shift_ST -20
    
    comment --- Analysis Settings ---
    positive Time_step 0.005
    positive Min_pitch 75
    positive Max_pitch 600
    
    comment --- Output ---
    boolean Play_result 1
    boolean Keep_intermediate 0
endform

# --- 1. Apply Logic ---
# Default values from Manual settings
op_stylize = manual_Stylize_Hz
op_shift = manual_Shift_ST
mode = 0  
# mode 0=Normal, 1=Quantize (Step), 2=Robot (Flat)

if preset == 2
    # Gentle Smoothing
    op_stylize = 3.0    ; Increased from 1.0 to make it audible
    op_shift = 0
    mode = 0
elsif preset == 3
    # Stepwise Quantize
    op_stylize = 0
    op_shift = 0
    mode = 1            ; Activate Quantization Formula
elsif preset == 4
    # Robot Voice
    op_shift = -2
    mode = 2            ; Activate Flattening Formula
elsif preset == 5
    # Pitch Down
    op_stylize = 0
    op_shift = -12      ; Changed from -24 to -12 (safer range)
    mode = 0
elsif preset == 6
    # Pitch Up
    op_stylize = 0
    op_shift = 12
    mode = 0
elsif preset == 7
    # Strong Stylize
    op_stylize = 10.0
    op_shift = -5
    mode = 0
endif

# --- 2. Input Check ---
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

id_orig = selected("Sound")
orig_name$ = selected$("Sound")
dur = Get total duration

# --- 3. Processing (PSOLA) ---

# A. Create Manipulation
selectObject: id_orig
id_manip = To Manipulation: time_step, min_pitch, max_pitch

# B. Extract PitchTier
selectObject: id_manip
id_pitch = Extract pitch tier

# C. Apply Effects based on Mode
selectObject: id_pitch

if mode == 2
    # ROBOT: Flatten to mean pitch
    mean_val = Get mean (curve): 0, 0
    Formula: "mean_val"

elsif mode == 1
    # QUANTIZE: Snap to nearest semitone (Autotune effect)
    # Formula: ref * 2 ^ (round(12 * log2(x / ref)) / 12)
    # We use 440Hz as reference
    Formula: "440 * 2 ^ (round(12 * log2(self / 440)) / 12)"

else
    # NORMAL STYLIZE
    if op_stylize > 0
        Stylize: op_stylize, "Hz"
    endif
endif

# D. Apply Shift
if op_shift != 0
    Shift frequencies: 0, dur, op_shift, "semitones"
endif

# E. Resynthesize
selectObject: id_manip
plusObject: id_pitch
Replace pitch tier

selectObject: id_manip
id_resynth = Get resynthesis (overlap-add)
Rename: orig_name$ + "_processed"

# --- 4. Cleanup ---
if not keep_intermediate
    selectObject: id_manip
    plusObject: id_pitch
    Remove
endif

# --- 5. Finalize ---
selectObject: id_resynth
if play_result
    Play
endif