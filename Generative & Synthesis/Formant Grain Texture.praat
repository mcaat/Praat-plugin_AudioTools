# ============================================================
# Praat AudioTools - Formant Grain Texture.praat
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

form Formant Grain Texture
    optionmenu Preset: 1
        option Custom
        option Vowel Cloud
        option Whisper Choir
        option Robotic Speech
        option Alien Language
        option Gregorian Chant
        option Baby Babble
        option Synthetic Singing
        option Ghost Voices
        option Formant Storm
        option Vocal Cascade
        option Harmonic Rain
        option Spectral Whisper
        option Glitch Vocals
        option Formant Echo
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Choir
        option Rotating Voices
        option Binaural Whisper
        option Wide Cloud
        option Ping Pong
    real Duration 5.0
    real Sampling_frequency 44100
    real Grain_density 25.0
    real Base_frequency 100
endform

echo Creating Formant Grain Texture...

# Apply presets
if preset > 1
    if preset = 2
        # Vowel Cloud
        grain_density = 20
        base_frequency = 120
        
    elsif preset = 3
        # Whisper Choir
        grain_density = 15
        base_frequency = 180
        
    elsif preset = 4
        # Robotic Speech
        grain_density = 35
        base_frequency = 80
        
    elsif preset = 5
        # Alien Language
        grain_density = 30
        base_frequency = 140
        
    elsif preset = 6
        # Gregorian Chant
        grain_density = 12
        base_frequency = 90
        
    elsif preset = 7
        # Baby Babble
        grain_density = 40
        base_frequency = 250
        
    elsif preset = 8
        # Synthetic Singing
        grain_density = 25
        base_frequency = 130
        
    elsif preset = 9
        # Ghost Voices
        grain_density = 8
        base_frequency = 160
        
    elsif preset = 10
        # Formant Storm
        grain_density = 50
        base_frequency = 110
        
    elsif preset = 11
        # Vocal Cascade
        grain_density = 18
        base_frequency = 140
        
    elsif preset = 12
        # Harmonic Rain
        grain_density = 22
        base_frequency = 95
        
    elsif preset = 13
        # Spectral Whisper
        grain_density = 10
        base_frequency = 170
        
    elsif preset = 14
        # Glitch Vocals
        grain_density = 45
        base_frequency = 200
        
    elsif preset = 15
        # Formant Echo
        grain_density = 28
        base_frequency = 125
    endif
endif

echo Using preset: 'preset'

total_grains = round(duration * grain_density)
formula$ = "0"

for grain to total_grains
    grain_time = randomUniform(0, duration - 0.2)
    
    # Preset-specific vowel distributions
    if preset = 2
        # Vowel Cloud - balanced mix
        vowel_choice = randomInteger(1, 5)
        
    elsif preset = 3
        # Whisper Choir - mostly A, O, U
        r = randomUniform(0,1)
        if r < 0.4
            vowel_choice = 1
        elsif r < 0.7
            vowel_choice = 3
        else
            vowel_choice = 5
        endif
        
    elsif preset = 4
        # Robotic Speech - precise I, E
        r = randomUniform(0,1)
        if r < 0.5
            vowel_choice = 2
        else
            vowel_choice = 4
        endif
        
    elsif preset = 5
        # Alien Language - extreme formants
        vowel_choice = randomInteger(1, 5)
        # Apply formant shifts for alien sound
        formant_shift = 1.0 + randomUniform(-0.3, 0.5)
        
    elsif preset = 6
        # Gregorian Chant - deep A, O, U
        r = randomUniform(0,1)
        if r < 0.4
            vowel_choice = 1
        elsif r < 0.7
            vowel_choice = 3
        else
            vowel_choice = 5
        endif
        
    elsif preset = 7
        # Baby Babble - bright vowels
        vowel_choice = randomInteger(1, 5)
        
    elsif preset = 8
        # Synthetic Singing - melodic vowels
        r = randomUniform(0,1)
        if r < 0.3
            vowel_choice = 1
        elsif r < 0.5
            vowel_choice = 4
        elsif r < 0.7
            vowel_choice = 5
        else
            vowel_choice = 2
        endif
        
    elsif preset = 9
        # Ghost Voices - sparse, ethereal
        r = randomUniform(0,1)
        if r < 0.6
            vowel_choice = 3
        else
            vowel_choice = 2
        endif
        
    else
        # Default balanced distribution
        vowel_choice = randomInteger(1, 5)
    endif
    
    # Set formant frequencies based on vowel choice
    if vowel_choice = 1
        f1 = 730
        f2 = 1090
        f3 = 2440
    elsif vowel_choice = 2
        f1 = 270
        f2 = 2290
        f3 = 3010
    elsif vowel_choice = 3
        f1 = 300
        f2 = 870
        f3 = 2240
    elsif vowel_choice = 4
        f1 = 530
        f2 = 1840
        f3 = 2480
    else
        f1 = 570
        f2 = 840
        f3 = 2410
    endif
    
    # Apply alien formant shifts if needed
    if preset = 5 and randomUniform(0,1) > 0.7
        f1 = f1 * (0.7 + randomUniform(0,0.6))
        f2 = f2 * (1.0 + randomUniform(0,0.8))
        f3 = f3 * (1.2 + randomUniform(0,0.5))
    endif
    
    # Preset-specific grain parameters
    if preset = 3
        grain_dur = 0.08 + 0.15 * randomUniform(0,1)
        grain_amp = 0.4 + 0.3 * randomUniform(0,1)
    elsif preset = 6
        grain_dur = 0.12 + 0.25 * randomUniform(0,1)
        grain_amp = 0.5 + 0.3 * randomUniform(0,1)
    elsif preset = 7
        grain_dur = 0.03 + 0.06 * randomUniform(0,1)
        grain_amp = 0.6 + 0.3 * randomUniform(0,1)
    elsif preset = 9
        grain_dur = 0.15 + 0.3 * randomUniform(0,1)
        grain_amp = 0.3 + 0.2 * randomUniform(0,1)
    elsif preset = 10
        grain_dur = 0.02 + 0.05 * randomUniform(0,1)
        grain_amp = 0.7 + 0.2 * randomUniform(0,1)
    else
        grain_dur = 0.05 + 0.1 * randomUniform(0,1)
        grain_amp = 0.8
    endif
    
    if grain_time + grain_dur > duration
        grain_dur = duration - grain_time
    endif
    
    if grain_dur > 0.001
        grain_formula$ = "if x >= " + string$(grain_time) + " and x < " + string$(grain_time + grain_dur)
        grain_formula$ = grain_formula$ + " then " + string$(grain_amp)
        grain_formula$ = grain_formula$ + " * (0.3*sin(2*pi*" + string$(base_frequency) + "*x) + "
        grain_formula$ = grain_formula$ + "0.5*sin(2*pi*" + string$(f1) + "*x) + "
        grain_formula$ = grain_formula$ + "0.4*sin(2*pi*" + string$(f2) + "*x) + "
        grain_formula$ = grain_formula$ + "0.3*sin(2*pi*" + string$(f3) + "*x))"
        grain_formula$ = grain_formula$ + " * (1 - cos(2*pi*(x-" + string$(grain_time) + ")/" + string$(grain_dur) + "))/2"
        grain_formula$ = grain_formula$ + " else 0 fi"
        
        if formula$ = "0"
            formula$ = grain_formula$
        else
            formula$ = formula$ + " + " + grain_formula$
        endif
    endif
    
    if grain mod 50 = 0
        echo Generated 'grain'/'total_grains' grains
    endif
endfor

Create Sound from formula: "formant_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# ====== SPATIAL PROCESSING ======
select Sound formant_output

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "formant_grains_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO CHOIR - Creates choir-like spatialization
    Copy: "formant_left"
    left_sound = selected("Sound")
    
    select Sound formant_output
    Copy: "formant_right" 
    right_sound = selected("Sound")
    
    # Left channel: warmer vowels (A, O, U)
    select left_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 0, 2500, 120
    
    # Right channel: brighter vowels (I, E)
    select right_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 150, 4000, 120
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "formant_grains_choir"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING VOICES - Voices move around listener
    Copy: "formant_left"
    left_sound = selected("Sound")
    
    select Sound formant_output
    Copy: "formant_right"
    right_sound = selected("Sound")
    
    # Apply rotating panning
    rotation_rate = 0.12
    select left_sound
    Formula: "self * (0.5 + 0.4 * cos(2*pi*rotation_rate*x))"
    
    select right_sound
    Formula: "self * (0.5 + 0.4 * sin(2*pi*rotation_rate*x))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "formant_grains_rotating"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL WHISPER - Intimate, close spatialization
    Copy: "formant_left"
    left_sound = selected("Sound")
    
    select Sound formant_output
    Copy: "formant_right"
    right_sound = selected("Sound")
    
    # Left channel: close, intimate
    select left_sound
    Filter (pass Hann band): 100, 3000, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.2))"
    
    # Right channel: slightly different character
    select right_sound
    Filter (pass Hann band): 80, 3500, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.25))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "formant_grains_binaural"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 5
    # WIDE CLOUD - Very wide stereo spread
    Copy: "formant_left"
    left_sound = selected("Sound")
    
    select Sound formant_output
    Copy: "formant_right" 
    right_sound = selected("Sound")
    
    # Extreme frequency separation for wide image
    select left_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 2000, 150
    
    select right_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 300, 6000, 150
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "formant_grains_wide"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 6
    # PING PONG - Alternating left-right movement
    Copy: "formant_left"
    left_sound = selected("Sound")
    
    select Sound formant_output
    Copy: "formant_right"
    right_sound = selected("Sound")
    
    # Fast alternating panning
    pan_rate = 3.0
    select left_sound
    Formula: "self * (0.3 + 0.5 * abs(sin(2*pi*pan_rate*x)))"
    
    select right_sound
    Formula: "self * (0.3 + 0.5 * abs(cos(2*pi*pan_rate*x)))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "formant_grains_pingpong"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

select output_sound
Play

echo Formant Grain Texture complete!
echo Preset: 'preset'
echo Spatial mode: 'spatial_mode'
echo Total grains: 'total_grains'