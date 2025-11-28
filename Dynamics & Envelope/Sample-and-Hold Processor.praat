# ============================================================
# Praat AudioTools - Sample-and-Hold Processor.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sample-and-Hold Audio Processor
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Sample-and-Hold Audio Processor 


form Sample-and-Hold Audio Processor
    comment Control Settings
    positive sample_period 0.02
    comment (Sample interval in seconds - e.g., 0.02 = 20ms)
    
    optionmenu control_type 1
        option Binary (Play/Mute)
        option Intensity-based
        option Amplitude Modulation (Sine)
        option Pitch-gated
        option Custom Pattern
        option Spectral Centroid Gate
    
    comment Binary Control
    real play_threshold 0.5
    
    comment Intensity-based Control
    real intensity_threshold 50
    comment (dB - segments above threshold pass through)
    boolean auto_intensity_threshold 0
    comment (Auto-set threshold to median intensity)
    
    comment Amplitude Modulation
    real modulation_frequency 2
    comment (Hz - for sine wave amplitude control)
    real modulation_depth 1.0
    comment (0.0 to 1.0 - amount of modulation)
    
    comment Pitch-gated Control
    real pitch_threshold 100
    comment (Hz - pass segments with pitch above this)
    
    comment Spectral Centroid Gate
    real centroid_threshold 1000
    comment (Hz - pass segments with centroid above this)
    
    comment Custom Pattern (repeating)
    sentence pattern 1 0 1 1 0 1 0 1
    comment (Space-separated: 1=pass 0=mute)
    
    comment Output Options
    boolean show_control_signal 1
    real mute_amplitude 0.0
    comment (Amplitude for muted segments: 0.0=silence, 0.1=quiet)
endform

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sample_rate = Get sampling frequency
num_channels = Get number of channels

# Calculate intervals
num_intervals = ceiling(duration / sample_period)

writeInfoLine: "Sample-and-Hold Audio Processor"
appendInfoLine: "================================"
appendInfoLine: "Input: ", sound_name$
appendInfoLine: "Duration: ", fixed$(duration, 3), " s"
appendInfoLine: "Sample period: ", fixed$(sample_period, 3), " s"
appendInfoLine: "Intervals: ", num_intervals

# Parse and validate custom pattern
pattern_length = 0
if control_type = 5
    pattern$ = replace_regex$(pattern$, "^[ \t]+", "", 0)
    pattern$ = replace_regex$(pattern$, "[ \t]+$", "", 0)
    
    if length(pattern$) = 0
        exitScript: "ERROR: Custom pattern is empty. Please provide space-separated values (e.g., '1 0 1 1 0')."
    endif
    
    pattern$ = pattern$ + " "
    @countPatternValues: pattern$
    pattern_length = countPatternValues.count
    
    if pattern_length = 0
        exitScript: "ERROR: No valid pattern values found. Please provide space-separated numbers (e.g., '1 0 1 1 0')."
    endif
    
    appendInfoLine: "Pattern length: ", pattern_length, " values"
endif

appendInfoLine: ""

# Auto-threshold for intensity: first pass to collect intensity values
if control_type = 2 and auto_intensity_threshold
    appendInfoLine: "Computing intensity statistics..."
    selectObject: sound
    
    # Collect all intensity values
    for i from 0 to num_intervals - 1
        t_start = i * sample_period
        t_end = t_start + sample_period
        if t_end > duration
            t_end = duration
        endif
        
        selectObject: sound
        Extract part: t_start, t_end, "rectangular", 1, "no"
        temp_seg = selected("Sound")
        intensity_vals[i] = Get intensity (dB)
        removeObject: temp_seg
    endfor
    
    # Sort and find median
    for i from 0 to num_intervals - 1
        for j from i + 1 to num_intervals - 1
            if intensity_vals[j] < intensity_vals[i]
                temp = intensity_vals[i]
                intensity_vals[i] = intensity_vals[j]
                intensity_vals[j] = temp
            endif
        endfor
    endfor
    
    median_index = floor(num_intervals / 2)
    intensity_threshold = intensity_vals[median_index]
    
    appendInfoLine: "Auto-threshold set to: ", fixed$(intensity_threshold, 1), " dB (median)"
    appendInfoLine: "Intensity range: ", fixed$(intensity_vals[0], 1), " to ", 
    ... fixed$(intensity_vals[num_intervals-1], 1), " dB"
    appendInfoLine: ""
endif

# Display intensity statistics if intensity-based
if control_type = 2
    appendInfoLine: "Intensity-based gating:"
    appendInfoLine: "Threshold: ", fixed$(intensity_threshold, 1), " dB"
    appendInfoLine: "Segments above threshold will PASS"
    appendInfoLine: "Segments below threshold will be ", if mute_amplitude = 0 then "MUTED" else "ATTENUATED" fi
    appendInfoLine: ""
endif

if show_control_signal
    appendInfoLine: "Control Signal:"
    if control_type = 2
        appendInfoLine: "Interval  Time(s)   Intensity(dB)  State  Action"
        appendInfoLine: "------------------------------------------------"
    else
        appendInfoLine: "Interval  Time(s)   State   Action"
        appendInfoLine: "--------------------------------------"
    endif
endif

# Copy the original sound to output
selectObject: sound
output_sound = Copy: sound_name$ + "_SH"

# Statistics for intensity-based
pass_count = 0
mute_count = 0

# Process each interval
for i from 0 to num_intervals - 1
    t_start = i * sample_period
    t_end = t_start + sample_period
    
    if t_end > duration
        t_end = duration
    endif
    
    # SAMPLE PHASE: Compute control value
    selectObject: sound
    
    if control_type = 1
        # Binary pattern
        control_value = if i mod 2 = 0 then 1 else 0 fi
        
    elsif control_type = 2
        # Intensity-based
        Extract part: t_start, t_end, "rectangular", 1, "no"
        temp_segment = selected("Sound")
        intensity_value = Get intensity (dB)
        control_value = if intensity_value > intensity_threshold then 1 else 0 fi
        
        # Track statistics
        if control_value = 1
            pass_count += 1
        else
            mute_count += 1
        endif
        
        removeObject: temp_segment
        
    elsif control_type = 3
        # Amplitude modulation (sine)
        phase = 2 * pi * modulation_frequency * t_start
        sine_value = (sin(phase) + 1) / 2
        control_value = 1 - (modulation_depth * (1 - sine_value))
        
    elsif control_type = 4
        # Pitch-gated
        To Pitch: 0.01, 75, 600
        pitch_obj = selected("Pitch")
        pitch_value = Get value at time: t_start, "Hertz", "linear"
        control_value = if pitch_value > pitch_threshold and pitch_value != undefined then 1 else 0 fi
        removeObject: pitch_obj
        
    elsif control_type = 5
        # Custom pattern
        pattern_index = (i mod pattern_length) + 1
        @getPatternValue: pattern$, pattern_index
        control_value = getPatternValue.value
        
    elsif control_type = 6
        # Spectral centroid gate
        Extract part: t_start, t_end, "rectangular", 1, "no"
        temp_segment = selected("Sound")
        To Spectrum: "yes"
        spectrum = selected("Spectrum")
        centroid = Get centre of gravity: 2
        control_value = if centroid > centroid_threshold then 1 else 0 fi
        removeObject: spectrum
        removeObject: temp_segment
    endif
    
    # Display control signal (first 30 intervals)
    if show_control_signal and i < 30
        if control_type = 2
            action$ = if control_value > play_threshold then "PASS" else "MUTE" fi
            appendInfoLine: fixed$(i, 4), "      ", fixed$(t_start, 3), "      ", 
            ... fixed$(intensity_value, 1), "         ", fixed$(control_value, 1), "      ", action$
        elsif control_type = 3
            action$ = "AMP=" + fixed$(control_value, 3)
            appendInfoLine: fixed$(i, 4), "      ", fixed$(t_start, 3), "    ", 
            ... fixed$(control_value, 3), "   ", action$
        else
            action$ = if control_value > play_threshold then "PASS" else "MUTE" fi
            appendInfoLine: fixed$(i, 4), "      ", fixed$(t_start, 3), "    ", 
            ... fixed$(control_value, 3), "   ", action$
        endif
    endif
    
    # HOLD PHASE: Apply control value
    selectObject: output_sound
    
    if control_type = 3
        amp_mult = control_value
    else
        amp_mult = if control_value >= play_threshold then 1 else mute_amplitude fi
    endif
    
    Formula (part): t_start, t_end, 1, num_channels, "self * " + string$(amp_mult)
endfor

# Summary for intensity-based
if control_type = 2
    appendInfoLine: ""
    appendInfoLine: "Intensity-based gating results:"
    appendInfoLine: "  Passed: ", pass_count, " intervals (", 
    ... fixed$(100 * pass_count / num_intervals, 1), "%)"
    appendInfoLine: "  Muted: ", mute_count, " intervals (", 
    ... fixed$(100 * mute_count / num_intervals, 1), "%)"
    
    if pass_count = num_intervals
        appendInfoLine: ""
        appendInfoLine: "⚠ WARNING: All segments passed! Try:"
        appendInfoLine: "  - Lower the threshold (current: ", fixed$(intensity_threshold, 1), " dB)"
        appendInfoLine: "  - Or enable 'auto_intensity_threshold'"
    elsif mute_count = num_intervals
        appendInfoLine: ""
        appendInfoLine: "⚠ WARNING: All segments muted! Try:"
        appendInfoLine: "  - Raise the threshold (current: ", fixed$(intensity_threshold, 1), " dB)"
        appendInfoLine: "  - Or enable 'auto_intensity_threshold'"
    endif
endif

selectObject: output_sound

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", sound_name$ + "_SH"
Play

# Helper procedures
procedure countPatternValues: .pattern$
    .count = 0
    .temp$ = .pattern$
    repeat
        .space_pos = index_regex(.temp$, "[ \t]+")
        if .space_pos > 0
            .count += 1
            .temp$ = right$(.temp$, length(.temp$) - .space_pos)
            .temp$ = replace_regex$(.temp$, "^[ \t]+", "", 0)
        endif
    until .space_pos = 0 or length(.temp$) = 0
endproc

procedure getPatternValue: .pattern$, .index
    .current = 0
    .temp$ = .pattern$
    repeat
        .space_pos = index_regex(.temp$, "[ \t]+")
        if .space_pos > 0
            .current += 1
            .val_str$ = left$(.temp$, .space_pos - 1)
            if .current = .index
                .value = number(.val_str$)
                goto FOUND
            endif
            .temp$ = right$(.temp$, length(.temp$) - .space_pos)
            .temp$ = replace_regex$(.temp$, "^[ \t]+", "", 0)
        endif
    until .space_pos = 0
    .value = 0
    label FOUND
endproc