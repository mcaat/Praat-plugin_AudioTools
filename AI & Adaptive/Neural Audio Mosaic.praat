# ============================================================
# Praat AudioTools - Neural Audio Mosaic
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025) - Optimized + Stereo
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Audio Mosaic
#   Reconstructs 'Target' using 'Source' grains via feature matching.
#   Optimizations:
#   - Proper overlap-add synthesis with Hanning windows
#   - Joint feature normalization
#   - Balanced feature weighting
#   - Native arrays
#   - Exhaustive/stochastic search modes
#   - Stereo output
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Audio Mosaic 
# - Reconstructs 'Target' using 'Source' grains.

form Neural Audio Mosaic
    comment Select 2 Sounds: #1 = Target (Structure), #2 = Source (Texture)
    
    comment === Preset ===
    optionmenu Preset 1
        option Manual (Use Settings Below)
        option Tight Match
        option Creative Loose
        option Rhythmic
        option Spectral Only
        option Pitch Priority
        option Hybrid Texture
    
    comment === Grain Parameters ===
    positive Grain_size_ms 50
    real Overlap_ratio 0.5
    
    comment === Search Parameters ===
    optionmenu Search_mode 1
        option Stochastic (fast)
        option Exhaustive (accurate)
    integer Search_probes 50
    comment (Only used for stochastic mode)
    
    comment === Feature Weights ===
    positive Pitch_weight 1.0
    positive Spectral_weight 1.0
    positive Energy_weight 0.5
    
    comment === Output ===
    boolean Stereo_output 1
    real Stereo_variation 0.3
    boolean Normalize_volume 1
    boolean Play_result 1
endform

# ============================================
# PRESET LOGIC
# ============================================

if preset$ = "Tight Match"
    grain_size_ms = 40
    overlap_ratio = 0.5
    search_mode = 2
    pitch_weight = 1.2
    spectral_weight = 1.5
    energy_weight = 0.8
    stereo_variation = 0.15

elsif preset$ = "Creative Loose"
    grain_size_ms = 80
    overlap_ratio = 0.6
    search_mode = 1
    search_probes = 20
    pitch_weight = 0.3
    spectral_weight = 0.5
    energy_weight = 0.2
    stereo_variation = 0.5

elsif preset$ = "Rhythmic"
    grain_size_ms = 30
    overlap_ratio = 0.25
    search_mode = 1
    search_probes = 80
    pitch_weight = 0.5
    spectral_weight = 1.0
    energy_weight = 1.5
    stereo_variation = 0.25

elsif preset$ = "Spectral Only"
    grain_size_ms = 60
    overlap_ratio = 0.5
    search_mode = 2
    pitch_weight = 0.0
    spectral_weight = 2.0
    energy_weight = 0.3
    stereo_variation = 0.3

elsif preset$ = "Pitch Priority"
    grain_size_ms = 50
    overlap_ratio = 0.5
    search_mode = 2
    pitch_weight = 3.0
    spectral_weight = 0.5
    energy_weight = 0.5
    stereo_variation = 0.2

elsif preset$ = "Hybrid Texture"
    grain_size_ms = 70
    overlap_ratio = 0.65
    search_mode = 1
    search_probes = 40
    pitch_weight = 1.0
    spectral_weight = 1.0
    energy_weight = 1.0
    stereo_variation = 0.4
endif

# ============================================
# SETUP & VALIDATION
# ============================================

nSelected = numberOfSelected("Sound")
if nSelected <> 2
    exitScript: "Please select exactly TWO Sound objects. (1=Target, 2=Source)"
endif

id1 = selected("Sound", 1)
id2 = selected("Sound", 2)

selectObject: id1
targetName$ = selected$("Sound")
durTarget = Get total duration
fsTarget = Get sampling frequency

selectObject: id2
sourceName$ = selected$("Sound")
durSource = Get total duration
fsSource = Get sampling frequency

if fsTarget <> fsSource
    exitScript: "Error: Both sounds must have the same sampling frequency."
endif

fs = fsTarget
grainSec = grain_size_ms / 1000
stepSec = grainSec * (1 - overlap_ratio)

if stepSec < 0.001
    stepSec = 0.001
endif

if durTarget < grainSec or durSource < grainSec
    exitScript: "Sounds are too short for this grain size."
endif

writeInfoLine: "=== NEURAL AUDIO MOSAIC ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Target: ", targetName$, " (", fixed$(durTarget, 2), " s)"
appendInfoLine: "Source: ", sourceName$, " (", fixed$(durSource, 2), " s)"
appendInfoLine: "Grain: ", grain_size_ms, " ms | Overlap: ", fixed$(overlap_ratio * 100, 0), "%"
if search_mode = 1
    appendInfoLine: "Search: Stochastic (", search_probes, " probes)"
else
    appendInfoLine: "Search: Exhaustive"
endif
if stereo_output
    appendInfoLine: "Output: Stereo (variation: ", fixed$(stereo_variation * 100, 0), "%)"
else
    appendInfoLine: "Output: Mono"
endif
appendInfoLine: "================================"
appendInfoLine: ""

# Make mono working copies
selectObject: id1
targetSnd = Convert to mono
Rename: "Work_Target"

selectObject: id2
sourceSnd = Convert to mono
Rename: "Work_Source"

# ============================================
# FEATURE EXTRACTION (Native Arrays)
# ============================================

appendInfoLine: "Extracting features..."

# Calculate frame counts
nTarget = floor((durTarget - grainSec) / stepSec)
nSource = floor((durSource - grainSec) / stepSec)

if nTarget < 1
    nTarget = 1
endif
if nSource < 1
    nSource = 1
endif

appendInfoLine: "  Target frames: ", nTarget
appendInfoLine: "  Source frames: ", nSource

# Feature dimensions: 12 MFCCs + 1 pitch + 1 energy = 14
nFeatures = 14

# Allocate arrays for target features
for f from 1 to nFeatures
    tFeat_'f'# = zero#(nTarget)
endfor
tTime# = zero#(nTarget)

# Allocate arrays for source features
for f from 1 to nFeatures
    sFeat_'f'# = zero#(nSource)
endfor
sTime# = zero#(nSource)

# Extract TARGET features
selectObject: targetSnd
tMfcc = To MFCC: 12, 0.025, stepSec, 100, 100, 0

selectObject: targetSnd
tPitch = To Pitch: stepSec, 75, 600

selectObject: targetSnd
tIntensity = To Intensity: 75, stepSec, "yes"

for i from 1 to nTarget
    t = (i - 0.5) * stepSec
    tTime#[i] = t
    
    # MFCCs
    selectObject: tMfcc
    for c from 1 to 12
        val = Get value in frame: i, c
        if val = undefined
            val = 0
        endif
        tFeat_'c'#[i] = val
    endfor
    
    # Pitch (log scale)
    selectObject: tPitch
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        logF0 = 0
    else
        logF0 = 12 * ln(f0 / 100) / ln(2)
    endif
    tFeat_13#[i] = logF0
    
    # Energy
    selectObject: tIntensity
    energy = Get value at time: t, "cubic"
    if energy = undefined
        energy = 50
    endif
    tFeat_14#[i] = energy
endfor

removeObject: tMfcc, tPitch, tIntensity

# Extract SOURCE features
selectObject: sourceSnd
sMfcc = To MFCC: 12, 0.025, stepSec, 100, 100, 0

selectObject: sourceSnd
sPitch = To Pitch: stepSec, 75, 600

selectObject: sourceSnd
sIntensity = To Intensity: 75, stepSec, "yes"

for i from 1 to nSource
    t = (i - 0.5) * stepSec
    sTime#[i] = t
    
    # MFCCs
    selectObject: sMfcc
    for c from 1 to 12
        val = Get value in frame: i, c
        if val = undefined
            val = 0
        endif
        sFeat_'c'#[i] = val
    endfor
    
    # Pitch (log scale)
    selectObject: sPitch
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        logF0 = 0
    else
        logF0 = 12 * ln(f0 / 100) / ln(2)
    endif
    sFeat_13#[i] = logF0
    
    # Energy
    selectObject: sIntensity
    energy = Get value at time: t, "cubic"
    if energy = undefined
        energy = 50
    endif
    sFeat_14#[i] = energy
endfor

removeObject: sMfcc, sPitch, sIntensity

appendInfoLine: "  Features extracted"

# ============================================
# JOINT FEATURE NORMALIZATION
# ============================================

appendInfoLine: "Normalizing features (joint)..."

# For each feature, compute stats across BOTH target and source
for f from 1 to nFeatures
    # Find min/max across both
    minV = 1e9
    maxV = -1e9
    
    for i from 1 to nTarget
        v = tFeat_'f'#[i]
        if v < minV
            minV = v
        endif
        if v > maxV
            maxV = v
        endif
    endfor
    
    for i from 1 to nSource
        v = sFeat_'f'#[i]
        if v < minV
            minV = v
        endif
        if v > maxV
            maxV = v
        endif
    endfor
    
    range = maxV - minV
    if range < 1e-9
        range = 1
    endif
    
    # Normalize both using same stats
    for i from 1 to nTarget
        tFeat_'f'#[i] = (tFeat_'f'#[i] - minV) / range
    endfor
    
    for i from 1 to nSource
        sFeat_'f'#[i] = (sFeat_'f'#[i] - minV) / range
    endfor
endfor

appendInfoLine: "  Normalization complete"

# ============================================
# BUILD FEATURE WEIGHT ARRAY
# ============================================

# Normalize weights so they sum to nFeatures (balanced contribution)
totalWeight = spectral_weight * 12 + pitch_weight + energy_weight
if totalWeight < 0.001
    totalWeight = 1
endif

# Per-dimension weights
for c from 1 to 12
    w_'c' = spectral_weight * nFeatures / totalWeight
endfor
w_13 = pitch_weight * nFeatures / totalWeight
w_14 = energy_weight * nFeatures / totalWeight

# ============================================
# NEURAL SEARCH (Matching)
# ============================================

appendInfoLine: "Running neural search..."

# Output: best source index for each target frame
matchIdx# = zero#(nTarget)

# For stereo: second match with slight variation
if stereo_output
    matchIdx_R# = zero#(nTarget)
endif

for i from 1 to nTarget
    best_dist = 1e9
    best_idx = 1
    
    # For stereo right channel
    second_best_dist = 1e9
    second_best_idx = 1
    
    if search_mode = 2
        # Exhaustive search
        for j from 1 to nSource
            dist = 0
            for f from 1 to nFeatures
                d = tFeat_'f'#[i] - sFeat_'f'#[j]
                dist += d * d * w_'f'
            endfor
            
            if dist < best_dist
                second_best_dist = best_dist
                second_best_idx = best_idx
                best_dist = dist
                best_idx = j
            elsif dist < second_best_dist
                second_best_dist = dist
                second_best_idx = j
            endif
        endfor
    else
        # Stochastic search
        for probe from 1 to search_probes
            j = randomInteger(1, nSource)
            
            dist = 0
            for f from 1 to nFeatures
                d = tFeat_'f'#[i] - sFeat_'f'#[j]
                dist += d * d * w_'f'
            endfor
            
            if dist < best_dist
                second_best_dist = best_dist
                second_best_idx = best_idx
                best_dist = dist
                best_idx = j
            elsif dist < second_best_dist
                second_best_dist = dist
                second_best_idx = j
            endif
        endfor
    endif
    
    matchIdx#[i] = best_idx
    
    # For stereo: use second best or add variation
    if stereo_output
        if randomUniform(0, 1) < stereo_variation
            matchIdx_R#[i] = second_best_idx
        else
            matchIdx_R#[i] = best_idx
        endif
    endif
    
    if i mod 100 = 0
        perc = i / nTarget * 100
        appendInfoLine: "  Matching: ", fixed$(perc, 0), "%"
    endif
endfor

appendInfoLine: "  Search complete"

# ============================================
# OVERLAP-ADD SYNTHESIS
# ============================================

appendInfoLine: "Synthesizing mosaic (overlap-add)..."

outputDur = nTarget * stepSec + grainSec

if stereo_output
    n_passes = 2
else
    n_passes = 1
endif

for pass from 1 to n_passes
    if stereo_output
        if pass = 1
            appendInfoLine: "  LEFT channel..."
        else
            appendInfoLine: "  RIGHT channel..."
        endif
    endif
    
    # Create output buffer
    outputSnd = Create Sound from formula: "Output_" + string$(pass), 1, 0, outputDur, fs, "0"
    
    # Overlap-add each grain
    for i from 1 to nTarget
        # Get source index for this pass
        if pass = 1
            srcIdx = matchIdx#[i]
        else
            srcIdx = matchIdx_R#[i]
        endif
        
        # Source grain time
        t_src = sTime#[srcIdx]
        t1 = t_src - (grainSec / 2)
        t2 = t_src + (grainSec / 2)
        
        # Clamp to valid range
        if t1 < 0
            t1 = 0
            t2 = grainSec
        endif
        if t2 > durSource
            t2 = durSource
            t1 = durSource - grainSec
            if t1 < 0
                t1 = 0
            endif
        endif
        
        # Extract grain with Hanning window
        selectObject: sourceSnd
        grain = Extract part: t1, t2, "Hanning", 1, "no"
        
        # Destination time
        destTime = (i - 1) * stepSec
        
        # Add to output buffer
        selectObject: grain
        grainName$ = selected$("Sound")
        grainDur = Get total duration
        
        selectObject: outputSnd
        Formula (part): destTime, destTime + grainDur, 1, 1,
            ... "self + Sound_'grainName$'(x - " + string$(destTime) + ")"
        
        removeObject: grain
    endfor
    
    # Compensate for overlap-add gain
    selectObject: outputSnd
    if overlap_ratio > 0
        # OLA gain compensation (approximate)
        gain_comp = 1 / (1 + overlap_ratio)
        Formula: "self * " + string$(gain_comp)
    endif
    
    # Store channel
    if pass = 1
        channel_left = outputSnd
        selectObject: channel_left
        Rename: "Channel_Left"
    else
        channel_right = outputSnd
        selectObject: channel_right
        Rename: "Channel_Right"
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
    
    if dur_L < dur_R
        selectObject: channel_right
        tmp = Extract part: 0, dur_L, "rectangular", 1, "no"
        removeObject: channel_right
        channel_right = tmp
    elsif dur_R < dur_L
        selectObject: channel_left
        tmp = Extract part: 0, dur_R, "rectangular", 1, "no"
        removeObject: channel_left
        channel_left = tmp
    endif
    
    selectObject: channel_left, channel_right
    finalOut = Combine to stereo
    Rename: targetName$ + "_Mosaic_stereo"
    
    removeObject: channel_left, channel_right
else
    finalOut = channel_left
    Rename: targetName$ + "_Mosaic"
endif

if normalize_volume
    selectObject: finalOut
    Scale peak: 0.99
endif

# ============================================
# CLEANUP
# ============================================

removeObject: targetSnd, sourceSnd

selectObject: id1
plusObject: id2
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