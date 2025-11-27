# ============================================================
# Praat AudioTools - Stereo Flanger.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Stereo Flanger
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Stereo Flanger Effect
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Classic 80s Flanger
        option Slow Jet (High Feedback)
        option Liquid Metal (Fast)
        option Deep Throat (Long Delay)
        option Through-Zero (Simulated)
        option Subtle Stereo Widener
    
    comment --- LFO Settings ---
    positive Rate_hz 0.3
    positive Depth_ms 2.0
    positive Base_delay_ms 3.0
    
    comment --- Stereo Image ---
    positive Stereo_Phase_Offset_deg 180
    comment (180 = Wide/Counter-sweep, 0 = Mono)
    
    comment --- Mix & Feedback ---
    real Feedback 0.7
    positive Dry_Wet_Mix 0.5
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# ============================================================
# PRESET LOGIC ENGINE
# ============================================================

if preset = 2
    # Classic 80s Flanger
    rate_hz = 0.5
    depth_ms = 1.5
    base_delay_ms = 2.0
    stereo_Phase_Offset_deg = 90
    feedback = 0.6
    dry_Wet_Mix = 0.5

elsif preset = 3
    # Slow Jet (High Feedback)
    rate_hz = 0.15
    depth_ms = 2.5
    base_delay_ms = 3.0
    stereo_Phase_Offset_deg = 180
    feedback = 0.85
    dry_Wet_Mix = 0.5

elsif preset = 4
    # Liquid Metal (Fast)
    rate_hz = 3.0
    depth_ms = 0.5
    base_delay_ms = 1.0
    stereo_Phase_Offset_deg = 180
    feedback = -0.7
    dry_Wet_Mix = 0.6

elsif preset = 5
    # Deep Throat (Long Delay - More Chorus-like)
    rate_hz = 0.4
    depth_ms = 4.0
    base_delay_ms = 8.0
    stereo_Phase_Offset_deg = 45
    feedback = 0.5
    dry_Wet_Mix = 0.5

elsif preset = 6
    # Through-Zero (Simulated - extremely short delay)
    rate_hz = 0.2
    depth_ms = 0.9
    base_delay_ms = 1.0
    stereo_Phase_Offset_deg = 180
    feedback = 0.4
    dry_Wet_Mix = 0.7

elsif preset = 7
    # Subtle Stereo Widener
    rate_hz = 0.1
    depth_ms = 1.0
    base_delay_ms = 5.0
    stereo_Phase_Offset_deg = 180
    feedback = 0.1
    dry_Wet_Mix = 0.4
endif

# Check for Sound
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

sound = selected("Sound")
name$ = selected$("Sound")
channels = Get number of channels

# Convert stereo phase to radians
phase_rad = stereo_Phase_Offset_deg * pi / 180

# Get Sampling Info
selectObject: sound
fs = Get sampling frequency

# Calculate samples
base_samp = base_delay_ms * fs / 1000
mod_samp = depth_ms * fs / 1000

# ============================================================
# STEREO CHECK & CONVERSION
# ============================================================
if channels = 1
    Convert to stereo
    sound = selected("Sound")
    name$ = name$ + "_stereo"
endif

# ============================================================
# APPLY FLANGER FORMULA
# ============================================================

Copy: name$ + "_flanger"
processed = selected("Sound")

# 1. Apply Feedback Layer (Approximation)
# Flangers rely heavily on feedback (recursion). 
# We simulate the first reflection of feedback to tighten the sound.
if feedback <> 0
    Formula: "self + 'feedback' * self[col - round('base_samp' + 'mod_samp' * sin(2*pi*'rate_hz'*x + (row-1)*'phase_rad'))]"
endif

# 2. Apply Main Flange Mix
# This combines the Dry signal with the Modulated Delay line.
# Note: Liquid Metal preset uses Negative Feedback (inverted phase) for a hollow sound.
Formula: "(1 - 'dry_Wet_Mix') * self + 'dry_Wet_Mix' * self[col - round('base_samp' + 'mod_samp' * sin(2*pi*'rate_hz'*x + (row-1)*'phase_rad'))]"

# ============================================================
# CLEANUP
# ============================================================

Scale peak: scale_peak

if play_after_processing
    Play
endif