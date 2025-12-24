# ============================================================
# Praat AudioTools - Amplitude-Following Wah-Wah.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Amplitude-Following Wah-Wah script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Amplitude-Following Wah-Wah with Presets
# Select a Sound object and run.

form Amplitude Following Wah
    comment Select a Preset Style:
    optionmenu Style: 1
        option Classic Guitar (Mid-range, sharp)
        option Funky Bass (Low-range, thumpy)
        option Subtle Vocal (Wide, gentle)
        option Sci-Fi Zap (Extreme range, very sharp)
        option Custom (Use settings below)
    
    comment Custom Settings (Ignored unless "Custom" is selected above):
    positive Custom_Min_Hz 400
    positive Custom_Max_Hz 2500
    positive Custom_Bandwidth_Hz 150
endform

# --- 1. HANDLE PRESETS ---
# We set the actual working variables based on the dropdown choice.

if style$ = "Classic Guitar (Mid-range, sharp)"
    min_cutoff = 400
    max_cutoff = 2500
    bw = 100
elsif style$ = "Funky Bass (Low-range, thumpy)"
    min_cutoff = 80
    max_cutoff = 800
    bw = 80
elsif style$ = "Subtle Vocal (Wide, gentle)"
    min_cutoff = 500
    max_cutoff = 1500
    bw = 300
elsif style$ = "Sci-Fi Zap (Extreme range, very sharp)"
    min_cutoff = 200
    max_cutoff = 4000
    bw = 50
else
    # "Custom" was selected, so we read the text fields
    # Note: Praat lowercases the form variables
    min_cutoff = custom_Min_Hz
    max_cutoff = custom_Max_Hz
    bw = custom_Bandwidth_Hz
endif

# --- 2. SETUP ---
id_sound = selected("Sound")
dur = Get total duration
name$ = selected$("Sound")

# --- 3. GET ENVELOPE ---
selectObject: id_sound
# 100Hz min pitch for intensity provides decent time resolution
id_int = To Intensity: 100, 0, "yes"

min_int = Get minimum: 0, 0, "Parabolic"
max_int = Get maximum: 0, 0, "Parabolic"
range_int = max_int - min_int
if range_int = 0
    range_int = 1
endif

# --- 4. CREATE FORMANT GRID ---
# Create grid with 1 formant. We initialize with dummy values, we will overwrite them.
id_grid = Create FormantGrid: name$ + "_filter", 0, dur, 10, 550, 600, 50, 50

# --- 5. MAP INTENSITY TO FREQUENCY ---
selectObject: id_int
n_frames = Get number of frames

for i to n_frames
    t = Get time from frame number: i
    val = Get value in frame: i
    
    # Normalize (0.0 to 1.0)
    norm_val = (val - min_int) / range_int
    if norm_val < 0
        norm_val = 0
    endif

    # Calculate Frequency based on the Preset variables
    target_freq = min_cutoff + ((max_cutoff - min_cutoff) * norm_val)
    
    # Update Grid
    selectObject: id_grid
    Add formant point: 1, t, target_freq
    Add bandwidth point: 1, t, bw
    
    selectObject: id_int
endfor

# --- 6. APPLY FILTER ---
selectObject: id_sound
plusObject: id_grid
id_wah = Filter

# --- 7. CLEANUP ---
selectObject: id_int
plusObject: id_grid
Remove
selectObject: id_wah
Rename: name$ + "_wah_" + style$
Play

# Output message
appendInfoLine: "Applied Wah preset '", style$, "' to ", name$