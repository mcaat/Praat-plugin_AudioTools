# ============================================================
# Praat AudioTools - Adaptive Pitch Shifter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-based transformation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Enhanced Adaptive Pitch Shifter with Presets and Advanced Controls
# Version 2.0

# Check for selected sound
sound = selected("Sound")
if !sound
    exitScript: "Please select a Sound object first."
endif

# Get sound info for validation
selectObject: sound
duration = Get total duration
sampleRate = Get sampling frequency
originalName$ = selected$("Sound")

# Enhanced form with presets and advanced controls
form Enhanced Adaptive Pitch Shift
    comment === PRESETS ===
    optionmenu Preset: 1
        option Custom
        option Subtle Wobble
        option Robot Voice
        option Harmonic Shimmer
        option Deep Bass Mod
        option Vibrato Effect
        option Extreme Warp
    comment === BASIC CONTROLS ===
    positive Base_pitch_shift 1.0
    positive Modulation_amount 0.5
    comment === ADVANCED CONTROLS ===
    optionmenu Modulation_source: 1
        option Amplitude
        option Pitch Contour
        option Time-based LFO
        option Combined
    positive LFO_frequency 3.0
    positive Smoothing_factor 0.1
    comment === PROCESSING OPTIONS ===
    boolean Apply_formant_preservation 1
    boolean Add_stereo_width 0
    positive Output_gain 1.0
    comment === QUALITY ===
    optionmenu Quality: 2
        option Fast
        option Standard
        option High Quality
    boolean Preview_only 0
endform

# Apply preset values
if preset = 2
    # Subtle Wobble
    base_pitch_shift = 1.0
    modulation_amount = 0.15
    modulation_source = 1
    lFO_frequency = 4.0
    smoothing_factor = 0.2
elsif preset = 3
    # Robot Voice
    base_pitch_shift = 0.8
    modulation_amount = 0.8
    modulation_source = 3
    lFO_frequency = 8.0
    smoothing_factor = 0.05
elsif preset = 4
    # Harmonic Shimmer
    base_pitch_shift = 1.5
    modulation_amount = 0.3
    modulation_source = 2
    lFO_frequency = 2.0
    smoothing_factor = 0.3
elsif preset = 5
    # Deep Bass Mod
    base_pitch_shift = 0.5
    modulation_amount = 1.0
    modulation_source = 4
    lFO_frequency = 1.5
    smoothing_factor = 0.15
elsif preset = 6
    # Vibrato Effect
    base_pitch_shift = 1.0
    modulation_amount = 0.08
    modulation_source = 3
    lFO_frequency = 5.5
    smoothing_factor = 0.4
elsif preset = 7
    # Extreme Warp
    base_pitch_shift = 1.2
    modulation_amount = 1.5
    modulation_source = 4
    lFO_frequency = 10.0
    smoothing_factor = 0.0
endif

# Set quality parameters
if quality = 1
    # Fast
    timestep = 0.01
    pitchFloor = 75
    pitchCeiling = 600
elsif quality = 2
    # Standard
    timestep = 0.005
    pitchFloor = 75
    pitchCeiling = 600
elsif quality = 3
    # High Quality
    timestep = 0.001
    pitchFloor = 50
    pitchCeiling = 800
endif

# === MAIN PROCESSING ===
writeInfoLine: "Processing: ", originalName$
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Base pitch shift: ", base_pitch_shift
appendInfoLine: "Modulation amount: ", modulation_amount
appendInfoLine: "Modulation source: ", modulation_source$

# Extract pitch if needed
selectObject: sound
if modulation_source = 2 or modulation_source = 4
    appendInfoLine: "Extracting pitch contour..."
    pitch = To Pitch: timestep, pitchFloor, pitchCeiling
endif

# Extract intensity for amplitude modulation
if modulation_source = 1 or modulation_source = 4
    selectObject: sound
    appendInfoLine: "Extracting amplitude envelope..."
    intensity = To Intensity: pitchFloor, timestep, "yes"
    intensityTier = Down to IntensityTier
endif

# Create manipulation object
selectObject: sound
appendInfoLine: "Creating manipulation object..."
manipulation = To Manipulation: timestep, pitchFloor, pitchCeiling

# Extract pitch tier for modification
selectObject: manipulation
pitchTier = Extract pitch tier

# Get number of points
selectObject: pitchTier
numPoints = Get number of points

appendInfoLine: "Modifying pitch at ", numPoints, " points..."

# Modify pitch tier based on modulation source
for i from 1 to numPoints
    selectObject: pitchTier
    time = Get time from index: i
    originalFreq = Get value at index: i
    
    if originalFreq != undefined
        modulation = 0
        
        # Calculate modulation based on source
        if modulation_source = 1
            # Amplitude-based
            selectObject: intensityTier
            amplitude = Get value at time: time
            if amplitude != undefined
                normalizedAmp = (amplitude - 40) / 60
                normalizedAmp = max(0, min(1, normalizedAmp))
                modulation = normalizedAmp
            endif
            
        elsif modulation_source = 2
            # Pitch contour-based
            selectObject: pitch
            currentPitch = Get value at time: time, "Hertz", "Linear"
            if currentPitch != undefined
                normalizedPitch = (currentPitch - pitchFloor) / (pitchCeiling - pitchFloor)
                modulation = normalizedPitch
            endif
            
        elsif modulation_source = 3
            # Time-based LFO
            modulation = (sin(2 * pi * lFO_frequency * time) + 1) / 2
            
        elsif modulation_source = 4
            # Combined (Amplitude + LFO)
            selectObject: intensityTier
            amplitude = Get value at time: time
            if amplitude != undefined
                normalizedAmp = (amplitude - 40) / 60
                normalizedAmp = max(0, min(1, normalizedAmp))
                lfo = (sin(2 * pi * lFO_frequency * time) + 1) / 2
                modulation = (normalizedAmp + lfo) / 2
            endif
        endif
        
        # Apply smoothing
        if smoothing_factor > 0 and i > 1
            selectObject: pitchTier
            prevFreq = Get value at index: i-1
            if prevFreq != undefined
                modulation = modulation * (1 - smoothing_factor) + (prevFreq / originalFreq - 1) * smoothing_factor
            endif
        endif
        
        # Calculate new frequency
        pitchMultiplier = base_pitch_shift + (modulation * modulation_amount)
        newFreq = originalFreq * pitchMultiplier
        
        # Clamp to reasonable range
        newFreq = max(50, min(1000, newFreq))
        
        # Update pitch tier
        selectObject: pitchTier
        Remove point: i
        Add point: time, newFreq
    endif
endfor

# Apply modified pitch tier
selectObject: manipulation
plus pitchTier
Replace pitch tier

# Generate output
selectObject: manipulation
appendInfoLine: "Synthesizing output..."
if apply_formant_preservation
    output = Get resynthesis (overlap-add)
else
    output = Get resynthesis (PSOLA)
endif

Rename: originalName$ + "_shifted"

# Apply output gain
selectObject: output
Formula: "self * output_gain"

# Add stereo width if requested
selectObject: output
numChannels = Get number of channels
if add_stereo_width and numChannels = 1
    appendInfoLine: "Adding stereo width..."
    stereoOutput = Convert to stereo
    selectObject: stereoOutput
    Formula: "if col = 1 then self * 1.1 else self * 0.9 fi"
    removeObject: output
    output = stereoOutput
endif

# Cleanup intermediate objects
if modulation_source = 2 or modulation_source = 4
    removeObject: pitch
endif
if modulation_source = 1 or modulation_source = 4
    removeObject: intensity
    removeObject: intensityTier
endif
removeObject: manipulation
removeObject: pitchTier

# Play preview or finalize
selectObject: output
if preview_only
    appendInfoLine: "Playing preview..."
    Play
    removeObject: output
    appendInfoLine: "Preview complete. Output not saved."
else
    appendInfoLine: "Processing complete!"
    appendInfoLine: "Output object: ", selected$("Sound")
    Play
endif

appendInfoLine: "Done!"