# ============================================================
# Praat AudioTools - convolve_STEREO.praat
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

form Stereo Fibonacci Impulses Convolution
    comment This script creates stereo Fibonacci patterns with different jitter
    optionmenu Preset 1
        option Custom
        option Subtle Fibonacci
        option Medium Fibonacci
        option Heavy Fibonacci
        option Extreme Fibonacci
    positive duration_seconds 1.5
    natural number_of_impulses 12
    comment Left channel:
    positive left_fib_start_1 1
    positive left_fib_start_2 1
    positive left_scale_divisor 100.0
    positive left_jitter_stddev 0.010
    comment Right channel:
    positive right_fib_start_1 2
    positive right_fib_start_2 3
    positive right_scale_divisor 120.0
    positive right_jitter_stddev 0.020
    comment Pulse train parameters:
    positive sampling_frequency 44100
    positive pulse_amplitude 1
    positive pulse_width 0.05
    positive pulse_period 2000
    comment Output:
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Fibonacci
    duration_seconds = 1.2
    number_of_impulses = 8
    left_fib_start_1 = 1
    left_fib_start_2 = 1
    left_scale_divisor = 120.0
    left_jitter_stddev = 0.005
    right_fib_start_1 = 1
    right_fib_start_2 = 2
    right_scale_divisor = 140.0
    right_jitter_stddev = 0.008
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.04
    pulse_period = 2200
elsif preset = 3
    # Medium Fibonacci
    duration_seconds = 1.5
    number_of_impulses = 12
    left_fib_start_1 = 1
    left_fib_start_2 = 1
    left_scale_divisor = 100.0
    left_jitter_stddev = 0.010
    right_fib_start_1 = 2
    right_fib_start_2 = 3
    right_scale_divisor = 120.0
    right_jitter_stddev = 0.020
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.05
    pulse_period = 2000
elsif preset = 4
    # Heavy Fibonacci
    duration_seconds = 2.0
    number_of_impulses = 16
    left_fib_start_1 = 1
    left_fib_start_2 = 2
    left_scale_divisor = 85.0
    left_jitter_stddev = 0.018
    right_fib_start_1 = 3
    right_fib_start_2 = 5
    right_scale_divisor = 100.0
    right_jitter_stddev = 0.035
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.06
    pulse_period = 1800
elsif preset = 5
    # Extreme Fibonacci
    duration_seconds = 3.0
    number_of_impulses = 20
    left_fib_start_1 = 2
    left_fib_start_2 = 3
    left_scale_divisor = 70.0
    left_jitter_stddev = 0.030
    right_fib_start_1 = 5
    right_fib_start_2 = 8
    right_scale_divisor = 85.0
    right_jitter_stddev = 0.050
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.08
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
# Create LEFT pattern
Create empty PointProcess: "PP_LEFT", 0, duration_seconds
selectObject: "PointProcess PP_LEFT"
fib1 = left_fib_start_1
fib2 = left_fib_start_2
for i from 1 to number_of_impulses
    t = (fib1 / left_scale_divisor) * duration_seconds + randomGauss(0, left_jitter_stddev)
    if t > 0 and t < duration_seconds
        Add point: t
    endif
    fibTemp = fib1 + fib2
    fib1 = fib2
    fib2 = fibTemp
endfor
# Create RIGHT pattern
Create empty PointProcess: "PP_RIGHT", 0, duration_seconds
selectObject: "PointProcess PP_RIGHT"
fib1 = right_fib_start_1
fib2 = right_fib_start_2
for i from 1 to number_of_impulses
    t = (fib1 / right_scale_divisor) * duration_seconds + randomGauss(0, right_jitter_stddev)
    if t > 0 and t < duration_seconds
        Add point: t
    endif
    fibTemp = fib1 + fib2
    fib1 = fib2
    fib2 = fibTemp
endfor
# Convert to pulse trains
selectObject: "PointProcess PP_LEFT"
To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
Rename: "IMP_LEFT"
Scale peak: 0.99
selectObject: "PointProcess PP_RIGHT"
To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
Rename: "IMP_RIGHT"
Scale peak: 0.99
# Combine to stereo
selectObject: "Sound IMP_LEFT"
plusObject: "Sound IMP_RIGHT"
Combine to stereo
Rename: "IMPULSE_STEREO"
# Convolve
selectObject: "Sound XXXX"
plusObject: "Sound IMPULSE_STEREO"
Convolve: "peak 0.99", "zero"
Rename: originalName$ + "_stereo_fibonacci"
if play_after_processing
    Play
endif
# Cleanup
selectObject: "Sound XXXX"
plusObject: "PointProcess PP_LEFT"
plusObject: "PointProcess PP_RIGHT"
plusObject: "Sound IMP_LEFT"
plusObject: "Sound IMP_RIGHT"
plusObject: "Sound IMPULSE_STEREO"
Remove
selectObject: "Sound " + originalName$ + "_stereo_fibonacci"