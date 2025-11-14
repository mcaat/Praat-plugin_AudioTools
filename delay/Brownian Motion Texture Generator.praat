# ============================================================
# Praat AudioTools - Brownian Motion Texture Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Brownian Motion Texture Generator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Brownian Motion Texture Generator
# Generates texture from short sampled elements using Brownian motion

form Brownian Motion Texture
    comment Preset Selection
    optionmenu Preset 1
        option Custom
        option Dense Cloud
        option Sparse Field
        option Wild Drift
        option Subtle Shimmer
        option Rhythmic Pulse
        option Frozen Moment
    comment Input sound should be selected
    positive Grain_duration_(s) 0.05
    positive Output_duration_(s) 10.0
    positive Density_(grains_per_second) 20
    comment Temporal Brownian Motion
    positive Time_step_size_(s) 0.1
    real Time_drift 0.0
    comment Spatial Brownian Motion (Stereo Field)
    boolean Enable_spatial_brownian 1
    positive Spatial_step_size 0.15
    real Spatial_drift 0.0
    comment General
    positive Amplitude_scaling 0.7
    boolean Random_grain_positions 1
    positive Fade_duration_(s) 0.005
    positive Fade_out_time_(s) 2.0
endform

# ====== APPLY PRESET ======
if preset = 2 ; Dense Cloud
    grain_duration = 0.03
    output_duration = 8.0
    density = 40
    time_step_size = 0.08
    time_drift = 0.0
    enable_spatial_brownian = 1
    spatial_step_size = 0.2
    spatial_drift = 0.0
    amplitude_scaling = 0.5
    random_grain_positions = 1
    fade_duration = 0.003
    fade_out_time = 2.0
    
elsif preset = 3 ; Sparse Field
    grain_duration = 0.15
    output_duration = 15.0
    density = 8
    time_step_size = 0.2
    time_drift = 0.0
    enable_spatial_brownian = 1
    spatial_step_size = 0.1
    spatial_drift = 0.0
    amplitude_scaling = 0.8
    random_grain_positions = 1
    fade_duration = 0.01
    fade_out_time = 3.0
    
elsif preset = 4 ; Wild Drift
    grain_duration = 0.06
    output_duration = 12.0
    density = 25
    time_step_size = 0.25
    time_drift = 0.02
    enable_spatial_brownian = 1
    spatial_step_size = 0.3
    spatial_drift = 0.01
    amplitude_scaling = 0.6
    random_grain_positions = 1
    fade_duration = 0.005
    fade_out_time = 2.5
    
elsif preset = 5 ; Subtle Shimmer
    grain_duration = 0.04
    output_duration = 10.0
    density = 30
    time_step_size = 0.05
    time_drift = 0.0
    enable_spatial_brownian = 1
    spatial_step_size = 0.08
    spatial_drift = 0.0
    amplitude_scaling = 0.6
    random_grain_positions = 1
    fade_duration = 0.004
    fade_out_time = 2.0
    
elsif preset = 6 ; Rhythmic Pulse
    grain_duration = 0.08
    output_duration = 10.0
    density = 15
    time_step_size = 0.02
    time_drift = 0.0
    enable_spatial_brownian = 1
    spatial_step_size = 0.25
    spatial_drift = 0.0
    amplitude_scaling = 0.75
    random_grain_positions = 0
    fade_duration = 0.006
    fade_out_time = 1.5
    
elsif preset = 7 ; Frozen Moment
    grain_duration = 0.4
    output_duration = 20.0
    density = 6
    time_step_size = 0.15
    time_drift = 0.0
    enable_spatial_brownian = 1
    spatial_step_size = 0.12
    spatial_drift = 0.0
    amplitude_scaling = 0.85
    random_grain_positions = 1
    fade_duration = 0.015
    fade_out_time = 4.0
endif

# Get input sound
input_sound = selected("Sound")
input_name$ = selected$("Sound")
input_duration = Get total duration
sample_rate = Get sampling frequency

# Initialize
total_grains = round(density * output_duration)

# Create output sound (STEREO)
Create Sound from formula: "brownian_mix", 2, 0, output_duration, sample_rate, "0"
mixed_sound = selected("Sound")

# Initialize Brownian displacements
time_offset = 0
pan_position = 0.5

writeInfoLine: "Generating ", total_grains, " grains with Brownian motion"
appendInfoLine: "Temporal Brownian: enabled"
if enable_spatial_brownian
    appendInfoLine: "Spatial Brownian: enabled"
else
    appendInfoLine: "Spatial Brownian: disabled (center pan)"
endif
appendInfoLine: ""

# Generate grains with Brownian motion
for i from 1 to total_grains
    
    # ====== TEMPORAL BROWNIAN MOTION ======
    base_time = (i - 1) / density
    
    # Add Brownian displacement to time
    time_step = randomGauss(time_drift, time_step_size)
    time_offset = time_offset + time_step
    
    # Calculate actual grain position
    grain_time = base_time + time_offset
    
    # Clamp to valid range
    if grain_time < 0
        grain_time = 0
    endif
    if grain_time > output_duration - grain_duration
        grain_time = output_duration - grain_duration
    endif
    
    # ====== SPATIAL BROWNIAN MOTION ======
    if enable_spatial_brownian
        spatial_step = randomGauss(spatial_drift, spatial_step_size)
        pan_position = pan_position + spatial_step
        
        # Clamp pan to [0, 1]
        if pan_position < 0
            pan_position = 0
        endif
        if pan_position > 1
            pan_position = 1
        endif
    else
        pan_position = 0.5
    endif
    
    # Calculate stereo gains (sqrt panning law)
    gain_left = sqrt(1 - pan_position)
    gain_right = sqrt(pan_position)
    
    # ====== GRAIN EXTRACTION ======
    selectObject: input_sound
    if random_grain_positions
        grain_start = randomUniform(0, input_duration - grain_duration)
    else
        grain_start = (i / total_grains) * (input_duration - grain_duration)
    endif
    
    Extract part: grain_start, grain_start + grain_duration, "rectangular", 1, "no"
    grain_mono = selected("Sound")
    grain_dur = Get total duration
    
    # Apply fade in/out
    if fade_duration > 0 and fade_duration < grain_dur / 2
        Fade in: 0, 0, fade_duration, "yes"
        Fade out: 0, grain_dur, -fade_duration, "yes"
    endif
    
    # Scale amplitude
    Formula: "self * amplitude_scaling"
    
    # ====== CONVERT TO STEREO WITH PANNING ======
    Copy: "grain_left"
    grain_L_temp = selected("Sound")
    Formula: "self * gain_left"
    
    selectObject: grain_mono
    Copy: "grain_right"
    grain_R_temp = selected("Sound")
    Formula: "self * gain_right"
    
    # Combine to stereo
    selectObject: grain_L_temp
    plusObject: grain_R_temp
    Combine to stereo
    grain_stereo = selected("Sound")
    
    # Cleanup temp objects
    removeObject: grain_mono
    removeObject: grain_L_temp
    removeObject: grain_R_temp
    
    # Rename grain for formula reference
    Rename: "Grain_'i'"
    
    # Calculate grain end time
    grain_end = grain_time + grain_dur
    if grain_end > output_duration
        grain_end = output_duration
        grain_dur = grain_end - grain_time
    endif
    
    # ====== MIX GRAIN INTO OUTPUT ======
    if grain_dur > 0 and grain_time >= 0
        # Extract the portion of mix where grain will be added
        selectObject: mixed_sound
        Extract part: grain_time, grain_end, "rectangular", 1, "no"
        mix_part = selected("Sound")
        
        # Extract matching portion from grain
        selectObject: grain_stereo
        Extract part: 0, grain_dur, "rectangular", 1, "no"
        grain_part = selected("Sound")
        
        # Extract and add channels separately
        selectObject: mix_part
        Extract one channel: 1
        Rename: "MixL"
        mix_L = selected("Sound")
        
        selectObject: mix_part
        Extract one channel: 2
        Rename: "MixR"
        mix_R = selected("Sound")
        
        selectObject: grain_part
        Extract one channel: 1
        Rename: "GrainL"
        grain_L = selected("Sound")
        
        selectObject: grain_part
        Extract one channel: 2
        Rename: "GrainR"
        grain_R = selected("Sound")
        
        # Add left channel
        selectObject: mix_L
        Formula: "self + Sound_GrainL[]"
        
        # Add right channel
        selectObject: mix_R
        Formula: "self + Sound_GrainR[]"
        
        # Combine back to stereo
        selectObject: mix_L
        plusObject: mix_R
        Combine to stereo
        summed_part = selected("Sound")
        
        # Reconstruct the mix: before + summed + after
        if grain_time > 0
            selectObject: mixed_sound
            Extract part: 0, grain_time, "rectangular", 1, "no"
            before_part = selected("Sound")
        endif
        
        if grain_end < output_duration
            selectObject: mixed_sound
            Extract part: grain_end, output_duration, "rectangular", 1, "no"
            after_part = selected("Sound")
        endif
        
        # Concatenate parts
        if grain_time > 0
            selectObject: before_part
            plusObject: summed_part
            if grain_end < output_duration
                plusObject: after_part
            endif
            Concatenate
        elsif grain_end < output_duration
            selectObject: summed_part
            plusObject: after_part
            Concatenate
        else
            selectObject: summed_part
            Copy: "NewMix"
        endif
        new_mix = selected("Sound")
        Rename: "brownian_mix"
        
        # Remove old mix and update reference
        selectObject: mixed_sound
        Remove
        mixed_sound = new_mix
        
        # Cleanup
        removeObject: mix_part
        removeObject: grain_part
        removeObject: mix_L
        removeObject: mix_R
        removeObject: grain_L
        removeObject: grain_R
        removeObject: summed_part
        if grain_time > 0
            removeObject: before_part
        endif
        if grain_end < output_duration
            removeObject: after_part
        endif
    endif
    
    # Cleanup grain
    removeObject: grain_stereo
    
    if i mod 10 = 0
        appendInfoLine: "Processed ", i, " of ", total_grains, " grains..."
    endif
endfor

# Final processing
selectObject: mixed_sound
Rename: input_name$ + "_brownian"

# Apply fade out
if fade_out_time > 0
    selectObject: mixed_sound
    total_duration = Get total duration
    Fade out: 0, total_duration, -fade_out_time, "yes"
endif

# Scale peak
selectObject: mixed_sound
Scale peak: 0.99

# PLAY!
selectObject: mixed_sound
Play

appendInfoLine: newline$, "Done! Brownian motion texture created with spatial movement."