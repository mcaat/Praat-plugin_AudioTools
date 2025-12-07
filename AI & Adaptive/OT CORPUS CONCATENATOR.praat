# ============================================================
# Praat AudioTools - OT CORPUS CONCATENATOR
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   OT CORPUS CONCATENATOR
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# OT CORPUS CONCATENATOR
# ============================================================

form OT Concatenation Settings
    comment --- Selection ---
    integer limit_files 10
    
    comment --- OT Constraints (Weights) ---
    real weight_darkness 0.0
    real weight_brightness 1.0
    real weight_energy 2.0
    real weight_stability 1.0
    
    comment --- Playback ---
    boolean play_result 1
endform

# 1. DIRECTORY SELECTION
# ============================================================
clearinfo
n_target = limit_files

directory$ = chooseDirectory$("Choose the folder containing your audio files")

if directory$ = ""
    exitScript: "No folder selected."
endif

if right$(directory$, 1) <> "/" and right$(directory$, 1) <> "\"
    if environment$("os") = "windows"
        directory$ = directory$ + "\"
    else
        directory$ = directory$ + "/"
    endif
endif

stringsID = Create Strings as file list: "FileList", directory$ + "*.wav"
nFiles = Get number of strings

if nFiles = 0
    selectObject: stringsID
    Remove
    exitScript: "No .wav files found in that directory!"
endif

if n_target > nFiles
    n_target = nFiles
endif

# Create Analysis Table with violation columns
tableID = Create Table with column names: "OT_Leaderboard", nFiles, 
    ..."Filename C0_Energy C1_Tilt Stability Viol_Darkness Viol_Brightness Viol_Energy Viol_Stability Harmony_Score"

appendInfoLine: "Analyzing ", nFiles, " files..."

# 2. ANALYSIS LOOP
# ============================================================
for i to nFiles
    selectObject: stringsID
    fileName$ = Get string: i
    
    soundID = Read from file: directory$ + fileName$
    
    # MFCC Analysis
    # 12 coeffs, 15ms window, 5ms shift
    mfccID = To MFCC: 12, 0.015, 0.005, 100.0, 100.0, 0
    
    # Calculate Mean C0 and Mean C1 manually
    nFrames = Get number of frames
    
    sum_c0 = 0
    sum_c1 = 0
    
    # Loop through all frames to get the raw values
    for f to nFrames
        # c0 (Energy) is coefficient 1
        val_c0 = Get value in frame: f, 1
        # c1 (Tilt) is coefficient 2
        val_c1 = Get value in frame: f, 2
        
        sum_c0 = sum_c0 + val_c0
        sum_c1 = sum_c1 + val_c1
    endfor
    
    # Calculate Averages
    if nFrames > 0
        mean_c0 = sum_c0 / nFrames
        mean_c1 = sum_c1 / nFrames
    else
        mean_c0 = 0
        mean_c1 = 0
    endif
    
    # Calculate Stability (Standard Deviation of C1) manually
    sum_sq_diff = 0
    selectObject: mfccID
    for f to nFrames
        val_c1 = Get value in frame: f, 2
        diff = val_c1 - mean_c1
        sum_sq_diff = sum_sq_diff + (diff * diff)
    endfor
    
    if nFrames > 1
        stdev_c1 = sqrt(sum_sq_diff / (nFrames - 1))
    else
        stdev_c1 = 0
    endif
    
    # --- VIOLATIONS ---
    viol_dark = 0
    if mean_c1 < 0
        viol_dark = abs(mean_c1)
    endif
    
    viol_bright = 0
    if mean_c1 > 0
        viol_bright = mean_c1
    endif
    
    viol_energy = 100 - mean_c0
    if viol_energy < 0
        viol_energy = 0
    endif
    
    viol_stable = stdev_c1 * 10
    
    # Harmony Score (lower is better)
    harmony = (viol_dark * weight_darkness) + (viol_bright * weight_brightness) + (viol_energy * weight_energy) + (viol_stable * weight_stability)
    
    # Save to Table
    selectObject: tableID
    Set string value: i, "Filename", fileName$
    Set numeric value: i, "C0_Energy", mean_c0
    Set numeric value: i, "C1_Tilt", mean_c1
    Set numeric value: i, "Stability", stdev_c1
    Set numeric value: i, "Viol_Darkness", viol_dark
    Set numeric value: i, "Viol_Brightness", viol_bright
    Set numeric value: i, "Viol_Energy", viol_energy
    Set numeric value: i, "Viol_Stability", viol_stable
    Set numeric value: i, "Harmony_Score", harmony
    
    # Cleanup
    selectObject: soundID
    plusObject: mfccID
    Remove
endfor

# 3. SORTING
# ============================================================
selectObject: tableID
Sort rows: "Harmony_Score"

appendInfoLine: "============================================"
appendInfoLine: "CONSTRAINT WEIGHTS:"
appendInfoLine: "  *DARKNESS     = ", fixed$(weight_darkness, 2), " (penalizes negative spectral tilt)"
appendInfoLine: "  *BRIGHTNESS   = ", fixed$(weight_brightness, 2), " (penalizes positive spectral tilt)"
appendInfoLine: "  *LOW-ENERGY   = ", fixed$(weight_energy, 2), " (penalizes low loudness)"
appendInfoLine: "  *UNSTABLE     = ", fixed$(weight_stability, 2), " (penalizes timbral variance)"
appendInfoLine: "============================================"
appendInfoLine: ""
appendInfoLine: "RANKING: Top ", n_target, " files by Harmony Score"
appendInfoLine: "--------------------------------------------"

for i to n_target
    selectObject: tableID
    name$ = Get value: i, "Filename"
    score = Get value: i, "Harmony_Score"
    
    v_dark = Get value: i, "Viol_Darkness"
    v_bright = Get value: i, "Viol_Brightness"
    v_energy = Get value: i, "Viol_Energy"
    v_stable = Get value: i, "Viol_Stability"
    
    c0 = Get value: i, "C0_Energy"
    c1 = Get value: i, "C1_Tilt"
    
    appendInfoLine: i, ". ", name$, " → Harmony: ", fixed$(score, 2)
    appendInfoLine: "   Features: Energy=", fixed$(c0, 1), " | Tilt=", fixed$(c1, 2)
    appendInfoLine: "   Violations:"
    
    if v_dark > 0
        appendInfoLine: "      *DARKNESS    = ", fixed$(v_dark, 2), " × ", weight_darkness, " = ", fixed$(v_dark * weight_darkness, 2)
    endif
    
    if v_bright > 0
        appendInfoLine: "      *BRIGHTNESS  = ", fixed$(v_bright, 2), " × ", weight_brightness, " = ", fixed$(v_bright * weight_brightness, 2)
    endif
    
    if v_energy > 0
        appendInfoLine: "      *LOW-ENERGY  = ", fixed$(v_energy, 2), " × ", weight_energy, " = ", fixed$(v_energy * weight_energy, 2)
    endif
    
    if v_stable > 0
        appendInfoLine: "      *UNSTABLE    = ", fixed$(v_stable, 2), " × ", weight_stability, " = ", fixed$(v_stable * weight_stability, 2)
    endif
    
    appendInfoLine: ""
endfor

appendInfoLine: "--------------------------------------------"

# 4. CONCATENATION
# ============================================================
appendInfoLine: "Loading and concatenating files..."

# Read all files and store their IDs
for i to n_target
    selectObject: tableID
    fileName$ = Get value: i, "Filename"
    soundID = Read from file: directory$ + fileName$
    
    if i = 1
        firstID = soundID
    endif
endfor

# Select all sounds for concatenation
selectObject: firstID
for i from 2 to n_target
    plusObject: firstID + (i - 1)
endfor

# Concatenate into single sound
Concatenate
finalID = selected("Sound")
Rename: "OT_Optimal_Concatenation"

# 5. CLEANUP
# ============================================================
# Remove individual sound files
selectObject: firstID
for i from 2 to n_target
    plusObject: firstID + (i - 1)
endfor
Remove

# Remove temporary objects
selectObject: stringsID
plusObject: tableID
Remove

# Select final result
selectObject: finalID

appendInfoLine: "============================================"
appendInfoLine: "SUCCESS!"
appendInfoLine: "Created: OT_Optimal_Concatenation"
appendInfoLine: "Contains ", n_target, " concatenated files"
appendInfoLine: "============================================"

if play_result
    Play
endif