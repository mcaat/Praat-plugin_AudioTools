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
# Band-Based Concatenative Synthesis 
# Select Source Sound (1) and Target Sound (2) before running
# Optimized for speed while maintaining quality

form Band-Based Concatenative Synthesis (Fast)
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
    positive Crossfade_duration_(s) 0.015
    comment === Frequency Bands (Hz, comma-separated) ===
    sentence Band_edges 0,500,500,1500,1500,4000,4000,10000
    comment === Matching Parameters ===
    real Continuity_weight_lambda 0.3
    positive Locality_window_(s) 0.4
    comment === Output Leveling ===
    positive Target_intensity_(dB) 70
endform

# Apply preset if not Custom
if preset = 2
    # Subtle Morph - smooth and natural
    window_length = 0.080
    hop_size = 0.040
    crossfade_duration = 0.020
    band_edges$ = "0,400,400,1200,1200,3500,3500,10000"
    continuity_weight_lambda = 0.5
    locality_window = 0.6
elsif preset = 3
    # Granular Texture - fast grains
    window_length = 0.040
    hop_size = 0.020
    crossfade_duration = 0.010
    band_edges$ = "0,600,600,2000,2000,6000,6000,12000"
    continuity_weight_lambda = 0.15
    locality_window = 0.3
elsif preset = 4
    # Spectral Match - balanced
    window_length = 0.050
    hop_size = 0.025
    crossfade_duration = 0.012
    band_edges$ = "0,300,300,1000,1000,3000,3000,8000"
    continuity_weight_lambda = 0.35
    locality_window = 0.4
elsif preset = 5
    # Rhythmic Mosaic - preserves rhythm
    window_length = 0.100
    hop_size = 0.050
    crossfade_duration = 0.025
    band_edges$ = "0,400,400,1200,1200,3500,3500,10000"
    continuity_weight_lambda = 0.7
    locality_window = 0.8
elsif preset = 6
    # Smooth Blend - very continuous
    window_length = 0.120
    hop_size = 0.060
    crossfade_duration = 0.030
    band_edges$ = "0,500,500,1500,1500,4500,4500,12000"
    continuity_weight_lambda = 0.6
    locality_window = 1.0
endif

# Check selection
numberOfSelected = numberOfSelected("Sound")
if numberOfSelected <> 2
    exitScript: "Please select exactly 2 Sounds (Source and Target)"
endif

# Get selected sounds
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

# Determine preset name
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

writeInfoLine: "=== Band-Based Concatenative Synthesis (Fast) ==="
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Source: ", source_name$, " (", fixed$(source_dur, 3), " s)"
appendInfoLine: "Target: ", target_name$, " (", fixed$(target_dur, 3), " s)"
appendInfoLine: ""

# Safety checks
if source_sr <> target_sr
    exitScript: "Sample rates must match. Please resample first."
endif

if 2 * crossfade_duration > window_length
    crossfade_duration = window_length / 2.5
    appendInfoLine: "⚠ Crossfade adjusted to ", fixed$(crossfade_duration*1000, 0), " ms"
endif

if target_dur < window_length
    exitScript: "Target too short for window length"
endif

# Parse bands
band_edges$ = band_edges$ + ","
@countCommas: band_edges$
num_bands = countCommas.result / 2

if num_bands < 2
    exitScript: "Need at least 2 bands"
endif

# Parse and validate bands
nyquist = source_sr / 2
for b from 1 to num_bands
    @extractPair: band_edges$, b
    band_low[b] = max(0, extractPair.low)
    band_high[b] = min(extractPair.high, nyquist)
    
    if band_high[b] - band_low[b] < 50
        band_high[b] = min(band_low[b] + 50, nyquist)
    endif
endfor

appendInfoLine: "Bands: ", num_bands
appendInfoLine: ""

# === Extract Target Features ===
appendInfoLine: "Analyzing target..."
target_frames = floor((target_dur - window_length) / hop_size) + 1

for b from 1 to num_bands
    selectObject: target
    target_band[b] = Filter (pass Hann band): band_low[b], band_high[b], 100
endfor

for k from 1 to target_frames
    t_start = (k - 1) * hop_size
    for b from 1 to num_bands
        selectObject: target_band[b]
        t_end = min(t_start + window_length, target_dur)
        if t_end > t_start
            temp = Extract part: t_start, t_end, "rectangular", 1.0, "no"
            rms = Get root-mean-square: 0, 0
            Remove
            target_feature[k, b] = if rms > 0 then log10(rms + 1e-10) else -10 fi
        else
            target_feature[k, b] = -10
        endif
    endfor
endfor

# === Build Source Index ===
appendInfoLine: "Indexing source..."
snippet_hop = hop_size / 2
source_snippets = floor((source_dur - window_length) / snippet_hop) + 1

for b from 1 to num_bands
    selectObject: source
    source_band[b] = Filter (pass Hann band): band_low[b], band_high[b], 100
endfor

for j from 1 to source_snippets
    snippet_start[j] = (j - 1) * snippet_hop
    for b from 1 to num_bands
        selectObject: source_band[b]
        s_end = min(snippet_start[j] + window_length, source_dur)
        if s_end > snippet_start[j]
            temp = Extract part: snippet_start[j], s_end, "rectangular", 1.0, "no"
            rms = Get root-mean-square: 0, 0
            Remove
            source_feature[j, b] = if rms > 0 then log10(rms + 1e-10) else -10 fi
        else
            source_feature[j, b] = -10
        endif
    endfor
endfor

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

# Compute lambda
appendInfoLine: "Computing lambda..."
sample_size = min(150, target_frames * 3)
for s from 1 to sample_size
    k_samp = randomInteger(1, target_frames)
    j_samp = randomInteger(1, source_snippets)
    @computeDistance: k_samp, j_samp, num_bands
    sample_dist[s] = computeDistance.result
endfor

@median: sample_size
lambda = continuity_weight_lambda * median.result

locality_range = max(1, round(locality_window / snippet_hop))

# === Matching ===
appendInfoLine: "Matching (", target_frames, " frames)..."
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
            time_jump = abs((snippet_start[j] - snippet_start[prev_match]) - hop_size)
            cost = dist + lambda * time_jump
        endif
        
        if cost < best_cost
            best_cost = cost
            best_j = j
        elsif abs(cost - best_cost) < 1e-6
            if abs(j - prev_match) < abs(best_j - prev_match)
                best_j = j
            endif
        endif
    endfor
    
    match[k] = best_j
    prev_match = best_j
endfor

# === Overlap-Add ===
appendInfoLine: "Building output..."
output_dur = (target_frames - 1) * hop_size + window_length
selectObject: source
output = Create Sound from formula: "Output", 1, 0, output_dur, source_sr, "0"

selectObject: output
output_matrix = Down to Matrix
removeObject: output

for k from 1 to target_frames
    j = match[k]
    grain_start = snippet_start[j]
    output_start = (k - 1) * hop_size
    
    selectObject: source
    grain_end = min(grain_start + window_length, source_dur)
    if grain_end > grain_start
        grain = Extract part: grain_start, grain_end, "rectangular", 1.0, "no"
        
        selectObject: grain
        actual_dur = Get total duration
        fade = crossfade_duration
        Formula: "if x < fade then self * 0.5*(1 - cos(pi*x/fade)) else if x > (actual_dur - fade) then self * 0.5*(1 - cos(pi*(actual_dur - x)/fade)) else self endif endif"
        
        selectObject: grain
        grain_matrix = Down to Matrix
        
        selectObject: grain_matrix
        grain_cols = Get number of columns
        selectObject: output_matrix
        output_cols = Get number of columns
        
        output_start_sample = round(output_start * source_sr) + 1
        
        for samp from 1 to grain_cols
            output_samp = output_start_sample + samp - 1
            if output_samp >= 1 and output_samp <= output_cols
                selectObject: grain_matrix
                grain_val = Get value in cell: 1, samp
                selectObject: output_matrix
                output_val = Get value in cell: 1, output_samp
                Set value: 1, output_samp, output_val + grain_val
            endif
        endfor
        
        removeObject: grain, grain_matrix
    endif
    
    if k mod 100 = 0 or k = target_frames
        appendInfoLine: "  ", k, " / ", target_frames
    endif
endfor

selectObject: output_matrix
output = To Sound (slice): 1
removeObject: output_matrix

# === Finalize ===
appendInfoLine: "Finalizing..."
selectObject: output
Scale peak: 0.99
Scale intensity: target_intensity
Rename: "Concat_'source_name$'_to_'target_name$'_'preset_name$'"

# Cleanup
for b from 1 to num_bands
    removeObject: target_band[b], source_band[b]
endfor

appendInfoLine: "=== DONE ==="
selectObject: output

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