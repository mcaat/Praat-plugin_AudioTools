# ============================================================
# Praat AudioTools - ADAPTIVE GRAIN CLOUD SYNTHESIS.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Adaptive granular synthesis with spectral-content-based grain duration
#   and dynamics preservation
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Adaptive Grain Cloud Synthesis
    comment Select a Sound object first
    optionmenu Preset 1
        option Custom
        option Dense Cloud
        option Sparse Cloud
        option Micro-Grains
        option Long Grains
        option Spectral Freeze
        option Rhythmic Pulse
        option Chaotic Swarm
    comment ─────────────────────────────────
    positive grain_size_ms 50
    positive grain_overlap 0.75
    positive density_factor 2.0
    positive pitch_scatter 0.2
    positive time_scatter 0.1
    boolean reverse_grains 0
    boolean apply_pitch_shift 0
    choice window_type 1
        button Rectangular
        button Triangular
        button Parabolic
    comment Output scaling
    choice scaling_method 2
        button None (preserve dynamics)
        button Gentle RMS normalization
        button Peak normalization to 0.7
    comment Safety
    positive max_grains 2000
endform

# Apply preset values
if preset = 2
    # Dense Cloud - adjusted to avoid object overflow
    grain_size_ms = 40
    grain_overlap = 0.75
    density_factor = 2.5
    pitch_scatter = 0.1
    reverse_grains = 0
    apply_pitch_shift = 0
    window_type = 2
elsif preset = 3
    # Sparse Cloud
    grain_size_ms = 80
    grain_overlap = 0.3
    density_factor = 0.5
    pitch_scatter = 0.3
    reverse_grains = 1
    apply_pitch_shift = 1
    window_type = 3
elsif preset = 4
    # Micro-Grains
    grain_size_ms = 15
    grain_overlap = 0.5
    density_factor = 3.0
    pitch_scatter = 0.5
    reverse_grains = 0
    apply_pitch_shift = 1
    window_type = 2
elsif preset = 5
    # Long Grains
    grain_size_ms = 200
    grain_overlap = 0.9
    density_factor = 1.0
    pitch_scatter = 0.05
    reverse_grains = 0
    apply_pitch_shift = 0
    window_type = 3
elsif preset = 6
    # Spectral Freeze
    grain_size_ms = 60
    grain_overlap = 0.9
    density_factor = 2.5
    pitch_scatter = 0.0
    reverse_grains = 0
    apply_pitch_shift = 0
    window_type = 2
elsif preset = 7
    # Rhythmic Pulse
    grain_size_ms = 40
    grain_overlap = 0.0
    density_factor = 2.0
    pitch_scatter = 0.15
    reverse_grains = 0
    apply_pitch_shift = 0
    window_type = 1
elsif preset = 8
    # Chaotic Swarm
    grain_size_ms = 25
    grain_overlap = 0.6
    density_factor = 3.5
    pitch_scatter = 0.8
    reverse_grains = 1
    apply_pitch_shift = 1
    window_type = 2
endif

# Check if a sound object is selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

# Store original sound object and name BEFORE any operations
original_sound = selected("Sound")
original_name$ = selected$("Sound")

# Convert to mono (creates a new object with _mono suffix)
Convert to mono
mono_sound = selected("Sound")

# Get sound info from mono version
selectObject: mono_sound
duration = Get total duration
sample_rate = Get sample rate
num_channels = Get number of channels

# Get original RMS for dynamics preservation
original_rms = Get root-mean-square: 0, 0

# Validate parameters
if duration < grain_size_ms/1000
    exitScript: "Sound is shorter than grain size"
endif

# Calculate grain parameters
base_grain_duration = grain_size_ms / 1000
hop_time = base_grain_duration * (1 - grain_overlap)
num_grains = round(duration / hop_time * density_factor)

# SAFETY CHECK: Limit number of grains to prevent Praat overflow
if num_grains > max_grains
    appendInfoLine: "WARNING: Calculated ", num_grains, " grains (exceeds max_grains=", max_grains, ")"
    appendInfoLine: "Limiting to ", max_grains, " grains to prevent object overflow"
    num_grains = max_grains
endif

# Arrays to store grain IDs
grainIDs# = zero#(num_grains)
grainCount = 0

# Generate grains
for i from 1 to num_grains
    # Get source time within valid range (with adaptive grain duration)
    # We use base duration for now, will adjust per grain
    max_start = duration - base_grain_duration * 1.5
    if max_start > 0
        source_time = randomUniform(0, max_start)
        
        # Convert window_type number to string
        if window_type = 1
            window_shape$ = "rectangular"
        elsif window_type = 2
            window_shape$ = "triangular"
        else
            window_shape$ = "parabolic"
        endif
        
        # Extract temporary grain to analyze spectral content
        selectObject: mono_sound
        temp_extract_dur = min(base_grain_duration, duration - source_time)
        Extract part: source_time, source_time + temp_extract_dur, window_shape$, 1, 0
        temp_grain = selected("Sound")
        
        # Get spectral centroid for adaptive processing
        selectObject: temp_grain
        To Spectrum: "yes"
        spectrum = selected("Spectrum")
        centroid = Get centre of gravity: 2
        selectObject: spectrum
        Remove
        
        # ADAPTIVE: Adjust grain duration based on spectral content
        if centroid > 2000
            # High frequency content - shorter grains
            grain_duration = base_grain_duration * 0.6
            local_pitch_scatter = pitch_scatter * 2
        else
            # Low frequency content - longer grains
            grain_duration = base_grain_duration * 1.4
            local_pitch_scatter = pitch_scatter * 0.5
        endif
        
        # Remove temp grain and extract with adaptive duration
        selectObject: temp_grain
        Remove
        
        # Extract grain with adaptive duration
        selectObject: mono_sound
        actual_duration = min(grain_duration, duration - source_time)
        Extract part: source_time, source_time + actual_duration, window_shape$, 1, 0
        grain = selected("Sound")
        
        # Apply pitch shifting if needed (now using resampling)
        if apply_pitch_shift
            grain_pitch_shift = randomGauss(0, local_pitch_scatter)
            if abs(grain_pitch_shift) > 0.01
                selectObject: grain
                # Real pitch shift via resampling
                shift_semitones = grain_pitch_shift
                new_sample_rate = sample_rate * 2^(shift_semitones/12)
                Override sampling frequency: new_sample_rate
                Resample: sample_rate, 50
                shifted_grain = selected("Sound")
                
                selectObject: grain
                Remove
                grain = shifted_grain
            endif
        endif
        
        # Reverse grain randomly
        selectObject: grain
        if reverse_grains and randomUniform(0, 1) > 0.5
            Reverse
        endif
        
        # NO PER-GRAIN NORMALIZATION - preserve dynamics!
        # (removed the "Scale: 0.3" that was here)
        
        # Store grain ID
        grainCount += 1
        grainIDs#[grainCount] = grain
        Rename: original_name$ + "_grain_" + string$(grainCount)
    endif
endfor

# Concatenate ONLY the grains if any were created
if grainCount > 0
    # Select only the first grain
    selectObject: grainIDs#[1]
    
    # Add the rest of the grains to selection
    for i from 2 to grainCount
        if grainIDs#[i] != 0
            plusObject: grainIDs#[i]
        endif
    endfor
    
    # Concatenate only the selected grains
    output = Concatenate
    Rename: original_name$ + "_granular"
    
    # Clean up individual grains
    for i from 1 to grainCount
        if grainIDs#[i] != 0
            removeObject: grainIDs#[i]
        endif
    endfor
    
    # Apply selected scaling method
    selectObject: output
    if scaling_method = 2
        # Gentle RMS normalization - preserves relative dynamics
        output_rms = Get root-mean-square: 0, 0
        if output_rms > 0
            scale_factor = original_rms / output_rms
            # Limit scaling to reasonable range
            scale_factor = min(scale_factor, 3.0)
            Scale: scale_factor
            # Ensure we don't clip
            max_amp = Get maximum: 0, 0, "None"
            if max_amp > 0.95
                Scale peak: 0.95
            endif
        endif
    elsif scaling_method = 3
        # Gentle peak normalization
        max_amplitude = Get maximum: 0, 0, "None"
        if max_amplitude > 0
            Scale peak: 0.7
        endif
    endif
    # If scaling_method = 1, do nothing (preserve exact dynamics)
    
    appendInfoLine: "=== Adaptive Grain Cloud Synthesis Complete ==="
    appendInfoLine: "Created ", grainCount, " grains from '", original_name$, "'"
    appendInfoLine: "Adaptive grain durations: ", fixed$(base_grain_duration * 0.6, 3), " - ", fixed$(base_grain_duration * 1.4, 3), " sec"
    appendInfoLine: "Scaling method: ", scaling_method
    appendInfoLine: "Result: '", original_name$ + "_granular'"
else
    appendInfoLine: "No grains could be created with current parameters"
endif

# Clean up mono sound
selectObject: mono_sound
Remove

# Clean window - select only the result
if grainCount > 0
    selectObject: output
endif
Play
