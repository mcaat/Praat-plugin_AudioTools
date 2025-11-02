# ============================================================
# Praat AudioTools - Orbit_Chorus.praat
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

form Orbit Chorus Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Shimmer (slow drift, subtle)
        option Classic Orbit (balanced drift)
        option Deep Space (very slow drift, wide)
        option Fast Swirl (rapid drift, intense)
        option Vintage Chorus (minimal drift)
        option Extreme Vortex (maximum drift, chaotic)
    comment This script creates chorus with dual drifting taps
    comment ==== Delay Parameters ====
    positive base_delay_ms 8.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.12
    comment (depth of delay modulation, 0-1)
    comment ==== Modulation Parameters ====
    positive base_rate_hz 4.2
    comment (primary modulation frequency in Hz)
    positive phase_drift_hz 0.08
    comment (phase drift frequency for orbit effect in Hz)
    real phase_offset 1.3
    comment (phase offset between the two taps in radians)
    comment ==== Output Options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Shimmer
    base_delay_ms = 7.0
    modulation_depth = 0.10
    base_rate_hz = 3.5
    phase_drift_hz = 0.05
    phase_offset = 1.57
    scale_peak = 0.99
elsif preset = 3
    # Classic Orbit
    base_delay_ms = 8.0
    modulation_depth = 0.12
    base_rate_hz = 4.2
    phase_drift_hz = 0.08
    phase_offset = 1.3
    scale_peak = 0.99
elsif preset = 4
    # Deep Space
    base_delay_ms = 12.0
    modulation_depth = 0.15
    base_rate_hz = 2.0
    phase_drift_hz = 0.03
    phase_offset = 3.14
    scale_peak = 0.99
elsif preset = 5
    # Fast Swirl
    base_delay_ms = 6.0
    modulation_depth = 0.14
    base_rate_hz = 6.5
    phase_drift_hz = 0.15
    phase_offset = 0.9
    scale_peak = 0.99
elsif preset = 6
    # Vintage Chorus
    base_delay_ms = 10.0
    modulation_depth = 0.08
    base_rate_hz = 5.0
    phase_drift_hz = 0.02
    phase_offset = 1.57
    scale_peak = 0.99
elsif preset = 7
    # Extreme Vortex
    base_delay_ms = 15.0
    modulation_depth = 0.20
    base_rate_hz = 8.0
    phase_drift_hz = 0.25
    phase_offset = 2.5
    scale_peak = 0.97
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

writeInfoLine: "=== Orbit Chorus Effect ==="
appendInfoLine: "Processing: ", originalName$
appendInfoLine: ""
appendInfoLine: "Chorus parameters:"
appendInfoLine: "  Base rate: ", fixed$(base_rate_hz, 2), " Hz"
appendInfoLine: "  Modulation depth: ", fixed$(modulation_depth, 2)
appendInfoLine: ""
appendInfoLine: "Orbit parameters:"
appendInfoLine: "  Phase drift rate: ", fixed$(phase_drift_hz, 3), " Hz"
appendInfoLine: "  Phase offset: ", fixed$(phase_offset, 2), " radians (", fixed$(phase_offset * 180 / 3.1415926536, 0), "°)"
appendInfoLine: ""

# Work on a copy
Copy: originalName$ + "_orbit_chorus"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

appendInfoLine: "Creating dual counter-rotating taps..."

# Apply orbit chorus effect
# Two taps with counter-rotating phase drift
Formula: "(self[max(1, min(ncol, col + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x + 2 * pi * 'phase_drift_hz' * x))))] + self[max(1, min(ncol, col + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x + 'phase_offset' - 2 * pi * 'phase_drift_hz' * x))))] ) / 2"

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_chorus_orbit"

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", selected$ ("Sound")
appendInfoLine: "Two delay taps orbiting in counter-rotation"
appendInfoLine: "Peak scaled to: ", fixed$(scale_peak, 2)

# Play if requested
if play_after_processing
    Play
endif