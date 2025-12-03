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

# Dynamic Stochastic Synthesis (Ultra-Fast with Chunking)

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
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Evolution
        option Rotating Cloud
        option Wide Field
    real Duration 6.0
    real Base_frequency 120
    real Initial_density 30
    real Final_density 150
    real Frequency_evolution_speed 1.0
    boolean Play_after 1
endform

# Apply presets
if preset = 2
    base_frequency = 80
    initial_density = 15
    final_density = 60
    frequency_evolution_speed = 0.5
    preset_name$ = "GentleBloom"
elsif preset = 3
    base_frequency = 100
    initial_density = 20
    final_density = 200
    frequency_evolution_speed = 1.2
    preset_name$ = "StormBuild"
elsif preset = 4
    base_frequency = 60
    initial_density = 10
    final_density = 80
    frequency_evolution_speed = 2.0
    preset_name$ = "CosmicDrift"
elsif preset = 5
    base_frequency = 180
    initial_density = 40
    final_density = 180
    frequency_evolution_speed = 1.5
    preset_name$ = "DigitalCascade"
elsif preset = 6
    base_frequency = 90
    initial_density = 25
    final_density = 100
    frequency_evolution_speed = 0.8
    preset_name$ = "OrganicGrowth"
elsif preset = 7
    base_frequency = 110
    initial_density = 35
    final_density = 120
    frequency_evolution_speed = 1.0
    preset_name$ = "HarmonicSwarm"
elsif preset = 8
    base_frequency = 140
    initial_density = 50
    final_density = 250
    frequency_evolution_speed = 1.8
    preset_name$ = "MetallicStorm"
elsif preset = 9
    base_frequency = 70
    initial_density = 8
    final_density = 40
    frequency_evolution_speed = 0.3
    preset_name$ = "WhisperCloud"
else
    preset_name$ = "Custom"
endif

writeInfoLine: "Dynamic Stochastic Synthesis (Ultra-Fast)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: ""

sample_rate = 44100
chunk_duration = 1.5
num_chunks = ceiling(duration / chunk_duration)

total_grains = round((initial_density + final_density) / 2 * duration)

appendInfoLine: "Total grains: ", total_grains
appendInfoLine: "Generating grain parameters..."

# Pre-generate all grain parameters
for i to total_grains
    t = randomUniform(0, duration)
    normalized_time = t / duration
    
    current_density = initial_density + (final_density - initial_density) * normalized_time
    current_freq = base_frequency * (2 ^ (frequency_evolution_speed * normalized_time))
    
    # Preset-specific grain characteristics
    if preset = 2
        grain_freq[i] = current_freq * (0.9 + 0.2 * randomUniform(0, 1))
        grain_amp[i] = 0.4 * (1 - normalized_time ^ 0.5)
        grain_dur[i] = 0.03 + 0.08 * randomUniform(0, 1)
    elsif preset = 3
        grain_freq[i] = current_freq * (0.7 + 0.6 * randomUniform(0, 1))
        grain_amp[i] = 0.7 * (1 - normalized_time ^ 0.8)
        grain_dur[i] = 0.01 + 0.04 * randomUniform(0, 1)
    elsif preset = 4
        grain_freq[i] = current_freq * (0.5 + 1.0 * randomUniform(0, 1))
        grain_amp[i] = 0.5 * (1 - normalized_time ^ 0.3)
        grain_dur[i] = 0.05 + 0.12 * randomUniform(0, 1)
    elsif preset = 9
        grain_freq[i] = current_freq * (0.8 + 0.3 * randomUniform(0, 1))
        grain_amp[i] = 0.3 * (1 - normalized_time ^ 0.6)
        grain_dur[i] = 0.04 + 0.10 * randomUniform(0, 1)
    else
        grain_freq[i] = current_freq * (0.8 + 0.4 * randomUniform(0, 1))
        grain_amp[i] = 0.6 * (1 - normalized_time ^ 0.7)
        grain_dur[i] = 0.02 + 0.06 * randomUniform(0, 1)
    endif
    
    grain_time[i] = t
    
    if grain_time[i] + grain_dur[i] > duration
        grain_dur[i] = duration - grain_time[i]
    endif
    
    # Scale amplitude to prevent clipping
    grain_amp[i] = grain_amp[i] * 0.15
endfor

appendInfoLine: "Creating ", num_chunks, " chunks..."

# Create chunks
for chunk from 1 to num_chunks
    chunk_start = (chunk - 1) * chunk_duration
    chunk_end = min(chunk * chunk_duration, duration)
    actual_chunk_dur = chunk_end - chunk_start
    
    appendInfo: "  Chunk ", chunk, "/", num_chunks, "..."
    
    chunk_formula$ = "0"
    grains_in_chunk = 0
    
    # Add grains in this chunk (max 40 per chunk)
    for i to total_grains
        if grains_in_chunk >= 40
            i = total_grains
        elsif grain_time[i] >= chunk_start and grain_time[i] < chunk_end and grain_dur[i] > 0.005
            local_time = grain_time[i] - chunk_start
            
            s_time$ = fixed$(local_time, 4)
            s_end$ = fixed$(local_time + grain_dur[i], 4)
            s_amp$ = fixed$(grain_amp[i], 4)
            s_freq$ = fixed$(grain_freq[i], 1)
            s_dur$ = fixed$(grain_dur[i], 4)
            
            # Simplified formula with sine envelope
            term$ = "+if x>=" + s_time$ + " and x<" + s_end$ + " then " + s_amp$ + "*sin(2*pi*" + s_freq$ + "*x)*sin(pi*(x-" + s_time$ + ")/" + s_dur$ + ") else 0 fi"
            chunk_formula$ = chunk_formula$ + term$
            grains_in_chunk = grains_in_chunk + 1
        endif
    endfor
    
    if chunk_formula$ <> "0"
        Create Sound from formula: "C'chunk'", 1, 0, actual_chunk_dur, sample_rate, chunk_formula$
    else
        Create Sound from formula: "C'chunk'", 1, 0, actual_chunk_dur, sample_rate, "0"
    endif
    
    appendInfoLine: " ", grains_in_chunk, " grains"
endfor

# Concatenate all chunks
appendInfo: "Concatenating..."
selectObject: "Sound C1"
for chunk from 2 to num_chunks
    plusObject: "Sound C" + string$(chunk)
endfor

final_id = Concatenate
Rename: "stochastic_output"

# Cleanup chunks
for chunk from 1 to num_chunks
    removeObject: "Sound C" + string$(chunk)
endfor

appendInfoLine: " done"

# Spatial processing
selectObject: final_id

if spatial_mode = 1
    Rename: "stochastic_" + preset_name$
    
elsif spatial_mode = 2
    # Stereo Evolution
    Copy: "left"
    left_id = selected("Sound")
    selectObject: final_id
    Copy: "right"
    right_id = selected("Sound")
    
    s_dur$ = fixed$(duration, 6)
    
    selectObject: left_id
    Formula: "self * (0.8 - 0.3 * (x/" + s_dur$ + "))"
    Filter (pass Hann band): 0, 3500, 100
    
    selectObject: right_id
    Formula: "self * (0.5 + 0.3 * (x/" + s_dur$ + "))"
    Filter (pass Hann band): 100, 6000, 100
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "stochastic_" + preset_name$
    removeObject: final_id, left_id, right_id
    final_id = stereo_id
    
elsif spatial_mode = 3
    # Rotating Cloud
    Copy: "left"
    left_id = selected("Sound")
    selectObject: final_id
    Copy: "right"
    right_id = selected("Sound")
    
    s_dur$ = fixed$(duration, 6)
    
    selectObject: left_id
    Formula: "self * (0.5 + 0.4 * cos(2*pi*0.1*x * (1 + x/" + s_dur$ + ")))"
    
    selectObject: right_id
    Formula: "self * (0.5 + 0.4 * sin(2*pi*0.1*x * (1 + x/" + s_dur$ + ")))"
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "stochastic_" + preset_name$
    removeObject: final_id, left_id, right_id
    final_id = stereo_id
    
elsif spatial_mode = 4
    # Wide Field
    Copy: "left"
    left_id = selected("Sound")
    selectObject: final_id
    Copy: "right"
    right_id = selected("Sound")
    
    s_dur$ = fixed$(duration, 6)
    
    selectObject: left_id
    Formula: "self * (0.7 - 0.2 * (x/" + s_dur$ + "))"
    Filter (pass Hann band): 0, 2000, 120
    
    selectObject: right_id
    Formula: "self * (0.5 + 0.3 * (x/" + s_dur$ + "))"
    Filter (pass Hann band): 200, 7000, 120
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "stochastic_" + preset_name$
    removeObject: final_id, left_id, right_id
    final_id = stereo_id
endif

selectObject: final_id
Scale peak: 0.9

appendInfoLine: ""
appendInfoLine: "Done!"

if play_after
    Play
endif