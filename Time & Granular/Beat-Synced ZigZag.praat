# ============================================================
# Praat AudioTools - Beat-Synced ZigZag.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Beat-Synced ZigZag
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Beat-Synced ZigZag - Musical Time
# Reverses alternating segments synced to musical tempo
# Sha - Praat AudioTools

form ZigZag parameters
    comment Processing mode:
    optionmenu Mode: 1
        option Whole selection (musical time)
        option Tail segments (from midpoint)
    comment Musical timing:
    optionmenu BPM_mode: 1
        option Auto-detect from duration
        option Manual BPM
    positive Number_of_bars 4
    comment (For auto-detect: how many bars in the selection?)
    positive Manual_BPM 120
    comment (For manual mode)
    optionmenu Time_signature: 1
        option 4/4
        option 3/4
        option 6/8
        option 5/4
    optionmenu Subdivision: 2
        option Bars (whole bars)
        option Beats (quarter notes)
        option Eighth notes
        option Sixteenth notes
        option Thirty-second notes
endform

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
dur = Get total duration
start = Get start time
end = Get end time

# Determine beats per bar
if time_signature = 1
    beats_per_bar = 4
elsif time_signature = 2
    beats_per_bar = 3
elsif time_signature = 3
    beats_per_bar = 6
elsif time_signature = 4
    beats_per_bar = 5
endif

# Calculate BPM
if bPM_mode = 1
    # Auto-detect: duration contains N bars
    total_beats = number_of_bars * beats_per_bar
    bpm = (total_beats / dur) * 60
    writeInfoLine: "Auto-detected BPM: ", fixed$(bpm, 2)
else
    bpm = manual_BPM
    writeInfoLine: "Using BPM: ", bpm
endif

# Calculate beat duration
beat_dur = 60 / bpm

# Calculate segment duration based on subdivision
if subdivision = 1
    # Bars
    seg_dur = beat_dur * beats_per_bar
    subdiv_name$ = "bars"
elsif subdivision = 2
    # Beats (quarter notes)
    seg_dur = beat_dur
    subdiv_name$ = "beats"
elsif subdivision = 3
    # Eighth notes
    seg_dur = beat_dur / 2
    subdiv_name$ = "8ths"
elsif subdivision = 4
    # Sixteenth notes
    seg_dur = beat_dur / 4
    subdiv_name$ = "16ths"
elsif subdivision = 5
    # Thirty-second notes
    seg_dur = beat_dur / 8
    subdiv_name$ = "32nds"
endif

appendInfoLine: "Segment duration: ", fixed$(seg_dur * 1000, 2), " ms (", subdiv_name$, ")"

if mode = 1
    # Whole sound mode
    process_start = start
    num_segs = floor(dur / seg_dur)
else
    # Tail segments mode - start from midpoint
    process_start = start + (dur / 2)
    num_segs = floor((end - process_start) / seg_dur)
endif

appendInfoLine: "Number of segments: ", num_segs

# Create array to hold segments
for i to num_segs
    seg_start = process_start + (i - 1) * seg_dur
    seg_end = seg_start + seg_dur
    
    # Make sure we don't exceed sound boundaries
    if seg_end > end
        seg_end = end
    endif
    
    selectObject: sound
    segment[i] = Extract part: seg_start, seg_end, "rectangular", 1, "no"
    
    # Reverse every other segment (odd numbered segments)
    if i mod 2 = 1
        Reverse
    endif
endfor

# If tail mode, also need the head (before processing point)
if mode = 2
    selectObject: sound
    head = Extract part: start, process_start, "rectangular", 1, "no"
endif

# Concatenate all segments
if mode = 1
    # Whole sound mode
    selectObject: segment[1]
    for i from 2 to num_segs
        plusObject: segment[i]
    endfor
else
    # Tail mode - concatenate head first, then segments
    selectObject: head
    for i to num_segs
        plusObject: segment[i]
    endfor
endif

result = Concatenate
Rename: sound_name$ + "_zigzag_" + subdiv_name$

# Clean up
if mode = 2
    removeObject: head
endif
for i to num_segs
    removeObject: segment[i]
endfor
Play