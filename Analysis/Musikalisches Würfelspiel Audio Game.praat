# ============================================================
# Praat AudioTools - Musikalisches Würfelspiel Audio Game  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  Musikalisches Würfelspiel Audio Game
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Musikalisches Würfelspiel Audio Game

form Musikalisches Würfelspiel Settings
    comment Phrase Structure
    positive numberOfSegments 16
    comment Feature Weighting for Classification
    positive intensityWeight 1.0
    positive spectralWeight 1.0
    positive pitchWeight 0.5
    comment Musical Expression
    boolean applyRitardando 1
    positive ritardandoModerate 1.15
    positive ritardandoFinal 1.3
    boolean applyDiminuendo 1
    positive diminuendoModerate 0.6
    positive diminuendoFinal 0.4
    comment Playback Options
    boolean playDuringProcessing 1
    boolean playFinalResult 0
    positive visualizationDelay 0.05
endform

# Validate number of segments
if numberOfSegments < 4
    numberOfSegments = 4
endif
if numberOfSegments > 64
    numberOfSegments = 64
endif

# Get the selected Sound
soundID = selected("Sound")
soundName$ = selected$("Sound")

# Convert to mono if needed
select soundID
numberOfChannels = Get number of channels
if numberOfChannels > 1
    select soundID
    Convert to mono
    monoSound = selected("Sound")
    soundName$ = selected$("Sound")
    convertedToMono = 1
else
    monoSound = soundID
    convertedToMono = 0
endif

# Get total duration and calculate segment duration
select monoSound
duration = Get total duration
sampleRate = Get sampling frequency
segmentDuration = duration / numberOfSegments

# Create TableOfReal to store features and classifications
Create TableOfReal: "features", numberOfSegments, 4
featuresID = selected("TableOfReal")
Set column label (index): 1, "intensity"
Set column label (index): 2, "pitch"
Set column label (index): 3, "spectral_cog"
Set column label (index): 4, "function"

appendInfoLine: "========================================="
appendInfoLine: "Musikalisches Würfelspiel Audio Game"
appendInfoLine: "========================================="
appendInfoLine: "Analyzing ", numberOfSegments, " segments..."

# Extract segments and compute features for each
for i from 1 to numberOfSegments
    startTime = (i - 1) * segmentDuration
    endTime = i * segmentDuration
    
    # Extract segment
    select monoSound
    Extract part: startTime, endTime, "rectangular", 1, "no"
    segmentID[i] = selected("Sound")
    Rename: "segment_" + string$(i)
    
    # Compute mean intensity
    select segmentID[i]
    To Intensity: 75, 0, "yes"
    intensityID = selected("Intensity")
    meanIntensity = Get mean: 0, 0, "energy"
    Remove
    
    # Compute mean pitch
    select segmentID[i]
    To Pitch: 0, 75, 600
    pitchID = selected("Pitch")
    meanPitch = Get mean: 0, 0, "Hertz"
    if meanPitch = undefined
        meanPitch = 200
    endif
    Remove
    
    # Compute spectral centre of gravity
    select segmentID[i]
    To Spectrum: "yes"
    spectrumID = selected("Spectrum")
    spectralCOG = Get centre of gravity: 2
    Remove
    
    # Store features in TableOfReal
    select featuresID
    Set value: i, 1, meanIntensity
    Set value: i, 2, meanPitch
    Set value: i, 3, spectralCOG
    
    appendInfo: "."
    if i mod 4 = 0
        appendInfo: " ", i
    endif
endfor

appendInfoLine: ""
appendInfoLine: "Classifying segments with weighted features..."

# Compute global means and standard deviations for z-score normalization
select featuresID
totalIntensity = 0
totalPitch = 0
totalCOG = 0
for i from 1 to numberOfSegments
    totalIntensity += Get value: i, 1
    totalPitch += Get value: i, 2
    totalCOG += Get value: i, 3
endfor
meanIntensityGlobal = totalIntensity / numberOfSegments
meanPitchGlobal = totalPitch / numberOfSegments
meanCOGGlobal = totalCOG / numberOfSegments

# Calculate standard deviations
sumSqIntensity = 0
sumSqPitch = 0
sumSqCOG = 0
for i from 1 to numberOfSegments
    select featuresID
    intensity = Get value: i, 1
    pitch = Get value: i, 2
    cog = Get value: i, 3
    sumSqIntensity += (intensity - meanIntensityGlobal) ^ 2
    sumSqPitch += (pitch - meanPitchGlobal) ^ 2
    sumSqCOG += (cog - meanCOGGlobal) ^ 2
endfor
sdIntensity = sqrt(sumSqIntensity / numberOfSegments)
sdPitch = sqrt(sumSqPitch / numberOfSegments)
sdCOG = sqrt(sumSqCOG / numberOfSegments)

# Prevent division by zero
if sdIntensity = 0
    sdIntensity = 1
endif
if sdPitch = 0
    sdPitch = 1
endif
if sdCOG = 0
    sdCOG = 1
endif

# Classify each segment into functional roles using weighted z-scores
# 1 = T (tonic/stable), 2 = P (predominant), 3 = D (dominant/tension), 4 = C (cadence/release)
for i from 1 to numberOfSegments
    select featuresID
    intensity = Get value: i, 1
    pitch = Get value: i, 2
    cog = Get value: i, 3
    
    # Calculate z-scores
    zIntensity = (intensity - meanIntensityGlobal) / sdIntensity
    zPitch = (pitch - meanPitchGlobal) / sdPitch
    zCOG = (cog - meanCOGGlobal) / sdCOG
    
    # Compute weighted tension score
    # Higher intensity, higher pitch, brighter spectrum = more tension
    tensionScore = (zIntensity * intensityWeight) + (zPitch * pitchWeight) + (zCOG * spectralWeight)
    
    # Normalize by total weight
    totalWeight = intensityWeight + pitchWeight + spectralWeight
    tensionScore = tensionScore / totalWeight
    
    # Map tension to functional roles
    # High tension (z > 0.5) = Dominant
    # Medium-high tension (0 < z < 0.5) = Predominant  
    # Medium-low tension (-0.5 < z < 0) = Tonic
    # Low tension (z < -0.5) = Cadence
    if tensionScore > 0.5
        functionType = 3
    elsif tensionScore > 0
        functionType = 2
    elsif tensionScore > -0.5
        functionType = 1
    else
        functionType = 4
    endif
    
    Set value: i, 4, functionType
endfor

# Define output functional pattern (T-P-D-C repeating)
for i from 1 to numberOfSegments
    remainder = (i - 1) mod 4
    if remainder == 0
        outputPattern[i] = 1
    elsif remainder == 1
        outputPattern[i] = 2
    elsif remainder == 2
        outputPattern[i] = 3
    else
        outputPattern[i] = 4
    endif
endfor

# Pre-select segments for each output position
for position from 1 to numberOfSegments
    requiredFunction = outputPattern[position]
    
    # Find all segments matching the required function
    select featuresID
    matchCount = 0
    for seg from 1 to numberOfSegments
        segFunction = Get value: seg, 4
        if segFunction == requiredFunction
            matchCount += 1
            matches[matchCount] = seg
        endif
    endfor
    
    # Select random matching segment (or random fallback)
    if matchCount > 0
        randomIndex = randomInteger(1, matchCount)
        chosenSegment[position] = matches[randomIndex]
    else
        chosenSegment[position] = randomInteger(1, numberOfSegments)
    endif
    
    # Store function label
    if requiredFunction == 1
        requiredLabel$[position] = "T"
    elsif requiredFunction == 2
        requiredLabel$[position] = "P"
    elsif requiredFunction == 3
        requiredLabel$[position] = "D"
    else
        requiredLabel$[position] = "C"
    endif
endfor

appendInfoLine: "Processing with expression..."

# Calculate grid dimensions for visualization
gridSize = ceiling(sqrt(numberOfSegments))
if gridSize * (gridSize - 1) >= numberOfSegments
    gridRows = gridSize - 1
    gridCols = gridSize
else
    gridRows = gridSize
    gridCols = gridSize
endif

# ===== PROGRESSIVE PROCESSING WITH VISUALIZATION =====
for k from 1 to numberOfSegments
    # Draw visualization
    Erase all
    Select inner viewport: 0.5, 7.5, 0.5, 7.5
    
    Axes: 0, gridCols, 0, gridRows
    Black
    Line width: 1
    
    # Title
    Text top: "yes", "Würfelspiel Reordering - Step 'k'/'numberOfSegments'"
    Text left: "yes", "Row"
    Text bottom: "yes", "Column"
    
    # Draw grid
    Grey
    for i from 0 to gridCols
        Draw line: i, 0, i, gridRows
    endfor
    for i from 0 to gridRows
        Draw line: 0, i, gridCols, i
    endfor
    
    # Draw cells
    for position from 1 to numberOfSegments
        row = floor((position - 1) / gridCols)
        col = (position - 1) mod gridCols
        
        x1 = col
        x2 = col + 1
        y1 = gridRows - row - 1
        y2 = gridRows - row
        xCenter = (x1 + x2) / 2
        yCenter = (y1 + y2) / 2
        
        if position <= k
            # Already processed - show with color
            selectedSeg = chosenSegment[position]
            funcLabel$ = requiredLabel$[position]
            
            # Color by function (NEW COLORS)
            if funcLabel$ == "T"
                Paint circle: "purple", xCenter, yCenter, 0.35
            elsif funcLabel$ == "P"
                Paint circle: "cyan", xCenter, yCenter, 0.35
            elsif funcLabel$ == "D"
                Paint circle: "magenta", xCenter, yCenter, 0.35
            else
                Paint circle: "pink", xCenter, yCenter, 0.35
            endif
            
            # Draw text in WHITE
            White
            if position == k
                Line width: 3
                Text: xCenter, "centre", yCenter + 0.15, "half", "##→ 'selectedSeg'##"
                Text: xCenter, "centre", yCenter - 0.15, "half", "##'funcLabel$'##"
            else
                Line width: 1
                Text: xCenter, "centre", yCenter + 0.1, "half", "→'selectedSeg'"
                Text: xCenter, "centre", yCenter - 0.1, "half", "'funcLabel$'"
            endif
        else
            # Not yet processed - show empty
            Grey
            Draw circle: xCenter, yCenter, 0.35
        endif
    endfor
    
    # Legend (NEW COLORS)
    Select inner viewport: 0.5, 7.5, 7.8, 8.5
    Axes: 0, 1, 0, 1
    Black
    Line width: 1
    Paint circle: "purple", 0.05, 0.7, 0.015
    Text: 0.08, "left", 0.7, "half", "T=Tonic (stable)"
    Paint circle: "cyan", 0.3, 0.7, 0.015
    Text: 0.33, "left", 0.7, "half", "P=Predominant"
    Paint circle: "magenta", 0.6, 0.7, 0.015
    Text: 0.63, "left", 0.7, "half", "D=Dominant (tension)"
    Paint circle: "pink", 0.05, 0.3, 0.015
    Text: 0.08, "left", 0.3, "half", "C=Cadence (release)"
    
    # Process current segment - COPY from original segment
    select segmentID[chosenSegment[k]]
    Copy: "piece_" + string$(k)
    pieceID[k] = selected("Sound")
    
    # Apply ritardando and diminuendo at phrase endings ONLY
    # Every 4th segment (phrase ending), especially last segment
    if k mod 4 == 0
        select pieceID[k]
        pieceDur = Get total duration
        
        # Determine effect strength based on position
        if k == numberOfSegments
            # Final cadence - strongest effect
            ritFactor = ritardandoFinal
            dimAmount = diminuendoFinal
        else
            # Phrase endings - moderate effect
            ritFactor = ritardandoModerate
            dimAmount = diminuendoModerate
        endif
        
        # Apply diminuendo FIRST (before ritardando)
        if applyDiminuendo == 1
            select pieceID[k]
            fadeStart = pieceDur * 0.7
            Formula: "if x < fadeStart then self else self * (1 - (x - fadeStart)/(pieceDur - fadeStart) * (1 - dimAmount)) fi"
        endif
        
        # Apply ritardando (slow down) to last 30% of segment
        if applyRitardando == 1
            select pieceID[k]
            pieceDur = Get total duration
            fadeStart = pieceDur * 0.7
            
            # Use higher quality PSOLA settings
            To Manipulation: 0.01, 75, 600
            manipID = selected("Manipulation")
            Extract duration tier
            durTierID = selected("DurationTier")
            
            # Add points for gradual slowdown
            Add point: 0, 1.0
            Add point: fadeStart, 1.0
            Add point: pieceDur, ritFactor
            
            # Apply the duration tier
            select manipID
            plus durTierID
            Replace duration tier
            select manipID
            Get resynthesis (overlap-add)
            ritSound = selected("Sound")
            
            # Clean up manipulation objects
            select manipID
            plus durTierID
            Remove
            
            # Replace piece with ritardando version
            select pieceID[k]
            Remove
            select ritSound
            Rename: "piece_" + string$(k)
            pieceID[k] = selected("Sound")
        endif
    endif
    
    # Play current segment if requested
    if playDuringProcessing == 1
        select pieceID[k]
        Play
    endif
    
    # Visualization delay (only if not playing)
    if playDuringProcessing == 0
        sleep: visualizationDelay
    endif
    
    appendInfo: "."
    if k mod 4 = 0
        appendInfo: " ", k
    endif
endfor

appendInfoLine: ""
appendInfoLine: "Concatenating all segments..."

# ===== EFFICIENT CONCATENATION (ALL AT ONCE) =====
# Select all piece segments
select pieceID[1]
for i from 2 to numberOfSegments
    plus pieceID[i]
endfor
Concatenate
outputSound = selected("Sound")
Rename: "reordered_output"

# ===== FINAL VISUALIZATION =====
Erase all
Select inner viewport: 0.5, 7.5, 0.5, 7.5

Axes: 0, gridCols, 0, gridRows
Black
Line width: 1

# Title
Text top: "yes", "Würfelspiel Reordering - COMPLETE"
Text left: "yes", "Row"
Text bottom: "yes", "Column"

# Draw grid
Grey
for i from 0 to gridCols
    Draw line: i, 0, i, gridRows
endfor
for i from 0 to gridRows
    Draw line: 0, i, gridCols, i
endfor

# Draw all cells
for position from 1 to numberOfSegments
    row = floor((position - 1) / gridCols)
    col = (position - 1) mod gridCols
    
    x1 = col
    x2 = col + 1
    y1 = gridRows - row - 1
    y2 = gridRows - row
    xCenter = (x1 + x2) / 2
    yCenter = (y1 + y2) / 2
    
    selectedSeg = chosenSegment[position]
    funcLabel$ = requiredLabel$[position]
    
    # Color by function (NEW COLORS)
    if funcLabel$ == "T"
        Paint circle: "purple", xCenter, yCenter, 0.35
    elsif funcLabel$ == "P"
        Paint circle: "cyan", xCenter, yCenter, 0.35
    elsif funcLabel$ == "D"
        Paint circle: "magenta", xCenter, yCenter, 0.35
    else
        Paint circle: "pink", xCenter, yCenter, 0.35
    endif
    
    # Draw text in WHITE
    White
    Line width: 2
    Text: xCenter, "centre", yCenter + 0.1, "half", "→ 'selectedSeg'"
    Text: xCenter, "centre", yCenter - 0.1, "half", "'funcLabel$'"
endfor

# Legend (NEW COLORS)
Select inner viewport: 0.5, 7.5, 7.8, 8.5
Axes: 0, 1, 0, 1
Black
Line width: 1
Paint circle: "purple", 0.05, 0.7, 0.015
Text: 0.08, "left", 0.7, "half", "T=Tonic (stable)"
Paint circle: "cyan", 0.3, 0.7, 0.015
Text: 0.33, "left", 0.7, "half", "P=Predominant"
Paint circle: "magenta", 0.6, 0.7, 0.015
Text: 0.63, "left", 0.7, "half", "D=Dominant (tension)"
Paint circle: "pink", 0.05, 0.3, 0.015
Text: 0.08, "left", 0.3, "half", "C=Cadence (release)"

# Summary text
expressionText$ = ""
if applyRitardando == 1 and applyDiminuendo == 1
    expressionText$ = " | With ritardando & diminuendo"
elsif applyRitardando == 1
    expressionText$ = " | With ritardando"
elsif applyDiminuendo == 1
    expressionText$ = " | With diminuendo"
endif
Text: 0.5, "centre", 0.5, "half", "Pattern: T-P-D-C | 'soundName$''expressionText$'"

# Clean up temporary objects
select featuresID
Remove
for i from 1 to numberOfSegments
    select segmentID[i]
    Remove
    select pieceID[i]
    Remove
endfor

# Clean up mono sound if it was created
if convertedToMono == 1
    select monoSound
    Remove
endif

# Select final result
select outputSound

appendInfoLine: ""
appendInfoLine: "========================================="
appendInfoLine: "COMPLETE!"
appendInfoLine: "========================================="
appendInfoLine: "Output: reordered_output"
appendInfoLine: "Segments: ", numberOfSegments
appendInfoLine: "Feature weights: I=", intensityWeight, " P=", pitchWeight, " S=", spectralWeight
if applyRitardando == 1
    appendInfoLine: "Ritardando: moderate=", ritardandoModerate, " final=", ritardandoFinal
endif
if applyDiminuendo == 1
    appendInfoLine: "Diminuendo: moderate=", diminuendoModerate, " final=", diminuendoFinal
endif
appendInfoLine: ""

# Play the complete output if requested
if playFinalResult == 1
    appendInfoLine: "Now playing complete result..."
    Play
else
    appendInfoLine: "Playback disabled. Select 'reordered_output' and press Play to listen."
endif

appendInfoLine: ""