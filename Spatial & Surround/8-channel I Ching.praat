# ============================================================
# Praat AudioTools - 8-channel I Ching
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   8-channel I Ching: Form & Speed
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
# 8-channel I Ching: Form & Speed
# COMBINED VERSION
#
# 1. SLICES audio based on Hexagram lines (Yin = Reverse).
# 2. CONCATENATES slices to form a new structure.
# 3. Applies SPEED deviation based on Hexagram value.
# 4. Do this 8 times for 8 spatial channels.
# ============================================================

form 8-channel I Ching Form & Speed
    comment I Ching Configuration
    positive Deviation_range_(+/-) 0.20
    comment Random seed (0 = truly random)
    integer Random_seed 0
    
    comment Audio Settings
    boolean Override_sampling_frequency 1
    positive Target_sampling_frequency 44100
endform

# --- SETUP ---
if numberOfSelected("Sound") = 0
    exitScript: "Please select a sound object first."
endif

if random_seed > 0
    randomNumber = random_seed
endif

originalSound = selected("Sound")
originalName$ = selected$("Sound")
original_freq = Get sampling frequency
original_dur = Get total duration

# Setup Picture Window
Erase all
Select outer viewport: 0, 12, 0, 8
Axes: 0, 10, 0, 10
Font size: 14
Text: 5, "centre", 9.5, "half", "8-CHANNEL I CHING: FORM & SPEED"
Font size: 10

# --- MAIN LOOP (8 CHANNELS) ---
for ch from 1 to 8
    
    # 1. GENERATE HEXAGRAM
    l1 = randomInteger(0, 1)
    l2 = randomInteger(0, 1)
    l3 = randomInteger(0, 1)
    l4 = randomInteger(0, 1)
    l5 = randomInteger(0, 1)
    l6 = randomInteger(0, 1)

    # Calculate Values
    hex_value = l1 + (l2*2) + (l3*4) + (l4*8) + (l5*16) + (l6*32)
    normalized_hex = hex_value / 63
    speed_factor = 1.0 + ((normalized_hex * (deviation_range * 2)) - deviation_range)

    # 2. DRAWING (Grid Layout)
    if ch <= 4
        xCenter = 1.5 + (ch-1)*2.3
        yBase = 5.5
    else
        xCenter = 1.5 + (ch-5)*2.3
        yBase = 1.5
    endif
    
    Colour: "Black"
    Text: xCenter, "centre", yBase - 0.5, "half", "Ch " + string$(ch) + " (" + fixed$(speed_factor, 2) + "x)"
    
    Line width: 3
    for k from 1 to 6
        lineY = yBase + (k-1)*0.4
        # Get line value safely
        if k=1
             val=l1 
        elsif k=2
             val=l2 
        elsif k=3
             val=l3 
        elsif k=4
             val=l4 
        elsif k=5
             val=l5 
        else
             val=l6
        endif
        
        if val = 1
            Draw line: xCenter-0.8, lineY, xCenter+0.8, lineY
        else
            Draw line: xCenter-0.8, lineY, xCenter-0.15, lineY
            Draw line: xCenter+0.15, lineY, xCenter+0.8, lineY
        endif
    endfor
    Line width: 1

    # 3. SLICING & RECOMBINATION (Inner Loop)
    # We create the "Form" first, then change the "Speed"
    
    selectObject: originalSound
    sliceDuration = original_dur / 6
    validSliceCount = 0
    
    for s from 1 to 6
        # Determine line value for this slice
        if s=1
             sVal=l1 
        elsif s=2
             sVal=l2 
        elsif s=3
             sVal=l3 
        elsif s=4
             sVal=l4 
        elsif s=5
             sVal=l5 
        else
             sVal=l6
        endif
        
        # Extract Slice
        startTime = (s - 1) * sliceDuration
        endTime = s * sliceDuration
        if endTime > original_dur
            endTime = original_dur
        endif
        
        if endTime - startTime > 0.001
            selectObject: originalSound
            Extract part: startTime, endTime, "rectangular", 1.0, "no"
            currentSliceID = selected("Sound")
            
            # REVERSE IF YIN
            if sVal = 0
                Reverse
            endif
            
            # Store ID
            validSliceCount += 1
            sliceID_[validSliceCount] = selected("Sound")
        endif
    endfor
    
    # Concatenate Slices
    if validSliceCount > 0
        selectObject: sliceID_[1]
        for k from 2 to validSliceCount
            plusObject: sliceID_[k]
        endfor
        
        Concatenate
        recombinedSound = selected("Sound")
        
        # Cleanup Slices immediately
        selectObject: sliceID_[1]
        for k from 2 to validSliceCount
            plusObject: sliceID_[k]
        endfor
        Remove
    else
        # Fallback if slicing failed (rare)
        selectObject: originalSound
        Copy: "fallback"
        recombinedSound = selected("Sound")
    endif

    # 4. SPEED DEVIATION & FINALIZATION
    selectObject: recombinedSound
    
    # Force Mono (needed for overlap-add)
    nChans = Get number of channels
    if nChans > 1
        Convert to mono
        removeObject: recombinedSound
        recombinedSound = selected("Sound")
    endif
    
    # Apply Speed (Lengthen)
    # Note: Because we sliced it first, the duration might be slightly different due to concatenation,
    # but we base speed on the *original* intended duration.
    dur_current = Get total duration
    min_pitch = 75
    max_pitch = 600
    
    # Target duration is based on the speed factor
    target_dur = dur_current / speed_factor
    
    Lengthen (overlap-add): min_pitch, max_pitch, target_dur/dur_current
    
    removeObject: recombinedSound
    speedSound = selected("Sound")
    
    # Resample
    if override_sampling_frequency
        Resample: target_sampling_frequency, 50
    else
        Resample: original_freq, 50
    endif
    
    removeObject: speedSound
    final_channels[ch] = selected("Sound")
    Rename: "Ch" + string$(ch)

endfor

# --- COMBINE 8 CHANNELS ---
selectObject: final_channels[1]
for i from 2 to 8
    plusObject: final_channels[i]
endfor

Combine to stereo
Rename: originalName$ + "_8ch_IChing_FormSpeed"
finalID = selected("Sound")

# Cleanup Channels
for i from 1 to 8
    removeObject: final_channels[i]
endfor

# Play
selectObject: finalID
Play