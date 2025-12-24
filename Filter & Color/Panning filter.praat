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

# --- 1. Store Original & MEASURE DURATION ---
originalID = selected("Sound")
originalName$ = selected$("Sound")
originalDur = Get total duration

# --- 2. Process ---
selectObject: originalID
Copy: "tmp"
tmpSound = selected("Sound")

# Check stereo
numChan = Get number of channels
if numChan = 1
    stereoID = Convert to stereo
    removeObject: tmpSound
    tmpSound = stereoID
endif

selectObject: tmpSound
Extract all channels
ch1 = selected("Sound", 1)
ch2 = selected("Sound", 2)

# --- 3. Convert to spectra (with padding) ---
selectObject: ch1
spectrum_ch1 = To Spectrum: "yes"
selectObject: ch2
spectrum_ch2 = To Spectrum: "yes"

# --- 4. Apply frequency filters ---
selectObject: spectrum_ch1
Formula: "if x < freq then self else 0 fi"
sound_ch1 = To Sound

selectObject: spectrum_ch2
Formula: "if x > freq then self else 0 fi"
sound_ch2 = To Sound

# --- 5. Combine and CROP SILENCE ---
selectObject: sound_ch1
plusObject: sound_ch2
combinedID = Combine to stereo

# !! THIS IS THE FIX !!
# We cut the sound from 0 to the original duration
finalSound = Extract part: 0, originalDur, "rectangular", 1, "no"
Rename: originalName$ + "_panned"

# --- 6. Play ---
Play

# --- 7. Cleanup ---
# Remove the padded version (combinedID) and the others
selectObject: tmpSound
plusObject: ch1
plusObject: ch2
plusObject: spectrum_ch1
plusObject: spectrum_ch2
plusObject: sound_ch1
plusObject: sound_ch2
plusObject: combinedID
Remove