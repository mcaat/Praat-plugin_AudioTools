# ============================================================
# Praat AudioTools - Bell curve envelope.praat
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

form Bell Curve Envelope
    comment This script applies spectral filtering and Gaussian envelope
    comment Presets:
    optionmenu preset: 1
        option Default
        option Narrow Bell
        option Wide Bell
        option Low Freq Emphasis
        option High Freq Emphasis
    comment Spectral filtering parameters:
    positive low_freq_factor 1.1
    positive high_freq_factor 1.1
    comment Bell curve (Gaussian) envelope parameters:
    positive bell_width_divisor 4
    comment (higher = narrower bell, lower = wider bell)
    positive bell_center_position 0.5
    comment (0 = start, 0.5 = middle, 1 = end)
    comment Output options:
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values
if preset = 2 ; Narrow Bell
    bell_width_divisor = 6
elif preset = 3 ; Wide Bell
    bell_width_divisor = 2
elif preset = 4 ; Low Freq Emphasis
    low_freq_factor = 1.5
    high_freq_factor = 1.0
elif preset = 5 ; High Freq Emphasis
    low_freq_factor = 1.0
    high_freq_factor = 1.5
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Copy the sound object
Copy: "soundObj"

# Get name and ID
name$ = selected$("Sound")
sound = selected("Sound")

# Apply spectral filtering (emphasize mids, reduce extremes)
Formula: "self[col/'low_freq_factor'] - self[col*'high_freq_factor']"

# Apply Gaussian (bell curve) envelope
Formula: "self * exp(-((x - (xmin + (xmax-xmin) * 'bell_center_position')) / ((xmax-xmin) / 'bell_width_divisor'))^2)"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif