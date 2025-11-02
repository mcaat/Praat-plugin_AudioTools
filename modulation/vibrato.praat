# ============================================================
# Praat AudioTools - vibrato.praat
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

form Sine Vibrato Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Subtle Vocal Vibrato (6Hz, gentle)
        option Classic Chorus (5Hz, moderate)
        option Slow Leslie (1.5Hz, deep)
        option Fast Tremolo (8Hz, intense)
        option Gentle Warble (3Hz, subtle)
        option Extreme Wobble (12Hz, extreme)
    comment ==== Delay Parameters ====
    positive base_delay_ms 5.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.10
    comment (depth of delay modulation, 0-1)
    comment ==== Modulation Parameters ====
    positive modulation_rate_hz 5.0
    comment (vibrato frequency in Hz)
    real initial_phase_radians 0.0
    comment (starting phase in radians, 0 to 2π)
    comment ==== Output Options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Vocal Vibrato
    base_delay_ms = 4.0
    modulation_depth = 0.08
    modulation_rate_hz = 6.0
    initial_phase_radians = 0.0
elsif preset = 3
    # Classic Chorus
    base_delay_ms = 5.0
    modulation_depth = 0.10
    modulation_rate_hz = 5.0
    initial_phase_radians = 0.0
elsif preset = 4
    # Slow Leslie
    base_delay_ms = 8.0
    modulation_depth = 0.20
    modulation_rate_hz = 1.5
    initial_phase_radians = 0.0
elsif preset = 5
    # Fast Tremolo
    base_delay_ms = 3.0
    modulation_depth = 0.15
    modulation_rate_hz = 8.0
    initial_phase_radians = 0.0
elsif preset = 6
    # Gentle Warble
    base_delay_ms = 6.0
    modulation_depth = 0.06
    modulation_rate_hz = 3.0
    initial_phase_radians = 0.0
elsif preset = 7
    # Extreme Wobble
    base_delay_ms = 10.0
    modulation_depth = 0.30
    modulation_rate_hz = 12.0
    initial_phase_radians = 0.0
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_sine_vibrato"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Apply sine vibrato
Formula: "self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'modulation_rate_hz' * x + 'initial_phase_radians')))))]"

# Rename result
Rename: originalName$ + "_vibrato_sine"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif