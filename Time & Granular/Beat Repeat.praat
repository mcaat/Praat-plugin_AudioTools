# ============================================================
# Praat AudioTools - Sound to Grain.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Create Beat Repeat
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
form Beat Repeat Parameters
    real bpm 120
    optionmenu note_value 1
        option 1/32
        option 1/16
        option 1/8
        option 1/4
        option 1/2
        option 1/16 triplet
        option 1/8 triplet
        option 1/4 triplet
        option dotted 1/16
        option dotted 1/8
        option dotted 1/4
        option dotted 1/2
    comment --- Beat Selection ---
    optionmenu beat_selection_mode 1
        option Specific beat number
        option Random beat
        option Beat range
        option Auto (1 second in)
    integer specific_beat 4
    integer beat_range_start 2
    integer beat_range_end 4
    comment --- Repeat Parameters ---
    integer num_repeats 4
    real amplitude_decay 0.9
    comment --- Advanced Options ---
    boolean fade_repeats 0
    real fade_duration 0.01
endform

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")

selectObject: sound
duration = Get total duration
sampleRate = Get sampling frequency
numChannels = Get number of channels

writeInfoLine: "=== Beat Repeat Processing ==="
appendInfoLine: "Original duration: ", fixed$(duration, 3), " seconds"

secondsPerBeat = 60 / bpm
totalBeats = floor(duration / secondsPerBeat)

appendInfoLine: "BPM: ", bpm
appendInfoLine: "Total beats in audio: ", totalBeats

# Calculate note duration based on selection
if note_value = 1
    noteDuration = secondsPerBeat / 8  
    note_name$ = "thirty-second"
elsif note_value = 2
    noteDuration = secondsPerBeat / 4  
    note_name$ = "sixteenth"
elsif note_value = 3
    noteDuration = secondsPerBeat / 2  
    note_name$ = "eighth"
elsif note_value = 4
    noteDuration = secondsPerBeat      
    note_name$ = "quarter"
elsif note_value = 5
    noteDuration = secondsPerBeat * 2  
    note_name$ = "half"
elsif note_value = 6
    noteDuration = (secondsPerBeat / 4) * (2/3)
    note_name$ = "sixteenth triplet"
elsif note_value = 7
    noteDuration = (secondsPerBeat / 2) * (2/3)
    note_name$ = "eighth triplet"
elsif note_value = 8
    noteDuration = secondsPerBeat * (2/3)
    note_name$ = "quarter triplet"
elsif note_value = 9
    noteDuration = secondsPerBeat / 4 * 1.5  
    note_name$ = "dotted sixteenth"
elsif note_value = 10
    noteDuration = secondsPerBeat / 2 * 1.5  
    note_name$ = "dotted eighth"
elsif note_value = 11
    noteDuration = secondsPerBeat * 1.5      
    note_name$ = "dotted quarter"
elsif note_value = 12
    noteDuration = secondsPerBeat * 2 * 1.5  
    note_name$ = "dotted half"
endif

appendInfoLine: "Note value: ", note_name$, " note (", fixed$(noteDuration, 3), " sec)"

# Determine which beat to use based on selection mode
if beat_selection_mode = 1
    # Specific beat number
    selectedBeat = specific_beat
    if selectedBeat < 1
        selectedBeat = 1
    endif
    if selectedBeat > totalBeats
        selectedBeat = totalBeats
    endif
    appendInfoLine: "Mode: Specific beat #", selectedBeat
    
elsif beat_selection_mode = 2
    # Random beat (avoid first and last beat)
    if totalBeats > 2
        selectedBeat = randomInteger(2, totalBeats - 1)
    else
        selectedBeat = 1
    endif
    appendInfoLine: "Mode: Random beat #", selectedBeat
    
elsif beat_selection_mode = 3
    # Beat range - will process multiple beats
    rangeStart = beat_range_start
    rangeEnd = beat_range_end
    if rangeStart < 1
        rangeStart = 1
    endif
    if rangeEnd > totalBeats
        rangeEnd = totalBeats
    endif
    if rangeStart > rangeEnd
        temp = rangeStart
        rangeStart = rangeEnd
        rangeEnd = temp
    endif
    appendInfoLine: "Mode: Beat range #", rangeStart, " to #", rangeEnd
    selectedBeat = rangeStart
    
else
    # Auto mode (1 second in, or 25% of duration)
    startTime = 1.0
    if duration < 2.0
        startTime = duration * 0.25
    endif
    selectedBeat = floor(startTime / secondsPerBeat) + 1
    appendInfoLine: "Mode: Auto-selected beat #", selectedBeat
endif

# Calculate start time based on selected beat
if beat_selection_mode <> 4
    startTime = (selectedBeat - 1) * secondsPerBeat
else
    # Auto mode already set startTime
endif

# Ensure we don't go past the end
if startTime + noteDuration > duration
    startTime = duration - noteDuration
    if startTime < 0
        startTime = 0
        noteDuration = duration
    endif
endif

appendInfoLine: "Start time: ", fixed$(startTime, 3), " seconds (beat ", selectedBeat, ")"

# Extract the segment to repeat
selectObject: sound
segment = Extract part: startTime, startTime + noteDuration, "rectangular", 1.0, "no"
Rename: sound_name$ + "_segment"

# Check segment audio level
selectObject: segment
segment_rms = Get root-mean-square: 0, 0
appendInfoLine: "Segment RMS: ", fixed$(segment_rms, 6)

if segment_rms < 0.0001
    appendInfoLine: "WARNING: Segment is very quiet"
    appendInfoLine: "Consider selecting a different beat"
endif

# Apply fade to repeats if requested
if fade_repeats = 1
    selectObject: segment
    Fade in: 0, 0, fade_duration, "yes"
    Fade out: 0, 0, fade_duration, "yes"
endif

# Create before part
selectObject: sound
if startTime > 0
    before = Extract part: 0, startTime, "rectangular", 1.0, "no"
    hasBefore = 1
else
    hasBefore = 0
endif

# Create repeats with amplitude decay
appendInfoLine: "Creating ", num_repeats, " repeats..."

selectObject: segment
repeated = Copy: "temp_first_repeat"

for i from 2 to num_repeats
    selectObject: segment
    this_repeat = Copy: "temp_repeat_" + string$(i)
    
    # Apply amplitude decay
    decayFactor = amplitude_decay^(i-1)
    Formula: "self * " + string$(decayFactor)
    
    # Concatenate
    selectObject: repeated, this_repeat
    new_repeated = Concatenate
    removeObject: repeated, this_repeat
    repeated = new_repeated
endfor

Rename: sound_name$ + "_repeated"

# Get repeated section duration
selectObject: repeated
repeatedDuration = Get total duration
afterStart = startTime + noteDuration

appendInfoLine: "Repeated section duration: ", fixed$(repeatedDuration, 3), " seconds"

# Handle beat range mode
if beat_selection_mode = 3
    # For beat range, we extend the afterStart to skip the entire range
    rangeLength = (rangeEnd - rangeStart + 1) * secondsPerBeat
    afterStart = startTime + rangeLength
    appendInfoLine: "Beat range covers: ", fixed$(rangeLength, 3), " seconds"
endif

# Create after part
selectObject: sound
if afterStart < duration
    after = Extract part: afterStart, duration, "rectangular", 1.0, "no"
    hasAfter = 1
else
    hasAfter = 0
endif

# Create final result
appendInfoLine: "Creating final result..."

if hasBefore = 1 and hasAfter = 1
    selectObject: before, repeated, after
    result = Concatenate
    removeObject: before, after
elsif hasBefore = 1 and hasAfter = 0
    selectObject: before, repeated
    result = Concatenate
    removeObject: before
elsif hasBefore = 0 and hasAfter = 1
    selectObject: repeated, after
    result = Concatenate
    removeObject: after
else
    selectObject: repeated
    result = Copy: sound_name$ + "_beat_repeat"
endif

Rename: sound_name$ + "_beat_repeat"

# Final cleanup
nocheck removeObject: segment
nocheck removeObject: repeated

selectObject: result
resultDuration = Get total duration
final_rms = Get root-mean-square: 0, 0

appendInfoLine: ""
appendInfoLine: "=== Result ==="
appendInfoLine: "Output duration: ", fixed$(resultDuration, 3), " seconds"
appendInfoLine: "Final RMS: ", fixed$(final_rms, 6)

if final_rms < 0.0001
    appendInfoLine: "WARNING: Output is very quiet!"
    appendInfoLine: "Try a different beat or increase amplitude_decay"
else
    appendInfoLine: "Beat repeat effect complete!"
endif

appendInfoLine: ""
appendInfoLine: "The new sound '", sound_name$, "_beat_repeat' has been created."

# Play the result
Play

# Select the result
selectObject: result