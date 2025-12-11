# ============================================================
# Praat AudioTools - Hidden Markov Model (HMM) Timbre Sequencing
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Hidden Markov Model (HMM) Timbre Sequencing
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

################################################################################
# Hidden Markov Model (HMM) Timbre Sequencing
################################################################################

form Markov Chain Timbre Sequencer
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
    boolean Show_detailed_info 1
endform

################################################################################
# INITIALIZATION AND VALIDATION
################################################################################

numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")
selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency

frame_size = frame_size / 1000
frame_hop = frame_hop / 1000
crossfade = crossfade_duration / 1000

num_frames = floor((duration - frame_size) / frame_hop) + 1

if num_frames < number_of_timbre_states
    exitScript: "Sound is too short for ", number_of_timbre_states, " states. Reduce K or use longer sound."
endif

if show_detailed_info
    writeInfoLine: "=== Markov Chain Timbre Sequencer ==="
    appendInfoLine: "Sound: ", sound_name$
    appendInfoLine: "Duration: ", fixed$(duration, 3), " s"
    appendInfoLine: "Frames: ", num_frames
    appendInfoLine: "States (K): ", number_of_timbre_states
    appendInfoLine: ""
    appendInfoLine: "Creating global analysis objects..."
endif

################################################################################
# CREATE GLOBAL ANALYSIS OBJECTS (ONCE)
################################################################################

selectObject: sound
pitch_global = To Pitch: 0, 150, 600

selectObject: sound
spectrogram_global = To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"

if show_detailed_info
    appendInfoLine: "  Global Pitch and Spectrogram created"
endif

################################################################################
# STEP 1: FEATURE EXTRACTION (OPTIMIZED)
################################################################################

if show_detailed_info
    appendInfoLine: "Step 1: Extracting features..."
endif

feature_table = Create Table with column names: "features", num_frames,
    ... "time intensity pitch centroid slope"

for i from 1 to num_frames
    start_time = (i - 1) * frame_hop
    end_time = start_time + frame_size
    mid_time = start_time + frame_size / 2
    
    selectObject: sound
    frame_sound = Extract part: start_time, end_time, "rectangular", 1.0, "no"
    intensity_value = Get root-mean-square: 0, 0
    
    selectObject: frame_sound
    spectrum = To Spectrum: "yes"
    centroid_value = Get centre of gravity: 2
    
    low_freq_start = 100
    low_freq_end = 1000
    mid_freq_start = 1000
    mid_freq_end = 4000
    high_freq_start = 4000
    high_freq_end = 8000
    
    low_bin_start_real = Get bin number from frequency: low_freq_start
    low_bin_end_real = Get bin number from frequency: low_freq_end
    mid_bin_start_real = Get bin number from frequency: mid_freq_start
    mid_bin_end_real = Get bin number from frequency: mid_freq_end
    high_bin_start_real = Get bin number from frequency: high_freq_start
    high_bin_end_real = Get bin number from frequency: high_freq_end
    
    low_bin_start = round(low_bin_start_real)
    low_bin_end = round(low_bin_end_real)
    mid_bin_start = round(mid_bin_start_real)
    mid_bin_end = round(mid_bin_end_real)
    high_bin_start = round(high_bin_start_real)
    high_bin_end = round(high_bin_end_real)
    
    low_power = 0
    mid_power = 0
    high_power = 0
    
    for bin from low_bin_start to low_bin_end
        re = Get real value in bin: bin
        im = Get imaginary value in bin: bin
        low_power += re * re + im * im
    endfor
    
    for bin from mid_bin_start to mid_bin_end
        re = Get real value in bin: bin
        im = Get imaginary value in bin: bin
        mid_power += re * re + im * im
    endfor
    
    for bin from high_bin_start to high_bin_end
        re = Get real value in bin: bin
        im = Get imaginary value in bin: bin
        high_power += re * re + im * im
    endfor
    
    low_power = low_power / (low_bin_end - low_bin_start + 1)
    mid_power = mid_power / (mid_bin_end - mid_bin_start + 1)
    high_power = high_power / (high_bin_end - high_bin_start + 1)
    
    if low_power > 0 and high_power > 0
        slope_value = (log10(high_power) - log10(low_power)) / log10(high_freq_start / low_freq_start)
    else
        slope_value = 0
    endif
    
    removeObject: spectrum
    removeObject: frame_sound
    
    selectObject: pitch_global
    pitch_value = Get value at time: mid_time, "Hertz", "Linear"
    if pitch_value = undefined
        pitch_value = 0
    endif
    
    selectObject: feature_table
    Set numeric value: i, "time", mid_time
    Set numeric value: i, "intensity", intensity_value
    Set numeric value: i, "pitch", pitch_value
    Set numeric value: i, "centroid", centroid_value
    Set numeric value: i, "slope", slope_value
endfor

removeObject: pitch_global, spectrogram_global

if show_detailed_info
    appendInfoLine: "  Extracted 4 features per frame (optimized)"
endif

################################################################################
# STEP 2: FEATURE NORMALIZATION
################################################################################

if show_detailed_info
    appendInfoLine: "Step 2: Normalizing features..."
endif

selectObject: feature_table

mean_intensity = 0
mean_pitch = 0
mean_centroid = 0
mean_slope = 0

for i from 1 to num_frames
    mean_intensity += Get value: i, "intensity"
    mean_pitch += Get value: i, "pitch"
    mean_centroid += Get value: i, "centroid"
    mean_slope += Get value: i, "slope"
endfor

mean_intensity /= num_frames
mean_pitch /= num_frames
mean_centroid /= num_frames
mean_slope /= num_frames

std_intensity = 0
std_pitch = 0
std_centroid = 0
std_slope = 0

for i from 1 to num_frames
    diff_intensity = Get value: i, "intensity"
    diff_intensity -= mean_intensity
    std_intensity += diff_intensity * diff_intensity
    
    diff_pitch = Get value: i, "pitch"
    diff_pitch -= mean_pitch
    std_pitch += diff_pitch * diff_pitch
    
    diff_centroid = Get value: i, "centroid"
    diff_centroid -= mean_centroid
    std_centroid += diff_centroid * diff_centroid
    
    diff_slope = Get value: i, "slope"
    diff_slope -= mean_slope
    std_slope += diff_slope * diff_slope
endfor

std_intensity = sqrt(std_intensity / num_frames)
std_pitch = sqrt(std_pitch / num_frames)
std_centroid = sqrt(std_centroid / num_frames)
std_slope = sqrt(std_slope / num_frames)

if std_intensity < 1e-10
    std_intensity = 1
endif
if std_pitch < 1e-10
    std_pitch = 1
endif
if std_centroid < 1e-10
    std_centroid = 1
endif
if std_slope < 1e-10
    std_slope = 1
endif

Append column: "norm_intensity"
Append column: "norm_pitch"
Append column: "norm_centroid"
Append column: "norm_slope"

for i from 1 to num_frames
    val = Get value: i, "intensity"
    Set numeric value: i, "norm_intensity", (val - mean_intensity) / std_intensity
    
    val = Get value: i, "pitch"
    Set numeric value: i, "norm_pitch", (val - mean_pitch) / std_pitch
    
    val = Get value: i, "centroid"
    Set numeric value: i, "norm_centroid", (val - mean_centroid) / std_centroid
    
    val = Get value: i, "slope"
    Set numeric value: i, "norm_slope", (val - mean_slope) / std_slope
endfor

################################################################################
# STEP 3: K-MEANS CLUSTERING
################################################################################

if show_detailed_info
    appendInfoLine: "Step 3: Clustering into ", number_of_timbre_states, " timbre states..."
endif

k = number_of_timbre_states
centroids = Create Table with column names: "centroids", k,
    ... "intensity pitch centroid slope"

selectObject: feature_table
for state from 1 to k
    random_frame = randomInteger(1, num_frames)
    
    selectObject: feature_table
    intensity_val = Get value: random_frame, "norm_intensity"
    pitch_val = Get value: random_frame, "norm_pitch"
    centroid_val = Get value: random_frame, "norm_centroid"
    slope_val = Get value: random_frame, "norm_slope"
    
    selectObject: centroids
    Set numeric value: state, "intensity", intensity_val
    Set numeric value: state, "pitch", pitch_val
    Set numeric value: state, "centroid", centroid_val
    Set numeric value: state, "slope", slope_val
endfor

selectObject: feature_table
Append column: "state"

for iteration from 1 to max_kmeans_iterations
    assignments_changed = 0
    
    selectObject: feature_table
    for i from 1 to num_frames
        frame_int = Get value: i, "norm_intensity"
        frame_pitch = Get value: i, "norm_pitch"
        frame_cent = Get value: i, "norm_centroid"
        frame_slope = Get value: i, "norm_slope"
        
        min_distance = 1e10
        best_state = 1
        
        selectObject: centroids
        for state from 1 to k
            cent_int = Get value: state, "intensity"
            cent_pitch = Get value: state, "pitch"
            cent_cent = Get value: state, "centroid"
            cent_slope = Get value: state, "slope"
            
            distance = sqrt((frame_int - cent_int)^2 + 
                ...          (frame_pitch - cent_pitch)^2 + 
                ...          (frame_cent - cent_cent)^2 + 
                ...          (frame_slope - cent_slope)^2)
            
            if distance < min_distance
                min_distance = distance
                best_state = state
            endif
        endfor
        
        selectObject: feature_table
        old_state = Get value: i, "state"
        if old_state <> best_state
            assignments_changed += 1
        endif
        Set numeric value: i, "state", best_state
    endfor
    
    selectObject: centroids
    for state from 1 to k
        sum_int = 0
        sum_pitch = 0
        sum_cent = 0
        sum_slope = 0
        count = 0
        
        selectObject: feature_table
        for i from 1 to num_frames
            frame_state = Get value: i, "state"
            if frame_state = state
                sum_int += Get value: i, "norm_intensity"
                sum_pitch += Get value: i, "norm_pitch"
                sum_cent += Get value: i, "norm_centroid"
                sum_slope += Get value: i, "norm_slope"
                count += 1
            endif
        endfor
        
        if count > 0
            selectObject: centroids
            Set numeric value: state, "intensity", sum_int / count
            Set numeric value: state, "pitch", sum_pitch / count
            Set numeric value: state, "centroid", sum_cent / count
            Set numeric value: state, "slope", sum_slope / count
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
# STEP 4: MARKOV CHAIN TRANSITION MATRIX
################################################################################

if show_detailed_info
    appendInfoLine: "Step 4: Learning transition probabilities..."
endif

transition_matrix = Create Table with column names: "transitions", k, "state_1"
for i from 2 to k
    col_name$ = "state_" + string$(i)
    Append column: col_name$
endfor

initial_probs = Create Table with column names: "initial", 1, "state_1"
for i from 2 to k
    col_name$ = "state_" + string$(i)
    Append column: col_name$
endfor

selectObject: feature_table
first_state = Get value: 1, "state"

selectObject: initial_probs
for i from 1 to k
    Set numeric value: 1, "state_" + string$(i), 0
endfor
Set numeric value: 1, "state_" + string$(first_state), 1.0

selectObject: transition_matrix
for i from 1 to k
    for j from 1 to k
        Set numeric value: i, "state_" + string$(j), 0
    endfor
endfor

for i from 1 to num_frames - 1
    selectObject: feature_table
    current_state = Get value: i, "state"
    next_state = Get value: i + 1, "state"
    
    selectObject: transition_matrix
    current_count = Get value: current_state, "state_" + string$(next_state)
    Set numeric value: current_state, "state_" + string$(next_state), current_count + 1
endfor

selectObject: transition_matrix
for i from 1 to k
    row_sum = 0
    for j from 1 to k
        row_sum += Get value: i, "state_" + string$(j)
    endfor
    
    if row_sum > 0
        for j from 1 to k
            val = Get value: i, "state_" + string$(j)
            Set numeric value: i, "state_" + string$(j), val / row_sum
        endfor
    else
        for j from 1 to k
            Set numeric value: i, "state_" + string$(j), 1.0 / k
        endfor
    endif
endfor

if show_detailed_info
    appendInfoLine: "  Transition matrix learned"
endif

################################################################################
# STEP 5: GENERATE NEW STATE SEQUENCE
################################################################################

if show_detailed_info
    appendInfoLine: "Step 5: Generating new sequence (", output_sequence_length, " frames)..."
endif

sequence_table = Create Table with column names: "sequence", output_sequence_length,
    ... "state frame_index"

current_state = first_state

for t from 1 to output_sequence_length
    selectObject: sequence_table
    Set numeric value: t, "state", current_state
    
    selectObject: transition_matrix
    random_val = randomUniform(0, 1)
    cumulative_prob = 0
    next_state = 1
    
    for j from 1 to k
        trans_prob = Get value: current_state, "state_" + string$(j)
        cumulative_prob += trans_prob
        if random_val <= cumulative_prob
            next_state = j
            j = k + 1
        endif
    endfor
    
    current_state = next_state
endfor

for t from 1 to output_sequence_length
    selectObject: sequence_table
    target_state = Get value: t, "state"
    
    selectObject: feature_table
    matching_frames = 0
    for i from 1 to num_frames
        frame_state = Get value: i, "state"
        if frame_state = target_state
            matching_frames += 1
        endif
    endfor
    
    if matching_frames > 0
        random_pick = randomInteger(1, matching_frames)
        match_counter = 0
        selected_frame = 1
        
        for i from 1 to num_frames
            selectObject: feature_table
            frame_state = Get value: i, "state"
            if frame_state = target_state
                match_counter += 1
                if match_counter = random_pick
                    selected_frame = i
                    i = num_frames + 1
                endif
            endif
        endfor
    else
        selected_frame = 1
    endif
    
    selectObject: sequence_table
    Set numeric value: t, "frame_index", selected_frame
endfor

if show_detailed_info
    appendInfoLine: "  State sequence generated"
endif

################################################################################
# STEP 6: SYNTHESIZE OUTPUT SOUND (OPTIMIZED CONCATENATION)
# Fixed: Universal Mixing & Object Management
################################################################################

if show_detailed_info
    appendInfoLine: "Step 6: Synthesizing audio (Batch Concatenation)..."
endif

# --- 1. Get Source Properties ---
selectObject: sound
n_channels = Get number of channels

# --- 2. Validation for Fast Mode ---
if frame_size > 2 * frame_hop
    exitScript: "Optimization Error: Frame Size must be <= 2x Frame Hop for this method."
endif

# --- 3. Initialize Object Tracking ---
max_items = output_sequence_length * 2
odd_chain# = zero#(max_items)
even_chain# = zero#(max_items)
odd_count = 0
even_count = 0
odd_cursor = 0
even_cursor = 0

# --- 4. Generate Grains ---
for t from 1 to output_sequence_length
    selectObject: sequence_table
    frame_idx = Get value: t, "frame_index"
    
    selectObject: feature_table
    source_time = Get value: frame_idx, "time"
    src_start = source_time - frame_size / 2
    src_end = source_time + frame_size / 2
    
    selectObject: sound
    grain = Extract part: src_start, src_end, "rectangular", 1.0, "no"
    
    if crossfade > 0
        dur = Get total duration
        Formula: "self * (if x < " + string$(crossfade) + " then x/" + string$(crossfade) + 
        ... " else if x > " + string$(dur-crossfade) + " then (" + string$(dur) + "-x)/" + string$(crossfade) + 
        ... " else 1 fi fi)"
    endif
    
    dest_time = (t - 1) * frame_hop
    
    if t mod 2 == 1
        # --- ODD STREAM ---
        gap = dest_time - odd_cursor
        if gap > 0.00002
            silence = Create Sound from formula: "silence", n_channels, 0, gap, sampling_rate, "0"
            odd_count += 1
            odd_chain#[odd_count] = silence
        endif
        odd_count += 1
        odd_chain#[odd_count] = grain
        odd_cursor = dest_time + frame_size
    else
        # --- EVEN STREAM ---
        gap = dest_time - even_cursor
        if gap > 0.00002
            silence = Create Sound from formula: "silence", n_channels, 0, gap, sampling_rate, "0"
            even_count += 1
            even_chain#[even_count] = silence
        endif
        even_count += 1
        even_chain#[even_count] = grain
        even_cursor = dest_time + frame_size
    endif
endfor

# --- 5. Batch Concatenate ---

# Odd Stream
if odd_count > 0
    selectObject: odd_chain#[1]
    for i from 2 to odd_count
        plusObject: odd_chain#[i]
    endfor
    stream_odd = Concatenate
    Rename: "Stream_Odd"
else
    stream_odd = Create Sound from formula: "Stream_Odd", n_channels, 0, 0.01, sampling_rate, "0"
endif

# Even Stream
if even_count > 0
    selectObject: even_chain#[1]
    for i from 2 to even_count
        plusObject: even_chain#[i]
    endfor
    stream_even = Concatenate
    Rename: "Stream_Even"
else
    stream_even = Create Sound from formula: "Stream_Even", n_channels, 0, 0.01, sampling_rate, "0"
endif

# --- 6. Cleanup Grain Objects ---
# We do this immediately to free up memory
selectObject: odd_chain#[1]
for i from 2 to odd_count
    plusObject: odd_chain#[i]
endfor
for i from 1 to even_count
    plusObject: even_chain#[i]
endfor
Remove

# --- 7. Final Mix (Universal) ---
# We add Odd stream into Even stream.
# This works for both Mono and Stereo without volume loss.
selectObject: stream_even
Formula: "self + object(stream_odd)"

# Even stream is now the full mix. We delete Odd.
removeObject: stream_odd

# Final Polish
selectObject: stream_even
Rename: "Markov_Timbre_Sequence"
Scale peak: 0.99
output_sound = stream_even

if show_detailed_info
    dur = Get total duration
    appendInfoLine: "  Audio synthesis complete."
    appendInfoLine: ""
    appendInfoLine: "=== Markov Chain Timbre Sequencer Complete ==="
    appendInfoLine: "Output: Markov_Timbre_Sequence"
    appendInfoLine: "Duration: ", fixed$(dur, 3), " s"
endif

################################################################################
# CLEANUP AND FINALIZATION
################################################################################

removeObject: feature_table, centroids, transition_matrix, 
    ... initial_probs, sequence_table

selectObject: output_sound

if show_detailed_info
    appendInfoLine: ""
    appendInfoLine: "Generated sound is now selected."
    appendInfoLine: "Original sound: ", sound_name$
endif
Play