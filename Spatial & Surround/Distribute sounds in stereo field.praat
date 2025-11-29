# ============================================================
# Praat AudioTools - Distribute sounds in stereo field


# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Distribute sounds in stereo field


# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Distribute selected sounds equally across stereo panorama and mix
# -------------------------------------------------------------

# Get number of selected sounds
numberOfSounds = numberOfSelected("Sound")

if numberOfSounds < 2
    exitScript: "Please select at least 2 Sound objects to create a mix."
endif

# Feedback for user (Formula calculations can be slow)
writeInfoLine: "Mixing ", numberOfSounds, " sounds..."

# Store all sound IDs
for i from 1 to numberOfSounds
    sound[i] = selected("Sound", i)
endfor

# 1. Determine Output Parameters
selectObject: sound[1]
sampleRate = Get sampling frequency
maxDuration = 0

# Find maximum duration across all files
for i from 1 to numberOfSounds
    selectObject: sound[i]
    thisDuration = Get total duration
    if thisDuration > maxDuration
        maxDuration = thisDuration
    endif
endfor

# 2. Create the canvas (Empty Stereo Sound)
selectObject: sound[1]
# We name it based on the first sound, but you can change this
baseName$ = selected$("Sound")
stereoMix = Create Sound from formula: baseName$ + "_mix", 2, 0, maxDuration, sampleRate, "0"

# 3. Process and Mix
for i from 1 to numberOfSounds
    selectObject: sound[i]
    
    # Calculate Pan Position (-1 to +1)
    # Division by zero protection is handled by the initial check < 2
    pan = -1 + (2 * (i - 1) / (numberOfSounds - 1))
    
    # Handle Stereo inputs (fold down to mono before panning)
    nChannels = Get number of channels
    if nChannels > 1
        mono = Convert to mono
    else
        # Copy ensures we don't mess with the original selection
        mono = Copy: "temp_mono"
    endif
    
    # Calculate Constant Power Gains (Sin/Cos or Sqrt approach)
    # Using Sqrt helps keep center consistent with sides
    leftGain = sqrt((1 - pan) / 2)
    rightGain = sqrt((1 + pan) / 2)
    
    # Get duration of this specific sound (to limit formula processing time)
    selectObject: mono
    soundDuration = Get total duration
    
    # Add to LEFT channel
    selectObject: stereoMix
    # We only process up to the sound's duration to save CPU on long mixes
    Formula (part): 0, soundDuration, 1, 1, "self + object[mono] * " + string$(leftGain)
    
    # Add to RIGHT channel
    Formula (part): 0, soundDuration, 2, 2, "self + object[mono] * " + string$(rightGain)
    
    # Clean up temp object
    removeObject: mono
    
    # Update info window
    appendInfoLine: "Processed sound ", i, " at pan position ", fixed$(pan, 2)
endfor

# 4. Finalize
selectObject: stereoMix

# CRITICAL STEP: Prevent Clipping
# Summing signals usually pushes amplitude > 1. We normalize to 0.99
Scale peak: 0.99

appendInfoLine: "Done! Output scaled to 0.99 peak amplitude."
Play