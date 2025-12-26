# ============================================================
# Praat AudioTools - Neural Granular Texture Morpher
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025) - Optimized + Stereo
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Granular Texture Morpher
#   Optimizations:
#   - Proper overlap-add synthesis
#   - Smooth morphing between clusters
#   - Multiple morph modes
#   - Native arrays
#   - Stereo output
#   - Grain variation controls
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Neural Texture Morpher
    comment === Preset ===
    optionmenu Preset 1
        option Manual (Use Settings Below)
        option Slow Evolution
        option Rapid Texture
        option Random Walk
        option Rhythmic Cycle
        option Ambient Drift
        option Chaotic Morph
    
    comment === Analysis Parameters ===
    positive Grain_size_ms 60
    positive Overlap_ratio 0.5
    integer Number_of_clusters 4
    
    comment === Synthesis Parameters ===
    positive Output_duration_sec 10.0
    positive Morph_speed_hz 0.5
    optionmenu Morph_mode 1
        option Cycle (linear)
        option Pendulum (back-forth)
        option Random Walk
        option Random Jump
        option Weighted Random
    
    comment === Grain Variation ===
    real Pitch_scatter_semitones 0.0
    real Position_randomness 0.2
    real Density_variation 0.1
    
    comment === Output ===
    boolean Stereo_output 1
    real Stereo_spread 0.5
    boolean Play_result 1
endform

# ============================================
# PRESET LOGIC
# ============================================

if preset$ = "Slow Evolution"
    grain_size_ms = 80
    overlap_ratio = 0.6
    number_of_clusters = 4
    output_duration_sec = 15.0
    morph_speed_hz = 0.15
    morph_mode = 1
    pitch_scatter_semitones = 0.0
    position_randomness = 0.1
    density_variation = 0.05
    stereo_spread = 0.4

elsif preset$ = "Rapid Texture"
    grain_size_ms = 30
    overlap_ratio = 0.4
    number_of_clusters = 6
    output_duration_sec = 8.0
    morph_speed_hz = 2.0
    morph_mode = 1
    pitch_scatter_semitones = 0.5
    position_randomness = 0.3
    density_variation = 0.15
    stereo_spread = 0.6

elsif preset$ = "Random Walk"
    grain_size_ms = 50
    overlap_ratio = 0.5
    number_of_clusters = 5
    output_duration_sec = 12.0
    morph_speed_hz = 0.8
    morph_mode = 3
    pitch_scatter_semitones = 0.3
    position_randomness = 0.25
    density_variation = 0.1
    stereo_spread = 0.5

elsif preset$ = "Rhythmic Cycle"
    grain_size_ms = 40
    overlap_ratio = 0.3
    number_of_clusters = 4
    output_duration_sec = 10.0
    morph_speed_hz = 1.0
    morph_mode = 2
    pitch_scatter_semitones = 0.0
    position_randomness = 0.05
    density_variation = 0.0
    stereo_spread = 0.3

elsif preset$ = "Ambient Drift"
    grain_size_ms = 100
    overlap_ratio = 0.7
    number_of_clusters = 3
    output_duration_sec = 20.0
    morph_speed_hz = 0.1
    morph_mode = 3
    pitch_scatter_semitones = 0.2
    position_randomness = 0.15
    density_variation = 0.08
    stereo_spread = 0.7

elsif preset$ = "Chaotic Morph"
    grain_size_ms = 45
    overlap_ratio = 0.5
    number_of_clusters = 8
    output_duration_sec = 10.0
    morph_speed_hz = 1.5
    morph_mode = 4
    pitch_scatter_semitones = 1.0
    position_randomness = 0.4
    density_variation = 0.2
    stereo_spread = 0.8
endif

# ============================================
# SETUP
# ============================================

nSelected = numberOfSelected("Sound")
if nSelected <> 1
    exitScript: "Please select exactly one Sound object."
endif

snd = selected("Sound")
sndName$ = selected$("Sound")

selectObject: snd
dur = Get total duration
fs = Get sampling frequency

writeInfoLine: "=== NEURAL GRANULAR TEXTURE MORPHER ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Grain: ", grain_size_ms, " ms | Overlap: ", fixed$(overlap_ratio * 100, 0), "%"
appendInfoLine: "Clusters: ", number_of_clusters, " | Morph: ", morph_speed_hz, " Hz"
appendInfoLine: "Mode: ", morph_mode$
if stereo_output
    appendInfoLine: "Output: Stereo (spread: ", fixed$(stereo_spread * 100, 0), "%)"
else
    appendInfoLine: "Output: Mono"
endif
appendInfoLine: "========================================="
appendInfoLine: ""

# Work on mono copy
selectObject: snd
workSnd = Convert to mono
Rename: "Analysis_Work"

grainSec = grain_size_ms / 1000
stepSec = grainSec * (1 - overlap_ratio)

if dur < grainSec * 2
    removeObject: workSnd
    exitScript: "Sound is too short for granular analysis."
endif

k = number_of_clusters

# ============================================
# FEATURE EXTRACTION (Native Arrays)
# ============================================

appendInfoLine: "Analyzing grains..."

nGrains = floor((dur - grainSec) / stepSec)
if nGrains < k
    removeObject: workSnd
    exitScript: "Not enough grains for ", k, " clusters. Reduce grain size or clusters."
endif

# Feature arrays
feat_centroid# = zero#(nGrains)
feat_bandwidth# = zero#(nGrains)
feat_pitch# = zero#(nGrains)
feat_hnr# = zero#(nGrains)
feat_intensity# = zero#(nGrains)
grain_time# = zero#(nGrains)

# Create analysis objects
selectObject: workSnd
spec = To Spectrogram: grainSec, 8000, stepSec, 20, "Gaussian"

selectObject: workSnd
pit = To Pitch: stepSec, 75, 600

selectObject: workSnd
hnr_obj = To Harmonicity (cc): stepSec, 75, 0.1, 1.0

selectObject: workSnd
inten = To Intensity: 75, stepSec, "yes"

# Extract features
for i from 1 to nGrains
    t = (i - 0.5) * stepSec
    grain_time#[i] = t
    
    # Spectral features
    selectObject: spec
    slice = To Spectrum (slice): t
    selectObject: slice
    feat_centroid#[i] = Get centre of gravity: 2
    feat_bandwidth#[i] = Get standard deviation: 2
    removeObject: slice
    
    # Pitch
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        feat_pitch#[i] = 0
    else
        feat_pitch#[i] = f0
    endif
    
    # HNR
    selectObject: hnr_obj
    h = Get value at time: t, "cubic"
    if h = undefined
        feat_hnr#[i] = -50
    else
        feat_hnr#[i] = h
    endif
    
    # Intensity
    selectObject: inten
    iv = Get value at time: t, "cubic"
    if iv = undefined
        feat_intensity#[i] = 50
    else
        feat_intensity#[i] = iv
    endif
endfor

removeObject: spec, pit, hnr_obj, inten

appendInfoLine: "  ", nGrains, " grains analyzed"

# ============================================
# NORMALIZE FEATURES (Z-Score)
# ============================================

# Centroid
sum = 0
for i to nGrains
    sum += feat_centroid#[i]
endfor
mean_c = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_centroid#[i] - mean_c)^2
endfor
std_c = sqrt(sumSq / nGrains)
if std_c < 0.001
    std_c = 1
endif
norm_centroid# = zero#(nGrains)
for i to nGrains
    norm_centroid#[i] = (feat_centroid#[i] - mean_c) / std_c
endfor

# Bandwidth
sum = 0
for i to nGrains
    sum += feat_bandwidth#[i]
endfor
mean_b = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_bandwidth#[i] - mean_b)^2
endfor
std_b = sqrt(sumSq / nGrains)
if std_b < 0.001
    std_b = 1
endif
norm_bandwidth# = zero#(nGrains)
for i to nGrains
    norm_bandwidth#[i] = (feat_bandwidth#[i] - mean_b) / std_b
endfor

# Pitch
sum = 0
for i to nGrains
    sum += feat_pitch#[i]
endfor
mean_p = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_pitch#[i] - mean_p)^2
endfor
std_p = sqrt(sumSq / nGrains)
if std_p < 0.001
    std_p = 1
endif
norm_pitch# = zero#(nGrains)
for i to nGrains
    norm_pitch#[i] = (feat_pitch#[i] - mean_p) / std_p
endfor

# HNR
sum = 0
for i to nGrains
    sum += feat_hnr#[i]
endfor
mean_h = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_hnr#[i] - mean_h)^2
endfor
std_h = sqrt(sumSq / nGrains)
if std_h < 0.001
    std_h = 1
endif
norm_hnr# = zero#(nGrains)
for i to nGrains
    norm_hnr#[i] = (feat_hnr#[i] - mean_h) / std_h
endfor

# Intensity
sum = 0
for i to nGrains
    sum += feat_intensity#[i]
endfor
mean_i = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_intensity#[i] - mean_i)^2
endfor
std_i = sqrt(sumSq / nGrains)
if std_i < 0.001
    std_i = 1
endif
norm_intensity# = zero#(nGrains)
for i to nGrains
    norm_intensity#[i] = (feat_intensity#[i] - mean_i) / std_i
endfor

# ============================================
# K-MEANS CLUSTERING (Array-based)
# ============================================

appendInfoLine: "Clustering textures..."

# Centroid arrays (5 features)
cent_1# = zero#(k)
cent_2# = zero#(k)
cent_3# = zero#(k)
cent_4# = zero#(k)
cent_5# = zero#(k)

# Initialize from random grains
for c from 1 to k
    r = randomInteger(1, nGrains)
    cent_1#[c] = norm_centroid#[r]
    cent_2#[c] = norm_bandwidth#[r]
    cent_3#[c] = norm_pitch#[r]
    cent_4#[c] = norm_hnr#[r]
    cent_5#[c] = norm_intensity#[r]
endfor

# Assignments
assigns# = zero#(nGrains)

max_iter = 15
for iter from 1 to max_iter
    changes = 0
    
    # E-step: assign grains to nearest centroid
    for i from 1 to nGrains
        minDist = 1e9
        bestK = 1
        
        for c from 1 to k
            distSq = (norm_centroid#[i] - cent_1#[c])^2 +
                ... (norm_bandwidth#[i] - cent_2#[c])^2 +
                ... (norm_pitch#[i] - cent_3#[c])^2 +
                ... (norm_hnr#[i] - cent_4#[c])^2 +
                ... (norm_intensity#[i] - cent_5#[c])^2
            
            if distSq < minDist
                minDist = distSq
                bestK = c
            endif
        endfor
        
        if assigns#[i] <> bestK
            assigns#[i] = bestK
            changes += 1
        endif
    endfor
    
    # M-step: update centroids
    for c from 1 to k
        sum_1 = 0
        sum_2 = 0
        sum_3 = 0
        sum_4 = 0
        sum_5 = 0
        count = 0
        
        for i from 1 to nGrains
            if assigns#[i] = c
                sum_1 += norm_centroid#[i]
                sum_2 += norm_bandwidth#[i]
                sum_3 += norm_pitch#[i]
                sum_4 += norm_hnr#[i]
                sum_5 += norm_intensity#[i]
                count += 1
            endif
        endfor
        
        if count > 0
            cent_1#[c] = sum_1 / count
            cent_2#[c] = sum_2 / count
            cent_3#[c] = sum_3 / count
            cent_4#[c] = sum_4 / count
            cent_5#[c] = sum_5 / count
        endif
    endfor
    
    if changes = 0
        appendInfoLine: "  Converged at iteration ", iter
        iter = max_iter + 1
    endif
endfor

# ============================================
# BUILD CLUSTER INDEX
# ============================================

appendInfoLine: "  Building cluster index..."

# Count grains per cluster
cluster_count# = zero#(k)
for i from 1 to nGrains
    c = assigns#[i]
    cluster_count#[c] += 1
endfor

# Build flat index with offsets
cluster_offset# = zero#(k + 1)
cluster_offset#[1] = 0
for c from 2 to k + 1
    cluster_offset#[c] = cluster_offset#[c-1] + cluster_count#[c-1]
endfor

cluster_index# = zero#(nGrains)
cluster_fill# = zero#(k)

for i from 1 to nGrains
    c = assigns#[i]
    pos = cluster_offset#[c] + cluster_fill#[c] + 1
    cluster_index#[pos] = i
    cluster_fill#[c] += 1
endfor

# Check for empty clusters
valid_clusters = 0
for c from 1 to k
    if cluster_count#[c] > 0
        valid_clusters += 1
    endif
endfor

if valid_clusters < 2
    removeObject: workSnd
    exitScript: "Not enough distinct textures found. Try fewer clusters."
endif

appendInfoLine: "  ", valid_clusters, " valid clusters"

# ============================================
# GENERATIVE SYNTHESIS (Overlap-Add)
# ============================================

appendInfoLine: "Synthesizing texture..."

grains_needed = ceiling(output_duration_sec / stepSec)
output_dur = output_duration_sec + grainSec  ; Extra for final grain

if stereo_output
    n_passes = 2
else
    n_passes = 1
endif

# Morph state for random walk
current_cluster = 1
walk_momentum = 0

for pass from 1 to n_passes
    if stereo_output
        if pass = 1
            appendInfoLine: "  LEFT channel..."
        else
            appendInfoLine: "  RIGHT channel..."
        endif
    else
        appendInfoLine: "  Generating..."
    endif
    
    # Create output buffer
    output_buf = Create Sound from formula: "Output_" + string$(pass), 1, 0, output_dur, fs, "0"
    
    # Reset morph state for each channel (slightly different for stereo)
    if pass = 2
        current_cluster = randomInteger(1, k)
    else
        current_cluster = 1
    endif
    
    for g from 1 to grains_needed
        # Current time
        t_out = (g - 1) * stepSec
        
        # Apply density variation
        if density_variation > 0
            t_out = t_out + randomUniform(-1, 1) * density_variation * stepSec
            if t_out < 0
                t_out = 0
            endif
        endif
        
        # Determine target cluster based on morph mode
        if morph_mode = 1
            # Cycle (linear)
            cycle_pos = t_out * morph_speed_hz
            target_c = floor(cycle_pos mod k) + 1
            
        elsif morph_mode = 2
            # Pendulum (back and forth)
            cycle_pos = t_out * morph_speed_hz
            ping_pong = cycle_pos mod (2 * (k - 1))
            if ping_pong < k - 1
                target_c = floor(ping_pong) + 1
            else
                target_c = k - floor(ping_pong - (k - 1)) - 1
            endif
            target_c = max(1, min(k, target_c))
            
        elsif morph_mode = 3
            # Random walk
            if randomUniform(0, 1) < morph_speed_hz * stepSec
                walk_momentum += randomUniform(-1, 1)
                walk_momentum = walk_momentum * 0.8  ; Damping
                current_cluster += round(walk_momentum)
                if current_cluster < 1
                    current_cluster = 1
                    walk_momentum = abs(walk_momentum)
                elsif current_cluster > k
                    current_cluster = k
                    walk_momentum = -abs(walk_momentum)
                endif
            endif
            target_c = current_cluster
            
        elsif morph_mode = 4
            # Random jump
            if randomUniform(0, 1) < morph_speed_hz * stepSec
                target_c = randomInteger(1, k)
                current_cluster = target_c
            else
                target_c = current_cluster
            endif
            
        else
            # Weighted random (favor current and neighbors)
            if randomUniform(0, 1) < morph_speed_hz * stepSec * 0.5
                offset = randomInteger(-1, 1)
                target_c = current_cluster + offset
                target_c = max(1, min(k, target_c))
                current_cluster = target_c
            else
                target_c = current_cluster
            endif
        endif
        
        # Ensure valid cluster
        if target_c < 1
            target_c = 1
        elsif target_c > k
            target_c = k
        endif
        
        # Handle empty cluster
        if cluster_count#[target_c] = 0
            # Find nearest non-empty cluster
            for offset from 1 to k
                if target_c + offset <= k and cluster_count#[target_c + offset] > 0
                    target_c = target_c + offset
                    offset = k + 1
                elsif target_c - offset >= 1 and cluster_count#[target_c - offset] > 0
                    target_c = target_c - offset
                    offset = k + 1
                endif
            endfor
        endif
        
        # Select grain from cluster
        n_in_cluster = cluster_count#[target_c]
        if n_in_cluster > 0
            # Apply position randomness for stereo variation
            if stereo_output and pass = 2 and stereo_spread > 0
                r_idx = randomInteger(1, n_in_cluster)
            else
                r_idx = randomInteger(1, n_in_cluster)
            endif
            
            idx_pos = cluster_offset#[target_c] + r_idx
            grain_idx = cluster_index#[idx_pos]
        else
            grain_idx = 1
        endif
        
        # Get grain time with position randomness
        t_grain = grain_time#[grain_idx]
        if position_randomness > 0
            t_grain = t_grain + randomUniform(-1, 1) * position_randomness * grainSec
            t_grain = max(grainSec/2, min(dur - grainSec/2, t_grain))
        endif
        
        t_start = t_grain - grainSec/2
        t_end = t_grain + grainSec/2
        
        # Clamp to valid range
        if t_start < 0
            t_start = 0
            t_end = grainSec
        endif
        if t_end > dur
            t_end = dur
            t_start = dur - grainSec
            if t_start < 0
                t_start = 0
            endif
        endif
        
        # Extract grain with Hanning window
        selectObject: workSnd
        grain = Extract part: t_start, t_end, "Hanning", 1, "no"
        
        # Apply pitch scatter
        if pitch_scatter_semitones > 0
            selectObject: grain
            scatter = randomUniform(-pitch_scatter_semitones, pitch_scatter_semitones)
            ratio = 2 ^ (scatter / 12)
            orig_fs = Get sampling frequency
            new_fs = orig_fs * ratio
            if new_fs > 8000 and new_fs < 96000
                Resample: new_fs, 50
                Override sampling frequency: orig_fs
                grain_new = selected("Sound")
                removeObject: grain
                grain = grain_new
            endif
        endif
        
        # Add to output buffer (overlap-add)
        selectObject: grain
        grain_name$ = selected$("Sound")
        grain_dur = Get total duration
        
        selectObject: output_buf
        Formula (part): t_out, t_out + grain_dur, 1, 1,
            ... "self + Sound_'grain_name$'(x - " + string$(t_out) + ")"
        
        removeObject: grain
    endfor
    
    # Normalize for overlap-add gain
    selectObject: output_buf
    if overlap_ratio > 0.3
        gain_comp = 1 / (1 + overlap_ratio * 0.8)
        Formula: "self * " + string$(gain_comp)
    endif
    
    # Store channel
    if pass = 1
        channel_left = output_buf
    else
        channel_right = output_buf
    endif
endfor

# ============================================
# COMBINE OUTPUT
# ============================================

if stereo_output
    appendInfoLine: "Combining to stereo..."
    
    # Match durations
    selectObject: channel_left
    dur_L = Get total duration
    selectObject: channel_right
    dur_R = Get total duration
    
    min_dur = min(dur_L, dur_R)
    
    if dur_L > min_dur
        selectObject: channel_left
        tmp = Extract part: 0, min_dur, "rectangular", 1, "no"
        removeObject: channel_left
        channel_left = tmp
    endif
    if dur_R > min_dur
        selectObject: channel_right
        tmp = Extract part: 0, min_dur, "rectangular", 1, "no"
        removeObject: channel_right
        channel_right = tmp
    endif
    
    selectObject: channel_left, channel_right
    finalOut = Combine to stereo
    Rename: sndName$ + "_TextureMorph_stereo"
    
    removeObject: channel_left, channel_right
else
    finalOut = channel_left
    Rename: sndName$ + "_TextureMorph"
endif

selectObject: finalOut
Scale peak: 0.99

# ============================================
# CLEANUP
# ============================================

removeObject: workSnd

selectObject: snd
plusObject: finalOut

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
selectObject: finalOut
n_ch = Get number of channels
out_dur = Get total duration
appendInfoLine: "Output: ", selected$("Sound")
appendInfoLine: "Duration: ", fixed$(out_dur, 2), " s"
appendInfoLine: "Channels: ", n_ch

if play_result
    appendInfoLine: "Playing..."
    selectObject: finalOut
    Play
endif

selectObject: finalOut
