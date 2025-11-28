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

form Neural Phonetic Tremolo-Glitch (FFNet, Adaptive++)
    comment Effect Parameters:
    positive tremolo_rate_hz 8.0
    positive tremolo_depth 0.95
    positive shift_amount_seconds 0.015
    positive confidence_threshold 0.3
    positive temperature 0.5
    
    comment Effect Enable/Disable:
    boolean enable_vowel 1
    boolean enable_fric 1
    boolean enable_other 1
    boolean enable_silence 1
    
    comment Adaptive Voicing:
    positive voiced_boost 0.35
    
    comment Network:
    integer hidden_units 24
    integer training_iterations 2000
    integer train_chunk 100
    positive early_stop_delta 0.005
    integer early_stop_patience 3
    positive learning_rate 0.001
    
    comment Feature Extraction:
    positive frame_step_seconds 0.01
    positive max_formant_hz 5500
    
    comment Classification Thresholds:
    positive vowel_hnr_threshold 5.0
    positive fricative_hnr_max 3.0
    positive silence_intensity_threshold 45
    
    boolean play_result 0
endform

# ===== INIT =====
sound = selected("Sound")
sound_name$ = selected$("Sound")
if sound = 0
    exitScript: "Error: No sound selected."
endif

selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency
if duration <= 0
    exitScript: "Error: Sound has zero/negative duration."
endif
if duration < frame_step_seconds
    exitScript: "Error: Sound duration too short."
endif

# ===== ANALYSIS =====
selectObject: sound
To Pitch: 0, 75, 600
pitch = selected("Pitch")

selectObject: sound
To Intensity: 75, 0, "yes"
intensity = selected("Intensity")

selectObject: sound
To Formant (burg): 0, 5, max_formant_hz, 0.025, 50
formant = selected("Formant")

selectObject: sound
To MFCC: 12, 0.025, frame_step_seconds, 100, 100, 0
mfcc = selected("MFCC")

selectObject: sound
To Harmonicity (cc): frame_step_seconds, 75, 0.1, 1.0
harmonicity = selected("Harmonicity")

# ----- frame counts -----
selectObject: mfcc
nFrames_mfcc = Get number of frames
if nFrames_mfcc <= 0
    exitScript: "Error: No frames in MFCC."
endif

selectObject: intensity
nFrames_int = Get number of frames
if nFrames_int <= 0
    nFrames_int = 1
endif

selectObject: harmonicity
nFrames_hnr = Get number of frames
if nFrames_hnr <= 0
    nFrames_hnr = 1
endif

selectObject: pitch
nFrames_f0 = Get number of frames
if nFrames_f0 <= 0
    nFrames_f0 = 1
endif

rows_target = round(duration / frame_step_seconds)
if rows_target < 1
    rows_target = 1
endif
n_features = 18

# ===== FEATURE MATRIX =====
Create TableOfReal: "features", rows_target, n_features
feature_matrix = selected("TableOfReal")

selectObject: feature_matrix
rows = Get number of rows
cols = Get number of columns
eps = frame_step_seconds * 0.25
if eps <= 0
    eps = 0.001
endif

# ----- feature extraction -----
for iframe from 1 to rows
    raw_time = frame_step_seconds * (iframe - 0.5)
    if raw_time < 0
        time = 0
    elsif raw_time > duration - eps
        time = duration - eps
    else
        time = raw_time
    endif

    # clamp indices
    iI = iframe
    if iI > nFrames_int
        iI = nFrames_int
    endif
    if iI < 1
        iI = 1
    endif

    iH = iframe
    if iH > nFrames_hnr
        iH = nFrames_hnr
    endif
    if iH < 1
        iH = 1
    endif

    iP = iframe
    if iP > nFrames_f0
        iP = nFrames_f0
    endif
    if iP < 1
        iP = 1
    endif

    iM = iframe
    if iM > nFrames_mfcc
        iM = nFrames_mfcc
    endif
    if iM < 1
        iM = 1
    endif

    # --- MFCCs ---
    for icoef from 1 to 12
        selectObject: mfcc
        v = Get value in frame: iM, icoef
        if v = undefined or v <> v
            v = 0
        endif
        selectObject: feature_matrix
        if icoef <= 3
            Set value: iframe, icoef, v
        else
            Set value: iframe, 9 + icoef - 3, v
        endif
    endfor

    # --- Formants ---
    selectObject: formant
    f1 = Get value at time: 1, time, "Hertz", "Linear"
    f2 = Get value at time: 2, time, "Hertz", "Linear"
    f3 = Get value at time: 3, time, "Hertz", "Linear"
    if f1 = undefined or f1 <> f1
        f1 = 500
    endif
    if f2 = undefined or f2 <> f2
        f2 = 1500
    endif
    if f3 = undefined or f3 <> f3
        f3 = 2500
    endif
    selectObject: feature_matrix
    Set value: iframe, 4, f1 / 1000
    Set value: iframe, 5, f2 / 1000
    Set value: iframe, 6, f3 / 1000

    # --- Intensity ---
    selectObject: intensity
    it = Get value in frame: iI
    if it = undefined or it <> it
        it = 60
    endif
    selectObject: feature_matrix
    Set value: iframe, 7, (it - 60) / 20

    # --- Harmonicity ---
    selectObject: harmonicity
    hnr = Get value in frame: iH
    if hnr = undefined or hnr <> hnr
        hnr = 0
    endif
    selectObject: feature_matrix
    Set value: iframe, 8, hnr / 20

    # --- Pitch ---
    selectObject: pitch
    f0 = Get value in frame: iP, "Hertz"
    if f0 = undefined or f0 <> f0 or f0 <= 0
        z = 0.5
    else
        z = f0 / 500
        if z <= 0
            z = 0.5
        endif
    endif
    selectObject: feature_matrix
    Set value: iframe, 9, z
endfor

# ===== TARGET CATEGORIES =====
Create Categories: "output_categories"
output_categories = selected("Categories")
for iframe from 1 to rows
    raw_time = frame_step_seconds * (iframe - 0.5)
    if raw_time < 0
        time = 0
    elsif raw_time > duration - eps
        time = duration - eps
    else
        time = raw_time
    endif
    
    selectObject: intensity
    int_val = Get value at time: time, "cubic"
    if int_val = undefined or int_val <> int_val
        int_val = 60
    endif
    
    selectObject: harmonicity
    hnr_val = Get value at time: time, "cubic"
    if hnr_val = undefined or hnr_val <> hnr_val
        hnr_val = 0
    endif
    
    selectObject: formant
    f1_val = Get value at time: 1, time, "Hertz", "Linear"
    if f1_val = undefined or f1_val <> f1_val
        f1_val = 500
    endif
    
    selectObject: pitch
    f0_val = Get value at time: time, "Hertz", "Linear"
    if f0_val = undefined or f0_val <> f0_val
        f0_val = 0
    endif
    
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
endfor

selectObject: output_categories
n_categories = Get number of categories
if n_categories <> rows
    exitScript: "Error: Categories size mismatch."
endif

# ===== NORMALIZE FEATURES =====
selectObject: feature_matrix
for j from 1 to cols
    col_min = 1e30
    col_max = -1e30
    for i from 1 to rows
        val = Get value: i, j
        if val = undefined or val <> val
            val = 0
        endif
        if val < col_min
            col_min = val
        endif
        if val > col_max
            col_max = val
        endif
    endfor
    range = col_max - col_min
    if range = undefined or range <> range or range = 0
        range = 1
    endif
    for i from 1 to rows
        val = Get value: i, j
        if val = undefined or val <> val
            val = 0
        endif
        norm = (val - col_min) / range
        if norm = undefined or norm <> norm
            norm = 0
        endif
        Set value: i, j, norm
    endfor
endfor

# ===== CONVERT TO PATTERN =====
selectObject: feature_matrix
To Matrix
feature_matrix_m = selected("Matrix")

selectObject: feature_matrix_m
To Pattern: 1
pattern = selected("PatternList")

# ===== FFNET BUILD & TRAIN WITH EARLY STOPPING =====
selectObject: pattern, output_categories
To FFNet: 'hidden_units', 0
ffnet = selected("FFNet")

total_trained = 0
stale_chunks = 0
prevActID = 0
chunk_count = 0
early_stopped = 0

while total_trained < training_iterations
    remaining = training_iterations - total_trained
    this_chunk = train_chunk
    if this_chunk > remaining
        this_chunk = remaining
    endif

    selectObject: ffnet, pattern, output_categories
    Learn: this_chunk, learning_rate, "Minimum-squared-error"
    total_trained = total_trained + this_chunk
    chunk_count = chunk_count + 1

    selectObject: ffnet, pattern
    To ActivationList: 1
    activ_tmp = selected("Activation")
    selectObject: activ_tmp
    To Matrix
    actID = selected("Matrix")
    selectObject: activ_tmp
    Remove

    if prevActID = 0
        prevActID = actID
    else
        selectObject: prevActID
        nR_prev = Get number of rows
        nC_prev = Get number of columns

        selectObject: actID
        nR_cur = Get number of rows
        nC_cur = Get number of columns

        nR = nR_prev
        if nR_cur < nR
            nR = nR_cur
        endif
        nC = nC_prev
        if nC_cur < nC
            nC = nC_cur
        endif
        if nR < 1
            nR = 1
        endif
        if nC < 1
            nC = 1
        endif

        maxSample = 100
        stepR = 1
        if nR > maxSample
            stepR = round(nR / maxSample)
            if stepR < 1
                stepR = 1
            endif
        endif

        sumdiff = 0
        countd = 0
        r = 1
        while r <= nR
            for c from 1 to nC
                selectObject: prevActID
                v1 = Get value in cell: r, c
                if v1 = undefined or v1 <> v1
                    v1 = 0
                endif
                selectObject: actID
                v2 = Get value in cell: r, c
                if v2 = undefined or v2 <> v2
                    v2 = 0
                endif
                d = v1 - v2
                if d < 0
                    d = -d
                endif
                sumdiff = sumdiff + d
                countd = countd + 1
            endfor
            r = r + stepR
        endwhile

        if countd = 0
            meanDiff = 0
        else
            meanDiff = sumdiff / countd
        endif

        selectObject: prevActID
        Remove
        prevActID = actID

        if meanDiff < early_stop_delta
            stale_chunks = stale_chunks + 1
        else
            stale_chunks = 0
        endif
        if stale_chunks >= early_stop_patience
            early_stopped = 1
            total_trained = training_iterations
        endif
    endif
endwhile

if prevActID <> 0
    selectObject: prevActID
    Remove
endif

# ===== FINAL ACTIVATIONS =====
selectObject: ffnet, pattern
To ActivationList: 1
activations = selected("Activation")

selectObject: activations
To Matrix
activation_matrix = selected("Matrix")

# ===== APPLY EFFECTS WITH ADAPTIVE WEIGHTING =====
selectObject: sound
Copy: sound_name$ + "_glitched_adaptive"
output_sound = selected("Sound")

num_samples = Get number of samples
dt = 1 / sampling_rate

shift_samples = round(shift_amount_seconds * sampling_rate)
if shift_samples < 1
    shift_samples = 1
endif

class1_count = 0
class2_count = 0
class3_count = 0
class4_count = 0
total_applied = 0

clearinfo
writeInfoLine: "=== NEURAL TREMOLO-GLITCH (EARLY-STOP, ADAPTIVE) ==="
appendInfo: "Frames: ", rows, newline$
appendInfo: "Training chunks: ", chunk_count, "   Epochs trained: ", total_trained, " / ", training_iterations, newline$
appendInfo: "Early stopped: ", early_stopped, "   Delta: ", early_stop_delta, "   Patience: ", early_stop_patience, newline$
appendInfo: "Confidence threshold: ", confidence_threshold, "   Temperature: ", temperature, newline$
appendInfo: "Voiced boost: ", voiced_boost, newline$
appendInfo: "Shift samples: ", shift_samples, newline$, newline$

for iframe from 1 to rows
    frame_center_time = frame_step_seconds * (iframe - 0.5)
    
    selectObject: activation_matrix
    a1 = Get value in cell: iframe, 1
    a2 = Get value in cell: iframe, 2
    a3 = Get value in cell: iframe, 3
    a4 = Get value in cell: iframe, 4
    if a1 = undefined or a1 <> a1
        a1 = 0
    endif
    if a2 = undefined or a2 <> a2
        a2 = 0
    endif
    if a3 = undefined or a3 <> a3
        a3 = 0
    endif
    if a4 = undefined or a4 <> a4
        a4 = 0
    endif

    if enable_vowel = 0
        a1 = 0
    endif
    if enable_fric = 0
        a2 = 0
    endif
    if enable_other = 0
        a3 = 0
    endif
    if enable_silence = 0
        a4 = 0
    endif

    # Temperature-scaled softmax
    tdiv = temperature
    if tdiv <= 0.0001
        tdiv = 0.0001
    endif
    e1 = exp(a1 / tdiv)
    e2 = exp(a2 / tdiv)
    e3 = exp(a3 / tdiv)
    e4 = exp(a4 / tdiv)
    denom = e1 + e2 + e3 + e4
    if denom <= 0
        denom = 1e-12
    endif
    w1 = e1 / denom
    w2 = e2 / denom
    w3 = e3 / denom
    w4 = e4 / denom

    # Adaptive voicing boost
    selectObject: harmonicity
    h = Get value in frame: iframe
    if h = undefined or h <> h
        h = 0
    endif
    vh = (h - 0) / 15
    if vh < 0
        vh = 0
    endif
    if vh > 1
        vh = 1
    endif

    selectObject: pitch
    f0c = Get value in frame: iframe, "Hertz"
    vflag = 0
    if f0c > 0
        vflag = 1
    endif
    voicedness = (0.5*vh + 0.5*vflag)
    adapt_weight = 1 + voiced_boost * (voicedness - 0.5) * 2

    # Boost vowel weight for voiced frames
    w1_adapt = w1 * adapt_weight
    
    # Renormalize
    sum_w = w1_adapt + w2 + w3 + w4
    if sum_w <= 0
        sum_w = 1
    endif
    w1_adapt = w1_adapt / sum_w
    w2 = w2 / sum_w
    w3 = w3 / sum_w
    w4 = w4 / sum_w

    # Find dominant class
    max_w = w1_adapt
    class_idx = 1
    if w2 > max_w
        max_w = w2
        class_idx = 2
    endif
    if w3 > max_w
        max_w = w3
        class_idx = 3
    endif
    if w4 > max_w
        max_w = w4
        class_idx = 4
    endif

    if max_w >= confidence_threshold
        total_applied = total_applied + 1
        
        t_start = max(0, frame_center_time - frame_step_seconds/2)
        t_end = min(duration, frame_center_time + frame_step_seconds/2)
        
        sample_start = max(1, round(t_start * sampling_rate) + 1)
        sample_end = min(num_samples, round(t_end * sampling_rate))
        
        selectObject: output_sound
        
        if class_idx = 1
            class1_count = class1_count + 1
            for isamp from sample_start to sample_end
                t_samp = (isamp - 1) / sampling_rate
                lfo = 0.5 * (1 + sin(2 * pi * tremolo_rate_hz * t_samp))
                trem_gain = 1 - tremolo_depth + tremolo_depth * lfo
                old_val = Get value at sample number: 1, isamp
                Set value at sample number: 1, isamp, old_val * trem_gain
            endfor
        endif

        if class_idx = 2
            class2_count = class2_count + 1
            for isamp from sample_start to sample_end
                src_samp = isamp + shift_samples
                if src_samp > num_samples
                    src_samp = num_samples
                endif
                if src_samp < 1
                    src_samp = 1
                endif
                shifted_val = Get value at sample number: 1, src_samp
                Set value at sample number: 1, isamp, shifted_val * 2.5
            endfor
        endif

        if class_idx = 3
            class3_count = class3_count + 1
            for isamp from sample_start to sample_end
                old_val = Get value at sample number: 1, isamp
                x = old_val * 4.0
                if x > 3
                    shaped = 1
                elsif x < -3
                    shaped = -1
                else
                    shaped = x * (27 + x*x) / (27 + 9*x*x)
                endif
                Set value at sample number: 1, isamp, shaped * 0.9
            endfor
        endif

        if class_idx = 4
            class4_count = class4_count + 1
            for isamp from sample_start to sample_end
                old_val = Get value at sample number: 1, isamp
                Set value at sample number: 1, isamp, old_val * 0.01
            endfor
        endif
    endif
endfor

appendInfo: newline$, "Effects applied to ", total_applied, " frames", newline$
appendInfo: "Class 1 (vowel tremolo): ", class1_count, newline$
appendInfo: "Class 2 (fricative glitch): ", class2_count, newline$
appendInfo: "Class 3 (waveshaping): ", class3_count, newline$
appendInfo: "Class 4 (silence): ", class4_count, newline$

selectObject: output_sound
Scale peak: 0.99
Rename: sound_name$ + "_glitched_adaptive_es"

# ===== CLEANUP =====
selectObject: pitch
plusObject: intensity
plusObject: formant
plusObject: mfcc
plusObject: harmonicity
plusObject: feature_matrix
plusObject: feature_matrix_m
plusObject: pattern
plusObject: output_categories
plusObject: ffnet
plusObject: activations
plusObject: activation_matrix
Remove

if play_result
    selectObject: output_sound
    Play
endif

selectObject: output_sound