# ============================================================
# Praat AudioTools - 8-channel speed deviations.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   DBAP (Distance-Based Amplitude Panning) with Movement Control
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
clearinfo
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one sound object."
endif

sound = selected("Sound")
selectObject: sound
sound_name$ = selected$("Sound")
duration = Get total duration
original_fs = Get sampling frequency

form DBAP Movement Control
    comment Movement trajectory settings:
    optionmenu movement_type: 1
        option Linear
        option Circular
        option Figure-8
        option Spiral In
        option Spiral Out
        option Pendulum
        option Zigzag
        option Random Walk
        option Ellipse
        option Square
    real start_x -1.0
    real start_y 0.0
    real end_x 1.0
    real end_y 0.0
    real radius 0.4
    real speed 1.0
    
    comment Speaker configuration:
    optionmenu preset: 1
        option Stereo (2 speakers)
        option Triangle (3 speakers)
        option Quad (4 speakers)
        option Pentagon (5 speakers)
        option Hexagon (6 speakers)
        option Surround 5.1 (6 speakers)
        option Surround 7.1 (8 speakers)
        option Octagon (8 speakers)
    
    comment Processing settings:
    positive chunk_duration 0.05
    positive rolloff 1.0
    boolean normalize_gains 1
endform

if preset = 1
    number_of_speakers = 2
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    
elsif preset = 2
    number_of_speakers = 3
    speakerX1 = -0.866
    speakerY1 = -0.5
    speakerX2 = 0.866
    speakerY2 = -0.5
    speakerX3 = 0.0
    speakerY3 = 1.0
    
elsif preset = 3
    number_of_speakers = 4
    for i to 4
        angle = (i - 1) * 2 * pi / 4
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor

elsif preset = 4
    number_of_speakers = 5
    for i to 5
        angle = (i - 1) * 2 * pi / 5 - pi / 2
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor

elsif preset = 5
    number_of_speakers = 6
    for i to 6
        angle = (i - 1) * 2 * pi / 6
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor
    
elsif preset = 6
    number_of_speakers = 6
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    speakerX3 = 0.0
    speakerY3 = 1.0
    speakerX4 = -0.7
    speakerY4 = -0.7
    speakerX5 = 0.7
    speakerY5 = -0.7
    speakerX6 = 0.0
    speakerY6 = 0.0

elsif preset = 7
    number_of_speakers = 8
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    speakerX3 = 0.0
    speakerY3 = 1.0
    speakerX4 = -0.7
    speakerY4 = 0.7
    speakerX5 = 0.7
    speakerY5 = 0.7
    speakerX6 = -0.7
    speakerY6 = -0.7
    speakerX7 = 0.7
    speakerY7 = -0.7
    speakerX8 = 0.0
    speakerY8 = 0.0

elsif preset = 8
    number_of_speakers = 8
    for i to 8
        angle = (i - 1) * 2 * pi / 8
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor
endif

selectObject: sound
num_channels = Get number of channels
if num_channels > 1
    appendInfoLine: "Converting to mono..."
    monoSound = Convert to mono
else
    monoSound = Copy: "mono_copy"
endif

selectObject: monoSound
fs = Get sampling frequency

num_chunks = ceiling(duration / chunk_duration)

appendInfoLine: "Processing DBAP with ", number_of_speakers, " speakers..."
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: "Chunk duration: ", fixed$(chunk_duration, 3), " seconds"
appendInfoLine: "Number of chunks: ", num_chunks

for speaker to number_of_speakers
    speakerSound'speaker' = 0
endfor

for chunk to num_chunks
    chunk_start = (chunk - 1) * chunk_duration
    chunk_end = chunk_start + chunk_duration
    if chunk_end > duration
        chunk_end = duration
    endif
    
    chunk_middle = (chunk_start + chunk_end) / 2
    progress = chunk_middle / duration
    
    if movement_type = 1
        source_x = start_x + (end_x - start_x) * progress
        source_y = start_y + (end_y - start_y) * progress
        
    elsif movement_type = 2
        angle = progress * 2 * pi * speed
        source_x = radius * cos(angle)
        source_y = radius * sin(angle)
        
    elsif movement_type = 3
        angle = progress * 4 * pi * speed
        source_x = radius * sin(angle)
        source_y = radius * sin(2 * angle) / 2

    elsif movement_type = 4
        angle = progress * 4 * pi * speed
        current_radius = radius * (1 - progress)
        source_x = current_radius * cos(angle)
        source_y = current_radius * sin(angle)

    elsif movement_type = 5
        angle = progress * 4 * pi * speed
        current_radius = radius * progress
        source_x = current_radius * cos(angle)
        source_y = current_radius * sin(angle)

    elsif movement_type = 6
        swing_angle = sin(progress * pi * speed * 4) * pi / 3
        source_x = radius * sin(swing_angle)
        source_y = -radius * cos(swing_angle) * 0.5

    elsif movement_type = 7
        num_zigs = 4 * speed
        zig_progress = (progress * num_zigs) mod 1
        zig_num = floor(progress * num_zigs)
        if zig_num mod 2 = 0
            source_x = -radius + 2 * radius * zig_progress
        else
            source_x = radius - 2 * radius * zig_progress
        endif
        source_y = -radius + 2 * radius * progress

    elsif movement_type = 8
        angle1 = progress * 137.5 * speed
        angle2 = progress * 97.3 * speed
        source_x = radius * sin(angle1) * 0.7
        source_y = radius * cos(angle2) * 0.7

    elsif movement_type = 9
        angle = progress * 2 * pi * speed
        source_x = radius * 1.4 * cos(angle)
        source_y = radius * 0.7 * sin(angle)

    elsif movement_type = 10
        side_progress = (progress * 4 * speed) mod 1
        side_num = floor((progress * 4 * speed) mod 4)
        if side_num = 0
            source_x = -radius + 2 * radius * side_progress
            source_y = radius
        elsif side_num = 1
            source_x = radius
            source_y = radius - 2 * radius * side_progress
        elsif side_num = 2
            source_x = radius - 2 * radius * side_progress
            source_y = -radius
        else
            source_x = -radius
            source_y = -radius + 2 * radius * side_progress
        endif
    endif
    
    total_power = 0
    for speaker to number_of_speakers
        sp_x = speakerX'speaker'
        sp_y = speakerY'speaker'
        
        dx = source_x - sp_x
        dy = source_y - sp_y
        distance = sqrt(dx * dx + dy * dy)
        
        min_distance = 0.01
        if distance < min_distance
            distance = min_distance
        endif
        
        gain'speaker' = 1 / (distance ^ rolloff)
        total_power = total_power + (gain'speaker' * gain'speaker')
    endfor
    
    if normalize_gains and total_power > 0
        normalization = sqrt(total_power)
        for speaker to number_of_speakers
            gain'speaker' = gain'speaker' / normalization
        endfor
    endif
    
    selectObject: monoSound
    chunkSound = Extract part: chunk_start, chunk_end, "rectangular", 1, "no"
    
    for speaker to number_of_speakers
        selectObject: chunkSound
        gainedChunk = Copy: "gained"
        
        gain_value = gain'speaker'
        Formula: "self * " + string$(gain_value)
        
        if speakerSound'speaker' = 0
            speakerSound'speaker' = gainedChunk
        else
            selectObject: speakerSound'speaker'
            plusObject: gainedChunk
            tempSound = Concatenate
            removeObject: speakerSound'speaker'
            removeObject: gainedChunk
            speakerSound'speaker' = tempSound
        endif
    endfor
    
    removeObject: chunkSound
    
    if chunk mod 10 = 0 or chunk = num_chunks
        percent = (chunk / num_chunks) * 100
        appendInfoLine: "Processed chunk ", chunk, "/", num_chunks, " (", fixed$(percent, 1), "%)"
        appendInfoLine: "  Position: x=", fixed$(source_x, 3), ", y=", fixed$(source_y, 3)
    endif
endfor

appendInfoLine: "Combining channels..."
selectObject: speakerSound1
for speaker from 2 to number_of_speakers
    plusObject: speakerSound'speaker'
endfor

if number_of_speakers = 2
    combinedSound = Combine to stereo
else
    combinedSound = Combine to stereo
endif
selectObject: combinedSound
Rename: sound_name$ + "_DBAP_" + string$(number_of_speakers) + "ch"
resultSound = combinedSound

selectObject: resultSound
channels = Get number of channels
result_duration = Get total duration

appendInfoLine: ""
appendInfoLine: "=== DBAP Processing Complete ==="
appendInfoLine: "Output: ", selected$("Sound")
appendInfoLine: "Channels: ", channels
appendInfoLine: "Duration: ", fixed$(result_duration, 3), "s"
appendInfoLine: "Sampling frequency: ", fs, " Hz"

selectObject: resultSound
Play

removeObject: monoSound
for speaker to number_of_speakers
    removeObject: speakerSound'speaker'
endfor

selectObject: resultSound

appendInfoLine: "Done! Original sound and DBAP result are selected."