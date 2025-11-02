# ============================================================
# Praat AudioTools - Stereo_Swirl_Vibrato.praat
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

form Stereo Swirl Vibrato Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Stereo Chorus (90° phase, subtle)
        option Wide Stereo Swirl (180° phase, dramatic)
        option Rotating Leslie (90° phase, slow)
        option Psychedelic Spiral (270° phase, intense)
        option Subtle Width (45° phase, gentle)
        option Extreme Dizzy (180° phase, fast & deep)
    comment NOTE: Requires a stereo (2-channel) sound
    comment ==== Delay Parameters ====
    positive base_delay_ms 6.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.12
    comment (depth of delay modulation, 0-1)
    positive modulation_rate_hz 4.5
    comment (vibrato frequency in Hz)
    comment ==== Stereo Phase Parameters ====
    real phase_step_radians 1.5707963268
    comment (phase offset between channels)
    comment (π/2 = 1.571 = 90°, π = 3.142 = 180°, 0 = mono)
    comment ==== Output Options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Stereo Chorus
    base_delay_ms = 5.0
    modulation_depth = 0.10
    modulation_rate_hz = 5.0
    phase_step_radians = 1.5707963268
elsif preset = 3
    # Wide Stereo Swirl
    base_delay_ms = 6.0
    modulation_depth = 0.15
    modulation_rate_hz = 4.5
    phase_step_radians = 3.1415926536
elsif preset = 4
    # Rotating Leslie
    base_delay_ms = 8.0
    modulation_depth = 0.18
    modulation_rate_hz = 1.5
    phase_step_radians = 1.5707963268
elsif preset = 5
    # Psychedelic Spiral
    base_delay_ms = 7.0
    modulation_depth = 0.20
    modulation_rate_hz = 6.0
    phase_step_radians = 4.7123889804
elsif preset = 6
    # Subtle Width
    base_delay_ms = 4.0
    modulation_depth = 0.08
    modulation_rate_hz = 4.0
    phase_step_radians = 0.7853981634
elsif preset = 7
    # Extreme Dizzy
    base_delay_ms = 10.0
    modulation_depth = 0.25
    modulation_rate_hz = 8.0
    phase_step_radians = 3.1415926536
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Check if sound is stereo
numberOfChannels = Get number of channels
if numberOfChannels <> 2
    exitScript: "This script requires a stereo (2-channel) sound."
endif

# Get original sound name
originalName$ = selected$("Sound")

writeInfoLine: "=== Stereo Swirl Vibrato Effect ==="
appendInfoLine: "Processing: ", originalName$
appendInfoLine: "Modulation rate: ", fixed$(modulation_rate_hz, 2), " Hz"
appendInfoLine: "Modulation depth: ", fixed$(modulation_depth, 2)
appendInfoLine: "Phase offset: ", fixed$(phase_step_radians, 2), " radians (", fixed$(phase_step_radians * 180 / 3.1415926536, 0), "°)"
appendInfoLine: ""

# Work on a copy
Copy: originalName$ + "_stereo_swirl"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

appendInfoLine: "Applying stereo swirl modulation..."

# Apply stereo swirl vibrato
# Each channel gets phase-shifted modulation based on row number
Formula: "self[max(1, min(ncol, col + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'modulation_rate_hz' * x + (row - 1) * 'phase_step_radians'))))]"

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_vibrato_stereo_swirl"

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", selected$ ("Sound")
appendInfoLine: "Peak scaled to: ", fixed$(scale_peak, 2)

# Play if requested
if play_after_processing
    Play
endif