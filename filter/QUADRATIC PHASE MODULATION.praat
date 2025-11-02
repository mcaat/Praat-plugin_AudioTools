# ============================================================
# Praat AudioTools - QUADRATIC PHASE MODULATION.praat
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


form Quadratic Phase Ring Modulation
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Bend (150Hz, subtle)
        option Classic Sweep (200Hz, moderate)
        option Dramatic Warp (250Hz, intense)
        option Reverse Bend (180Hz, negative)
        option Extreme Distortion (300Hz, extreme)
        option Subtle Shimmer (120Hz, minimal)
    comment ==== Modulation parameters ====
    positive f0 150
    comment (carrier frequency in Hz)
    real phase_curve 0.5
    comment (phase curvature - positive/negative for different effects)
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Bend
    f0 = 150
    phase_curve = 0.3
elsif preset = 3
    # Classic Sweep
    f0 = 200
    phase_curve = 0.5
elsif preset = 4
    # Dramatic Warp
    f0 = 250
    phase_curve = 1.0
elsif preset = 5
    # Reverse Bend
    f0 = 180
    phase_curve = -0.4
elsif preset = 6
    # Extreme Distortion
    f0 = 300
    phase_curve = 1.5
elsif preset = 7
    # Subtle Shimmer
    f0 = 120
    phase_curve = 0.1
endif

Copy... soundObj
Formula... self*(sin(2*pi*f0*x + phase_curve*x*x*x))
Play