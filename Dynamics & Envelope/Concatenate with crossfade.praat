# ============================================================
# Praat AudioTools - Concatenate with crossfade 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Concatenate with crossfade
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Concatenate selected sounds with 25% crossfade
form Concatenate with crossfade
    boolean Randomize_order 1
endform

fade_percentage = 25
fade_ratio = fade_percentage / 100

n = numberOfSelected("Sound")
if n < 2
    exitScript: "Please select at least 2 Sound objects"
endif

# Store sound IDs
for i to n
    sound[i] = selected("Sound", i)
endfor

# Randomize order if requested
if randomize_order
    for i to n
        j = randomInteger(1, n)
        temp = sound[i]
        sound[i] = sound[j]
        sound[j] = temp
    endfor
endif

# Start with first sound
selectObject: sound[1]
result = Copy: "crossfaded"

# Process each subsequent sound
for i from 2 to n
    # Get duration of incoming sound for overlap calculation
    selectObject: sound[i]
    current_duration = Get total duration
    overlap_time = current_duration * fade_ratio
    
    # Copy incoming sound
    incoming = Copy: "temp_incoming"
    
    # Apply fades
    selectObject: result
    result_duration = Get total duration
    fade_start = result_duration - overlap_time
    Fade out: 0, fade_start, overlap_time, "yes"
    
    selectObject: incoming
    Fade in: 0, 0, overlap_time, "yes"
    
    # Concatenate with overlap (result must be selected first)
    selectObject: result
    plusObject: incoming
    new_result = Concatenate with overlap: overlap_time
    
    # Clean up temporary objects
    removeObject: result, incoming
    result = new_result
endfor

# Normalize and play
selectObject: result
Rename: "concatenated_crossfade"
Scale peak: 0.99
Play