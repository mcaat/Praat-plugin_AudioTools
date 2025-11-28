# ============================================================
# Praat AudioTools - TimeVaryingSpectralVibrato.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Modulation or vibrato-based processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Time-Varying Vibrato
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Ramp Up (Accelerating)
        option Slow Down (Decelerating)
        option Swell (Fade-In Depth)
        option Fade Out (Dying Wobble)
        option Nervous Shiver (Fast & Shallow)
        option Opera Finale (Wide & Slowing)
    
    comment --- Rate Evolution (Hz) ---
    positive Start_Rate_Hz 4.0
    positive End_Rate_Hz 8.0
    
    comment --- Depth Evolution (Semitones) ---
    positive Start_Depth_ST 0.1
    positive End_Depth_ST 0.1
    
    comment --- Output ---
    boolean Play_after_processing 1
endform

# Check for selection
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# PRESET LOGIC
# ============================================================

if preset = 2
    # Ramp Up (Accelerating)
    start_Rate_Hz = 2.0
    end_Rate_Hz = 10.0
    start_Depth_ST = 0.2
    end_Depth_ST = 0.2

elsif preset = 3
    # Slow Down (Engine failure)
    start_Rate_Hz = 12.0
    end_Rate_Hz = 0.5
    start_Depth_ST = 0.3
    end_Depth_ST = 0.5

elsif preset = 4
    # Swell (Fade-In)
    start_Rate_Hz = 5.0
    end_Rate_Hz = 5.0
    start_Depth_ST = 0.0
    end_Depth_ST = 1.0

elsif preset = 5
    # Fade Out (Calming down)
    start_Rate_Hz = 6.0
    end_Rate_Hz = 3.0
    start_Depth_ST = 0.5
    end_Depth_ST = 0.0

elsif preset = 6
    # Nervous Shiver
    start_Rate_Hz = 8.0
    end_Rate_Hz = 12.0
    start_Depth_ST = 0.1
    end_Depth_ST = 0.1

elsif preset = 7
    # Opera Finale
    start_Rate_Hz = 5.5
    end_Rate_Hz = 4.0
    start_Depth_ST = 0.3
    end_Depth_ST = 1.5
endif

# ============================================================
# PSOLA ANALYSIS
# ============================================================

selectObject: original_sound_id
duration = Get total duration

# 1. Create Manipulation Object (The engine for pitch shifting)
To Manipulation: 0.01, 75, 600
manip_id = selected("Manipulation")

# 2. Extract PitchTier (The curve we will modify)
Extract pitch tier
pitch_tier_id = selected("PitchTier")

# ============================================================
# APPLY TIME-VARYING VIBRATO
# ============================================================

# We use the Chirp formula logic to handle changing rates properly.
# Phase = Integral(Rate) = Start_Rate*t + 0.5*Acceleration*t^2

rate_slope = (end_Rate_Hz - start_Rate_Hz) / duration
depth_slope = (end_Depth_ST - start_Depth_ST) / duration

selectObject: pitch_tier_id

# Apply the complex modulation formula to the PitchTier
# 1. Calculate instantaneous Depth: (Start + Slope*x)
# 2. Calculate instantaneous Phase: 2*pi * (Start*x + 0.5*Slope*x^2)
# 3. Convert semitones to ratio: 2 ^ (semitones / 12)
# 4. Multiply original pitch (self) by this ratio

Formula: "self * 2 ^ ( (start_Depth_ST + depth_slope * x) * sin(2*pi * (start_Rate_Hz * x + 0.5 * rate_slope * x^2)) / 12 )"

# ============================================================
# RESYNTHESIS
# ============================================================

selectObject: manip_id
plusObject: pitch_tier_id
Replace pitch tier

selectObject: manip_id
Get resynthesis (overlap-add)
Rename: original_name$ + "_time_vibrato"
final_id = selected("Sound")

# ============================================================
# CLEANUP
# ============================================================

removeObject: manip_id
removeObject: pitch_tier_id
selectObject: original_sound_id
Rename: original_name$

selectObject: final_id
if play_after_processing
    Play
endif