# ============================================================
# Praat AudioTools - Band-Based Concatenative Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  Band-Based Concatenative Synthesis
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Band-Based Concatenative Synthesis (v2.5 - Stable)
# Select Source Sound (1) and Target Sound (2) before running
# Fixes: String concatenation syntax in 'Rename' command.

form Band-Based Concatenative Synthesis (Final)
    comment === Presets ===
    choice Preset 1
        button Custom
        button Subtle_Morph
        button Granular_Texture
        button Spectral_Match
        button Rhythmic_Mosaic
        button Smooth_Blend
    comment === Temporal Parameters ===
    positive Window_length_(s) 0.060
    positive Hop_size_(s) 0.030
    comment === Frequency Bands (Hz, comma-separated) ===
    sentence Band_edges 0,500,500,1500,1500,4000,4000,10000
    comment === Matching Parameters ===
    real Continuity_weight_lambda 0.3
    positive Locality_window_(s) 0.4
    comment === Output Leveling ===
    positive Target_intensity_(dB) 70
endform

# === Preset Logic ===
if preset = 2
    # Subtle Morph
    window_length = 0.080
    hop_size = 0.040
    band_edges$ = "0,400,400,1200,1200,3500,3500,10000"
    continuity_weight_lambda = 0.5
    locality_window = 0.6
elsif preset = 3
    # Granular Texture
    window_length = 0.040
    hop_size = 0.020
    band_edges$ = "0,600,600,2000,2000,6000,6000,12000"
    continuity_weight_lambda = 0.15
    locality_window = 0.3
elsif preset = 4
    # Spectral Match
    window_length = 0.050
    hop_size = 0.025
    band_edges$ = "0,300,300,1000,1000,3000,3000,8000"
    continuity_weight_lambda = 0.35
    locality_window = 0.4
elsif preset = 5
    # Rhythmic Mosaic
    window_length = 0.100
    hop_size = 0.050
    band_edges$ = "0,400,400,1200,1200,3500,3500,10000"
    continuity_weight_lambda = 0.7
    locality_window = 0.8
elsif preset = 6
    # Smooth Blend
    window_length = 0.120
    hop_size = 0.060
    band_edges$ = "0,500,500,1500,1500,4500,4500,12000"
    continuity_weight_lambda = 0.6
    locality_window = 1.0
endif

# Determine preset name string for filename
if preset = 1
    preset_name$ = "Custom"
elsif preset = 2
    preset_name$ = "SubtleMorph"
elsif preset = 3
    preset_name$ = "GranularTexture"
elsif preset = 4
    preset_name$ = "SpectralMatch"
elsif preset = 5
    preset_name$ = "RhythmicMosaic"
elsif preset = 6
    preset_name$ = "SmoothBlend"
endif

# [OLA CONSTRAINT]
ratio = window_length / hop_size
int_ratio = round(ratio)
if abs(ratio - int_ratio) > 0.01
    hop_size = window_length / int_ratio
    appendInfoLine: "⚠ Hop size adjusted to ", fixed$(hop_size, 4), " to fit window"
endif
num_streams = int_ratio

# Check selection
numberOfSelected = numberOfSelected("Sound")
if numberOfSelected <> 2
    exitScript: "Please select exactly 2 Sounds (Source and Target)"
endif

sound1 = selected("Sound", 1)
sound2 = selected("Sound", 2)

selectObject: sound1
source_name$ = selected$("Sound")
source = sound1
source_dur = Get total duration
source_sr = Get sampling frequency

selectObject: sound2
target_name$ = selected$("Sound")
target = sound2
target_dur = Get total duration
target_sr = Get sampling frequency

writeInfoLine: "=== Band-Based Concatenative Synthesis (v2.5) ==="
appendInfoLine: "Streams: ", num_streams

# Safety checks
if source_sr <> target_sr
    exitScript: "Sample rates must match. Please resample first."
endif

# Parse bands
band_edges$ = band_edges$ + ","
@countCommas: band_edges$
num_bands = countCommas.result / 2
nyquist = source_sr / 2

for b from 1 to num_bands
    @extractPair: band_edges$, b
    band_low[b] = max(0, extractPair.low)
    band_high[b] = min(extractPair.high, nyquist)
    if band_high[b] - band_low[b] < 50
        band_high[b] = min(band_low[b] + 50, nyquist)
    endif
endfor

# ==============================================================================
# 1. ANALYSIS
# ==============================================================================
appendInfoLine: "Analyzing..."

# --- Analyze Target ---
target_frames = floor((target_dur - window_length) / hop_size) + 1
for b from 1 to num_bands
    selectObject: target
    target_band[b] = Filter (pass Hann band): band_low[b], band_high[b], 100
endfor

for k from 1 to target_frames
    t_start = (k - 1) * hop_size
    t_end = t_start + window_length
    for b from 1 to num_bands
        selectObject: target_band[b]
        rms = Get root-mean-square: t_start, t_end
        target_feature[k, b] = if rms > 0 then log10(rms + 1e-10) else -10 fi
    endfor
endfor

# --- Analyze Source ---
snippet_hop = hop_size / 2
source_snippets = floor((source_dur - window_length) / snippet_hop) + 1

for b from 1 to num_bands
    selectObject: source
    source_band[b] = Filter (pass Hann band): band_low[b], band_high[b], 100
endfor

for j from 1 to source_snippets
    s_start = (j - 1) * snippet_hop
    s_end = s_start + window_length
    for b from 1 to num_bands
        selectObject: source_band[b]
        rms = Get root-mean-square: s_start, s_end
        source_feature[j, b] = if rms > 0 then log10(rms + 1e-10) else -10 fi
    endfor
endfor

# Cleanup Analysis filters
for b from 1 to num_bands
    removeObject: target_band[b], source_band[b]
endfor

# ==============================================================================
# 2. MATCHING
# ==============================================================================
appendInfoLine: "Matching..."

# Z-score normalization
for b from 1 to num_bands
    sum = 0
    for j from 1 to source_snippets
        sum += source_feature[j, b]
    endfor
    band_mean[b] = sum / source_snippets
    
    var_sum = 0
    for j from 1 to source_snippets
        diff = source_feature[j, b] - band_mean[b]
        var_sum += diff * diff
    endfor
    band_std[b] = sqrt(var_sum / source_snippets)
    if band_std[b] < 1e-6
        band_std[b] = 1.0
    endif
endfor

for j from 1 to source_snippets
    for b from 1 to num_bands
        source_feature[j, b] = (source_feature[j, b] - band_mean[b]) / band_std[b]
    endfor
endfor

for k from 1 to target_frames
    for b from 1 to num_bands
        target_feature[k, b] = (target_feature[k, b] - band_mean[b]) / band_std[b]
    endfor
endfor

# Compute Lambda
sample_size = min(150, target_frames * 3)
for s from 1 to sample_size
    k_samp = randomInteger(1, target_frames)
    j_samp = randomInteger(1, source_snippets)
    @computeDistance: k_samp, j_samp, num_bands
    sample_dist[s] = computeDistance.result
endfor
@median: sample_size
lambda = continuity_weight_lambda * median.result

# Search
locality_range = max(1, round(locality_window / snippet_hop))
prev_match = 0

for k from 1 to target_frames
    best_j = 1
    best_cost = 1e10
    
    if k = 1
        j_min = 1
        j_max = source_snippets
    else
        j_min = max(1, prev_match - locality_range)
        j_max = min(source_snippets, prev_match + locality_range)
    endif
    
    for j from j_min to j_max
        @computeDistance: k, j, num_bands
        dist = computeDistance.result
        if k = 1
            cost = dist
        else
            pos_j = (j - 1) * snippet_hop
            pos_prev = (prev_match - 1) * snippet_hop
            time_jump = abs((pos_j - pos_prev) - hop_size)
            cost = dist + lambda * time_jump
        endif
        
        if cost < best_cost
            best_cost = cost
            best_j = j
        endif
    endfor
    match[k] = best_j
    prev_match = best_j
endfor

# ==============================================================================
# 3. SYNTHESIS (Clean Syntax)
# ==============================================================================
appendInfoLine: "Synthesizing..."

# Master Window
Create Sound from formula: "MasterWindow", 1, 0, window_length, source_sr, "0.5 * (1 - cos(2 * pi * x / " + fixed$(window_length, 6) + "))"
win_id = selected("Sound")

# Initialize stream lists
for s from 1 to num_streams
    stream_count[s] = 0
endfor

# Distribute grains
for k from 1 to target_frames
    curr_stream = ((k - 1) mod num_streams) + 1
    j = match[k]
    grain_start = (j - 1) * snippet_hop
    
    selectObject: source
    g_end = min(grain_start + window_length, source_dur)
    
    if g_end > grain_start + (1/source_sr)
        grain = Extract part: grain_start, g_end, "rectangular", 1, "no"
        g_dur = Get total duration
        
        # Padding tolerance check
        padding_dur = window_length - g_dur
        if padding_dur > (2.0 / source_sr)
            g_temp = grain
            Create Sound from formula: "silence", 1, 0, padding_dur, source_sr, "0"
            sil = selected("Sound")
            selectObject: g_temp
            plusObject: sil
            grain = Concatenate
            removeObject: g_temp, sil
        endif
        
        # Window
        selectObject: grain
        Formula: "self * Sound_MasterWindow[]"
        
        # Store
        count = stream_count[curr_stream] + 1
        stream_grains[curr_stream, count] = grain
        stream_count[curr_stream] = count
    endif
endfor

selectObject: win_id
Remove

# Concatenate streams
appendInfoLine: "Merging Streams..."

# Generate a unique ID to prevent name collisions
unique_id = randomInteger(10000, 99999)

for s from 1 to num_streams
    n = stream_count[s]
    if n > 0
        for i from 1 to n
            id[i] = stream_grains[s, i]
        endfor
        selectObject: id[1]
        for i from 2 to n
            plusObject: id[i]
        endfor
        
        stream_sound[s] = Concatenate
        
        # Cleanup grains
        for i from 1 to n
            removeObject: id[i]
        endfor
    else
        # Empty stream handling
        stream_sound[s] = Create Sound from formula: "silence", 1, 0, 0.1, source_sr, "0"
    endif
    
    # RENAME to a safe, space-free name
    selectObject: stream_sound[s]
    s_name$ = "Strm_" + fixed$(unique_id, 0) + "_" + fixed$(s, 0)
    Rename: s_name$
    stream_names$[s] = s_name$
endfor

# Mix Streams
selectObject: stream_sound[1]
final_output = Copy: "Result"
Formula: "0" 

for s from 1 to num_streams
    selectObject: stream_sound[s]
    start_offset = (s - 1) * hop_size
    s_dur = Get total duration
    
    current_name$ = stream_names$[s]
    
    selectObject: final_output
    
    if s > 1
        # Use fixed$ to prevent scientific notation or spaces in numbers
        off_samp$ = fixed$(round(start_offset * source_sr), 0)
        
        # Praat formula: Sound_Name[]
        Formula: "self + Sound_" + current_name$ + "[col - " + off_samp$ + "]"
    else
        # Base stream (no offset calculation needed)
        Formula: "self + Sound_" + current_name$ + "[]"
    endif
    
    removeObject: stream_sound[s]
endfor

selectObject: final_output
Scale peak: 0.99
Scale intensity: target_intensity

# [FIX] Variable assigned explicitly before Rename
final_name$ = "Concat_" + preset_name$
Rename: final_name$

appendInfoLine: "Done!"

# === PROCEDURES ===

procedure countCommas: .text$
    .result = 0
    for .i to length(.text$)
        if mid$(.text$, .i, 1) = ","
            .result += 1
        endif
    endfor
endproc

procedure extractPair: .text$, .pair_index
    .comma_count = 0
    .start_pos = 1
    .target_comma1 = (.pair_index - 1) * 2 + 1
    .target_comma2 = .target_comma1 + 1
    for .i to length(.text$)
        if mid$(.text$, .i, 1) = ","
            .comma_count += 1
            if .comma_count = .target_comma1
                .low_str$ = mid$(.text$, .start_pos, .i - .start_pos)
                .start_pos = .i + 1
            elsif .comma_count = .target_comma2
                .high_str$ = mid$(.text$, .start_pos, .i - .start_pos)
                .start_pos = .i + 1
            endif
        endif
    endfor
    .low = number(.low_str$)
    .high = number(.high_str$)
endproc

procedure computeDistance: .k, .j, .num_bands
    .sum = 0
    for .b to .num_bands
        .diff = target_feature[.k, .b] - source_feature[.j, .b]
        .sum += .diff * .diff
    endfor
    .result = sqrt(.sum)
endproc

procedure median: .n
    for .i to .n - 1
        for .j to .n - .i
            if sample_dist[.j] > sample_dist[.j + 1]
                .temp = sample_dist[.j]
                sample_dist[.j] = sample_dist[.j + 1]
                sample_dist[.j + 1] = .temp
            endif
        endfor
    endfor
    .result = sample_dist[floor(.n / 2) + 1]
endproc
Play