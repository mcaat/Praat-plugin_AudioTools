# ============================================================
# Praat AudioTools - stereo_shimmer.praat
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

form Stereo Shimmer
    comment This script creates shimmering delays with high-frequency enhancement
    optionmenu Preset 1
        option Custom
        option Subtle Shimmer
        option Medium Shimmer
        option Heavy Shimmer
        option Extreme Shimmer
    positive tail_duration_seconds 2
    natural number_of_echoes 80
    positive base_amplitude 0.24
    positive min_delay 0.02
    positive max_delay 1.2
    positive decay_factor 0.95
    positive jitter_amount 0.012
    positive hf_enhancement 0.25
    positive scale_every_n 20
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Shimmer
    tail_duration_seconds = 1.5
    number_of_echoes = 40
    base_amplitude = 0.15
    min_delay = 0.02
    max_delay = 0.8
    decay_factor = 0.96
    jitter_amount = 0.008
    hf_enhancement = 0.15
    scale_every_n = 15
elsif preset = 3
    # Medium Shimmer
    tail_duration_seconds = 2
    number_of_echoes = 80
    base_amplitude = 0.24
    min_delay = 0.02
    max_delay = 1.2
    decay_factor = 0.95
    jitter_amount = 0.012
    hf_enhancement = 0.25
    scale_every_n = 20
elsif preset = 4
    # Heavy Shimmer
    tail_duration_seconds = 3
    number_of_echoes = 120
    base_amplitude = 0.32
    min_delay = 0.015
    max_delay = 1.8
    decay_factor = 0.94
    jitter_amount = 0.018
    hf_enhancement = 0.35
    scale_every_n = 25
elsif preset = 5
    # Extreme Shimmer
    tail_duration_seconds = 4
    number_of_echoes = 180
    base_amplitude = 0.4
    min_delay = 0.01
    max_delay = 2.5
    decay_factor = 0.93
    jitter_amount = 0.025
    hf_enhancement = 0.45
    scale_every_n = 30
endif

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif
originalName$ = selected$("Sound")
Copy: originalName$ + "_shimmer"
select Sound 'originalName$'_shimmer
sampling_rate = Get sample rate
channels = Get number of channels
# Create silent tail
if channels = 2
    Create Sound from formula: "silent_tail", 2, 0, tail_duration_seconds, sampling_rate, "0"
else
    Create Sound from formula: "silent_tail", 1, 0, tail_duration_seconds, sampling_rate, "0"
endif
select Sound 'originalName$'_shimmer
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
    
    # Process left
    select Sound left_channel
    for k from 1 to number_of_echoes
        delay = min_delay + (max_delay - min_delay) * k/number_of_echoes + randomUniform(-jitter_amount, jitter_amount)
        sgn = if (k mod 4 < 2) then 1 else -1 fi
        a = base_amplitude * (decay_factor ^ k) * sgn
        Formula: "if x > delay then self + a * self(x - delay) else self fi"
        if k mod scale_every_n = 0
            Scale peak: 0.98
        endif
    endfor
    Formula: "self + 'hf_enhancement'*(self - self(x - 1/44100))"
    Scale peak: 0.98
    
    # Process right (different jitter and phase)
    select Sound right_channel
    for k from 1 to number_of_echoes
        delay = min_delay + (max_delay - min_delay) * k/number_of_echoes + randomUniform(-0.015, 0.015)
        sgn = if ((k + 2) mod 4 < 2) then 1 else -1 fi
        a = base_amplitude * (0.94 ^ k) * sgn
        Formula: "if x > delay then self + a * self(x - delay) else self fi"
        if k mod scale_every_n = 0
            Scale peak: 0.98
        endif
    endfor
    Formula: "self + 0.23*(self - self(x - 1/44100))"
    Scale peak: 0.98
    
    # Combine
    select Sound left_channel
    plus Sound right_channel
    Combine to stereo
    Rename: originalName$ + "_shimmer_result"
    
    # Cleanup
    select Sound left_channel
    plus Sound right_channel
    plus Sound silent_tail
    Remove
    
else
    for k from 1 to number_of_echoes
        delay = min_delay + (max_delay - min_delay) * k/number_of_echoes + randomUniform(-jitter_amount, jitter_amount)
        sgn = if (k mod 4 < 2) then 1 else -1 fi
        a = base_amplitude * (decay_factor ^ k) * sgn
        Formula: "if x > delay then self + a * self(x - delay) else self fi"
        if k mod scale_every_n = 0
            Scale peak: 0.98
        endif
    endfor
    Formula: "self + 'hf_enhancement'*(self - self(x - 1/44100))"
    Scale peak: 0.98
    Rename: originalName$ + "_shimmer_result"
    
    select Sound silent_tail
    Remove
endif
select Sound 'originalName$'_shimmer_result
if play_after_processing
    Play
endif