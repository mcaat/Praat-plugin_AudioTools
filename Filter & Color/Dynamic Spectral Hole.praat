# ============================================================
# Praat AudioTools - Dynamic Spectral Hole.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Filtering or timbral modification script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Pitch-Based Spectral Notch (v2.0 - Fixed & Safe)
# Applies a frequency-domain cut based on the file's average pitch.

form Pitch-Based Spectral Notch
    comment Preset:
    optionmenu Processing_preset: 1
        option Custom settings
        option Voice fundamental (speech)
        option Voice harmonics (speech)
        option Music fundamental
        option Music upper partials
        option Aggressive notch
        option Gentle notch
    
    comment --- Analysis ---
    positive Time_step 0.01
    positive Minimum_pitch 75
    positive Maximum_pitch 600
    
    comment --- Notch Filter ---
    positive Octave_multiplier 2
    comment (Notch Range: Mean Pitch -> Mean Pitch * Multiplier)
    
    positive Notch_attenuation 0.1
    comment (0 = silence, 1 = no change)
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
    boolean Keep_intermediate_objects 0
endform

# --- Apply Presets ---
if processing_preset = 2
    # Voice fundamental
    time_step = 0.01
    minimum_pitch = 75
    maximum_pitch = 300
    octave_multiplier = 1.5
    notch_attenuation = 0.05
elsif processing_preset = 3
    # Voice harmonics
    time_step = 0.01
    minimum_pitch = 75
    maximum_pitch = 300
    octave_multiplier = 4
    notch_attenuation = 0.2
elsif processing_preset = 4
    # Music fundamental
    time_step = 0.05
    minimum_pitch = 50
    maximum_pitch = 800
    octave_multiplier = 2
    notch_attenuation = 0.1
elsif processing_preset = 5
    # Music upper partials
    time_step = 0.05
    minimum_pitch = 50
    maximum_pitch = 800
    octave_multiplier = 8
    notch_attenuation = 0.15
elsif processing_preset = 6
    # Aggressive
    time_step = 0.01
    minimum_pitch = 75
    maximum_pitch = 600
    octave_multiplier = 3
    notch_attenuation = 0.01
elsif processing_preset = 7
    # Gentle
    time_step = 0.1
    minimum_pitch = 75
    maximum_pitch = 600
    octave_multiplier = 2
    notch_attenuation = 0.3
endif

# Check selection
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
soundName$ = selected$("Sound")

# 1. ANALYZE PITCH
# Note: Reduced time_step to 0.01 in default for better accuracy
pitch = To Pitch: time_step, minimum_pitch, maximum_pitch
mean_pitch = Get mean: 0, 0, "Hertz"

# Safety Check: If sound is unvoiced (whisper/noise), mean_pitch is undefined
if mean_pitch = undefined
    removeObject: pitch
    exitScript: "Analysis failed: No pitch detected. The sound might be unvoiced or too quiet."
endif

lower_bound = mean_pitch
upper_bound = mean_pitch * octave_multiplier

writeInfoLine: "Pitch Notch Filter"
appendInfoLine: "Mean Pitch detected: ", round(mean_pitch), " Hz"
appendInfoLine: "Notching range: ", round(lower_bound), " Hz to ", round(upper_bound), " Hz"

# 2. SPECTRAL MANIPULATION
selectObject: sound
# 'yes' for Fast Fourier is standard
spectrum = To Spectrum: "yes"

# [FIXED FORMULA]
# We interpret variables inside single quotes
Formula: "if x >= 'lower_bound' and x <= 'upper_bound' then self * 'notch_attenuation' else self fi"

# 3. RECONSTRUCT
sound_out = To Sound
Rename: soundName$ + "_notched"
Scale peak: scale_peak

# 4. CLEANUP
if keep_intermediate_objects = 0
    removeObject: pitch, spectrum
endif

if play_after_processing
    selectObject: sound_out
    Play
endif

selectObject: sound_out