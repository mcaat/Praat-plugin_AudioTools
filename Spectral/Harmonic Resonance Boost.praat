# ============================================================
# Praat AudioTools - Harmonic Resonance Boost.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Harmonic Resonance Boost (Matrix-Based - STEREO)

form Harmonic Resonance Boost
    comment This script boosts harmonic frequencies and attenuates others
    comment Optimized with matrix-based processing for speed
    optionmenu preset: 1
        option Custom (use settings below)
        option Strong Harmonic Boost
        option Subtle Harmonic Boost
        option Wide Harmonic Bandwidth
        option Deep Attenuation
        option Extreme Resonance
    comment === Custom Settings ===
    positive fundamental_frequency 440
    comment (base frequency for harmonic series in Hz)
    positive harmonic_bandwidth 50
    comment (width of harmonic region in Hz)
    positive harmonic_boost 1.5
    comment (multiplier for harmonic frequencies)
    positive mid_freq_cutoff 6000
    comment (transition point between mid and high frequency)
    positive low_mid_attenuation 0.6
    comment (attenuation below mid_freq_cutoff)
    positive high_freq_attenuation 0.4
    comment (attenuation above mid_freq_cutoff)
    boolean create_stereo 1
    positive stereo_bandwidth_offset 10
    comment (R channel bandwidth offset in bins for stereo width)
    positive scale_peak 0.88
    boolean play_after_processing 1
endform

# Apply preset values
if preset = 2
    fundamental_frequency = 440
    harmonic_bandwidth = 50
    harmonic_boost = 3.0
    mid_freq_cutoff = 6000
    low_mid_attenuation = 0.4
    high_freq_attenuation = 0.3
    preset_name$ = "Strong"
elsif preset = 3
    fundamental_frequency = 440
    harmonic_bandwidth = 50
    harmonic_boost = 1.2
    mid_freq_cutoff = 6000
    low_mid_attenuation = 0.75
    high_freq_attenuation = 0.6
    preset_name$ = "Subtle"
elsif preset = 4
    fundamental_frequency = 440
    harmonic_bandwidth = 150
    harmonic_boost = 2.0
    mid_freq_cutoff = 6000
    low_mid_attenuation = 0.5
    high_freq_attenuation = 0.35
    preset_name$ = "WideBand"
elsif preset = 5
    fundamental_frequency = 440
    harmonic_bandwidth = 50
    harmonic_boost = 2.5
    mid_freq_cutoff = 6000
    low_mid_attenuation = 0.2
    high_freq_attenuation = 0.1
    preset_name$ = "DeepAtten"
elsif preset = 6
    fundamental_frequency = 440
    harmonic_bandwidth = 30
    harmonic_boost = 5.0
    mid_freq_cutoff = 6000
    low_mid_attenuation = 0.15
    high_freq_attenuation = 0.05
    preset_name$ = "Extreme"
else
    preset_name$ = "Custom"
endif

# Check if a Sound is selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

writeInfoLine: "Harmonic Resonance Boost (Matrix-Based)"
appendInfoLine: "=== PRESET: ", preset_name$, " ==="
if create_stereo
    appendInfoLine: "MODE: STEREO (bandwidth offset: ", stereo_bandwidth_offset, ")"
else
    appendInfoLine: "MODE: MONO"
endif
appendInfoLine: "Fundamental: ", fundamental_frequency, " Hz"
appendInfoLine: "Harmonic bandwidth: ", harmonic_bandwidth, " bins"
appendInfoLine: "Harmonic boost: ", harmonic_boost, "x"
appendInfoLine: "Low/mid attenuation: ", low_mid_attenuation, "x"
appendInfoLine: "High freq attenuation: ", high_freq_attenuation, "x"
appendInfoLine: ""

# Get the original sound
original_sound = selected("Sound")
original_name$ = selected$("Sound")
n_channels = Get number of channels

# Convert to mono if needed
if n_channels > 1
    sound = Convert to mono
else
    sound = Copy: "mono_temp"
endif

# ===== PROCESS LEFT CHANNEL =====
appendInfoLine: "Processing LEFT channel..."

selectObject: sound
spectrum_L = To Spectrum: "yes"
selectObject: spectrum_L
matrix_L = To Matrix

selectObject: matrix_L
ncols = Get number of columns

# Apply harmonic boost to left
Formula: "if (col mod 'fundamental_frequency') < 'harmonic_bandwidth' then self * 'harmonic_boost' else if x < 'mid_freq_cutoff' then self * 'low_mid_attenuation' else self * 'high_freq_attenuation' fi fi"

selectObject: matrix_L
spectrum_L_mod = To Spectrum
selectObject: spectrum_L_mod
result_L = To Sound

appendInfoLine: "Left channel complete"

# ===== PROCESS RIGHT CHANNEL (if stereo) =====
if create_stereo
    appendInfoLine: "Processing RIGHT channel..."
    
    selectObject: sound
    spectrum_R = To Spectrum: "yes"
    selectObject: spectrum_R
    matrix_R = To Matrix
    
    # Right channel uses slightly different bandwidth for stereo width
    bandwidth_R = harmonic_bandwidth + stereo_bandwidth_offset
    
    selectObject: matrix_R
    Formula: "if (col mod 'fundamental_frequency') < 'bandwidth_R' then self * 'harmonic_boost' else if x < 'mid_freq_cutoff' then self * 'low_mid_attenuation' else self * 'high_freq_attenuation' fi fi"
    
    selectObject: matrix_R
    spectrum_R_mod = To Spectrum
    selectObject: spectrum_R_mod
    result_R = To Sound
    
    appendInfoLine: "Right channel complete"
    
    # Combine to stereo
    appendInfoLine: "Creating stereo output..."
    selectObject: result_L
    plusObject: result_R
    final_result = Combine to stereo
    
    # Cleanup stereo processing
    removeObject: spectrum_R, matrix_R, spectrum_R_mod, result_L, result_R
else
    final_result = result_L
endif

# Finalize
selectObject: final_result
if create_stereo
    Rename: original_name$ + "_HB_" + preset_name$ + "_STEREO"
else
    Rename: original_name$ + "_HB_" + preset_name$
endif
Scale peak: scale_peak

appendInfoLine: "Done!"

if play_after_processing
    Play
endif

# Cleanup
removeObject: sound, spectrum_L, matrix_L, spectrum_L_mod

appendInfoLine: "Processing complete!"