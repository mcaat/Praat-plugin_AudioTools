# ============================================================
# Praat AudioTools - Correlation-Based Pitch Class Extraction.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Correlation-Based Pitch Class Extraction
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Matched Filter by Pitch Class Selection
# Analyzes fundamental frequency, extracts notes by pitch

# ===== CONFIGURATION =====
form Matched Filter by Pitch Selection
    comment Pitch analysis settings
    real Pitch_floor_(Hz) 75
    real Pitch_ceiling_(Hz) 600
    comment Pitch detection quality
    optionmenu Method: 1
        option Accurate (cc)
        button Standard (ac)
    comment Post-processing
    boolean Apply_gate_function 1
    real Gate_threshold_(dB) -40
    boolean Normalize_result 1
    real Peak_amplitude 0.99
endform

# ===== INITIAL CHECKS =====
numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds = 0
    exitScript: "Error: Please select a Sound object first"
endif

original_sound = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound
duration = Get total duration
sampleRate = Get sampling frequency

writeInfoLine: "=== Pitch Analysis for Matched Filter ==="
appendInfoLine: "Analyzing: ", original_name$
appendInfoLine: "Duration: ", fixed$(duration, 3), " s"
appendInfoLine: ""

# ===== STEP 1: PITCH ANALYSIS =====
appendInfoLine: "Step 1: Analyzing fundamental frequency..."
selectObject: original_sound

if method = 1
    pitch = To Pitch (cc): 0, pitch_floor, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, pitch_ceiling
else
    pitch = To Pitch: 0, pitch_floor, pitch_ceiling
endif

Rename: original_name$ + "_pitch"
appendInfoLine: "  Pitch object created"

# ===== STEP 2: EXTRACT UNIQUE PITCHES =====
appendInfoLine: ""
appendInfoLine: "Step 2: Extracting detected pitches..."

selectObject: pitch
n_frames = Get number of frames

# Collect all valid pitch values
pitchCount = 0
for i from 1 to n_frames
    f0 = Get value in frame: i, "Hertz"
    if f0 != undefined
        pitchCount += 1
        pitch_value[pitchCount] = f0
        pitch_time[pitchCount] = Get time from frame number: i
    endif
endfor

appendInfoLine: "  Found ", pitchCount, " voiced frames"

if pitchCount = 0
    removeObject: pitch
    exitScript: "Error: No pitch detected in the sound. Try adjusting pitch floor/ceiling."
endif

# ===== STEP 3: CLUSTER PITCHES INTO PITCH CLASSES =====
appendInfoLine: ""
appendInfoLine: "Step 3: Clustering pitches into note classes..."

# Convert Hz to MIDI note numbers for clustering
for i from 1 to pitchCount
    midi_note[i] = round(12 * log2(pitch_value[i] / 440) + 69)
endfor

# Find unique MIDI notes
uniqueCount = 0
for i from 1 to pitchCount
    note = midi_note[i]
    isUnique = 1
    for j from 1 to uniqueCount
        if note = unique_midi[j]
            isUnique = 0
        endif
    endfor
    if isUnique
        uniqueCount += 1
        unique_midi[uniqueCount] = note
    endif
endfor

# Sort unique notes
for i from 1 to uniqueCount - 1
    for j from i + 1 to uniqueCount
        if unique_midi[i] > unique_midi[j]
            temp = unique_midi[i]
            unique_midi[i] = unique_midi[j]
            unique_midi[j] = temp
        endif
    endfor
endfor

appendInfoLine: "  Found ", uniqueCount, " unique pitch classes"
appendInfoLine: ""
appendInfoLine: "Detected notes:"

# Create note name lookup
for i from 1 to uniqueCount
    midi = unique_midi[i]
    note_class = (midi - 12) mod 12
    octave = floor((midi - 12) / 12)
    
    if note_class = 0
        note_name$ = "C"
    elsif note_class = 1
        note_name$ = "C#"
    elsif note_class = 2
        note_name$ = "D"
    elsif note_class = 3
        note_name$ = "D#"
    elsif note_class = 4
        note_name$ = "E"
    elsif note_class = 5
        note_name$ = "F"
    elsif note_class = 6
        note_name$ = "F#"
    elsif note_class = 7
        note_name$ = "G"
    elsif note_class = 8
        note_name$ = "G#"
    elsif note_class = 9
        note_name$ = "A"
    elsif note_class = 10
        note_name$ = "A#"
    elsif note_class = 11
        note_name$ = "B"
    endif
    
    unique_note_name$[i] = note_name$ + string$(octave)
    
    # Calculate average frequency for this note
    count = 0
    sum = 0
    for j from 1 to pitchCount
        if midi_note[j] = midi
            count += 1
            sum += pitch_value[j]
        endif
    endfor
    avg_freq = sum / count
    unique_freq[i] = avg_freq
    
    appendInfoLine: "  ", i, ". ", unique_note_name$[i], " (MIDI ", midi, ", ~", fixed$(avg_freq, 1), " Hz)"
endfor

# ===== STEP 4: USER SELECTION =====
appendInfoLine: ""
appendInfoLine: "Opening selection dialog..."

# Build choice menu
beginPause: "Select Target Pitch"
    comment: "Choose the note you want to extract:"
    choice: "Target_note", 1
    for i from 1 to uniqueCount
        option: unique_note_name$[i] + " (" + fixed$(unique_freq[i], 1) + " Hz)"
    endfor
endPause: "Cancel", "Extract", 2

if target_note = 0
    removeObject: pitch
    exitScript: "User cancelled"
endif

selected_midi = unique_midi[target_note]
selected_name$ = unique_note_name$[target_note]
selected_freq = unique_freq[target_note]

writeInfoLine: "=== Matched Filter Extraction ==="
appendInfoLine: "Target note: ", selected_name$, " (~", fixed$(selected_freq, 1), " Hz)"
appendInfoLine: ""

# ===== STEP 5: FIND BEST TEMPLATE SEGMENT =====
appendInfoLine: "Step 5: Finding template segment for ", selected_name$, "..."

# Find longest continuous segment of target pitch
best_start = 0
best_end = 0
best_duration = 0
current_start = 0
in_segment = 0

for i from 1 to pitchCount
    if midi_note[i] = selected_midi
        if not in_segment
            current_start = i
            in_segment = 1
        endif
    else
        if in_segment
            segment_duration = pitch_time[i-1] - pitch_time[current_start]
            if segment_duration > best_duration
                best_duration = segment_duration
                best_start = pitch_time[current_start]
                best_end = pitch_time[i-1]
            endif
            in_segment = 0
        endif
    endif
endfor

# Check final segment
if in_segment
    segment_duration = pitch_time[pitchCount] - pitch_time[current_start]
    if segment_duration > best_duration
        best_duration = segment_duration
        best_start = pitch_time[current_start]
        best_end = pitch_time[pitchCount]
    endif
endif

if best_duration = 0
    removeObject: pitch
    exitScript: "Error: Could not find continuous segment of ", selected_name$
endif

# Add small padding
padding = 0.05
template_start = max(0, best_start - padding)
template_end = min(duration, best_end + padding)

appendInfoLine: "  Template segment: ", fixed$(template_start, 3), " - ", fixed$(template_end, 3), " s"
appendInfoLine: "  Duration: ", fixed$(best_duration, 3), " s"

# ===== STEP 6: EXTRACT TEMPLATE =====
appendInfoLine: ""
appendInfoLine: "Step 6: Extracting template..."
selectObject: original_sound
template = Extract part: template_start, template_end, "rectangular", 1.0, "no"
Rename: original_name$ + "_" + selected_name$ + "_template"

# ===== STEP 7: CROSS-CORRELATION =====
appendInfoLine: ""
appendInfoLine: "Step 7: Computing matched filter (cross-correlation)..."
selectObject: original_sound, template
correlation = Cross-correlate: "peak 0.99", "zero"
Rename: original_name$ + "_" + selected_name$ + "_correlation"

selectObject: correlation
corr_max = Get maximum: 0, 0, "None"
appendInfoLine: "  Peak correlation: ", fixed$(corr_max, 6)

# ===== STEP 8: APPLY GATE =====
if apply_gate_function
    appendInfoLine: ""
    appendInfoLine: "Step 8: Applying gate function..."
    
    selectObject: correlation
    threshold_linear = 10^(gate_threshold / 20) * corr_max
    
    result = Copy: original_name$ + "_" + selected_name$ + "_result"
    n_samples = Get number of samples
    
    for i from 1 to n_samples
        value = Get value at sample number: 1, i
        if abs(value) < threshold_linear
            Set value at sample number: 1, i, 0
        endif
    endfor
    
    appendInfoLine: "  Gated at ", gate_threshold, " dB"
else
    selectObject: correlation
    result = Copy: original_name$ + "_" + selected_name$ + "_result"
endif

# ===== STEP 9: NORMALIZE =====
if normalize_result
    appendInfoLine: ""
    appendInfoLine: "Step 9: Normalizing..."
    selectObject: result
    Scale peak: peak_amplitude
endif

# ===== CLEANUP AND SUMMARY =====
appendInfoLine: ""
appendInfoLine: "=== Processing Complete ==="
appendInfoLine: ""
appendInfoLine: "Created objects:"
appendInfoLine: "  • Pitch analysis"
appendInfoLine: "  • Template (", selected_name$, " note)"
appendInfoLine: "  • Correlation (matched filter)"
appendInfoLine: "  • Result (extracted note)"
appendInfoLine: ""
appendInfoLine: "Peaks in the result show where ", selected_name$, " occurs in the melody."

# Select results for viewing
selectObject: pitch, template, correlation, result