# ============================================================
# Praat AudioTools - Neural Phonetic Harmonizer (FFNet, Adaptive++)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Phonetic Harmonizer with adaptive pitch shifting per phonetic class
#   OPTIMIZED: Uses IntensityTiers instead of per-sample processing
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Neural Phonetic Harmonizer (FFNet, Adaptive++)
    comment Harmony Intervals (semitones):
    real vowel_semitones 7.0
    real fric_semitones -5.0
    real other_semitones 4.0
    real silence_semitones 0.0
    comment Harmony Mix Levels (0-1, higher = stronger):
    positive vowel_mix 1.2
    positive fric_mix 0.9
    positive other_mix 1.0
    positive silence_mix 0.2
    comment Processing:
    positive confidence_threshold 0.20
    positive temperature 0.3
    positive voiced_boost 0.2
    comment Network (defaults work well):
    integer hidden_units 24
    integer training_iterations 3000
    positive learning_rate 0.001
    comment Output:
    boolean create_stereo 1
    boolean play_result 1
endform

# Hidden parameters with good defaults
train_chunk = 100
early_stop_delta = 0.005
early_stop_patience = 3
frame_step_seconds = 0.01
max_formant_hz = 5500
vowel_hnr_threshold = 5.0
fricative_hnr_max = 3.0
silence_intensity_threshold = 45
enable_vowel = 1
enable_fric = 1
enable_other = 1
enable_silence = 1

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

# ===== CREATE INTENSITY TIERS FOR EACH HARMONY VOICE =====
Create IntensityTier: "tier_v1", 0, duration
tier1 = selected("IntensityTier")

Create IntensityTier: "tier_v2", 0, duration
tier2 = selected("IntensityTier")

Create IntensityTier: "tier_v3", 0, duration
tier3 = selected("IntensityTier")

Create IntensityTier: "tier_v4", 0, duration
tier4 = selected("IntensityTier")

class1_frames = 0
class2_frames = 0
class3_frames = 0
class4_frames = 0
total_mixed = 0

# Calculate per-frame mix amounts and build intensity tiers
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

    w1_adapt = w1 * adapt_weight
    
    sum_w = w1_adapt + w2 + w3 + w4
    if sum_w <= 0
        sum_w = 1
    endif
    w1_adapt = w1_adapt / sum_w
    w2 = w2 / sum_w
    w3 = w3 / sum_w
    w4 = w4 / sum_w

    # Calculate mix amounts (convert to dB for IntensityTier)
    mix1 = w1_adapt * vowel_mix
    mix2 = w2 * fric_mix
    mix3 = w3 * other_mix
    mix4 = w4 * silence_mix
    
    # Convert linear mix to dB (IntensityTier uses dB)
    # 0 mix = -80 dB (silent), 1.0 mix = 70 dB (loud)
    if mix1 <= 0.001
        db1 = 0
    else
        db1 = 20 * log10(mix1) + 70
        if db1 < 0
            db1 = 0
        endif
    endif
    
    if mix2 <= 0.001
        db2 = 0
    else
        db2 = 20 * log10(mix2) + 70
        if db2 < 0
            db2 = 0
        endif
    endif
    
    if mix3 <= 0.001
        db3 = 0
    else
        db3 = 20 * log10(mix3) + 70
        if db3 < 0
            db3 = 0
        endif
    endif
    
    if mix4 <= 0.001
        db4 = 0
    else
        db4 = 20 * log10(mix4) + 70
        if db4 < 0
            db4 = 0
        endif
    endif
    
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
        total_mixed = total_mixed + 1
        
        if class_idx = 1
            class1_frames = class1_frames + 1
        elsif class_idx = 2
            class2_frames = class2_frames + 1
        elsif class_idx = 3
            class3_frames = class3_frames + 1
        else
            class4_frames = class4_frames + 1
        endif
    endif
    
    # Add points to intensity tiers
    selectObject: tier1
    Add point: frame_center_time, db1
    selectObject: tier2
    Add point: frame_center_time, db2
    selectObject: tier3
    Add point: frame_center_time, db3
    selectObject: tier4
    Add point: frame_center_time, db4
endfor

clearinfo
writeInfoLine: "=== NEURAL HARMONIZER (EARLY-STOP, ADAPTIVE) ==="
appendInfo: "Frames: ", rows, newline$
appendInfo: "Training chunks: ", chunk_count, "   Epochs trained: ", total_trained, " / ", training_iterations, newline$
appendInfo: "Early stopped: ", early_stopped, "   Delta: ", early_stop_delta, "   Patience: ", early_stop_patience, newline$
appendInfo: "Confidence threshold: ", confidence_threshold, "   Temperature: ", temperature, newline$
appendInfo: "Voiced boost: ", voiced_boost, newline$
appendInfo: "Intervals (semitones): V=", vowel_semitones, " F=", fric_semitones, " O=", other_semitones, " S=", silence_semitones, newline$
appendInfo: "Mix levels: V=", vowel_mix, " F=", fric_mix, " O=", other_mix, " S=", silence_mix, newline$
appendInfo: newline$, "Harmony applied to ", total_mixed, " frames", newline$
appendInfo: "Class 1 (vowel harmony): ", class1_frames, newline$
appendInfo: "Class 2 (fricative harmony): ", class2_frames, newline$
appendInfo: "Class 3 (other harmony): ", class3_frames, newline$
appendInfo: "Class 4 (silence): ", class4_frames, newline$
appendInfo: newline$, "Creating pitch-shifted voices (this may take a moment)...", newline$

# ===== CREATE HARMONY VOICES WITH PITCH SHIFTS =====
selectObject: sound
Copy: "harmony_v1"
h1 = selected("Sound")

selectObject: sound
Copy: "harmony_v2"
h2 = selected("Sound")

selectObject: sound
Copy: "harmony_v3"
h3 = selected("Sound")

selectObject: sound
Copy: "harmony_v4"
h4 = selected("Sound")

# Apply pitch shifts using manipulation
for voice from 1 to 4
    if voice = 1
        semitones = vowel_semitones
        selectObject: h1
    elsif voice = 2
        semitones = fric_semitones
        selectObject: h2
    elsif voice = 3
        semitones = other_semitones
        selectObject: h3
    else
        semitones = silence_semitones
        selectObject: h4
    endif
    
    if semitones <> 0
        To Manipulation: 0.01, 75, 600
        manip = selected("Manipulation")
        
        Create PitchTier: "shift", 0, duration
        ptier = selected("PitchTier")
        Add point: 0, 100
        Add point: duration, 100
        
        Formula: "self * 2^('semitones'/12)"
        
        selectObject: manip
        plusObject: ptier
        Replace pitch tier
        
        selectObject: manip
        Get resynthesis (overlap-add)
        shifted = selected("Sound")
        
        if voice = 1
            removeObject: h1
            h1 = shifted
        elsif voice = 2
            removeObject: h2
            h2 = shifted
        elsif voice = 3
            removeObject: h3
            h3 = shifted
        else
            removeObject: h4
            h4 = shifted
        endif
        
        removeObject: manip, ptier
    endif
endfor

# ===== APPLY INTENSITY TIERS TO HARMONY VOICES =====
appendInfo: "Applying adaptive mixing...", newline$

selectObject: h1
plusObject: tier1
Multiply
scaled1 = selected("Sound")

selectObject: h2
plusObject: tier2
Multiply
scaled2 = selected("Sound")

selectObject: h3
plusObject: tier3
Multiply
scaled3 = selected("Sound")

selectObject: h4
plusObject: tier4
Multiply
scaled4 = selected("Sound")

# ===== MIX ALL VOICES TOGETHER =====
selectObject: sound
Copy: "mix_base"
mix = selected("Sound")

selectObject: mix
plusObject: scaled1
plusObject: scaled2
plusObject: scaled3
plusObject: scaled4
Combine to stereo
temp_stereo = selected("Sound")

selectObject: temp_stereo
Convert to mono
harmonized = selected("Sound")
Rename: sound_name$ + "_harmonized"

removeObject: temp_stereo

selectObject: harmonized
Scale peak: 0.99

# ===== STEREO OUTPUT (OPTIONAL) =====
if create_stereo
    selectObject: sound
    Copy: "orig_for_stereo"
    orig_stereo = selected("Sound")
    
    selectObject: orig_stereo
    plusObject: harmonized
    Combine to stereo
    stereo_out = selected("Sound")
    Rename: sound_name$ + "_harmonized_stereo"
    
    removeObject: orig_stereo, harmonized
    
    appendInfo: "Done! Created stereo output (original L, harmonized R)", newline$
    
    if play_result
        selectObject: stereo_out
        Play
    endif
    
    selectObject: stereo_out
else
    appendInfo: "Done! Created mono harmonized output", newline$
    
    if play_result
        selectObject: harmonized
        Play
    endif
    
    selectObject: harmonized
endif

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
plusObject: tier1
plusObject: tier2
plusObject: tier3
plusObject: tier4
plusObject: h1
plusObject: h2
plusObject: h3
plusObject: h4
plusObject: scaled1
plusObject: scaled2
plusObject: scaled3
plusObject: scaled4
plusObject: mix
Remove