# ============================================================
# Praat AudioTools - QUANTUM_PITCH_JUMPS.praat
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

form Quantum Pitch Jumps Effect
    comment Preset configurations for quantum pitch leap effects
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Quantum
        option Moderate Quantum  
        option Aggressive Quantum
        option Extreme Quantum
        option Glitchy Micro
        option Harmonic Leaps
        option Chaotic Quantum
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    natural quantum_levels 12
    positive jump_probability 0.4
    comment (0-1: probability of quantum jumps)
    positive glitch_probability 0.15
    comment (0-1: probability of glitch events)
    comment Energy modulation:
    positive energy_min 0.5
    positive energy_max 2.0
    comment Glitch deviation range:
    real glitch_min_semitones -2
    real glitch_max_semitones 3
    comment Quantum uncertainty:
    positive uncertainty_min 0.98
    positive uncertainty_max 1.02
    comment Pitch analysis:
    positive time_step 0.005
    positive minimum_pitch 50
    positive maximum_pitch 900
    comment Output:
    positive output_sample_rate 44100
    positive resample_precision 50
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Apply presets
if preset = 2    ; Gentle Quantum
    quantum_levels = 8
    jump_probability = 0.2
    glitch_probability = 0.05
    energy_min = 0.8
    energy_max = 1.5
    glitch_min_semitones = -1
    glitch_max_semitones = 1.5
    uncertainty_min = 0.99
    uncertainty_max = 1.01
elsif preset = 3    ; Moderate Quantum
    quantum_levels = 12
    jump_probability = 0.3
    glitch_probability = 0.1
    energy_min = 0.7
    energy_max = 1.8
    glitch_min_semitones = -1.5
    glitch_max_semitones = 2
    uncertainty_min = 0.98
    uncertainty_max = 1.02
elsif preset = 4    ; Aggressive Quantum
    quantum_levels = 16
    jump_probability = 0.5
    glitch_probability = 0.2
    energy_min = 0.5
    energy_max = 2.2
    glitch_min_semitones = -3
    glitch_max_semitones = 4
    uncertainty_min = 0.95
    uncertainty_max = 1.05
elsif preset = 5    ; Extreme Quantum
    quantum_levels = 24
    jump_probability = 0.7
    glitch_probability = 0.3
    energy_min = 0.3
    energy_max = 3.0
    glitch_min_semitones = -5
    glitch_max_semitones = 6
    uncertainty_min = 0.9
    uncertainty_max = 1.1
elsif preset = 6    ; Glitchy Micro
    quantum_levels = 5
    jump_probability = 0.6
    glitch_probability = 0.4
    energy_min = 0.9
    energy_max = 1.2
    glitch_min_semitones = -0.5
    glitch_max_semitones = 1
    uncertainty_min = 0.995
    uncertainty_max = 1.005
elsif preset = 7    ; Harmonic Leaps
    quantum_levels = 7
    jump_probability = 0.4
    glitch_probability = 0.05
    energy_min = 0.6
    energy_max = 1.8
    glitch_min_semitones = -1
    glitch_max_semitones = 1
    uncertainty_min = 0.98
    uncertainty_max = 1.02
elsif preset = 8    ; Chaotic Quantum
    quantum_levels = 32
    jump_probability = 0.8
    glitch_probability = 0.5
    energy_min = 0.2
    energy_max = 4.0
    glitch_min_semitones = -8
    glitch_max_semitones = 10
    uncertainty_min = 0.8
    uncertainty_max = 1.2
endif

originalName$ = selected$("Sound")
orig_sr = Get sampling frequency

# Define harmonic ratios with microtones
ratios# = {1, 16/15, 9/8, 6/5, 5/4, 4/3, 7/5, 3/2, 8/5, 5/3, 16/9, 15/8, 2}

# Get original sound duration
xmin = Get start time
xmax = Get end time
dur = xmax - xmin

# Create dense point sampling for smooth transitions
npoints = round(dur / 0.01)
if npoints < 200
    npoints = 200
endif
if npoints > 2000
    npoints = 2000
endif

Copy: originalName$ + "_quantum_tmp"
To Manipulation: time_step, minimum_pitch, maximum_pitch

# Get original pitch for reference
select Sound 'originalName$'_quantum_tmp
To Pitch: time_step, minimum_pitch, maximum_pitch
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

select Pitch 'originalName$'_quantum_tmp
Remove

# Create NEW empty pitch tier with dense points
Create PitchTier: originalName$ + "_quantum_pitch", xmin, xmax
ptier_obj = selected("PitchTier")

# Initialize quantum state
current_level = 1
energy_level = 1
last_level = 1
last_energy = 1

# Build the quantum pitch curve with DENSE points
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    
    # Normalized position (0 to 1)
    pos = i / (npoints-1)
    
    # Quantum tunnel events - more frequent evaluation with dense points
    if randomUniform(0, 1) < (jump_probability / (npoints/100))
        current_level = randomInteger(1, quantum_levels)
        energy_level = randomUniform(energy_min, energy_max)
    endif
    
    # Glitch events
    glitch_factor = 0
    if randomUniform(0, 1) < (glitch_probability / (npoints/100))
        glitch_factor = randomUniform(glitch_min_semitones, glitch_max_semitones)
    endif
    
    ratio_index = ((current_level - 1) mod size(ratios#)) + 1
    base_ratio = ratios#[ratio_index]
    
    # Apply energy modulation and glitches
    glitch_multiplier = exp((ln(2) / 12) * glitch_factor)
    final_ratio = base_ratio * energy_level * glitch_multiplier
    
    # Add quantum uncertainty
    uncertainty = randomUniform(uncertainty_min, uncertainty_max)
    final_ratio = final_ratio * uncertainty
    
    # Convert ratio to actual frequency
    new_f0 = median_f0 * final_ratio
    
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
select Manipulation 'originalName$'_quantum_tmp
plus PitchTier 'originalName$'_quantum_pitch
Replace pitch tier

# Resynthesize
select Manipulation 'originalName$'_quantum_tmp
result = Get resynthesis (overlap-add)
Rename: originalName$ + "_quantum_result"

# Resample if needed
if output_sample_rate <> orig_sr
    select Sound 'originalName$'_quantum_result
    Resample: output_sample_rate, resample_precision
endif

if play_after_processing
    Play
endif

# Cleanup
select Sound 'originalName$'_quantum_tmp
Remove

if not keep_intermediate_objects
    select Manipulation 'originalName$'_quantum_tmp
    plus PitchTier 'originalName$'_quantum_pitch
    Remove
endif

# Select the final result
select Sound 'originalName$'_quantum_result