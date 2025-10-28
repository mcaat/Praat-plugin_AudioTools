# ============================================================
# Praat AudioTools - Logistic Map Synthesis.praat
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

form Logistic Map Synthesis
    optionmenu Preset: 1
        option Custom
        option Gentle Chaos
        option Wild Oscillations
        option Periodic Orbit
        option Edge of Chaos
        option Bifurcation Cascade
        option Strange Attractor
        option Intermittent Bursts
        option Harmonic Drift
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Random Pan
        option Binaural
    real Duration 6.0
    real Sampling_frequency 44100
    real Base_frequency 180
    real R_parameter 3.7
    real Initial_x 0.5
endform

echo Creating Logistic Map Synthesis...

# Apply presets
if preset > 1
    if preset = 2
        # Gentle Chaos
        r_parameter = 3.5
        base_frequency = 150
        initial_x = 0.3
        
    elsif preset = 3
        # Wild Oscillations
        r_parameter = 3.9
        base_frequency = 200
        initial_x = 0.1
        
    elsif preset = 4
        # Periodic Orbit
        r_parameter = 3.2
        base_frequency = 120
        initial_x = 0.7
        
    elsif preset = 5
        # Edge of Chaos
        r_parameter = 3.56995
        base_frequency = 170
        initial_x = 0.5
        
    elsif preset = 6
        # Bifurcation Cascade
        r_parameter = 3.55
        base_frequency = 140
        initial_x = 0.4
        
    elsif preset = 7
        # Strange Attractor
        r_parameter = 3.8
        base_frequency = 190
        initial_x = 0.2
        
    elsif preset = 8
        # Intermittent Bursts
        r_parameter = 3.828
        base_frequency = 160
        initial_x = 0.6
        
    elsif preset = 9
        # Harmonic Drift
        r_parameter = 3.0
        base_frequency = 110
        initial_x = 0.8
    endif
endif

echo Using preset: 'preset'

control_rate = 100
time_step = 1/control_rate
total_points = round(duration * control_rate)
formula$ = "0"

logistic_x = initial_x

for i to total_points
    current_time = (i-1) * time_step
    
    logistic_x = r_parameter * logistic_x * (1 - logistic_x)
    current_freq = base_frequency * (0.5 + logistic_x)
    current_amp = 0.6 * logistic_x
    
    if current_time + time_step > duration
        current_dur = duration - current_time
    else
        current_dur = time_step
    endif
    
    if current_dur > 0.001
        segment_formula$ = "if x >= " + string$(current_time) + " and x < " + string$(current_time + current_dur)
        segment_formula$ = segment_formula$ + " then " + string$(current_amp)
        segment_formula$ = segment_formula$ + " * sin(2*pi*" + string$(current_freq) + "*x)"
        segment_formula$ = segment_formula$ + " else 0 fi"
        
        if formula$ = "0"
            formula$ = segment_formula$
        else
            formula$ = formula$ + " + " + segment_formula$
        endif
    endif
    
    if i mod 100 = 0
        echo Processed 'i'/'total_points' points, x='logistic_x:3'
    endif
endfor

Create Sound from formula: "logistic_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# ====== SPATIAL PROCESSING ======
select Sound logistic_output

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "logistic_map_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO WIDE - Spread chaotic frequencies
    Copy: "logistic_left"
    left_sound = selected("Sound")
    
    select Sound logistic_output
    Copy: "logistic_right" 
    right_sound = selected("Sound")
    
    # Left channel: emphasize lower chaotic frequencies
    select left_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 0, 3000, 100
    
    # Right channel: emphasize higher chaotic frequencies
    select right_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 200, 6000, 100
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "logistic_map_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    # RANDOM PAN - Chaotic panning movement
    Copy: "logistic_left"
    left_sound = selected("Sound")
    
    select Sound logistic_output
    Copy: "logistic_right"
    right_sound = selected("Sound")
    
    # Apply chaotic panning using logistic map-like movement
    pan_rate = 2.0
    select left_sound
    Formula: "self * (0.4 + 0.4 * sin(2*pi*pan_rate*x + 0.5*sin(2*pi*0.7*x)))"
    
    select right_sound
    Formula: "self * (0.4 + 0.4 * cos(2*pi*pan_rate*x + 0.5*sin(2*pi*0.7*x)))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "logistic_map_random_pan"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL - 3D chaotic space
    Copy: "logistic_left"
    left_sound = selected("Sound")
    
    select Sound logistic_output
    Copy: "logistic_right"
    right_sound = selected("Sound")
    
    # Left channel: warm chaotic texture
    select left_sound
    Filter (pass Hann band): 50, 3500, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.3))"
    
    # Right channel: bright chaotic texture with slight delay
    select right_sound
    # Small phase shift for binaural effect
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.4))"
    Filter (pass Hann band): 100, 5000, 80
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "logistic_map_binaural"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

select output_sound
Play

echo Logistic Map Synthesis complete!
echo Preset: 'preset'
echo Spatial mode: 'spatial_mode'
echo R parameter: 'r_parameter:4'
echo Final x value: 'logistic_x:4'