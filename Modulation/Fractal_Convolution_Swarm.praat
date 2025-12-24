# ============================================================
# Praat AudioTools - Fractal_Convolution_Swarm.praat
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

form Fractal Convolution Swarm
    comment This script applies multi-scale fractal convolution processing
    comment ==============================================
    optionmenu Preset 1
        option Custom (use settings below)
        option Subtle Texture
        option Ambient Swarm
        option Dense Cloud
        option Granular Dispersion
        option Extreme Fractal
        option Gentle Shimmer
    comment ==============================================
    comment Fractal parameters:
    natural fractal_depth 5
    comment (number of recursive depth levels)
    natural convolution_width 3
    comment (kernel half-width: processes from -width to +width)
    comment Scaling parameters:
    positive base_delay_ms 5.0
    comment (base delay time in milliseconds)
    positive depth_scale_factor 1.6
    comment (delay multiplier per depth level)
    positive mix_amount 0.3
    comment (wet/dry mix per iteration, 0-1)
    comment Output options:
    positive scale_peak 0.95
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Texture
    fractal_depth = 3
    convolution_width = 2
    base_delay_ms = 3.0
    depth_scale_factor = 1.4
    mix_amount = 0.2
elsif preset = 3
    # Ambient Swarm
    fractal_depth = 5
    convolution_width = 3
    base_delay_ms = 5.0
    depth_scale_factor = 1.6
    mix_amount = 0.3
elsif preset = 4
    # Dense Cloud
    fractal_depth = 6
    convolution_width = 4
    base_delay_ms = 7.0
    depth_scale_factor = 1.8
    mix_amount = 0.4
elsif preset = 5
    # Granular Dispersion
    fractal_depth = 7
    convolution_width = 5
    base_delay_ms = 8.0
    depth_scale_factor = 2.0
    mix_amount = 0.45
elsif preset = 6
    # Extreme Fractal
    fractal_depth = 8
    convolution_width = 6
    base_delay_ms = 10.0
    depth_scale_factor = 2.2
    mix_amount = 0.5
elsif preset = 7
    # Gentle Shimmer
    fractal_depth = 4
    convolution_width = 2
    base_delay_ms = 2.5
    depth_scale_factor = 1.3
    mix_amount = 0.15
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_fractal_swarm"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base_delay = round(base_delay_ms * sampling / 1000)

# Apply fractal convolution processing with better algorithm
for depth from 1 to fractal_depth
    # Calculate delay for this depth level (exponentially increasing)
    current_delay = round(base_delay * (depth_scale_factor ^ depth))
    
    # Weight decreases with depth but not too aggressively
    depth_weight = 1 / sqrt(depth)
    
    # Apply convolution kernel at multiple offsets
    for kernel from -convolution_width to convolution_width
        if kernel <> 0
            # Calculate kernel weight (center-weighted)
            kernel_weight = 1 / (1 + abs(kernel))
            
            # Calculate total shift
            total_shift = current_delay + (kernel * round(current_delay * 0.3))
            
            # Mix in the delayed/advanced signal
            Formula: "self * (1 - 'mix_amount' * 'kernel_weight' * 'depth_weight') + self[max(1, min(ncol, col + 'total_shift'))] * ('mix_amount' * 'kernel_weight' * 'depth_weight')"
        endif
    endfor
endfor

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_fractal_convolution_swarm"

# Play if requested
if play_after_processing
    Play
endif