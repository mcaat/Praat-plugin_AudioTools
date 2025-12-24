# ============================================================
# Praat AudioTools - Wah-Wah Effect.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Wah-Wah Effect
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Advanced Wah-Wah Effect
    natural Number_of_segments 20
    real Frequency_min 300
    real Frequency_max 1500
    real Wah_speed 1.6
    real Bandwidth_min 300
    real Bandwidth_max 600
    real Stereo_width 1.2
    real Intensity_modulation 1.0
endform

soundName$ = selected$("Sound")

# Convert input to mono for processing
select Sound 'soundName$'
Convert to mono
Rename... 'soundName$'_mono

# Store original RMS for normalization
select Sound 'soundName$'_mono
originalRMS = Get root-mean-square... 0 0
totalDuration = Get total duration
segmentDuration = totalDuration / 'Number_of_segments'
fs = Get sampling frequency
nyq = fs / 2

# Process left and right channels
for i from 1 to 'Number_of_segments'
    time = i / 'Number_of_segments'
    
    # Core modulation
    intensity = 0.5 + 'Intensity_modulation' * 0.5 * sin(2 * pi * 'Wah_speed' * time)
    base_freq = 'Frequency_min' + ('Frequency_max' - 'Frequency_min') * intensity
    base_bw = 'Bandwidth_min' + ('Bandwidth_max' - 'Bandwidth_min') * (0.5 + 0.5 * sin(2 * pi * 1.5 * time))
    
    # Left channel parameters
    freq_L = base_freq
    bw_L = base_bw
    gain_L = 0.8 * (0.7 + 0.3 * sin(2 * pi * 3 * time))
    
    # Right channel with stereo variations
    freq_R = base_freq * 'Stereo_width'
    bw_R = base_bw * (2.0 - 'Stereo_width')
    gain_R = 0.8 * (0.7 + 0.3 * cos(2 * pi * 3 * time))
    
    # Additional effect parameters
    envelope = 0.3 + 0.7 * (1 - abs(time - 0.5) * 2)
    
    # Extract segment
    select Sound 'soundName$'_mono
    startTime = (i-1) * segmentDuration
    endTime = i * segmentDuration
    Extract part... startTime endTime Hanning 1 yes
    segmentRMS = Get root-mean-square... 0 0
    Rename... segment_'i'
    
    # Make copy for right channel
    select Sound segment_'i'
    Copy... segment_'i'_copy
    
    # Left channel processing
    low_L = max(20, freq_L - bw_L/2)
    high_L = min(nyq - 50, freq_L + bw_L/2)
    if high_L <= low_L
        high_L = low_L + 50
    endif
    
    select Sound segment_'i'
    Filter (pass Hann band)... low_L high_L 50
    # Apply gain and envelope
    currentRMS = Get root-mean-square... 0 0
    if currentRMS < 1e-9
        scaleFactor = 1
    else
        scaleFactor = (segmentRMS / currentRMS) * gain_L * envelope
    endif
    Formula... self * scaleFactor
    Rename... left_seg_'i'
    
    # Right channel processing
    low_R = max(20, freq_R - bw_R/2)
    high_R = min(nyq - 50, freq_R + bw_R/2)
    if high_R <= low_R
        high_R = low_R + 50
    endif
    
    select Sound segment_'i'_copy
    Filter (pass Hann band)... low_R high_R 50
    # Apply gain and envelope
    currentRMS = Get root-mean-square... 0 0
    if currentRMS < 1e-9
        scaleFactor = 1
    else
        scaleFactor = (segmentRMS / currentRMS) * gain_R * envelope
    endif
    Formula... self * scaleFactor
    Rename... right_seg_'i'
endfor

# Create left channel
select Sound left_seg_1
for i from 2 to 'Number_of_segments'
    plus Sound left_seg_'i'
endfor
Concatenate
Rename... left_channel

# Create right channel  
select Sound right_seg_1
for i from 2 to 'Number_of_segments'
    plus Sound right_seg_'i'
endfor
Concatenate
Rename... right_channel

# Combine to stereo
select Sound left_channel
plus Sound right_channel
Combine to stereo
Rename... 'soundName$'_wahwah_advanced

# Play result
select Sound 'soundName$'_wahwah_advanced
Scale peak: 0.99
Play

# Cleanup - remove all intermediate objects
select Sound 'soundName$'_mono
for i from 1 to 'Number_of_segments'
    plus Sound segment_'i'
    plus Sound segment_'i'_copy
    plus Sound left_seg_'i'
    plus Sound right_seg_'i'
endfor
plus Sound left_channel
plus Sound right_channel
Remove