# ============================================================
# Praat AudioTools - ZigZag_Effect.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Creates a zigzag time effect by moving forward and backward through
#   the audio timeline, creating rhythmic stuttering and glitchy textures.
#   The playback oscillates back and forth while progressing overall.
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ZigZag Time Effect (v5.0 - CDP Edition)
# Includes "Tape Scrub" mode (CDP Style) where backward segments are reversed.
# Optimization: Iterative Stitching (Memory Safe).

form ZigZag Time Effect
    optionmenu Preset: 1
        option "Default (Tape Scrub)"
        option "Subtle Stutter"
        option "Aggressive Glitch (CDP)"
        option "Tape Wobble"
        option "Custom"
    
    comment Mode:
    choice Playback_mode 2
        button Stutter (Always Play Forward)
        button Scrub (Reverse Audio when Moving Back)
    
    comment ZigZag parameters:
    positive Zigzag_time 0.05
    positive Forward_ratio 0.6
    positive Segment_overlap 0.002
    
    comment Direction change parameters:
    natural Direction_changes_per_second 20
    positive Backward_distance_factor 0.8
    
    comment Envelope smoothing:
    optionmenu Window_type: 1
        option Hanning
        option Hamming
        option Rectangular
    
    comment Variation controls:
    positive Segment_duration_variation 0.15
    positive Amplitude_variation 0.1
    
    comment Output options:
    positive Scale_peak 0.91
    boolean Play_after_processing 1
    
    comment Random seed:
    boolean Use_random_seed 0
    positive Random_seed 12345
endform

# --- 1. APPLY PRESETS ---
if preset = 1
    # Default (Tape Scrub - CDP Style)
    playback_mode = 2
    zigzag_time = 0.05
    forward_ratio = 0.6
    segment_overlap = 0.002
    direction_changes_per_second = 20
    backward_distance_factor = 0.8
    segment_duration_variation = 0.15
    amplitude_variation = 0.1
elsif preset = 2
    # Subtle Stutter (Original Style)
    playback_mode = 1
    zigzag_time = 0.08
    forward_ratio = 0.75
    segment_overlap = 0.003
    direction_changes_per_second = 12
    backward_distance_factor = 0.5
    segment_duration_variation = 0.08
    amplitude_variation = 0.05
elsif preset = 3
    # Aggressive Glitch (CDP Style)
    playback_mode = 2
    zigzag_time = 0.03
    forward_ratio = 0.5
    segment_overlap = 0.001
    direction_changes_per_second = 35
    backward_distance_factor = 1.2
    segment_duration_variation = 0.25
    amplitude_variation = 0.2
elsif preset = 4
    # Tape Wobble
    playback_mode = 2
    zigzag_time = 0.12
    forward_ratio = 0.65
    segment_overlap = 0.005
    direction_changes_per_second = 8
    backward_distance_factor = 0.6
    segment_duration_variation = 0.12
    amplitude_variation = 0.08
endif

# --- 2. SETUP ---
if !selected("Sound")
    exitScript: "Please select a Sound object first."
endif

soundID = selected("Sound")
soundName$ = selected$("Sound")
totalDuration = Get total duration
sampleRate = Get sampling frequency

if zigzag_time >= totalDuration
    exitScript: "ZigZag time must be less than sound duration."
endif

if use_random_seed
    randomSeed: random_seed
endif

# Base calculations
segment_duration = 1.0 / direction_changes_per_second
if segment_duration > zigzag_time
    segment_duration = zigzag_time / 2
endif

# Window type string
if window_type = 1
    windowName$ = "Hanning"
elsif window_type = 2
    windowName$ = "Hamming"
else
    windowName$ = "Rectangular"
endif

# Info Log
mode_str$ = "Stutter"
if playback_mode = 2
    mode_str$ = "Scrub (CDP)"
endif
writeInfoLine: "Processing ZigZag (" + mode_str$ + ")..."

# --- 3. PROCESSING LOOP ---
currentPosition = 0.0
direction = 1
segmentCount = 0
masterID = 0

while currentPosition < totalDuration
    segmentCount += 1
    
    # --- A. DETERMINE SEGMENT ---
    if direction = 1
        # -- FORWARD SEGMENT --
        var = randomUniform(1.0 - segment_duration_variation, 1.0 + segment_duration_variation)
        currentSegDuration = segment_duration * var
        
        startTime = currentPosition
        endTime = currentPosition + currentSegDuration
        
        # Clamp
        if endTime > totalDuration
            endTime = totalDuration
        endif
        
        # Extract
        selectObject: soundID
        grain = Extract part: startTime, endTime, windowName$, 1, "no"
        
        # Move Forward
        currentPosition += currentSegDuration * forward_ratio
        direction = -1
        
    else
        # -- BACKWARD SEGMENT --
        var = randomUniform(1.0 - segment_duration_variation, 1.0 + segment_duration_variation)
        currentSegDuration = segment_duration * var
        
        backwardDistance = currentSegDuration * backward_distance_factor
        backStartPos = currentPosition - backwardDistance
        if backStartPos < 0
            backStartPos = 0
        endif
        
        startTime = backStartPos
        endTime = backStartPos + currentSegDuration
        
        # Clamp
        if endTime > totalDuration
            endTime = totalDuration
            startTime = endTime - currentSegDuration
            if startTime < 0
                startTime = 0
            endif
        endif
        
        # Extract
        selectObject: soundID
        grain = Extract part: startTime, endTime, windowName$, 1, "no"
        
        # [THE CDP FIX]
        # If we are in Scrub Mode (2), we REVERSE the backward segments.
        if playback_mode = 2
            Reverse
        endif
        
        # Move Forward slightly
        currentPosition += currentSegDuration * forward_ratio * 0.3
        direction = 1
    endif
    
    # --- B. AMPLITUDE JITTER ---
    selectObject: grain
    ampFactor = randomUniform(1.0 - amplitude_variation, 1.0 + amplitude_variation)
    Formula: "self * " + fixed$(ampFactor, 4)
    
    # --- C. STITCHING (Memory Safe) ---
    if masterID = 0
        # First segment
        masterID = grain
        Rename: "Output_Temp"
    else
        # Append to Master
        selectObject: masterID
        plusObject: grain
        
        if segment_overlap > 0
            # Overlap-add smooths the seams between forward/reverse
            tempID = Concatenate with overlap: segment_overlap
        else
            tempID = Concatenate
        endif
        
        # Clean up immediately
        removeObject: masterID
        removeObject: grain
        
        # Update Master
        masterID = tempID
        Rename: "Output_Temp"
    endif
    
    # Progress
    if segmentCount mod 50 = 0
        perc = round((currentPosition / totalDuration) * 100)
        appendInfoLine: "Segment: ", segmentCount, " (", perc, "%)"
    endif
endwhile

# --- 4. FINALIZE ---
selectObject: masterID
Rename: soundName$ + "_ZigZag"
Scale peak: scale_peak

appendInfoLine: "Done! Created ", segmentCount, " segments."

if play_after_processing
    Play
endif