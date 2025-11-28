# ============================================================
# Praat AudioTools - Harmonic_Resonance.praat
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

form Harmonic Sound Processing
    optionmenu Preset: 1
        option "Custom"
        option "Subtle Harmonics"
        option "Medium Harmonics"
        option "Heavy Harmonics"
        option "Extreme Harmonics"
    positive Tail_duration_(seconds) 2.0
    comment Harmonic processing parameters:
    natural num_iterations 7
    comment Harmonic base range (for randomization):
    positive harmonic_base_min 1.5
    positive harmonic_base_max 4.0
    comment Or use a fixed harmonic base:
    boolean use_fixed_base 0
    positive fixed_harmonic_base 2.5
    comment Amplitude decay parameters:
    positive decay_factor 0.6
    comment Output options:
    positive scale_peak 0.95
    positive Fadeout_duration_(seconds) 1.0
    boolean play_after_processing 1
endform

# Apply preset if not Custom
if preset = 2
    # Subtle Harmonics
    tail_duration = 1.5
    num_iterations = 4
    harmonic_base_min = 1.3
    harmonic_base_max = 2.2
    use_fixed_base = 0
    fixed_harmonic_base = 1.8
    decay_factor = 0.4
    scale_peak = 0.96
    fadeout_duration = 0.8
elsif preset = 3
    # Medium Harmonics
    tail_duration = 2.0
    num_iterations = 7
    harmonic_base_min = 1.5
    harmonic_base_max = 4.0
    use_fixed_base = 0
    fixed_harmonic_base = 2.5
    decay_factor = 0.6
    scale_peak = 0.95
    fadeout_duration = 1.0
elsif preset = 4
    # Heavy Harmonics
    tail_duration = 2.8
    num_iterations = 10
    harmonic_base_min = 2.0
    harmonic_base_max = 4.8
    use_fixed_base = 0
    fixed_harmonic_base = 3.5
    decay_factor = 0.75
    scale_peak = 0.93
    fadeout_duration = 1.4
elsif preset = 5
    # Extreme Harmonics
    tail_duration = 4.0
    num_iterations = 15
    harmonic_base_min = 2.5
    harmonic_base_max = 6.0
    use_fixed_base = 0
    fixed_harmonic_base = 4.5
    decay_factor = 0.85
    scale_peak = 0.91
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

# Determine harmonic base
if use_fixed_base
    harmonicBase = fixed_harmonic_base
else
    harmonicBase = randomUniform(harmonic_base_min, harmonic_base_max)
endif

# Main harmonic processing loop
for k from 1 to num_iterations
    # Exponential harmonic progression
    shiftFactor = harmonicBase ^ k
    b = a / shiftFactor
    
    # Bidirectional formula with harmonic weighting
    Formula: "(self [col + round(b)] - self [col - round(b/2)]) * (1/k)"
    
    # Harmonic amplitude decay
    Formula: "self * (1 - k/num_iterations * 'decay_factor')"
endfor

# Scale to peak
Scale peak: scale_peak

# Apply fadeout
select Sound soundObj
total_duration = Get total duration
fade_start = total_duration - fadeout_duration
Formula: "if x > fade_start then self * (0.5 + 0.5 * cos(pi * (x - fade_start) / 'fadeout_duration')) else self fi"

Rename: original_sound$ + "_harmonics"

# Cleanup
select Sound silent_tail
plus Sound extended_sound
Remove

select Sound 'original_sound$'_harmonics

# Play if requested
if play_after_processing
    Play
endif