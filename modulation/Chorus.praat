# ============================================================
# Praat AudioTools - Chorus.praat
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

form Chorus / Unison Effect
    comment This script creates a 3-tap chorus effect
    comment ==============================================
    optionmenu Preset 1
        option Custom (use settings below)
        option Subtle Chorus
        option Classic Chorus
        option Rich Unison
        option Wide Ensemble
        option Deep Chorus
        option Shimmer Effect
    comment ==============================================
    comment Delay parameters:
    positive base_delay_ms 8.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.12
    comment (depth of delay modulation)
    comment Modulation rates for each tap:
    positive tap1_rate_hz 3.6
    positive tap2_rate_hz 4.7
    positive tap3_rate_hz 5.8
    comment Phase offsets for taps 2 and 3:
    real tap2_phase_offset 1.9
    real tap3_phase_offset 3.1
    comment Output options:
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Chorus
    base_delay_ms = 6.0
    modulation_depth = 0.08
    tap1_rate_hz = 3.2
    tap2_rate_hz = 4.1
    tap3_rate_hz = 5.3
    tap2_phase_offset = 2.1
    tap3_phase_offset = 4.2
elsif preset = 3
    # Classic Chorus
    base_delay_ms = 8.0
    modulation_depth = 0.12
    tap1_rate_hz = 3.6
    tap2_rate_hz = 4.7
    tap3_rate_hz = 5.8
    tap2_phase_offset = 1.9
    tap3_phase_offset = 3.1
elsif preset = 4
    # Rich Unison
    base_delay_ms = 10.0
    modulation_depth = 0.15
    tap1_rate_hz = 2.8
    tap2_rate_hz = 3.9
    tap3_rate_hz = 5.1
    tap2_phase_offset = 2.5
    tap3_phase_offset = 4.8
elsif preset = 5
    # Wide Ensemble
    base_delay_ms = 12.0
    modulation_depth = 0.18
    tap1_rate_hz = 2.5
    tap2_rate_hz = 4.2
    tap3_rate_hz = 6.3
    tap2_phase_offset = 1.5
    tap3_phase_offset = 3.7
elsif preset = 6
    # Deep Chorus
    base_delay_ms = 15.0
    modulation_depth = 0.20
    tap1_rate_hz = 2.0
    tap2_rate_hz = 3.5
    tap3_rate_hz = 5.0
    tap2_phase_offset = 2.8
    tap3_phase_offset = 5.2
elsif preset = 7
    # Shimmer Effect
    base_delay_ms = 5.0
    modulation_depth = 0.10
    tap1_rate_hz = 4.5
    tap2_rate_hz = 6.0
    tap3_rate_hz = 7.5
    tap2_phase_offset = 1.3
    tap3_phase_offset = 2.6
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_chorus"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Apply 3-tap chorus effect
# Each tap has independent modulation rate and phase
Formula: "(self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'tap1_rate_hz' * x)))))] + self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'tap2_rate_hz' * x + 'tap2_phase_offset')))))] + self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'tap3_rate_hz' * x + 'tap3_phase_offset')))))] ) / 3"

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_chorus_unison"

# Play if requested
if play_after_processing
    Play
endif
