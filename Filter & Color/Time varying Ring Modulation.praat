# ============================================================
# Praat AudioTools - Time varying Ring Modulation.praat
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

form Time Varying Ring Modulation
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Subtle Shimmer (100Hz)
        option Rising Metallic (200Hz)
        option Sci-Fi Sweep (300Hz)
        option Laser Beam (500Hz)
        option Extreme Glitch (800Hz)
    comment ==== Modulation parameters ====
    positive f0 200
    comment (starting frequency in Hz - sweeps upward over time)
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Shimmer
    f0 = 100
elsif preset = 3
    # Rising Metallic
    f0 = 200
elsif preset = 4
    # Sci-Fi Sweep
    f0 = 300
elsif preset = 5
    # Laser Beam
    f0 = 500
elsif preset = 6
    # Extreme Glitch
    f0 = 800
endif

Copy... soundObj
Formula... self*(sin(2*pi*f0*x*x/2))
Play