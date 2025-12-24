# ============================================================
# Praat AudioTools - Dual-Mode Tremolo Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Dual-Mode Tremolo Generator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Dual-Mode Tremolo Generator
    comment Select Tremolo Mode:
    choice Mode 1
        button Adaptive (Reacts to volume)
        button Strong (Absolute pulsing)
    
    comment Common Parameters:
    positive Modulation_rate_hz 5
    
    comment --- Adaptive Mode Settings ---
    positive Max_modulation_depth 0.7
    positive Signal_sensitivity 0.5
    positive Sensitivity_offset 0.5
    
    comment --- Strong Mode Settings ---
    boolean Keep_modulator_sound 0
    
    comment --- Output Options ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound info
sound = selected("Sound")
sound$ = selected$("Sound")
selectObject: sound
duration = Get total duration
samplePeriod = Get sample period
fs = 1 / samplePeriod

# ============================================================
# MODE 1: ADAPTIVE TREMOLO (From Tremolo.praat)
# ============================================================
if mode = 1
    # Create copy
    selectObject: sound
    Copy: sound$ + "_adaptive_tremolo"
    processed = selected("Sound")

    # Apply adaptive formula
    # Modulation depth is controlled by signal amplitude 
    Formula: "self * (1 - 'max_modulation_depth' * (1 + sin(2 * pi * 'modulation_rate_hz' * x)) / 2 * ('sensitivity_offset' + 'signal_sensitivity' * abs(self)))"
    
    Rename: sound$ + "_adaptive_tremolo"

# ============================================================
# MODE 2: STRONG TREMOLO (From tremolo_2.praat)
# ============================================================
elsif mode = 2
    # Create absolute-sine modulator (swings from 0 to 1) 
    modulator = Create Sound from formula: sound$ + "_tremoloLFO", 1, 0, duration, fs, "abs(sin(2 * pi * 'modulation_rate_hz' * x))"

    # Apply modulator to original sound
    selectObject: sound
    processed = Copy: sound$ + "_strong_tremolo"
    Formula: "self * Sound_" + sound$ + "_tremoloLFO[col]"
    Rename: sound$ + "_strong_tremolo"

    # Clean up modulator unless requested to keep [cite: 10]
    if not keep_modulator_sound
        selectObject: modulator
        Remove
    endif
    
    # Reselect processed sound
    selectObject: processed
endif

# ============================================================
# COMMON CLEANUP
# ============================================================

# Scale to peak [cite: 5, 9]
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif