form Neural Phonetic Tremolo/Glitch (FFNet)
    comment Effect Parameters:
    positive tremolo_rate_hz 8.0
    positive tremolo_depth 0.95
    positive shift_amount_seconds 0.015
    positive confidence_threshold 0.3
    comment Network:
    integer hidden_units 24
    integer training_iterations 2000
    positive learning_rate 0.001
    comment Feature Extraction:
    positive frame_step_seconds 0.01
    positive max_formant_hz 5500
    comment Classification Thresholds (for labels):
    positive vowel_hnr_threshold 5.0
    positive fricative_hnr_max 3.0
    positive silence_intensity_threshold 45
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

# ===== FEATURE MATRIX =====
n_features = 18
Create Matrix: "features", 0, nFrames_mfcc, nFrames_mfcc, 0.5, 1, 1, n_features, n_features, 1, 1, "0"
feature_matrix = selected("Matrix")

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

    # --- MFCCs ---
    for icoef from 1 to 12
        selectObject: mfcc
        v = Get value in frame: iframe, icoef
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

# ===== TARGET CATEGORIES (using acoustic features for better labels) =====
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
    
    # Get raw acoustic values for classification
    selectObject: intensity
    int_val = Get value at time: time, "Cubic"
    if int_val = undefined or int_val <> int_val
        int_val = 60
    endif
    
    selectObject: harmonicity
    hnr_val = Get value at time: time, "Cubic"
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
    
    # Classify using acoustic thresholds
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
        val = Get value in cell: i, j
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
        val = Get value in cell: i, j
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

# ===== PATTERNLIST =====
selectObject: feature_matrix
To Pattern: 1
pattern = selected("PatternList")

# ===== FFNET BUILD & TRAIN =====
selectObject: pattern, output_categories
# Fix: To FFNet expects integers for hidden layer sizes
# Syntax: To FFNet: hidden1, hidden2 (0 = no second layer)
To FFNet: 'hidden_units', 0
ffnet = selected("FFNet")

selectObject: ffnet, pattern, output_categories
Learn: training_iterations, learning_rate, "Minimum-squared-error"
epochs = training_iterations

# ===== ACTIVATIONS =====
selectObject: ffnet, pattern
To ActivationList: 1
activations = selected("Activation")

selectObject: activations
To Matrix
activation_matrix = selected("Matrix")

# ===== APPLY EFFECTS - PER SAMPLE PROCESSING =====
selectObject: sound
Copy: sound_name$ + "_glitched"
output_sound = selected("Sound")

# Get sample data
selectObject: output_sound
num_samples = Get number of samples
dt = 1 / sampling_rate

# Calculate shift in samples
shift_samples = round(shift_amount_seconds * sampling_rate)
if shift_samples < 1
    shift_samples = 1
endif

# Debug counters
class1_count = 0
class2_count = 0
class3_count = 0
class4_count = 0
total_applied = 0

clearinfo
writeInfoLine: "=== NEURAL NETWORK EFFECT DEBUG ==="
appendInfo: "Total frames: ", rows, newline$
appendInfo: "Training epochs: ", epochs, newline$
appendInfo: "Learning rate: ", learning_rate, newline$
appendInfo: "Confidence threshold: ", confidence_threshold, newline$
appendInfo: "Shift samples: ", shift_samples, newline$, newline$

# Process each frame
for iframe from 1 to rows
    frame_center_time = frame_step_seconds * (iframe - 0.5)
    
    # Read activations
    selectObject: activation_matrix
    c1 = Get value in cell: iframe, 1
    c2 = Get value in cell: iframe, 2
    c3 = Get value in cell: iframe, 3
    c4 = Get value in cell: iframe, 4
    if c1 = undefined or c1 <> c1
        c1 = 0
    endif
    if c2 = undefined or c2 <> c2
        c2 = 0
    endif
    if c3 = undefined or c3 <> c3
        c3 = 0
    endif
    if c4 = undefined or c4 <> c4
        c4 = 0
    endif

    max_conf = c1
    class_idx = 1
    if c2 > max_conf
        max_conf = c2
        class_idx = 2
    endif
    if c3 > max_conf
        max_conf = c3
        class_idx = 3
    endif
    if c4 > max_conf
        max_conf = c4
        class_idx = 4
    endif

    if max_conf >= confidence_threshold
        total_applied = total_applied + 1
        
        # Calculate sample range for this frame
        t_start = max(0, frame_center_time - frame_step_seconds/2)
        t_end = min(duration, frame_center_time + frame_step_seconds/2)
        
        sample_start = max(1, round(t_start * sampling_rate) + 1)
        sample_end = min(num_samples, round(t_end * sampling_rate))
        
        selectObject: output_sound
        
        # Class 1: REAL TREMOLO - per-sample modulation
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

        # Class 2: REAL TIME-SHIFT using sample indices
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

        # Class 3: WAVESHAPING (tanh approximation for soft distortion)
        if class_idx = 3
            class3_count = class3_count + 1
            for isamp from sample_start to sample_end
                old_val = Get value at sample number: 1, isamp
                x = old_val * 4.0
                # Soft clipping tanh approximation
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

        # Class 4: SILENCE (aggressive ducking)
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

# ===== NORMALIZE OUTPUT =====
selectObject: output_sound
Scale peak: 0.99
Play

# ===== CLEANUP (remove intermediates, keep output_sound and original sound) =====
selectObject: pitch
plusObject: intensity
plusObject: formant
plusObject: mfcc
plusObject: harmonicity
plusObject: feature_matrix
plusObject: pattern
plusObject: output_categories
plusObject: ffnet
plusObject: activations
plusObject: activation_matrix
Remove

# Reselect the final output
selectObject: output_sound


