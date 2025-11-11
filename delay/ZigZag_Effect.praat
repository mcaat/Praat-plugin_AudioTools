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

form ZigZag Time Effect
    optionmenu Preset: 1
        option "Default (moderate zigzag)"
        option "Subtle Stutter"
        option "Aggressive Glitch"
        option "Tape Wobble"
        option "Custom"
    comment ZigZag parameters:
    positive zigzag_time 0.05
    positive forward_ratio 0.6
    positive segment_overlap 0.002
    comment Direction change parameters:
    natural direction_changes_per_second 20
    positive backward_distance_factor 0.8
    comment Envelope smoothing:
    optionmenu Window_type: 1
        option Hanning
        option Hamming
        option Rectangular
    comment Variation controls:
    positive segment_duration_variation 0.15
    positive amplitude_variation 0.1
    comment Output options:
    positive scale_peak 0.91
    boolean play_after_processing 1
    comment Random seed (optional, leave unchecked for random):
    boolean use_random_seed 0
    positive random_seed 12345
endform

# Apply preset values if not Custom
if preset = 1
    # Default (moderate zigzag)
    zigzag_time = 0.05
    forward_ratio = 0.6
    segment_overlap = 0.002
    direction_changes_per_second = 20
    backward_distance_factor = 0.8
    segment_duration_variation = 0.15
    amplitude_variation = 0.1
elsif preset = 2
    # Subtle Stutter
    zigzag_time = 0.08
    forward_ratio = 0.75
    segment_overlap = 0.003
    direction_changes_per_second = 12
    backward_distance_factor = 0.5
    segment_duration_variation = 0.08
    amplitude_variation = 0.05
elsif preset = 3
    # Aggressive Glitch
    zigzag_time = 0.03
    forward_ratio = 0.5
    segment_overlap = 0.001
    direction_changes_per_second = 35
    backward_distance_factor = 1.2
    segment_duration_variation = 0.25
    amplitude_variation = 0.2
elsif preset = 4
    # Tape Wobble
    zigzag_time = 0.12
    forward_ratio = 0.65
    segment_overlap = 0.005
    direction_changes_per_second = 8
    backward_distance_factor = 0.6
    segment_duration_variation = 0.12
    amplitude_variation = 0.08
endif

# Check if a sound object is selected
if !selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get selected sound info
soundID = selected("Sound")
soundName$ = selected$("Sound")
totalDuration = Get total duration
sampleRate = Get sampling frequency

# Validate parameters
if zigzag_time >= totalDuration
    exitScript: "ZigZag time (" + string$(zigzag_time) + " s) must be less than sound duration (" + string$(totalDuration) + " s)."
endif

# Set random seed if specified
if use_random_seed
    randomSeed: random_seed
endif

# Calculate segment duration based on direction changes per second
segment_duration = 1.0 / direction_changes_per_second

# Ensure segment duration is reasonable
if segment_duration > zigzag_time
    segment_duration = zigzag_time / 2
endif

# Calculate total number of segments needed
estimatedSegments = ceiling(totalDuration / (segment_duration * forward_ratio))

# Array to store segment IDs
segmentIDs# = zero#(estimatedSegments * 2)
segmentCount = 0

# Current playback position
currentPosition = 0.0

# Window type for extraction
if window_type = 1
    windowName$ = "Hanning"
elsif window_type = 2
    windowName$ = "Hamming"
else
    windowName$ = "Rectangular"
endif

# Main zigzag processing loop
writeInfoLine: "Processing ZigZag effect..."
appendInfoLine: "Total duration: ", totalDuration, " s"
appendInfoLine: "Segment duration: ", segment_duration, " s"
appendInfoLine: "ZigZag time window: ", zigzag_time, " s"
appendInfoLine: ""

# Direction flag (1 = forward, -1 = backward)
direction = 1

while currentPosition < totalDuration
    segmentCount += 1
    
    if direction = 1
        # Forward segment
        # Randomize segment duration
        currentSegDuration = segment_duration * randomUniform(1.0 - segment_duration_variation, 1.0 + segment_duration_variation)
        
        startTime = currentPosition
        endTime = currentPosition + currentSegDuration
        
        # Ensure we don't exceed total duration
        if endTime > totalDuration
            endTime = totalDuration
        endif
        
        # Extract forward segment
        selectObject: soundID
        extractedID = Extract part: startTime, endTime, windowName$, 1, "no"
        segmentIDs#[segmentCount] = extractedID
        
        # Apply amplitude variation
        ampFactor = randomUniform(1.0 - amplitude_variation, 1.0 + amplitude_variation)
        Formula: "self * ampFactor"
        
        # Move position forward
        currentPosition += currentSegDuration * forward_ratio
        
        # Switch to backward
        direction = -1
        
    else
        # Backward segment
        # Randomize segment duration
        currentSegDuration = segment_duration * randomUniform(1.0 - segment_duration_variation, 1.0 + segment_duration_variation)
        
        # Calculate backward distance
        backwardDistance = currentSegDuration * backward_distance_factor
        
        # Calculate start and end for backward segment
        backStartPos = currentPosition - backwardDistance
        if backStartPos < 0
            backStartPos = 0
        endif
        
        startTime = backStartPos
        endTime = backStartPos + currentSegDuration
        
        # Ensure we don't exceed bounds
        if endTime > totalDuration
            endTime = totalDuration
            startTime = endTime - currentSegDuration
            if startTime < 0
                startTime = 0
            endif
        endif
        
        # Extract backward segment and reverse it
        selectObject: soundID
        extractedID = Extract part: startTime, endTime, windowName$, 1, "no"
        Reverse
        segmentIDs#[segmentCount] = selected("Sound")
        
        # Apply amplitude variation
        ampFactor = randomUniform(1.0 - amplitude_variation, 1.0 + amplitude_variation)
        Formula: "self * ampFactor"
        
        # Continue moving forward overall
        currentPosition += currentSegDuration * forward_ratio * 0.3
        
        # Switch back to forward
        direction = 1
    endif
    
    # Progress indicator
    if segmentCount mod 50 = 0
        progressPercent = round((currentPosition / totalDuration) * 100)
        appendInfoLine: "Processed ", segmentCount, " segments (", progressPercent, "% complete)..."
    endif
    
    # Safety limit
    if segmentCount >= estimatedSegments * 2
        break
    endif
endwhile

appendInfoLine: "Total segments created: ", segmentCount
appendInfoLine: "Concatenating segments..."

# Select all segments and concatenate
if segmentCount > 0
    selectObject: segmentIDs#[1]
    for seg from 2 to segmentCount
        if segmentIDs#[seg] != 0
            plusObject: segmentIDs#[seg]
        endif
    endfor
    
    # Concatenate with overlap
    if segment_overlap > 0
        concatenatedID = Concatenate with overlap: segment_overlap
    else
        concatenatedID = Concatenate
    endif
    
    Rename: soundName$ + "_zigzag"
    
    # Scale to peak
    Scale peak: scale_peak
    
    appendInfoLine: "ZigZag effect complete!"
    
    # Clean up: remove individual segments
    for seg from 1 to segmentCount
        if segmentIDs#[seg] != 0
            removeObject: segmentIDs#[seg]
        endif
    endfor
    
    # Play if requested
    if play_after_processing
        Play
    endif
else
    exitScript: "No segments were created. Check your parameters."
endif