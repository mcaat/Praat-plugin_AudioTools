# ============================================================
# Praat AudioTools - Swarm_Vibrato_Stack.praat
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

form Swarm Vibrato Stack Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Shimmer (3 layers, subtle)
        option Classic Swarm (6 layers, moderate)
        option Dense Cloud (10 layers, thick)
        option Sparse Wobble (4 layers, wide spacing)
        option Insect Chorus (8 layers, fast)
        option Extreme Cluster (12 layers, chaotic)
    comment ==== Stack Parameters ====
    natural number_of_layers 6
    comment (number of vibrato layers to add)
    comment ==== Delay Parameters ====
    positive base_delay_ms 6.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.12
    comment (depth of delay modulation, 0-1)
    comment ==== Layer Modulation Parameters ====
    positive base_rate_hz 3.0
    comment (base frequency, multiplied by layer number)
    positive phase_step 0.9
    comment (phase increment per layer in radians)
    positive weight_offset 1
    comment (attenuation offset: weight = 1/(layer + offset))
    comment ==== Output Options ====
    positive scale_peak 0.95
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Shimmer
    number_of_layers = 3
    base_delay_ms = 5.0
    modulation_depth = 0.08
    base_rate_hz = 2.5
    phase_step = 0.7
    weight_offset = 1.5
    scale_peak = 0.95
elsif preset = 3
    # Classic Swarm
    number_of_layers = 6
    base_delay_ms = 6.0
    modulation_depth = 0.12
    base_rate_hz = 3.0
    phase_step = 0.9
    weight_offset = 1.0
    scale_peak = 0.95
elsif preset = 4
    # Dense Cloud
    number_of_layers = 10
    base_delay_ms = 7.0
    modulation_depth = 0.10
    base_rate_hz = 2.0
    phase_step = 0.6
    weight_offset = 1.2
    scale_peak = 0.93
elsif preset = 5
    # Sparse Wobble
    number_of_layers = 4
    base_delay_ms = 8.0
    modulation_depth = 0.15
    base_rate_hz = 1.5
    phase_step = 1.2
    weight_offset = 0.8
    scale_peak = 0.95
elsif preset = 6
    # Insect Chorus
    number_of_layers = 8
    base_delay_ms = 4.0
    modulation_depth = 0.14
    base_rate_hz = 4.5
    phase_step = 0.8
    weight_offset = 1.5
    scale_peak = 0.94
elsif preset = 7
    # Extreme Cluster
    number_of_layers = 12
    base_delay_ms = 6.0
    modulation_depth = 0.18
    base_rate_hz = 3.5
    phase_step = 0.5
    weight_offset = 2.0
    scale_peak = 0.92
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_swarm_vibrato"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

writeInfoLine: "=== Swarm Vibrato Stack Effect ==="
appendInfoLine: "Processing: ", originalName$
appendInfoLine: "Number of layers: ", number_of_layers
appendInfoLine: "Base rate: ", fixed$(base_rate_hz, 2), " Hz"
appendInfoLine: "Modulation depth: ", fixed$(modulation_depth, 2)
appendInfoLine: ""
appendInfoLine: "Building vibrato stack..."

# Apply swarm vibrato stack
for d from 1 to number_of_layers
    # Each layer has progressively higher frequency
    rate = base_rate_hz * d
    
    # Each layer has different phase offset
    phase = phase_step * d
    
    # Each layer is progressively attenuated
    weight = 1 / (d + weight_offset)
    
    # Add this vibrato layer
    Formula: "self + self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * sin(2 * pi * rate * x + phase))))) ] * weight"
    
    if d mod 3 = 0 or d = number_of_layers
        appendInfoLine: "  Layer ", d, " / ", number_of_layers, " - Rate: ", fixed$(rate, 1), " Hz, Weight: ", fixed$(weight, 3)
    endif
endfor

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_vibrato_swarm_stack"

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", selected$ ("Sound")
appendInfoLine: "Peak scaled to: ", fixed$(scale_peak, 2)

# Play if requested
if play_after_processing
    Play
endif