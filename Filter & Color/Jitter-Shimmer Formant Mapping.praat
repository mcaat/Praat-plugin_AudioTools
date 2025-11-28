# ============================================================
# Praat AudioTools - Jitter-Shimmer Formant Mapping.praat
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

form Jitter Shimmer to Formant Mapping
    comment Select sounds to analyze and modify...
    choice preset 1
        option modal low perturbation
        option breathy high shimmer
        option creaky high jitter
        option custom
    positive f1base 500
    positive f2base 1500
    positive jitterfactor 0.1
    positive shimmerfactor 0.08
endform

appendInfoLine: "=== JITTER/SHIMMER TO FORMANT MAPPING ==="

# Check if sounds are selected
if not selected("Sound")
    exitScript: "Please select Sound objects first."
endif

number_of_selected_sounds = numberOfSelected("Sound")
appendInfoLine: "Number of sounds selected: ", number_of_selected_sounds

# Store selected sounds in array
for i from 1 to number_of_selected_sounds
    sound'i' = selected("Sound", i)
endfor

# Preset configurations
if preset = 1
    # Modal preset
    f1base = 500
    f2base = 1500
    jitterfactor = 0.1
    shimmerfactor = 0.08
    presetname$ = "modal"
elsif preset = 2
    # Breathy preset
    f1base = 500
    f2base = 1700
    jitterfactor = 0.08
    shimmerfactor = 0.12
    presetname$ = "breathy"
elsif preset = 3
    # Creaky preset
    f1base = 460
    f2base = 1400
    jitterfactor = 0.15
    shimmerfactor = 0.06
    presetname$ = "creaky"
else
    # Custom - use user input values
    presetname$ = "custom"
endif

appendInfoLine: "Using preset: ", presetname$
appendInfoLine: "F1 base: ", f1base, " Hz, F2 base: ", f2base, " Hz"
appendInfoLine: "Jitter factor: ", jitterfactor, ", Shimmer factor: ", shimmerfactor

appendInfoLine: newline$, "=== ANALYZING JITTER AND SHIMMER ==="

# Analyze each sound and store jitter/shimmer values
for current_sound from 1 to number_of_selected_sounds
    select sound'current_sound'
    name$ = selected$("Sound")
    
    # Analyze jitter and shimmer in one go
    select sound'current_sound'
    pitch = To Pitch (raw cc): 0, 75, 600, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14
    select sound'current_sound'
    plus pitch
    pointprocess = To PointProcess (cc)
    select sound'current_sound'
    plus pitch
    plus pointprocess
    voiceReport$ = Voice report: 0, 0, 75, 600, 1.3, 1.6, 0.03, 0.45
    
    jitter = (extractNumber(voiceReport$, "Jitter (local): ")) * 100
    shimmer = (extractNumber(voiceReport$, "Shimmer (local): ")) * 100
    
    appendInfoLine: "Sound: ", name$, " - Jitter: ", fixed$(jitter, 2), "%, Shimmer: ", fixed$(shimmer, 2), "%"
    
    # Store values for later use
    jitter'current_sound' = jitter
    shimmer'current_sound' = shimmer
    
    # Clean up analysis objects
    select pitch
    plus pointprocess
    Remove
endfor

appendInfoLine: newline$, "=== APPLYING FORMANT MODIFICATIONS ==="

# Apply formant modifications based on jitter/shimmer
for current_sound from 1 to number_of_selected_sounds
    select sound'current_sound'
    originalName$ = selected$("Sound")
    
    jitter = jitter'current_sound'
    shimmer = shimmer'current_sound'
    
    appendInfoLine: "Processing: ", originalName$, " (Jitter: ", fixed$(jitter, 2), "%, Shimmer: ", fixed$(shimmer, 2), "%)"
    
    # Map jitter to F1 modification and shimmer to F2 modification using preset factors
    f1shiftfactor = 1.0 + (jitter * jitterfactor)
    f2shiftfactor = 1.0 + (shimmer * shimmerfactor)
    
    appendInfoLine: "  F1 shift factor: ", fixed$(f1shiftfactor, 3)
    appendInfoLine: "  F2 shift factor: ", fixed$(f2shiftfactor, 3)
    
    # SIMPLE APPROACH: Use band-pass filtering to emphasize modified formant regions
    select sound'current_sound'
    
    # Create band-pass filters around modified F1 and F2 regions
    # F1 region (typically 300-900 Hz)
    f1low = f1base * f1shiftfactor
    f1high = (f1base + 400) * f1shiftfactor
    
    # F2 region (typically 900-2500 Hz)  
    f2low = f2base * f2shiftfactor
    f2high = (f2base + 600) * f2shiftfactor
    
    # Apply band-pass filtering for F1 region
    select sound'current_sound'
    f1filtered = Filter (pass Hann band): f1low, f1high, 100
    
    # Apply band-pass filtering for F2 region
    select sound'current_sound'
    f2filtered = Filter (pass Hann band): f2low, f2high, 100
    
    # Combine the filtered sounds
    select f1filtered
    plus f2filtered
    combined = Combine to stereo
    
    # Convert to mono if needed
    select combined
    finalSound = Convert to mono
    Rename: "formantmod" + originalName$ + presetname$
    Scale peak: 0.99

    # Play original and modified
    appendInfoLine: "  Playing modified sound..."
    select finalSound
    Play
    
    # Clean up temporary objects
    select f1filtered
    plus f2filtered
    plus combined
    Remove
    
    appendInfoLine: "  Completed: ", originalName$
endfor

appendInfoLine: newline$, "=== MAPPING SUMMARY ==="
appendInfoLine: "Preset: ", presetname$
appendInfoLine: "Jitter → Formant 1 region: Higher jitter = higher F1 frequencies"
appendInfoLine: "Shimmer → Formant 2 region: Higher shimmer = higher F2 frequencies"
appendInfoLine: "Method: Band-pass filtering around modified formant regions"