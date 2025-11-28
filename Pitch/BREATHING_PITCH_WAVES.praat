# ============================================================
# Praat AudioTools - BREATHING_PITCH_WAVES.praat
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

form Breathing Pitch Waves Effect
    comment Preset configurations for emotional breathing pitch effects
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Breath
        option Emotional Swell
        option Dramatic Breath
        option Panic Breathing
        option Subtle Tremor
        option Deep Meditation
        option Intense Gasping
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    positive breath_rate 0.3
    comment (breathing cycles per second)
    positive pitch_depth_semitones 18
    comment (pitch variation range)
    comment Flutter and chaos:
    positive micro_flutter 4
    positive emotional_intensity 2.5
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
if preset = 2    ; Gentle Breath
    breath_rate = 0.2
    pitch_depth_semitones = 8
    micro_flutter = 1
    emotional_intensity = 1.2
elsif preset = 3    ; Emotional Swell
    breath_rate = 0.25
    pitch_depth_semitones = 15
    micro_flutter = 2
    emotional_intensity = 2.0
elsif preset = 4    ; Dramatic Breath
    breath_rate = 0.35
    pitch_depth_semitones = 24
    micro_flutter = 5
    emotional_intensity = 3.0
elsif preset = 5    ; Panic Breathing
    breath_rate = 0.8
    pitch_depth_semitones = 36
    micro_flutter = 8
    emotional_intensity = 4.0
elsif preset = 6    ; Subtle Tremor
    breath_rate = 0.15
    pitch_depth_semitones = 6
    micro_flutter = 3
    emotional_intensity = 0.8
elsif preset = 7    ; Deep Meditation
    breath_rate = 0.1
    pitch_depth_semitones = 4
    micro_flutter = 0.5
    emotional_intensity = 0.5
elsif preset = 8    ; Intense Gasping
    breath_rate = 0.5
    pitch_depth_semitones = 30
    micro_flutter = 6
    emotional_intensity = 3.5
endif

originalName$ = selected$("Sound")
orig_sr = Get sampling frequency

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

Copy: originalName$ + "_breath_tmp"
To Manipulation: time_step, minimum_pitch, maximum_pitch

# Get original pitch for reference
select Sound 'originalName$'_breath_tmp
To Pitch: time_step, minimum_pitch, maximum_pitch
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"

# If no pitch detected, use default
if median_f0 = undefined
    median_f0 = 200
endif

select Pitch 'originalName$'_breath_tmp
Remove

# Create NEW empty pitch tier with dense points
Create PitchTier: originalName$ + "_breath_pitch", xmin, xmax
ptier_obj = selected("PitchTier")

# Build the breathing pitch curve with DENSE points
for i from 0 to npoints-1
    t = xmin + (i / (npoints-1)) * dur
    
    # Breathing phase calculation
    phase = (t - xmin) * 2 * pi * breath_rate
    
    # Complex breathing waveform
    breath_fundamental = sin(phase)^3
    breath_harmonic = 0.6 * sin(phase * 2)^5
    breath_subharmonic = 0.3 * sin(phase * 0.5)^2
    breath_curve = breath_fundamental + breath_harmonic + breath_subharmonic
    
    # Micro-flutter components
    flutter_phase = phase * 12
    chaos_phase = phase * 23.7
    flutter_component1 = sin(flutter_phase) * randomUniform(0.6, 1.4)
    flutter_component2 = 0.5 * sin(chaos_phase) * randomUniform(0.8, 1.2)
    flutter = micro_flutter * 0.15 * (flutter_component1 + flutter_component2)
    
    # Emotional tremor and gasps
    tremor = 0.8 * sin(phase * 7.3) * cos(phase * 2.1)
    gasp_trigger = sin(phase * 3)^8
    gasp = 3 * gasp_trigger * randomUniform(0.5, 1.5)
    
    # Emotional intensity envelope
    time_factor = (t - xmin) / dur
    intensity_envelope = 1 + emotional_intensity * time_factor^1.5
    
    # Calculate total pitch shift
    total_shift = pitch_depth_semitones * (breath_curve + flutter + tremor + gasp) * intensity_envelope
    
    # Convert semitones to frequency ratio
    ratio = 2 ^ (total_shift / 12)
    
    # Apply ratio to median frequency
    new_f0 = median_f0 * ratio
    
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
select Manipulation 'originalName$'_breath_tmp
plus PitchTier 'originalName$'_breath_pitch
Replace pitch tier

# Resynthesize
select Manipulation 'originalName$'_breath_tmp
result = Get resynthesis (overlap-add)
Rename: originalName$ + "_breath_result"

# Resample if needed
if output_sample_rate <> orig_sr
    select Sound 'originalName$'_breath_result
    Resample: output_sample_rate, resample_precision
endif

if play_after_processing
    Play
endif

# Cleanup
select Sound 'originalName$'_breath_tmp
Remove

if not keep_intermediate_objects
    select Manipulation 'originalName$'_breath_tmp
    plus PitchTier 'originalName$'_breath_pitch
    Remove
endif

# Select the final result
select Sound 'originalName$'_breath_result