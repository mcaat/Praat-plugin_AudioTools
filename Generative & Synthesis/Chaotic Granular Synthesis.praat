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

# Advanced Chaotic Granular Synthesis (Ultra-Fast - Grain Limit Per Chunk)

form Advanced Chaotic Granular Synthesis System
    optionmenu preset: 1
        option Custom (use settings below)
        option Logistic Sparse
        option Henon Texture
        option Lorenz Atmospheric
    
    comment === Custom Settings ===
    positive Duration_(sec) 10
    positive Base_frequency_(Hz) 120
    positive Grain_density_(grains/sec) 8
    integer Number_of_layers 3
    boolean Randomize_parameters 1
    positive Fade_time_(sec) 2
    optionmenu Synthesis_mode: 1
        option Logistic Map
        option Henon Map
        option Lorenz System
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
    boolean Normalize_output 1
    boolean Play_after 1
endform

# Apply presets
if preset = 2
    duration = 10
    base_frequency = 120
    grain_density = 8
    number_of_layers = 3
    randomize_parameters = 1
    synthesis_mode = 1
    preset_name$ = "LogisticSparse"
elsif preset = 3
    duration = 12
    base_frequency = 100
    grain_density = 6
    number_of_layers = 4
    randomize_parameters = 1
    synthesis_mode = 2
    spatial_mode = 2
    preset_name$ = "HenonTexture"
elsif preset = 4
    duration = 15
    base_frequency = 80
    grain_density = 5
    number_of_layers = 3
    randomize_parameters = 1
    synthesis_mode = 3
    preset_name$ = "LorenzAtmospheric"
else
    preset_name$ = "Custom"
endif

if number_of_layers > 8
    number_of_layers = 8
endif

writeInfoLine: "Chaotic Granular Synthesis (Ultra-Fast)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: ""

sample_rate = 44100
chunk_duration = 2.0
num_chunks = ceiling(duration / chunk_duration)

# Conservative amplitude
base_amp_scale = 0.3 / number_of_layers

# Max grains per chunk to keep formula manageable
max_grains_per_chunk = 30

# ====== PROCESS EACH LAYER ======
for layer from 1 to number_of_layers
    appendInfo: "Layer ", layer, "/", number_of_layers, "..."
    
    # Initialize chaos parameters
    if synthesis_mode = 1
        # Logistic Map
        if randomize_parameters
            r = 3.5 + 0.4 * randomUniform(0, 1)
            layer_density = grain_density * (0.7 + 0.6 * randomUniform(0, 1))
        else
            r = 3.7
            layer_density = grain_density
        endif
        chaos_x = 0.5
        
    elsif synthesis_mode = 2
        # Henon Map
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
        
    else
        # Lorenz System
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
    endif
    
    total_grains = round(duration * layer_density)
    
    # Pre-generate all grain parameters
    for grain to total_grains
        grain_time[grain] = randomUniform(0, duration - 0.2)
        grain_dur[grain] = 0.08 + 0.15 * randomUniform(0, 1)
        
        # Evolve chaos and calculate frequency
        if synthesis_mode = 1
            chaos_x = r * chaos_x * (1 - chaos_x)
            grain_freq[grain] = base_frequency * (0.3 + 1.4 * chaos_x) * (1 + (layer - 1) * 0.2)
        elsif synthesis_mode = 2
            new_x = 1 - a * chaos_x * chaos_x + chaos_y
            chaos_y = b * chaos_x
            chaos_x = new_x
            grain_freq[grain] = base_frequency * (0.5 + chaos_x) * (1 + (layer - 1) * 0.25)
        else
            dx = sigma * (chaos_y - chaos_x) * dt
            dy = (chaos_x * (28 - chaos_z) - chaos_y) * dt
            dz = (chaos_x * chaos_y - 2.667 * chaos_z) * dt
            chaos_x = chaos_x + dx
            chaos_y = chaos_y + dy
            chaos_z = chaos_z + dz
            grain_freq[grain] = base_frequency * (0.5 + 0.5 * (chaos_x / 20 + 0.5)) * (1 + (layer - 1) * 0.3)
        endif
        
        grain_amp[grain] = base_amp_scale
        
        if grain_time[grain] + grain_dur[grain] > duration
            grain_dur[grain] = duration - grain_time[grain]
        endif
    endfor
    
    # Create chunks
    for chunk from 1 to num_chunks
        chunk_start = (chunk - 1) * chunk_duration
        chunk_end = min(chunk * chunk_duration, duration)
        actual_chunk_dur = chunk_end - chunk_start
        
        chunk_formula$ = "0"
        grains_added = 0
        
        # Add grains - LIMIT TO max_grains_per_chunk
        for grain to total_grains
            if grains_added >= max_grains_per_chunk
                # Skip remaining grains in this chunk
                grain = total_grains
            elsif grain_time[grain] >= chunk_start and grain_time[grain] < chunk_end and grain_dur[grain] > 0.01
                local_time = grain_time[grain] - chunk_start
                local_end = local_time + grain_dur[grain]
                
                # Clamp to chunk boundaries
                if local_end > actual_chunk_dur
                    local_end = actual_chunk_dur
                endif
                
                s_start$ = fixed$(local_time, 4)
                s_end$ = fixed$(local_end, 4)
                s_amp$ = fixed$(grain_amp[grain], 4)
                s_freq$ = fixed$(grain_freq[grain], 1)
                s_dur$ = fixed$(grain_dur[grain], 4)
                
                # Simple formula with Hanning envelope
                hann$ = "(1-cos(2*pi*(x-" + s_start$ + ")/" + s_dur$ + "))/2"
                term$ = "+if x>=" + s_start$ + " and x<" + s_end$ + " then " + s_amp$ + "*sin(2*pi*" + s_freq$ + "*x)*" + hann$ + " else 0 fi"
                
                chunk_formula$ = chunk_formula$ + term$
                grains_added = grains_added + 1
            endif
        endfor
        
        if chunk_formula$ <> "0"
            Create Sound from formula: "L'layer'C'chunk'", 1, 0, actual_chunk_dur, sample_rate, chunk_formula$
        else
            Create Sound from formula: "L'layer'C'chunk'", 1, 0, actual_chunk_dur, sample_rate, "0"
        endif
    endfor
    
    # Concatenate chunks
    selectObject: "Sound L" + string$(layer) + "C1"
    for chunk from 2 to num_chunks
        plusObject: "Sound L" + string$(layer) + "C" + string$(chunk)
    endfor
    
    layer_sound = Concatenate
    Rename: "layer_" + string$(layer)
    
    # Cleanup
    for chunk from 1 to num_chunks
        removeObject: "Sound L" + string$(layer) + "C" + string$(chunk)
    endfor
    
    appendInfoLine: " ", total_grains, " grains"
endfor

# Mix layers
appendInfo: "Mixing..."
selectObject: "Sound layer_1"
final_id = Copy: "chaotic_mix"

for layer from 2 to number_of_layers
    selectObject: "Sound layer_" + string$(layer)
    layer_id = selected("Sound")
    selectObject: final_id
    Formula: "self+object(" + string$(layer_id) + ",x)"
endfor

for layer from 1 to number_of_layers
    removeObject: "Sound layer_" + string$(layer)
endfor
appendInfoLine: " done"

# Fade
if fade_time > 0
    selectObject: final_id
    s_fade$ = fixed$(fade_time, 6)
    s_dur$ = fixed$(duration, 6)
    Formula: "if x<" + s_fade$ + " then self*(x/" + s_fade$ + ") else if x>" + s_dur$ + "-" + s_fade$ + " then self*((" + s_dur$ + "-x)/" + s_fade$ + ") else self fi fi"
endif

# Spatial
selectObject: final_id
if spatial_mode = 1
    Rename: "chaotic_" + preset_name$
else
    Copy: "L"
    left_id = selected("Sound")
    selectObject: final_id
    Copy: "R"
    right_id = selected("Sound")
    
    selectObject: left_id
    Formula: "self*0.8"
    Filter (pass Hann band): 0, 4000, 100
    selectObject: right_id
    Formula: "self*0.8"
    Filter (pass Hann band): 200, 8000, 100
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "chaotic_" + preset_name$
    removeObject: final_id, left_id, right_id
    final_id = stereo_id
endif

selectObject: final_id
if normalize_output
    Scale peak: 0.9
endif

appendInfoLine: ""
appendInfoLine: "Done!"

if play_after
    Play
endif