# ============================================================
# Praat AudioTools - Golden-chaos_vibrato.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   A chaotic vibrato using irrational numbers (Pi, Euler, Phi)
#   to create non-repeating modulation patterns.
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Golden-Chaos Vibrato Effect
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Golden Shimmer (Phi driven - Smooth)
        option Euler's Wobble (e driven - Asymmetric)
        option Pi Cycle (Pi driven - Classic)
        option Mathematical Chaos (Full Mix)
        option Subtle Irregularity
        option Deep Math Texture
    
    comment --- Delay Parameters ---
    positive Base_delay_ms 6.0
    positive Modulation_depth 0.14
    
    comment --- Modulation Rates (Irrational Constants) ---
    positive Rate1_hz 3.14159
    comment (Pi - π)
    positive Rate2_hz 2.71828
    comment (e - Euler's Number)
    positive Rate3_hz 1.61803
    comment (Phi - Golden Ratio)
    
    comment --- Mixing Ratios ---
    positive Rate2_mix 0.6
    positive Rate3_mix 0.4
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
# Rename source to a safe temporary ID to prevent formula errors
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# PRESET LOGIC ENGINE
# ============================================================

if preset = 2
    # Golden Shimmer
    base_delay_ms = 5.0
    modulation_depth = 0.08
    rate1_hz = 1.618
    rate2_hz = 3.236
    rate3_hz = 0.618
    rate2_mix = 0.3
    rate3_mix = 0.5

elsif preset = 3
    # Euler's Wobble
    base_delay_ms = 7.0
    modulation_depth = 0.15
    rate1_hz = 2.718
    rate2_hz = 5.436
    rate3_hz = 1.0
    rate2_mix = 0.8
    rate3_mix = 0.2

elsif preset = 4
    # Pi Cycle
    base_delay_ms = 6.0
    modulation_depth = 0.12
    rate1_hz = 3.14159
    rate2_hz = 6.28318
    rate3_hz = 1.57079
    rate2_mix = 0.2
    rate3_mix = 0.1

elsif preset = 5
    # Mathematical Chaos
    base_delay_ms = 8.0
    modulation_depth = 0.20
    rate1_hz = 3.14159
    rate2_hz = 2.71828
    rate3_hz = 1.61803
    rate2_mix = 1.0
    rate3_mix = 1.0

elsif preset = 6
    # Subtle Irregularity
    base_delay_ms = 4.0
    modulation_depth = 0.05
    rate1_hz = 3.14159
    rate2_hz = 2.71828
    rate3_hz = 1.61803
    rate2_mix = 0.5
    rate3_mix = 0.5

elsif preset = 7
    # Deep Math Texture
    base_delay_ms = 12.0
    modulation_depth = 0.25
    rate1_hz = 0.314
    rate2_hz = 0.271
    rate3_hz = 0.161
    rate2_mix = 0.7
    rate3_mix = 0.7
endif

# ============================================================
# PROCESSING
# ============================================================

selectObject: original_sound_id
sampling = Get sampling frequency
base = round(base_delay_ms * sampling / 1000)

# Create output
Copy: original_name$ + "_chaos"
processed_id = selected("Sound")

# Apply Nested Modulation Formula
# WE READ FROM 'Sound_SourceAudio_Temp' explicitly to ensure data exists.
# We use [row, ...] to ensure stereo channels are preserved.

Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate1_hz'*x + 'rate2_mix'*sin(2*pi*'rate2_hz'*x) + 'rate3_mix'*sin(2*pi*'rate3_hz'*x))))))]"

# ============================================================
# CLEANUP
# ============================================================

# Restore original name
selectObject: original_sound_id
Rename: original_name$

# Finalize output
selectObject: processed_id
Scale peak: scale_peak

if play_after_processing
    Play
endif