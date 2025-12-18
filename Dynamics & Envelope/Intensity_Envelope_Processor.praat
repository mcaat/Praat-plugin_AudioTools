# ============================================================
# Praat AudioTools - Intensity_Envelope_Processor.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 1.0 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Unified intensity envelope manipulation tool combining 8 transformation types
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# STAGE 1: Select Processing Type
# ============================================================

form Intensity Envelope Processor - Select Type
    comment Choose transformation type:
    optionmenu Processing_type 1
        option Power Shaping
        option Sine Modulation
        option Rhythmic Gating
        option Time Shift (Early/Late)
        option Time Scaling (Compress/Stretch)
        option Wave Inversion
endform

# ============================================================
# STAGE 2: Type-Specific Parameters (using beginPause/endPause)
# ============================================================

if processing_type = 1
    # Power Shaping
    beginPause: "Power Shaping Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Shaping"
            option: "Medium Shaping"
            option: "Heavy Shaping"
            option: "Extreme Shaping"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Power parameters:"
        positive: "exponent", 2.0
        positive: "intensity_scale", 100
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        exponent = 1.3
        intensity_scale = 100
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        exponent = 2.0
        intensity_scale = 100
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        exponent = 3.0
        intensity_scale = 100
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        exponent = 4.0
        intensity_scale = 100
        scale_intensities = 1
    endif
    
elsif processing_type = 2
    # Sine Modulation
    beginPause: "Sine Modulation Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Modulation"
            option: "Medium Modulation"
            option: "Heavy Modulation"
            option: "Extreme Modulation"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Modulation parameters:"
        positive: "modulation_frequency", 10
        positive: "modulation_center", 0.5
        positive: "modulation_depth", 0.5
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        modulation_frequency = 5
        modulation_center = 0.7
        modulation_depth = 0.2
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        modulation_frequency = 10
        modulation_center = 0.5
        modulation_depth = 0.5
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        modulation_frequency = 15
        modulation_center = 0.5
        modulation_depth = 0.45
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        modulation_frequency = 25
        modulation_center = 0.5
        modulation_depth = 0.48
        scale_intensities = 1
    endif
    
elsif processing_type = 3
    # Rhythmic Gating
    beginPause: "Rhythmic Gating Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Gate"
            option: "Medium Gate"
            option: "Heavy Gate"
            option: "Extreme Gate"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Gating parameters:"
        positive: "gate_frequency", 8
        positive: "minimum_level", 0.3
        positive: "maximum_level", 1.0
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        gate_frequency = 4
        minimum_level = 0.5
        maximum_level = 1.0
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        gate_frequency = 8
        minimum_level = 0.3
        maximum_level = 1.0
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        gate_frequency = 12
        minimum_level = 0.15
        maximum_level = 1.0
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        gate_frequency = 16
        minimum_level = 0.05
        maximum_level = 1.0
        scale_intensities = 1
    endif
    
elsif processing_type = 4
    # Time Shift
    beginPause: "Time Shift Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Early"
            option: "Medium Early"
            option: "Heavy Early"
            option: "Extreme Early"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Time shift (negative = earlier):"
        real: "shift_amount_seconds", -0.3
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.08
        subtract_mean = 1
        shift_amount_seconds = -0.15
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        shift_amount_seconds = -0.3
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.12
        subtract_mean = 1
        shift_amount_seconds = -0.5
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.15
        subtract_mean = 1
        shift_amount_seconds = -0.8
        scale_intensities = 1
    endif
    
elsif processing_type = 5
    # Time Scaling
    beginPause: "Time Scaling Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Stretch"
            option: "Medium Stretch"
            option: "Heavy Stretch"
            option: "Extreme Stretch"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Time scaling (>1 = stretch, <1 = compress):"
        positive: "time_scale_factor", 2.0
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        time_scale_factor = 1.3
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        time_scale_factor = 2.0
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        time_scale_factor = 3.0
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        time_scale_factor = 4.0
        scale_intensities = 1
    endif
    
elsif processing_type = 6
    # Wave Inversion
    beginPause: "Wave Inversion Parameters"
        comment: "Preset:"
        optionMenu: "preset", 1
            option: "Custom"
            option: "Subtle Inversion"
            option: "Medium Inversion"
            option: "Heavy Inversion"
            option: "Extreme Inversion"
        comment: "Intensity extraction:"
        positive: "minimum_pitch", 100
        positive: "time_step", 0.1
        boolean: "subtract_mean", 1
        comment: "Inversion midpoint:"
        positive: "inversion_midpoint", 100
        comment: "Output:"
        boolean: "scale_intensities", 1
        boolean: "play_after_processing", 1
        boolean: "keep_intermediate_objects", 0
    clicked = endPause: "Cancel", "OK", 2, 1
    if clicked = 1
        exitScript: ""
    endif
    
    # Apply presets
    if preset = 2
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        inversion_midpoint = 90
        scale_intensities = 1
    elsif preset = 3
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        inversion_midpoint = 80
        scale_intensities = 1
    elsif preset = 4
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        inversion_midpoint = 70
        scale_intensities = 1
    elsif preset = 5
        minimum_pitch = 100
        time_step = 0.1
        subtract_mean = 1
        inversion_midpoint = 60
        scale_intensities = 1
    endif
endif

# ============================================================
# MAIN PROCESSING
# ============================================================

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Store original sound
original_sound = selected("Sound")
originalName$ = selected$("Sound")

# Determine suffix based on processing type
if processing_type = 1
    suffix$ = "_power_shaped"
elsif processing_type = 2
    suffix$ = "_sine_modulated"
elsif processing_type = 3
    suffix$ = "_rhythmic_gated"
elsif processing_type = 4
    suffix$ = "_time_shifted"
elsif processing_type = 5
    suffix$ = "_time_scaled"
elsif processing_type = 6
    suffix$ = "_wave_inverted"
endif

# Copy the sound
copy_sound = Copy: originalName$ + suffix$

# Get sound duration (needed for time scaling)
sound_duration = Get total duration

# Extract intensity
intensity_obj = To Intensity: minimum_pitch, time_step, subtract_mean

# ============================================================
# APPLY TRANSFORMATION
# ============================================================

if processing_type = 1
    # Power Shaping
    Formula: "(self/'intensity_scale')^'exponent' * 'intensity_scale'"
    
elsif processing_type = 2
    # Sine Modulation
    Formula: "self * ('modulation_center' + 'modulation_depth' * sin(x * 'modulation_frequency'))"
    
elsif processing_type = 3
    # Rhythmic Gating
    gate_depth = maximum_level - minimum_level
    Formula: "self * ('minimum_level' + 'gate_depth' * (sin(x * 'gate_frequency') > 0))"
    
elsif processing_type = 4
    # Time Shift
    Shift times to: "start time", shift_amount_seconds
    
elsif processing_type = 5
    # Time Scaling
    if time_scale_factor >= 1
        # Stretch (slower)
        Scale times by: time_scale_factor
    else
        # Compress (faster)
        new_duration = sound_duration / time_scale_factor
        Scale times to: 0, new_duration
    endif
    
elsif processing_type = 6
    # Wave Inversion
    Formula: "'inversion_midpoint' - self"
endif

# ============================================================
# CONVERT AND APPLY
# ============================================================

# Convert to IntensityTier
intensity_tier = Down to IntensityTier

# Select sound and intensity tier, then multiply
select original_sound
plus intensity_tier
Multiply: scale_intensities

# Rename result
Rename: originalName$ + "_result"
result_sound = selected("Sound")

# ============================================================
# OUTPUT AND CLEANUP
# ============================================================

# Play if requested
if play_after_processing
    Play
endif

# Clean up intermediate objects unless requested to keep
if not keep_intermediate_objects
    select copy_sound
    plus intensity_obj
    plus intensity_tier
    Remove
else
    select result_sound
endif