# ============================================================
# Praat AudioTools - Evolving Granular.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Delay or temporal structure script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# Praat AudioTools - Evolving Granular (Ultra-Fast)
# Optimized with Sound-object-based control signals + Presets
# ============================================================

form Evolving Granular Manipulation
    optionmenu Preset: 1
        option Custom
        option Dense Cloud
        option Sparse Texture
        option Rising Pitch Sweep
        option Falling Pitch Sweep
        option Three Region Evolution
        option Gentle Growth
        option Extreme Density Build
        option Micro Grains
    comment === GRAIN PARAMETERS (Custom only) ===
    real Initial_density 10.0
    real Final_density 25.0
    real Grain_duration_min 0.05
    real Grain_duration_max 0.15
    comment === EVOLUTION PARAMETERS ===
    choice Evolution_type: 1
        button Density_growth
        button Pitch_sweep
        button Statistical_shift
    real Pitch_shift_semitones 7.0
    comment === RANDOMIZATION ===
    real Position_randomness 0.3
    real Pitch_randomness 2.0
    real Amplitude_randomness 0.2
    comment === PERFORMANCE OPTIONS ===
    boolean Enable_pitch_shifting 1
    boolean Play_after 1
endform

# Apply presets
if preset = 2
    # Dense Cloud
    initial_density = 20.0
    final_density = 40.0
    grain_duration_min = 0.04
    grain_duration_max = 0.10
    evolution_type = 1
    pitch_shift_semitones = 3.0
    position_randomness = 0.4
    pitch_randomness = 1.5
    amplitude_randomness = 0.25
    enable_pitch_shifting = 1
    preset_name$ = "DenseCloud"
    
elsif preset = 3
    # Sparse Texture
    initial_density = 5.0
    final_density = 12.0
    grain_duration_min = 0.08
    grain_duration_max = 0.20
    evolution_type = 1
    pitch_shift_semitones = 2.0
    position_randomness = 0.2
    pitch_randomness = 1.0
    amplitude_randomness = 0.15
    enable_pitch_shifting = 1
    preset_name$ = "SparseTexture"
    
elsif preset = 4
    # Rising Pitch Sweep
    initial_density = 15.0
    final_density = 30.0
    grain_duration_min = 0.05
    grain_duration_max = 0.12
    evolution_type = 2
    pitch_shift_semitones = 12.0
    position_randomness = 0.25
    pitch_randomness = 2.0
    amplitude_randomness = 0.20
    enable_pitch_shifting = 1
    preset_name$ = "RisingPitchSweep"
    
elsif preset = 5
    # Falling Pitch Sweep
    initial_density = 15.0
    final_density = 30.0
    grain_duration_min = 0.05
    grain_duration_max = 0.12
    evolution_type = 2
    pitch_shift_semitones = -12.0
    position_randomness = 0.25
    pitch_randomness = 2.0
    amplitude_randomness = 0.20
    enable_pitch_shifting = 1
    preset_name$ = "FallingPitchSweep"
    
elsif preset = 6
    # Three Region Evolution
    initial_density = 18.0
    final_density = 35.0
    grain_duration_min = 0.03
    grain_duration_max = 0.15
    evolution_type = 3
    pitch_shift_semitones = 5.0
    position_randomness = 0.35
    pitch_randomness = 2.5
    amplitude_randomness = 0.25
    enable_pitch_shifting = 1
    preset_name$ = "ThreeRegionEvolution"
    
elsif preset = 7
    # Gentle Growth
    initial_density = 8.0
    final_density = 20.0
    grain_duration_min = 0.06
    grain_duration_max = 0.16
    evolution_type = 1
    pitch_shift_semitones = 2.0
    position_randomness = 0.15
    pitch_randomness = 1.0
    amplitude_randomness = 0.10
    enable_pitch_shifting = 1
    preset_name$ = "GentleGrowth"
    
elsif preset = 8
    # Extreme Density Build
    initial_density = 10.0
    final_density = 60.0
    grain_duration_min = 0.03
    grain_duration_max = 0.08
    evolution_type = 1
    pitch_shift_semitones = 5.0
    position_randomness = 0.5
    pitch_randomness = 3.0
    amplitude_randomness = 0.30
    enable_pitch_shifting = 1
    preset_name$ = "ExtremeDensityBuild"
    
elsif preset = 9
    # Micro Grains
    initial_density = 30.0
    final_density = 50.0
    grain_duration_min = 0.02
    grain_duration_max = 0.05
    evolution_type = 1
    pitch_shift_semitones = 7.0
    position_randomness = 0.3
    pitch_randomness = 4.0
    amplitude_randomness = 0.25
    enable_pitch_shifting = 0
    preset_name$ = "MicroGrains"
    
else
    preset_name$ = "Custom"
endif

# Get selected Sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency
n_channels = Get number of channels

# Convert to mono if stereo
if n_channels > 1
    selectObject: sound
    Convert to mono
    sound_mono = selected("Sound")
    sound = sound_mono
endif

writeInfoLine: "Creating Evolving Granular (Ultra-Fast)..."
appendInfoLine: "  Preset: ", preset_name$
appendInfoLine: "  Duration: ", fixed$(duration, 2), " s"
appendInfoLine: "  Evolution type: ", evolution_type$
appendInfoLine: ""

# Calculate total number of grains
avg_density = (initial_density + final_density) / 2
total_grains = round(avg_density * duration)

appendInfoLine: "  Total grains: ", total_grains
appendInfoLine: "  Grain density: ", fixed$(initial_density, 1), " → ", fixed$(final_density, 1), " grains/sec"
appendInfoLine: "  Generating grain parameters..."

# ===================================================================
# PRE-COMPUTE ALL GRAIN PARAMETERS AS SOUND OBJECTS
# ===================================================================

Create Sound from formula: "grain_source_pos", 1, 0, total_grains, total_grains, "0"
source_pos_sound = selected("Sound")

Create Sound from formula: "grain_output_pos", 1, 0, total_grains, total_grains, "0"
output_pos_sound = selected("Sound")

Create Sound from formula: "grain_duration", 1, 0, total_grains, total_grains, "0"
duration_sound = selected("Sound")

Create Sound from formula: "grain_pitch_shift", 1, 0, total_grains, total_grains, "0"
pitch_sound = selected("Sound")

Create Sound from formula: "grain_amplitude", 1, 0, total_grains, total_grains, "0"
amp_sound = selected("Sound")

# Generate grain parameters based on evolution type
if evolution_type = 1
    call GenerateDensityGrowth
elsif evolution_type = 2
    call GeneratePitchSweep
else
    call GenerateStatisticalShift
endif

appendInfoLine: "  Parameters generated"
appendInfoLine: "  Synthesizing grains..."

# ===================================================================
# GRAIN SYNTHESIS
# ===================================================================

# Create output sound (silence)
Create Sound from formula: sound_name$ + "_granular", 1, 0, duration, sampling_rate, "0"
output_sound = selected("Sound")

# Process each grain
valid_grains = 0
for grain to total_grains
    # Read grain parameters from Sound objects
    selectObject: source_pos_sound
    source_pos = Get value at sample number: 1, grain
    
    selectObject: output_pos_sound
    grain_start = Get value at sample number: 1, grain
    
    selectObject: duration_sound
    grain_dur = Get value at sample number: 1, grain
    
    selectObject: pitch_sound
    pitch_shift = Get value at sample number: 1, grain
    
    selectObject: amp_sound
    amp_factor = Get value at sample number: 1, grain
    
    # Skip invalid grains (marked with negative duration)
    if grain_dur > 0
        call AddGrainFast 'source_pos' 'grain_start' 'grain_dur' 'pitch_shift' 'amp_factor'
        valid_grains = valid_grains + 1
    endif
    
    if grain mod 50 = 0
        appendInfoLine: "  Progress: ", grain, "/", total_grains, " (", fixed$(grain/total_grains*100, 1), "%)"
    endif
endfor

# Clean up control sounds
removeObject: source_pos_sound, output_pos_sound, duration_sound, pitch_sound, amp_sound

# ===================================================================
# FINALIZE
# ===================================================================

selectObject: output_sound
Scale peak: 0.95
Rename: sound_name$ + "_" + preset_name$

# Clean up mono conversion if it was done
if n_channels > 1
    removeObject: sound_mono
endif

appendInfoLine: ""
appendInfoLine: "✓ Evolving Granular complete!"
appendInfoLine: "  Valid grains: ", valid_grains, "/", total_grains
appendInfoLine: "  Duration: ", fixed$(duration, 2), " s"

if play_after
    Play
endif

# ===================================================================
# PROCEDURES - PARAMETER GENERATION
# ===================================================================

procedure GenerateDensityGrowth
    for grain to total_grains
        normalized_time = (grain - 1) / total_grains
        current_density = initial_density + (final_density - initial_density) * normalized_time
        
        grain_center = normalized_time * duration + position_randomness * randomGauss(0, 1)
        grain_dur = grain_duration_min + (grain_duration_max - grain_duration_min) * randomUniform(0, 1)
        grain_start = grain_center - grain_dur / 2
        
        time_probability = current_density / ((initial_density + final_density) / 2)
        
        if randomUniform(0, 1) < time_probability and grain_start >= 0 and grain_start + grain_dur <= duration
            source_pos = grain_start + position_randomness * randomGauss(0, 0.5)
            source_pos = max(0, min(duration - grain_dur, source_pos))
            
            pitch_shift = pitch_randomness * randomGauss(0, 1)
            amp_factor = 1 + amplitude_randomness * randomGauss(0, 1)
            amp_factor = max(0.3, min(1.5, amp_factor))
            
            call StoreGrainParams 'grain' 'source_pos' 'grain_start' 'grain_dur' 'pitch_shift' 'amp_factor'
        else
            call StoreGrainParams 'grain' 0 0 -1 0 0
        endif
    endfor
endproc

procedure GeneratePitchSweep
    for grain to total_grains
        grain_center = randomUniform(0, duration)
        normalized_time = grain_center / duration
        
        grain_dur = grain_duration_min + (grain_duration_max - grain_duration_min) * randomUniform(0, 1)
        grain_start = grain_center - grain_dur / 2
        
        if grain_start >= 0 and grain_start + grain_dur <= duration
            current_pitch_shift = pitch_shift_semitones * normalized_time
            pitch_shift = current_pitch_shift + pitch_randomness * randomGauss(0, 1)
            
            source_pos = grain_start + position_randomness * randomGauss(0, 0.3)
            source_pos = max(0, min(duration - grain_dur, source_pos))
            
            amp_factor = (1.2 - normalized_time * 0.4) + amplitude_randomness * randomGauss(0, 1)
            amp_factor = max(0.3, min(1.5, amp_factor))
            
            call StoreGrainParams 'grain' 'source_pos' 'grain_start' 'grain_dur' 'pitch_shift' 'amp_factor'
        else
            call StoreGrainParams 'grain' 0 0 -1 0 0
        endif
    endfor
endproc

procedure GenerateStatisticalShift
    for grain to total_grains
        grain_center = randomUniform(0, duration)
        normalized_time = grain_center / duration
        
        if normalized_time < 0.33
            grain_dur = 0.08 + 0.1 * randomUniform(0, 1)
            pitch_shift = -4 + pitch_randomness * randomGauss(0, 1)
            amp_factor = 0.9 + amplitude_randomness * randomGauss(0, 1)
        elsif normalized_time < 0.66
            grain_dur = 0.04 + 0.06 * randomUniform(0, 1)
            pitch_shift = 2 + pitch_randomness * 1.5 * randomGauss(0, 1)
            amp_factor = 0.7 + amplitude_randomness * randomGauss(0, 1)
        else
            grain_dur = 0.02 + 0.04 * randomUniform(0, 1)
            pitch_shift = 8 + pitch_randomness * 2 * randomGauss(0, 1)
            amp_factor = 0.5 + amplitude_randomness * randomGauss(0, 1)
        endif
        
        grain_start = grain_center - grain_dur / 2
        
        if grain_start >= 0 and grain_start + grain_dur <= duration
            source_pos = grain_start + position_randomness * randomGauss(0, 0.5)
            source_pos = max(0, min(duration - grain_dur, source_pos))
            amp_factor = max(0.2, min(1.3, amp_factor))
            
            call StoreGrainParams 'grain' 'source_pos' 'grain_start' 'grain_dur' 'pitch_shift' 'amp_factor'
        else
            call StoreGrainParams 'grain' 0 0 -1 0 0
        endif
    endfor
endproc

procedure StoreGrainParams grain source_pos grain_start grain_dur pitch_shift amp_factor
    selectObject: source_pos_sound
    Set value at sample number: 1, grain, source_pos
    
    selectObject: output_pos_sound
    Set value at sample number: 1, grain, grain_start
    
    selectObject: duration_sound
    Set value at sample number: 1, grain, grain_dur
    
    selectObject: pitch_sound
    Set value at sample number: 1, grain, pitch_shift
    
    selectObject: amp_sound
    Set value at sample number: 1, grain, amp_factor
endproc

# ===================================================================
# GRAIN SYNTHESIS - FAST VERSION
# ===================================================================

procedure AddGrainFast source_pos grain_start grain_dur pitch_shift amp_factor
    # Extract grain
    selectObject: sound
    Extract part: source_pos, source_pos + grain_dur, "Hanning", 1, "no"
    grain_extract = selected("Sound")
    
    # Apply pitch shift if enabled
    pitch_factor = 2^(pitch_shift / 12)
    if enable_pitch_shifting and grain_dur >= 0.04 and abs(pitch_factor - 1) > 0.02
        selectObject: grain_extract
        Lengthen (overlap-add): 80, 600, pitch_factor
        grain_shifted = selected("Sound")
        removeObject: grain_extract
        grain_extract = grain_shifted
    endif
    
    # Apply amplitude
    selectObject: grain_extract
    Formula: "self * amp_factor"
    
    # Get grain duration after pitch shift
    grain_actual_dur = Get total duration
    grain_end = grain_start + grain_actual_dur
    
    # Mix into output using Formula (part) - FAST!
    s_grain_start$ = fixed$(grain_start, 6)
    grain_id$ = string$(grain_extract)
    
    selectObject: output_sound
    Formula (part): grain_start, grain_end, 1, 1, "self + object(" + grain_id$ + ", x - " + s_grain_start$ + ")"
    
    # Clean up
    removeObject: grain_extract
endproc
