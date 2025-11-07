# ============================================================
# Praat AudioTools - rate_modulation.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Modulation or vibrato-based processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Vibrato Rate Modulation Effect
    comment This script creates vibrato with time-varying rate
    comment ==============================================
    optionmenu Preset 1
        option Custom (use settings below)
        option Subtle Natural Vibrato
        option Classic Vocal Vibrato
        option Wide Expressive Vibrato
        option Fast Tremolo
        option Slow Wavy Effect
        option Extreme Modulation
    comment ==============================================
    comment Delay parameters:
    positive base_delay_ms 5.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.10
    comment (depth of delay modulation)
    comment Rate modulation parameters:
    positive base_rate_hz 4.0
    comment (center frequency of vibrato)
    positive rate_sensitivity 3.0
    comment (amount of rate variation)
    positive rate_modulation_hz 0.8
    comment (frequency of rate changes)
    comment Output options:
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Natural Vibrato
    base_delay_ms = 4.0
    modulation_depth = 0.08
    base_rate_hz = 5.5
    rate_sensitivity = 1.5
    rate_modulation_hz = 0.5
elsif preset = 3
    # Classic Vocal Vibrato
    base_delay_ms = 6.0
    modulation_depth = 0.12
    base_rate_hz = 5.8
    rate_sensitivity = 2.0
    rate_modulation_hz = 0.6
elsif preset = 4
    # Wide Expressive Vibrato
    base_delay_ms = 8.0
    modulation_depth = 0.18
    base_rate_hz = 4.5
    rate_sensitivity = 4.0
    rate_modulation_hz = 0.7
elsif preset = 5
    # Fast Tremolo
    base_delay_ms = 3.0
    modulation_depth = 0.15
    base_rate_hz = 8.0
    rate_sensitivity = 5.0
    rate_modulation_hz = 1.2
elsif preset = 6
    # Slow Wavy Effect
    base_delay_ms = 10.0
    modulation_depth = 0.20
    base_rate_hz = 2.5
    rate_sensitivity = 2.5
    rate_modulation_hz = 0.4
elsif preset = 7
    # Extreme Modulation
    base_delay_ms = 12.0
    modulation_depth = 0.25
    base_rate_hz = 6.0
    rate_sensitivity = 6.0
    rate_modulation_hz = 1.5
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_vibrato_rate_mod"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Apply vibrato with rate modulation
# Vibrato rate varies between (base_rate - sensitivity) and (base_rate + sensitivity)
Formula: "self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * x * ('base_rate_hz' + 'rate_sensitivity' * (0.5 + 0.5 * sin(2 * pi * 'rate_modulation_hz' * x))))))))]"

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_vibrato_rate_mod"

# Play if requested
if play_after_processing
    Play
endif



