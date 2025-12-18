# ============================================================
# Praat AudioTools - Percussive Audio Groove Creator
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Detects bass drums, hi-hats, and snares from audio and creates groove patterns
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Percussive Groove Pattern Creator
# Detects bass drums, hi-hats, and snares from audio and creates groove patterns

form Percussive Groove Pattern Creator
    comment Input file is already selected
    optionmenu Pattern_length: 3
        option 1 bar
        option 2 bars
        option 4 bars
    optionmenu Beat_pattern: 1
        option Standard 4/4
        option Syncopated Funk
        option Breakbeat
        option Half-time Feel
        option Double-time Feel
        option Sparse Minimal
    real Tempo_(BPM) 120
    comment Detection parameters
    real Onset_threshold_(dB) -20
    positive Min_silence_between_events_(s) 0.05
    positive Max_segment_duration_(s) 0.15
    comment Groove settings
    real Groove_density_(0-1) 0.6
    positive Clip_max_length_(s) 0.12
    comment Dynamic shaping
    positive Attack_time_(s) 0.002
    positive Release_time_(s) 0.05
    real Shape_intensity 1.2
    boolean Create_stereo 1
endform

# Get the selected sound
sound = selected("Sound")
soundName$ = selected$("Sound")
duration = Get total duration
sampleRate = Get sampling frequency
numChannels = Get number of channels

writeInfoLine: "=== Percussive Groove Pattern Creator ==="
appendInfoLine: "Analyzing: ", soundName$
appendInfoLine: "Duration: ", fixed$(duration, 2), "s"
appendInfoLine: ""

# Convert to mono if needed
if numChannels > 1
    selectObject: sound
    soundMono = Convert to mono
    appendInfoLine: "Converted to mono for analysis"
else
    soundMono = sound
endif

# Create intensity for onset detection
selectObject: soundMono
intensity = To Intensity: 70, 0, "yes"
intensityTier = Down to IntensityTier

# Detect onset peaks
selectObject: intensity
intensityMatrix = Down to Matrix
selectObject: intensityMatrix
numberOfFrames = Get number of columns
timeStep = Get column distance

# Storage arrays
maxEvents = 500
numberOfEvents = 0
lastEventTime = -1

# Scan for percussive onsets
appendInfoLine: "Detecting percussive events..."

for frame from 3 to numberOfFrames - 2
    selectObject: intensityMatrix
    time = Get x of column: frame
    
    if time > 0.02 and time < duration - 0.05
        if time - lastEventTime > min_silence_between_events
            currentValue = Get value in cell: 1, frame
            prevValue1 = Get value in cell: 1, frame - 1
            prevValue2 = Get value in cell: 1, frame - 2
            nextValue1 = Get value in cell: 1, frame + 1
            
            # Detect sharp peak (onset)
            if currentValue > prevValue1 and currentValue > prevValue2 
                ...and currentValue > nextValue1
                if currentValue > onset_threshold
                    # Extract segment
                    segmentStart = max(0, time - 0.005)
                    segmentEnd = min(duration, time + max_segment_duration)
                    
                    selectObject: soundMono
                    segment = Extract part: segmentStart, segmentEnd, "rectangular", 1, "no"
                    segDur = Get total duration
                    
                    # Skip if too short
                    if segDur > 0.015
                        # Analyze frequency content
                        spectrum = To Spectrum: "yes"
                        
                        # Energy in frequency bands
                        lowEnergy = Get band energy: 20, 250
                        midEnergy = Get band energy: 250, 4000
                        highEnergy = Get band energy: 4000, 18000
                        
                        totalEnergy = lowEnergy + midEnergy + highEnergy
                        
                        # Classify based on spectral content
                        eventType = 0
                        if totalEnergy > 0
                            lowRatio = lowEnergy / totalEnergy
                            midRatio = midEnergy / totalEnergy
                            highRatio = highEnergy / totalEnergy
                            
                            # Bass drum: dominant low frequencies
                            if lowRatio > 0.55
                                eventType = 1
                            # Hi-hat: dominant high frequencies
                            elsif highRatio > 0.35
                                eventType = 2
                            # Snare: mid frequencies with spread
                            elsif midRatio > 0.4
                                eventType = 3
                            endif
                        endif
                        
                        removeObject: spectrum
                        
                        if eventType > 0 and numberOfEvents < maxEvents
                            numberOfEvents += 1
                            eventTime'numberOfEvents' = time
                            eventType'numberOfEvents' = eventType
                            eventSound'numberOfEvents' = segment
                            lastEventTime = time
                            
                            # Determine type name
                            if eventType = 1
                                type$ = "BASS"
                            elsif eventType = 2
                                type$ = "HH"
                            else
                                type$ = "SNARE"
                            endif
                            
                            appendInfoLine: tab$, "#", numberOfEvents, ": ", 
                                ...type$, " at ", fixed$(time, 3), "s"
                        else
                            removeObject: segment
                        endif
                    else
                        removeObject: segment
                    endif
                endif
            endif
        endif
    endif
endfor

removeObject: intensity, intensityMatrix, intensityTier
if numChannels > 1
    removeObject: soundMono
endif

if numberOfEvents = 0
    exitScript: "No percussive events detected.", newline$, 
        ..."Try lowering the onset threshold."
endif

appendInfoLine: "", "Total detected: ", numberOfEvents, " events"

# Organize by type
numBass = 0
numHH = 0
numSnare = 0

for i to numberOfEvents
    if eventType'i' = 1
        numBass += 1
        bassDrums'numBass' = eventSound'i'
    elsif eventType'i' = 2
        numHH += 1
        hiHats'numHH' = eventSound'i'
    elsif eventType'i' = 3
        numSnare += 1
        snares'numSnare' = eventSound'i'
    endif
endfor

appendInfoLine: "  → Bass drums: ", numBass
appendInfoLine: "  → Hi-hats: ", numHH
appendInfoLine: "  → Snares: ", numSnare
appendInfoLine: ""

if numBass = 0 or numHH = 0 or numSnare = 0
    appendInfoLine: "WARNING: Not all types detected."
    appendInfoLine: "The pattern will use available types only."
endif

# Calculate pattern parameters
if pattern_length = 1
    bars = 1
elsif pattern_length = 2
    bars = 2
else
    bars = 4
endif

beatDuration = 60.0 / tempo
patternDuration = bars * 4 * beatDuration
sixteenthDur = beatDuration / 4

appendInfoLine: "Creating ", bars, "-bar groove at ", tempo, " BPM..."
appendInfoLine: "Beat pattern: ", beat_pattern$
appendInfoLine: "Pattern duration: ", fixed$(patternDuration, 2), "s"
appendInfoLine: "Groove density: ", fixed$(groove_density, 2)
appendInfoLine: ""

# Generate mono pattern (will be used for left or mono)
pattern_left = Create Sound from formula: "pattern", 1, 0, patternDuration, 
    ...sampleRate, "0"

# Indices for cycling through detected sounds
bassIdx = 1
hhIdx = 1
snareIdx = 1
hitsPlaced = 0

for beat from 1 to bars * 4
    beatStart = (beat - 1) * beatDuration
    
    for sixteenth from 1 to 4
        position = beatStart + (sixteenth - 1) * sixteenthDur
        
        placeType = 0
        probability = randomUniform(0, 1)
        
        # Different beat patterns
        if beat_pattern = 1
            # Standard 4/4
            if (beat - 1) mod 4 = 0 and sixteenth = 1
                placeType = 1
            elsif (beat - 1) mod 4 = 2 and sixteenth = 1
                if probability < groove_density
                    placeType = 1
                endif
            elsif ((beat - 1) mod 4 = 1 or (beat - 1) mod 4 = 3) and sixteenth = 1
                if probability < groove_density + 0.2
                    placeType = 3
                endif
            elsif sixteenth = 1 or sixteenth = 3
                if probability < groove_density * 0.8
                    placeType = 2
                endif
            elsif probability < groove_density * 0.3
                placeType = 2
            endif
        elsif beat_pattern = 2
            # Syncopated Funk
            if (beat - 1) mod 4 = 0 and sixteenth = 1
                placeType = 1
            elsif (beat - 1) mod 4 = 1 and sixteenth = 4
                if probability < groove_density
                    placeType = 1
                endif
            elsif (beat - 1) mod 4 = 2 and sixteenth = 3
                if probability < groove_density
                    placeType = 1
                endif
            elsif ((beat - 1) mod 4 = 1 or (beat - 1) mod 4 = 3) and sixteenth = 1
                if probability < groove_density + 0.2
                    placeType = 3
                endif
            elsif probability < groove_density * 0.9
                placeType = 2
            endif
        elsif beat_pattern = 3
            # Breakbeat
            if (beat - 1) mod 4 = 0 and sixteenth = 1
                placeType = 1
            elsif (beat - 1) mod 4 = 0 and sixteenth = 3
                if probability < groove_density * 0.6
                    placeType = 1
                endif
            elsif (beat - 1) mod 4 = 2 and (sixteenth = 1 or sixteenth = 4)
                if probability < groove_density
                    placeType = 1
                endif
            elsif (beat - 1) mod 4 = 1 and sixteenth = 1
                placeType = 3
            elsif (beat - 1) mod 4 = 3 and (sixteenth = 1 or sixteenth = 3)
                if probability < groove_density
                    placeType = 3
                endif
            elsif probability < groove_density * 0.7
                placeType = 2
            endif
        elsif beat_pattern = 4
            # Half-time Feel
            if (beat - 1) mod 8 = 0 and sixteenth = 1
                placeType = 1
            elsif (beat - 1) mod 8 = 4 and sixteenth = 1
                if probability < groove_density
                    placeType = 3
                endif
            elsif sixteenth = 1
                if probability < groove_density * 0.6
                    placeType = 2
                endif
            endif
        elsif beat_pattern = 5
            # Double-time Feel
            if sixteenth = 1 or sixteenth = 3
                if probability < groove_density
                    placeType = 1
                endif
            elsif (sixteenth = 2 or sixteenth = 4)
                if probability < groove_density * 0.8
                    placeType = 3
                endif
            elsif probability < groove_density
                placeType = 2
            endif
        elsif beat_pattern = 6
            # Sparse Minimal
            if (beat - 1) mod 4 = 0 and sixteenth = 1
                placeType = 1
            elsif (beat - 1) mod 4 = 2 and sixteenth = 1
                if probability < 0.3
                    placeType = 1
                endif
            elsif (beat - 1) mod 4 = 1 and sixteenth = 1
                if probability < groove_density * 0.5
                    placeType = 3
                endif
            elsif (beat - 1) mod 2 = 0 and sixteenth = 1
                if probability < groove_density * 0.4
                    placeType = 2
                endif
            endif
        endif
        
        # Place sound if type available
        if placeType > 0
            soundToUse = 0
            
            if placeType = 1 and numBass > 0
                selectObject: bassDrums'bassIdx'
                soundToUse = Copy: "temp"
                bassIdx = (bassIdx mod numBass) + 1
            elsif placeType = 2 and numHH > 0
                selectObject: hiHats'hhIdx'
                soundToUse = Copy: "temp"
                hhIdx = (hhIdx mod numHH) + 1
            elsif placeType = 3 and numSnare > 0
                selectObject: snares'snareIdx'
                soundToUse = Copy: "temp"
                snareIdx = (snareIdx mod numSnare) + 1
            endif
            
            if soundToUse > 0
                hitsPlaced += 1
                
                selectObject: soundToUse
                soundDur = Get total duration
                
                if soundDur > clip_max_length
                    Extract part: 0, clip_max_length, "rectangular", 1, "no"
                    shortened = selected("Sound")
                    removeObject: soundToUse
                    soundToUse = shortened
                    soundDur = clip_max_length
                endif
                
                envelope = Create Sound from formula: "env", 1, 0, soundDur, 
                    ...sampleRate, ~ if x < attack_time then 
                    ...(x/attack_time)^(1/shape_intensity) 
                    ...else if x > soundDur - release_time then 
                    ...((soundDur - x)/release_time)^shape_intensity 
                    ...else 1 fi fi
                
                selectObject: soundToUse
                Formula: ~ self * object[envelope]
                removeObject: envelope
                
                Scale peak: 0.7
                velocity = 0.6 + randomUniform(0, 0.4)
                Formula: ~ self * velocity
                
                maxLen = patternDuration - position
                if maxLen <= 0
                    removeObject: soundToUse
                    soundToUse = 0
                endif
                
                if soundToUse > 0
                    if soundDur > maxLen
                        selectObject: soundToUse
                        Extract part: 0, maxLen, "rectangular", 1, "no"
                        trimmed = selected("Sound")
                        removeObject: soundToUse
                        soundToUse = trimmed
                        soundDur = maxLen
                    endif
                    
                    selectObject: soundToUse
                    soundMatrix = Down to Matrix
                    nCols = Get number of columns
                    
                    selectObject: pattern_left
                    positionSamples = round(position * sampleRate)
                    
                    Formula: ~ if col >= positionSamples + 1 and col <= positionSamples + nCols 
                        ...then self + object[soundMatrix, 1, col - positionSamples] 
                        ...else self fi
                    
                    removeObject: soundMatrix, soundToUse
                endif
            endif
        endif
    endfor
endfor

appendInfoLine: "Left channel: ", hitsPlaced, " hits placed"

# Create stereo if requested
if create_stereo
    appendInfoLine: ""
    appendInfoLine: "Creating right channel variation..."
    
    # Generate right channel with different randomization
    pattern_right = Create Sound from formula: "pattern", 1, 0, patternDuration, 
        ...sampleRate, "0"
    
    bassIdx = 1
    hhIdx = 1
    snareIdx = 1
    hitsPlacedR = 0
    
    for beat from 1 to bars * 4
        beatStart = (beat - 1) * beatDuration
        
        for sixteenth from 1 to 4
            position = beatStart + (sixteenth - 1) * sixteenthDur
            
            placeType = 0
            probability = randomUniform(0, 1)
            
            # Use same beat pattern logic
            if beat_pattern = 1
                if (beat - 1) mod 4 = 0 and sixteenth = 1
                    placeType = 1
                elsif (beat - 1) mod 4 = 2 and sixteenth = 1
                    if probability < groove_density
                        placeType = 1
                    endif
                elsif ((beat - 1) mod 4 = 1 or (beat - 1) mod 4 = 3) and sixteenth = 1
                    if probability < groove_density + 0.2
                        placeType = 3
                    endif
                elsif sixteenth = 1 or sixteenth = 3
                    if probability < groove_density * 0.8
                        placeType = 2
                    endif
                elsif probability < groove_density * 0.3
                    placeType = 2
                endif
            elsif beat_pattern = 2
                if (beat - 1) mod 4 = 0 and sixteenth = 1
                    placeType = 1
                elsif (beat - 1) mod 4 = 1 and sixteenth = 4
                    if probability < groove_density
                        placeType = 1
                    endif
                elsif (beat - 1) mod 4 = 2 and sixteenth = 3
                    if probability < groove_density
                        placeType = 1
                    endif
                elsif ((beat - 1) mod 4 = 1 or (beat - 1) mod 4 = 3) and sixteenth = 1
                    if probability < groove_density + 0.2
                        placeType = 3
                    endif
                elsif probability < groove_density * 0.9
                    placeType = 2
                endif
            elsif beat_pattern = 3
                if (beat - 1) mod 4 = 0 and sixteenth = 1
                    placeType = 1
                elsif (beat - 1) mod 4 = 0 and sixteenth = 3
                    if probability < groove_density * 0.6
                        placeType = 1
                    endif
                elsif (beat - 1) mod 4 = 2 and (sixteenth = 1 or sixteenth = 4)
                    if probability < groove_density
                        placeType = 1
                    endif
                elsif (beat - 1) mod 4 = 1 and sixteenth = 1
                    placeType = 3
                elsif (beat - 1) mod 4 = 3 and (sixteenth = 1 or sixteenth = 3)
                    if probability < groove_density
                        placeType = 3
                    endif
                elsif probability < groove_density * 0.7
                    placeType = 2
                endif
            elsif beat_pattern = 4
                if (beat - 1) mod 8 = 0 and sixteenth = 1
                    placeType = 1
                elsif (beat - 1) mod 8 = 4 and sixteenth = 1
                    if probability < groove_density
                        placeType = 3
                    endif
                elsif sixteenth = 1
                    if probability < groove_density * 0.6
                        placeType = 2
                    endif
                endif
            elsif beat_pattern = 5
                if sixteenth = 1 or sixteenth = 3
                    if probability < groove_density
                        placeType = 1
                    endif
                elsif (sixteenth = 2 or sixteenth = 4)
                    if probability < groove_density * 0.8
                        placeType = 3
                    endif
                elsif probability < groove_density
                    placeType = 2
                endif
            elsif beat_pattern = 6
                if (beat - 1) mod 4 = 0 and sixteenth = 1
                    placeType = 1
                elsif (beat - 1) mod 4 = 2 and sixteenth = 1
                    if probability < 0.3
                        placeType = 1
                    endif
                elsif (beat - 1) mod 4 = 1 and sixteenth = 1
                    if probability < groove_density * 0.5
                        placeType = 3
                    endif
                elsif (beat - 1) mod 2 = 0 and sixteenth = 1
                    if probability < groove_density * 0.4
                        placeType = 2
                    endif
                endif
            endif
            
            if placeType > 0
                soundToUse = 0
                
                if placeType = 1 and numBass > 0
                    selectObject: bassDrums'bassIdx'
                    soundToUse = Copy: "temp"
                    bassIdx = (bassIdx mod numBass) + 1
                elsif placeType = 2 and numHH > 0
                    selectObject: hiHats'hhIdx'
                    soundToUse = Copy: "temp"
                    hhIdx = (hhIdx mod numHH) + 1
                elsif placeType = 3 and numSnare > 0
                    selectObject: snares'snareIdx'
                    soundToUse = Copy: "temp"
                    snareIdx = (snareIdx mod numSnare) + 1
                endif
                
                if soundToUse > 0
                    hitsPlacedR += 1
                    
                    selectObject: soundToUse
                    soundDur = Get total duration
                    
                    if soundDur > clip_max_length
                        Extract part: 0, clip_max_length, "rectangular", 1, "no"
                        shortened = selected("Sound")
                        removeObject: soundToUse
                        soundToUse = shortened
                        soundDur = clip_max_length
                    endif
                    
                    envelope = Create Sound from formula: "env", 1, 0, soundDur, 
                        ...sampleRate, ~ if x < attack_time then 
                        ...(x/attack_time)^(1/shape_intensity) 
                        ...else if x > soundDur - release_time then 
                        ...((soundDur - x)/release_time)^shape_intensity 
                        ...else 1 fi fi
                    
                    selectObject: soundToUse
                    Formula: ~ self * object[envelope]
                    removeObject: envelope
                    
                    Scale peak: 0.7
                    velocity = 0.6 + randomUniform(0, 0.4)
                    Formula: ~ self * velocity
                    
                    maxLen = patternDuration - position
                    if maxLen <= 0
                        removeObject: soundToUse
                        soundToUse = 0
                    endif
                    
                    if soundToUse > 0
                        if soundDur > maxLen
                            selectObject: soundToUse
                            Extract part: 0, maxLen, "rectangular", 1, "no"
                            trimmed = selected("Sound")
                            removeObject: soundToUse
                            soundToUse = trimmed
                            soundDur = maxLen
                        endif
                        
                        selectObject: soundToUse
                        soundMatrix = Down to Matrix
                        nCols = Get number of columns
                        
                        selectObject: pattern_right
                        positionSamples = round(position * sampleRate)
                        
                        Formula: ~ if col >= positionSamples + 1 and col <= positionSamples + nCols 
                            ...then self + object[soundMatrix, 1, col - positionSamples] 
                            ...else self fi
                        
                        removeObject: soundMatrix, soundToUse
                    endif
                endif
            endif
        endfor
    endfor
    
    appendInfoLine: "Right channel: ", hitsPlacedR, " hits placed"
    
    # Combine to stereo
    selectObject: pattern_left, pattern_right
    stereoPattern = Combine to stereo
    
    removeObject: pattern_left, pattern_right
    
    selectObject: stereoPattern
    Scale peak: 0.95
    Rename: soundName$ + "_groove_" + string$(bars) + "bar_stereo"
    
    finalPattern = stereoPattern
else
    selectObject: pattern_left
    Scale peak: 0.95
    Rename: soundName$ + "_groove_" + string$(bars) + "bar"
    finalPattern = pattern_left
endif

# Cleanup original segments
for i to numberOfEvents
    removeObject: eventSound'i'
endfor

appendInfoLine: ""
appendInfoLine: "✓ Groove pattern created!"
appendInfoLine: "New sound: ", selected$("Sound")

selectObject: finalPattern
Play