# ============================================================
# Praat AudioTools - Simple_Experimental_Reverberation.praat
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

form Smooth Cosmic Reverb Effect
    comment Apply a smooth, modulated cosmic reverb effect
    comment 
    optionmenu Preset 1
        option Custom
        option Subtle Cosmic
        option Medium Cosmic
        option Heavy Cosmic
        option Extreme Cosmic
    positive Tail_duration_(seconds) 2.0
    comment 
    comment === Main Effect Parameters ===
    positive Number_of_delays 45
    positive Base_amplitude_(left/mono) 0.22
    positive Decay_factor_(left/mono) 0.96
    comment 
    comment === Delay Range ===
    positive Delay_start_(seconds) 0.08
    positive Delay_range_(seconds) 0.5
    positive Delay_modulation_depth_(seconds) 0.08
    comment 
    comment === Stereo Right Channel Parameters ===
    positive Right_base_amplitude 0.20
    positive Right_decay_factor 0.95
    positive Right_delay_start_(seconds) 0.09
    positive Right_delay_range_(seconds) 0.48
    positive Right_delay_modulation_depth_(seconds) 0.07
    comment 
    comment === Modulation Parameters ===
    positive Amplitude_modulation_depth 0.2
    positive Modulation_frequency_factor 0.5
    comment 
    comment === Enhancement and Fade ===
    positive High_frequency_enhancement 0.08
    positive HF_enhancement_decay_rate 4.0
    positive Fadeout_duration_(seconds) 1.2
    positive Final_peak_level 0.98
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Cosmic
    tail_duration = 1.5
    number_of_delays = 25
    base_amplitude = 0.15
    decay_factor = 0.97
    delay_start = 0.05
    delay_range = 0.3
    delay_modulation_depth = 0.05
    right_base_amplitude = 0.14
    right_decay_factor = 0.97
    right_delay_start = 0.06
    right_delay_range = 0.28
    right_delay_modulation_depth = 0.04
    amplitude_modulation_depth = 0.15
    modulation_frequency_factor = 0.4
    high_frequency_enhancement = 0.05
    hF_enhancement_decay_rate = 3.0
    fadeout_duration = 1.0
    final_peak_level = 0.98
elsif preset = 3
    # Medium Cosmic
    tail_duration = 2.0
    number_of_delays = 45
    base_amplitude = 0.22
    decay_factor = 0.96
    delay_start = 0.08
    delay_range = 0.5
    delay_modulation_depth = 0.08
    right_base_amplitude = 0.20
    right_decay_factor = 0.95
    right_delay_start = 0.09
    right_delay_range = 0.48
    right_delay_modulation_depth = 0.07
    amplitude_modulation_depth = 0.2
    modulation_frequency_factor = 0.5
    high_frequency_enhancement = 0.08
    hF_enhancement_decay_rate = 4.0
    fadeout_duration = 1.2
    final_peak_level = 0.98
elsif preset = 4
    # Heavy Cosmic
    tail_duration = 3.0
    number_of_delays = 70
    base_amplitude = 0.28
    decay_factor = 0.95
    delay_start = 0.1
    delay_range = 0.75
    delay_modulation_depth = 0.12
    right_base_amplitude = 0.26
    right_decay_factor = 0.94
    right_delay_start = 0.11
    right_delay_range = 0.72
    right_delay_modulation_depth = 0.11
    amplitude_modulation_depth = 0.3
    modulation_frequency_factor = 0.65
    high_frequency_enhancement = 0.12
    hF_enhancement_decay_rate = 5.0
    fadeout_duration = 1.8
    final_peak_level = 0.98
elsif preset = 5
    # Extreme Cosmic
    tail_duration = 4.5
    number_of_delays = 100
    base_amplitude = 0.35
    decay_factor = 0.94
    delay_start = 0.12
    delay_range = 1.2
    delay_modulation_depth = 0.18
    right_base_amplitude = 0.33
    right_decay_factor = 0.93
    right_delay_start = 0.13
    right_delay_range = 1.15
    right_delay_modulation_depth = 0.16
    amplitude_modulation_depth = 0.4
    modulation_frequency_factor = 0.8
    high_frequency_enhancement = 0.15
    hF_enhancement_decay_rate = 6.0
    fadeout_duration = 2.5
    final_peak_level = 0.98
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
    
    select Sound left_channel
    Copy: "processed_left"
    select Sound processed_left
    
    n = number_of_delays
    base_amplitude = base_amplitude
    
    for k from 1 to n
        delay = delay_start + delay_range * (k/n) + delay_modulation_depth * sin(k * 0.6)
        amp_mod = base_amplitude * (decay_factor ^ k) * (0.8 + amplitude_modulation_depth * sin(k * modulation_frequency_factor))
        
        if k mod 8 = 0
            Formula: "self + 'amp_mod' * self(x - 'delay') * (1 + 0.2*sin(x*40))"
        elsif k mod 12 = 0
            Formula: "self + 'amp_mod' * 0.7 * self(x - 'delay') * (1 + 0.15*sin(x*80))"
        elsif k mod 6 = 0
            Formula: "self + 'amp_mod' * self(x - 'delay') * (0.7 + 0.3*sin(4*pi*x))"
        else
            Formula: "self + 'amp_mod' * self(x - 'delay') * (0.9 + 0.1*sin(x*60))"
        endif
    endfor
    
    Formula: "self * (0.9 + 0.1*(1 - x/'original_duration'))"
    
    select Sound right_channel
    Copy: "processed_right"
    select Sound processed_right
    
    n = number_of_delays
    base_amplitude = right_base_amplitude
    
    for k from 1 to n
        delay = right_delay_start + right_delay_range * (k/n) + right_delay_modulation_depth * cos(k * 0.7)
        amp_mod = base_amplitude * (right_decay_factor ^ k) * (0.75 + 0.25 * cos(k * 0.6))
        
        if k mod 7 = 0
            Formula: "self + 'amp_mod' * self(x - 'delay') * (1 + 0.18*cos(x*35))"
        elsif k mod 11 = 0
            Formula: "self + 'amp_mod' * 0.75 * self(x - 'delay') * (1 + 0.12*sin(x*70))"
        elsif k mod 5 = 0
            Formula: "self + 'amp_mod' * self(x - 'delay') * (0.65 + 0.35*cos(3*pi*x))"
        else
            Formula: "self + 'amp_mod' * self(x - 'delay') * (0.85 + 0.15*cos(x*55))"
        endif
    endfor
    
    Formula: "self * (0.88 + 0.12*(1 - x/'original_duration'))"
    
    select Sound processed_left
    plus Sound processed_right
    Combine to stereo
    Rename: "smooth_cosmic_reverb"
    
    removeObject: "Sound processed_left"
    removeObject: "Sound processed_right"
    
else
    Copy: "processed"
    select Sound processed
    
    n = number_of_delays
    base_amplitude = base_amplitude
    
    for k from 1 to n
        delay = delay_start + delay_range * (k/n) + delay_modulation_depth * sin(k * 0.6)
        amp_mod = base_amplitude * (decay_factor ^ k) * (0.8 + amplitude_modulation_depth * sin(k * modulation_frequency_factor))
        
        if k mod 8 = 0
            Formula: "self + 'amp_mod' * self(x - 'delay') * (1 + 0.2*sin(x*40))"
        elsif k mod 10 = 0
            Formula: "self + 'amp_mod' * 0.7 * self(x - 'delay') * (1 + 0.15*sin(x*80))"
        else
            Formula: "self + 'amp_mod' * self(x - 'delay') * (0.9 + 0.1*sin(x*60))"
        endif
    endfor
    
    Formula: "self * (0.9 + 0.1*(1 - x/'original_duration'))"
    Convert to stereo
    Rename: "smooth_cosmic_reverb"
    
    removeObject: "Sound processed"
endif

# Gentle high-frequency enhancement (not harsh)
select Sound smooth_cosmic_reverb
Formula: "self + 'high_frequency_enhancement' * (self - self(x - 1/'sampling_rate')) * exp(-'hF_enhancement_decay_rate'*x/'original_duration')"

select Sound smooth_cosmic_reverb
total_duration = Get total duration
fade_duration = fadeout_duration
fade_start = total_duration - fade_duration

Formula: "if x > 'fade_start' then self * (0.5 + 0.5 * cos(pi * (x - 'fade_start') / 'fade_duration')) else self fi"

select Sound silent_tail
plus Sound extended_sound
if channels = 2
    plus Sound left_channel
    plus Sound right_channel
endif
Remove

select Sound smooth_cosmic_reverb
Scale peak: final_peak_level
Play