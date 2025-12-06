# ============================================================
# Praat AudioTools - Pitch-Only Loop Finder
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-Only Loop Finder
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
# Pitch Loop Finder 
# ============================================================

form Turbo Pitch Loop Finder
    comment === SPEED SETTINGS ===
    positive time_step 0.05
    comment (0.05 = Fast, 0.02 = High Precision)
    
    comment === PITCH SETTINGS ===
    positive pitch_floor 75
    positive pitch_ceiling 600
    positive tolerance_hz 50
    
    comment === LOOP TIMING ===
    positive min_loop_duration 0.4
    positive max_loop_duration 10.0
    
    comment === OUTPUT ===
    positive num_loops_to_find 5
endform

# ===================================================================
# 1. SETUP
# ===================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

originalID = selected("Sound")
originalName$ = selected$("Sound")

# 1. Extract Pitch
selectObject: originalID
To Pitch: time_step, pitch_floor, pitch_ceiling
pitchID = selected("Pitch")
num_frames = Get number of frames

writeInfoLine: "Extracted ", num_frames, " frames."
appendInfoLine: "Time Step: ", time_step, "s"

# ===================================================================
# 2. THE SPEED HACK (Formula Calculation)
# ===================================================================

# Convert Pitch to Matrix
# We name it "ThePitchData" so the Formula command can find it by name
Create simple Matrix: "ThePitchData", num_frames, 1, "0"
dataID = selected("Matrix")

selectObject: pitchID
# Using Vector method to fill data quickly
pitch_vals# = zero# (num_frames)
for i to num_frames
    val = Get value in frame: i, "Hertz"
    if val = undefined
        val = 0
    endif
    pitch_vals#[i] = val
endfor
removeObject: pitchID

selectObject: dataID
for i to num_frames
    Set value: i, 1, pitch_vals#[i]
endfor

# Create SSM
Create simple Matrix: "SSM", num_frames, num_frames, "0"
ssmID = selected("Matrix")

appendInfo: "Calculating Matrix (Turbo Mode)..."

# THIS IS THE MAGIC LINE
# Instead of a slow loop, we run a C++ formula.
# Logic: If both pitches > 0 and difference < tolerance, calculate score. Else 0.
Formula: "if Matrix_ThePitchData[row, 1] > 0 and Matrix_ThePitchData[col, 1] > 0 and abs(Matrix_ThePitchData[row, 1] - Matrix_ThePitchData[col, 1]) < " + string$(tolerance_hz) + " then 1 - (abs(Matrix_ThePitchData[row, 1] - Matrix_ThePitchData[col, 1]) / " + string$(tolerance_hz) + ") else 0 fi"

appendInfoLine: " done!"

# ===================================================================
# 3. FIND LOOPS
# ===================================================================

# Create TextGrid for output
selectObject: originalID
To TextGrid: "Loops Repeats", ""
textgridID = selected("TextGrid")

Create Table with column names: "candidates", 0, "start_frame length_frames gap_frames score"
tableID = selected("Table")

selectObject: ssmID
frame_rate = 1 / time_step
min_len = round(min_loop_duration * frame_rate)
max_gap = num_frames - min_len

gap = min_len
step = 1

# Speed up search: larger steps for long files
if num_frames > 2000
    step = 2
endif

appendInfo: "Scanning diagonals..."

while gap <= max_gap
    path_len = 0
    path_start = 0
    search_limit = num_frames - gap
    
    # We still loop here, but it's much lighter than the matrix build
    for i to search_limit
        j = i + gap
        val = Get value in cell: i, j
        
        if val > 0.5
            if path_len = 0
                path_start = i
            endif
            path_len = path_len + 1
        else
            if path_len >= min_len
                selectObject: tableID
                Append row
                row = Get number of rows
                Set numeric value: row, "start_frame", path_start
                Set numeric value: row, "length_frames", path_len
                Set numeric value: row, "gap_frames", gap
                Set numeric value: row, "score", path_len * val
                selectObject: ssmID
            endif
            path_len = 0
        endif
    endfor
    gap = gap + step
endwhile

appendInfoLine: " done."

# ===================================================================
# 4. FILTER & ANNOTATE
# ===================================================================

selectObject: tableID
nRows = Get number of rows

if nRows = 0
    removeObject: dataID, ssmID, tableID
    exitScript: "No loops found."
endif

Sort rows: "score"

# De-duplication logic
for k to num_loops_to_find
    saved_t1[k] = -1
    saved_t2[k] = -1
endfor

loops_found = 0
row_index = nRows

while loops_found < num_loops_to_find and row_index > 0
    selectObject: tableID
    start_f = Get value: row_index, "start_frame"
    len_f = Get value: row_index, "length_frames"
    gap_f = Get value: row_index, "gap_frames"
    
    t1 = (start_f - 1) * time_step
    dur = len_f * time_step
    t2 = t1 + dur
    rep_t1 = (start_f + gap_f - 1) * time_step
    rep_t2 = rep_t1 + dur
    
    # Overlap Check
    is_overlap = 0
    for k to loops_found
        if t1 < saved_t2[k] and t2 > saved_t1[k]
            is_overlap = 1
        endif
    endfor
    
    if is_overlap = 0
        loops_found = loops_found + 1
        saved_t1[loops_found] = t1
        saved_t2[loops_found] = t2
        
        # Annotate TextGrid
        selectObject: textgridID
        
        # Tier 1: Source
        Insert boundary: 1, t1
        Insert boundary: 1, t2
        int_idx = Get interval at time: 1, t1 + 0.001
        Set interval text: 1, int_idx, "Loop " + string$(loops_found)
        
        # Tier 2: Repeat
        Insert boundary: 2, rep_t1
        Insert boundary: 2, rep_t2
        int_idx = Get interval at time: 2, rep_t1 + 0.001
        Set interval text: 2, int_idx, "Repeat " + string$(loops_found)
        
        appendInfoLine: "Found Loop ", loops_found, ": ", fixed$(t1, 2), "s -> ", fixed$(rep_t1, 2), "s"
    endif
    row_index = row_index - 1
endwhile

# Cleanup
selectObject: dataID
plusObject: ssmID
plusObject: tableID
Remove

selectObject: originalID
plusObject: textgridID
View & Edit