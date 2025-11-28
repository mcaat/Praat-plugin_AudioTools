# ============================================================
# Praat AudioTools - Fractal_Convolution_Matrix.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Delay or temporal structure script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Fractal Sound Processing
    comment Fractal processing parameters:
    optionmenu Preset 1
        option Custom
        option Subtle Fractal
        option Medium Fractal
        option Heavy Fractal
        option Extreme Fractal
    positive Tail_duration_(seconds) 2.0
    natural fractal_depth 5
    natural convolution_width 3
    comment Scaling parameters:
    positive kernel_divisor 10
    positive amplitude_reduction 0.15
    comment Output options:
    positive scale_peak 0.90
    positive Fadeout_duration_(seconds) 1.0
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Fractal
    tail_duration = 1.5
    fractal_depth = 3
    convolution_width = 2
    kernel_divisor = 12
    amplitude_reduction = 0.12
    scale_peak = 0.92
    fadeout_duration = 0.8
elsif preset = 3
    # Medium Fractal
    tail_duration = 2.0
    fractal_depth = 5
    convolution_width = 3
    kernel_divisor = 10
    amplitude_reduction = 0.15
    scale_peak = 0.90
    fadeout_duration = 1.0
elsif preset = 4
    # Heavy Fractal
    tail_duration = 2.8
    fractal_depth = 7
    convolution_width = 4
    kernel_divisor = 8
    amplitude_reduction = 0.18
    scale_peak = 0.88
    fadeout_duration = 1.4
elsif preset = 5
    # Extreme Fractal
    tail_duration = 4.0
    fractal_depth = 10
    convolution_width = 5
    kernel_divisor = 6
    amplitude_reduction = 0.22
    scale_peak = 0.86
    fadeout_duration = 1.8
endif

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

original_sound$ = selected$("Sound")
select Sound 'original_sound$'
sampling_rate = Get sample rate
channels = Get number of channels

# Create silent tail
if channels = 2
    Create Sound from formula: "silent_tail", 2, 0, tail_duration, sampling_rate, "0"
else
    Create Sound from formula: "silent_tail", 1, 0, tail_duration, sampling_rate, "0"
endif

# Concatenate
select Sound 'original_sound$'
plus Sound silent_tail
Concatenate
Rename: "extended_sound"

select Sound extended_sound
Copy: "soundObj"

# Get the number of samples
a = Get number of samples

# Main fractal processing loop
for depth from 1 to fractal_depth
    scaleFactor = 2 ^ depth
    kernelSize = round(a / (kernel_divisor * scaleFactor))
    
    # Fractal convolution kernel
    for kernel from -convolution_width to convolution_width
        kernelWeight = 1 / (1 + abs(kernel))
        kernelShift = kernel * kernelSize
        
        Formula: "self + self [col + 'kernelShift'] * 'kernelWeight' / ('depth' + 2)"
    endfor
    
    # Fractal amplitude scaling
    Formula: "self * (1 - depth * 'amplitude_reduction')"
endfor

# Scale to peak
Scale peak: scale_peak

# Apply fadeout
select Sound soundObj
total_duration = Get total duration
fade_start = total_duration - fadeout_duration
Formula: "if x > fade_start then self * (0.5 + 0.5 * cos(pi * (x - fade_start) / 'fadeout_duration')) else self fi"

Rename: original_sound$ + "_fractal"

# Cleanup
select Sound silent_tail
plus Sound extended_sound
Remove

select Sound 'original_sound$'_fractal

# Play if requested
if play_after_processing
    Play
endif