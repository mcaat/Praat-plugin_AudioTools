form Phonetic Tremolo/Glitch Effect
    comment Effect Parameters:
    positive tremolo_rate_hz 8.0
    positive tremolo_depth 0.7
    positive shift_amount_seconds 0.015
    comment Feature Extraction:
    positive frame_step_seconds 0.01
    positive max_formant_hz 5500
    comment Classification Thresholds:
    positive vowel_hnr_threshold 5.0
    positive vowel_f1_min_hz 300
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
To Harmonicity (cc): frame_step_seconds, 75, 0.1, 1.0
harmonicity = selected("Harmonicity")

# ===== APPLY EFFECTS =====
selectObject: sound
Copy: sound_name$ + "_glitched"
output_sound = selected("Sound")

# Calculate number of frames
n_frames = floor(duration / frame_step_seconds)
eps = 0.001

# Debug counters
class1_count = 0
class2_count = 0
class3_count = 0
class4_count = 0

clearinfo
writeInfoLine: "=== PHONETIC EFFECT DEBUG ==="
appendInfo: "Duration: ", duration, " s", newline$
appendInfo: "Total frames: ", n_frames, newline$
appendInfo: "Frame step: ", frame_step_seconds, " s", newline$, newline$

for iframe from 1 to n_frames
    time = frame_step_seconds * iframe
    if time > duration - eps
        time = duration - eps
    endif
    
    # Get acoustic features at this time
    selectObject: intensity
    int_val = Get value at time: time, "Cubic"
    if int_val = undefined or int_val <> int_val
        int_val = 50
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
    
    # Classify based on acoustic features
    t_start = max(0, time - frame_step_seconds/2)
    t_end = min(duration, time + frame_step_seconds/2)
    
    selectObject: output_sound
    
    # Class 1: VOWEL (high HNR, voiced, F1 in vowel range)
    if hnr_val > vowel_hnr_threshold and f0_val > 0 and f1_val > vowel_f1_min_hz
        class1_count = class1_count + 1
        # Tremolo effect
        tremolo_phase = (time * tremolo_rate_hz) mod 1
        trem_amount = 0.3 + 0.7 * sin(2 * pi * tremolo_phase)
        Formula (part): t_start, t_end, 1, 1, "self * 'trem_amount'"
    
    # Class 2: FRICATIVE (low HNR, high intensity, unvoiced)
    elsif int_val > silence_intensity_threshold and hnr_val < fricative_hnr_max and f0_val = 0
        class2_count = class2_count + 1
        # Glitch/shift effect
        Formula (part): t_start, t_end, 1, 1, "self [x + 'shift_amount_seconds'] * 1.5"
    
    # Class 4: SILENCE (low intensity)
    elsif int_val < silence_intensity_threshold
        class4_count = class4_count + 1
        # Heavy attenuation
        Formula (part): t_start, t_end, 1, 1, "self * 0.05"
    
    # Class 3: OTHER (everything else)
    else
        class3_count = class3_count + 1
        # Moderate amplification
        Formula (part): t_start, t_end, 1, 1, "self * 1.3"
    endif
endfor

appendInfo: newline$, "Classification results:", newline$
appendInfo: "Class 1 (vowels - tremolo): ", class1_count, newline$
appendInfo: "Class 2 (fricatives - glitch): ", class2_count, newline$
appendInfo: "Class 3 (other - boost): ", class3_count, newline$
appendInfo: "Class 4 (silence - attenuate): ", class4_count, newline$

# ===== NORMALIZE OUTPUT =====
selectObject: output_sound
Scale peak: 0.99

selectObject: output_sound