# ============================================================
# Praat AudioTools - Intensity_Sine_Modulation.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Dynamic range or envelope control script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Intensity Sine Modulation
    comment This script modulates intensity with a sine wave
    optionmenu Preset 1
        option Custom
        option Subtle Modulation
        option Medium Modulation
        option Heavy Modulation
        option Extreme Modulation
    comment Intensity extraction parameters:
    positive minimum_pitch 100
    positive time_step 0.1
    boolean subtract_mean yes
    comment Sine modulation parameters:
    positive modulation_frequency 10
    positive modulation_center 0.5
    positive modulation_depth 0.5
    comment (intensity will vary between center-depth and center+depth)
    comment Multiply parameters:
    boolean scale_intensities yes
    comment Output options:
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Modulation
    minimum_pitch = 100
    time_step = 0.1
    subtract_mean = 1
    modulation_frequency = 5
    modulation_center = 0.7
    modulation_depth = 0.2
    scale_intensities = 1
elsif preset = 3
    # Medium Modulation
    minimum_pitch = 100
    time_step = 0.1
    subtract_mean = 1
    modulation_frequency = 10
    modulation_center = 0.5
    modulation_depth = 0.5
    scale_intensities = 1
elsif preset = 4
    # Heavy Modulation
    minimum_pitch = 100
    time_step = 0.1
    subtract_mean = 1
    modulation_frequency = 15
    modulation_center = 0.5
    modulation_depth = 0.45
    scale_intensities = 1
elsif preset = 5
    # Extreme Modulation
    minimum_pitch = 100
    time_step = 0.1
    subtract_mean = 1
    modulation_frequency = 25
    modulation_center = 0.5
    modulation_depth = 0.48
    scale_intensities = 1
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif
# Store original sound
a = selected("Sound")
originalName$ = selected$("Sound")
# Copy the sound
b = Copy: originalName$ + "_sine_modulated"
# Extract intensity
To Intensity: minimum_pitch, time_step, subtract_mean
# Apply sine wave modulation
Formula: "self * ('modulation_center' + 'modulation_depth' * sin(x * 'modulation_frequency'))"
# Convert to IntensityTier
c = Down to IntensityTier
# Select sound and intensity tier, then multiply
select a
plus c
Multiply: scale_intensities
# Rename result
Rename: originalName$ + "_result"
# Play if requested
if play_after_processing
    Play
endif
# Clean up intermediate objects unless requested to keep
if not keep_intermediate_objects
    select b
    Remove
    select c
    Remove
endif