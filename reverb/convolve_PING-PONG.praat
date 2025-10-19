# ============================================================
# Praat AudioTools - convolve_PING-PONG.praat
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

form Bursts and Sparse Taps Convolution
    comment This script creates sparse taps plus clustered bursts
    optionmenu Preset 1
        option Custom
        option Subtle Bursts
        option Medium Bursts
        option Heavy Bursts
        option Extreme Bursts
    positive duration_seconds 1.8
    comment Sparse tap times:
    positive tap_1_time 0.15
    positive tap_2_time 1.20
    comment Burst parameters:
    natural number_of_bursts 3
    natural points_per_burst 10
    positive burst_stddev 0.035
    comment (Gaussian spread of burst cluster)
    positive burst_min_time 0.3
    comment (margin from edges)
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
    # Subtle Bursts
    duration_seconds = 1.5
    tap_1_time = 0.12
    tap_2_time = 1.0
    number_of_bursts = 2
    points_per_burst = 6
    burst_stddev = 0.025
    burst_min_time = 0.25
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.018
    pulse_period = 2200
elsif preset = 3
    # Medium Bursts
    duration_seconds = 1.8
    tap_1_time = 0.15
    tap_2_time = 1.20
    number_of_bursts = 3
    points_per_burst = 10
    burst_stddev = 0.035
    burst_min_time = 0.3
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.02
    pulse_period = 2000
elsif preset = 4
    # Heavy Bursts
    duration_seconds = 2.5
    tap_1_time = 0.18
    tap_2_time = 1.80
    number_of_bursts = 5
    points_per_burst = 15
    burst_stddev = 0.050
    burst_min_time = 0.35
    sampling_frequency = 44100
    pulse_amplitude = 1
    pulse_width = 0.025
    pulse_period = 1800
elsif preset = 5
    # Extreme Bursts
    duration_seconds = 3.5
    tap_1_time = 0.20
    tap_2_time = 2.80
    number_of_bursts = 8
    points_per_burst = 25
    burst_stddev = 0.080
    burst_min_time = 0.4
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
# Create point pattern with sparse taps and bursts
Create empty PointProcess: "pp_bursts", 0, duration_seconds
selectObject: "PointProcess pp_bursts"
# Add sparse taps
Add point: tap_1_time
Add point: tap_2_time
# Add bursts
b = 1
while b <= number_of_bursts
    c = randomUniform(burst_min_time, duration_seconds - burst_min_time)
    i = 1
    while i <= points_per_burst
        u = c + randomGauss(0, burst_stddev)
        if u > 0 and u < duration_seconds
            Add point: u
        endif
        i = i + 1
    endwhile
    b = b + 1
endwhile
# Convert to pulse train
To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
Rename: "impulse_bursts"
Scale peak: 0.99
# Convolve
selectObject: "Sound XXXX"
plusObject: "Sound impulse_bursts"
Convolve: "peak 0.99", "zero"
Rename: originalName$ + "_bursts_taps"
if play_after_processing
    Play
endif
# Cleanup - including the resampled XXXX file
selectObject: "Sound XXXX"
plusObject: "PointProcess pp_bursts"
plusObject: "Sound impulse_bursts"
# Also remove the XXXX_44100 file created by Resample
if numberOfSelected("Sound") > 0
    select all
    minus Sound 'originalName$'
    minus Sound 'originalName$'_bursts_taps
    Remove
endif
selectObject: "Sound " + originalName$ + "_bursts_taps"