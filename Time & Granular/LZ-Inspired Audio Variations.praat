# ============================================================
# Praat AudioTools - LZ-Inspired Audio Variations
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   LZ-Inspired Audio Variations
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# LZ-Inspired Audio Variations
# Implements vectorization and sort-and-sweep algorithms

form LZ Audio Variations (Optimized)
    comment === Segmentation Parameters ===
    choice Analysis_type 1
        button Pitch
        button Spectrum
        button Intensity
    positive Window_size_(seconds) 0.1
    positive Overlap_(0-0.99) 0.5
    
    comment === Similarity Threshold ===
    positive Similarity_threshold_(0-1) 0.8
    comment (Higher = more similar patterns required)
    
    comment === Distance Metric ===
    choice Distance_metric 1
        button Euclidean
        button Correlation
        button Cosine
    
    comment === Variation Method ===
    choice Variation_method 1
        button Pitch shift
        button Time stretch
        button Amplitude modulation
        button Spectral filter
        button Reverse
        button Granular shuffle
    
    comment === Variation Parameters ===
    real Variation_amount 0.5
    comment (0-1: subtle to extreme)
    
    comment === Output ===
    positive Output_duration_(seconds) 10
    boolean Randomize_dictionary_order 1
    boolean Play_output 1
endform

# Get original sound
original_sound = selected("Sound")
sound_name$ = selected$("Sound")
sample_rate = Get sampling frequency
total_duration = Get total duration

writeInfoLine: "=== LZ-Inspired Audio Analysis (OPTIMIZED) ==="
appendInfoLine: "Analysis type: ", analysis_type$
appendInfoLine: "Window size: ", window_size, " s"
appendInfoLine: "Overlap: ", overlap * 100, "%"
appendInfoLine: ""

# Calculate hop size
hop_size = window_size * (1 - overlap)
num_windows = floor((total_duration - window_size) / hop_size) + 1

appendInfoLine: "Number of windows: ", num_windows
appendInfoLine: "Analyzing..."

# === STEP 1: Extract features for each window ===
features = Create Table with column names: "features", num_windows, "start end index"

for i to num_windows
    start_time = (i - 1) * hop_size
    end_time = start_time + window_size
    
    selectObject: features
    Set numeric value: i, "start", start_time
    Set numeric value: i, "end", end_time
    Set numeric value: i, "index", i
endfor

# Extract analysis-specific features
selectObject: original_sound

if analysis_type = 1
    # PITCH ANALYSIS
    appendInfoLine: "Extracting pitch contours..."
    pitch = To Pitch: 0, 75, 600
    
    for i to num_windows
        selectObject: features
        start_time = Get value: i, "start"
        end_time = Get value: i, "end"
        
        selectObject: pitch
        mean_f0 = Get mean: start_time, end_time, "Hertz"
        stdev_f0 = Get standard deviation: start_time, end_time, "Hertz"
        
        selectObject: features
        if i = 1
            Append column: "mean_f0"
            Append column: "stdev_f0"
        endif
        Set numeric value: i, "mean_f0", mean_f0
        Set numeric value: i, "stdev_f0", stdev_f0
    endfor
    
elsif analysis_type = 2
    # SPECTRAL ANALYSIS
    appendInfoLine: "Extracting spectral features..."
    
    for i to num_windows
        selectObject: features
        start_time = Get value: i, "start"
        end_time = Get value: i, "end"
        
        selectObject: original_sound
        segment = Extract part: start_time, end_time, "rectangular", 1, "no"
        spectrum = To Spectrum: "yes"
        
        cog = Get centre of gravity: 2
        stdev = Get standard deviation: 2
        
        removeObject: segment, spectrum
        
        selectObject: features
        if i = 1
            Append column: "spectral_cog"
            Append column: "spectral_stdev"
        endif
        Set numeric value: i, "spectral_cog", cog
        Set numeric value: i, "spectral_stdev", stdev
    endfor
    
elsif analysis_type = 3
    # INTENSITY ANALYSIS
    appendInfoLine: "Extracting intensity contours..."
    intensity = To Intensity: 100, 0, "yes"
    
    for i to num_windows
        selectObject: features
        start_time = Get value: i, "start"
        end_time = Get value: i, "end"
        
        selectObject: intensity
        mean_int = Get mean: start_time, end_time, "energy"
        max_int = Get maximum: start_time, end_time, "Parabolic"
        
        selectObject: features
        if i = 1
            Append column: "mean_intensity"
            Append column: "max_intensity"
        endif
        Set numeric value: i, "mean_intensity", mean_int
        Set numeric value: i, "max_intensity", max_int
    endfor
endif

# === OPTIMIZATION 1: VECTORIZATION ===
# Load features into arrays for fast access (eliminates selectObject overhead)
appendInfoLine: "Loading features into memory..."

selectObject: features
start_times# = zero# (num_windows)
end_times# = zero# (num_windows)
original_indices# = zero# (num_windows)
feature1# = zero# (num_windows)
feature2# = zero# (num_windows)

for i to num_windows
    start_times# [i] = Get value: i, "start"
    end_times# [i] = Get value: i, "end"
    original_indices# [i] = Get value: i, "index"
    
    if analysis_type = 1
        feature1# [i] = Get value: i, "mean_f0"
        feature2# [i] = Get value: i, "stdev_f0"
    elsif analysis_type = 2
        feature1# [i] = Get value: i, "spectral_cog"
        feature2# [i] = Get value: i, "spectral_stdev"
    else
        feature1# [i] = Get value: i, "mean_intensity"
        feature2# [i] = Get value: i, "max_intensity"
    endif
endfor

# === OPTIMIZATION 2: SORT AND SWEEP ===
# Sort by primary feature to enable early termination
appendInfoLine: "Sorting features for efficient comparison..."

if analysis_type = 1
    selectObject: features
    Sort rows: "mean_f0"
elsif analysis_type = 2
    selectObject: features
    Sort rows: "spectral_cog"
else
    selectObject: features
    Sort rows: "mean_intensity"
endif

# Reload sorted arrays
for i to num_windows
    selectObject: features
    original_indices# [i] = Get value: i, "index"
    
    if analysis_type = 1
        feature1# [i] = Get value: i, "mean_f0"
        feature2# [i] = Get value: i, "stdev_f0"
    elsif analysis_type = 2
        feature1# [i] = Get value: i, "spectral_cog"
        feature2# [i] = Get value: i, "spectral_stdev"
    else
        feature1# [i] = Get value: i, "mean_intensity"
        feature2# [i] = Get value: i, "max_intensity"
    endif
endfor

# === STEP 2: Calculate distances and build dictionary ===
appendInfoLine: ""
appendInfoLine: "Building similarity dictionary..."

dictionary = Create Table with column names: "dictionary", 0, "window_id similar_to distance"

num_pairs = 0
comparisons_made = 0
comparisons_skipped = 0

# Determine max acceptable difference for early break
if analysis_type = 1
    max_acceptable_diff = 600 * (1 - similarity_threshold)
elsif analysis_type = 2
    max_acceptable_diff = 5000 * (1 - similarity_threshold)
else
    max_acceptable_diff = 100 * (1 - similarity_threshold)
endif

for i to num_windows - 1
    # Load from vectorized arrays (FAST!)
    f1_i = feature1# [i]
    f2_i = feature2# [i]
    idx_i = original_indices# [i]
    
    # Only process if value is defined
    if f1_i <> undefined
        # Inner loop with early break
        for j from i + 1 to num_windows
            f1_j = feature1# [j]
            f2_j = feature2# [j]
            
            # Only process if value is defined
            if f1_j <> undefined
                idx_j = original_indices# [j]
                
                # === SORT AND SWEEP: Early termination ===
                # Since sorted, if difference exceeds threshold, break
                primary_diff = abs(f1_j - f1_i)
                
                if primary_diff > max_acceptable_diff
                    comparisons_skipped += (num_windows - j + 1)
                    j = num_windows + 1
                else
                    comparisons_made += 1
                    
                    # Calculate distance using vectorized data (no selectObject!)
                    if distance_metric = 1
                        # Euclidean
                        dist = sqrt((f1_i - f1_j)^2 + (f2_i - f2_j)^2)
                        if analysis_type = 1
                            max_dist = 600
                        elsif analysis_type = 2
                            max_dist = 5000
                        else
                            max_dist = 100
                        endif
                        
                    elsif distance_metric = 2
                        # Correlation
                        dist = abs(f1_i - f1_j) / max(abs(f1_i), abs(f1_j))
                        max_dist = 1
                        
                    else
                        # Cosine
                        dist = 1 - (min(abs(f1_i), abs(f1_j)) / max(abs(f1_i), abs(f1_j)))
                        max_dist = 1
                    endif
                    
                    # Normalize and check similarity
                    similarity = 1 - (dist / max_dist)
                    
                    if similarity >= similarity_threshold
                        selectObject: dictionary
                        Append row
                        num_pairs += 1
                        Set numeric value: num_pairs, "window_id", idx_i
                        Set numeric value: num_pairs, "similar_to", idx_j
                        Set numeric value: num_pairs, "distance", dist
                    endif
                endif
            endif
        endfor
    endif
endfor

selectObject: dictionary
num_patterns = Get number of rows
appendInfoLine: "Found ", num_patterns, " similar pattern pairs"
appendInfoLine: "Comparisons made: ", comparisons_made
appendInfoLine: "Comparisons skipped: ", comparisons_skipped
total_possible = (num_windows * (num_windows - 1)) / 2
if comparisons_made > 0
    speedup = total_possible / comparisons_made
    appendInfoLine: "Speedup factor: ", fixed$(speedup, 2), "x"
endif

# === STEP 3: Create variations ===
appendInfoLine: ""
appendInfoLine: "Creating variations..."

num_output_windows = floor(output_duration / window_size)
segment_ids# = zero# (num_output_windows)

for out_i to num_output_windows
    if out_i mod 10 = 0
        appendInfoLine: "Processing window ", out_i, "/", num_output_windows
    endif
    
    if num_patterns > 0 and randomize_dictionary_order
        selectObject: dictionary
        random_pair = randomInteger(1, num_patterns)
        window_idx = Get value: random_pair, "window_id"
        
        if randomUniform(0, 1) > 0.5
            window_idx = Get value: random_pair, "similar_to"
        endif
    else
        window_idx = ((out_i - 1) mod num_windows) + 1
    endif
    
    # Use vectorized lookup (FAST!)
    start_time = start_times# [window_idx]
    end_time = end_times# [window_idx]
    
    selectObject: original_sound
    segment = Extract part: start_time, end_time, "rectangular", 1, "no"
    
    varied_segment = selected("Sound")
    
    if variation_method = 1
        shift_semitones = randomGauss(0, 12 * variation_amount)
        manipulation = To Manipulation: 0.01, 75, 600
        pitch_tier = Extract pitch tier
        Formula: "self * 2^('shift_semitones'/12)"
        plusObject: manipulation
        Replace pitch tier
        selectObject: manipulation
        varied_segment = Get resynthesis (overlap-add)
        removeObject: manipulation, pitch_tier
        
    elsif variation_method = 2
        stretch_factor = 1 + randomGauss(0, variation_amount)
        stretch_factor = max(0.5, min(2, stretch_factor))
        manipulation = To Manipulation: 0.01, 75, 600
        duration_tier = Extract duration tier
        Add point: start_time + window_size/2, stretch_factor
        plusObject: manipulation
        Replace duration tier
        selectObject: manipulation
        varied_segment = Get resynthesis (overlap-add)
        removeObject: manipulation, duration_tier
        
    elsif variation_method = 3
        selectObject: segment
        varied_segment = Copy: "modulated"
        mod_freq = 10 * (1 + variation_amount * 10)
        Formula: "self * (1 + 'variation_amount' * sin(2*pi*'mod_freq'*x))"
        
    elsif variation_method = 4
        selectObject: segment
        spectrum = To Spectrum: "yes"
        cutoff = 1000 + randomUniform(-500, 500) * variation_amount
        Formula: "if x < 'cutoff' then self * (1 - 'variation_amount') else self fi"
        varied_segment = To Sound
        removeObject: spectrum
        
    elsif variation_method = 5
        if randomUniform(0, 1) < variation_amount
            selectObject: segment
            varied_segment = Copy: "reversed"
            Reverse
        endif
        
    else
        grain_size = 0.02
        num_grains = floor(window_size / grain_size)
        grain_ids# = zero# (num_grains)
        
        for g to num_grains
            shuffled_idx = randomInteger(1, num_grains)
            shuffled_start = (shuffled_idx - 1) * grain_size
            
            selectObject: segment
            temp_grain = Extract part: shuffled_start, shuffled_start + grain_size, "rectangular", 1, "no"
            grain_ids# [g] = temp_grain
        endfor
        
        selectObject: grain_ids# [1]
        for g from 2 to num_grains
            plusObject: grain_ids# [g]
        endfor
        varied_segment = Concatenate
        
        for g to num_grains
            removeObject: grain_ids# [g]
        endfor
    endif
    
    segment_ids# [out_i] = varied_segment
    
    if varied_segment <> segment
        removeObject: segment
    endif
endfor

# === Concatenate all segments ===
appendInfoLine: ""
appendInfoLine: "Concatenating segments..."

selectObject: segment_ids# [1]
for i from 2 to num_output_windows
    plusObject: segment_ids# [i]
endfor

output = Concatenate
Rename: sound_name$ + "_LZ_variation"

for i to num_output_windows
    removeObject: segment_ids# [i]
endfor

# Trim to exact output duration
selectObject: output
current_duration = Get total duration
if current_duration > output_duration
    trimmed = Extract part: 0, output_duration, "rectangular", 1, "no"
    removeObject: output
    output = trimmed
    selectObject: output
    Rename: sound_name$ + "_LZ_variation"
endif

selectObject: output
Scale peak: 0.99
final_duration = Get total duration

# === FINAL OUTPUT ===
appendInfoLine: ""
appendInfoLine: "=== Complete ==="
appendInfoLine: "Output duration: ", final_duration, " seconds"
appendInfoLine: "Dictionary size: ", num_patterns, " similar pairs"
appendInfoLine: ""
appendInfoLine: "Output sound created: ", sound_name$, "_LZ_variation"

if play_output
    appendInfoLine: ""
    appendInfoLine: "Playing output..."
    Play
endif

# Cleanup
if analysis_type = 1
    removeObject: pitch
elsif analysis_type = 3
    removeObject: intensity
endif

removeObject: features, dictionary

selectObject: output