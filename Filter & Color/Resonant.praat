# ============================================================
# Praat AudioTools - Resonant.praat
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

form Random Delay Feedback
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Light Echo (5 repeats)
        option Medium Reverb (10 repeats)
        option Dense Space (20 repeats)
        option Extreme Chaos (30 repeats)
        option Subtle Texture (3 repeats)
    comment ==== Delay parameters ====
    positive ntimes 20
    comment (number of feedback iterations)
    real feedback_amount 0.5
    comment (feedback gain, 0-1 range)
    positive max_delay_samples 1000
    comment (maximum random delay in samples)
    comment ==== Output options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Light Echo
    ntimes = 5
    feedback_amount = 0.5
    max_delay_samples = 1000
elsif preset = 3
    # Medium Reverb
    ntimes = 10
    feedback_amount = 0.5
    max_delay_samples = 1500
elsif preset = 4
    # Dense Space
    ntimes = 20
    feedback_amount = 0.5
    max_delay_samples = 2000
elsif preset = 5
    # Extreme Chaos
    ntimes = 30
    feedback_amount = 0.6
    max_delay_samples = 2500
elsif preset = 6
    # Subtle Texture
    ntimes = 3
    feedback_amount = 0.4
    max_delay_samples = 800
endif

Copy... tmp
delay = randomInteger(0, max_delay_samples)
for i from 1 to ntimes
    Formula... self + 'feedback_amount'*self[col-'delay']
endfor
Scale peak: scale_peak

if play_after_processing
    Play
endif
