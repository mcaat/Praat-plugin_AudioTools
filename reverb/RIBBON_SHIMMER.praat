# ============================================================
# Praat AudioTools - RIBBON_SHIMMER.praat
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

form Ribbon Shimmer Effect
    comment Apply a lush reverb-like shimmer effect to the selected sound
    comment 
    optionmenu Preset 1
        option Custom
        option Subtle Ribbon
        option Medium Ribbon
        option Heavy Ribbon
        option Extreme Ribbon
    positive Tail_duration_(seconds) 0.5
    comment 
    comment === Effect Parameters ===
    positive Number_of_delays 95
    positive Base_amplitude 0.24
    positive Minimum_delay_(seconds) 0.015
    positive Maximum_delay_(seconds) 1.35
    positive Decay_factor 0.955
    comment 
    comment === Stereo Parameters (for stereo input) ===
    positive Right_channel_base_amplitude 0.23
    positive Right_channel_min_delay_(seconds) 0.017
    positive Right_channel_max_delay_(seconds) 1.32
    positive Right_channel_decay_factor 0.95
    comment 
    comment === Fade Out ===
    positive Fadeout_duration_(seconds) 1.0
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Ribbon
    tail_duration = 0.3
    number_of_delays = 50
    base_amplitude = 0.16
    minimum_delay = 0.012
    maximum_delay = 0.8
    decay_factor = 0.965
    right_channel_base_amplitude = 0.15
    right_channel_min_delay = 0.013
    right_channel_max_delay = 0.78
    right_channel_decay_factor = 0.964
    fadeout_duration = 0.8
elsif preset = 3
    # Medium Ribbon
    tail_duration = 0.5
    number_of_delays = 95
    base_amplitude = 0.24
    minimum_delay = 0.015
    maximum_delay = 1.35
    decay_factor = 0.955
    right_channel_base_amplitude = 0.23
    right_channel_min_delay = 0.017
    right_channel_max_delay = 1.32
    right_channel_decay_factor = 0.95
    fadeout_duration = 1.0
elsif preset = 4
    # Heavy Ribbon
    tail_duration = 0.8
    number_of_delays = 140
    base_amplitude = 0.3
    minimum_delay = 0.012
    maximum_delay = 1.8
    decay_factor = 0.945
    right_channel_base_amplitude = 0.29
    right_channel_min_delay = 0.014
    right_channel_max_delay = 1.75
    right_channel_decay_factor = 0.94
    fadeout_duration = 1.4
elsif preset = 5
    # Extreme Ribbon
    tail_duration = 1.2
    number_of_delays = 200
    base_amplitude = 0.38
    minimum_delay = 0.01
    maximum_delay = 2.5
    decay_factor = 0.935
    right_channel_base_amplitude = 0.36
    right_channel_min_delay = 0.011
    right_channel_max_delay = 2.4
    right_channel_decay_factor = 0.93
    fadeout_duration = 1.8
endif

original_sound$ = selected$("Sound")
select Sound 'original_sound$'

original_duration = Get total duration
sampling_rate = Get sample rate
channels = Get number of channels

tail_duration = tail_duration
if channels = 2
    Create Sound from formula: "silent_tail", 2, 0, tail_duration, sampling_rate, "0"
else
    Create Sound from formula: "silent_tail", 1, 0, tail_duration, sampling_rate, "0"
endif

select Sound 'original_sound$'
plus Sound silent_tail
Concatenate
Rename: "extended_sound"

select Sound extended_sound

if channels = 2
    Extract one channel: 1
    Rename: "left_channel"
    select Sound extended_sound
    Extract one channel: 2
    Rename: "right_channel"
    
    # Process left channel
    select Sound left_channel
    Copy: "ribbon_shimmer_left"
    select Sound ribbon_shimmer_left
    
    n = number_of_delays
    baseAmp = base_amplitude
    minD = minimum_delay
    maxD = maximum_delay
    
    for k from 1 to n
        u = k/n
        delay = minD * ( (maxD/minD) ^ u )
        if k mod 3 = 0
            a = baseAmp * (decay_factor ^ k) * (-1)
        else
            a = baseAmp * (decay_factor ^ k) * (1)
        endif
        
        j = randomUniform(-0.003, 0.003)
        Formula: "if x > delay + j then self + a * ( self(x - (delay + j)) + 0.25*(self(x - (delay + j)) - self(x - (delay + j) - 1/sampling_rate)) ) else self fi"
        
        if k mod 20 = 0
            Scale peak: 0.98
        endif
    endfor
    
    Scale peak: 0.98
    
    # Process right channel with different parameters
    select Sound right_channel
    Copy: "ribbon_shimmer_right"
    select Sound ribbon_shimmer_right
    
    n = number_of_delays
    baseAmp = right_channel_base_amplitude
    minD = right_channel_min_delay
    maxD = right_channel_max_delay
    
    for k from 1 to n
        u = k/n
        delay = minD * ( (maxD/minD) ^ u )
        if k mod 4 = 0
            a = baseAmp * (right_channel_decay_factor ^ k) * (-1)
        else
            a = baseAmp * (right_channel_decay_factor ^ k) * (1)
        endif
        
        j = randomUniform(-0.002, 0.002)
        Formula: "if x > delay + j then self + a * ( self(x - (delay + j)) + 0.2*(self(x - (delay + j)) - self(x - (delay + j) - 1/sampling_rate)) ) else self fi"
        
        if k mod 25 = 0
            Scale peak: 0.98
        endif
    endfor
    
    Scale peak: 0.98
    
    # Combine left and right channels to stereo
    select Sound ribbon_shimmer_left
    plus Sound ribbon_shimmer_right
    Combine to stereo
    Rename: "ribbon_shimmer_stereo"
    
    # Cleanup - remove all temporary objects
    removeObject: "Sound ribbon_shimmer_left"
    removeObject: "Sound ribbon_shimmer_right"
    
else
    # Mono processing
    Copy: "ribbon_shimmer"
    select Sound ribbon_shimmer
    
    n = number_of_delays
    baseAmp = base_amplitude
    minD = minimum_delay
    maxD = maximum_delay
    
    for k from 1 to n
        u = k/n
        delay = minD * ( (maxD/minD) ^ u )
        if k mod 3 = 0
            a = baseAmp * (decay_factor ^ k) * (-1)
        else
            a = baseAmp * (decay_factor ^ k) * (1)
        endif
        
        j = randomUniform(-0.003, 0.003)
        Formula: "if x > delay + j then self + a * ( self(x - (delay + j)) + 0.25*(self(x - (delay + j)) - self(x - (delay + j) - 1/sampling_rate)) ) else self fi"
        
        if k mod 20 = 0
            Scale peak: 0.98
        endif
    endfor
    
    Scale peak: 0.98
    Convert to stereo
    Rename: "ribbon_shimmer_stereo"
    
    # Cleanup - remove all temporary objects
    removeObject: "Sound ribbon_shimmer"
endif

# Apply fadeout to the end of the sound
select Sound ribbon_shimmer_stereo
total_duration = Get total duration
fade_duration = fadeout_duration
fade_start = total_duration - fade_duration

Formula: "if x > fade_start then self * (0.5 + 0.5 * cos(pi * (x - fade_start) / fade_duration)) else self fi"

# Final cleanup - remove all intermediate processing objects
select Sound silent_tail
plus Sound extended_sound
if channels = 2
    plus Sound left_channel
    plus Sound right_channel
endif
Remove

# At this point, only the original sound and the final result remain
select Sound ribbon_shimmer_stereo
Play
