# ============================================================
# Praat AudioTools - Dynamic Stochastic Synthesis.praat
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

form Dynamic Stochastic Synthesis
    optionmenu Preset: 1
        option Custom
        option Gentle Bloom
        option Storm Build
        option Cosmic Drift
        option Digital Cascade
        option Organic Growth
        option Harmonic Swarm
        option Metallic Storm
        option Whisper Cloud
        option Industrial Evolution
        option Spectral Migration
        option Chaotic Expansion
        option Rhythmic Pulse
        option Glacial Drift
        option Quantum Foam
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Evolution
        option Rotating Cloud
        option Binaural Space
        option Wide Field
        option Panning Growth
    real Duration 6.0
    real Sampling_frequency 44100
    real Base_frequency 120
    real Initial_density 30
    real Final_density 150
    real Frequency_evolution_speed 1.0
endform

echo Building dynamic stochastic formula...

# Apply presets
if preset > 1
    if preset = 2
        # Gentle Bloom
        base_frequency = 80
        initial_density = 15
        final_density = 60
        frequency_evolution_speed = 0.5
        
    elsif preset = 3
        # Storm Build
        base_frequency = 100
        initial_density = 20
        final_density = 200
        frequency_evolution_speed = 1.2
        
    elsif preset = 4
        # Cosmic Drift
        base_frequency = 60
        initial_density = 10
        final_density = 80
        frequency_evolution_speed = 2.0
        
    elsif preset = 5
        # Digital Cascade
        base_frequency = 180
        initial_density = 40
        final_density = 180
        frequency_evolution_speed = 1.5
        
    elsif preset = 6
        # Organic Growth
        base_frequency = 90
        initial_density = 25
        final_density = 100
        frequency_evolution_speed = 0.8
        
    elsif preset = 7
        # Harmonic Swarm
        base_frequency = 110
        initial_density = 35
        final_density = 120
        frequency_evolution_speed = 1.0
        
    elsif preset = 8
        # Metallic Storm
        base_frequency = 140
        initial_density = 50
        final_density = 250
        frequency_evolution_speed = 1.8
        
    elsif preset = 9
        # Whisper Cloud
        base_frequency = 70
        initial_density = 8
        final_density = 40
        frequency_evolution_speed = 0.3
        
    elsif preset = 10
        # Industrial Evolution
        base_frequency = 85
        initial_density = 60
        final_density = 300
        frequency_evolution_speed = 1.3
        
    elsif preset = 11
        # Spectral Migration
        base_frequency = 130
        initial_density = 30
        final_density = 140
        frequency_evolution_speed = 1.1
        
    elsif preset = 12
        # Chaotic Expansion
        base_frequency = 95
        initial_density = 45
        final_density = 220
        frequency_evolution_speed = 2.2
        
    elsif preset = 13
        # Rhythmic Pulse
        base_frequency = 125
        initial_density = 20
        final_density = 90
        frequency_evolution_speed = 0.7
        
    elsif preset = 14
        # Glacial Drift
        base_frequency = 55
        initial_density = 5
        final_density = 35
        frequency_evolution_speed = 0.4
        
    elsif preset = 15
        # Quantum Foam
        base_frequency = 200
        initial_density = 70
        final_density = 280
        frequency_evolution_speed = 2.5
    endif
endif

echo Using preset: 'preset'

total_grains = round((initial_density + final_density)/2 * duration)
formula$ = "0"

for i to total_grains
    t = randomUniform(0, duration)
    normalized_time = t / duration
    
    current_density = initial_density + (final_density - initial_density) * normalized_time
    current_freq = base_frequency * (2^(frequency_evolution_speed * normalized_time))
    
    # Preset-specific grain characteristics
    if preset = 2
        grain_freq = current_freq * (0.9 + 0.2 * randomUniform(0,1))
        grain_amp = 0.4 * (1 - normalized_time^0.5)
        grain_duration = 0.03 + 0.08 * randomUniform(0,1)
    elsif preset = 3
        grain_freq = current_freq * (0.7 + 0.6 * randomUniform(0,1))
        grain_amp = 0.7 * (1 - normalized_time^0.8)
        grain_duration = 0.01 + 0.04 * randomUniform(0,1)
    elsif preset = 4
        grain_freq = current_freq * (0.5 + 1.0 * randomUniform(0,1))
        grain_amp = 0.5 * (1 - normalized_time^0.3)
        grain_duration = 0.05 + 0.12 * randomUniform(0,1)
    elsif preset = 9
        grain_freq = current_freq * (0.8 + 0.3 * randomUniform(0,1))
        grain_amp = 0.3 * (1 - normalized_time^0.6)
        grain_duration = 0.04 + 0.10 * randomUniform(0,1)
    elsif preset = 14
        grain_freq = current_freq * (0.6 + 0.5 * randomUniform(0,1))
        grain_amp = 0.4 * (1 - normalized_time^0.2)
        grain_duration = 0.08 + 0.20 * randomUniform(0,1)
    else
        grain_freq = current_freq * (0.8 + 0.4 * randomUniform(0,1))
        grain_amp = 0.6 * (1 - normalized_time^0.7)
        grain_duration = 0.02 + 0.06 * randomUniform(0,1)
    endif
    
    grain_start = t
    grain_end = grain_start + grain_duration
    
    if grain_end > duration
        grain_duration = duration - grain_start
        grain_end = duration
    endif
    
    grain_formula$ = "if x >= " + string$(grain_start) + " and x < " + string$(grain_end)
    grain_formula$ = grain_formula$ + " then " + string$(grain_amp)
    grain_formula$ = grain_formula$ + " * sin(2*pi*" + string$(grain_freq) + "*x)"
    grain_formula$ = grain_formula$ + " * sin(pi*(x-" + string$(grain_start) + ")/" + string$(grain_duration) + ")"
    grain_formula$ = grain_formula$ + " else 0 fi"
    
    if i = 1
        formula$ = grain_formula$
    else
        formula$ = formula$ + " + " + grain_formula$
    endif
    
    if i mod 100 = 0
        echo Added 'i' of 'total_grains' grains...
    endif
endfor

echo Creating final sound...
Create Sound from formula: "stochastic_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# ====== SPATIAL PROCESSING ======
select Sound stochastic_output

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "stochastic_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO EVOLUTION - Spatialization evolves with density
    Copy: "stochastic_left"
    left_sound = selected("Sound")
    
    select Sound stochastic_output
    Copy: "stochastic_right" 
    right_sound = selected("Sound")
    
    # Left channel: evolves from dominant to subtle
    select left_sound
    Formula: "self * (0.8 - 0.3 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 0, 3500, 100
    
    # Right channel: evolves from subtle to dominant
    select right_sound
    Formula: "self * (0.5 + 0.3 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 100, 6000, 100
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "stochastic_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING CLOUD - Grain cloud rotates around listener
    Copy: "stochastic_left"
    left_sound = selected("Sound")
    
    select Sound stochastic_output
    Copy: "stochastic_right"
    right_sound = selected("Sound")
    
    # Apply rotating panning that speeds up
    rotation_rate = 0.1
    select left_sound
    Formula: "self * (0.5 + 0.4 * cos(2*pi*rotation_rate*x * (1 + x/" + string$(duration) + ")))"
    
    select right_sound
    Formula: "self * (0.5 + 0.4 * sin(2*pi*rotation_rate*x * (1 + x/" + string$(duration) + ")))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "stochastic_rotating"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL SPACE - 3D evolving stochastic field
    Copy: "stochastic_left"
    left_sound = selected("Sound")
    
    select Sound stochastic_output
    Copy: "stochastic_right"
    right_sound = selected("Sound")
    
    # Left channel: warm evolving texture
    select left_sound
    Filter (pass Hann band): 50, 4000, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.15))"
    
    # Right channel: bright evolving texture
    select right_sound
    Filter (pass Hann band): 80, 5000, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.2))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "stochastic_binaural"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 5
    # WIDE FIELD - Extreme stereo width that grows
    Copy: "stochastic_left"
    left_sound = selected("Sound")
    
    select Sound stochastic_output
    Copy: "stochastic_right" 
    right_sound = selected("Sound")
    
    # Left channel: low frequencies, decreasing
    select left_sound
    Formula: "self * (0.7 - 0.2 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 0, 2000, 120
    
    # Right channel: high frequencies, increasing
    select right_sound
    Formula: "self * (0.5 + 0.3 * (x/" + string$(duration) + "))"
    Filter (pass Hann band): 200, 7000, 120
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "stochastic_wide"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 6
    # PANNING GROWTH - Panning evolves with density growth
    Copy: "stochastic_left"
    left_sound = selected("Sound")
    
    select Sound stochastic_output
    Copy: "stochastic_right"
    right_sound = selected("Sound")
    
    # Panning evolves from left to center to right
    select left_sound
    Formula: "self * (0.6 + 0.3 * cos(pi * x/" + string$(duration) + "))"
    
    select right_sound
    Formula: "self * (0.6 + 0.3 * sin(pi * x/" + string$(duration) + "))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "stochastic_panning"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

select output_sound
Play

echo Dynamic Stochastic Synthesis complete!
echo Preset: 'preset'
echo Spatial mode: 'spatial_mode'
echo Total grains: 'total_grains'