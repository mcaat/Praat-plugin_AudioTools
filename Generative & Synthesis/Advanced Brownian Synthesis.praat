# ============================================================
# Praat AudioTools - Advanced Brownian Synthesis.praat
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

# Advanced Brownian Synthesis System (Ultra-Fast - Click-Free)
# Optimization: Continuous phase tracking across chunks

form Advanced Brownian Synthesis System
    optionmenu preset: 1
        option Custom (use settings below)
        option Default Walk
        option Tight Knots
        option Loose Drift
        option Chaotic Swarm
        option Harmonic Bells
    
    comment === Custom Settings ===
    positive Duration_(sec) 10
    positive Base_frequency_(Hz) 150
    positive Number_of_layers 4
    real Frequency_spread_(Hz) 100
    real Step_size 10
    boolean Enable_drift 1
    real Drift_force 0.1
    positive Fade_time_(sec) 2
    optionmenu Synthesis_mode: 1
        option Brownian Walk
        option Brownian Chaos
        option Brownian Harmonics
        option Pulsed Brownian
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Rotating
    boolean Normalize_output 1
endform

# Apply presets
if preset = 2
    # Default Walk
    duration = 10
    base_frequency = 150
    number_of_layers = 4
    frequency_spread = 100
    step_size = 10
    enable_drift = 1
    drift_force = 0.1
    fade_time = 2
    synthesis_mode = 1
    spatial_mode = 1
    normalize_output = 1
    preset_name$ = "DefaultWalk"
elsif preset = 3
    # Tight Knots
    duration = 8
    base_frequency = 200
    number_of_layers = 6
    frequency_spread = 50
    step_size = 5
    enable_drift = 1
    drift_force = 0.2
    fade_time = 1
    synthesis_mode = 1
    spatial_mode = 2
    normalize_output = 1
    preset_name$ = "TightKnots"
elsif preset = 4
    # Loose Drift
    duration = 15
    base_frequency = 100
    number_of_layers = 3
    frequency_spread = 200
    step_size = 20
    enable_drift = 1
    drift_force = 0.05
    fade_time = 3
    synthesis_mode = 1
    spatial_mode = 3
    normalize_output = 1
    preset_name$ = "LooseDrift"
elsif preset = 5
    # Chaotic Swarm
    duration = 12
    base_frequency = 180
    number_of_layers = 8
    frequency_spread = 80
    step_size = 15
    enable_drift = 1
    drift_force = 0.15
    fade_time = 2
    synthesis_mode = 2
    spatial_mode = 2
    normalize_output = 1
    preset_name$ = "ChaoticSwarm"
elsif preset = 6
    # Harmonic Bells
    duration = 10
    base_frequency = 220
    number_of_layers = 5
    frequency_spread = 0
    step_size = 8
    enable_drift = 1
    drift_force = 0.1
    fade_time = 2
    synthesis_mode = 3
    spatial_mode = 1
    normalize_output = 1
    preset_name$ = "HarmonicBells"
else
    preset_name$ = "Custom"
endif

# Validation
if number_of_layers > 16
    number_of_layers = 16
endif

writeInfoLine: "Brownian Synthesis (Ultra-Fast - Click-Free)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Duration: ", duration, " s"
appendInfoLine: "Layers: ", number_of_layers
appendInfoLine: "Mode: ", synthesis_mode
appendInfoLine: ""

# Initialize
sample_rate = 44100
control_rate = 40
time_step = 1 / control_rate
chunk_duration = 1.0
chunks = ceiling(duration / chunk_duration)

appendInfoLine: "Processing ", chunks, " chunks..."

# Create output buffer
Create Sound from formula: "gen_output", 1, 0, duration, sample_rate, "0"
output_id = selected("Sound")

# ====== PROCESS EACH LAYER ======
for layer from 1 to number_of_layers
    appendInfo: "  Layer ", layer, "/", number_of_layers, "..."
    
    # Initialize layer parameters
    if synthesis_mode = 1
        # Brownian Walk
        voice_freq = base_frequency + (layer - 1) * frequency_spread
        chaos_factor = step_size
        amp_base = 0.6 / number_of_layers
    elsif synthesis_mode = 2
        # Brownian Chaos
        voice_freq = base_frequency * (0.5 + layer * 0.3)
        chaos_factor = step_size * (1 + layer * 0.5)
        amp_base = 0.7 / number_of_layers
    elsif synthesis_mode = 3
        # Brownian Harmonics
        voice_freq = base_frequency * layer
        chaos_factor = step_size * (0.5 + layer * 0.2)
        amp_base = (0.5 / number_of_layers) / layer
    elsif synthesis_mode = 4
        # Pulsed Brownian
        voice_freq = base_frequency * (0.8 + layer * 0.4)
        chaos_factor = step_size
        amp_base = 0.7 / number_of_layers
        pulse_rate = 2 + layer * 1.5
    endif
    
    voice_phase = 0
    global_time = 0
    
    # Process in chunks
    for chunk from 1 to chunks
        t_start = (chunk - 1) * chunk_duration
        t_end = min(chunk * chunk_duration, duration)
        actual_chunk_dur = t_end - t_start
        
        if actual_chunk_dur > 0
            # Create this chunk
            Create Sound from formula: "chunk", 1, 0, actual_chunk_dur, sample_rate, "0"
            chunk_id = selected("Sound")
            
            # Build formula for this chunk (relative to chunk start)
            chunk_formula$ = "0"
            local_time = 0
            
            while local_time < actual_chunk_dur
                segment_duration = min(time_step, actual_chunk_dur - local_time)
                
                if segment_duration > 0.001
                    # Calculate Brownian step
                    if synthesis_mode = 2
                        # Chaos mode: occasional large jumps
                        brownian_step = randomGauss(0, 1) * chaos_factor
                        if randomUniform(0, 1) < 0.1
                            brownian_step = brownian_step * 5
                        endif
                    else
                        brownian_step = randomGauss(0, 1) * chaos_factor
                    endif
                    
                    # Apply drift
                    if enable_drift
                        target_freq = base_frequency
                        if synthesis_mode = 2
                            target_freq = base_frequency * 2
                        elsif synthesis_mode = 3
                            target_freq = base_frequency * layer
                        endif
                        
                        drift = (target_freq - voice_freq) * drift_force * time_step
                        brownian_step = brownian_step + drift
                    endif
                    
                    # Update frequency
                    voice_freq = voice_freq + brownian_step
                    voice_freq = max(30, min(8000, voice_freq))
                    
                    # Calculate amplitude
                    if synthesis_mode = 2
                        # Chaos: stability-based amplitude
                        stability = exp(-abs(brownian_step) / chaos_factor)
                        voice_amp = amp_base * stability
                    elsif synthesis_mode = 4
                        # Pulsed (use global_time for continuity)
                        pulse = (sin(2 * pi * pulse_rate * global_time) > 0.7) * 0.8 + 0.2
                        voice_amp = amp_base * pulse
                    else
                        voice_amp = amp_base * (1 - (layer - 1) / number_of_layers * 0.3)
                    endif
                    
                    # Add segment to formula
                    s_time$ = fixed$(local_time, 6)
                    s_end$ = fixed$(local_time + segment_duration, 6)
                    s_amp$ = fixed$(voice_amp, 6)
                    s_phase$ = fixed$(voice_phase, 6)
                    s_freq$ = fixed$(voice_freq, 2)
                    
                    segment$ = " + if x >= " + s_time$ + " and x < " + s_end$ + " then " + s_amp$ + " * sin(" + s_phase$ + " + 2*pi*" + s_freq$ + "*(x - " + s_time$ + ")) else 0 fi"
                    chunk_formula$ = chunk_formula$ + segment$
                    
                    # Update phase
                    voice_phase = voice_phase + 2 * pi * voice_freq * segment_duration
                    
                    local_time = local_time + time_step
                    global_time = global_time + time_step
                endif
            endwhile
            
            # Apply formula to chunk
            selectObject: chunk_id
            Formula: chunk_formula$
            
            # Shift to absolute time
            Shift times to: "start time", t_start
            
            # Add to output
            selectObject: output_id
            chunk_str$ = string$(chunk_id)
            s_start$ = fixed$(t_start, 6)
            s_end$ = fixed$(t_end, 6)
            Formula: "if x >= " + s_start$ + " and x <= " + s_end$ + " then self + object(" + chunk_str$ + ", x) else self fi"
            
            # Cleanup
            removeObject: chunk_id
        endif
    endfor
    
    appendInfoLine: " done"
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
    Rename: "brownian_" + preset_name$
    
elsif spatial_mode = 2
    # STEREO WIDE
    appendInfo: "Creating stereo..."
    Copy: "brownian_left"
    left_id = selected("Sound")
    
    selectObject: output_id
    Copy: "brownian_right"
    right_id = selected("Sound")
    
    # Different filtering for width
    selectObject: left_id
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 4000, 100
    
    selectObject: right_id
    Formula: "self * 0.8"
    Filter (pass Hann band): 200, 8000, 100
    
    # Combine
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "brownian_" + preset_name$
    
    removeObject: output_id, left_id, right_id
    output_id = stereo_id
    appendInfoLine: " done"
    
elsif spatial_mode = 3
    # ROTATING
    appendInfo: "Creating rotating stereo..."
    Copy: "brownian_left"
    left_id = selected("Sound")
    
    selectObject: output_id
    Copy: "brownian_right"
    right_id = selected("Sound")
    
    # Rotation panning
    selectObject: left_id
    Formula: "self * (0.6 + cos(2*pi*0.15*x) * 0.4)"
    
    selectObject: right_id
    Formula: "self * (0.6 + sin(2*pi*0.15*x) * 0.4)"
    
    selectObject: left_id
    plusObject: right_id
    stereo_id = Combine to stereo
    Rename: "brownian_" + preset_name$
    
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