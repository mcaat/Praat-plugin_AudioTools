# ============================================================
# Praat AudioTools - globally change the pitch and duration.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-based transformation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

################################################################################
# Simple Partial Editor - Manipulation Method with Presets
# Uses Praat's optimized Manipulation object for best quality
################################################################################

form Partial editor with presets
    comment === Choose a Preset ===
    optionmenu preset: 1
        option Custom (use settings below)
        option Vocal harmonics (speech partials)
        option Reduce breathiness (clean harmonics)
        option Deeper voice (pitch down, keep formants)
        option Higher voice (pitch up, keep formants)
        option Chipmunk effect (pitch + formants up)
        option Robot voice (monotone low pitch)
        option Telephone effect (narrow band)
        option Radio voice (warm low cut)
    
    comment === Manual Settings (for Custom preset) ===
    positive pitch_floor       75     
    positive pitch_ceiling     600     
    positive time_step         0.01    
    
    comment === Frequency Range ===
    positive freq_cutoff_low   120     
    positive freq_cutoff_high  3500    
    
    comment === Transformations ===
    real     pitch_shift_semitones       0     
    real     formant_shift_ratio     1.0      
    real     duration_factor_time_stretch   1.0     
endform

# Validation
if numberOfSelected("Sound") = 0
    exit Please select a Sound first.
endif

writeInfoLine: "Partial Editor - Manipulation Method"
writeInfoLine: "====================================="

selectObject: selected("Sound", 1)
origName$ = selected$("Sound")
dur = Get total duration
fs = Get sampling frequency

# ========================================
# APPLY PRESET VALUES
# ========================================

if preset = 2
    # Vocal harmonics (speech partials)
    writeInfoLine: "Preset: Vocal harmonics"
    pitch_floor = 75
    pitch_ceiling = 500
    freq_cutoff_low = 100
    freq_cutoff_high = 4000
    pitch_shift_semitones = 0
    formant_shift_ratio = 1.0
    duration_factor_time_stretch = 1.0
    
elsif preset = 3
    # Reduce breathiness (clean harmonics)
    writeInfoLine: "Preset: Reduce breathiness"
    pitch_floor = 75
    pitch_ceiling = 500
    freq_cutoff_low = 200
    freq_cutoff_high = 3000
    pitch_shift_semitones = 0
    formant_shift_ratio = 1.0
    duration_factor_time_stretch = 1.0
    
elsif preset = 4
    # Deeper voice (pitch down, keep formants)
    writeInfoLine: "Preset: Deeper voice"
    pitch_floor = 50
    pitch_ceiling = 400
    freq_cutoff_low = 80
    freq_cutoff_high = 4000
    pitch_shift_semitones = -4
    formant_shift_ratio = 1.0
    duration_factor_time_stretch = 1.0
    
elsif preset = 5
    # Higher voice (pitch up, keep formants)
    writeInfoLine: "Preset: Higher voice"
    pitch_floor = 100
    pitch_ceiling = 800
    freq_cutoff_low = 150
    freq_cutoff_high = 5000
    pitch_shift_semitones = 5
    formant_shift_ratio = 1.0
    duration_factor_time_stretch = 1.0
    
elsif preset = 6
    # Chipmunk effect (pitch + formants up)
    writeInfoLine: "Preset: Chipmunk effect"
    pitch_floor = 150
    pitch_ceiling = 1000
    freq_cutoff_low = 200
    freq_cutoff_high = 8000
    pitch_shift_semitones = 7
    formant_shift_ratio = 1.4
    duration_factor_time_stretch = 0.85
    
elsif preset = 7
    # Robot voice (monotone low pitch)
    writeInfoLine: "Preset: Robot voice"
    pitch_floor = 50
    pitch_ceiling = 300
    freq_cutoff_low = 100
    freq_cutoff_high = 2500
    pitch_shift_semitones = -6
    formant_shift_ratio = 0.9
    duration_factor_time_stretch = 1.05
    
elsif preset = 8
    # Telephone effect (narrow band)
    writeInfoLine: "Preset: Telephone effect"
    pitch_floor = 75
    pitch_ceiling = 500
    freq_cutoff_low = 300
    freq_cutoff_high = 3400
    pitch_shift_semitones = 0
    formant_shift_ratio = 1.0
    duration_factor_time_stretch = 1.0
    
elsif preset = 9
    # Radio voice (warm low cut)
    writeInfoLine: "Preset: Radio voice"
    pitch_floor = 60
    pitch_ceiling = 400
    freq_cutoff_low = 80
    freq_cutoff_high = 8000
    pitch_shift_semitones = -2
    formant_shift_ratio = 0.95
    duration_factor_time_stretch = 0.98
    
else
    # Custom - use form values
    writeInfoLine: "Preset: Custom"
endif

writeInfoLine: "Settings:"
writeInfoLine: "  Pitch range: ", pitch_floor, " - ", pitch_ceiling, " Hz"
writeInfoLine: "  Frequency range: ", freq_cutoff_low, " - ", freq_cutoff_high, " Hz"
writeInfoLine: "  Pitch shift: ", pitch_shift_semitones, " semitones"
writeInfoLine: "  Formant shift: ", formant_shift_ratio, "x"
writeInfoLine: "  Duration: ", duration_factor_time_stretch, "x"
writeInfoLine: ""

# ========================================
# MANIPULATION OBJECT PROCESSING
# ========================================

writeInfo: "Creating manipulation..."

selectObject: "Sound " + origName$
To Manipulation: time_step, pitch_floor, pitch_ceiling
manip_obj = selected("Manipulation")

# Modify pitch
if pitch_shift_semitones <> 0
    writeInfo: "Applying pitch shift..."
    selectObject: manip_obj
    Extract pitch tier
    pitch_tier = selected("PitchTier")
    Formula: "self * " + string$(2^(pitch_shift_semitones/12))
    
    selectObject: manip_obj
    plus pitch_tier
    Replace pitch tier
    removeObject: pitch_tier
endif

# Modify duration
if duration_factor_time_stretch <> 1.0
    writeInfo: "Applying duration change..."
    selectObject: manip_obj
    Extract duration tier
    dur_tier = selected("DurationTier")
    Add point: 0, duration_factor_time_stretch
    
    selectObject: manip_obj
    plus dur_tier
    Replace duration tier
    removeObject: dur_tier
endif

# Resynthesize
writeInfo: "Resynthesizing..."
selectObject: manip_obj
Get resynthesis (overlap-add)
Rename: "temp_resynth"

# Apply formant shift if needed
if formant_shift_ratio <> 1.0
    writeInfo: "Applying formant shift..."
    Change gender: pitch_floor, pitch_ceiling, formant_shift_ratio, 0, 0, 1.0
endif

# Apply frequency filtering
writeInfo: "Applying frequency filtering..."
Filter (pass Hann band): freq_cutoff_low, freq_cutoff_high, 100

# Final naming
if preset = 1
    Rename: origName$ + "_custom"
elsif preset = 2
    Rename: origName$ + "_vocal"
elsif preset = 3
    Rename: origName$ + "_clean"
elsif preset = 4
    Rename: origName$ + "_deeper"
elsif preset = 5
    Rename: origName$ + "_higher"
elsif preset = 6
    Rename: origName$ + "_chipmunk"
elsif preset = 7
    Rename: origName$ + "_robot"
elsif preset = 8
    Rename: origName$ + "_telephone"
elsif preset = 9
    Rename: origName$ + "_radio"
endif

result_name$ = selected$("Sound")

# Normalize
Scale intensity: 70
Play

# Cleanup
removeObject: manip_obj
removeObject: "Sound temp_resynth"

writeInfoLine: "====================================="
writeInfoLine: "COMPLETE!"
writeInfoLine: "====================================="
writeInfoLine: "Original: Sound ", origName$
writeInfoLine: "Result: Sound ", result_name$
writeInfoLine: "Original duration: ", fixed$(dur, 3), "s"

# Select result for user
selectObject: "Sound " + result_name$

writeInfoLine: ""
writeInfoLine: "Ready! The processed sound is now selected."
