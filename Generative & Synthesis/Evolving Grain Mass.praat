# ============================================================
# Praat AudioTools - Evolving Grain Mass.praat
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

form Evolving Grain Mass
    optionmenu Preset: 1
        option Custom
        option Cloud Formation
        option Rising Mist
        option Storm Build
        option Cosmic Drift
        option Industrial Growth
        option Organic Bloom
        option Digital Cascade
        option Harmonic Evolution
        option Textural Shift
        option Density Wave
        option Frequency Storm
        option Granular Swarm
        option Spectral Migration
        option Chaotic Bloom
        option Rhythmic Pulse
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Evolution
        option Rotating Cloud
        option Binaural Space
        option Wide Field
        option Panning Growth
    real Duration 5.0
    real Sampling_frequency 44100
    real Initial_density 20.0
    real Final_density 60.0
    real Base_frequency 120
    real Frequency_evolution 2.0
    optionmenu Evolution_type: 1
        option Density_growth
        option Frequency_sweep
        option Statistical_shift
endform

echo Creating Evolving Grain Mass...

# Apply presets
if preset > 1
    if preset = 2
        # Cloud Formation
        initial_density = 10
        final_density = 40
        base_frequency = 80
        evolution_type = 1
        
    elsif preset = 3
        # Rising Mist
        initial_density = 5
        final_density = 25
        base_frequency = 150
        frequency_evolution = 1.5
        evolution_type = 2
        
    elsif preset = 4
        # Storm Build
        initial_density = 15
        final_density = 80
        base_frequency = 100
        evolution_type = 1
        
    elsif preset = 5
        # Cosmic Drift
        initial_density = 8
        final_density = 30
        base_frequency = 60
        frequency_evolution = 3.0
        evolution_type = 2
        
    elsif preset = 6
        # Industrial Growth
        initial_density = 30
        final_density = 100
        base_frequency = 80
        evolution_type = 1
        
    elsif preset = 7
        # Organic Bloom
        initial_density = 12
        final_density = 35
        base_frequency = 110
        evolution_type = 3
        
    elsif preset = 8
        # Digital Cascade
        initial_density = 25
        final_density = 70
        base_frequency = 200
        evolution_type = 3
        
    elsif preset = 9
        # Harmonic Evolution
        initial_density = 18
        final_density = 45
        base_frequency = 130
        frequency_evolution = 2.5
        evolution_type = 2
        
    elsif preset = 10
        # Textural Shift
        initial_density = 20
        final_density = 50
        base_frequency = 90
        evolution_type = 3
        
    elsif preset = 11
        # Density Wave
        initial_density = 15
        final_density = 65
        base_frequency = 140
        evolution_type = 1
        
    elsif preset = 12
        # Frequency Storm
        initial_density = 35
        final_density = 85
        base_frequency = 70
        frequency_evolution = 4.0
        evolution_type = 2
        
    elsif preset = 13
        # Granular Swarm
        initial_density = 40
        final_density = 120
        base_frequency = 160
        evolution_type = 1
        
    elsif preset = 14
        # Spectral Migration
        initial_density = 22
        final_density = 55
        base_frequency = 180
        evolution_type = 3
        
    elsif preset = 15
        # Chaotic Bloom
        initial_density = 8
        final_density = 45
        base_frequency = 95
        evolution_type = 3
        
    elsif preset = 16
        # Rhythmic Pulse
        initial_density = 25
        final_density = 75
        base_frequency = 110
        evolution_type = 1
    endif
endif

echo Using preset: 'preset'

total_grains = round(((initial_density + final_density)/2) * duration)
formula$ = "0"

if evolution_type = 1
    call DensityGrowth
elsif evolution_type = 2
    call FrequencySweep
else
    call StatisticalShift
endif

Create Sound from formula: "grain_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# ====== SPATIAL PROCESSING ======
select Sound grain_output

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "evolving_grains_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO EVOLUTION - Spatialization evolves over time
    Copy: "grain_left"
    left_sound = selected("Sound")
    
    select Sound grain_output
    Copy: "grain_right" 
    right_sound = selected("Sound")
    
    # Left channel: evolves from low to high frequencies
    select left_sound
    Formula: "self * (0.7 + 0.2 * (1 - x/" + string$(duration) + "))"
    Filter (pass Hann band): 0, 3000, 100
    
    # Right channel: evolves from high to low frequencies
    select right_sound
    Formula: "self * (0.7 + 0.2 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 200, 5000, 100
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "evolving_grains_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING CLOUD - Grain cloud rotates around listener
    Copy: "grain_left"
    left_sound = selected("Sound")
    
    select Sound grain_output
    Copy: "grain_right"
    right_sound = selected("Sound")
    
    # Apply rotating panning that evolves
    rotation_rate = 0.08
    select left_sound
    Formula: "self * (0.5 + 0.4 * cos(2*pi*rotation_rate*x * (1 + x/" + string$(duration) + ")))"
    
    select right_sound
    Formula: "self * (0.5 + 0.4 * sin(2*pi*rotation_rate*x * (1 + x/" + string$(duration) + ")))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "evolving_grains_rotating"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL SPACE - 3D evolving space
    Copy: "grain_left"
    left_sound = selected("Sound")
    
    select Sound grain_output
    Copy: "grain_right"
    right_sound = selected("Sound")
    
    # Left channel: evolving spectral character
    select left_sound
    Filter (pass Hann band): 50, 3500, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.2 * (1 + x/" + string$(duration*2) + ")))"
    
    # Right channel: complementary evolution
    select right_sound
    Filter (pass Hann band): 100, 4500, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.25 * (1 + x/" + string$(duration*2) + ")))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "evolving_grains_binaural"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 5
    # WIDE FIELD - Extreme stereo width that evolves
    Copy: "grain_left"
    left_sound = selected("Sound")
    
    select Sound grain_output
    Copy: "grain_right" 
    right_sound = selected("Sound")
    
    # Left channel: starts narrow, becomes very wide
    select left_sound
    Formula: "self * (0.6 + 0.3 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 0, 2500, 120
    
    # Right channel: complementary evolution
    select right_sound
    Formula: "self * (0.6 + 0.3 * (1 - x/" + string$(duration) + "))"
    Filter (pass Hann band): 150, 6000, 120
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "evolving_grains_wide"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 6
    # PANNING GROWTH - Panning evolves with density
    Copy: "grain_left"
    left_sound = selected("Sound")
    
    select Sound grain_output
    Copy: "grain_right"
    right_sound = selected("Sound")
    
    # Panning evolves from center to wide
    select left_sound
    Formula: "self * (0.4 + 0.4 * (1 - x/" + string$(duration) + "))"
    
    select right_sound
    Formula: "self * (0.4 + 0.4 * (x/" + string$(duration) + "))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "evolving_grains_panning"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

select output_sound
Play

echo Evolving Grain Mass complete!
echo Preset: 'preset'
echo Spatial mode: 'spatial_mode'
echo Evolution type: 'evolution_type'
echo Total grains: 'total_grains'

procedure DensityGrowth
    for grain to total_grains
        normalized_time = (grain-1) / total_grains
        current_density = initial_density + (final_density - initial_density) * normalized_time
        
        grain_time = randomUniform(0, duration)
        grain_freq = base_frequency + 200 * randomGauss(0,1)
        grain_dur = 0.05 + 0.1 * randomUniform(0,1)
        grain_amp = 0.6
        
        time_probability = current_density / ((initial_density + final_density)/2)
        
        if randomUniform(0,1) < time_probability and grain_time + grain_dur <= duration
            grain_formula$ = "if x >= " + string$(grain_time) + " and x < " + string$(grain_time + grain_dur)
            grain_formula$ = grain_formula$ + " then " + string$(grain_amp)
            grain_formula$ = grain_formula$ + " * sin(2*pi*" + string$(grain_freq) + "*x)"
            grain_formula$ = grain_formula$ + " * (1 - cos(2*pi*(x-" + string$(grain_time) + ")/" + string$(grain_dur) + "))/2"
            grain_formula$ = grain_formula$ + " else 0 fi"
            
            if formula$ = "0"
                formula$ = grain_formula$
            else
                formula$ = formula$ + " + " + grain_formula$
            endif
        endif
        
        if grain mod 200 = 0
            echo Processed 'grain'/'total_grains' grains
        endif
    endfor
endproc

procedure FrequencySweep
    for grain to total_grains
        grain_time = randomUniform(0, duration)
        normalized_time = grain_time / duration
        
        current_base_freq = base_frequency * (frequency_evolution ^ normalized_time)
        grain_freq = current_base_freq + 150 * randomGauss(0,1)
        grain_dur = 0.03 + 0.08 * randomUniform(0,1)
        grain_amp = 0.7 * (1 - normalized_time * 0.3)
        
        if grain_time + grain_dur <= duration
            grain_formula$ = "if x >= " + string$(grain_time) + " and x < " + string$(grain_time + grain_dur)
            grain_formula$ = grain_formula$ + " then " + string$(grain_amp)
            grain_formula$ = grain_formula$ + " * sin(2*pi*" + string$(grain_freq) + "*x)"
            grain_formula$ = grain_formula$ + " * sin(pi*(x-" + string$(grain_time) + ")/" + string$(grain_dur) + ")"
            grain_formula$ = grain_formula$ + " else 0 fi"
            
            if formula$ = "0"
                formula$ = grain_formula$
            else
                formula$ = formula$ + " + " + grain_formula$
            endif
        endif
    endfor
endproc

procedure StatisticalShift
    for grain to total_grains
        grain_time = randomUniform(0, duration)
        normalized_time = grain_time / duration
        
        if normalized_time < 0.33
            grain_freq = base_frequency + 100 * randomGauss(0,1)
            grain_dur = 0.1 + 0.15 * randomUniform(0,1)
            grain_amp = 0.8
        elsif normalized_time < 0.66
            grain_freq = base_frequency * 1.5 + 200 * randomUniform(0,1)
            grain_dur = 0.05 + 0.08 * randomUniform(0,1)
            grain_amp = 0.6
        else
            grain_freq = base_frequency * 2.0 + 300 * randomUniform(0,1)
            grain_dur = 0.02 + 0.04 * randomUniform(0,1)
            grain_amp = 0.4
        endif
        
        if grain_time + grain_dur <= duration
            grain_formula$ = "if x >= " + string$(grain_time) + " and x < " + string$(grain_time + grain_dur)
            grain_formula$ = grain_formula$ + " then " + string$(grain_amp)
            grain_formula$ = grain_formula$ + " * sin(2*pi*" + string$(grain_freq) + "*x)"
            grain_formula$ = grain_formula$ + " * (1 - cos(2*pi*(x-" + string$(grain_time) + ")/" + string$(grain_dur) + "))/2"
            grain_formula$ = grain_formula$ + " else 0 fi"
            
            if formula$ = "0"
                formula$ = grain_formula$
            else
                formula$ = formula$ + " + " + grain_formula$
            endif
        endif
    endfor
endproc