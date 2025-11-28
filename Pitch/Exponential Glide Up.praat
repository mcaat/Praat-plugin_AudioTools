# ============================================================
# Praat AudioTools - Exponential Glide Up.praat
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

form Pitch Glide Up Effect
    comment Preset configurations for exponential pitch rises
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Glide
        option Moderate Rise
        option Dramatic Sweep
        option Extreme Rocket
        option Slow Build
        option Quick Jump
        option Cinematic Rise
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    positive semitones_rise 7
    comment (total pitch rise in semitones)
    positive curve_steepness 3
    comment (higher = faster initial rise)
    comment Pitch analysis:
    positive time_step 0.005
    positive minimum_pitch 50
    positive maximum_pitch 900
    comment Output options:
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Apply presets
if preset = 2    ; Gentle Glide
    semitones_rise = 5
    curve_steepness = 2
elsif preset = 3    ; Moderate Rise
    semitones_rise = 8
    curve_steepness = 3
elsif preset = 4    ; Dramatic Sweep
    semitones_rise = 12
    curve_steepness = 4
elsif preset = 5    ; Extreme Rocket
    semitones_rise = 24
    curve_steepness = 6
elsif preset = 6    ; Slow Build
    semitones_rise = 6
    curve_steepness = 1
elsif preset = 7    ; Quick Jump
    semitones_rise = 4
    curve_steepness = 8
elsif preset = 8    ; Cinematic Rise
    semitones_rise = 18
    curve_steepness = 2.5
endif

originalName$ = selected$("Sound")

# Get original sound info
xmin = Get start time
xmax = Get end time
dur = xmax - xmin

# Create dense point sampling
npoints = round(dur / 0.01)
if npoints < 200
    npoints = 200
endif
if npoints > 2000
    npoints = 2000
endif

# Create manipulation
Copy: originalName$ + "_tmp"
To Manipulation: time_step, minimum_pitch, maximum_pitch

# Get original pitch for reference
select Sound 'originalName$'_tmp
To Pitch: time_step, minimum_pitch, maximum_pitch
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

select Pitch 'originalName$'_tmp
Remove

# Create NEW empty pitch tier
Create PitchTier: originalName$ + "_pitch", xmin, xmax
ptier_obj = selected("PitchTier")

# Build exponential pitch rise curve
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    
    # Normalized position (0 to 1)
    u = i / (npoints-1)
    
    # Exponential rise curve
    if curve_steepness > 0.001
        pitch_factor = 1 + (semitones_rise / 12) * (1 - exp(-curve_steepness * u)) / (1 - exp(-curve_steepness))
    else
        pitch_factor = 1 + (semitones_rise / 12) * u  # Linear fallback
    endif
    
    # Convert to semitones and then to frequency
    semitones_shift = (pitch_factor - 1) * 12
    new_f0 = median_f0 * (2 ^ (semitones_shift / 12))
    
    # Clamp to reasonable range
    if new_f0 < minimum_pitch
        new_f0 = minimum_pitch
    elsif new_f0 > maximum_pitch
        new_f0 = maximum_pitch
    endif
    
    Add point: t, new_f0
endfor

# Replace the pitch tier in manipulation
select Manipulation 'originalName$'_tmp
plus PitchTier 'originalName$'_pitch
Replace pitch tier

# Resynthesize
select Manipulation 'originalName$'_tmp
result = Get resynthesis (overlap-add)
Rename: originalName$ + "_glideUp"

if play_after_processing
    Play
endif

# Cleanup
select Sound 'originalName$'_tmp
Remove

if not keep_intermediate_objects
    select Manipulation 'originalName$'_tmp
    plus PitchTier 'originalName$'_pitch
    Remove
endif

select Sound 'originalName$'_glideUp