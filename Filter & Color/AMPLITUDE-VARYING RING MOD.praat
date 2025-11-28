# ============================================================
# Praat AudioTools - AMPLITUDE-VARYING RING MOD.praat
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

form Amplitude Varying Ring Modulation
    comment This script applies ring modulation with varying amplitude
    optionmenu Preset: 1
        option Default
        option Subtle Modulation
        option Extreme Sweep
        option Fast Pulsing
    comment Ring modulation parameters:
    positive carrier_frequency 250
    comment (base frequency for ring modulation in Hz)
    comment Frequency sweep parameters:
    positive sweep_exponent 2
    comment (controls frequency acceleration: 1=linear, 2=quadratic)
    comment Amplitude modulation parameters:
    positive amplitude_rate 3
    comment (rate of amplitude variation in Hz)
    positive amplitude_center 0.5
    positive amplitude_depth 0.5
    comment (amplitude varies between center-depth and center+depth)
    comment Output options:
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values
if preset$ = "Subtle Modulation"
    carrier_frequency = 100
    sweep_exponent = 1.5
    amplitude_rate = 1
    amplitude_center = 0.7
    amplitude_depth = 0.3
elif preset$ = "Extreme Sweep"
    carrier_frequency = 500
    sweep_exponent = 3
    amplitude_rate = 5
    amplitude_center = 0.5
    amplitude_depth = 0.5
elif preset$ = "Fast Pulsing"
    carrier_frequency = 200
    sweep_exponent = 2
    amplitude_rate = 10
    amplitude_center = 0.6
    amplitude_depth = 0.4
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get the name of the original sound
originalName$ = selected$("Sound")

# Copy the sound object
Copy: originalName$ + "_ringmod"

# Apply amplitude-varying ring modulation with frequency sweep
Formula: "self * (sin(2 * pi * 'carrier_frequency' * x^'sweep_exponent' / 'sweep_exponent')) * ('amplitude_center' + 'amplitude_depth' * sin(2 * pi * 'amplitude_rate' * x))"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif