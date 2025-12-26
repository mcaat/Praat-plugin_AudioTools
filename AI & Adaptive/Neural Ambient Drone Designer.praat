# ============================================================
# Praat AudioTools - Neural Ambient Drone Designer
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025) - Optimized + Stereo
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Ambient Drone Designer
#   Optimizations:
#   - Proper layer mixing (Formula addition)
#   - Native arrays instead of TableOfReal
#   - Presets for different drone characters
#   - Stereo output with layer panning
#   - Controllable shimmer intervals
#   - Crossfade between grains
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Ambient Drone Designer 
# - Generates lush evolving drones from source material

form Neural Ambient Drone Designer
    comment === Preset ===
    optionmenu Preset 1
        option Manual (Use Settings Below)
        option Dark Ambient
        option Bright Shimmer
        option Dense Texture
        option Sparse Minimal
        option Evolving Pad
    
    comment === Synthesis Parameters ===
    positive Output_duration_sec 20.0
    positive Layer_density 3
    positive Grain_crossfade_ms 20
    
    comment === Shimmer Control ===
    boolean Add_octave_shimmer 1
    positive Shimmer_probability 0.15
    optionmenu Shimmer_intervals 1
        option Octaves only
        option Octaves and fifths
        option Full harmonic series
    
    comment === AI Analysis ===
    positive Grain_size_ms 100
    integer Number_of_clusters 3
    integer Kmeans_iterations 10
    
    comment === Output ===
    boolean Stereo_output 1
    real Stereo_width 0.7
    boolean Play_result 1
endform

# ============================================
# PRESET LOGIC
# ============================================

if preset$ = "Dark Ambient"
    output_duration_sec = 30.0
    layer_density = 4
    grain_crossfade_ms = 40
    add_octave_shimmer = 1
    shimmer_probability = 0.1
    shimmer_intervals = 1
    grain_size_ms = 150
    number_of_clusters = 3
    stereo_width = 0.8

elsif preset$ = "Bright Shimmer"
    output_duration_sec = 20.0
    layer_density = 5
    grain_crossfade_ms = 15
    add_octave_shimmer = 1
    shimmer_probability = 0.25
    shimmer_intervals = 3
    grain_size_ms = 80
    number_of_clusters = 4
    stereo_width = 0.9

elsif preset$ = "Dense Texture"
    output_duration_sec = 25.0
    layer_density = 6
    grain_crossfade_ms = 10
    add_octave_shimmer = 0
    shimmer_probability = 0.05
    shimmer_intervals = 1
    grain_size_ms = 50
    number_of_clusters = 5
    stereo_width = 0.6

elsif preset$ = "Sparse Minimal"
    output_duration_sec = 40.0
    layer_density = 2
    grain_crossfade_ms = 60
    add_octave_shimmer = 1
    shimmer_probability = 0.08
    shimmer_intervals = 1
    grain_size_ms = 200
    number_of_clusters = 2
    stereo_width = 0.5

elsif preset$ = "Evolving Pad"
    output_duration_sec = 30.0
    layer_density = 4
    grain_crossfade_ms = 30
    add_octave_shimmer = 1
    shimmer_probability = 0.18
    shimmer_intervals = 2
    grain_size_ms = 120
    number_of_clusters = 4
    stereo_width = 0.75
endif

# ============================================
# SETUP & VALIDATION
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
nch = Get number of channels

# Work on Mono Copy
selectObject: snd
workSnd = Convert to mono
Rename: "Analysis_Work"

grainSec = grain_size_ms / 1000
stepSec = grainSec * 0.5
crossfadeSec = grain_crossfade_ms / 1000

if dur < grainSec * 2
    removeObject: workSnd
    exitScript: "Sound is too short. Need at least " + fixed$(grainSec * 2, 2) + " seconds."
endif

writeInfoLine: "=== NEURAL AMBIENT DRONE DESIGNER ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Duration: ", output_duration_sec, " s | Layers: ", layer_density
appendInfoLine: "Grain: ", grain_size_ms, " ms | Clusters: ", number_of_clusters
if add_octave_shimmer
    appendInfoLine: "Shimmer: ", fixed$(shimmer_probability * 100, 0), "% probability"
endif
if stereo_output
    appendInfoLine: "Output: Stereo (width: ", fixed$(stereo_width * 100, 0), "%)"
else
    appendInfoLine: "Output: Mono"
endif
appendInfoLine: "========================================"
appendInfoLine: ""

# ============================================
# FEATURE EXTRACTION (Optimized with arrays)
# ============================================

appendInfoLine: "Analyzing spectral stability..."

nGrains = floor((dur - grainSec) / stepSec)
nFeatures = 4

# Feature arrays: 1=Centroid, 2=Bandwidth, 3=HNR, 4=Pitch
feat_centroid# = zero#(nGrains)
feat_bandwidth# = zero#(nGrains)
feat_hnr# = zero#(nGrains)
feat_pitch# = zero#(nGrains)
grain_time# = zero#(nGrains)

# Create analysis objects once
selectObject: workSnd
spec = To Spectrogram: grainSec, 8000, stepSec, 20, "Gaussian"

selectObject: workSnd
hnr = To Harmonicity (cc): stepSec, 75, 0.1, 1.0

selectObject: workSnd
pit = To Pitch: stepSec, 75, 600

# Extract features
for i from 1 to nGrains
    t = (i - 0.5) * stepSec
    grain_time#[i] = t
    
    # Spectrum slice
    selectObject: spec
    slice = To Spectrum (slice): t
    selectObject: slice
    feat_centroid#[i] = Get centre of gravity: 2
    feat_bandwidth#[i] = Get standard deviation: 2
    removeObject: slice
    
    # HNR
    selectObject: hnr
    h = Get value at time: t, "cubic"
    if h = undefined
        feat_hnr#[i] = -50
    else
        feat_hnr#[i] = h
    endif
    
    # Pitch
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined
        feat_pitch#[i] = 0
    else
        feat_pitch#[i] = f0
    endif
endfor

removeObject: spec, hnr, pit

appendInfoLine: "  Extracted ", nGrains, " grains"

# ============================================
# NORMALIZE FEATURES (Z-Score)
# ============================================

# Centroid
sum = 0
for i to nGrains
    sum += feat_centroid#[i]
endfor
mean_cent = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_centroid#[i] - mean_cent)^2
endfor
std_cent = sqrt(sumSq / nGrains)
if std_cent = 0
    std_cent = 1
endif

# Bandwidth
sum = 0
for i to nGrains
    sum += feat_bandwidth#[i]
endfor
mean_band = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_bandwidth#[i] - mean_band)^2
endfor
std_band = sqrt(sumSq / nGrains)
if std_band = 0
    std_band = 1
endif

# HNR
sum = 0
for i to nGrains
    sum += feat_hnr#[i]
endfor
mean_hnr = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_hnr#[i] - mean_hnr)^2
endfor
std_hnr = sqrt(sumSq / nGrains)
if std_hnr = 0
    std_hnr = 1
endif

# Pitch
sum = 0
for i to nGrains
    sum += feat_pitch#[i]
endfor
mean_pitch = sum / nGrains
sumSq = 0
for i to nGrains
    sumSq += (feat_pitch#[i] - mean_pitch)^2
endfor
std_pitch = sqrt(sumSq / nGrains)
if std_pitch = 0
    std_pitch = 1
endif

# Normalize in-place
norm_cent# = zero#(nGrains)
norm_band# = zero#(nGrains)
norm_hnr# = zero#(nGrains)
norm_pitch# = zero#(nGrains)

for i to nGrains
    norm_cent#[i] = (feat_centroid#[i] - mean_cent) / std_cent
    norm_band#[i] = (feat_bandwidth#[i] - mean_band) / std_band
    norm_hnr#[i] = (feat_hnr#[i] - mean_hnr) / std_hnr
    norm_pitch#[i] = (feat_pitch#[i] - mean_pitch) / std_pitch
endfor

# ============================================
# K-MEANS CLUSTERING (Array-based)
# ============================================

appendInfoLine: "Clustering textures..."

k = number_of_clusters

# Centroid arrays
cent_c# = zero#(k)
cent_b# = zero#(k)
cent_h# = zero#(k)
cent_p# = zero#(k)

# Initialize centroids from random grains
for c from 1 to k
    randRow = randomInteger(1, nGrains)
    cent_c#[c] = norm_cent#[randRow]
    cent_b#[c] = norm_band#[randRow]
    cent_h#[c] = norm_hnr#[randRow]
    cent_p#[c] = norm_pitch#[randRow]
endfor

# Cluster assignments
assigns# = zero#(nGrains)

for iter from 1 to kmeans_iterations
    changes = 0
    
    # E-Step: Assign grains to nearest centroid
    for i from 1 to nGrains
        minDist = 1e9
        bestK = 1
        
        for c from 1 to k
            distSq = (norm_cent#[i] - cent_c#[c])^2 +
                ... (norm_band#[i] - cent_b#[c])^2 +
                ... (norm_hnr#[i] - cent_h#[c])^2 +
                ... (norm_pitch#[i] - cent_p#[c])^2
            
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
    
    # M-Step: Update centroids
    for c from 1 to k
        sum_c = 0
        sum_b = 0
        sum_h = 0
        sum_p = 0
        count = 0
        
        for i from 1 to nGrains
            if assigns#[i] = c
                sum_c += norm_cent#[i]
                sum_b += norm_band#[i]
                sum_h += norm_hnr#[i]
                sum_p += norm_pitch#[i]
                count += 1
            endif
        endfor
        
        if count > 0
            cent_c#[c] = sum_c / count
            cent_b#[c] = sum_b / count
            cent_h#[c] = sum_h / count
            cent_p#[c] = sum_p / count
        endif
    endfor
    
    if changes = 0
        appendInfoLine: "  K-means converged at iteration ", iter
        iter = kmeans_iterations + 1
    endif
endfor

# ============================================
# IDENTIFY "BEST" CLUSTER (Highest HNR = most tonal)
# ============================================

best_cluster = 1
max_hnr_score = -1e9

for c from 1 to k
    if cent_h#[c] > max_hnr_score
        max_hnr_score = cent_h#[c]
        best_cluster = c
    endif
endfor

appendInfoLine: "  Selected Cluster ", best_cluster, " (Most Tonal)"

# Collect indices of tonal grains
tonal_indices# = zero#(nGrains)
tonal_count = 0

for i from 1 to nGrains
    if assigns#[i] = best_cluster
        tonal_count += 1
        tonal_indices#[tonal_count] = i
    endif
endfor

if tonal_count = 0
    removeObject: workSnd
    exitScript: "Failed to find tonal segments. Try increasing number of clusters."
endif

appendInfoLine: "  Found ", tonal_count, " tonal grains"

# ============================================
# BUILD SHIMMER INTERVAL TABLE
# ============================================

if shimmer_intervals = 1
    # Octaves only
    n_intervals = 2
    interval_1 = 0.5    ; octave down
    interval_2 = 2.0    ; octave up
elsif shimmer_intervals = 2
    # Octaves and fifths
    n_intervals = 4
    interval_1 = 0.5    ; octave down
    interval_2 = 0.667  ; fifth down
    interval_3 = 1.5    ; fifth up
    interval_4 = 2.0    ; octave up
else
    # Full harmonic series
    n_intervals = 6
    interval_1 = 0.5    ; octave down
    interval_2 = 0.667  ; fifth down
    interval_3 = 1.25   ; major third up
    interval_4 = 1.5    ; fifth up
    interval_5 = 2.0    ; octave up
    interval_6 = 3.0    ; octave + fifth up
endif

# ============================================
# GENERATIVE DRONE SYNTHESIS
# ============================================

appendInfoLine: ""
appendInfoLine: "Generating drone layers..."

nLayers = layer_density
layer_dur = output_duration_sec

# Store layer sound IDs
layer_ids# = zero#(nLayers)

# Calculate pan positions for stereo
for layer_idx from 1 to nLayers
    if nLayers = 1
        pan_'layer_idx' = 0.5
    else
        pan_'layer_idx' = (layer_idx - 1) / (nLayers - 1)
        # Apply stereo width
        pan_'layer_idx' = 0.5 + (pan_'layer_idx' - 0.5) * stereo_width
    endif
endfor

for layer_idx from 1 to nLayers
    appendInfoLine: "  Layer ", layer_idx, "/", nLayers, "..."
    
    grains_needed = ceiling(layer_dur / (grainSec * 0.5))
    
    # Collect grains for this layer
    grain_sounds# = zero#(grains_needed)
    
    for g from 1 to grains_needed
        # Random selection from tonal grains
        rand_idx = randomInteger(1, tonal_count)
        g_idx = tonal_indices#[rand_idx]
        
        t_center = grain_time#[g_idx]
        t1 = t_center - (grainSec / 2)
        t2 = t_center + (grainSec / 2)
        
        # Clamp to valid range
        if t1 < 0
            t1 = 0
            t2 = grainSec
        endif
        if t2 > dur
            t2 = dur
            t1 = dur - grainSec
        endif
        
        selectObject: workSnd
        Extract part: t1, t2, "Hanning", 1, "no"
        gid = selected("Sound")
        
        # Apply shimmer transposition
        if add_octave_shimmer and randomUniform(0, 1) < shimmer_probability
            sr_orig = Get sampling frequency
            
            # Pick random interval
            int_choice = randomInteger(1, n_intervals)
            ratio = interval_'int_choice'
            
            # Resample to transpose
            new_sr = sr_orig * ratio
            if new_sr > 8000 and new_sr < 96000
                Resample: new_sr, 50
                Override sampling frequency: sr_orig
                tmp = selected("Sound")
                removeObject: gid
                gid = tmp
            endif
        endif
        
        # Apply crossfade envelope
        if crossfadeSec > 0
            selectObject: gid
            grain_dur = Get total duration
            fade = min(crossfadeSec, grain_dur * 0.4)
            Formula: "self * (if x < " + string$(fade) + " then x/" + string$(fade) + 
                ... " else if x > " + string$(grain_dur - fade) + " then (" + string$(grain_dur) + "-x)/" + string$(fade) + 
                ... " else 1 fi fi)"
        endif
        
        grain_sounds#[g] = gid
    endfor
    
    # Concatenate all grains for this layer
    selectObject: grain_sounds#[1]
    for g from 2 to grains_needed
        plusObject: grain_sounds#[g]
    endfor
    Concatenate
    layerSnd = selected("Sound")
    
    # Trim to exact duration
    selectObject: layerSnd
    current_dur = Get total duration
    if current_dur > layer_dur
        Extract part: 0, layer_dur, "rectangular", 1, "no"
        trimmed = selected("Sound")
        removeObject: layerSnd
        layerSnd = trimmed
    endif
    
    selectObject: layerSnd
    Rename: "Layer_" + string$(layer_idx)
    
    # Cleanup grain sounds
    for g from 1 to grains_needed
        removeObject: grain_sounds#[g]
    endfor
    
    layer_ids#[layer_idx] = layerSnd
endfor

# ============================================
# MIX LAYERS (FIXED - Proper mixing with Formula)
# ============================================

appendInfoLine: ""
appendInfoLine: "Mixing layers..."

# Get the shortest duration among layers
min_dur = 1e9
for layer_idx from 1 to nLayers
    selectObject: layer_ids#[layer_idx]
    d = Get total duration
    if d < min_dur
        min_dur = d
    endif
endfor

if stereo_output
    # Create stereo output
    output_left = Create Sound from formula: "Mix_L", 1, 0, min_dur, fs, "0"
    output_right = Create Sound from formula: "Mix_R", 1, 0, min_dur, fs, "0"
    
    # Mix each layer with panning
    for layer_idx from 1 to nLayers
        selectObject: layer_ids#[layer_idx]
        layer_name$ = selected$("Sound")
        
        pan = pan_'layer_idx'
        left_gain = cos(pan * pi / 2)
        right_gain = sin(pan * pi / 2)
        
        selectObject: output_left
        Formula: "self + Sound_'layer_name$'[col] * " + string$(left_gain)
        
        selectObject: output_right
        Formula: "self + Sound_'layer_name$'[col] * " + string$(right_gain)
    endfor
    
    # Combine to stereo
    selectObject: output_left, output_right
    finalOut = Combine to stereo
    Rename: sndName$ + "_NeuralDrone_stereo"
    
    removeObject: output_left, output_right
    
else
    # Mono output - sum all layers
    selectObject: layer_ids#[1]
    finalOut = Copy: "Mix"
    
    for layer_idx from 2 to nLayers
        selectObject: layer_ids#[layer_idx]
        layer_name$ = selected$("Sound")
        
        selectObject: finalOut
        Formula: "self + Sound_'layer_name$'[col]"
    endfor
    
    selectObject: finalOut
    Rename: sndName$ + "_NeuralDrone"
endif

# Normalize output
selectObject: finalOut
Scale peak: 0.99

# Cleanup layers
for layer_idx from 1 to nLayers
    removeObject: layer_ids#[layer_idx]
endfor

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
