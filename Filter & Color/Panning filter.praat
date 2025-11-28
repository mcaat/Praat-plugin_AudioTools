# ============================================================
# Praat AudioTools - Panning filter.praat
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

# ============================================================
# Praat AudioTools - Panning filter.praat
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

form Panning filter
    comment Please select a stereo file
    positive freq 500
endform

# Store the original sound
originalSound = selected("Sound")
originalName$ = selected$("Sound")

# Process
Copy: "tmp"
tmpSound = selected("Sound")
Extract all channels

# Get channel objects
ch1 = selected("Sound", 1)
ch2 = selected("Sound", 2)

# Convert to spectra
select ch1
spectrum_ch1 = To Spectrum: "yes"
select ch2
spectrum_ch2 = To Spectrum: "yes"

# Apply frequency filters
select spectrum_ch1
Formula: "if x <freq then self else 0 fi"
sound_ch1 = To Sound
select spectrum_ch2
Formula: "if x >freq then self else 0 fi"
sound_ch2 = To Sound

# Combine to stereo
select sound_ch1
plus sound_ch2
finalSound = Combine to stereo
Rename: "'originalName$'_panned"

# Play the result
Play

# Cleanup: Remove all intermediate objects, keep only original + result
select tmpSound
plus ch1
plus ch2
plus spectrum_ch1
plus spectrum_ch2
plus sound_ch1
plus sound_ch2
Remove

