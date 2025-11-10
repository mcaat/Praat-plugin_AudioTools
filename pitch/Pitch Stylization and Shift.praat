# ============================================================
# Praat AudioTools - Pitch Stylization and Shift.praat
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

form Pitch Stylization and Shift
    comment Preset configurations for pitch stylization
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Smoothing
        option Stepwise Quantize
        option Robot Voice
        option Pitch Down
        option Pitch Up
        option Strong Stylize
    comment ─────────────────────────────────────
    comment Manual parameters (active if Manual is selected):
    real Stylize_frequency 2
    real Shift_amount -20
    comment Pitch analysis:
    positive Time_step 0.005
    positive Minimum_pitch 75
    positive Maximum_pitch 600
    comment Output options:
    boolean Play_result 1
    boolean Keep_intermediate_objects 0
endform

# Apply presets
if preset = 2    ; Gentle Smoothing
    stylize_frequency = 1
    shift_amount = 0
elsif preset = 3    ; Stepwise Quantize
    stylize_frequency = 5
    shift_amount = 0
elsif preset = 4    ; Robot Voice
    stylize_frequency = 8
    shift_amount = -12
elsif preset = 5    ; Pitch Down
    stylize_frequency = 0
    shift_amount = -24
elsif preset = 6    ; Pitch Up
    stylize_frequency = 0
    shift_amount = 12
elsif preset = 7    ; Strong Stylize
    stylize_frequency = 10
    shift_amount = -5
endif

# Check if a sound object is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get the selected sound
originalSound = selected("Sound")
originalName$ = selected$("Sound")

# Get duration for the shift command
duration = Get total duration

# Create manipulation object with better time resolution
selectObject: originalSound
manipulation = To Manipulation: time_step, minimum_pitch, maximum_pitch

# Extract pitch tier for modifications
selectObject: manipulation
pitchTier = Extract pitch tier

# Stylize the pitch tier if frequency > 0
if stylize_frequency > 0
    selectObject: pitchTier
    Stylize: stylize_frequency, "Hz"
endif

# Shift pitch frequencies on the pitch tier
if shift_amount != 0
    selectObject: pitchTier
    Shift frequencies: 0, duration, shift_amount, "semitones"
endif

# Put the modified pitch tier back into manipulation
selectObject: manipulation
plusObject: pitchTier
Replace pitch tier

# Get resynthesis using overlap-add method
selectObject: manipulation
resynthesized = Get resynthesis (overlap-add)
Rename: originalName$ + "_stylized"

# Clean up intermediate objects
if not keep_intermediate_objects
    removeObject: pitchTier, manipulation
endif

# Play if requested
if play_result
    Play
endif

# Select the result
selectObject: resynthesized