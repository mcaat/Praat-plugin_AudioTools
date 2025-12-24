# ============================================================
# Praat AudioTools - MFCC TRANSFORMER
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 2.0 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Comprehensive MFCC-based sound manipulation toolkit.
#
# Algorithms:
#   1. Direct Control - C1→Pitch, C2→Amplitude, C3→Duration
#   2. Reverse Control - Reverses MFCC timeline
#   3. Complexity Time-Stretch - Adaptive stretching
#   4. Freeze Spectral Moments - Freezes stable regions
#   5. Trajectory Scramble - Local randomization
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit 
#   for Experimental Composition.
# ============================================================

form MFCC Sound Processor
    comment ======== PRESETS (Choose one or use Custom) ========
    optionmenu Preset 1
        option Custom
        option Direct: Subtle
        option Direct: Wide Range
        option Direct: Pitch Focus
        option Reverse: Classic
        option Reverse: Dramatic
        option Complexity: Moderate
        option Complexity: Extreme
        option Freeze: Sparse
        option Freeze: Dense
        option Scramble: Subtle
        option Scramble: Wild

    comment ======== MANUAL SETTINGS (Custom only) ========
    optionmenu Algorithm 1
        option Direct Control
        option Reverse Control
        option Complexity Stretch
        option Freeze Moments
        option Trajectory Scramble
    
    comment Control Ranges (Direct Control only):
    real Pitch_range 0.6
    comment (±range from 1.0, e.g., 0.6 = 0.4 to 1.6)
    real Duration_range 0.3
    comment (±range from 1.0)
    
    comment Other Algorithm Parameters:
    positive Complexity_threshold 0.5
    positive Max_stretch_factor 2.0
    positive Freeze_duration_(s) 0.2
    positive Scramble_window_(frames) 10
    
    comment Output:
    boolean Play_result 1
endform

# ============================================================
# Check Selection
# ============================================================
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
soundName$ = selected$("Sound")
duration = Get total duration
samplingFrequency = Get sampling frequency

# ============================================================
# PRESET LOGIC
# ============================================================
algo = algorithm

# Fixed MFCC parameters (good defaults)
num_coeffs = 12
win_len = 0.015
t_step = 0.005
first_freq = 100
filter_dist = 100
max_freq = 0

# Default algorithm parameters
c1_p_min = 1.0 - pitch_range
c1_p_max = 1.0 + pitch_range
c2_a_min = 0.5
c2_a_max = 1.0
c3_d_min = 1.0 - duration_range
c3_d_max = 1.0 + duration_range
comp_thresh = complexity_threshold
max_stretch = max_stretch_factor
min_stretch = 0.5
freeze_dur = freeze_duration
sim_thresh = 0.3
scramble_win = scramble_window

# Override with presets
if preset$ = "Direct: Subtle"
    algo = 1
    c1_p_min = 0.9
    c1_p_max = 1.1
    c2_a_min = 0.8
    c2_a_max = 1.0
    c3_d_min = 0.95
    c3_d_max = 1.05

elsif preset$ = "Direct: Wide Range"
    algo = 1
    c1_p_min = 0.5
    c1_p_max = 1.5
    c2_a_min = 0.3
    c2_a_max = 1.0
    c3_d_min = 0.7
    c3_d_max = 1.3

elsif preset$ = "Direct: Pitch Focus"
    algo = 1
    c1_p_min = 0.6
    c1_p_max = 1.6
    c2_a_min = 0.9
    c2_a_max = 1.0
    c3_d_min = 0.95
    c3_d_max = 1.05

elsif preset$ = "Reverse: Classic"
    algo = 2

elsif preset$ = "Reverse: Dramatic"
    algo = 2

elsif preset$ = "Complexity: Moderate"
    algo = 3
    comp_thresh = 0.5
    max_stretch = 2.0
    min_stretch = 0.7

elsif preset$ = "Complexity: Extreme"
    algo = 3
    comp_thresh = 0.4
    max_stretch = 4.0
    min_stretch = 0.5

elsif preset$ = "Freeze: Sparse"
    algo = 4
    freeze_dur = 0.15
    sim_thresh = 0.2

elsif preset$ = "Freeze: Dense"
    algo = 4
    freeze_dur = 0.2
    sim_thresh = 0.4

elsif preset$ = "Scramble: Subtle"
    algo = 5
    scramble_win = 5

elsif preset$ = "Scramble: Wild"
    algo = 5
    scramble_win = 30

endif

# ============================================================
# Initialize Info
# ============================================================
algo_name$ = ""
if algo = 1
    algo_name$ = "_DirectControl"
elsif algo = 2
    algo_name$ = "_Reversed"
elsif algo = 3
    algo_name$ = "_ComplexityStretch"
elsif algo = 4
    algo_name$ = "_FrozenMoments"
elsif algo = 5
    algo_name$ = "_Scrambled"
endif

writeInfoLine: "MFCC Sound Processor"
appendInfoLine: "===================="
appendInfoLine: "Processing: ", soundName$
appendInfoLine: ""

# ============================================================
# SHARED MFCC EXTRACTION
# ============================================================
selectObject: sound
To MFCC: num_coeffs, win_len, t_step, first_freq, filter_dist, max_freq
mfcc = selected("MFCC")

selectObject: mfcc
To Matrix
matrix = selected("Matrix")

numFrames = Get number of columns
numCoeffs = Get number of rows

# Extract MFCC data
for i to numFrames
    for j to min(numCoeffs, 12)
        mfcc_data[i, j] = Get value in cell: j, i
    endfor
endfor

# ============================================================
# ALGORITHM IMPLEMENTATION
# ============================================================

# ALGORITHM 1: DIRECT CONTROL
if algo = 1
    # Extract and normalize C1, C2, C3
    for i to numFrames
        c1[i] = mfcc_data[i, 1]
        c2[i] = mfcc_data[i, 2]
        c3[i] = mfcc_data[i, 3]
    endfor
    
    minC1 = c1[1]
    maxC1 = c1[1]
    minC2 = c2[1]
    maxC2 = c2[1]
    minC3 = c3[1]
    maxC3 = c3[1]
    
    for i from 2 to numFrames
        if c1[i] < minC1
            minC1 = c1[i]
        endif
        if c1[i] > maxC1
            maxC1 = c1[i]
        endif
        if c2[i] < minC2
            minC2 = c2[i]
        endif
        if c2[i] > maxC2
            maxC2 = c2[i]
        endif
        if c3[i] < minC3
            minC3 = c3[i]
        endif
        if c3[i] > maxC3
            maxC3 = c3[i]
        endif
    endfor
    
    for i to numFrames
        c1_scaled[i] = (c1[i] - minC1) / (maxC1 - minC1 + 0.0001)
        c2_scaled[i] = (c2[i] - minC2) / (maxC2 - minC2 + 0.0001)
        c3_scaled[i] = (c3[i] - minC3) / (maxC3 - minC3 + 0.0001)
    endfor
    
    selectObject: sound
    To Manipulation: 0.01, 75, 600
    manipulation = selected("Manipulation")
    
    selectObject: manipulation
    Extract pitch tier
    pitchTier = selected("PitchTier")
    
    selectObject: manipulation
    Extract duration tier
    durationTier = selected("DurationTier")
    
    selectObject: pitchTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            pitchFactor = c1_p_min + (c1_scaled[i] * (c1_p_max - c1_p_min))
            Add point: time, 100 * pitchFactor
        endif
    endfor
    
    selectObject: durationTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            durationFactor = c3_d_min + (c3_scaled[i] * (c3_d_max - c3_d_min))
            Add point: time, durationFactor
        endif
    endfor
    
    selectObject: manipulation
    plus pitchTier
    Replace pitch tier
    
    selectObject: manipulation
    plus durationTier
    Replace duration tier
    
    selectObject: manipulation
    Get resynthesis (overlap-add)
    result = selected("Sound")
    
    selectObject: result
    amplitudeRange = c2_a_max - c2_a_min
    Formula: "self * (c2_a_min + c2_scaled[max(1, min(numFrames, round((x / duration) * numFrames)))] * amplitudeRange)"
    
    Rename: soundName$ + algo_name$
    removeObject: manipulation, pitchTier, durationTier

# ALGORITHM 2: REVERSE CONTROL
elsif algo = 2
    for i to numFrames
        reversedIndex = numFrames - i + 1
        for j to 3
            c_reversed[i, j] = mfcc_data[reversedIndex, j]
        endfor
    endfor
    
    for j to 3
        minVal = c_reversed[1, j]
        maxVal = c_reversed[1, j]
        for i from 2 to numFrames
            if c_reversed[i, j] < minVal
                minVal = c_reversed[i, j]
            endif
            if c_reversed[i, j] > maxVal
                maxVal = c_reversed[i, j]
            endif
        endfor
        
        for i to numFrames
            c_scaled[i, j] = (c_reversed[i, j] - minVal) / (maxVal - minVal + 0.0001)
        endfor
    endfor
    
    selectObject: sound
    To Manipulation: 0.01, 75, 600
    manipulation = selected("Manipulation")
    
    selectObject: manipulation
    Extract pitch tier
    pitchTier = selected("PitchTier")
    
    selectObject: manipulation
    Extract duration tier
    durationTier = selected("DurationTier")
    
    selectObject: pitchTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            pitchFactor = 0.7 + (c_scaled[i, 1] * 0.6)
            Add point: time, 100 * pitchFactor
        endif
    endfor
    
    selectObject: durationTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            durationFactor = 0.8 + (c_scaled[i, 3] * 0.4)
            Add point: time, durationFactor
        endif
    endfor
    
    selectObject: manipulation
    plus pitchTier
    Replace pitch tier
    
    selectObject: manipulation
    plus durationTier
    Replace duration tier
    
    selectObject: manipulation
    Get resynthesis (overlap-add)
    result = selected("Sound")
    Rename: soundName$ + algo_name$
    removeObject: manipulation, pitchTier, durationTier

# ALGORITHM 3: COMPLEXITY TIME-STRETCH
elsif algo = 3
    for i to numFrames
        sum = 0
        for j from 2 to min(6, numCoeffs)
            sum += mfcc_data[i, j] * mfcc_data[i, j]
        endfor
        complexity[i] = sqrt(sum)
    endfor
    
    minComp = complexity[1]
    maxComp = complexity[1]
    for i from 2 to numFrames
        if complexity[i] < minComp
            minComp = complexity[i]
        endif
        if complexity[i] > maxComp
            maxComp = complexity[i]
        endif
    endfor
    
    for i to numFrames
        complexity_norm[i] = (complexity[i] - minComp) / (maxComp - minComp + 0.0001)
    endfor
    
    selectObject: sound
    To Manipulation: 0.01, 75, 600
    manipulation = selected("Manipulation")
    
    selectObject: manipulation
    Extract duration tier
    durationTier = selected("DurationTier")
    
    selectObject: durationTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            if complexity_norm[i] > comp_thresh
                stretchFactor = 1 + ((complexity_norm[i] - comp_thresh) / (1 - comp_thresh)) * (max_stretch - 1)
            else
                stretchFactor = min_stretch + (complexity_norm[i] / comp_thresh) * (1 - min_stretch)
            endif
            Add point: time, stretchFactor
        endif
    endfor
    
    selectObject: manipulation
    plus durationTier
    Replace duration tier
    
    selectObject: manipulation
    Get resynthesis (overlap-add)
    result = selected("Sound")
    Rename: soundName$ + algo_name$
    removeObject: manipulation, durationTier

# ALGORITHM 4: FREEZE SPECTRAL MOMENTS
elsif algo = 4
    for i from 2 to numFrames
        distance = 0
        for j to min(6, numCoeffs)
            diff = mfcc_data[i, j] - mfcc_data[i-1, j]
            distance += diff * diff
        endfor
        spectral_distance[i] = sqrt(distance)
    endfor
    
    maxDist = spectral_distance[2]
    for i from 3 to numFrames
        if spectral_distance[i] > maxDist
            maxDist = spectral_distance[i]
        endif
    endfor
    
    for i from 2 to numFrames
        spectral_distance_norm[i] = spectral_distance[i] / (maxDist + 0.0001)
    endfor
    
    numFreezes = 0
    for i from 2 to numFrames - 1
        if spectral_distance_norm[i] < sim_thresh
            freeze_at[numFreezes + 1] = i
            numFreezes += 1
        endif
    endfor
    
    selectObject: sound
    To Manipulation: 0.01, 75, 600
    manipulation = selected("Manipulation")
    
    selectObject: manipulation
    Extract duration tier
    durationTier = selected("DurationTier")
    
    selectObject: durationTier
    for f to numFreezes
        frameIndex = freeze_at[f]
        freezeTime = (frameIndex - 1) * t_step + win_len/2
        
        if freezeTime > 0.01 and freezeTime < duration - 0.01
            Add point: freezeTime - 0.01, 1.0
            Add point: freezeTime, 5.0
            Add point: freezeTime + freeze_dur, 5.0
            Add point: freezeTime + freeze_dur + 0.01, 1.0
        endif
    endfor
    
    selectObject: manipulation
    plus durationTier
    Replace duration tier
    
    selectObject: manipulation
    Get resynthesis (overlap-add)
    result = selected("Sound")
    Rename: soundName$ + algo_name$
    removeObject: manipulation, durationTier
    
    appendInfoLine: "Frozen ", numFreezes, " moments"

# ALGORITHM 5: TRAJECTORY SCRAMBLE
elsif algo = 5
    for i to numFrames
        windowStart = max(1, round(i - scramble_win / 2))
        windowEnd = min(numFrames, round(i + scramble_win / 2))
        
        windowSize = windowEnd - windowStart + 1
        if windowSize > 1
            randomOffset = randomInteger(0, windowSize - 1)
            sourceFrame = windowStart + randomOffset
        else
            sourceFrame = i
        endif
        
        for j to 3
            c_scrambled[i, j] = mfcc_data[sourceFrame, j]
        endfor
    endfor
    
    for j to 3
        minVal = c_scrambled[1, j]
        maxVal = c_scrambled[1, j]
        for i from 2 to numFrames
            if c_scrambled[i, j] < minVal
                minVal = c_scrambled[i, j]
            endif
            if c_scrambled[i, j] > maxVal
                maxVal = c_scrambled[i, j]
            endif
        endfor
        
        for i to numFrames
            c_scaled[i, j] = (c_scrambled[i, j] - minVal) / (maxVal - minVal + 0.0001)
        endfor
    endfor
    
    selectObject: sound
    To Manipulation: 0.01, 75, 600
    manipulation = selected("Manipulation")
    
    selectObject: manipulation
    Extract pitch tier
    pitchTier = selected("PitchTier")
    
    selectObject: manipulation
    Extract duration tier
    durationTier = selected("DurationTier")
    
    selectObject: pitchTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            pitchFactor = 0.7 + (c_scaled[i, 1] * 0.6)
            Add point: time, 100 * pitchFactor
        endif
    endfor
    
    selectObject: durationTier
    for i to numFrames
        time = (i - 1) * t_step + win_len/2
        if time <= duration
            durationFactor = 0.8 + (c_scaled[i, 2] * 0.4)
            Add point: time, durationFactor
        endif
    endfor
    
    selectObject: manipulation
    plus pitchTier
    Replace pitch tier
    
    selectObject: manipulation
    plus durationTier
    Replace duration tier
    
    selectObject: manipulation
    Get resynthesis (overlap-add)
    result = selected("Sound")
    Rename: soundName$ + algo_name$
    removeObject: manipulation, pitchTier, durationTier

endif

# ============================================================
# Cleanup & Finalize
# ============================================================
removeObject: mfcc, matrix

appendInfoLine: "Complete! Output: ", soundName$, algo_name$

selectObject: result

if play_result
    Play
endif