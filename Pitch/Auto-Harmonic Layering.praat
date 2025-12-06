# ============================================================
# Praat AudioTools - Auto-Harmonic Layering
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Auto-Harmonic Layering
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
# Auto-Harmonic Layering - One-Step Loop Harmonizer 
# ============================================================

form One-Step Loop Harmonizer
    comment === LOOP DETECTION SETTINGS ===
    positive Time_step 0.05
    positive Pitch_floor 75
    positive Pitch_ceiling 600
    positive Tolerance_hz 50
    positive Min_loop_duration 0.4
    positive Max_loop_duration 10.0
    integer Num_loops_to_find 5

    comment === HARMONIZATION SETTINGS ===
    real Mix_volume 0.5
    choice Chord_Type: 7
        option Octave Doubling
        option Fifth
        option Major
        option Minor
        option Sus4
        option Sus2
        option Random
endform

# ===================================================================
# PHASE 1: FIND LOOPS
# ===================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

originalID = selected("Sound")
originalName$ = selected$("Sound")

appendInfoLine: "--- Analyzing Pitch & Loops ---"

# 1. Extract Pitch
selectObject: originalID
To Pitch: time_step, pitch_floor, pitch_ceiling
pitchID = selected("Pitch")
num_frames = Get number of frames

# 2. Convert Pitch to Matrix
Create simple Matrix: "ThePitchData", num_frames, 1, "0"
dataID = selected("Matrix")

selectObject: pitchID
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

# 3. Calculate SSM
Create simple Matrix: "SSM", num_frames, num_frames, "0"
ssmID = selected("Matrix")

Formula: "if Matrix_ThePitchData[row, 1] > 0 and Matrix_ThePitchData[col, 1] > 0 and abs(Matrix_ThePitchData[row, 1] - Matrix_ThePitchData[col, 1]) < " + string$(tolerance_hz) + " then 1 - (abs(Matrix_ThePitchData[row, 1] - Matrix_ThePitchData[col, 1]) / " + string$(tolerance_hz) + ") else 0 fi"

# 4. Find Candidates
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

if num_frames > 2000
    step = 2
endif

while gap <= max_gap
    path_len = 0
    path_start = 0
    search_limit = num_frames - gap
    
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

# 5. Filter & Annotate
selectObject: tableID
nRows = Get number of rows

if nRows = 0
    removeObject: dataID, ssmID, tableID, textgridID
    exitScript: "No loops found."
endif

Sort rows: "score"

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
        
        selectObject: textgridID
        
        # Tier 1
        Insert boundary: 1, t1
        Insert boundary: 1, t2
        int_idx = Get interval at time: 1, t1 + 0.001
        Set interval text: 1, int_idx, "Loop " + string$(loops_found)
        
        # Tier 2
        Insert boundary: 2, rep_t1
        Insert boundary: 2, rep_t2
        int_idx = Get interval at time: 2, rep_t1 + 0.001
        Set interval text: 2, int_idx, "Repeat " + string$(loops_found)
    endif
    row_index = row_index - 1
endwhile

# CLEANUP Phase 1
removeObject: dataID, ssmID, tableID

# ===================================================================
# PHASE 2: HARMONIZATION
# ===================================================================

appendInfoLine: "--- Generating Harmonies ---"

# 1. Auto-Mono Conversion
selectObject: originalID
nChans = Get number of channels
if nChans > 1
    soundID = Convert to mono
    Rename: "Mono_Source"
else
    soundID = Copy: "Mono_Source"
endif

selectObject: soundID
total_duration = Get total duration
fs = Get sampling frequency

# 2. Collect Events
selectObject: textgridID
nTiers = Get number of tiers
nEvents = 0

for t to nTiers
    nInt = Get number of intervals: t
    for i to nInt
        lab$ = Get label of interval: t, i
        if startsWith(lab$, "Loop") or startsWith(lab$, "Repeat")
            nEvents = nEvents + 1
            event_start[nEvents] = Get start point: t, i
            event_end[nEvents] = Get end point: t, i
            
            # --- CHORD SELECTION LOGIC ---
            if chord_Type = 7
                # Random: Choose between 1 and 6
                event_chord[nEvents] = randomInteger(1, 6)
            else
                # Use the specific user selection
                event_chord[nEvents] = chord_Type
            endif
        endif
    endfor
endfor

# Sort Events
for i to nEvents
    for j from i+1 to nEvents
        if event_start[j] < event_start[i]
            tmp = event_start[i]; event_start[i] = event_start[j]; event_start[j] = tmp
            tmp = event_end[i]; event_end[i] = event_end[j]; event_end[j] = tmp
            tmp = event_chord[i]; event_chord[i] = event_chord[j]; event_chord[j] = tmp
        endif
    endfor
endfor

# 3. Build Sequence
current_time = 0
chainID = 0

for i to nEvents
    # A. Gap
    gap = event_start[i] - current_time
    if gap > 0.001
        Create Sound from formula: "Gap", 1, 0, gap, fs, "0"
        partID = selected("Sound")
        if chainID = 0
            chainID = partID
        else
            selectObject: chainID
            plusObject: partID
            Concatenate
            newChainID = selected("Sound")
            removeObject: chainID, partID
            chainID = newChainID
        endif
    endif
    
    # B. Generate Chord
    selectObject: soundID
    Extract part: event_start[i], event_end[i], "rectangular", 1, "no"
    clipID = selected("Sound")
    
    chordType = event_chord[i]
    @generateChord: clipID, chordType
    partID = selected("Sound")
    
    selectObject: partID
    Scale peak: mix_volume
    
    # C. Append
    if chainID = 0
        chainID = partID
    else
        selectObject: chainID
        plusObject: partID
        Concatenate
        newChainID = selected("Sound")
        removeObject: chainID, partID
        chainID = newChainID
    endif
    
    # Clean up the clip from this iteration
    removeObject: clipID
    
    current_time = event_end[i]
endfor

# D. Final Gap
gap = total_duration - current_time
if gap > 0.001
    Create Sound from formula: "EndGap", 1, 0, gap, fs, "0"
    partID = selected("Sound")
    if chainID <> 0
        selectObject: chainID
        plusObject: partID
        Concatenate
        newChainID = selected("Sound")
        removeObject: chainID, partID
        chainID = newChainID
    else
        chainID = partID
    endif
endif

selectObject: chainID
Rename: "Harmonized_Track_Mono"

# 4. Final Mix
selectObject: originalID
plusObject: chainID
Combine to stereo
Rename: "Final_Mix_With_Chords"
finalID = selected("Sound")

# ===================================================================
# PHASE 3: FINAL CLEANUP
# ===================================================================

removeObject: textgridID, soundID, chainID

appendInfoLine: "Done! Cleaned all temporary objects."

selectObject: finalID
Play

# ===================================================================
# PROCEDURE: Generate Chord (Specific Intervals)
# ===================================================================
procedure generateChord: .srcID, .type
    selectObject: .srcID
    .fs = Get sampling frequency
    
    # Interval Definitions (Semitones)
    # 1: Octave Doubling (Root + 12 + 24)
    if .type = 1
        .i2 = 12
        .i3 = 24
    # 2: Fifth (Power Chord: Root + 7 + 12)
    elsif .type = 2
        .i2 = 7
        .i3 = 12
    # 3: Major (Root + 4 + 7)
    elsif .type = 3
        .i2 = 4
        .i3 = 7
    # 4: Minor (Root + 3 + 7)
    elsif .type = 4
        .i2 = 3
        .i3 = 7
    # 5: Sus4 (Root + 5 + 7)
    elsif .type = 5
        .i2 = 5
        .i3 = 7
    # 6: Sus2 (Root + 2 + 7)
    else
        .i2 = 2
        .i3 = 7
    endif
    
    .semitone = 2 ^ (1/12)
    
    # 1. Root
    selectObject: .srcID
    .root = Copy: "root"
    
    # 2. Note 2
    selectObject: .srcID
    .n2 = Copy: "n2"
    .ratio = .semitone ^ .i2
    Override sampling frequency: .fs * .ratio
    .m = To Manipulation: 0.01, 75, 600
    .d = Extract duration tier
    selectObject: .d
    Add point: 0, .ratio
    selectObject: .m
    plusObject: .d
    Replace duration tier
    selectObject: .m
    .res2 = Get resynthesis (overlap-add)
    selectObject: .res2
    .final2 = Resample: .fs, 50
    
    # CLEANUP NOTE 2
    removeObject: .n2, .m, .d, .res2
    
    # 3. Note 3
    selectObject: .srcID
    .n3 = Copy: "n3"
    .ratio = .semitone ^ .i3
    Override sampling frequency: .fs * .ratio
    .m = To Manipulation: 0.01, 75, 600
    .d = Extract duration tier
    selectObject: .d
    Add point: 0, .ratio
    selectObject: .m
    plusObject: .d
    Replace duration tier
    selectObject: .m
    .res3 = Get resynthesis (overlap-add)
    selectObject: .res3
    .final3 = Resample: .fs, 50
    
    # CLEANUP NOTE 3
    removeObject: .n3, .m, .d, .res3
    
    # 4. Mix to Mono
    selectObject: .root
    plusObject: .final2
    .s1 = Combine to stereo
    .m1 = Convert to mono
    
    selectObject: .m1
    plusObject: .final3
    .s2 = Combine to stereo
    .result = Convert to mono
    
    # FINAL PROCEDURE CLEANUP
    removeObject: .root, .final2, .final3, .s1, .m1, .s2
    
    selectObject: .result
endproc