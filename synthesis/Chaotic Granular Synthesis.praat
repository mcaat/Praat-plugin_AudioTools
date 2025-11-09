# ============================================================
# Praat AudioTools - Chaotic Granular Synthesis.praat
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

form Advanced Chaotic Granular Synthesis System
    positive Duration_(sec) 10
    positive Base_frequency_(Hz) 120
    positive Grain_density_(grains/sec) 20
    integer Number_of_layers 3
    boolean Randomize_parameters 1
    positive Fade_time_(sec) 2
    optionmenu Synthesis_mode: 1
        option Logistic Map
        option Henon Map
        option Lorenz System
        option Ikeda Map
        option Mixed Chaos
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Rotating
        option Binaural
    boolean Normalize_output 1
endform

if number_of_layers > 8
    number_of_layers = 8
endif

sample_rate = 44100

echo Building Advanced Chaotic Granular Synthesis...

# Create base sound
Create Sound from formula: "gen_output", 1, 0, duration, sample_rate, "0"

if synthesis_mode = 1
    # Logistic Map
    for layer from 1 to number_of_layers
        if randomize_parameters
            r = 3.5 + 0.4 * randomUniform(0, 1)
            layer_density = grain_density * (0.7 + 0.6 * randomUniform(0, 1))
        else
            r = 3.7
            layer_density = grain_density
        endif
        
        chaos_x = 0.5
        total_grains = round(duration * layer_density)
        
        echo Layer 'layer': Generating 'total_grains' grains with Logistic Map
        
        for grain to total_grains
            grain_time = randomUniform(0, duration - 0.2)
            grain_dur = 0.05 + 0.1 * randomUniform(0, 1)
            
            chaos_x = r * chaos_x * (1 - chaos_x)
            grain_freq = base_frequency * (0.3 + 1.4 * chaos_x) * (1 + (layer - 1) * 0.2)
            grain_amp = 1.2 / number_of_layers
            
            call addGrainToOutput
        endfor
    endfor
    
elsif synthesis_mode = 2
    # Henon Map
    for layer from 1 to number_of_layers
        if randomize_parameters
            a = 1.2 + 0.4 * randomUniform(0, 1)
            b = 0.2 + 0.2 * randomUniform(0, 1)
            layer_density = grain_density * (0.8 + 0.4 * randomUniform(0, 1))
        else
            a = 1.4
            b = 0.3
            layer_density = grain_density
        endif
        
        chaos_x = 0.1
        chaos_y = 0.1
        total_grains = round(duration * layer_density)
        
        echo Layer 'layer': Generating 'total_grains' grains with Henon Map
        
        for grain to total_grains
            grain_time = randomUniform(0, duration - 0.2)
            grain_dur = 0.04 + 0.08 * randomUniform(0, 1)
            
            new_x = 1 - a * chaos_x * chaos_x + chaos_y
            chaos_y = b * chaos_x
            chaos_x = new_x
            grain_freq = base_frequency * (0.5 + chaos_x) * (1 + (layer - 1) * 0.25)
            grain_amp = 1.3 / number_of_layers
            
            call addGrainToOutput
        endfor
    endfor
    
elsif synthesis_mode = 3
    # Lorenz System (simplified)
    for layer from 1 to number_of_layers
        if randomize_parameters
            sigma = 8 + 4 * randomUniform(0, 1)
            layer_density = grain_density * (0.75 + 0.5 * randomUniform(0, 1))
        else
            sigma = 10
            layer_density = grain_density
        endif
        
        chaos_x = 0.1
        chaos_y = 0.0
        chaos_z = 0.0
        dt = 0.01
        total_grains = round(duration * layer_density)
        
        echo Layer 'layer': Generating 'total_grains' grains with Lorenz System
        
        for grain to total_grains
            grain_time = randomUniform(0, duration - 0.2)
            grain_dur = 0.06 + 0.12 * randomUniform(0, 1)
            
            # Simplified Lorenz update
            dx = sigma * (chaos_y - chaos_x) * dt
            dy = (chaos_x * (28 - chaos_z) - chaos_y) * dt
            dz = (chaos_x * chaos_y - 2.667 * chaos_z) * dt
            
            chaos_x = chaos_x + dx
            chaos_y = chaos_y + dy
            chaos_z = chaos_z + dz
            
            grain_freq = base_frequency * (0.5 + 0.5 * (chaos_x / 20 + 0.5)) * (1 + (layer - 1) * 0.3)
            grain_amp = 1.4 / number_of_layers
            
            call addGrainToOutput
        endfor
    endfor
    
elsif synthesis_mode = 4
    # Ikeda Map (Simplified without trig)
    for layer from 1 to number_of_layers
        if randomize_parameters
            u = 0.7 + 0.3 * randomUniform(0, 1)
            layer_density = grain_density * (0.8 + 0.4 * randomUniform(0, 1))
        else
            u = 0.9
            layer_density = grain_density
        endif
        
        chaos_x = 0.5
        chaos_y = 0.5
        total_grains = round(duration * layer_density)
        
        echo Layer 'layer': Generating 'total_grains' grains with Ikeda Map
        
        for grain to total_grains
            grain_time = randomUniform(0, duration - 0.2)
            grain_dur = 0.05 + 0.1 * randomUniform(0, 1)
            
            # Simplified Ikeda-like iteration without trig functions
            t = 0.4 - 6 / (1 + chaos_x * chaos_x + chaos_y * chaos_y)
            t2 = t * t
            t3 = t2 * t
            cos_approx = 1 - t2 / 2
            sin_approx = t - t3 / 6
            
            new_x = 1 + u * (chaos_x * cos_approx - chaos_y * sin_approx)
            new_y = u * (chaos_x * sin_approx + chaos_y * cos_approx)
            chaos_x = new_x
            chaos_y = new_y
            
            # Manual abs calculation
            chaos_x_abs = chaos_x
            if chaos_x_abs < 0
                chaos_x_abs = -chaos_x_abs
            endif
            
            grain_freq = base_frequency * (0.4 + 0.8 * chaos_x_abs / 2) * (1 + (layer - 1) * 0.2)
            grain_amp = 1.2 / number_of_layers
            
            call addGrainToOutput
        endfor
    endfor
    
elsif synthesis_mode = 5
    # Mixed Chaos - use different map for each layer
    for layer from 1 to number_of_layers
        chaos_type = ((layer - 1) mod 4) + 1
        
        if randomize_parameters
            layer_density = grain_density * (0.6 + 0.8 * randomUniform(0, 1))
        else
            layer_density = grain_density
        endif
        
        total_grains = round(duration * layer_density)
        
        if chaos_type = 1
            # Logistic
            r = 3.5 + 0.4 * randomUniform(0, 1)
            chaos_x = 0.5
            echo Layer 'layer': Generating 'total_grains' grains with Logistic Map
        elsif chaos_type = 2
            # Henon
            a = 1.2 + 0.4 * randomUniform(0, 1)
            b = 0.2 + 0.2 * randomUniform(0, 1)
            chaos_x = 0.1
            chaos_y = 0.1
            echo Layer 'layer': Generating 'total_grains' grains with Henon Map
        elsif chaos_type = 3
            # Lorenz
            sigma = 8 + 4 * randomUniform(0, 1)
            chaos_x = 0.1
            chaos_y = 0.0
            chaos_z = 0.0
            dt = 0.01
            echo Layer 'layer': Generating 'total_grains' grains with Lorenz System
        else
            # Ikeda
            u = 0.7 + 0.3 * randomUniform(0, 1)
            chaos_x = 0.5
            chaos_y = 0.5
            echo Layer 'layer': Generating 'total_grains' grains with Ikeda Map
        endif
        
        for grain to total_grains
            grain_time = randomUniform(0, duration - 0.2)
            grain_dur = 0.04 + 0.12 * randomUniform(0, 1)
            
            if chaos_type = 1
                chaos_x = r * chaos_x * (1 - chaos_x)
                grain_freq = base_frequency * (0.3 + 1.4 * chaos_x)
            elsif chaos_type = 2
                new_x = 1 - a * chaos_x * chaos_x + chaos_y
                chaos_y = b * chaos_x
                chaos_x = new_x
                grain_freq = base_frequency * (0.5 + chaos_x)
            elsif chaos_type = 3
                dx = sigma * (chaos_y - chaos_x) * dt
                dy = (chaos_x * (28 - chaos_z) - chaos_y) * dt
                dz = (chaos_x * chaos_y - 2.667 * chaos_z) * dt
                chaos_x = chaos_x + dx
                chaos_y = chaos_y + dy
                chaos_z = chaos_z + dz
                grain_freq = base_frequency * (0.5 + 0.5 * (chaos_x / 20 + 0.5))
            else
                # Ikeda in mixed mode
                t = 0.4 - 6 / (1 + chaos_x * chaos_x + chaos_y * chaos_y)
                t2 = t * t
                t3 = t2 * t
                cos_approx = 1 - t2 / 2
                sin_approx = t - t3 / 6
                
                new_x = 1 + u * (chaos_x * cos_approx - chaos_y * sin_approx)
                new_y = u * (chaos_x * sin_approx + chaos_y * cos_approx)
                chaos_x = new_x
                chaos_y = new_y
                
                # Manual abs calculation
                chaos_x_abs = chaos_x
                if chaos_x_abs < 0
                    chaos_x_abs = -chaos_x_abs
                endif
                grain_freq = base_frequency * (0.4 + 0.8 * chaos_x_abs / 2)
            endif
            
            grain_amp = 1.3 / number_of_layers
            
            call addGrainToOutput
        endfor
    endfor
endif

# Select gen_output for spatial processing
select Sound gen_output

if spatial_mode = 1
    Rename: "chaotic_granular"
    final_sound = selected("Sound")
    
elsif spatial_mode = 2
    Copy: "chaotic_left"
    left_sound = selected("Sound")
    
    select Sound gen_output
    Copy: "chaotic_right"
    right_sound = selected("Sound")
    
    select left_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 4000, 100
    
    select right_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 200, 8000, 100
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "chaotic_granular"
    final_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    Copy: "chaotic_left"
    left_sound = selected("Sound")
    
    select Sound gen_output
    Copy: "chaotic_right"
    right_sound = selected("Sound")
    
    rotation_rate = 0.35
    select left_sound
    Formula: "self * (0.6 + cos(2*pi*'rotation_rate'*x) * 0.4)"
    
    select right_sound
    Formula: "self * (0.6 + sin(2*pi*'rotation_rate'*x) * 0.4)"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "chaotic_granular"
    final_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    Copy: "chaotic_left"
    left_sound = selected("Sound")
    
    select Sound gen_output
    Copy: "chaotic_right"
    right_sound = selected("Sound")
    
    select left_sound
    Filter (pass Hann band): 50, 3000, 80
    
    select right_sound
    Formula: "if col > 30 then self[col - 30] else 0 fi"
    Filter (pass Hann band): 200, 6000, 80
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "chaotic_granular"
    final_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

# Clean up gen_output if it still exists (not renamed in Mono mode)
if spatial_mode <> 1
    select Sound gen_output
    Remove
endif

select final_sound

if normalize_output
    Scale peak: 0.9
endif

call applyFinalFade

Play

echo Advanced Chaotic Granular Synthesis complete!

procedure addGrainToOutput
    if grain_time + grain_dur > duration
        grain_dur = duration - grain_time
    endif
    
    if grain_dur > 0.005
        # Store values for formula construction
        amp_val = grain_amp
        freq_val = grain_freq
        dur_val = grain_dur
        
        # Create individual grain as a sound object with explicit numeric values
        Create Sound from formula: "grain", 1, 0, dur_val, sample_rate, 
        ... "amp_val * sin(2*pi*freq_val*x) * (1 - cos(2*pi*x/dur_val))/2"
        
        # Extract part of gen_output, add grain, replace
        select Sound gen_output
        Extract part: grain_time, grain_time + grain_dur, "rectangular", 1, "no"
        Rename: "segment"
        
        select Sound segment
        Formula: "self + Sound_grain[]"
        
        # Replace the segment back into gen_output
        select Sound gen_output
        override_start = grain_time
        override_end = grain_time + grain_dur
        sample_offset = round(override_start * sample_rate)
        Formula: "if x >= override_start and x < override_end then Sound_segment[col - sample_offset] else self fi"
        
        # Clean up temporary objects
        select Sound grain
        plus Sound segment
        Remove
    endif
endproc

procedure applyFinalFade
    if fade_time > 0
        fade_samples = fade_time * sample_rate
        total_samples = duration * sample_rate
        Formula: "if col < fade_samples then self * (col/fade_samples) else if col > (total_samples - fade_samples) then self * ((total_samples - col)/fade_samples) else self fi fi"
    endif
endproc