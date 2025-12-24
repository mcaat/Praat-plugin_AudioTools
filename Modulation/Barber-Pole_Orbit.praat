# ============================================================
# Praat AudioTools - Barber-Pole_Orbit.praat
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

form Barber-Pole Orbit Effect (Stereo)
    comment This script creates a continuously rising/falling pitch illusion in stereo
    comment ==============================================
    optionmenu Preset 1
        option Custom (use settings below)
        option Gentle Ascending Illusion
        option Classic Barber Pole
        option Intense Spiral
        option Subtle Shimmer
        option Deep Space Rotation
        option Extreme Perpetual Motion
    comment ==============================================
    comment Orbit parameters:
    natural number_of_turns 5
    comment (number of orbit iterations)
    comment Delay parameters:
    positive base_delay_ms 7.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.10
    comment (depth of delay modulation)
    comment Modulation rates:
    positive base_rate_hz 3.8
    comment (primary modulation frequency)
    positive drift_rate_hz 0.12
    comment (secondary drift frequency)
    positive phase_offset 1.2
    comment (phase offset between up/down halos)
    comment Stereo parameters:
    positive stereo_phase_offset 0.5
    comment (phase offset between left/right channels, 0-1)
    comment Mix parameters:
    positive turn_attenuation 1.0
    comment (attenuation factor: weight = 1/(turn + attenuation))
    positive temporal_shift 0.3
    comment (temporal phase shift per turn)
    comment Output options:
    positive scale_peak 0.95
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Ascending Illusion
    number_of_turns = 3
    base_delay_ms = 5.0
    modulation_depth = 0.08
    base_rate_hz = 3.0
    drift_rate_hz = 0.08
    phase_offset = 1.57
    stereo_phase_offset = 0.25
    turn_attenuation = 1.5
    temporal_shift = 0.2
elsif preset = 3
    # Classic Barber Pole
    number_of_turns = 5
    base_delay_ms = 7.0
    modulation_depth = 0.12
    base_rate_hz = 4.0
    drift_rate_hz = 0.15
    phase_offset = 1.2
    stereo_phase_offset = 0.5
    turn_attenuation = 1.0
    temporal_shift = 0.3
elsif preset = 4
    # Intense Spiral
    number_of_turns = 7
    base_delay_ms = 9.0
    modulation_depth = 0.18
    base_rate_hz = 5.5
    drift_rate_hz = 0.22
    phase_offset = 0.9
    stereo_phase_offset = 0.75
    turn_attenuation = 0.7
    temporal_shift = 0.45
elsif preset = 5
    # Subtle Shimmer
    number_of_turns = 4
    base_delay_ms = 4.0
    modulation_depth = 0.06
    base_rate_hz = 2.5
    drift_rate_hz = 0.05
    phase_offset = 1.8
    stereo_phase_offset = 0.3
    turn_attenuation = 2.0
    temporal_shift = 0.15
elsif preset = 6
    # Deep Space Rotation
    number_of_turns = 6
    base_delay_ms = 12.0
    modulation_depth = 0.15
    base_rate_hz = 2.0
    drift_rate_hz = 0.10
    phase_offset = 1.0
    stereo_phase_offset = 0.66
    turn_attenuation = 0.8
    temporal_shift = 0.5
elsif preset = 7
    # Extreme Perpetual Motion
    number_of_turns = 10
    base_delay_ms = 10.0
    modulation_depth = 0.25
    base_rate_hz = 6.5
    drift_rate_hz = 0.30
    phase_offset = 0.8
    stereo_phase_offset = 0.9
    turn_attenuation = 0.5
    temporal_shift = 0.6
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Check if mono or stereo
numberOfChannels = Get number of channels

if numberOfChannels = 1
    # Convert mono to stereo
    Convert to stereo
endif

# Work on a copy
Copy: originalName$ + "_barber_pole_stereo"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Calculate stereo phase in radians
stereo_phase = stereo_phase_offset * 2 * pi

# Apply barber-pole orbit effect - same as original but alternating between channels
for t from 1 to number_of_turns
    # Calculate weight for this turn
    w = 1 / (t + turn_attenuation)
    
    # Upward-drifting halo on LEFT channel
    Formula: "self[col - (col mod 2) + 1] + self[max(1, min(ncol, (col - (col mod 2) + 1) + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x + 2 * pi * 'drift_rate_hz' * x + 't' * 'temporal_shift'))))] * 'w'"
    
    # Downward-drifting halo on LEFT channel
    Formula: "self[col - (col mod 2) + 1] + self[max(1, min(ncol, (col - (col mod 2) + 1) + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x - 2 * pi * 'drift_rate_hz' * x + 'phase_offset' - 't' * 'temporal_shift'))))] * 'w'"
    
    # Upward-drifting halo on RIGHT channel (with stereo phase)
    Formula: "self[col - (col mod 2) + 2] + self[max(1, min(ncol, (col - (col mod 2) + 2) + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x + 2 * pi * 'drift_rate_hz' * x + 't' * 'temporal_shift' + 'stereo_phase'))))] * 'w'"
    
    # Downward-drifting halo on RIGHT channel (with stereo phase)
    Formula: "self[col - (col mod 2) + 2] + self[max(1, min(ncol, (col - (col mod 2) + 2) + round('base' + 'base' * 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x - 2 * pi * 'drift_rate_hz' * x + 'phase_offset' - 't' * 'temporal_shift' + 'stereo_phase'))))] * 'w'"
endfor

# Scale to peak
Scale peak: scale_peak

# Rename result
Rename: originalName$ + "_barber_pole_stereo"

# Play if requested
if play_after_processing
    Play
endif