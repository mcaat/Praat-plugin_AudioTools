# ============================================================
# Praat AudioTools - Bit Crusher (8-Bit Arcade).praat
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

form Spectral Quantization
    comment This script applies low-bit quantization to the spectrum
    optionmenu Preset: 1
        option Default
        option Subtle Quantization
        option Heavy Quantization
        option Wide Range
    comment WARNING: This process can have long runtime on long files
    comment due to FFT calculations
    comment Spectrum parameters:
    boolean fast_fourier no
    comment (use "no" for precise control)
    comment Quantization frequency range:
    positive lower_frequency 200
    positive upper_frequency 3000
    comment Quantization parameters:
    positive quantization_steps 2
    comment (number of quantization levels: lower = more extreme)
    comment Outside range attenuation:
    positive outside_range_multiplier 0.5
    comment (applied to frequencies outside the range)
    comment Output options:
    positive scale_peak 0.99
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

# Apply preset values
if preset$ = "Subtle Quantization"
    lower_frequency = 300
    upper_frequency = 2500
    quantization_steps = 4
    outside_range_multiplier = 0.7
elif preset$ = "Heavy Quantization"
    lower_frequency = 100
    upper_frequency = 4000
    quantization_steps = 1
    outside_range_multiplier = 0.3
elif preset$ = "Wide Range"
    lower_frequency = 50
    upper_frequency = 6000
    quantization_steps = 3
    outside_range_multiplier = 0.5
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get the original sound name
originalName$ = selected$("Sound")

# Convert to spectrum
spectrum = To Spectrum: fast_fourier

# Apply spectral quantization
# Frequencies within range are quantized, outside range are attenuated
Formula: "if x >= 'lower_frequency' and x <= 'upper_frequency' then self * (round('quantization_steps' * (x - 'lower_frequency') / ('upper_frequency' - 'lower_frequency')) / 'quantization_steps') else self * 'outside_range_multiplier' fi"

# Convert back to sound
result = To Sound

# Rename result
Rename: originalName$ + "_spectral_quantized"

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