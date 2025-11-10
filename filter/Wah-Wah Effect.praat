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
form Wah-Wah Effect Parameters
    natural Number_of_segments 20
    real Frequency_min 300
    real Frequency_max 1500
    real Wah_speed 1.6
    real Bandwidth_min 300
    real Bandwidth_max 600
endform

soundName$ = selected$("Sound")

# Convert to mono first
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

# Create control matrix
Create simple Matrix... wah_control 'Number_of_segments' 2 0

for i from 1 to 'Number_of_segments'
    time = i / 'Number_of_segments'
    
    # Frequency sweep
    freq = 'Frequency_min' + ('Frequency_max' - 'Frequency_min') * (0.5 + 0.5 * sin(2 * pi * 'Wah_speed' * time))
    
    # Bandwidth modulation
    bw = 'Bandwidth_min' + ('Bandwidth_max' - 'Bandwidth_min') * (0.5 + 0.5 * sin(2 * pi * 1.5 * time))
    
    select Matrix wah_control
    Set value... i 1 freq
    Set value... i 2 bw
endfor

# Process left and right channels
for i from 1 to 'Number_of_segments'
    # Extract segment once
    select Sound 'soundName$'_mono
    startTime = (i-1) * segmentDuration
    endTime = i * segmentDuration
    Extract part... startTime endTime Hanning 1 yes
    segmentRMS = Get root-mean-square... 0 0
    Rename... segment_'i'
    
    # Make copy for right channel
    select Sound segment_'i'
    Copy... segment_'i'_copy
    
    # Get filter parameters
    select Matrix wah_control
    freq = Get value in cell... i 1
    bw = Get value in cell... i 2
    
    # Clamp bandwidth to valid range
    low = max(20, freq - bw/2)
    high = min(nyq - 50, freq + bw/2)
    if high <= low
        high = low + 50
    endif
    
    # Left channel (normal)
    select Sound segment_'i'
    Filter (pass Hann band)... low high 50
    # Safe normalization
    currentRMS = Get root-mean-square... 0 0
    if currentRMS < 1e-9
        scaleFactor = 1
    else
        scaleFactor = segmentRMS / currentRMS
    endif
    Formula... self * scaleFactor
    Rename... left_seg_'i'
    
    # Right channel (slightly offset frequency for stereo)
    offset_freq = freq * 1.1
    low_right = max(20, offset_freq - bw/2)
    high_right = min(nyq - 50, offset_freq + bw/2)
    if high_right <= low_right
        high_right = low_right + 50
    endif
    
    select Sound segment_'i'_copy
    Filter (pass Hann band)... low_right high_right 50
    # Safe normalization
    currentRMS = Get root-mean-square... 0 0
    if currentRMS < 1e-9
        scaleFactor = 1
    else
        scaleFactor = segmentRMS / currentRMS
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
Rename... 'soundName$'_wahwah_stereo

# Final normalization with stereo compensation
select Sound 'soundName$'_wahwah_stereo
currentRMS = Get root-mean-square... 0 0
scaleFactor = originalRMS / (currentRMS * sqrt(2))
Formula... self * scaleFactor

select Sound 'soundName$'_wahwah_stereo
Play

# Cleanup
select all
minus Sound 'soundName$'
minus Sound 'soundName$'_wahwah_stereo
Remove