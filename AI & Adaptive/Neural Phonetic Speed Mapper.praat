# ============================================================
# Praat AudioTools - Neural Phonetic Speed Mapper.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Phonetic Speed Mapper (FFNet, Adaptive++) script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Phonetic Speed Mapper (Lite Interface)
# - Clean UI: Only essential controls shown
# - High Speed: Optimized batch processing and early stopping
# - Robust: Fixed variable case sensitivity

form Neural Speed Mapper
    comment Speed Multipliers (1.0 = Normal, >1.0 = Faster, <1.0 = Slower):
    positive speed_vowel 3.2
    positive speed_fric 0.3
    positive speed_other 2.4
    positive speed_silence 1.0

    comment Toggles (Uncheck to keep original speed for that sound):
    boolean enable_vowel 1
    boolean enable_fric 1
    boolean enable_other 1
    boolean enable_silence 1

    comment Output:
    boolean play_result 1
endform

# ==========================================
# ADVANCED PARAMETERS (Hidden from UI)
# You can edit these manually if needed
# ==========================================
confidence_threshold = 0.10
smooth_ms = 20
change_tolerance = 0.03
min_seg_ms = 35
max_gap_ms = 100
contrast_gain = 2.2
temperature = 0.5
voiced_boost = 0.35

# Network Settings
hidden_units = 24
training_iterations = 1000
train_chunk = 100
early_stop_delta = 0.005
early_stop_patience = 3
learning_rate = 0.001

# Analysis Settings
frame_step_seconds = 0.005
max_formant_hz = 5500
vowel_hnr_threshold = 5.0
fricative_hnr_max = 3.0
silence_intensity_threshold = 45
force_every_frames = 2
# ==========================================

# ===== INIT =====
nSelected = numberOfSelected("Sound")
if nSelected <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")

selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency

if duration < frame_step_seconds
    exitScript: "Error: Sound duration too short."
endif

# Preserve original, work on copy
selectObject: sound
Copy: "Analysis_Copy"
sound_work = selected("Sound")

# ===== ANALYSIS (BATCH MODE) =====
writeInfoLine: "Analyzing audio features..."

selectObject: sound_work
To Pitch: 0, 75, 600
pitch = selected("Pitch")

selectObject: sound_work
To Intensity: 75, 0, "yes"
intensity = selected("Intensity")

selectObject: sound_work
To Formant (burg): 0, 5, max_formant_hz, 0.025, 50
formant = selected("Formant")

selectObject: sound_work
To MFCC: 12, 0.025, frame_step_seconds, 100, 100, 0
mfcc = selected("MFCC")

selectObject: sound_work
To Harmonicity (cc): frame_step_seconds, 75, 0.1, 1.0
harmonicity = selected("Harmonicity")

selectObject: mfcc
nFrames = Get number of frames
if nFrames <= 0
    exitScript: "Error: No frames generated."
endif

rows_target = nFrames
n_features = 18

# ===== FEATURE EXTRACTION =====
Create TableOfReal: "features", rows_target, n_features
feature_matrix = selected("TableOfReal")

# Batch: MFCC
selectObject: mfcc
for i from 1 to rows_target
    for c from 1 to 12
        v = Get value in frame: i, c
        if v = undefined
            v = 0
        endif
        # Map cols
        col_idx = 0
        if c <= 3
            col_idx = c
        else
            col_idx = 9 + c - 3
        endif
        selectObject: feature_matrix
        Set value: i, col_idx, v
        selectObject: mfcc
    endfor
endfor

# Batch: Formants
selectObject: formant
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    if f1 = undefined
        f1 = 500
    endif
    if f2 = undefined
        f2 = 1500
    endif
    if f3 = undefined
        f3 = 2500
    endif
    selectObject: feature_matrix
    Set value: i, 4, f1 / 1000
    Set value: i, 5, f2 / 1000
    Set value: i, 6, f3 / 1000
    selectObject: formant
endfor

# Batch: Intensity
selectObject: intensity
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "cubic"
    if v = undefined
        v = 60
    endif
    selectObject: feature_matrix
    Set value: i, 7, (v - 60) / 20
    selectObject: intensity
endfor

# Batch: Harmonicity
selectObject: harmonicity
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "cubic"
    if v = undefined
        v = 0
    endif
    selectObject: feature_matrix
    Set value: i, 8, v / 20
    selectObject: harmonicity
endfor

# Batch: Pitch
selectObject: pitch
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "Hertz", "Linear"
    if v = undefined or v <= 0
        z = 0.5
    else
        z = v / 500
        if z <= 0
            z = 0.5
        endif
    endif
    selectObject: feature_matrix
    Set value: i, 9, z
    selectObject: pitch
endfor

# ===== CATEGORIZATION =====
Create Categories: "output_categories"
output_categories = selected("Categories")

# Temp table for raw data
Create TableOfReal: "RawData", rows_target, 4
raw_data = selected("TableOfReal")

# Fill Temp Table
selectObject: intensity
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "cubic"
    if v = undefined
        v = -100
    endif
    selectObject: raw_data
    Set value: i, 1, v
    selectObject: intensity
endfor

selectObject: harmonicity
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "cubic"
    if v = undefined
        v = -100
    endif
    selectObject: raw_data
    Set value: i, 2, v
    selectObject: harmonicity
endfor

selectObject: pitch
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: t, "Hertz", "Linear"
    if v = undefined
        v = 0
    endif
    selectObject: raw_data
    Set value: i, 3, v
    selectObject: pitch
endfor

selectObject: formant
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    v = Get value at time: 1, t, "Hertz", "Linear"
    if v = undefined
        v = 500
    endif
    selectObject: raw_data
    Set value: i, 4, v
    selectObject: formant
endfor

# Generate Categories Logic
selectObject: raw_data
for i from 1 to rows_target
    int_val = Get value: i, 1
    hnr_val = Get value: i, 2
    f0_val  = Get value: i, 3
    f1_val  = Get value: i, 4
    
    selectObject: output_categories
    if int_val < silence_intensity_threshold
        Append category: "silence"
    elsif hnr_val > vowel_hnr_threshold and f0_val > 0 and f1_val > 300
        Append category: "vowel"
    elsif int_val > silence_intensity_threshold and hnr_val < fricative_hnr_max and f0_val = 0
        Append category: "fricative"
    else
        Append category: "other"
    endif
    selectObject: raw_data
endfor

selectObject: raw_data
Remove

# ===== NORMALIZE =====
selectObject: feature_matrix
cols = n_features
for j from 1 to cols
    col_min = 1e30
    col_max = -1e30
    for i from 1 to rows_target
        val = Get value: i, j
        if val <> undefined
            if val < col_min
                col_min = val
            endif
            if val > col_max
                col_max = val
            endif
        endif
    endfor
    range = col_max - col_min
    if range = 0
        range = 1
    endif
    for i from 1 to rows_target
        val = Get value: i, j
        if val <> undefined
            norm = (val - col_min) / range
            Set value: i, j, norm
        else
            Set value: i, j, 0
        endif
    endfor
endfor

# ===== TRAINING (FAST EARLY STOP) =====
writeInfoLine: "Training Neural Network..."

selectObject: feature_matrix
To Matrix
feature_matrix_m = selected("Matrix")
To Pattern: 1
pattern = selected("PatternList")

selectObject: pattern
plusObject: output_categories
To FFNet: hidden_units, 0
ffnet = selected("FFNet")

total_trained = 0
stale_chunks = 0
prev_cost = 1e9
early_stopped = 0

while total_trained < training_iterations
    selectObject: ffnet
    plusObject: pattern
    plusObject: output_categories
    Learn: train_chunk, learning_rate, "Minimum-squared-error"
    
    current_cost = Get total costs: "Minimum-squared-error"
    
    delta = abs(prev_cost - current_cost)
    if delta < early_stop_delta
        stale_chunks = stale_chunks + 1
    else
        stale_chunks = 0
    endif
    
    prev_cost = current_cost
    total_trained = total_trained + train_chunk
    
    if stale_chunks >= early_stop_patience
        early_stopped = 1
        total_trained = training_iterations
    endif
    
    if total_trained mod 200 == 0
        appendInfoLine: "Iter: ", total_trained, " Cost: ", fixed$(current_cost, 4)
    endif
endwhile

# ===== INFERENCE =====
selectObject: ffnet
plusObject: pattern
To ActivationList: 1
activations = selected("Activation")
To Matrix
activation_matrix = selected("Matrix")

# ===== MAPPING SPEED =====
selectObject: sound_work
Copy: sound_name$ + "_neural_speed"
output_sound = selected("Sound")

durationTier = Create DurationTier: "ffnet_dur", 0, duration
selectObject: durationTier

Create TableOfReal: "frameFactor", rows_target, 1
frameFactor = selected("TableOfReal")

for iframe from 1 to rows_target
    selectObject: activation_matrix
    a1 = Get value in cell: iframe, 1
    a2 = Get value in cell: iframe, 2
    a3 = Get value in cell: iframe, 3
    a4 = Get value in cell: iframe, 4
    
    # Enable/Disable Masks
    if enable_vowel = 0
        a1 = -100
    endif
    if enable_fric = 0
        a2 = -100
    endif
    if enable_other = 0
        a3 = -100
    endif
    if enable_silence = 0
        a4 = -100
    endif

    # Softmax
    tdiv = temperature
    if tdiv <= 0.0001
        tdiv = 0.0001
    endif
    
    max_a = a1
    if a2 > max_a
        max_a = a2
    endif
    if a3 > max_a
        max_a = a3
    endif
    if a4 > max_a
        max_a = a4
    endif
    
    e1 = exp((a1-max_a) / tdiv)
    e2 = exp((a2-max_a) / tdiv)
    e3 = exp((a3-max_a) / tdiv)
    e4 = exp((a4-max_a) / tdiv)
    denom = e1 + e2 + e3 + e4
    if denom <= 0
        denom = 1e-12
    endif
    w1 = e1 / denom
    w2 = e2 / denom
    w3 = e3 / denom
    w4 = e4 / denom

    # Calculate Speed
    s1 = speed_vowel
    s2 = speed_fric
    s3 = speed_other
    s4 = speed_silence
    
    # Revert disabled to neutral speed
    if enable_vowel = 0
        s1 = 1.0
    endif
    if enable_fric = 0
        s2 = 1.0
    endif
    if enable_other = 0
        s3 = 1.0
    endif
    if enable_silence = 0
        s4 = 1.0
    endif

    weighted = w1*s1 + w2*s2 + w3*s3 + w4*s4

    # Adaptive Boost
    selectObject: feature_matrix
    norm_hnr = Get value: iframe, 8
    norm_f0 = Get value: iframe, 9
    
    voicedness = (norm_hnr * 0.5) + (norm_f0 * 0.5) 
    adapt_weight = 1 + voiced_boost * (voicedness - 0.5) * 2
    
    weighted = 1 + adapt_weight * (weighted - 1)
    
    max_prob = w1
    if w2 > max_prob
        max_prob = w2
    endif
    if w3 > max_prob
        max_prob = w3
    endif
    if w4 > max_prob
        max_prob = w4
    endif
    
    mix = (max_prob - confidence_threshold) / (1 - confidence_threshold)
    if mix < 0
        mix = 0
    endif
    if mix > 1
        mix = 1
    endif

    factor = 1 + contrast_gain * mix * (weighted - 1)
    
    selectObject: frameFactor
    Set value: iframe, 1, factor
endfor

# ===== SMOOTHING & DURATION TIER =====
Create TableOfReal: "frameFactorSm", rows_target, 1
frameFactorSm = selected("TableOfReal")

win = round(smooth_ms / (1000 * frame_step_seconds))
if win < 1
    win = 1
endif

for i from 1 to rows_target
    i1 = i - win
    if i1 < 1
        i1 = 1
    endif
    i2 = i + win
    if i2 > rows_target
        i2 = rows_target
    endif
    
    sumv = 0
    countv = 0
    for k from i1 to i2
        selectObject: frameFactor
        v = Get value: k, 1
        sumv = sumv + v
        countv = countv + 1
    endfor
    sm = sumv / countv
    selectObject: frameFactorSm
    Set value: i, 1, sm
endfor

# Write to DurationTier
min_seg = min_seg_ms / 1000
max_gap = max_gap_ms / 1000
segments_written = 0

selectObject: frameFactorSm
v0 = Get value: 1, 1
if v0 = undefined
    v0 = 1.0
endif

last_written_factor = v0
last_write_t = 0
cum_change = 0
last_forced_i = 1

selectObject: durationTier
Add point: 0, v0

for i from 2 to rows_target
    frame_center = frame_step_seconds * (i - 0.5)
    t = frame_center

    selectObject: frameFactorSm
    v = Get value: i, 1
    
    dv = abs(v - last_written_factor)
    cum_change = cum_change + dv
    time_since = t - last_write_t
    
    do_force = 0
    if (i - last_forced_i) >= force_every_frames and time_since >= min_seg
        do_force = 1
    endif

    if ( (cum_change >= change_tolerance and time_since >= min_seg) or (time_since >= max_gap) or (do_force = 1) )
        selectObject: durationTier
        Add point: t, v
        last_written_factor = v
        last_write_t = t
        last_forced_i = i
        cum_change = 0
        segments_written = segments_written + 1
    endif
endfor

selectObject: durationTier
Add point: duration, last_written_factor

# ===== RESYNTHESIS =====
selectObject: output_sound
To Manipulation: 0.01, 75, 600
manip = selected("Manipulation")

selectObject: manip
plusObject: durationTier
Replace duration tier

selectObject: manip
Get resynthesis (overlap-add)
resynth = selected("Sound")
Rename: sound_name$ + "_neural_speed_mapped"
Scale peak: 0.99

# ===== CLEANUP & REPORT =====
appendInfoLine: "Processing Complete."
appendInfoLine: "Modified segments: ", segments_written

procedure safeRemove .id
    if .id > 0
        selectObject: .id
        Remove
    endif
endproc

call safeRemove: sound_work
call safeRemove: pitch
call safeRemove: intensity
call safeRemove: formant
call safeRemove: mfcc
call safeRemove: harmonicity
call safeRemove: feature_matrix
call safeRemove: feature_matrix_m
call safeRemove: pattern
call safeRemove: output_categories
call safeRemove: ffnet
call safeRemove: activations
call safeRemove: activation_matrix
call safeRemove: frameFactor
call safeRemove: frameFactorSm
call safeRemove: durationTier
call safeRemove: manip
call safeRemove: output_sound

if play_result
    selectObject: resynth
    Play
endif
