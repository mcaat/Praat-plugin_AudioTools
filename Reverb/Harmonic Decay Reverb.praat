# ============================================================
# Praat AudioTools - Harmonic Decay Reverb.praat
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

form Harmonic Decay Reverb
    comment This script creates delays based on harmonic intervals
    optionmenu Preset 1
        option Custom
        option Subtle Harmonic
        option Medium Harmonic
        option Heavy Harmonic
        option Extreme Harmonic
    positive Tail_duration_(seconds) 1.5
    natural number_of_echoes 48
    positive base_delay_seconds 0.05
    positive decay_factor 0.92
    positive harmonic_spread 1.2
    positive amplitude_mean 0.25
    positive amplitude_stddev 0.08
    positive Fadeout_duration_(seconds) 1.0
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Harmonic
    tail_duration = 1.0
    number_of_echoes = 30
    base_delay_seconds = 0.04
    decay_factor = 0.94
    harmonic_spread = 1.4
    amplitude_mean = 0.18
    amplitude_stddev = 0.05
    fadeout_duration = 0.8
elsif preset = 3
    # Medium Harmonic
    tail_duration = 1.5
    number_of_echoes = 48
    base_delay_seconds = 0.05
    decay_factor = 0.92
    harmonic_spread = 1.2
    amplitude_mean = 0.25
    amplitude_stddev = 0.08
    fadeout_duration = 1.0
elsif preset = 4
    # Heavy Harmonic
    tail_duration = 2.0
    number_of_echoes = 70
    base_delay_seconds = 0.06
    decay_factor = 0.9
    harmonic_spread = 1.0
    amplitude_mean = 0.32
    amplitude_stddev = 0.1
    fadeout_duration = 1.4
elsif preset = 5
    # Extreme Harmonic
    tail_duration = 3.0
    number_of_echoes = 100
    base_delay_seconds = 0.08
    decay_factor = 0.88
    harmonic_spread = 0.8
    amplitude_mean = 0.38
    amplitude_stddev = 0.12
    fadeout_duration = 1.8
endif

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

originalName$ = selected$("Sound")
select Sound 'originalName$'
sampling_rate = Get sample rate
channels = Get number of channels

# Create silent tail
if channels = 2
    Create Sound from formula: "silent_tail", 2, 0, tail_duration, sampling_rate, "0"
else
    Create Sound from formula: "silent_tail", 1, 0, tail_duration, sampling_rate, "0"
endif

# Concatenate
select Sound 'originalName$'
plus Sound silent_tail
Concatenate
Rename: "extended_sound"

select Sound extended_sound
Copy: originalName$ + "_harmonic_reverb"

for k from 1 to number_of_echoes
    harmonic_power = 1 / harmonic_spread
    harmonic_delay = base_delay_seconds * k^harmonic_power
    amplitude = decay_factor^k * randomGauss(amplitude_mean, amplitude_stddev)
    Formula: "self + amplitude * self(x - harmonic_delay)"
endfor

# Apply fadeout
select Sound 'originalName$'_harmonic_reverb
total_duration = Get total duration
fade_start = total_duration - fadeout_duration
Formula: "if x > fade_start then self * (0.5 + 0.5 * cos(pi * (x - fade_start) / 'fadeout_duration')) else self fi"

# Cleanup
select Sound silent_tail
plus Sound extended_sound
Remove

select Sound 'originalName$'_harmonic_reverb

if play_after_processing
    Play
endif