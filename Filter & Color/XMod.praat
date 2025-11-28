# ============================================================
# Praat AudioTools - XMod.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Filtering or timbral modification script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Rhythmic Gating
    comment This script applies rhythmic on/off gating to the sound
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Fast Stutter (100ms cycle)
        option Medium Pulse (250ms cycle)
        option Slow Pulse (500ms cycle)
        option Tremolo (150ms cycle)
        option Helicopter (80ms cycle)
    comment ==== Gating parameters ====
    positive gate_period 0.1
    comment (duration of one complete gate cycle in seconds)
    positive gate_duty_cycle 0.05
    comment (duration gate is OFF before turning ON)
    comment ==== Output options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Fast Stutter
    gate_period = 0.1
    gate_duty_cycle = 0.05
elsif preset = 3
    # Medium Pulse
    gate_period = 0.25
    gate_duty_cycle = 0.125
elsif preset = 4
    # Slow Pulse
    gate_period = 0.5
    gate_duty_cycle = 0.25
elsif preset = 5
    # Tremolo
    gate_period = 0.15
    gate_duty_cycle = 0.075
elsif preset = 6
    # Helicopter
    gate_period = 0.08
    gate_duty_cycle = 0.04
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get the name of the original sound
originalName$ = selected$("Sound")

# Copy the sound object
Copy: originalName$ + "_gated"

# Apply rhythmic gating
Formula: "if (x mod 'gate_period' > 'gate_duty_cycle') then self else 0 fi"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif