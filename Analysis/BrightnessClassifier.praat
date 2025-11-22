# ============================================================
# Praat AudioTools - BrightnessClassifier.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Audio Brightness Classifier based on spectral centroid analysis
#   Classifies audio into five brightness categories: very_dark, dark, 
#   medium, bright, and very_bright
#
# Usage:
#   Select one or more Sound objects in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

clearinfo

form Audio Brightness Classification
    comment Frequency bands optimized for music:
    positive low_freq 200
    positive mid_freq 1000
    positive high_freq 4000
endform

# Get number of selected sounds
number_of_selected_sounds = numberOfSelected("Sound")
if number_of_selected_sounds = 0
    exitScript: "Please select at least one Sound object first"
endif

# Store references to all selected sounds
for index to number_of_selected_sounds
    sound'index' = selected("Sound", index)
endfor

# Process each sound
for current_sound_index from 1 to number_of_selected_sounds
    select sound'current_sound_index'
    sound_name$ = selected$("Sound")
    
    # Get overall spectral analysis
    To Spectrum: "yes"
    spectrum = selected("Spectrum")
    
    # Get energy in frequency bands optimized for music
    select spectrum
    bass = Get band energy: 100, low_freq
    low_mid = Get band energy: low_freq, mid_freq  
    high_mid = Get band energy: mid_freq, high_freq
    high_freq_energy = Get band energy: high_freq, 10000
    
    # Calculate spectral centroid
    total_energy = bass + low_mid + high_mid + high_freq_energy
    
    if total_energy > 0
        spectral_centroid = ((bass * 150) + (low_mid * 600) + (high_mid * 2500) + (high_freq_energy * 7500)) / total_energy
    else
        spectral_centroid = 0
    endif
    
    # Classification thresholds
    if spectral_centroid < 300
        category$ = "very_dark"
    elsif spectral_centroid >= 300 and spectral_centroid < 600
        category$ = "dark"
    elsif spectral_centroid >= 600 and spectral_centroid < 1200
        category$ = "medium"
    elsif spectral_centroid >= 1200 and spectral_centroid < 2000
        category$ = "bright"
    else
        category$ = "very_bright"
    endif
    
    # Clean output
    appendInfoLine: sound_name$ + ": " + string$(round(spectral_centroid)) + " Hz → " + category$
    
    # Cleanup
    select spectrum
    Remove
endfor

# Reselect all original sounds
select sound1
for current_sound_index from 2 to number_of_selected_sounds
    plus sound'current_sound_index'
endfor