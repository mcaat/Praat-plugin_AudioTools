# ============================================================
# Praat AudioTools - Advanced Poisson Synthesis.praat
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

# Advanced Poisson Synthesis System (Ultra-Fast)
# Optimization: Batch formula building instead of individual grain insertion

form Advanced Poisson Synthesis System
    optionmenu preset: 1
        option Custom (use settings below)
        option Standard Three Layer
        option Dense Cloud
        option Sparse Atmosphere
        option Rhythmic Pattern
        option Chaotic Texture
    
    comment === Custom Settings ===
    positive Duration_(sec) 12
    positive Base_frequency_(Hz) 100
    positive Frequency_range_(Hz) 300
    positive Low_rate_(events/sec) 3
    positive High_rate_(events/sec) 15
    integer Number_of_layers 3
    boolean Randomize_parameters 1
    positive Fade_time_(sec) 2
    optionmenu Synthesis_mode: 1
        option Three Layer Standard
        option Dense Granular
        option Sparse Atmospheric
        option Rhythmic Pulses
        option Chaotic Scatter
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Rotating
    boolean Normalize_output 1
endform

# Apply presets
if preset = 2
    # Standard Three Layer
    duration = 12
    base_frequency = 100
    frequency_range = 300
    low_rate = 3
    high_rate = 15
    number_of_layers = 3
    randomize_parameters = 1
    fade_time = 2
    synthesis_mode = 1
    spatial_mode = 1
    normalize_output = 1
    preset_name$ = "Standard"
elsif preset = 3
    # Dense Cloud
    duration = 10
    base_frequency = 150
    frequency_range = 400
    low_rate = 10
    high_rate = 25
    number_of_layers = 4
    randomize_parameters = 1
    fade_time = 2
    synthesis_mode = 2
    spatial_mode = 2
    normalize_output = 1
    preset_name$ = "DenseCloud"
elsif preset = 4
    # Sparse Atmosphere
    duration = 20
    base_frequency = 80
    frequency_range = 500
    low_rate = 1
    high_rate = 5
    number_of_layers = 3
    randomize_parameters = 1
    fade_time = 3
    synthesis_mode = 3
    spatial_mode = 3
    normalize_output = 1
    preset_name$ = "Sparse"
elsif preset = 5
    # Rhythmic Pattern
    duration = 15
    base_frequency = 120
    frequency_range = 200
    low_rate = 5
    high_rate = 12
    number_of_layers = 4
    randomize_parameters = 0
    fade_time = 2
    synthesis_mode = 4
    spatial_mode = 1
    normalize_output = 1
    preset_name$ = "Rhythmic"
elsif preset = 6
    # Chaotic Texture
    duration = 12
    base_frequency = 100
    frequency_range = 600
    low_rate = 2
    high_rate = 20
    number_of_layers = 5
    randomize_parameters = 1
    fade_time = 2
    synthesis_mode = 5
    spatial_mode = 2
    normalize_output = 1
    preset_name$ = "Chaotic"
else
    preset_name$ = "Custom"
endif

# Validation
if number_of_layers > 8
    number_of_layers = 8
endif

writeInfoLine: "Poisson Synthesis (Ultra-Fast)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Duration: ", duration, " s"
appendInfoLine: "Layers: ", number_of_layers
appendInfoLine: ""

sample_rate = 44100

# Create base sound
Create Sound from formula: "gen_output", 1, 0, duration, sample_rate, "0"
output_id = selected("Sound")

# ====== PROCESS EACH LAYER ======
for layer from 1 to number_of_layers
    appendInfo: "  Layer ", layer, "/", number_of_layers, "..."
    
    # Determine layer rate based on synthesis mode
    if synthesis_mode = 1
        # Three Layer Standard
        if randomize_parameters
            layer_rate = low_rate + (high_rate - low_rate) * (layer - 1) / max(1, number_of_layers - 1) * (0.8 + 0.4 * randomUniform(0, 1))
        else
            layer_rate = low_rate + (high_rate - low_rate) * (layer - 1) / max(1, number_of_layers - 1)
        endif
    elsif synthesis_mode = 2
        # Dense Granular
        if randomize_parameters
            layer_rate = high_rate * 1.5 * (0.7 + 0.6 * randomUniform(0, 1))
        else
            layer_rate = high_rate * 1.5
        endif
    elsif synthesis_mode = 3
        # Sparse Atmospheric
        if randomize_parameters
            layer_rate = low_rate * 0.5 * (0.6 + 0.8 * randomUniform(0, 1))
        else
            layer_rate = low_rate * 0.5
        endif
    elsif synthesis_mode = 4
        # Rhythmic Pulses
        if randomize_parameters
            layer_rate = (low_rate + high_rate) / 2 * (0.9 + 0.2 * randomUniform(0, 1))
        else
            layer_rate = (low_rate + high_rate) / 2
        endif
    elsif synthesis_mode = 5
        # Chaotic Scatter
        if randomize_parameters
            layer_rate = (low_rate + (high_rate - low_rate) * randomUniform(0, 1)) * (0.5 + randomUniform(0, 1))
        else
            layer_rate = low_rate + (high_rate - low_rate) * randomUniform(0, 1)
        endif
    endif
    
    # Create Poisson process
    Create Poisson process: "poisson_layer", 0, duration, layer_rate
    poisson_id = selected("PointProcess")
    num_points = Get number of points
    
    # Build complete layer formula
    layer_formula$ = "0"
    
    for point to num_points
        selectObject: poisson_id
        point_time = Get time from index: point
        
        # Determine grain parameters based on synthesis mode
        if synthesis_mode = 1
            # Standard
            grain_freq = base_frequency + frequency_range * randomUniform(0, 1)
            grain_dur = 0.1 + 0.2 * randomUniform(0, 1)
            grain_amp = 1.5 / number_of_layers
        elsif synthesis_mode = 2
            # Dense Granular
            grain_freq = base_frequency * (0.5 + layer * 0.3) + frequency_range * randomUniform(0, 1)
            grain_dur = 0.03 + 0.08 * randomUniform(0, 1)
            grain_amp = 1.2 / number_of_layers
        elsif synthesis_mode = 3
            # Sparse Atmospheric
            grain_freq = base_frequency * (0.3 + layer * 0.4) + frequency_range * 0.5 * randomUniform(0, 1)
            grain_dur = 0.3 + 0.5 * randomUniform(0, 1)
            grain_amp = 2.0 / number_of_layers
        elsif synthesis_mode = 4
            # Rhythmic Pulses
            grain_freq = base_frequency * layer + frequency_range * 0.3 * randomUniform(0, 1)
            grain_dur = 0.08 + 0.12 * randomUniform(0, 1)
            grain_amp = 1.8 / number_of_layers
        elsif synthesis_mode = 5
            # Chaotic Scatter
            grain_freq = base_frequency * (0.5 + 2 * randomUniform(0, 1)) + frequency_range * randomUniform(0, 1)
            grain_dur = 0.05 + 0.3 * randomUniform(0, 1)
            grain_amp = 1.5 / number_of_layers
        endif
        
        # Clamp grain duration
        if point_time + grain_dur > duration
            grain_dur = duration - point_time
        endif
        
        if grain_dur > 0.005
            # Add grain to formula
            s_time$ = fixed$(point_time, 6)
            s_end$ = fixed$(point_time + grain_dur, 6)
            s_amp$ = fixed$(grain_amp, 6)
            s_freq$ = fixed$(grain_freq, 2)
            s_dur$ = fixed$(grain_dur, 6)
            
            # Grain formula with Hanning envelope
            grain_term$ = " + if x >= " + s_time$ + " and x < " + s_end$ + " then " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*(x - " + s_time$ + ")) * (1 - cos(2*pi*(x - " + s_time$ + ")/" + s_dur$ + "))/2 else 0 fi"
            layer_formula$ = layer_formula$ + grain_term$
        endif
    endfor
    
    # Create layer sound with complete formula
    Create Sound from formula: "layer", 1, 0, duration, sample_rate, layer_formula$
    layer_id = selected("Sound")
    
    # Add to output
    selectObject: output_id
    layer_str$ = string$(layer_id)
    Formula: "self + object(" + layer_str$ + ", x)"
    
    # Cleanup
    removeObject: poisson_id, layer_id
    
    appendInfoLine: " ", num_points, " grains"
endfor

# ====== APPLY FADE ======
if fade_time > 0
    appendInfo: "Applying fade..."
    selectObject: output_id
    s_fade$ = fixed$(fade_time, 6)
    s_dur$ = fixed$(duration, 6)
    Formula: "if x < " + s_fade$ + " then self * (x / " + s_fade$ + ") else if x > " + s_dur$ + " - " + s_fade$ + " then self * ((" + s_dur$ + " - x) / " + s_fade$ + ") else self fi fi"
    appendInfoLine: " done"
endif

# ====== SPATIAL PROCESSING ======
selectObject: output_id

if spatial_mode = 1
    # MONO
    Rename: "poisson_" + preset_name$
    
elsif spatial_mode = 2
    # STEREO WIDE
    appendInfo: "Creating stereo..."
    Copy: "poisson_left"
    left_id = selected("Sound")
    
    selectObject: output_id
    Copy: "poisson_right"
    right_id = selected("Sound")
    
    selectObject: left_id
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 4000, 100
    
    selectObject: right_id
    Formula: "self * 0.8"
    Filter (pass Hann band): 200, 8000, 100
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "poisson_" + preset_name$
    
    removeObject: output_id, left_id, right_id
    output_id = stereo_id
    appendInfoLine: " done"
    
elsif spatial_mode = 3
    # ROTATING
    appendInfo: "Creating rotating stereo..."
    Copy: "poisson_left"
    left_id = selected("Sound")
    
    selectObject: output_id
    Copy: "poisson_right"
    right_id = selected("Sound")
    
    selectObject: left_id
    Formula: "self * (0.6 + cos(2*pi*0.25*x) * 0.4)"
    
    selectObject: right_id
    Formula: "self * (0.6 + sin(2*pi*0.25*x) * 0.4)"
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "poisson_" + preset_name$
    
    removeObject: output_id, left_id, right_id
    output_id = stereo_id
    appendInfoLine: " done"
endif

# ====== FINALIZE ======
selectObject: output_id

if normalize_output
    Scale peak: 0.9
endif

appendInfoLine: ""
appendInfoLine: "Done!"

Play