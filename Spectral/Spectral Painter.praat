# ============================================================
# Praat AudioTools - Spectral Painter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Frequency-domain processing tool for spectral gain modulation
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ==========================================
# BRIGHT MODULATION - EXPERIMENTAL EDITION
# Advanced Spectral Processing Tool
# ==========================================
# 
# PRESET SONIC GUIDE:
# 1. Custom - Full manual control
# 2. Metallic Ring - Classic robot voice, linear sine ripples
# 3. Deep Resonance - Heavy bass emphasis, slow modulation
# 4. High Shimmer - Bright sparkle, fast treble modulation
# 5. Comb Filter - Harsh stepped brick-wall filtering (phase coherent)
# 6. Harmonic Series - Exponential decay (loud bass → quiet treble)
# 7. Chaotic Wobble - Spectral diffusion, fuzzy/glassy texture
# 8. Dual Wave Interference - Beating pattern, two frequencies clash
# 9. Frequency Stairs - Stepped sawtooth, digital ladder effect
# 10. Inverted Valleys - Phase inversion bands (hollow/flanged)
# 11. Random Spectral Carving - Heavy phase-destroying diffusion
# 12. Pulsing Bands - Sawtooth ramps, sweeping filter effect
# 13. Exponential Sweep - Natural decay following ear sensitivity
# 14. Musical Phaser - Logarithmic spacing (uniform ripples)
# 
# TECHNICAL NOTES:
# - Square Wave (Type 3): Creates 0.2x to 1.8x gain bands (harsh comb)
# - Random (Type 7): Per-bin randomness = spectral diffusion (not wobble)
# - Inverted Valleys: Negative depth inverts phase (hollow sound)
# - Musical spacing: ln(x) scaling matches human pitch perception
# ==========================================

form Spectral Painter 
    comment === PRESETS ===
    optionmenu preset: 1
        option Custom
        option Metallic Ring (Linear)
        option Deep Resonance
        option High Shimmer
        option Comb Filter (Harsh)
        option Harmonic Series
        option Chaotic Wobble
        option Dual Wave Interference
        option Frequency Stairs
        option Inverted Valleys (Phase Flip)
        option Random Spectral Carving
        option Pulsing Bands
        option Exponential Sweep
        option Musical Phaser (Logarithmic)
    
    comment === MODULATION TYPE ===
    optionmenu modulation_type: 1
        option Sine Wave (Linear)
        option Sine Wave (Logarithmic/Musical)
        option Triangle Wave
        option Square Wave (Stepped)
        option Sawtooth
        option Exponential
        option Logarithmic
        option Random (Per-Bin Diffusion)
        option Dual Sine (Interference)
    
    comment === BASIC PARAMETERS ===
    positive cutoff_frequency 15000
    comment (frequencies below this are affected)
    positive modulation_center 1.0
    positive modulation_depth 0.8
    positive modulation_frequency_divisor 150
    comment (Lower = faster modulation)
    
    comment === ADVANCED PARAMETERS ===
    positive phase_offset 0.01
    comment (0-6.28 for sine phase shift)
    positive second_divisor 300
    comment (For dual wave interference)
    positive randomness_amount 0.3
    comment (For random modulation)
    
    comment === SAFETY ===
    boolean warn_phase_inversion 1
    comment (Alert if depth > center causes phase flip)
    
    comment === OUTPUT ===
    positive scale_peak 0.95
    boolean play_after_processing 1
endform

# ===================================================================
# PRESET APPLICATION
# ===================================================================

if preset = 2
    # Metallic Ring (Linear)
    modulation_type = 1
    modulation_depth = 0.9
    modulation_frequency_divisor = 100
    cutoff_frequency = 10000
    
elsif preset = 3
    # Deep Resonance
    modulation_type = 1
    modulation_depth = 0.95
    modulation_frequency_divisor = 400
    cutoff_frequency = 5000
    
elsif preset = 4
    # High Shimmer
    modulation_type = 1
    modulation_depth = 0.6
    modulation_frequency_divisor = 50
    cutoff_frequency = 20000
    
elsif preset = 5
    # Comb Filter (Harsh)
    modulation_type = 4
    modulation_depth = 1.0
    modulation_frequency_divisor = 200
    cutoff_frequency = 12000
    modulation_center = 1.0
    
elsif preset = 6
    # Harmonic Series
    modulation_type = 6
    modulation_depth = 0.7
    modulation_frequency_divisor = 100
    cutoff_frequency = 8000
    
elsif preset = 7
    # Chaotic Wobble
    modulation_type = 8
    modulation_depth = 0.85
    randomness_amount = 0.5
    cutoff_frequency = 10000
    
elsif preset = 8
    # Dual Wave Interference
    modulation_type = 9
    modulation_depth = 0.7
    modulation_frequency_divisor = 100
    second_divisor = 250
    cutoff_frequency = 12000
    
elsif preset = 9
    # Frequency Stairs
    modulation_type = 5
    modulation_depth = 0.8
    modulation_frequency_divisor = 300
    cutoff_frequency = 15000
    
elsif preset = 10
    # Inverted Valleys (Phase Flip)
    modulation_type = 1
    modulation_center = 0.8
    modulation_depth = -0.6
    modulation_frequency_divisor = 200
    cutoff_frequency = 10000
    
elsif preset = 11
    # Random Spectral Carving
    modulation_type = 8
    modulation_depth = 0.9
    randomness_amount = 0.8
    cutoff_frequency = 18000
    
elsif preset = 12
    # Pulsing Bands
    modulation_type = 5
    modulation_depth = 0.95
    modulation_frequency_divisor = 150
    cutoff_frequency = 12000
    
elsif preset = 13
    # Exponential Sweep
    modulation_type = 6
    modulation_depth = 0.8
    modulation_frequency_divisor = 80
    cutoff_frequency = 15000
    
elsif preset = 14
    # Musical Phaser (Logarithmic)
    modulation_type = 2
    modulation_depth = 0.75
    modulation_frequency_divisor = 150
    cutoff_frequency = 15000
endif

# ===================================================================
# SAFETY CHECK
# ===================================================================

if warn_phase_inversion
    min_gain = modulation_center - abs(modulation_depth)
    max_gain = modulation_center + abs(modulation_depth)
    
    if min_gain < 0
        writeInfoLine: "⚠ PHASE INVERSION WARNING ⚠"
        appendInfoLine: "Your settings will cause phase inversion (negative gain)."
        appendInfoLine: "Center: ", modulation_center, " | Depth: ", modulation_depth
        appendInfoLine: "Gain range: ", fixed$(min_gain, 2), " to ", fixed$(max_gain, 2)
        appendInfoLine: ""
        appendInfoLine: "This creates a 'hollow' flanged effect by inverting phase."
        appendInfoLine: "This is intentional for 'Inverted Valleys' preset."
        appendInfoLine: ""
        appendInfoLine: "Continue? (Close this to abort, or click OK to proceed)"
        
        beginPause: "Phase Inversion Detected"
            comment: "Negative gain will invert phase in affected bands."
            comment: "This sounds 'hollow' or 'flanged' - cool but extreme."
        clicked = endPause: "Abort", "Continue", 2
        
        if clicked = 1
            exit User aborted due to phase inversion warning.
        endif
    endif
endif

# ===================================================================
# PROCESSING
# ===================================================================

if numberOfSelected ("Sound") <> 1
    exit Please select exactly ONE Sound object first.
endif

originalID = selected ("Sound")
originalName$ = selected$ ("Sound")
original_sr = Get sampling frequency

writeInfoLine: "=== EXPERIMENTAL BRIGHT MODULATION ==="
appendInfoLine: "Preset: ", preset
appendInfoLine: "Modulation type: ", modulation_type
appendInfoLine: "Sample rate: ", original_sr, " Hz"
appendInfoLine: ""

# Convert to Spectrum
selectObject: originalID
specID = To Spectrum: "yes"

# Build modulation formula based on type
selectObject: specID

if modulation_type = 1
    # SINE WAVE (Linear - Classic)
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * sin((x / " + string$(modulation_frequency_divisor) + ") + " + string$(phase_offset) + ")) else self fi"
    appendInfoLine: "Applied: Sine wave (linear spacing)"
    
elsif modulation_type = 2
    # SINE WAVE (Logarithmic - Musical)
    # Uses ln(x) for perceptually uniform spacing
    density = modulation_frequency_divisor / 10
    formula$ = "if x < " + string$(cutoff_frequency) + " and x > 1 then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * sin((ln(x) * " + string$(density) + ") + " + string$(phase_offset) + ")) else self fi"
    appendInfoLine: "Applied: Sine wave (logarithmic/musical spacing)"
    
elsif modulation_type = 3
    # TRIANGLE WAVE
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * (2 * abs((x / " + string$(modulation_frequency_divisor) + ") - floor((x / " + string$(modulation_frequency_divisor) + ") + 0.5)) - 1)) else self fi"
    appendInfoLine: "Applied: Triangle wave"
    
elsif modulation_type = 4
    # SQUARE WAVE (Phase-coherent brick walls)
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * (if sin(x / " + string$(modulation_frequency_divisor) + ") > 0 then 1 else -1 fi)) else self fi"
    appendInfoLine: "Applied: Square wave (harsh comb filter)"
    
elsif modulation_type = 5
    # SAWTOOTH
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * (2 * ((x / " + string$(modulation_frequency_divisor) + ") - floor((x / " + string$(modulation_frequency_divisor) + ") + 0.5)))) else self fi"
    appendInfoLine: "Applied: Sawtooth wave"
    
elsif modulation_type = 6
    # EXPONENTIAL (Natural decay)
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * exp(-x / " + string$(modulation_frequency_divisor) + ")) else self fi"
    appendInfoLine: "Applied: Exponential decay"
    
elsif modulation_type = 7
    # LOGARITHMIC (Natural growth)
    formula$ = "if x < " + string$(cutoff_frequency) + " and x > 1 then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * ln(1 + x / " + string$(modulation_frequency_divisor) + ")) else self fi"
    appendInfoLine: "Applied: Logarithmic growth"
    
elsif modulation_type = 8
    # RANDOM (Spectral diffusion - per bin)
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * (sin(x / " + string$(modulation_frequency_divisor) + ") + " + string$(randomness_amount) + " * randomGauss(0, 1))) else self fi"
    appendInfoLine: "Applied: Random per-bin diffusion (fuzzy/glassy)"
    
else
    # DUAL SINE (Interference pattern)
    formula$ = "if x < " + string$(cutoff_frequency) + " then self * (" + string$(modulation_center) + " + " + string$(modulation_depth) + " * (sin(x / " + string$(modulation_frequency_divisor) + ") + 0.5 * sin(x / " + string$(second_divisor) + "))/1.5) else self fi"
    appendInfoLine: "Applied: Dual sine interference"
endif

# Apply the formula
Formula: formula$

# Convert back to Sound
processedID = To Sound
removeObject: specID

# Finalize
selectObject: processedID
outName$ = originalName$ + "_mod"
Rename: outName$
Scale peak: scale_peak

appendInfoLine: ""
appendInfoLine: "✓ PROCESSING COMPLETE"
appendInfoLine: "Output: ", outName$

if play_after_processing
    Play
endif