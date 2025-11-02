# ============================================================
# Praat AudioTools - Rotary.praat
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

form Rotary Speaker Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Leslie Slow (chorale speed)
        option Leslie Fast (tremolo speed)
        option Vintage Organ (classic sound)
        option Psychedelic Swirl (intense modulation)
        option Subtle Rotation (gentle effect)
        option Extreme Spin (maximum modulation)
    comment This script simulates rotary speaker (vibrato + tremolo)
    comment ==== Delay Parameters ====
    positive base_delay_ms 6.0
    comment (base delay time in milliseconds)
    comment ==== Vibrato Parameters (pitch modulation) ====
    positive vibrato_depth 0.12
    comment (depth of pitch modulation, 0-1)
    positive vibrato_rate_hz 5.0
    comment (vibrato frequency in Hz)
    comment ==== Tremolo Parameters (amplitude modulation) ====
    positive tremolo_depth 0.40
    comment (depth of amplitude modulation, 0-1)
    positive tremolo_rate_hz 4.8
    comment (tremolo frequency in Hz)
    comment ==== Output Options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Leslie Slow (chorale)
    base_delay_ms = 7.0
    vibrato_depth = 0.10
    vibrato_rate_hz = 0.8
    tremolo_depth = 0.30
    tremolo_rate_hz = 0.75
elsif preset = 3
    # Leslie Fast (tremolo)
    base_delay_ms = 6.0
    vibrato_depth = 0.15
    vibrato_rate_hz = 6.5
    tremolo_depth = 0.50
    tremolo_rate_hz = 6.2
elsif preset = 4
    # Vintage Organ
    base_delay_ms = 6.0
    vibrato_depth = 0.12
    vibrato_rate_hz = 5.0
    tremolo_depth = 0.40
    tremolo_rate_hz = 4.8
elsif preset = 5
    # Psychedelic Swirl
    base_delay_ms = 8.0
    vibrato_depth = 0.20
    vibrato_rate_hz = 7.5
    tremolo_depth = 0.60
    tremolo_rate_hz = 7.0
elsif preset = 6
    # Subtle Rotation
    base_delay_ms = 5.0
    vibrato_depth = 0.08
    vibrato_rate_hz = 3.0
    tremolo_depth = 0.25
    tremolo_rate_hz = 2.8
elsif preset = 7
    # Extreme Spin
    base_delay_ms = 10.0
    vibrato_depth = 0.25
    vibrato_rate_hz = 10.0
    tremolo_depth = 0.70
    tremolo_rate_hz = 9.5
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

writeInfoLine: "=== Rotary Speaker Effect ==="
appendInfoLine: "Processing: ", originalName$
appendInfoLine: ""
appendInfoLine: "Vibrato (pitch modulation):"
appendInfoLine: "  Rate: ", fixed$(vibrato_rate_hz, 2), " Hz"
appendInfoLine: "  Depth: ", fixed$(vibrato_depth, 2)
appendInfoLine: ""
appendInfoLine: "Tremolo (amplitude modulation):"
appendInfoLine: "  Rate: ", fixed$(tremolo_rate_hz, 2), " Hz"
appendInfoLine: "  Depth: ", fixed$(tremolo_depth, 2)
appendInfoLine: ""

# Work on a copy
Copy: originalName$ + "_rotary_speaker"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

appendInfoLine: "Applying rotary speaker simulation..."

# Apply rotary speaker effect (combined vibrato and tremolo)
# Vibrato creates pitch modulation via delay
# Tremolo creates amplitude modulation
Formula: "(self[max(1, min(ncol, col + round('base' * (1 + 'vibrato_depth' * sin(2 * pi * 'vibrato_rate_hz' * x)))))]) * (1 + 'tremolo_depth' * sin(2 * pi * 'tremolo_rate_hz' * x))"

# Rename result
Rename: originalName$ + "_rotary_speaker"

# Scale to peak
Scale peak: scale_peak

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", selected$ ("Sound")
appendInfoLine: "Peak scaled to: ", fixed$(scale_peak, 2)

# Play if requested
if play_after_processing
    Play
endif