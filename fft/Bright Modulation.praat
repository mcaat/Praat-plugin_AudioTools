# ============================================================
# Praat AudioTools - Bright Modulation.praat
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

form Bright Modulation
    comment This script applies sinusoidal modulation to lower frequencies
    comment WARNING: This process can have long runtime on long files
    comment due to FFT calculations
    comment Presets:
    optionmenu preset: 1
        option Default
        option Deep Modulation
        option Shallow Modulation
        option Fast Modulation
        option Slow Modulation
    comment Spectrum parameters:
    boolean fast_fourier yes
    comment Modulation parameters:
    positive cutoff_frequency 10000
    comment (frequencies below this will be modulated)
    positive modulation_center 0.5
    positive modulation_depth 0.5
    positive modulation_frequency_divisor 1000
    comment (higher = slower modulation across spectrum)
    comment Output options:
    positive scale_peak 0.95
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

# Apply preset values
if preset = 2 ; Deep Modulation
    modulation_depth = 0.8
elif preset = 3 ; Shallow Modulation
    modulation_depth = 0.2
elif preset = 4 ; Fast Modulation
    modulation_frequency_divisor = 500
elif preset = 5 ; Slow Modulation
    modulation_frequency_divisor = 2000
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get the original sound name
originalName$ = selected$("Sound")

# Get sampling frequency
sampling_rate = Get sampling frequency

# Convert to spectrum
spectrum = To Spectrum: fast_fourier

# Apply bright modulation (sinusoidal modulation to lower frequencies)
Formula: "if col < 'cutoff_frequency' then self[1,col] * 'modulation_center' * (1 + 'modulation_depth' * sin(col / 'modulation_frequency_divisor')) else self[1,col] fi"

# Convert back to sound
result = To Sound

# Rename result
Rename: originalName$ + "_bright_modulated"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif

# Clean up intermediate objects unless requested to keep
if not keep_intermediate_objects
    selectObject: spectrum
    Remove
endif