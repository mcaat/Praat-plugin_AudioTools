# ============================================================
# Praat AudioTools - Random Sound Extractor.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Random Sound Extractor
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Random Sound Extractor

form Extract Random Sound Segments
    positive number_of_segments 4
    real min_duration 0.25
    real max_duration 2.0
endform

# Get the selected sound
sound_name$ = selected$("Sound")
sound_id = selected("Sound")

# Error checking
if sound_id = undefined
    exitScript: "Please select a Sound object first."
endif

selectObject: sound_id
total_duration = Get total duration

# Check if durations are valid
if min_duration <= 0
    exitScript: "Durations must be positive numbers."
endif

if max_duration <= 0
    exitScript: "Durations must be positive numbers."
endif

if min_duration > max_duration
    exitScript: "Minimum duration cannot be larger than maximum duration."
endif

if max_duration > total_duration
    exitScript: "Maximum duration cannot be longer than the total sound duration."
endif

# Extract multiple random segments
for i to number_of_segments
    # Generate random duration between min and max
    segment_duration = randomUniform(min_duration, max_duration)
    
    # Generate random start time
    max_start_time = total_duration - segment_duration
    window_start = randomUniform(0, max_start_time)
    window_end = window_start + segment_duration

    # Extract the segment
    selectObject: sound_id
    segment = Extract part: window_start, window_end, "rectangular", 1, "no"

    # Rename with sequential numbering
    Rename: sound_name$ + "_segment_" + string$(i)
endfor
