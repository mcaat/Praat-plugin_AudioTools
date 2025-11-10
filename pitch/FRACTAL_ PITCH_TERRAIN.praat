# ============================================================
# Praat AudioTools - FRACTAL_ PITCH_TERRAIN.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-based transformation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Fractal Pitch Terrain Effect
    comment Preset configurations for fractal pitch landscapes
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Fractal
        option Complex Terrain
        option Chaotic Mountains
        option Micro Fractal
        option Rhythmic Layers
        option Evolving Landscape
        option Extreme Chaos
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    natural iterations 6
    positive base_frequency 1.5
    positive amplitude_decay 0.55
    positive chaos_factor 0.3
    comment Wave mixing:
    positive sine_mix 0.7
    positive square_mix 0.3
    comment Frequency progression:
    positive frequency_multiplier 2.618
    comment (golden ratio)
    positive phase_increment 0.33
    comment Pitch scaling:
    positive pitch_depth 15
    positive drift_amplitude 2
    positive drift_frequency 0.7
    comment Time evolution:
    positive time_evolution_power 2
    positive time_evolution_strength 0.5
    comment Pitch analysis:
    positive time_step 0.005
    positive minimum_pitch 50
    positive maximum_pitch 900
    comment Output:
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Apply presets
if preset = 2    ; Gentle Fractal
    iterations = 4
    base_frequency = 1.2
    amplitude_decay = 0.6
    chaos_factor = 0.1
    sine_mix = 0.9
    square_mix = 0.1
    frequency_multiplier = 2.0
    pitch_depth = 8
    drift_amplitude = 1
    time_evolution_strength = 0.2
elsif preset = 3    ; Complex Terrain
    iterations = 7
    base_frequency = 1.5
    amplitude_decay = 0.55
    chaos_factor = 0.25
    sine_mix = 0.7
    square_mix = 0.3
    frequency_multiplier = 2.618
    pitch_depth = 18
    drift_amplitude = 2
    time_evolution_strength = 0.4
elsif preset = 4    ; Chaotic Mountains
    iterations = 8
    base_frequency = 2.0
    amplitude_decay = 0.45
    chaos_factor = 0.6
    sine_mix = 0.5
    square_mix = 0.5
    frequency_multiplier = 3.0
    pitch_depth = 25
    drift_amplitude = 3
    time_evolution_strength = 0.7
elsif preset = 5    ; Micro Fractal
    iterations = 5
    base_frequency = 0.8
    amplitude_decay = 0.7
    chaos_factor = 0.05
    sine_mix = 0.95
    square_mix = 0.05
    frequency_multiplier = 1.5
    pitch_depth = 4
    drift_amplitude = 0.5
    time_evolution_strength = 0.1
elsif preset = 6    ; Rhythmic Layers
    iterations = 6
    base_frequency = 3.0
    amplitude_decay = 0.5
    chaos_factor = 0.15
    sine_mix = 0.4
    square_mix = 0.6
    frequency_multiplier = 2.0
    pitch_depth = 12
    drift_amplitude = 1.5
    time_evolution_strength = 0.3
elsif preset = 7    ; Evolving Landscape
    iterations = 7
    base_frequency = 1.3
    amplitude_decay = 0.58
    chaos_factor = 0.2
    sine_mix = 0.8
    square_mix = 0.2
    frequency_multiplier = 2.3
    pitch_depth = 20
    drift_amplitude = 2.5
    time_evolution_strength = 0.8
elsif preset = 8    ; Extreme Chaos
    iterations = 10
    base_frequency = 2.5
    amplitude_decay = 0.4
    chaos_factor = 0.8
    sine_mix = 0.3
    square_mix = 0.7
    frequency_multiplier = 3.5
    pitch_depth = 35
    drift_amplitude = 4
    time_evolution_strength = 1.0
endif

originalName$ = selected$("Sound")
orig_sr = Get sampling frequency

# Get original sound duration
xmin = Get start time
xmax = Get end time
dur = xmax - xmin

# Create dense point sampling for smooth fractal curves
npoints = round(dur / 0.01)
if npoints < 200
    npoints = 200
endif
if npoints > 2000
    npoints = 2000
endif

Copy: originalName$ + "_fractal_tmp"
To Manipulation: time_step, minimum_pitch, maximum_pitch

# Get original pitch for reference
select Sound 'originalName$'_fractal_tmp
To Pitch: time_step, minimum_pitch, maximum_pitch
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

select Pitch 'originalName$'_fractal_tmp
Remove

# Create NEW empty pitch tier with dense points
Create PitchTier: originalName$ + "_fractal_pitch", xmin, xmax
ptier_obj = selected("PitchTier")

# Build the fractal pitch terrain with DENSE points
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    u = (t - xmin) / dur
    
    pitch_sum = 0
    current_amplitude = 1
    current_frequency = base_frequency
    current_phase = 0
    
    # Fractal iteration layers
    for iteration from 1 to iterations
        wave_phase = (u + current_phase) * current_frequency * 2 * pi
        sine_component = sin(wave_phase)
        
        # Square wave component
        if sin(wave_phase) > 0
            square_component = 1
        else
            square_component = -1
        endif
        
        # Wave mixing
        combined_wave = sine_mix * sine_component + square_mix * square_component
        
        # Chaos component
        chaos_phase = wave_phase * 2.3
        chaos_component = chaos_factor * sin(chaos_phase) * randomUniform(0.9, 1.1)
        
        layer_value = current_amplitude * (combined_wave + chaos_component)
        pitch_sum = pitch_sum + layer_value
        
        # Update fractal parameters for next layer
        current_amplitude = current_amplitude * amplitude_decay
        current_frequency = current_frequency * frequency_multiplier
        current_phase = current_phase + phase_increment * iteration
    endfor
    
    # Time evolution envelope
    time_factor = 1 + time_evolution_strength * u ^ time_evolution_power
    pitch_st = pitch_depth * pitch_sum * time_factor
    
    # Low-frequency drift
    drift = drift_amplitude * sin(u * drift_frequency * pi) * u * u
    pitch_st = pitch_st + drift
    
    # Convert semitones to actual frequency
    new_f0 = median_f0 * (2 ^ (pitch_st / 12))
    
    # Clamp to reasonable range
    if new_f0 < minimum_pitch
        new_f0 = minimum_pitch
    elsif new_f0 > maximum_pitch
        new_f0 = maximum_pitch
    endif
    
    select ptier_obj
    Add point: t, new_f0
endfor

# Replace the pitch tier in manipulation
select Manipulation 'originalName$'_fractal_tmp
plus PitchTier 'originalName$'_fractal_pitch
Replace pitch tier

# Resynthesize
select Manipulation 'originalName$'_fractal_tmp
result = Get resynthesis (overlap-add)
Rename: originalName$ + "_fractal_result"

if play_after_processing
    Play
endif

# Cleanup
select Sound 'originalName$'_fractal_tmp
Remove

if not keep_intermediate_objects
    select Manipulation 'originalName$'_fractal_tmp
    plus PitchTier 'originalName$'_fractal_pitch
    Remove
endif

select Sound 'originalName$'_fractal_result