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
# Praat AudioTools - Auto-Harmonic Layering (Enhanced)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Auto-Harmonic Layering with enhanced features:
#   - Each loop gets consistent harmony across all repeats
#   - Control over harmonization time range
#   - Mono output option
#   - Fade-in/fade-out on chords for smooth blending
#   - Individual chord level control
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form One-Step Loop Harmonizer (Enhanced)
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
    
    comment === HARMONIZATION SCOPE ===
    boolean Harmonize_repeats 1
    real Harmonize_until_time 0
    
    comment === CHORD MIXING LEVELS (0-1) ===
    real Root_level 1.0
    real Note_2_level 0.8
    real Note_3_level 0.6
    
    comment === ENVELOPE SETTINGS ===
    positive Fade_duration 0.01
    boolean Apply_fades 1
    
    comment === OUTPUT FORMAT ===
    boolean Output_mono 0
endform

# ===================================================================
# PHASE 1: FIND LOOPS
# ===================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

originalID = selected("Sound")
originalName$ = selected$("Sound")

writeInfoLine: "=== AUTO-HARMONIC LAYERING ==="
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
total_duration = Get total duration
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
    
    # TIMING CALCULATION (Verified - Correct!)
    # Frames are 1-indexed, so (start_f - 1) converts to time
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

appendInfoLine: "Found ", loops_found, " loops"

# CLEANUP Phase 1
removeObject: dataID, ssmID, tableID

# ===================================================================
# PHASE 1B: ASSIGN CHORD TYPES TO EACH LOOP NUMBER
# ===================================================================

# NEW: Assign one chord type per loop number (not per event!)
# Initialize array explicitly
for loop_num to loops_found
    chord_for_loop'loop_num' = 0
endfor

for loop_num to loops_found
    if chord_Type = 7
        # Random: Choose between 1 and 6
        chord_for_loop'loop_num' = randomInteger(1, 6)
    else
        # Use the specific user selection
        chord_for_loop'loop_num' = chord_Type
    endif
endfor

# Report chord assignments
appendInfoLine: ""
appendInfoLine: "Chord assignments:"
for loop_num to loops_found
    c = chord_for_loop'loop_num'
    if c = 1
        chord_name$ = "Octave Doubling"
    elsif c = 2
        chord_name$ = "Fifth"
    elsif c = 3
        chord_name$ = "Major"
    elsif c = 4
        chord_name$ = "Minor"
    elsif c = 5
        chord_name$ = "Sus4"
    else
        chord_name$ = "Sus2"
    endif
    appendInfoLine: "  Loop ", loop_num, ": ", chord_name$
endfor

# ===================================================================
# PHASE 2: HARMONIZATION
# ===================================================================

appendInfoLine: ""
appendInfoLine: "--- Generating Harmonies ---"

# Set harmonization end time
if harmonize_until_time <= 0
    harm_end_time = total_duration
else
    harm_end_time = min(harmonize_until_time, total_duration)
endif

appendInfoLine: "Harmonizing until: ", fixed$(harm_end_time, 2), " s"

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
fs = Get sampling frequency

# 2. Collect Events
selectObject: textgridID
nTiers = Get number of tiers
nEvents = 0
skipped_events = 0

for t to nTiers
    nInt = Get number of intervals: t
    for i to nInt
        lab$ = Get label of interval: t, i
        
        # Check if this is a Loop or Repeat
        is_loop = startsWith(lab$, "Loop")
        is_repeat = startsWith(lab$, "Repeat")
        
        if is_loop or is_repeat
            event_start_time = Get start point: t, i
            event_end_time = Get end point: t, i
            
            # NEW: Apply filters
            should_include = 1
            
            # Filter 1: Skip repeats if user disabled them
            if is_repeat and not harmonize_repeats
                should_include = 0
            endif
            
            # Filter 2: Skip events that start after the harmonization end time
            if event_start_time >= harm_end_time
                should_include = 0
            endif
            
            if should_include
                nEvents = nEvents + 1
                event_start[nEvents] = event_start_time
                
                # Clip event end to harmonization limit
                event_end[nEvents] = min(event_end_time, harm_end_time)
                
                # Extract loop number from label and use its assigned chord
                if is_loop
                    loop_num_str$ = replace$(lab$, "Loop ", "", 1)
                else
                    loop_num_str$ = replace$(lab$, "Repeat ", "", 1)
                endif
                loop_num = number(loop_num_str$)
                
                event_chord[nEvents] = chord_for_loop'loop_num'
            else
                skipped_events = skipped_events + 1
            endif
        endif
    endfor
endfor

if skipped_events > 0
    appendInfoLine: "Skipped ", skipped_events, " events (outside harmonization range or repeats disabled)"
endif

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
    
    # Apply fade-in/fade-out
    if apply_fades
        selectObject: partID
        dur = Get total duration
        fade_in = min(fade_duration, dur/4)
        fade_out = min(fade_duration, dur/4)
        Fade in: 0, 0, fade_in, "yes"
        Fade out: 0, dur, -fade_out, "yes"
    endif
    
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

# D. Final Gap (to match total duration)
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
Rename: "Harmonized_Track"

# 4. Final Mix
selectObject: originalID
plusObject: chainID

if output_mono
    # Mono output option
    stereoID = Combine to stereo
    finalID = Convert to mono
    Rename: "Final_Mix_Mono"
    removeObject: stereoID
else
    # Stereo output
    Combine to stereo
    Rename: "Final_Mix_Stereo"
    finalID = selected("Sound")
endif

# ===================================================================
# PHASE 3: FINAL CLEANUP
# ===================================================================

removeObject: textgridID, soundID, chainID

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
appendInfoLine: "Events harmonized: ", nEvents
if apply_fades
    appendInfoLine: "Fade duration: ", fade_duration, " s"
endif
if output_mono
    appendInfoLine: "Output: Mono"
else
    appendInfoLine: "Output: Stereo"
endif

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
    
    # 1. Root (with level control)
    selectObject: .srcID
    .root = Copy: "root"
    Scale peak: root_level
    
    # 2. Note 2 (with level control)
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
    Scale peak: note_2_level
    
    # CLEANUP NOTE 2
    removeObject: .n2, .m, .d, .res2
    
    # 3. Note 3 (with level control)
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
    Scale peak: note_3_level
    
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