# ============================================================
# Praat AudioTools - Formant Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sound synthesis or generative algorithm script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Formant Synthesis Script for Praat
# This script creates synthetic vowel sounds using formant frequencies

# User-defined parameters
form Formant Synthesis Parameters
    optionmenu Preset: 1
        option Custom
        option Vowel A (ah)
        option Vowel E (eh)
        option Vowel I (ee)
        option Vowel O (oh)
        option Vowel U (oo)
        option Soprano A
        option Bass O
        option Child E
        option Robot Voice
        option Whisper
        option Singing
        option Choral
        option Formant Shift
        option Alien Voice
        option Underwater
    
    comment Basic settings:
    positive duration 3.0
    positive pitch 120
    positive sampling_frequency 44100
    
    comment Formant frequencies (Hz):
    positive f1 500
    positive f2 1500
    positive f3 2500
    positive f4 3500
    
    comment Formant bandwidths (Hz):
    positive bw1 50
    positive bw2 70
    positive bw3 110
    positive bw4 150
    
    comment Voice quality:
    positive voicing_amplitude 60
    boolean enable_vibrato 1
    positive vibrato_rate 6
    positive vibrato_depth 10
endform

# Apply presets
if preset > 1
    if preset = 2
        # Vowel A (ah)
        f1 = 730
        f2 = 1090
        f3 = 2440
        f4 = 3500
        bw1 = 40
        bw2 = 60
        bw3 = 100
        bw4 = 120
        
    elsif preset = 3
        # Vowel E (eh)
        f1 = 530
        f2 = 1840
        f3 = 2480
        f4 = 3500
        bw1 = 45
        bw2 = 65
        bw3 = 105
        bw4 = 125
        
    elsif preset = 4
        # Vowel I (ee)
        f1 = 270
        f2 = 2290
        f3 = 3010
        f4 = 3500
        bw1 = 35
        bw2 = 70
        bw3 = 110
        bw4 = 130
        
    elsif preset = 5
        # Vowel O (oh)
        f1 = 570
        f2 = 840
        f3 = 2410
        f4 = 3500
        bw1 = 50
        bw2 = 60
        bw3 = 100
        bw4 = 120
        
    elsif preset = 6
        # Vowel U (oo)
        f1 = 300
        f2 = 870
        f3 = 2240
        f4 = 3500
        bw1 = 40
        bw2 = 55
        bw3 = 95
        bw4 = 115
        
    elsif preset = 7
        # Soprano A
        f1 = 800
        f2 = 1150
        f3 = 2900
        f4 = 3900
        pitch = 260
        bw1 = 35
        bw2 = 50
        bw3 = 90
        bw4 = 110
        
    elsif preset = 8
        # Bass O
        f1 = 450
        f2 = 800
        f3 = 2830
        f4 = 3500
        pitch = 80
        bw1 = 60
        bw2 = 70
        bw3 = 120
        bw4 = 140
        
    elsif preset = 9
        # Child E
        f1 = 600
        f2 = 2000
        f3 = 2600
        f4 = 3800
        pitch = 300
        bw1 = 30
        bw2 = 55
        bw3 = 95
        bw4 = 115
        
    elsif preset = 10
        # Robot Voice
        f1 = 400
        f2 = 1200
        f3 = 2400
        f4 = 3200
        bw1 = 20
        bw2 = 30
        bw3 = 40
        bw4 = 50
        enable_vibrato = 0
        
    elsif preset = 11
        # Whisper
        f1 = 500
        f2 = 1500
        f3 = 2500
        f4 = 3500
        voicing_amplitude = 20
        enable_vibrato = 0
        bw1 = 80
        bw2 = 100
        bw3 = 150
        bw4 = 200
        
    elsif preset = 12
        # Singing
        f1 = 600
        f2 = 1200
        f3 = 2400
        f4 = 3600
        pitch = 220
        vibrato_depth = 15
        bw1 = 35
        bw2 = 55
        bw3 = 95
        bw4 = 115
        
    elsif preset = 13
        # Choral
        f1 = 550
        f2 = 1100
        f3 = 2350
        f4 = 3400
        bw1 = 45
        bw2 = 65
        bw3 = 105
        bw4 = 125
        vibrato_depth = 8
        
    elsif preset = 14
        # Formant Shift
        f1 = 900
        f2 = 1800
        f3 = 2800
        f4 = 4000
        bw1 = 25
        bw2 = 45
        bw3 = 85
        bw4 = 105
        
    elsif preset = 15
        # Alien Voice
        f1 = 200
        f2 = 3000
        f3 = 4000
        f4 = 5000
        pitch = 180
        bw1 = 15
        bw2 = 25
        bw3 = 35
        bw4 = 45
        enable_vibrato = 0
        
    elsif preset = 16
        # Underwater
        f1 = 350
        f2 = 950
        f3 = 2100
        f4 = 2800
        bw1 = 100
        bw2 = 150
        bw3 = 200
        bw4 = 250
        voicing_amplitude = 40
    endif
endif

echo Using preset: 'preset'

# Step 1: Create KlattGrid
klattGrid = Create KlattGrid: "synth", 0, duration, 6, 1, 1, 6, 1, 1, 1

# Step 2: Set pitch contour
selectObject: klattGrid
if enable_vibrato
    # Add proper vibrato with correct rate using more points
    vibrato_points = round(duration * vibrato_rate * 4)  
# 4 points per cycle
    if vibrato_points < 8
        vibrato_points = 8  
# Minimum points for smooth vibrato
    endif
    
    for point to vibrato_points
        time = (point - 1) * duration / (vibrato_points - 1)
        # Sine wave vibrato
        vibrato_offset = vibrato_depth * sin(2 * pi * vibrato_rate * time)
        current_pitch = pitch + vibrato_offset
        Add pitch point: time, current_pitch
    endfor
else
    Add pitch point: duration/2, pitch
endif

# Step 3: Set oral formant frequencies
selectObject: klattGrid
for i from 1 to 4
    f_val = f'i'
    Add oral formant frequency point: i, duration/2, f_val
endfor

# Step 4: Set oral formant bandwidths
selectObject: klattGrid
for i from 1 to 4
    bw_val = bw'i'
    Add oral formant bandwidth point: i, duration/2, bw_val
endfor

# Step 5: Set voicing amplitude
selectObject: klattGrid
Add voicing amplitude point: duration/2, voicing_amplitude

# Step 6: Synthesize sound
selectObject: klattGrid
To Sound
synthesized = selected("Sound")

# Step 7: Set sampling frequency
selectObject: synthesized
sampled_sound = Resample: sampling_frequency, 50

# Clean up and present result
selectObject: sampled_sound
Rename: "formant_synthesis"
Scale peak: 0.99

# Always play the sound
Play

# Clean up temporary objects
selectObject: klattGrid
plusObject: synthesized
Remove

# Select final output for inspection
selectObject: sampled_sound

# Print information
echo Formant synthesis complete!
echo Preset: 'preset'
echo Duration: 'duration' seconds
echo Pitch: 'pitch' Hz
echo Formants (Hz): F1='f1' F2='f2' F3='f3' F4='f4'
echo Vibrato: 'if enable_vibrato then "Yes ('vibrato_rate' Hz)" else "No" fi'