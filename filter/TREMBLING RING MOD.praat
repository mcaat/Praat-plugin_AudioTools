# ============================================================
# Praat AudioTools - TREMBLING RING MOD.praat
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
form Trembling Ring Modulation
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Gentle Warble (200Hz, slow)
        option Radio Interference (440Hz, fast)
        option Deep Space (100Hz, medium)
        option Vintage Synth (300Hz, fast)
        option Alien Voice (150Hz, very fast)
    comment ==== Modulation parameters ====
    positive f0 200
    comment (carrier frequency in Hz)
    positive vibrato_rate 15
    comment (vibrato rate in Hz)
    real vibrato_depth 0.05
    comment (vibrato depth, 0-1 range)
endform

# Apply preset values if not Custom
if preset = 2
    # Gentle Warble
    f0 = 200
    vibrato_rate = 5
    vibrato_depth = 0.03
elsif preset = 3
    # Radio Interference
    f0 = 440
    vibrato_rate = 25
    vibrato_depth = 0.08
elsif preset = 4
    # Deep Space
    f0 = 100
    vibrato_rate = 10
    vibrato_depth = 0.1
elsif preset = 5
    # Vintage Synth
    f0 = 300
    vibrato_rate = 20
    vibrato_depth = 0.06
elsif preset = 6
    # Alien Voice
    f0 = 150
    vibrato_rate = 30
    vibrato_depth = 0.12
endif

Copy... soundObj
Formula... self*(sin(2*pi*f0*(1 + vibrato_depth*sin(2*pi*vibrato_rate*x))*x*x/2))
Play