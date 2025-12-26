# ============================================================
# Praat AudioTools - Hidden Markov Model (HMM) Timbre Sequencing
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.4 (2025) - Stereo + Presets
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Hidden Markov Model (HMM) Timbre Sequencing
#   Features:
#   - Stereo output (independent L/R Markov chains)
#   - Presets for common use cases
#   - Band energy optimization
#   - Pre-built state index (O(1) lookup)
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

################################################################################
# Hidden Markov Model (HMM) Timbre Sequencing - Stereo + Presets
################################################################################

form Markov Chain Timbre Sequencer
    comment === Preset Selection ===
    optionmenu Preset: 1
        option Custom (use settings below)
        option Fine Grain (subtle, smooth)
        option Coarse Grain (bold, dramatic)
        option Textural (dense, evolving)
        option Rhythmic (pulse-aligned)
        option Experimental (glitchy, chaotic)
    
    comment === Feature Extraction Parameters ===
    positive Frame_size_(ms) 20
    positive Frame_hop_(ms) 10
    
    comment === Timbre State Clustering ===
    positive Number_of_timbre_states_(K) 8
    positive Max_kmeans_iterations 50
    
    comment === Sequence Generation ===
    positive Output_sequence_length_(frames) 200
    
    comment === Output Options ===
    positive Crossfade_duration_(ms) 5
    boolean Stereo_output 1
    boolean Show_detailed_info 1
endform

################################################################################
# APPLY PRESETS
################################################################################

if preset = 2
    # Fine Grain (subtle, smooth)
    frame_size = 10
    frame_hop = 5
    number_of_timbre_states = 12
    output_sequence_length = 400
    crossfade_duration = 3
elsif preset = 3
    # Coarse Grain (bold, dramatic)
    frame_size = 100
    frame_hop = 50
    number_of_timbre_states = 5
    output_sequence_length = 80
    crossfade_duration = 10
elsif preset = 4
    # Textural (dense, evolving)
    frame_size = 20
    frame_hop = 10
    number_of_timbre_states = 16
    output_sequence_length = 600
    crossfade_duration = 4
elsif preset = 5
    # Rhythmic (pulse-aligned ~120 BPM sixteenths)
    frame_size = 30
    frame_hop = 15
    number_of_timbre_states = 8
    output_sequence_length = 128
    crossfade_duration = 5
elsif preset = 6
    # Experimental (glitchy, chaotic)
    frame_size = 8
    frame_hop = 4
    number_of_timbre_states = 24
    output_sequence_length = 500
    crossfade_duration = 1
endif

################################################################################
# INITIALIZATION AND VALIDATION
################################################################################

numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound_original = selected("Sound")
sound_name$ = selected$("Sound")
selectObject: sound_original
duration = Get total duration
sampling_rate = Get sampling frequency
original_channels = Get number of channels

# Convert to mono for analysis
if original_channels > 1
    sound_mono = Convert to mono
    Rename: sound_name$ + "_mono"
else
    selectObject: sound_original
    sound_mono = Copy: sound_name$ + "_mono"
endif

selectObject: sound_mono
sound = sound_mono

frame_size = frame_size / 1000
frame_hop = frame_hop / 1000
crossfade = crossfade_duration / 1000

num_frames = floor((duration - frame_size) / frame_hop) + 1

if num_frames < number_of_timbre_states
    removeObject: sound_mono
    exitScript: "Sound is too short for ", number_of_timbre_states, " states. Reduce K or use longer sound."
endif

k = number_of_timbre_states

if show_detailed_info
    writeInfoLine: "=== Markov Chain Timbre Sequencer (Stereo + Presets) ==="
    appendInfoLine: "Sound: ", sound_name$
    appendInfoLine: "Duration: ", fixed$(duration, 3), " s"
    appendInfoLine: "Frames: ", num_frames
    appendInfoLine: "States (K): ", k
    if preset > 1
        appendInfoLine: "Preset: ", preset$
    endif
    if stereo_output
        appendInfoLine: "Output: Stereo (independent L/R chains)"
    else
        appendInfoLine: "Output: Mono"
    endif
    appendInfoLine: ""
endif

################################################################################
# STEP 1: FEATURE EXTRACTION (OPTIMIZED - Band Energy)
################################################################################

if show_detailed_info
    appendInfoLine: "Step 1: Extracting features..."
endif

# Create global pitch object once
selectObject: sound
pitch_global = To Pitch: 0, 150, 600

# Pre-allocate feature arrays
time# = zero#(num_frames)
intensity# = zero#(num_frames)
pitch# = zero#(num_frames)
centroid# = zero#(num_frames)
slope# = zero#(num_frames)

# Frequency bands for slope calculation
low_freq_start = 100
low_freq_end = 1000
high_freq_start = 4000
high_freq_end = 8000

# Single-pass feature extraction with running statistics
sum_int = 0
sum_pitch = 0
sum_cent = 0
sum_slope = 0
sum_sq_int = 0
sum_sq_pitch = 0
sum_sq_cent = 0
sum_sq_slope = 0

for i from 1 to num_frames
    start_time = (i - 1) * frame_hop
    end_time = start_time + frame_size
    mid_time = start_time + frame_size / 2
    
    selectObject: sound
    frame_sound = Extract part: start_time, end_time, "rectangular", 1.0, "no"
    
    intensity_value = Get root-mean-square: 0, 0
    
    spectrum = To Spectrum: "yes"
    centroid_value = Get centre of gravity: 2
    
    low_power = Get band energy: low_freq_start, low_freq_end
    high_power = Get band energy: high_freq_start, high_freq_end
    
    if low_power > 1e-20 and high_power > 1e-20
        slope_value = (ln(high_power) - ln(low_power)) / ln(high_freq_start / low_freq_start)
    else
        slope_value = 0
    endif
    
    removeObject: spectrum, frame_sound
    
    selectObject: pitch_global
    pitch_value = Get value at time: mid_time, "Hertz", "Linear"
    if pitch_value = undefined
        pitch_value = 0
    endif
    
    time#[i] = mid_time
    intensity#[i] = intensity_value
    pitch#[i] = pitch_value
    centroid#[i] = centroid_value
    slope#[i] = slope_value
    
    sum_int += intensity_value
    sum_pitch += pitch_value
    sum_cent += centroid_value
    sum_slope += slope_value
    sum_sq_int += intensity_value^2
    sum_sq_pitch += pitch_value^2
    sum_sq_cent += centroid_value^2
    sum_sq_slope += slope_value^2
endfor

removeObject: pitch_global

if show_detailed_info
    appendInfoLine: "  Extracted 4 features per frame"
endif

################################################################################
# STEP 2: FEATURE NORMALIZATION
################################################################################

if show_detailed_info
    appendInfoLine: "Step 2: Normalizing features..."
endif

mean_int = sum_int / num_frames
mean_pitch = sum_pitch / num_frames
mean_cent = sum_cent / num_frames
mean_slope = sum_slope / num_frames

std_int = sqrt(sum_sq_int / num_frames - mean_int^2)
std_pitch = sqrt(sum_sq_pitch / num_frames - mean_pitch^2)
std_cent = sqrt(sum_sq_cent / num_frames - mean_cent^2)
std_slope = sqrt(sum_sq_slope / num_frames - mean_slope^2)

if std_int < 1e-10
    std_int = 1
endif
if std_pitch < 1e-10
    std_pitch = 1
endif
if std_cent < 1e-10
    std_cent = 1
endif
if std_slope < 1e-10
    std_slope = 1
endif

norm_int# = zero#(num_frames)
norm_pitch# = zero#(num_frames)
norm_cent# = zero#(num_frames)
norm_slope# = zero#(num_frames)

for i from 1 to num_frames
    norm_int#[i] = (intensity#[i] - mean_int) / std_int
    norm_pitch#[i] = (pitch#[i] - mean_pitch) / std_pitch
    norm_cent#[i] = (centroid#[i] - mean_cent) / std_cent
    norm_slope#[i] = (slope#[i] - mean_slope) / std_slope
endfor

if show_detailed_info
    appendInfoLine: "  Normalization complete"
endif

################################################################################
# STEP 3: K-MEANS CLUSTERING
################################################################################

if show_detailed_info
    appendInfoLine: "Step 3: Clustering into ", k, " timbre states..."
endif

cent_int# = zero#(k)
cent_pitch# = zero#(k)
cent_cent# = zero#(k)
cent_slope# = zero#(k)

for state from 1 to k
    random_frame = randomInteger(1, num_frames)
    cent_int#[state] = norm_int#[random_frame]
    cent_pitch#[state] = norm_pitch#[random_frame]
    cent_cent#[state] = norm_cent#[random_frame]
    cent_slope#[state] = norm_slope#[random_frame]
endfor

state# = zero#(num_frames)

for iteration from 1 to max_kmeans_iterations
    assignments_changed = 0
    
    for i from 1 to num_frames
        min_distance = 1e10
        best_state = 1
        
        for s from 1 to k
            distance = sqrt((norm_int#[i] - cent_int#[s])^2 + 
                ...         (norm_pitch#[i] - cent_pitch#[s])^2 + 
                ...         (norm_cent#[i] - cent_cent#[s])^2 + 
                ...         (norm_slope#[i] - cent_slope#[s])^2)
            
            if distance < min_distance
                min_distance = distance
                best_state = s
            endif
        endfor
        
        if state#[i] <> best_state
            assignments_changed += 1
        endif
        state#[i] = best_state
    endfor
    
    for s from 1 to k
        s_int = 0
        s_pitch = 0
        s_cent = 0
        s_slope = 0
        count = 0
        
        for i from 1 to num_frames
            if state#[i] = s
                s_int += norm_int#[i]
                s_pitch += norm_pitch#[i]
                s_cent += norm_cent#[i]
                s_slope += norm_slope#[i]
                count += 1
            endif
        endfor
        
        if count > 0
            cent_int#[s] = s_int / count
            cent_pitch#[s] = s_pitch / count
            cent_cent#[s] = s_cent / count
            cent_slope#[s] = s_slope / count
        endif
    endfor
    
    if assignments_changed = 0
        if show_detailed_info
            appendInfoLine: "  K-means converged at iteration ", iteration
        endif
        iteration = max_kmeans_iterations + 1
    endif
endfor

if show_detailed_info
    appendInfoLine: "  Clustering complete"
endif

################################################################################
# STEP 3.5: BUILD STATE INDEX
################################################################################

if show_detailed_info
    appendInfoLine: "  Building state index..."
endif

state_count# = zero#(k)
for i from 1 to num_frames
    s = state#[i]
    state_count#[s] += 1
endfor

state_offset# = zero#(k + 1)
state_offset#[1] = 0
for s from 2 to k + 1
    state_offset#[s] = state_offset#[s-1] + state_count#[s-1]
endfor

state_index# = zero#(num_frames)
state_fill# = zero#(k)

for i from 1 to num_frames
    s = state#[i]
    pos = state_offset#[s] + state_fill#[s] + 1
    state_index#[pos] = i
    state_fill#[s] += 1
endfor

if show_detailed_info
    appendInfoLine: "  State index built"
endif

################################################################################
# STEP 4: MARKOV CHAIN TRANSITION MATRIX
################################################################################

if show_detailed_info
    appendInfoLine: "Step 4: Learning transition probabilities..."
endif

trans# = zero#(k * k)
first_state = state#[1]

for i from 1 to num_frames - 1
    current_s = state#[i]
    next_s = state#[i + 1]
    idx = (current_s - 1) * k + next_s
    trans#[idx] += 1
endfor

for i from 1 to k
    row_sum = 0
    for j from 1 to k
        idx = (i - 1) * k + j
        row_sum += trans#[idx]
    endfor
    
    if row_sum > 0
        for j from 1 to k
            idx = (i - 1) * k + j
            trans#[idx] /= row_sum
        endfor
    else
        for j from 1 to k
            idx = (i - 1) * k + j
            trans#[idx] = 1.0 / k
        endfor
    endif
endfor

if show_detailed_info
    appendInfoLine: "  Transition matrix learned"
endif

################################################################################
# STEP 5 & 6: GENERATE SEQUENCES AND SYNTHESIZE
# Run once for mono, twice for stereo (independent chains)
################################################################################

if stereo_output
    n_passes = 2
else
    n_passes = 1
endif

for pass from 1 to n_passes
    if show_detailed_info
        if stereo_output
            if pass = 1
                appendInfoLine: "Step 5-6: Generating LEFT channel..."
            else
                appendInfoLine: "Step 5-6: Generating RIGHT channel..."
            endif
        else
            appendInfoLine: "Step 5-6: Generating sequence and synthesizing..."
        endif
    endif
    
    # Generate state sequence
    out_state# = zero#(output_sequence_length)
    out_frame# = zero#(output_sequence_length)
    
    current_state = first_state
    
    for t from 1 to output_sequence_length
        out_state#[t] = current_state
        
        random_val = randomUniform(0, 1)
        cumulative_prob = 0
        next_state = 1
        
        for j from 1 to k
            idx = (current_state - 1) * k + j
            cumulative_prob += trans#[idx]
            if random_val <= cumulative_prob
                next_state = j
                j = k + 1
            endif
        endfor
        
        current_state = next_state
    endfor
    
    # Select frames using index
    for t from 1 to output_sequence_length
        target_state = out_state#[t]
        n_matching = state_count#[target_state]
        
        if n_matching > 0
            random_pick = randomInteger(1, n_matching)
            idx_pos = state_offset#[target_state] + random_pick
            out_frame#[t] = state_index#[idx_pos]
        else
            out_frame#[t] = 1
        endif
    endfor
    
    # Synthesize audio
    if frame_size > 2 * frame_hop
        removeObject: sound_mono
        exitScript: "Frame Size must be <= 2x Frame Hop."
    endif
    
    max_items = output_sequence_length * 2
    odd_chain# = zero#(max_items)
    even_chain# = zero#(max_items)
    odd_count = 0
    even_count = 0
    odd_cursor = 0
    even_cursor = 0
    
    if crossfade > 0
        use_crossfade = 1
    else
        use_crossfade = 0
    endif
    
    for t from 1 to output_sequence_length
        frame_idx = out_frame#[t]
        source_time = time#[frame_idx]
        src_start = source_time - frame_size / 2
        src_end = source_time + frame_size / 2
        
        selectObject: sound
        grain = Extract part: src_start, src_end, "rectangular", 1.0, "no"
        
        if use_crossfade
            dur = Get total duration
            Formula: "self * (if x < " + string$(crossfade) + " then x/" + string$(crossfade) + 
            ... " else if x > " + string$(dur-crossfade) + " then (" + string$(dur) + "-x)/" + string$(crossfade) + 
            ... " else 1 fi fi)"
        endif
        
        dest_time = (t - 1) * frame_hop
        
        if t mod 2 == 1
            gap = dest_time - odd_cursor
            if gap > 0.00002
                silence = Create Sound from formula: "silence", 1, 0, gap, sampling_rate, "0"
                odd_count += 1
                odd_chain#[odd_count] = silence
            endif
            odd_count += 1
            odd_chain#[odd_count] = grain
            odd_cursor = dest_time + frame_size
        else
            gap = dest_time - even_cursor
            if gap > 0.00002
                silence = Create Sound from formula: "silence", 1, 0, gap, sampling_rate, "0"
                even_count += 1
                even_chain#[even_count] = silence
            endif
            even_count += 1
            even_chain#[even_count] = grain
            even_cursor = dest_time + frame_size
        endif
    endfor
    
    # Concatenate odd stream
    if odd_count > 0
        selectObject: odd_chain#[1]
        for i from 2 to odd_count
            plusObject: odd_chain#[i]
        endfor
        stream_odd = Concatenate
        Rename: "Stream_Odd"
    else
        stream_odd = Create Sound from formula: "Stream_Odd", 1, 0, 0.01, sampling_rate, "0"
    endif
    
    # Concatenate even stream
    if even_count > 0
        selectObject: even_chain#[1]
        for i from 2 to even_count
            plusObject: even_chain#[i]
        endfor
        stream_even = Concatenate
        Rename: "Stream_Even"
    else
        stream_even = Create Sound from formula: "Stream_Even", 1, 0, 0.01, sampling_rate, "0"
    endif
    
    # Cleanup grains
    if odd_count > 0
        selectObject: odd_chain#[1]
        for i from 2 to odd_count
            plusObject: odd_chain#[i]
        endfor
        if even_count > 0
            for i from 1 to even_count
                plusObject: even_chain#[i]
            endfor
        endif
        Remove
    elsif even_count > 0
        selectObject: even_chain#[1]
        for i from 2 to even_count
            plusObject: even_chain#[i]
        endfor
        Remove
    endif
    
    # Mix streams
    selectObject: stream_even
    Formula: "self + object(stream_odd)"
    removeObject: stream_odd
    
    selectObject: stream_even
    Scale peak: 0.99
    
    if pass = 1
        channel_left = stream_even
        Rename: "Channel_Left"
    else
        channel_right = stream_even
        Rename: "Channel_Right"
    endif
endfor

################################################################################
# STEP 7: COMBINE TO STEREO (if applicable)
################################################################################

if stereo_output
    if show_detailed_info
        appendInfoLine: "Step 7: Combining to stereo..."
    endif
    
    # Get durations and match lengths
    selectObject: channel_left
    dur_left = Get total duration
    
    selectObject: channel_right
    dur_right = Get total duration
    
    # Use the shorter duration
    if dur_left < dur_right
        final_dur = dur_left
        selectObject: channel_right
        channel_right_trimmed = Extract part: 0, final_dur, "rectangular", 1.0, "no"
        removeObject: channel_right
        channel_right = channel_right_trimmed
    elsif dur_right < dur_left
        final_dur = dur_right
        selectObject: channel_left
        channel_left_trimmed = Extract part: 0, final_dur, "rectangular", 1.0, "no"
        removeObject: channel_left
        channel_left = channel_left_trimmed
    endif
    
    # Combine to stereo
    selectObject: channel_left, channel_right
    output_sound = Combine to stereo
    Rename: "Markov_Timbre_Sequence_Stereo"
    
    removeObject: channel_left, channel_right
else
    output_sound = channel_left
    Rename: "Markov_Timbre_Sequence"
endif

################################################################################
# CLEANUP AND FINALIZATION
################################################################################

removeObject: sound_mono

selectObject: output_sound

if show_detailed_info
    selectObject: output_sound
    dur = Get total duration
    n_ch = Get number of channels
    appendInfoLine: ""
    appendInfoLine: "=== Markov Chain Timbre Sequencer Complete ==="
    appendInfoLine: "Output: ", selected$("Sound")
    appendInfoLine: "Duration: ", fixed$(dur, 3), " s"
    appendInfoLine: "Channels: ", n_ch
    appendInfoLine: ""
    appendInfoLine: "Generated sound is now selected."
    appendInfoLine: "Original sound: ", sound_name$
endif
Play