# ============================================================
# Praat AudioTools - Total Serialism Machine
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Total Serialism Machine
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Total Serialism Machine 

# ============================================================================
# CHECK INPUT
# ============================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

input_sound = selected("Sound")
selectObject: input_sound
input_duration = Get total duration
input_sr = Get sampling frequency

# ============================================================================
# FORM LOOP
# ============================================================================

continue = 1
while continue

beginPause: "Total Serialism Machine"
    comment: "═══════════ PRESETS ═══════════"
    optionMenu: "preset", 1
        option: "Custom (manual settings)"
        option: "Pointillism (Webern-style)"
        option: "Moment Form (discrete blocks)"
        option: "Granular Texture (micro-events)"
        option: "Transformational (extreme ranges)"
        option: "Statistical Field (dense cloud)"
    comment: ""
    comment: "═══════════ SERIES ═══════════"
    integer: "series_length", 12
    optionMenu: "series_type", 3
        option: "Arithmetic (1..N)"
        option: "Permutation (custom)"
        option: "12-tone row (classic)"
    sentence: "series_values", "0,10,7,11,3,8,1,9,2,5,6,4"
    comment: ""
    comment: "═══════════ TRANSFORMATIONS ═══════════"
    boolean: "use_inversion", 0
    boolean: "use_retrograde", 0
    integer: "rotation", 0
    comment: ""
    comment: "═══════════ STRUCTURE ═══════════"
    integer: "num_events", 30
    positive: "min_event_ms", 200
    positive: "max_event_ms", 600
    positive: "gap_between_events_ms", 50
    comment: ""
    comment: "═══════════ PITCH RANGE ═══════════"
    integer: "min_pitch_cents", -200
    integer: "max_pitch_cents", 200
clicked = endPause: "Cancel", "Apply", "OK", 2

if clicked = 1
    # Cancel
    continue = 0
    exitScript()
elsif clicked = 2
    # Apply - process but keep form open
    continue = 1
elsif clicked = 3
    # OK - process and close
    continue = 0
endif

# ============================================================================
# APPLY PRESETS
# ============================================================================

if preset = 2
    # Pointillism (Webern-style): sparse, short events, wide pitch range
    num_events = 24
    min_event_ms = 80
    max_event_ms = 250
    gap_between_events_ms = 150
    min_pitch_cents = -400
    max_pitch_cents = 400
    
elsif preset = 3
    # Moment Form: discrete blocks, moderate density
    num_events = 20
    min_event_ms = 300
    max_event_ms = 800
    gap_between_events_ms = 200
    min_pitch_cents = -300
    max_pitch_cents = 300
    
elsif preset = 4
    # Granular Texture: many micro-events
    num_events = 60
    min_event_ms = 50
    max_event_ms = 150
    gap_between_events_ms = 20
    min_pitch_cents = -200
    max_pitch_cents = 200
    
elsif preset = 5
    # Transformational: extreme parameter ranges
    num_events = 40
    min_event_ms = 100
    max_event_ms = 700
    gap_between_events_ms = 80
    min_pitch_cents = -600
    max_pitch_cents = 600
    use_inversion = 1
    use_retrograde = 1
    
elsif preset = 6
    # Statistical Field: dense overlapping cloud
    num_events = 80
    min_event_ms = 150
    max_event_ms = 500
    gap_between_events_ms = 10
    min_pitch_cents = -300
    max_pitch_cents = 300
endif

min_event_s = min_event_ms / 1000
max_event_s = max_event_ms / 1000
gap_s = gap_between_events_ms / 1000

# ============================================================================
# BUILD SERIES
# ============================================================================

@createSeries: series_type, series_length, series_values$
@applySerialTransformations: use_inversion, use_retrograde, rotation
@normalizeSeries

writeInfoLine: "Total Serialism Machine"
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Series length: ", series_length
appendInfoLine: "Processing ", num_events, " events..."
appendInfoLine: ""

# ============================================================================
# GENERATE AND SORT EVENTS
# ============================================================================

for i to num_events
    series_i = ((i - 1) mod series_length) + 1
    norm_val = normalized_series[series_i]
    
    event_time[i] = norm_val
    event_index[i] = i
endfor

# Sort events by time
for i to num_events - 1
    for j from i + 1 to num_events
        if event_time[event_index[j]] < event_time[event_index[i]]
            temp = event_index[i]
            event_index[i] = event_index[j]
            event_index[j] = temp
        endif
    endfor
endfor

# ============================================================================
# CREATE EVENTS IN TIME ORDER
# ============================================================================

for pos to num_events
    i = event_index[pos]
    
    series_i = ((i - 1) mod series_length) + 1
    norm_val = normalized_series[series_i]
    
    # PARAMETER 1: Event duration
    dur_series_i = ((i + 1 - 1) mod series_length) + 1
    dur_norm = normalized_series[dur_series_i]
    event_dur = min_event_s + dur_norm * (max_event_s - min_event_s)
    
    # PARAMETER 2: Source position
    source_series_i = ((i + 3 - 1) mod series_length) + 1
    source_norm = normalized_series[source_series_i]
    max_source_start = input_duration - event_dur
    if max_source_start < 0
        max_source_start = 0
    endif
    source_pos = source_norm * max_source_start
    
    # PARAMETER 3: Pitch shift
    pitch_series_i = ((i + 4 - 1) mod series_length) + 1
    pitch_norm = normalized_series[pitch_series_i]
    pitch_cents = min_pitch_cents + pitch_norm * (max_pitch_cents - min_pitch_cents)
    
    # PARAMETER 4: Gain
    gain_series_i = ((i + 6 - 1) mod series_length) + 1
    gain_norm = normalized_series[gain_series_i]
    gain_db = -12 + gain_norm * 12
    gain_linear = 10^(gain_db / 20)
    
    # PARAMETER 5: Pan position
    pan_series_i = ((i * 2 - 1) mod series_length) + 1
    pan_pos = normalized_series[pan_series_i]
    
    if pos mod 10 = 1 or pos = num_events
        appendInfoLine: "Event ", pos, "/", num_events, ": pitch=", fixed$(pitch_cents, 0), "¢  pan=", fixed$(pan_pos, 2)
    endif
    
    # Extract segment
    selectObject: input_sound
    segment = Extract part: source_pos, source_pos + event_dur, "rectangular", 1, "no"
    
    # Convert to mono
    selectObject: segment
    n_ch = Get number of channels
    if n_ch = 2
        mono = Convert to mono
        removeObject: segment
        segment = mono
    endif
    
    # Apply gain
    selectObject: segment
    Formula: "self * 'gain_linear'"
    
    # Pitch shift
    if abs(pitch_cents) > 1
        pitch_ratio = 2^(pitch_cents / 1200)
        selectObject: segment
        new_sr = input_sr * pitch_ratio
        Override sampling frequency: new_sr
        resampled = Resample: input_sr, 50
        removeObject: segment
        segment = resampled
    endif
    
    # Fade
    selectObject: segment
    seg_dur = Get total duration
    fade = 0.005
    Formula: "self * if x < 'fade' then x/'fade' else if x > 'seg_dur'-'fade' then ('seg_dur'-x)/'fade' else 1 fi fi"
    
    # STEREO PANNING
    left_gain = sqrt(1 - pan_pos)
    right_gain = sqrt(pan_pos)
    
    selectObject: segment
    stereo = Convert to stereo
    removeObject: segment
    segment = stereo
    
    selectObject: segment
    Formula (part): 0, 0, 1, 1, "self * 'left_gain'"
    Formula (part): 0, 0, 2, 2, "self * 'right_gain'"
    
    # Store segment
    segment_obj[pos] = segment
endfor

# ============================================================================
# CONCATENATE ALL EVENTS
# ============================================================================

appendInfoLine: ""
appendInfoLine: "Concatenating..."

# Start with first segment
selectObject: segment_obj[1]
result = Copy: "serialist_result"

# Concatenate remaining segments with gaps
for pos from 2 to num_events
    # Create stereo silence gap
    Create Sound from formula: "gap", 2, 0, gap_s, input_sr, "0"
    gap = selected("Sound")
    
    # Append gap
    selectObject: result
    plusObject: gap
    old_result = result
    result = Concatenate
    removeObject: old_result, gap
    
    # Append next segment
    selectObject: result
    plusObject: segment_obj[pos]
    old_result = result
    result = Concatenate
    removeObject: old_result
endfor

# Cleanup segments
for i to num_events
    removeObject: segment_obj[i]
endfor

# ============================================================================
# FINALIZE
# ============================================================================

selectObject: result
Scale peak: 0.99

final_dur = Get total duration
appendInfoLine: ""
appendInfoLine: "Complete! Duration: ", fixed$(final_dur, 2), " s"
appendInfoLine: "Playing..."
Play

selectObject: result

# End of while loop
endwhile

# ============================================================================
# PROCEDURES
# ============================================================================

procedure createSeries: .type, .length, .values$
    for .i to .length
        base_series[.i] = .i
    endfor
    
    if .type = 1
        # Arithmetic: 1, 2, 3, ..., N
        for .i to .length
            base_series[.i] = .i
        endfor
    elsif .type = 2
        # Permutation: parse user values
        @parseSeriesValues: .values$, .length
    elsif .type = 3
        # 12-tone row (classic example)
        if .length = 12
            base_series[1] = 0
            base_series[2] = 10
            base_series[3] = 7
            base_series[4] = 11
            base_series[5] = 3
            base_series[6] = 8
            base_series[7] = 1
            base_series[8] = 9
            base_series[9] = 2
            base_series[10] = 5
            base_series[11] = 6
            base_series[12] = 4
        else
            for .i to .length
                base_series[.i] = .i
            endfor
        endif
    endif
endproc

procedure parseSeriesValues: .values$, .length
    .count = 0
    .remaining$ = .values$ + ","
    
    while length(.remaining$) > 0 and .count < .length
        .comma_pos = index(.remaining$, ",")
        if .comma_pos > 0
            .count += 1
            .value$ = left$(.remaining$, .comma_pos - 1)
            .value$ = replace$(.value$, " ", "", 0)
            
            if .value$ <> ""
                base_series[.count] = number(.value$)
            else
                base_series[.count] = .count
            endif
            
            .remaining$ = right$(.remaining$, length(.remaining$) - .comma_pos)
        else
            .remaining$ = ""
        endif
    endwhile
    
    for .i from .count + 1 to .length
        base_series[.i] = .i
    endfor
endproc

procedure applySerialTransformations: .invert, .retro, .rotate
    for .i to series_length
        working_series[.i] = base_series[.i]
    endfor
    
    if .invert
        .min = working_series[1]
        .max = working_series[1]
        for .i from 2 to series_length
            if working_series[.i] < .min
                .min = working_series[.i]
            endif
            if working_series[.i] > .max
                .max = working_series[.i]
            endif
        endfor
        
        for .i to series_length
            working_series[.i] = .min + .max - working_series[.i]
        endfor
    endif
    
    if .retro
        for .i to series_length
            temp_series[.i] = working_series[series_length - .i + 1]
        endfor
        for .i to series_length
            working_series[.i] = temp_series[.i]
        endfor
    endif
    
    .rot = .rotate mod series_length
    if .rot <> 0
        for .i to series_length
            .source_i = ((.i - 1 - .rot) mod series_length) + 1
            if .source_i < 1
                .source_i += series_length
            endif
            temp_series[.i] = working_series[.source_i]
        endfor
        for .i to series_length
            working_series[.i] = temp_series[.i]
        endfor
    endif
    
    for .i to series_length
        base_series[.i] = working_series[.i]
    endfor
endproc

procedure normalizeSeries
    .min = base_series[1]
    .max = base_series[1]
    
    for .i from 2 to series_length
        if base_series[.i] < .min
            .min = base_series[.i]
        endif
        if base_series[.i] > .max
            .max = base_series[.i]
        endif
    endfor
    
    .range = .max - .min
    if .range = 0
        .range = 1
    endif
    
    for .i to series_length
        normalized_series[.i] = (base_series[.i] - .min) / .range
    endfor
endproc