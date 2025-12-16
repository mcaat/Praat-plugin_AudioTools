# ============================================================
# Praat AudioTools - Stockhausen Studie II Generator (10 seconds)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Studie II Generator (10 seconds)
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Studie II Generator (10 seconds)
# =================================

form Studie II Generator
    comment Composition parameters:
    positive duration 10.0
    positive num_groups 7
    comment Generation method:
    optionmenu generation_mode 1
        option Random (varied each time)
        option Serial (pre-composed rows)
    comment Audio settings:
    positive sample_rate 44100
    positive base_frequency 100
    comment Amplitude range (0.0 - 1.0):
    positive min_amplitude 0.10
    positive max_amplitude 0.30
    comment Options:
    boolean draw_score 1
    boolean save_to_file 0
    comment Random seed (0 = different, only for Random mode):
    integer random_seed 0
endform

# Set variables from form
duration = duration
sampleRate = sample_rate
baseHz = base_frequency
minAmp = min_amplitude
maxAmp = max_amplitude
numGroupsTarget = num_groups
doDrawScore = draw_score
doSaveFile = save_to_file
seedValue = random_seed
genMode = generation_mode

# Build frequency scale (81 frequencies)
for i from 1 to 81
    freq_'i' = baseHz * (5 ^ ((i - 1) / 25))
endfor

# Initialize serial rows if using serial mode
if genMode == 2
    # Pitch index row (12 values, cycled)
    pitchRow_1 = 25
    pitchRow_2 = 42
    pitchRow_3 = 18
    pitchRow_4 = 55
    pitchRow_5 = 30
    pitchRow_6 = 48
    pitchRow_7 = 15
    pitchRow_8 = 38
    pitchRow_9 = 52
    pitchRow_10 = 22
    pitchRow_11 = 45
    pitchRow_12 = 35
    
    # Spread factor row (5 values, cycled)
    spreadRow_1 = 3
    spreadRow_2 = 1
    spreadRow_3 = 5
    spreadRow_4 = 2
    spreadRow_5 = 4
    
    # Duration row (normalized 0-1, 8 values)
    durRow_1 = 0.15
    durRow_2 = 0.42
    durRow_3 = 0.22
    durRow_4 = 0.35
    durRow_5 = 0.18
    durRow_6 = 0.48
    durRow_7 = 0.28
    durRow_8 = 0.38
    
    # Amplitude row (normalized 0-1, 6 values)
    ampRow_1 = 0.3
    ampRow_2 = 0.6
    ampRow_3 = 0.45
    ampRow_4 = 0.75
    ampRow_5 = 0.5
    ampRow_6 = 0.65
    
    # Envelope type row (6 values)
    envRow_1 = 1
    envRow_2 = 4
    envRow_3 = 2
    envRow_4 = 6
    envRow_5 = 3
    envRow_6 = 5
    
    # Group type row (alternating pattern)
    groupTypeRow_1 = 0
    groupTypeRow_2 = 1
    groupTypeRow_3 = 0
    groupTypeRow_4 = 1
    groupTypeRow_5 = 1
    groupTypeRow_6 = 0
    
    # Initialize row indices
    pitchRowIdx = 1
    spreadRowIdx = 1
    durRowIdx = 1
    ampRowIdx = 1
    envRowIdx = 1
    groupTypeRowIdx = 1
endif

# Create master timeline
Create Sound from formula: "master", 1, 0, duration, sampleRate, "0"
master = selected("Sound")

# Event storage for score drawing
numStoredEvents = 0

# Generate events
currentTime = 0
numGroups = numGroupsTarget

for iGroup from 1 to numGroups
    if currentTime >= duration - 0.05
        goto DONE_GENERATION
    endif
    
    # Determine group type
    if genMode == 2
        groupType = groupTypeRow_'groupTypeRowIdx'
        groupTypeRowIdx = groupTypeRowIdx + 1
        if groupTypeRowIdx > 6
            groupTypeRowIdx = 1
        endif
    else
        groupType = randomInteger(0, 1)
    endif
    
    # Determine number of events
    if genMode == 2
        numEvents = (iGroup mod 4) + 1
    else
        numEvents = randomInteger(1, 5)
    endif
    
    if groupType == 0
        # Horizontal: sequential
        for iEv from 1 to numEvents
            if currentTime >= duration - 0.05
                goto DONE_GENERATION
            endif
            
            # Get parameters from serial rows or random
            if genMode == 2
                spreadFactor = spreadRow_'spreadRowIdx'
                spreadRowIdx = spreadRowIdx + 1
                if spreadRowIdx > 5
                    spreadRowIdx = 1
                endif
                
                startIdx = pitchRow_'pitchRowIdx'
                pitchRowIdx = pitchRowIdx + 1
                if pitchRowIdx > 12
                    pitchRowIdx = 1
                endif
                
                durNorm = durRow_'durRowIdx'
                durRowIdx = durRowIdx + 1
                if durRowIdx > 8
                    durRowIdx = 1
                endif
                evDur = 0.08 + durNorm * 0.37
                
                ampNorm = ampRow_'ampRowIdx'
                ampRowIdx = ampRowIdx + 1
                if ampRowIdx > 6
                    ampRowIdx = 1
                endif
                evAmp = minAmp + ampNorm * (maxAmp - minAmp)
                
                envType = envRow_'envRowIdx'
                envRowIdx = envRowIdx + 1
                if envRowIdx > 6
                    envRowIdx = 1
                endif
            else
                spreadFactor = randomInteger(1, 5)
                startIdx = randomInteger(10, 65 - 4 * spreadFactor)
                evDur = randomUniform(0.08, 0.45)
                evAmp = randomUniform(minAmp, maxAmp)
                envType = randomInteger(1, 6)
            endif
            
            if currentTime + evDur > duration
                evDur = duration - currentTime
            endif
            
            # Store event for drawing
            if doDrawScore
                numStoredEvents = numStoredEvents + 1
                eventStart_'numStoredEvents' = currentTime
                eventDur_'numStoredEvents' = evDur
                eventIdx1_'numStoredEvents' = startIdx
                eventIdx2_'numStoredEvents' = startIdx + spreadFactor
                eventIdx3_'numStoredEvents' = startIdx + 2 * spreadFactor
                eventIdx4_'numStoredEvents' = startIdx + 3 * spreadFactor
                eventIdx5_'numStoredEvents' = startIdx + 4 * spreadFactor
            endif
            
            # Make mixture
            mixtureCreated = 0
            for comp from 0 to 4
                idx = startIdx + comp * spreadFactor
                if idx < 1
                    idx = 1
                elsif idx > 81
                    idx = 81
                endif
                
                frequency = freq_'idx'
                centerWeight = 1.0 - abs(comp - 2) * 0.12
                compAmp = evAmp * centerWeight
                
                Create Sound from formula: "component", 1, 0, evDur, sampleRate,
                    ... string$(compAmp) + " * sin(2 * pi * " + string$(frequency) + " * x)"
                compObj = selected("Sound")
                
                # Apply envelope
                if envType == 1
                    att = 0.025
                    rel = 0.018
                    Fade in: 0, 0, att, "yes"
                    Fade out: 0, evDur - rel, rel, "yes"
                elsif envType == 2
                    rampEnd = evDur * 0.72
                    Formula: "self * min(1, x / " + string$(rampEnd) + ")"
                    Fade out: 0, evDur - 0.01, 0.01, "yes"
                elsif envType == 3
                    tau = evDur / 2.8
                    Formula: "self * exp(-x / " + string$(tau) + ")"
                    Fade in: 0, 0, 0.004, "yes"
                elsif envType == 4
                    peak = evDur / 2
                    Formula: "self * (1 - abs(x - " + string$(peak) + ") / " + string$(peak) + ")"
                elsif envType == 5
                    Fade in: 0, 0, 0.003, "yes"
                    Fade out: 0, evDur - 0.006, 0.006, "yes"
                else
                    att = evDur * 0.18
                    rel = evDur * 0.22
                    Fade in: 0, 0, att, "yes"
                    Fade out: 0, evDur - rel, rel, "yes"
                endif
                
                if mixtureCreated == 0
                    Rename: "mixture_result"
                    mixtureObj = selected("Sound")
                    mixtureCreated = 1
                else
                    selectObject: mixtureObj
                    Formula: "self + Sound_component[col]"
                    removeObject: compObj
                endif
            endfor
            
            # Add to master
            selectObject: mixtureObj
            evDuration = Get total duration
            
            selectObject: master
            Formula: "self + Sound_mixture_result[col - round(" + string$(currentTime) + " * " + string$(sampleRate) + ")]"
            
            removeObject: mixtureObj
            
            # Calculate gap
            if genMode == 2
                gapDur = 0.01 + (durRowIdx mod 5) * 0.01
            else
                gapDur = randomUniform(0.005, 0.06)
            endif
            
            currentTime = currentTime + evDur + gapDur
        endfor
        
        # Add silence between groups
        if genMode == 2
            silenceDur = 0.05 + (groupTypeRowIdx mod 4) * 0.05
        else
            if randomUniform(0, 1) > 0.4
                silenceDur = randomUniform(0.03, 0.25)
            else
                silenceDur = 0
            endif
        endif
        currentTime = currentTime + silenceDur
        
    else
        # Vertical: overlapping
        groupStart = currentTime
        
        if genMode == 2
            groupLen = 0.25 + (durRowIdx mod 4) * 0.15
        else
            groupLen = randomUniform(0.25, 0.7)
        endif
        
        for iEv from 1 to numEvents
            if groupStart >= duration - 0.05
                goto SKIP_VERTICAL
            endif
            
            # Get parameters
            if genMode == 2
                spreadFactor = spreadRow_'spreadRowIdx'
                spreadRowIdx = spreadRowIdx + 1
                if spreadRowIdx > 5
                    spreadRowIdx = 1
                endif
                
                startIdx = pitchRow_'pitchRowIdx'
                pitchRowIdx = pitchRowIdx + 1
                if pitchRowIdx > 12
                    pitchRowIdx = 1
                endif
                
                durNorm = durRow_'durRowIdx'
                durRowIdx = durRowIdx + 1
                if durRowIdx > 8
                    durRowIdx = 1
                endif
                evDur = groupLen * (0.6 + durNorm * 0.7)
                
                evStart = groupStart + (iEv - 1) * groupLen * 0.15
                
                ampNorm = ampRow_'ampRowIdx'
                ampRowIdx = ampRowIdx + 1
                if ampRowIdx > 6
                    ampRowIdx = 1
                endif
                evAmp = minAmp + ampNorm * (maxAmp - minAmp)
                
                envType = envRow_'envRowIdx'
                envRowIdx = envRowIdx + 1
                if envRowIdx > 6
                    envRowIdx = 1
                endif
            else
                spreadFactor = randomInteger(1, 5)
                startIdx = randomInteger(10, 65 - 4 * spreadFactor)
                evDur = randomUniform(groupLen * 0.6, groupLen * 1.3)
                evStart = groupStart + randomUniform(0, groupLen * 0.25)
                evAmp = randomUniform(minAmp, maxAmp)
                envType = randomInteger(1, 6)
            endif
            
            if evStart + evDur > duration
                evDur = duration - evStart
            endif
            
            if evDur < 0.03
                goto SKIP_VERTICAL_EVENT
            endif
            
            # Store event for drawing
            if doDrawScore
                numStoredEvents = numStoredEvents + 1
                eventStart_'numStoredEvents' = evStart
                eventDur_'numStoredEvents' = evDur
                eventIdx1_'numStoredEvents' = startIdx
                eventIdx2_'numStoredEvents' = startIdx + spreadFactor
                eventIdx3_'numStoredEvents' = startIdx + 2 * spreadFactor
                eventIdx4_'numStoredEvents' = startIdx + 3 * spreadFactor
                eventIdx5_'numStoredEvents' = startIdx + 4 * spreadFactor
            endif
            
            # Make mixture
            mixtureCreated = 0
            for comp from 0 to 4
                idx = startIdx + comp * spreadFactor
                if idx < 1
                    idx = 1
                elsif idx > 81
                    idx = 81
                endif
                
                frequency = freq_'idx'
                centerWeight = 1.0 - abs(comp - 2) * 0.12
                compAmp = evAmp * centerWeight
                
                Create Sound from formula: "component", 1, 0, evDur, sampleRate,
                    ... string$(compAmp) + " * sin(2 * pi * " + string$(frequency) + " * x)"
                compObj = selected("Sound")
                
                # Apply envelope
                if envType == 1
                    att = 0.025
                    rel = 0.018
                    Fade in: 0, 0, att, "yes"
                    Fade out: 0, evDur - rel, rel, "yes"
                elsif envType == 2
                    rampEnd = evDur * 0.72
                    Formula: "self * min(1, x / " + string$(rampEnd) + ")"
                    Fade out: 0, evDur - 0.01, 0.01, "yes"
                elsif envType == 3
                    tau = evDur / 2.8
                    Formula: "self * exp(-x / " + string$(tau) + ")"
                    Fade in: 0, 0, 0.004, "yes"
                elsif envType == 4
                    peak = evDur / 2
                    Formula: "self * (1 - abs(x - " + string$(peak) + ") / " + string$(peak) + ")"
                elsif envType == 5
                    Fade in: 0, 0, 0.003, "yes"
                    Fade out: 0, evDur - 0.006, 0.006, "yes"
                else
                    att = evDur * 0.18
                    rel = evDur * 0.22
                    Fade in: 0, 0, att, "yes"
                    Fade out: 0, evDur - rel, rel, "yes"
                endif
                
                if mixtureCreated == 0
                    Rename: "mixture_result"
                    mixtureObj = selected("Sound")
                    mixtureCreated = 1
                else
                    selectObject: mixtureObj
                    Formula: "self + Sound_component[col]"
                    removeObject: compObj
                endif
            endfor
            
            # Add to master
            selectObject: master
            Formula: "self + Sound_mixture_result[col - round(" + string$(evStart) + " * " + string$(sampleRate) + ")]"
            
            removeObject: mixtureObj
            
            label SKIP_VERTICAL_EVENT
        endfor
        
        label SKIP_VERTICAL
        
        if genMode == 2
            gapAfter = 0.02 + (groupTypeRowIdx mod 3) * 0.03
        else
            gapAfter = randomUniform(0.01, 0.12)
        endif
        
        currentTime = groupStart + groupLen + gapAfter
    endif
endfor

label DONE_GENERATION

# Apply light echo/reverb
selectObject: master
Copy: "dry"
dryObj = selected("Sound")

selectObject: master
Formula: "self * 0.85"

for iTap from 1 to 3
    selectObject: dryObj
    Copy: "tap"
    tapObj = selected("Sound")
    
    delayTime = 0.023 + iTap * 0.017
    decayAmt = 0.65 ^ iTap * 0.12
    
    Formula: "self[col - round(" + string$(delayTime) + " * " + string$(sampleRate) + ")] * " + string$(decayAmt)
    
    selectObject: master
    Formula: "self + Sound_tap[col]"
    
    removeObject: tapObj
endfor

removeObject: dryObj

# Normalize
selectObject: master
Rename: "studieII_10s"
Scale peak: 0.97

# Save to file if requested
if doSaveFile
    if genMode == 2
        modeLabel$ = "serial"
    else
        modeLabel$ = "random"
    endif
    timestamp$ = string$(round(randomUniform(100000, 999999)))
    filename$ = "studieII_" + modeLabel$ + "_" + string$(duration) + "s_" + timestamp$ + ".wav"
    Save as WAV file: filename$
    writeInfoLine: "Saved to: ", filename$
endif

# Draw Stockhausen-style score if requested
if doDrawScore
    Erase all
    Select outer viewport: 0, 10, 0, 6
    Black
    Line width: 1
    Font size: 11
    
    # Draw frame and axes
    Axes: 0, duration, 1, 81
    Draw inner box
    Marks left every: 1, 10, "yes", "yes", "no"
    Marks bottom every: 1, 1, "yes", "yes", "no"
    Text left: "yes", "Pitch Index (Studie II Scale)"
    Text bottom: "yes", "Time (seconds)"
    
    if genMode == 2
        Text top: "no", "STUDIE II (quasi-realization) - SERIAL MODE"
    else
        Text top: "no", "STUDIE II (quasi-realization) - RANDOM MODE"
    endif
    
    # Draw light grid
    Grey
    Line width: 0.25
    for t from 1 to duration - 1
        Draw line: t, 1, t, 81
    endfor
    for p from 1 to 8
        pitchLine = p * 10
        Draw line: 0, pitchLine, duration, pitchLine
    endfor
    
    # Draw events as tone-mixture blocks
    for iEv from 1 to numStoredEvents
        evStart = eventStart_'iEv'
        evDur = eventDur_'iEv'
        evEnd = evStart + evDur
        
        idx1 = eventIdx1_'iEv'
        idx2 = eventIdx2_'iEv'
        idx3 = eventIdx3_'iEv'
        idx4 = eventIdx4_'iEv'
        idx5 = eventIdx5_'iEv'
        
        # Clamp indices to range
        if idx1 > 81
            idx1 = 81
        endif
        if idx2 > 81
            idx2 = 81
        endif
        if idx3 > 81
            idx3 = 81
        endif
        if idx4 > 81
            idx4 = 81
        endif
        if idx5 > 81
            idx5 = 81
        endif
        
        minIdx = idx1
        maxIdx = idx5
        
        # Paint rectangle (grey fill)
        Grey
        Paint rectangle: "Grey", evStart, evEnd, minIdx - 0.4, maxIdx + 0.4
        
        # Draw the 5 component lines (Tongemisch)
        Black
        Line width: 1.5
        Draw line: evStart, idx1, evEnd, idx1
        Draw line: evStart, idx2, evEnd, idx2
        Draw line: evStart, idx3, evEnd, idx3
        Draw line: evStart, idx4, evEnd, idx4
        Draw line: evStart, idx5, evEnd, idx5
        
        # Draw bounding box
        Line width: 2
        Draw rectangle: evStart, evEnd, minIdx - 0.4, maxIdx + 0.4
    endfor
    
    # Final outer frame
    Black
    Line width: 2.5
    Draw inner box
endif

# Select sound for listening
selectObject: master
Play