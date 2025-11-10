# ============================================================
# Praat AudioTools - PITCH_MORPHING_BETWEEN_TARGETS.praat
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

form Pitch Morphing Between Targets
    comment Preset configurations for pitch morphing effects
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Waves
        option Emotional Arcs
        option Dramatic Leaps
        option Chromatic Walk
        option Microtonal Glide
        option Tension Build
        option Chaotic Dance
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    sentence target_pitches 0_12_-8_15_-12_20_5_-5
    comment (underscore-separated semitone values)
    comment Morphing behavior:
    positive morph_smoothness 1.5
    comment (higher = smoother transitions)
    positive overshoot_factor 0.4
    comment (elastic overshoot amount)
    comment Dynamics:
    positive tension_strength 0.1
    positive vibrato_amount 0.3
    positive vibrato_frequency 25
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

# Apply presets with different target patterns
if preset = 2    ; Gentle Waves
    target_pitches$ = "0_3_-2_5_-1_2_0"
    morph_smoothness = 2.0
    overshoot_factor = 0.2
    tension_strength = 0.05
    vibrato_amount = 0.2
elsif preset = 3    ; Emotional Arcs
    target_pitches$ = "0_7_-5_12_-8_15_-12"
    morph_smoothness = 1.8
    overshoot_factor = 0.3
    tension_strength = 0.15
    vibrato_amount = 0.4
elsif preset = 4    ; Dramatic Leaps
    target_pitches$ = "0_12_-12_24_-24_12_0"
    morph_smoothness = 1.2
    overshoot_factor = 0.6
    tension_strength = 0.25
    vibrato_amount = 0.5
elsif preset = 5    ; Chromatic Walk
    target_pitches$ = "0_2_4_5_7_9_11_12_11_9_7_5_4_2_0"
    morph_smoothness = 1.5
    overshoot_factor = 0.1
    tension_strength = 0.08
    vibrato_amount = 0.15
elsif preset = 6    ; Microtonal Glide
    target_pitches$ = "0_1.5_-1_2.5_-0.5_1_-1.5_0.5"
    morph_smoothness = 2.5
    overshoot_factor = 0.15
    tension_strength = 0.03
    vibrato_amount = 0.1
elsif preset = 7    ; Tension Build
    target_pitches$ = "0_3_1_6_2_9_4_12_5"
    morph_smoothness = 1.3
    overshoot_factor = 0.4
    tension_strength = 0.3
    vibrato_amount = 0.25
elsif preset = 8    ; Chaotic Dance
    target_pitches$ = "0_7_-3_15_-8_5_12_-5_20_-12"
    morph_smoothness = 0.8
    overshoot_factor = 0.8
    tension_strength = 0.4
    vibrato_amount = 0.6
endif

originalName$ = selected$("Sound")
orig_sr = Get sampling frequency

# Parse target pitches
targets$ = target_pitches$ + " "
targets$ = replace$(targets$, "_", " ", 0)
n_targets = 0

repeat
    space_pos = index(targets$, " ")
    if space_pos > 1
        n_targets += 1
        target_val$[n_targets] = left$(targets$, space_pos - 1)
        targets$ = right$(targets$, length(targets$) - space_pos)
    endif
until space_pos <= 1

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

Copy: originalName$ + "_morph_tmp"
To Manipulation: time_step, minimum_pitch, maximum_pitch

# Get original pitch for reference
select Sound 'originalName$'_morph_tmp
To Pitch: time_step, minimum_pitch, maximum_pitch
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

select Pitch 'originalName$'_morph_tmp
Remove

# Create NEW empty pitch tier with dense points
Create PitchTier: originalName$ + "_morph_pitch", xmin, xmax
ptier_obj = selected("PitchTier")

# Build the morphing pitch curve with DENSE points
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    u = (t - xmin) / dur * (n_targets - 1)
    
    target_low = floor(u) + 1
    target_high = target_low + 1
    
    if target_high > n_targets
        target_high = n_targets
        target_low = n_targets
    endif
    
    fraction = u - floor(u)
    
    # Smooth interpolation with elastic curve
    elastic_curve = fraction^morph_smoothness / (fraction^morph_smoothness + (1 - fraction)^morph_smoothness)
    overshoot = overshoot_factor * sin(fraction * pi) * (1 - fraction) * fraction
    smooth_fraction = elastic_curve + overshoot
    
    pitch_low = number(target_val$[target_low])
    pitch_high = number(target_val$[target_high])
    
    # Tension effect based on pitch distance
    pitch_distance = abs(pitch_high - pitch_low)
    tension = 1 + tension_strength * pitch_distance * sin(fraction * 3 * pi)
    
    # Interpolated pitch
    interpolated_pitch = pitch_low + smooth_fraction * (pitch_high - pitch_low)
    
    # Vibrato effect
    vibrato = vibrato_amount * sin(fraction * vibrato_frequency * pi) * (1 - abs(2 * fraction - 1))
    
    # Final pitch in semitones
    final_pitch_st = interpolated_pitch * tension + vibrato
    
    # Convert semitones to actual frequency
    new_f0 = median_f0 * (2 ^ (final_pitch_st / 12))
    
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
select Manipulation 'originalName$'_morph_tmp
plus PitchTier 'originalName$'_morph_pitch
Replace pitch tier

# Resynthesize
select Manipulation 'originalName$'_morph_tmp
result = Get resynthesis (overlap-add)
Rename: originalName$ + "_morph_result"

if play_after_processing
    Play
endif

# Cleanup
select Sound 'originalName$'_morph_tmp
Remove

if not keep_intermediate_objects
    select Manipulation 'originalName$'_morph_tmp
    plus PitchTier 'originalName$'_morph_pitch
    Remove
endif

select Sound 'originalName$'_morph_result