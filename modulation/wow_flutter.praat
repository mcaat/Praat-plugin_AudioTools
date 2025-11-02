# ============================================================
# Praat AudioTools - wow_flutter.praat
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

form Wow and Flutter Vibrato Effect
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Vintage Cassette (subtle wow, moderate flutter)
        option Old Reel-to-Reel (slow wow, gentle flutter)
        option Damaged Tape (heavy wow and flutter)
        option VHS Tracking Issues (fast flutter, noise)
        option Warped Vinyl (slow wow, minimal flutter)
        option Underwater Effect (extreme slow modulation)
    comment ==== Delay Parameters ====
    positive base_delay_ms 7.0
    comment (base delay time in milliseconds)
    positive modulation_depth 0.12
    comment (overall modulation intensity, 0-1)
    comment ==== Wow Parameters (slow speed variation) ====
    positive wow_rate_hz 0.6
    comment (wow frequency in Hz - slow variation)
    positive wow_mix 0.6
    comment (wow amount, 0-1)
    comment ==== Flutter Parameters (fast speed variation) ====
    positive flutter_rate_hz 6.5
    comment (flutter frequency in Hz - fast variation)
    positive flutter_mix 0.4
    comment (flutter amount, 0-1)
    positive flutter_phase_offset 1.1
    comment (flutter phase offset in radians)
    comment ==== Noise Parameters (random variation) ====
    positive noise_amount 0.02
    comment (random noise amount, 0-1)
    positive noise_frequency 17.3
    comment (noise modulation frequency in Hz)
    positive noise_phase_offset 0.8
    comment (noise phase offset in radians)
    comment ==== Output Options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Vintage Cassette
    base_delay_ms = 7.0
    modulation_depth = 0.10
    wow_rate_hz = 0.8
    wow_mix = 0.5
    flutter_rate_hz = 8.0
    flutter_mix = 0.4
    flutter_phase_offset = 1.1
    noise_amount = 0.03
    noise_frequency = 15.0
    noise_phase_offset = 0.8
elsif preset = 3
    # Old Reel-to-Reel
    base_delay_ms = 10.0
    modulation_depth = 0.08
    wow_rate_hz = 0.4
    wow_mix = 0.7
    flutter_rate_hz = 5.0
    flutter_mix = 0.3
    flutter_phase_offset = 0.9
    noise_amount = 0.015
    noise_frequency = 12.0
    noise_phase_offset = 0.5
elsif preset = 4
    # Damaged Tape
    base_delay_ms = 12.0
    modulation_depth = 0.25
    wow_rate_hz = 1.2
    wow_mix = 0.8
    flutter_rate_hz = 10.0
    flutter_mix = 0.7
    flutter_phase_offset = 1.5
    noise_amount = 0.08
    noise_frequency = 25.0
    noise_phase_offset = 1.2
elsif preset = 5
    # VHS Tracking Issues
    base_delay_ms = 8.0
    modulation_depth = 0.15
    wow_rate_hz = 0.5
    wow_mix = 0.4
    flutter_rate_hz = 12.0
    flutter_mix = 0.8
    flutter_phase_offset = 2.0
    noise_amount = 0.06
    noise_frequency = 30.0
    noise_phase_offset = 1.5
elsif preset = 6
    # Warped Vinyl
    base_delay_ms = 6.0
    modulation_depth = 0.18
    wow_rate_hz = 0.3
    wow_mix = 0.9
    flutter_rate_hz = 4.0
    flutter_mix = 0.2
    flutter_phase_offset = 0.7
    noise_amount = 0.01
    noise_frequency = 8.0
    noise_phase_offset = 0.3
elsif preset = 7
    # Underwater Effect
    base_delay_ms = 15.0
    modulation_depth = 0.30
    wow_rate_hz = 0.2
    wow_mix = 1.0
    flutter_rate_hz = 3.0
    flutter_mix = 0.5
    flutter_phase_offset = 0.5
    noise_amount = 0.04
    noise_frequency = 10.0
    noise_phase_offset = 1.0
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound name
originalName$ = selected$("Sound")

# Work on a copy
Copy: originalName$ + "_wow_flutter"

# Get sampling frequency
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Apply wow and flutter vibrato
# Combines slow wow, fast flutter, and random noise
Formula: "self[max(1, min(ncol, col + round('base' * (1 + 'modulation_depth' * ('wow_mix' * sin(2 * pi * 'wow_rate_hz' * x) + 'flutter_mix' * sin(2 * pi * 'flutter_rate_hz' * x + 'flutter_phase_offset') + 'noise_amount' * sin(2 * pi * 'noise_frequency' * x + 'noise_phase_offset'))))))]"

# Rename result
Rename: originalName$ + "_vibrato_wow_flutter"

# Scale to peak
Scale peak: scale_peak

# Play if requested
if play_after_processing
    Play
endif