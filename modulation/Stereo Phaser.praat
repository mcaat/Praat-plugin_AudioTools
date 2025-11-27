# ============================================================
# Praat AudioTools - Stereo Phaser.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Stereo Phaser
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Stereo Phaser Effect
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Classic 70s Phaser
        option Slow & Deep
        option Jet Plane (High Resonance)
        option Fast Wobble
        option Wide Stereo Widener
        option Sci-Fi Raygun
    
    comment --- LFO Settings (The Sweep) ---
    positive Rate_hz 0.5
    positive Depth_ms 2.0
    positive Center_delay_ms 3.0
    
    comment --- Stereo Image ---
    positive Stereo_Phase_Offset_deg 180
    comment (180 = Wide/Counter-sweep, 0 = Mono)
    
    comment --- Intensity ---
    positive Feedback_Resonance 0.6
    positive Dry_Wet_Mix 0.5
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# ============================================================
# PRESET LOGIC ENGINE
# ============================================================

if preset = 2
    # Classic 70s Phaser
    rate_hz = 0.6
    depth_ms = 1.5
    center_delay_ms = 2.5
    stereo_Phase_Offset_deg = 90
    feedback_Resonance = 0.4
    dry_Wet_Mix = 0.5

elsif preset = 3
    # Slow & Deep
    rate_hz = 0.2
    depth_ms = 3.5
    center_delay_ms = 4.0
    stereo_Phase_Offset_deg = 180
    feedback_Resonance = 0.5
    dry_Wet_Mix = 0.6

elsif preset = 4
    # Jet Plane (High Resonance)
    rate_hz = 0.15
    depth_ms = 2.0
    center_delay_ms = 1.5
    stereo_Phase_Offset_deg = 0
    feedback_Resonance = 0.85
    dry_Wet_Mix = 0.5

elsif preset = 5
    # Fast Wobble
    rate_hz = 4.0
    depth_ms = 1.0
    center_delay_ms = 2.0
    stereo_Phase_Offset_deg = 180
    feedback_Resonance = 0.3
    dry_Wet_Mix = 0.4

elsif preset = 6
    # Wide Stereo Widener (Subtle movement)
    rate_hz = 0.1
    depth_ms = 0.8
    center_delay_ms = 5.0
    stereo_Phase_Offset_deg = 180
    feedback_Resonance = 0.0
    dry_Wet_Mix = 0.3

elsif preset = 7
    # Sci-Fi Raygun
    rate_hz = 2.5
    depth_ms = 4.0
    center_delay_ms = 1.0
    stereo_Phase_Offset_deg = 180
    feedback_Resonance = 0.9
    dry_Wet_Mix = 0.5
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
base_samp = center_delay_ms * fs / 1000
mod_samp = depth_ms * fs / 1000

# ============================================================
# STEREO CHECK & CONVERSION
# ============================================================
# If sound is Mono, we must convert to Stereo to hear the width
if channels = 1
    Convert to stereo
    sound = selected("Sound")
    name$ = name$ + "_stereo"
endif

# ============================================================
# APPLY PHASER FORMULA
# ============================================================

Copy: name$ + "_phaser"
processed = selected("Sound")

# 1. Apply Feedback / Resonance Layer (Pre-shaping)
# We create a sharper peak by adding a self-modulated layer first
if feedback_Resonance > 0
    Formula: "self + 'feedback_Resonance' * self[col - round('base_samp' + 'mod_samp' * sin(2*pi*'rate_hz'*x + (row-1)*'phase_rad'))]"
endif

# 2. Apply Main Phaser Mixing (The Notch Creator)
# Row 1 (Left) uses sin(wt)
# Row 2 (Right) uses sin(wt + phase_offset)
Formula: "(1 - 'dry_Wet_Mix') * self + 'dry_Wet_Mix' * self[col - round('base_samp' + 'mod_samp' * sin(2*pi*'rate_hz'*x + (row-1)*'phase_rad'))]"

# ============================================================
# CLEANUP
# ============================================================

Scale peak: scale_peak

if play_after_processing
    Play
endif