# ============================================================
# Praat AudioTools - convolve_RANDOM WALK.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Reverberation or diffusion script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Random Walk Density Convolution
    comment This script creates impulses with randomly evolving spacing
    optionmenu Preset 1
        option Custom
        option Subtle Walk
        option Medium Walk
        option Heavy Walk
        option Extreme Walk
    positive duration_seconds 1.8
    positive first_pulse_time 0.10
    positive initial_gap 0.18
    positive gap_variation_stddev 0.015
    positive minimum_gap 0.020
    positive maximum_gap 0.400
    natural maximum_pulses 200
    comment Pulse train parameters:
    positive sampling_frequency 44100
    positive pulse_amplitude 1
    positive pulse_width 0.02
    positive pulse_period 2000
    comment Output:
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Walk
    duration_seconds = 1.5
    first_pulse_time = 0.08
    initial_gap = 0.20
    gap_variation_stddev = 0.008
    minimum_gap = 0.030
    maximum_gap = 0.350
    maximum_pulses = 150
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.018
    pulse_period = 2200
elsif preset = 3
    # Medium Walk
    duration_seconds = 1.8
    first_pulse_time = 0.10
    initial_gap = 0.18
    gap_variation_stddev = 0.015
    minimum_gap = 0.020
    maximum_gap = 0.400
    maximum_pulses = 200
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.02
    pulse_period = 2000
elsif preset = 4
    # Heavy Walk
    duration_seconds = 2.5
    first_pulse_time = 0.12
    initial_gap = 0.15
    gap_variation_stddev = 0.025
    minimum_gap = 0.015
    maximum_gap = 0.500
    maximum_pulses = 280
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.025
    pulse_period = 1800
elsif preset = 5
    # Extreme Walk
    duration_seconds = 3.5
    first_pulse_time = 0.15
    initial_gap = 0.12
    gap_variation_stddev = 0.040
    minimum_gap = 0.010
    maximum_gap = 0.650
    maximum_pulses = 400
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.03
    pulse_period = 1600
endif

if numberOfSelected("Sound") < 1
    exitScript: "Select a Sound in the Objects window first."
endif
selectObject: selected("Sound", 1)
originalName$ = selected$("Sound")
Copy: "XXXX"
selectObject: "Sound XXXX"
Resample: sampling_frequency, 50
Convert to mono
# Create random walk point pattern
Create empty PointProcess: "pp_walk", 0, duration_seconds
selectObject: "PointProcess pp_walk"
t = first_pulse_time
gap = initial_gap
i = 0
while (t < duration_seconds) and (i < maximum_pulses)
    Add point: t
    gap = gap + randomGauss(0, gap_variation_stddev)
    if gap < minimum_gap
        gap = minimum_gap
    endif
    if gap > maximum_gap
        gap = maximum_gap
    endif
    t = t + gap
    i = i + 1
endwhile
# Convert to pulse train
To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
Rename: "impulse_walk"
Scale peak: 0.99
# Convolve
selectObject: "Sound XXXX"
plusObject: "Sound impulse_walk"
Convolve: "peak 0.99", "zero"
Rename: originalName$ + "_random_walk"
if play_after_processing
    Play
endif
# Cleanup
selectObject: "Sound XXXX"
plusObject: "PointProcess pp_walk"
plusObject: "Sound impulse_walk"
Remove
selectObject: "Sound " + originalName$ + "_random_walk"