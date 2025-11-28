# ============================================================
# Praat AudioTools - SPIRAL FREQUENCY MODULATION.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Filtering or timbral modification script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Spiral Ring Modulation
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Spiral (200Hz, slow)
        option Classic Vortex (250Hz, medium)
        option Intense Whirlpool (300Hz, fast)
        option Deep Rotation (150Hz, slow wide)
        option Hypnotic Spin (400Hz, very fast)
        option Cosmic Spiral (180Hz, ultra wide)
    comment ==== Modulation parameters ====
    positive center_f0 250
    comment (center frequency in Hz)
    positive spiral_rate 0.8
    comment (spiral rotation speed)
    positive spiral_depth 150
    comment (frequency deviation range in Hz)
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Spiral
    center_f0 = 200
    spiral_rate = 0.5
    spiral_depth = 80
elsif preset = 3
    # Classic Vortex
    center_f0 = 250
    spiral_rate = 0.8
    spiral_depth = 150
elsif preset = 4
    # Intense Whirlpool
    center_f0 = 300
    spiral_rate = 1.2
    spiral_depth = 200
elsif preset = 5
    # Deep Rotation
    center_f0 = 150
    spiral_rate = 0.6
    spiral_depth = 120
elsif preset = 6
    # Hypnotic Spin
    center_f0 = 400
    spiral_rate = 1.5
    spiral_depth = 180
elsif preset = 7
    # Cosmic Spiral
    center_f0 = 180
    spiral_rate = 0.7
    spiral_depth = 250
endif

Copy... soundObj
Formula... self*(sin(2*pi*(center_f0 + spiral_depth*sin(spiral_rate*x)*x/xmax)*x))
Play