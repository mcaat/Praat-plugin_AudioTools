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

# Neural Phonetic Harmonizer 
# - Fixed "Unknown variable h1" (Scope issue).
# - Fixed "break" variable issue.
# - Optimized for speed.

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

# Hidden parameters
train_chunk = 100
# Stop if cost changes less than this %
early_stop_ratio = 0.001 
early_stop_patience = 5
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
if duration < frame_step_seconds
    exitScript: "Error: Sound duration too short."
endif

# ===== ANALYSIS =====
writeInfoLine: "Analyzing audio features..."

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

# Validate frames
selectObject: mfcc
nFrames = Get number of frames
rows_target = nFrames
n_features = 18

# ===== FEATURE MATRIX =====
Create TableOfReal: "features", rows_target, n_features
feature_matrix = selected("TableOfReal")

# ----- Optimized Feature Extraction -----
# 1. MFCCs
selectObject: mfcc
for i from 1 to rows_target
    for c from 1 to 12
        v = Get value in frame: i, c
        if v = undefined
            v = 0
        endif
        
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

# 3. Intensity, Harmonicity, Pitch
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    
    selectObject: intensity
    it = Get value at time: t, "cubic"
    if it = undefined
        it = 60
    endif
    
    selectObject: harmonicity
    hnr = Get value at time: t, "cubic"
    if hnr = undefined
        hnr = 0
    endif
    
    selectObject: pitch
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        z = 0.5
    else
        z = f0 / 500
        if z > 1
            z = 1
        endif
    endif
    
    selectObject: feature_matrix
    Set value: i, 7, (it - 60) / 20
    Set value: i, 8, hnr / 20
    Set value: i, 9, z
endfor

# ===== TARGET CATEGORIES =====
Create Categories: "output_categories"
output_categories = selected("Categories")

# Pre-calculate categories (Fast loop)
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    
    selectObject: intensity
    int_val = Get value at time: t, "cubic"
    if int_val = undefined
        int_val = -100
    endif
    
    selectObject: harmonicity
    hnr_val = Get value at time: t, "cubic"
    if hnr_val = undefined
        hnr_val = -100
    endif
    
    selectObject: pitch
    f0_val = Get value at time: t, "Hertz", "Linear"
    if f0_val = undefined
        f0_val = 0
    endif
    
    selectObject: formant
    f1_val = Get value at time: 1, t, "Hertz", "Linear"
    if f1_val = undefined
        f1_val = 500
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

# ===== NORMALIZE FEATURES =====
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

# ===== FFNET TRAINING (OPTIMIZED) =====
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
    
    # Fast Early Stopping
    current_cost = Get total costs: "Minimum-squared-error"
    
    # Check convergence
    delta = abs(prev_cost - current_cost)
    if delta < (prev_cost * early_stop_ratio)
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
    
    if total_trained mod 500 == 0
        appendInfoLine: "Iter: ", total_trained, " Cost: ", fixed$(current_cost, 4)
    endif
endwhile

# ===== ACTIVATIONS & MIXING =====
writeInfoLine: "Generating Harmony Voices..."

selectObject: ffnet
plusObject: pattern
To ActivationList: 1
activations = selected("Activation")
To Matrix
activation_matrix = selected("Matrix")

# Create IntensityTiers
Create IntensityTier: "tier_v1", 0, duration
tier1 = selected("IntensityTier")
Create IntensityTier: "tier_v2", 0, duration
tier2 = selected("IntensityTier")
Create IntensityTier: "tier_v3", 0, duration
tier3 = selected("IntensityTier")
Create IntensityTier: "tier_v4", 0, duration
tier4 = selected("IntensityTier")

# Calculate mix
for i from 1 to rows_target
    t = frame_step_seconds * (i - 0.5)
    
    selectObject: activation_matrix
    a1 = Get value in cell: i, 1
    a2 = Get value in cell: i, 2
    a3 = Get value in cell: i, 3
    a4 = Get value in cell: i, 4
    
    # Manual Softmax
    tdiv = temperature
    if tdiv < 0.001
        tdiv = 0.001
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
    
    e1 = exp((a1 - max_a)/tdiv) * enable_vowel
    e2 = exp((a2 - max_a)/tdiv) * enable_fric
    e3 = exp((a3 - max_a)/tdiv) * enable_other
    e4 = exp((a4 - max_a)/tdiv) * enable_silence
    
    sum = e1 + e2 + e3 + e4
    if sum = 0
        sum = 1
    endif
    
    w1 = e1 / sum
    w2 = e2 / sum
    w3 = e3 / sum
    w4 = e4 / sum
    
    # Adaptive Voice Boost
    mix1 = w1 * vowel_mix
    mix2 = w2 * fric_mix
    mix3 = w3 * other_mix
    mix4 = w4 * silence_mix
    
    # Add to tiers (dB conversion handled here: 70dB base)
    db1 = if mix1 > 0.001 then 20*log10(mix1)+70 else 0 fi
    db2 = if mix2 > 0.001 then 20*log10(mix2)+70 else 0 fi
    db3 = if mix3 > 0.001 then 20*log10(mix3)+70 else 0 fi
    db4 = if mix4 > 0.001 then 20*log10(mix4)+70 else 0 fi
    
    selectObject: tier1
    Add point: t, db1
    selectObject: tier2
    Add point: t, db2
    selectObject: tier3
    Add point: t, db3
    selectObject: tier4
    Add point: t, db4
endfor

# ===== SMART PITCH SHIFTING (Global Scope Fix) =====
appendInfoLine: "Pitch shifting voices..."

# Initialize IDs
h1 = 0
h2 = 0
h3 = 0
h4 = 0

for voice_idx from 1 to 4
    # Determine settings based on index
    if voice_idx == 1
        semi = vowel_semitones
        voice_name$ = "vowel_voice"
    elsif voice_idx == 2
        semi = fric_semitones
        voice_name$ = "fric_voice"
    elsif voice_idx == 3
        semi = other_semitones
        voice_name$ = "other_voice"
    else
        semi = silence_semitones
        voice_name$ = "silence_voice"
    endif

    # Create the voice
    if semi == 0
        selectObject: sound
        Copy: voice_name$
        current_id = selected("Sound")
    else
        selectObject: sound
        To Manipulation: 0.01, 75, 600
        manip = selected("Manipulation")
        Create PitchTier: "shift", 0, duration
        ptier = selected("PitchTier")
        Add point: 0, 100
        Add point: duration, 100
        Formula: "self * 2^('semi'/12)"
        
        selectObject: manip
        plusObject: ptier
        Replace pitch tier
        selectObject: manip
        Get resynthesis (overlap-add)
        Rename: voice_name$
        current_id = selected("Sound")
        
        removeObject: manip, ptier
    endif
    
    # Assign back to global variable
    if voice_idx == 1
        h1 = current_id
    elsif voice_idx == 2
        h2 = current_id
    elsif voice_idx == 3
        h3 = current_id
    elsif voice_idx == 4
        h4 = current_id
    endif
endfor

# ===== APPLY ENVELOPES & MIX =====
appendInfoLine: "Mixing..."

selectObject: h1
plusObject: tier1
Multiply
m1 = selected("Sound")
Rename: "m_vowel"

selectObject: h2
plusObject: tier2
Multiply
m2 = selected("Sound")
Rename: "m_fric"

selectObject: h3
plusObject: tier3
Multiply
m3 = selected("Sound")
Rename: "m_other"

selectObject: h4
plusObject: tier4
Multiply
m4 = selected("Sound")
Rename: "m_silence"

selectObject: sound
Copy: "final_mix"
mix_out = selected("Sound")

# Sum the processed voices
Formula: "Sound_m_vowel[] + Sound_m_fric[] + Sound_m_other[] + Sound_m_silence[]"

# Add Dry signal and create output
if create_stereo
    selectObject: sound
    Copy: "Dry_L"
    dry = selected("Sound")
    
    selectObject: dry
    plusObject: mix_out
    Combine to stereo
    final_out = selected("Sound")
    Rename: sound_name$ + "_harmonized_stereo"
    removeObject: dry, mix_out
else
    # Mono Mix
    selectObject: sound
    plusObject: mix_out
    Combine to stereo
    Convert to mono
    final_out = selected("Sound")
    Rename: sound_name$ + "_harmonized_mono"
    removeObject: mix_out
endif

selectObject: final_out
Scale peak: 0.99

# ===== CLEANUP =====
procedure safeRemove .id
    if .id > 0
        selectObject: .id
        Remove
    endif
endproc

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
call safeRemove: tier1
call safeRemove: tier2
call safeRemove: tier3
call safeRemove: tier4
call safeRemove: h1
call safeRemove: h2
call safeRemove: h3
call safeRemove: h4
call safeRemove: m1
call safeRemove: m2
call safeRemove: m3
call safeRemove: m4

if play_result
    selectObject: final_out
    Play
endif

selectObject: final_out