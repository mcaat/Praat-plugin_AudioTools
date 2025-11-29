# ============================================================
# Praat AudioTools - Neural Phonetic Tremolo-Glitch (FFNet, Adaptive++)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Phonetic Tremolo-Glitch with early stopping and adaptive voicing
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Phonetic Tremolo-Glitch (Fast & Robust)
# - Fixed "No such object" error by explicit renaming of mix tracks.
# - Optimized Glitch formula to be name-independent.

form Neural Tremolo-Glitch
    comment Effect Parameters:
    positive tremolo_rate_hz 8.0
    positive tremolo_depth 0.95
    positive shift_amount_seconds 0.015
    
    comment Mixing:
    positive confidence_threshold 0.3
    positive temperature 0.5
    positive voiced_boost 0.35

    comment Toggles:
    boolean enable_vowel 1
    boolean enable_fric 1
    boolean enable_other 1
    boolean enable_silence 1
    
    boolean play_result 1
endform

# Hidden technical parameters
hidden_units = 24
training_iterations = 2000
train_chunk = 100
early_stop_delta = 0.005
early_stop_patience = 3
learning_rate = 0.001
frame_step_seconds = 0.01
max_formant_hz = 5500
vowel_hnr_threshold = 5.0
fricative_hnr_max = 3.0
silence_intensity_threshold = 45

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

# Preserve original
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
rows_target = nFrames
n_features = 18

# ===== FEATURE MATRIX =====
Create TableOfReal: "features", rows_target, n_features
feature_matrix = selected("TableOfReal")

# 1. MFCC
selectObject: mfcc
for i from 1 to rows_target
    for c from 1 to 12
        v = Get value in frame: i, c
        if v = undefined
            v = 0
        endif
        col_idx = if c <= 3 then c else 9 + c - 3 fi
        selectObject: feature_matrix
        Set value: i, col_idx, v
        selectObject: mfcc
    endfor
endfor

# 2. Formants
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

# 3. Intensity
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

# 4. Harmonicity
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

# 5. Pitch
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

# ===== TRAINING =====
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

# ===== CREATE MASKS (INTENSITY TIERS) =====
Create IntensityTier: "Mask_Tremolo", 0, duration
mask_trem = selected("IntensityTier")
Create IntensityTier: "Mask_Glitch", 0, duration
mask_glitch = selected("IntensityTier")
Create IntensityTier: "Mask_Distort", 0, duration
mask_distort = selected("IntensityTier")
Create IntensityTier: "Mask_Silence", 0, duration
mask_silence = selected("IntensityTier")

writeInfoLine: "Generating Neural Masks..."

for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    
    selectObject: activation_matrix
    a1 = Get value in cell: i, 1
    a2 = Get value in cell: i, 2
    a3 = Get value in cell: i, 3
    a4 = Get value in cell: i, 4
    
    # Enable/Disable logic
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

    # Adaptive boost
    selectObject: feature_matrix
    norm_hnr = Get value: i, 8
    norm_f0 = Get value: i, 9
    voicedness = (norm_hnr * 0.5) + (norm_f0 * 0.5) 
    adapt_weight = 1 + voiced_boost * (voicedness - 0.5) * 2
    
    # Apply boost to Vowel (Tremolo)
    w1_adapt = w1 * adapt_weight
    
    # Renormalize
    sum_w = w1_adapt + w2 + w3 + w4
    if sum_w <= 0
        sum_w = 1
    endif
    
    w1 = w1_adapt / sum_w
    w2 = w2 / sum_w
    w3 = w3 / sum_w
    w4 = w4 / sum_w
    
    # Determine winner 
    max_w = w1
    if w2 > max_w
        max_w = w2
    endif
    if w3 > max_w
        max_w = w3
    endif
    if w4 > max_w
        max_w = w4
    endif
    
    gain1 = 0
    gain2 = 0
    gain3 = 0
    gain4 = 0
    
    if max_w >= confidence_threshold
        if w1 = max_w
            gain1 = 1
        elsif w2 = max_w
            gain2 = 1
        elsif w3 = max_w
            gain3 = 1
        elsif w4 = max_w
            gain4 = 1
        endif
    endif

    # Convert to dB for IntensityTier
    db_off = -100
    db_on = 0
    
    val1 = if gain1 then db_on else db_off fi
    val2 = if gain2 then db_on else db_off fi
    val3 = if gain3 then db_on else db_off fi
    val4 = if gain4 then db_on else db_off fi
    
    selectObject: mask_trem
    Add point: t, val1
    selectObject: mask_glitch
    Add point: t, val2
    selectObject: mask_distort
    Add point: t, val3
    selectObject: mask_silence
    Add point: t, val4
endfor

# ===== PARALLEL DSP PROCESSING =====
# We generate the full effect tracks using Formulas (Very Fast)

selectObject: sound_work
# 1. Tremolo Track
Copy: "Tremolo_Track"
s_trem = selected("Sound")
Formula: "self * (1 - 'tremolo_depth' + 'tremolo_depth' * 0.5 * (1 + sin(2*pi*'tremolo_rate_hz'*x)))"

# 2. Glitch Track
# We need to reference "Analysis_Copy" specifically to avoid name ambiguity
selectObject: sound_work
Copy: "Glitch_Track"
s_glitch = selected("Sound")
shift_s = shift_amount_seconds
Formula: "Sound_Analysis_Copy(x + shift_s) * 2.5"

# 3. Distort Track
selectObject: sound_work
Copy: "Distort_Track"
s_dist = selected("Sound")
Formula: "self * 4.0"
# Sigmoid soft clipping
Formula: "if self > 3 then 1 else if self < -3 then -1 else self * (27 + self^2) / (27 + 9*self^2) fi fi * 0.9"

# 4. Silence Track
selectObject: sound_work
Copy: "Silence_Track"
s_silence = selected("Sound")
Formula: "self * 0.01"

# ===== APPLY MASKS & RENAME =====
# We rename explicitly to predictable names for the mix formula

selectObject: s_trem
plusObject: mask_trem
Multiply
s_trem_masked = selected("Sound")
Rename: "Mix_Trem"

selectObject: s_glitch
plusObject: mask_glitch
Multiply
s_glitch_masked = selected("Sound")
Rename: "Mix_Glitch"

selectObject: s_dist
plusObject: mask_distort
Multiply
s_dist_masked = selected("Sound")
Rename: "Mix_Dist"

selectObject: s_silence
plusObject: mask_silence
Multiply
s_silence_masked = selected("Sound")
Rename: "Mix_Sil"

# ===== MIX =====
selectObject: sound_work
Copy: "Final_Mix"
final_out = selected("Sound")
Formula: "Sound_Mix_Trem[] + Sound_Mix_Glitch[] + Sound_Mix_Dist[] + Sound_Mix_Sil[]"

Rename: sound_name$ + "_neural_glitch"
Scale peak: 0.99

# ===== CLEANUP =====
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
call safeRemove: mask_trem
call safeRemove: mask_glitch
call safeRemove: mask_distort
call safeRemove: mask_silence
call safeRemove: s_trem
call safeRemove: s_glitch
call safeRemove: s_dist
call safeRemove: s_silence
call safeRemove: s_trem_masked
call safeRemove: s_glitch_masked
call safeRemove: s_dist_masked
call safeRemove: s_silence_masked

if play_result
    selectObject: final_out
    Play
endif
