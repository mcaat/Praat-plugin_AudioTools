# ============================================================
# Praat AudioTools - Hexaphonic Serial Audio Processor.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   erialist Amplitude Modulation Audio Effect
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Serialist Amplitude Modulation Audio Effect
# Applies ring modulation using 12-tone serial rows with transformations
# Sha - Bar-Ilan University

form Serialist Amplitude Modulation Effect
    comment Select a Sound object first, then run this script
    comment ═══════════════════════════════════════════════
    optionmenu Preset 1
        option Custom
        option Classic Webern
        option Berg Symmetrical
        option Schoenberg Op.25
        option Chromatic Ascent
        option All-Interval
        option Pentatonic Serial
        option Whole-Tone Serial
        option Random Chaos
    comment ═══════════════════════════════════════════════
    comment PRIME ROW DEFINITIONS (values 0-11):
    sentence mod_rate_row 0 3 7 11 2 6 9 1 5 8 4 10
    sentence mod_depth_row 5 9 2 11 0 7 3 10 1 6 8 4
    sentence mod_shape_row 2 8 5 0 11 3 7 1 9 4 10 6
    sentence duration_row 6 2 9 1 11 4 8 0 7 3 10 5
    sentence panning_row 4 8 1 10 3 7 0 11 5 9 2 6
    sentence speed_row 6 5 7 4 8 3 9 2 10 1 11 0
    comment ═══════════════════════════════════════════════
    comment PARAMETER RANGES:
    positive min_rate 0.5
    positive max_rate 50
    positive min_depth 0.05
    positive max_depth 0.95
    positive min_duration 0.1
    positive max_duration 3.0
    comment ═══════════════════════════════════════════════
    boolean perceptual_rate_scaling 1
    comment Shape: 0-2=sine, 3-5=triangle, 6-8=square, 9-11=sawtooth
    comment Panning: 0=left, 6=center, 11=right
    comment Speed: 0=-6 semitones, 6=original, 11=+5 semitones
endform

# Apply preset values
if preset = 2
    # Classic Webern - symmetrical structure
    mod_rate_row$ = "0 11 3 8 4 7 9 2 10 1 5 6"
    mod_depth_row$ = "0 1 2 3 4 5 6 7 8 9 10 11"
    mod_shape_row$ = "0 3 6 9 1 4 7 10 2 5 8 11"
    duration_row$ = "5 6 4 7 3 8 2 9 1 10 0 11"
    panning_row$ = "6 5 7 4 8 3 9 2 10 1 11 0"
    speed_row$ = "6 6 6 5 7 5 7 6 6 6 6 6"
elsif preset = 3
    # Berg Symmetrical - palindromic tendencies
    mod_rate_row$ = "0 11 7 4 2 9 3 8 10 1 5 6"
    mod_depth_row$ = "5 10 2 7 11 1 8 4 9 0 6 3"
    mod_shape_row$ = "6 5 4 3 2 1 0 11 10 9 8 7"
    duration_row$ = "0 1 2 3 4 5 6 7 8 9 10 11"
    panning_row$ = "0 2 4 6 8 10 11 9 7 5 3 1"
    speed_row$ = "6 7 5 8 4 9 3 10 2 11 1 0"
elsif preset = 4
    # Schoenberg Op.25 - famous row
    mod_rate_row$ = "4 5 7 1 6 3 8 2 11 0 9 10"
    mod_depth_row$ = "0 6 5 11 10 4 3 9 8 2 1 7"
    mod_shape_row$ = "8 10 11 1 3 4 6 7 9 0 2 5"
    duration_row$ = "3 9 2 8 1 7 0 6 11 5 10 4"
    panning_row$ = "2 8 4 10 0 6 11 5 9 3 7 1"
    speed_row$ = "5 6 7 6 5 7 6 5 6 7 5 6"
elsif preset = 5
    # Chromatic Ascent
    mod_rate_row$ = "0 1 2 3 4 5 6 7 8 9 10 11"
    mod_depth_row$ = "11 10 9 8 7 6 5 4 3 2 1 0"
    mod_shape_row$ = "0 2 4 6 8 10 1 3 5 7 9 11"
    duration_row$ = "6 7 5 8 4 9 3 10 2 11 1 0"
    panning_row$ = "0 1 2 3 4 5 6 7 8 9 10 11"
    speed_row$ = "0 1 2 3 4 5 6 7 8 9 10 11"
elsif preset = 6
    # All-Interval - contains all 11 intervals
    mod_rate_row$ = "0 1 4 2 9 5 11 3 8 10 7 6"
    mod_depth_row$ = "0 3 6 9 1 4 7 10 2 5 8 11"
    mod_shape_row$ = "0 5 10 3 8 1 6 11 4 9 2 7"
    duration_row$ = "2 7 1 8 0 9 11 4 10 3 5 6"
    panning_row$ = "1 5 9 2 6 10 3 7 11 4 8 0"
    speed_row$ = "4 8 2 10 1 7 0 9 3 11 5 6"
elsif preset = 7
    # Pentatonic Serial - emphasizes pentatonic intervals
    mod_rate_row$ = "0 2 4 7 9 1 3 5 8 10 6 11"
    mod_depth_row$ = "0 5 7 2 9 4 11 6 1 8 3 10"
    mod_shape_row$ = "0 7 2 9 4 11 6 1 8 3 10 5"
    duration_row$ = "1 6 3 8 5 10 7 2 9 4 11 0"
    panning_row$ = "0 7 2 9 4 11 6 1 8 3 10 5"
    speed_row$ = "6 5 7 6 5 7 6 5 7 6 5 7"
elsif preset = 8
    # Whole-Tone Serial
    mod_rate_row$ = "0 2 4 6 8 10 1 3 5 7 9 11"
    mod_depth_row$ = "1 3 5 7 9 11 0 2 4 6 8 10"
    mod_shape_row$ = "0 6 1 7 2 8 3 9 4 10 5 11"
    duration_row$ = "5 11 4 10 3 9 2 8 1 7 0 6"
    panning_row$ = "0 6 1 7 2 8 3 9 4 10 5 11"
    speed_row$ = "6 8 4 10 2 8 4 10 2 8 4 10"
elsif preset = 9
    # Random Chaos - generate random rows
    mod_rate_row$ = ""
    mod_depth_row$ = ""
    mod_shape_row$ = ""
    duration_row$ = ""
    panning_row$ = ""
    speed_row$ = ""
    # Generate random permutations for all six rows
    for row_num from 1 to 6
        for i from 0 to 11
            available[i] = i
        endfor
        temp_row$ = ""
        for i from 0 to 11
            remaining = 11 - i
            pick = randomInteger(0, remaining)
            temp_row$ = temp_row$ + " " + string$(available[pick])
            for j from pick to remaining - 1
                available[j] = available[j + 1]
            endfor
        endfor
        if row_num = 1
            mod_rate_row$ = temp_row$
        elsif row_num = 2
            mod_depth_row$ = temp_row$
        elsif row_num = 3
            mod_shape_row$ = temp_row$
        elsif row_num = 4
            duration_row$ = temp_row$
        elsif row_num = 5
            panning_row$ = temp_row$
        elsif row_num = 6
            speed_row$ = temp_row$
        endif
    endfor
endif

# Get selected sound
soundID = selected("Sound")
soundName$ = selected$("Sound")
duration = Get total duration
sampling_frequency = Get sampling frequency
num_channels = Get number of channels

# Parse prime rows into arrays
@parseRow: mod_rate_row$
for i from 1 to 12
    rate_prime[i] = parseRow.values[i]
endfor

@parseRow: mod_depth_row$
for i from 1 to 12
    depth_prime[i] = parseRow.values[i]
endfor

@parseRow: mod_shape_row$
for i from 1 to 12
    shape_prime[i] = parseRow.values[i]
endfor

@parseRow: duration_row$
for i from 1 to 12
    dur_prime[i] = parseRow.values[i]
endfor

@parseRow: panning_row$
for i from 1 to 12
    pan_prime[i] = parseRow.values[i]
endfor

@parseRow: speed_row$
for i from 1 to 12
    speed_prime[i] = parseRow.values[i]
endfor

# Generate transformations for all rows
for i from 1 to 12
    # Inversion: 0→11, 1→10, etc.
    rate_inversion[i] = 11 - rate_prime[i]
    depth_inversion[i] = 11 - depth_prime[i]
    shape_inversion[i] = 11 - shape_prime[i]
    dur_inversion[i] = 11 - dur_prime[i]
    pan_inversion[i] = 11 - pan_prime[i]
    speed_inversion[i] = 11 - speed_prime[i]
    
    # Retrograde: reverse order
    rate_retrograde[i] = rate_prime[13 - i]
    depth_retrograde[i] = depth_prime[13 - i]
    shape_retrograde[i] = shape_prime[13 - i]
    dur_retrograde[i] = dur_prime[13 - i]
    pan_retrograde[i] = pan_prime[13 - i]
    speed_retrograde[i] = speed_prime[13 - i]
    
    # Retrograde-Inversion: reverse + invert
    rate_ri[i] = 11 - rate_prime[13 - i]
    depth_ri[i] = 11 - depth_prime[13 - i]
    shape_ri[i] = 11 - shape_prime[13 - i]
    dur_ri[i] = 11 - dur_prime[13 - i]
    pan_ri[i] = 11 - pan_prime[13 - i]
    speed_ri[i] = 11 - speed_prime[13 - i]
endfor

writeInfoLine: "═══════════════════════════════════════════"
appendInfoLine: "Serialist Amplitude Modulation Processing"
appendInfoLine: "═══════════════════════════════════════════"
appendInfoLine: "Sound: ", soundName$
appendInfoLine: "Duration: ", fixed$(duration, 3), " s"
appendInfoLine: "Perceptual rate scaling: ", perceptual_rate_scaling
appendInfoLine: ""
appendInfoLine: "PRIME ROWS:"
appendInfoLine: "Rate:     ", mod_rate_row$
appendInfoLine: "Depth:    ", mod_depth_row$
appendInfoLine: "Shape:    ", mod_shape_row$
appendInfoLine: "Duration: ", duration_row$
appendInfoLine: "Panning:  ", panning_row$
appendInfoLine: "Speed:    ", speed_row$
appendInfoLine: ""
appendInfoLine: "CROSS-COUPLING STRUCTURE:"
appendInfoLine: "Section A: rate=P,  depth=P,  shape=P,  dur=P,  pan=P,  speed=P"
appendInfoLine: "Section B: rate=I,  depth=R,  shape=P,  dur=I,  pan=R,  speed=I"
appendInfoLine: "Section C: rate=R,  depth=P,  shape=I,  dur=R,  pan=I,  speed=R"
appendInfoLine: "Section D: rate=RI, depth=I,  shape=R,  dur=RI, pan=P,  speed=RI"
appendInfoLine: ""

# Array to store all processed segments
segment_count = 0
current_time = 0

# Section A: Prime for all
appendInfoLine: "Section A: PRIME (P-P-P-P-P-P)"
for step from 1 to 12
    rate_val = rate_prime[step]
    depth_val = depth_prime[step]
    shape_val = shape_prime[step]
    dur_val = dur_prime[step]
    pan_val = pan_prime[step]
    speed_val = speed_prime[step]
    
    step_dur = min_duration + (dur_val / 11) * (max_duration - min_duration)
    
    if current_time + step_dur > duration
        step_dur = duration - current_time
    endif
    
    if step_dur > 0.01
        @processSegment: soundID, current_time, current_time + step_dur, rate_val, depth_val, shape_val, pan_val, speed_val
        segment_count = segment_count + 1
        segment[segment_count] = processSegment.result
        appendInfoLine: "  Step ", step, ": r=", rate_val, " d=", depth_val, " sh=", shape_val, " dur=", fixed$(step_dur, 2), " pan=", pan_val, " sp=", speed_val
        current_time = current_time + step_dur
    endif
endfor

# Section B: Cross-coupled (I-R-P-I-R-I)
appendInfoLine: ""
appendInfoLine: "Section B: CROSS-COUPLED (I-R-P-I-R-I)"
for step from 1 to 12
    rate_val = rate_inversion[step]
    depth_val = depth_retrograde[step]
    shape_val = shape_prime[step]
    dur_val = dur_inversion[step]
    pan_val = pan_retrograde[step]
    speed_val = speed_inversion[step]
    
    step_dur = min_duration + (dur_val / 11) * (max_duration - min_duration)
    
    if current_time + step_dur > duration
        step_dur = duration - current_time
    endif
    
    if step_dur > 0.01
        @processSegment: soundID, current_time, current_time + step_dur, rate_val, depth_val, shape_val, pan_val, speed_val
        segment_count = segment_count + 1
        segment[segment_count] = processSegment.result
        appendInfoLine: "  Step ", step, ": r=", rate_val, " d=", depth_val, " sh=", shape_val, " dur=", fixed$(step_dur, 2), " pan=", pan_val, " sp=", speed_val
        current_time = current_time + step_dur
    endif
endfor

# Section C: Cross-coupled (R-P-I-R-I-R)
appendInfoLine: ""
appendInfoLine: "Section C: CROSS-COUPLED (R-P-I-R-I-R)"
for step from 1 to 12
    rate_val = rate_retrograde[step]
    depth_val = depth_prime[step]
    shape_val = shape_inversion[step]
    dur_val = dur_retrograde[step]
    pan_val = pan_inversion[step]
    speed_val = speed_retrograde[step]
    
    step_dur = min_duration + (dur_val / 11) * (max_duration - min_duration)
    
    if current_time + step_dur > duration
        step_dur = duration - current_time
    endif
    
    if step_dur > 0.01
        @processSegment: soundID, current_time, current_time + step_dur, rate_val, depth_val, shape_val, pan_val, speed_val
        segment_count = segment_count + 1
        segment[segment_count] = processSegment.result
        appendInfoLine: "  Step ", step, ": r=", rate_val, " d=", depth_val, " sh=", shape_val, " dur=", fixed$(step_dur, 2), " pan=", pan_val, " sp=", speed_val
        current_time = current_time + step_dur
    endif
endfor

# Section D: Cross-coupled (RI-I-R-RI-P-RI)
appendInfoLine: ""
appendInfoLine: "Section D: CROSS-COUPLED (RI-I-R-RI-P-RI)"
for step from 1 to 12
    rate_val = rate_ri[step]
    depth_val = depth_inversion[step]
    shape_val = shape_retrograde[step]
    dur_val = dur_ri[step]
    pan_val = pan_prime[step]
    speed_val = speed_ri[step]
    
    step_dur = min_duration + (dur_val / 11) * (max_duration - min_duration)
    
    if current_time + step_dur > duration
        step_dur = duration - current_time
    endif
    
    if step_dur > 0.01
        @processSegment: soundID, current_time, current_time + step_dur, rate_val, depth_val, shape_val, pan_val, speed_val
        segment_count = segment_count + 1
        segment[segment_count] = processSegment.result
        appendInfoLine: "  Step ", step, ": r=", rate_val, " d=", depth_val, " sh=", shape_val, " dur=", fixed$(step_dur, 2), " pan=", pan_val, " sp=", speed_val
        current_time = current_time + step_dur
    endif
endfor

# Concatenate all segments
appendInfoLine: ""
appendInfoLine: "Concatenating ", segment_count, " segments..."
selectObject: segment[1]
for i from 2 to segment_count
    plusObject: segment[i]
endfor
outputID = Concatenate
Rename: soundName$ + "_AM"

# CLEANUP: Remove all segment objects
appendInfoLine: "Cleaning up ", segment_count, " intermediate segments..."
for i from 1 to segment_count
    removeObject: segment[i]
endfor

appendInfoLine: ""
appendInfoLine: "═══════════════════════════════════════════"
appendInfoLine: "Processing complete!"
appendInfoLine: "═══════════════════════════════════════════"
appendInfoLine: "Original: '", soundName$, "'"
appendInfoLine: "Result:   '", soundName$, "_AM'"
appendInfoLine: "Total processed time: ", fixed$(current_time, 3), " / ", fixed$(duration, 3), " s"
appendInfoLine: ""
appendInfoLine: "Playing result..."
appendInfoLine: "═══════════════════════════════════════════"

# Select both original and result
selectObject: soundID
plusObject: outputID

# Play the result
selectObject: outputID
Play


# ═══════════════════════════════════════════════════
# PROCEDURES
# ═══════════════════════════════════════════════════

procedure parseRow: .row_string$
    # Parse space-separated row into array
    .length = 0
    .remaining$ = .row_string$ + " "
    while index(.remaining$, " ") > 0
        .space_pos = index(.remaining$, " ")
        .value$ = left$(.remaining$, .space_pos - 1)
        if .value$ <> ""
            .length = .length + 1
            .values[.length] = number(.value$)
        endif
        .remaining$ = right$(.remaining$, length(.remaining$) - .space_pos)
    endwhile
endproc

procedure processSegment: .soundID, .start_time, .end_time, .rate_index, .depth_index, .shape_index, .pan_index, .speed_index
    # Map serial indices (0-11) to parameter values
    
    # PERCEPTUAL RATE SCALING: logarithmic instead of linear
    if perceptual_rate_scaling
        rate_ratio = .rate_index / 11
        mod_rate = min_rate * (max_rate / min_rate) ^ rate_ratio
    else
        mod_rate = min_rate + (.rate_index / 11) * (max_rate - min_rate)
    endif
    
    mod_depth = min_depth + (.depth_index / 11) * (max_depth - min_depth)
    
    # Panning: 0=left, 11=right
    pan_position = .pan_index / 11
    
    # Extract segment
    selectObject: .soundID
    .segmentID = Extract part: .start_time, .end_time, "rectangular", 1, "no"
    .seg_duration = Get total duration
    .num_channels = Get number of channels
    
    # PLAYBACK SPEED (Resampling) - do this BEFORE AM processing
    # Formula: Target_Hz = Original_Hz * (2 ^ ((Row_Value - 6) / 12))
    # This gives ±6 semitones range centered at value 6
    selectObject: .segmentID
    speed_semitones = (.speed_index - 6)
    speed_factor = 2 ^ (speed_semitones / 12)
    target_hz = sampling_frequency * speed_factor
    
    if abs(speed_factor - 1.0) > 0.01
        selectObject: .segmentID
        Resample: target_hz, 50
        .resampledID = selected("Sound")
        removeObject: .segmentID
        .segmentID = .resampledID
        # Override sampling frequency to original for resampling back
        selectObject: .segmentID
        Override sampling frequency: sampling_frequency
        Resample: sampling_frequency, 50
        .finalResampledID = selected("Sound")
        removeObject: .segmentID
        .segmentID = .finalResampledID
    endif
    
    # Determine modulator shape
    if .shape_index <= 2
        .shape$ = "sine"
    elsif .shape_index <= 5
        .shape$ = "triangle"
    elsif .shape_index <= 8
        .shape$ = "square"
    else
        .shape$ = "sawtooth"
    endif
    
    # Apply AM to each channel
    for .ch from 1 to .num_channels
        selectObject: .segmentID
        .channelID = Extract one channel: .ch
        
        # Apply modulation based on shape (AMPLITUDE MODULATION / RING MOD)
        if .shape$ = "sine"
            Formula: "self * (1 + 'mod_depth' * sin(2 * pi * 'mod_rate' * x))"
        elsif .shape$ = "triangle"
            Formula: "self * (1 + 'mod_depth' * (1 - 4 * abs(round('mod_rate' * x) - 'mod_rate' * x)))"
        elsif .shape$ = "square"
            Formula: "self * (1 + 'mod_depth' * if ('mod_rate' * x - floor('mod_rate' * x)) < 0.5 then 1 else -1 fi)"
        elsif .shape$ = "sawtooth"
            Formula: "self * (1 + 'mod_depth' * (2 * (('mod_rate' * x) - floor('mod_rate' * x)) - 1))"
        endif
        
        .processedChannel = selected("Sound")
        
        if .ch = 1
            .processedID = .processedChannel
        else
            # Combine channels
            selectObject: .processedID
            plusObject: .processedChannel
            .combinedID = Combine to stereo
            removeObject: .processedID
            removeObject: .processedChannel
            .processedID = .combinedID
        endif
    endfor
    
    # Apply PANNING to stereo output
    selectObject: .processedID
    .current_channels = Get number of channels
    
    # Convert to stereo if mono
    if .current_channels = 1
        selectObject: .processedID
        Convert to stereo
        .stereoID = selected("Sound")
        removeObject: .processedID
        .processedID = .stereoID
    endif
    
    # Apply panning by extracting channels, applying gain, then recombining
    # Equal power panning would be: left = sqrt(1-pan), right = sqrt(pan)
    # Using linear for simplicity: left = 1-pan, right = pan
    left_gain = 1 - pan_position
    right_gain = pan_position
    
    selectObject: .processedID
    .leftChannel = Extract one channel: 1
    Formula: "self * 'left_gain'"
    
    selectObject: .processedID
    .rightChannel = Extract one channel: 2
    Formula: "self * 'right_gain'"
    
    # Recombine into stereo
    selectObject: .leftChannel
    plusObject: .rightChannel
    .pannedID = Combine to stereo
    
    # Clean up
    removeObject: .leftChannel
    removeObject: .rightChannel
    removeObject: .processedID
    removeObject: .segmentID
    
    .result = .pannedID
endproc