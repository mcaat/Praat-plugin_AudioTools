# ============================================================
# Praat AudioTools - SPIRAL_PITCH_DANCE.praat
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

form Spiral Pitch Dance
    comment Preset configurations for spiraling pitch movements
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Spiral
        option Moderate Spiral
        option Aggressive Spiral
        option Extreme Spiral
        option Fast Rotation
        option Slow Evolution
        option Psychedelic Swirl
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    positive spirals 2
    positive semitone_range 24
    positive acceleration 1.5
    positive timestep 0.005
    positive floor 50
    positive ceil 1200
    comment ─────────────────────────────────────
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Store original name for cleanup
orig$ = selected$("Sound")
orig_id = selected("Sound")

# Apply presets
if preset = 2
    spirals = 1.5
    semitone_range = 12
    acceleration = 1.3
elsif preset = 3
    spirals = 2
    semitone_range = 24
    acceleration = 1.5
elsif preset = 4
    spirals = 3
    semitone_range = 36
    acceleration = 1.8
elsif preset = 5
    spirals = 5
    semitone_range = 48
    acceleration = 2.2
elsif preset = 6
    spirals = 4
    semitone_range = 30
    acceleration = 2.5
elsif preset = 7
    spirals = 1
    semitone_range = 18
    acceleration = 1.2
elsif preset = 8
    spirals = 8
    semitone_range = 60
    acceleration = 3.0
endif

# Get time range from original sound
xmin = Get start time
xmax = Get end time
dur = xmax - xmin

# Processing
Copy... temp
To Manipulation: timestep, floor, ceil
manip_obj = selected("Manipulation")

# Get original pitch for reference
select Sound temp
To Pitch... timestep floor ceil
pitch_obj = selected("Pitch")
median_f0 = Get quantile... 0 0 0.5 Hertz

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

# Create NEW empty pitch tier from scratch
Create PitchTier... ptier xmin xmax
ptier_obj = selected("PitchTier")

# Dense point sampling for smooth curves
npoints = round(dur / 0.01)
if npoints < 200
    npoints = 200
endif
if npoints > 2000
    npoints = 2000
endif

# Build the spiral pitch curve with DENSE points
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    
    # Normalized position (0 to 1)
    pos = i / (npoints-1)
    
    # Accelerating phase
    phase = spirals * 2 * pi * (pos ^ acceleration)
    
    # Spiral oscillation
    spiral_value = sin(phase)
    
    # Calculate pitch shift in semitones
    pitch_shift_st = semitone_range * spiral_value
    
    # Convert to frequency ratio
    ratio = 2 ^ (pitch_shift_st / 12)
    
    # Apply ratio to median frequency
    new_f0 = median_f0 * ratio
    
    # Clamp to reasonable range
    if new_f0 < floor
        new_f0 = floor
    elsif new_f0 > ceil
        new_f0 = ceil
    endif
    
    select ptier_obj
    Add point... t new_f0
endfor

# Replace the pitch tier in manipulation
select manip_obj
plus ptier_obj
Replace pitch tier

# Resynthesize
select manip_obj
Get resynthesis (overlap-add)
Rename... 'orig$'_spiral
result_id = selected("Sound")

if play_after_processing
    Play
endif

# Cleanup
select pitch_obj
plus Sound temp
Remove

if not keep_intermediate_objects
    select manip_obj
    plus ptier_obj
    Remove
endif


