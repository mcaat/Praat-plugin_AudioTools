# ============================================================
# Praat AudioTools - Phonetic Tremolo/Glitch Effect.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Phonetic Tremolo/Glitch Effect
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Phonetic Tremolo/Glitch Effect
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Subtle Vocal Texture
        option Hard Robot Glitch
        option Broken Radio (High Speed)
        option Fricative Smear (Long Shift)
        option Stutter Vowels
        option Clean Gated (Silence Removal)
    
    comment --- Effect Parameters ---
    positive Tremolo_rate_hz 8.0
    positive Tremolo_depth 0.7
    positive Shift_amount_seconds 0.015
    
    comment --- Feature Extraction ---
    positive Frame_step_seconds 0.01
    positive Max_formant_hz 5500
    
    comment --- Classification Thresholds ---
    positive Vowel_hnr_threshold 5.0
    positive Vowel_f1_min_hz 300
    positive Fricative_hnr_max 3.0
    positive Silence_intensity_threshold 45
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check for selection
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# PRESET LOGIC
# ============================================================

if preset = 2
    # Subtle Vocal Texture
    tremolo_rate_hz = 4.0
    tremolo_depth = 0.3
    shift_amount_seconds = 0.005
    silence_intensity_threshold = 40
    
elsif preset = 3
    # Hard Robot Glitch
    tremolo_rate_hz = 12.0
    tremolo_depth = 0.9
    shift_amount_seconds = 0.03
    silence_intensity_threshold = 50
    
elsif preset = 4
    # Broken Radio
    tremolo_rate_hz = 25.0
    tremolo_depth = 0.8
    shift_amount_seconds = 0.01
    silence_intensity_threshold = 45
    
elsif preset = 5
    # Fricative Smear
    tremolo_rate_hz = 6.0
    tremolo_depth = 0.2
    shift_amount_seconds = 0.08
    fricative_hnr_max = 5.0
    
elsif preset = 6
    # Stutter Vowels
    tremolo_rate_hz = 15.0
    tremolo_depth = 1.0
    shift_amount_seconds = 0.0
    
elsif preset = 7
    # Clean Gated
    # Heavy silence attenuation, minimal effects
    tremolo_rate_hz = 0.0
    tremolo_depth = 0.0
    shift_amount_seconds = 0.0
    silence_intensity_threshold = 60
endif

# ============================================================
# ANALYSIS PHASE
# ============================================================

selectObject: original_sound_id
duration = Get total duration
sampling_rate = Get sampling frequency

# 1. Pitch Analysis
To Pitch: 0, 75, 600
pitch_id = selected("Pitch")

# 2. Intensity Analysis
selectObject: original_sound_id
To Intensity: 75, 0, "yes"
intensity_id = selected("Intensity")

# 3. Formant Analysis
selectObject: original_sound_id
To Formant (burg): 0, 5, max_formant_hz, 0.025, 50
formant_id = selected("Formant")

# 4. Harmonicity (HNR) Analysis
selectObject: original_sound_id
To Harmonicity (cc): 0.01, 75, 0.1, 1.0
hnr_id = selected("Harmonicity")

# Prepare Output Object
selectObject: original_sound_id
Copy: original_name$ + "_glitch"
output_id = selected("Sound")

# ============================================================
# PROCESSING LOOP
# ============================================================
# We loop through frames to classify phonetic content

t = 0
frames = duration / frame_step_seconds

for i from 1 to frames
    t_start = (i - 1) * frame_step_seconds
    t_end = i * frame_step_seconds
    t_mid = t_start + frame_step_seconds / 2
    
    # Get features at current time
    selectObject: pitch_id
    f0_val = Get value at time: t_mid, "Hertz", "Linear"
    if f0_val = undefined
        f0_val = 0
    endif
    
    selectObject: intensity_id
    int_val = Get value at time: t_mid, "cubic"
    
    selectObject: formant_id
    f1_val = Get value at time: 1, t_mid, "Hertz", "Linear"
    if f1_val = undefined
        f1_val = 0
    endif
    
    selectObject: hnr_id
    hnr_val = Get value at time: t_mid, "cubic"
    if hnr_val = undefined
        hnr_val = -100
    endif

    # Apply Logic to Output Sound
    selectObject: output_id
    
    # --- CLASS 1: VOWEL (Voiced, High HNR) ---
    if int_val > silence_intensity_threshold and hnr_val > vowel_hnr_threshold and f0_val > 0 and f1_val > vowel_f1_min_hz
        # Apply Tremolo
        # Math: 1.0 +/- Depth * Sin(Rate)
        # Using specific 'Formula (part)' to target just this time slice
        trem_phase = (t_mid * tremolo_rate_hz) * 2 * pi
        factor = 1.0 - tremolo_depth * (0.5 * (1.0 + sin(trem_phase)))
        Formula (part): t_start, t_end, 1, 1, "self * factor"
        
    # --- CLASS 2: FRICATIVE (Unvoiced, Low HNR) ---
    elsif int_val > silence_intensity_threshold and hnr_val < fricative_hnr_max and f0_val = 0
        # Apply Glitch / Time Shift
        # We grab audio from 'shift_amount' seconds in the future
        Formula (part): t_start, t_end, 1, 1, "self[x + shift_amount_seconds] * 1.5"
        
    # --- CLASS 3: SILENCE ---
    elsif int_val < silence_intensity_threshold
        # Gate / Attenuate
        Formula (part): t_start, t_end, 1, 1, "self * 0.05"
        
    # --- CLASS 4: OTHER ---
    else
        # Slight boost to maintain presence
        Formula (part): t_start, t_end, 1, 1, "self * 1.1"
    endif
endfor

# ============================================================
# CLEANUP
# ============================================================

removeObject: pitch_id
removeObject: intensity_id
removeObject: formant_id
removeObject: hnr_id

selectObject: original_sound_id
Rename: original_name$

selectObject: output_id
Scale peak: scale_peak

if play_after_processing
    Play
endif