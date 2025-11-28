# ============================================================
# Praat AudioTools - L-SYSTEM GRANULAR PITCH EFFECT.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   L-SYSTEM GRANULAR PITCH EFFECT
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

###############################################################################
# L-SYSTEM GRANULAR GATING + PITCH EFFECT
# Fast, Praat-native granular gating and pitch processing driven by L-system
# generative rules. Symbols control rhythmic on/off patterns and cumulative
# pitch shifts applied via Manipulation object.
#
# SYMBOL SEMANTICS:
#   G = Play grain (gate ON with RepeatGain)
#   S = Skip grain (gate OFF or use BaseSkipGain)
#   U = Increase pitch of next grain by PitchStep_semitones
#   D = Decrease pitch of next grain by PitchStep_semitones  
#   N = Neutral (no pitch change for next grain)
#
# The L-system generates a control pattern that is mapped cyclically across
# all grains. Pitch changes accumulate over time (walk up/down), while
# G/S symbols create rhythmic gating patterns.
###############################################################################

form L-System Granular Gating + Pitch Effect
    comment === Presets ===
    optionmenu Preset 9
        option Rhythmic Stutter
        option Pitch Walk Up
        option Pitch Walk Down
        option Chaotic Glitch
        option Melodic Arpeggio
        option Sparse Texture
        option Dense Granular
        option Fibonacci Pattern
        option Custom
    
    comment === L-System Configuration ===
    sentence Axiom G
    sentence Rule_G GSUN
    sentence Rule_S N
    sentence Rule_U UD
    sentence Rule_D DU
    sentence Rule_N G
    positive Iterations 3
    positive MaxStringLength 10000
    
    comment === Granular Processing ===
    positive GrainDuration_ms 50
    boolean GrainOverlap 1
    real BaseSkipGain 0.0 (= 0.0)
    real RepeatGain 1.0 (= 1.0)
    
    comment === Pitch Control ===
    real BasePitchShift_semitones 0 (= 0)
    real PitchStep_semitones 2 (= 2)
    positive MaxPitchShift_semitones 12
endform

###############################################################################
# 0. APPLY PRESET
###############################################################################

if preset = 1
    # Rhythmic Stutter - Heavy skip patterns for glitchy rhythm
    axiom$ = "GS"
    rule_G$ = "GSS"
    rule_S$ = "SG"
    rule_U$ = "U"
    rule_D$ = "D"
    rule_N$ = "N"
    iterations = 4
    grainDuration_ms = 40
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = 0
    pitchStep_semitones = 1
elsif preset = 2
    # Pitch Walk Up - Gradual pitch ascent
    axiom$ = "GU"
    rule_G$ = "GUN"
    rule_S$ = "N"
    rule_U$ = "UUN"
    rule_D$ = "N"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 60
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = -6
    pitchStep_semitones = 1
elsif preset = 3
    # Pitch Walk Down - Gradual pitch descent
    axiom$ = "GD"
    rule_G$ = "GDN"
    rule_S$ = "N"
    rule_U$ = "N"
    rule_D$ = "DDN"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 60
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = 6
    pitchStep_semitones = 1
elsif preset = 4
    # Chaotic Glitch - Complex evolving pattern (default from form)
    axiom$ = "GSUD"
    rule_G$ = "GSUN"
    rule_S$ = "N"
    rule_U$ = "UD"
    rule_D$ = "DU"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 50
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = 0
    pitchStep_semitones = 2
elsif preset = 5
    # Melodic Arpeggio - Creates up-down melodic patterns
    axiom$ = "GUUUDDD"
    rule_G$ = "G"
    rule_S$ = "G"
    rule_U$ = "UN"
    rule_D$ = "DN"
    rule_N$ = "N"
    iterations = 2
    grainDuration_ms = 80
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = -4
    pitchStep_semitones = 2
elsif preset = 6
    # Sparse Texture - Lots of silence, minimal grains
    axiom$ = "S"
    rule_G$ = "GSSS"
    rule_S$ = "SSSG"
    rule_U$ = "U"
    rule_D$ = "D"
    rule_N$ = "S"
    iterations = 4
    grainDuration_ms = 30
    grainOverlap = 1
    baseSkipGain = 0.05
    repeatGain = 0.8
    basePitchShift_semitones = 0
    pitchStep_semitones = 3
elsif preset = 7
    # Dense Granular - Mostly playing, continuous texture
    axiom$ = "G"
    rule_G$ = "GGUNG"
    rule_S$ = "G"
    rule_U$ = "UNG"
    rule_D$ = "DNG"
    rule_N$ = "NG"
    iterations = 3
    grainDuration_ms = 25
    grainOverlap = 1
    baseSkipGain = 0.2
    repeatGain = 0.9
    basePitchShift_semitones = 0
    pitchStep_semitones = 1
elsif preset = 8
    # Fibonacci Pattern - Mathematical structure
    axiom$ = "G"
    rule_G$ = "GN"
    rule_S$ = "S"
    rule_U$ = "UN"
    rule_D$ = "DN"
    rule_N$ = "G"
    iterations = 5
    grainDuration_ms = 45
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = 0
    pitchStep_semitones = 2
endif
# If preset = 9 (Custom), use values from form as entered

###############################################################################
# 1. ERROR CHECKING
###############################################################################

# Check if a Sound is selected
numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds = 0
    exitScript: "ERROR: Please select a Sound object first."
endif

# Get the selected sound
soundID = selected("Sound")
soundName$ = selected$("Sound")

# Get sound properties
selectObject: soundID
duration = Get total duration
sampleRate = Get sampling frequency
startTime = Get start time
endTime = Get end time
numChannels = Get number of channels

if duration <= 0
    exitScript: "ERROR: Sound duration must be greater than 0."
endif

###############################################################################
# 2. L-SYSTEM STRING GENERATION (Non-recursive, iterative)
###############################################################################

appendInfoLine: "=== L-System Granular Gating + Pitch Effect ==="
appendInfoLine: "Processing sound: ", soundName$
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"

# Show which preset was used
if preset = 1
    appendInfoLine: "Preset: Rhythmic Stutter"
elsif preset = 2
    appendInfoLine: "Preset: Pitch Walk Up"
elsif preset = 3
    appendInfoLine: "Preset: Pitch Walk Down"
elsif preset = 4
    appendInfoLine: "Preset: Chaotic Glitch"
elsif preset = 5
    appendInfoLine: "Preset: Melodic Arpeggio"
elsif preset = 6
    appendInfoLine: "Preset: Sparse Texture"
elsif preset = 7
    appendInfoLine: "Preset: Dense Granular"
elsif preset = 8
    appendInfoLine: "Preset: Fibonacci Pattern"
else
    appendInfoLine: "Preset: Custom"
endif

appendInfoLine: ""
appendInfoLine: "Generating L-system string..."

# Initialize with axiom
currentString$ = axiom$
currentLength = length(currentString$)

# Iterative L-system expansion
for iter from 1 to iterations
    nextString$ = ""
    
    # Process each character in current string
    for charPos from 1 to currentLength
        char$ = mid$(currentString$, charPos, 1)
        
        # Apply rewrite rules
        if char$ = "G"
            replacement$ = rule_G$
        elsif char$ = "S"
            replacement$ = rule_S$
        elsif char$ = "U"
            replacement$ = rule_U$
        elsif char$ = "D"
            replacement$ = rule_D$
        elsif char$ = "N"
            replacement$ = rule_N$
        else
            # Unknown symbol - keep as is (no-op)
            replacement$ = char$
        endif
        
        nextString$ = nextString$ + replacement$
    endfor
    
    # Update for next iteration
    currentString$ = nextString$
    currentLength = length(currentString$)
    
    # Check length limit
    if currentLength > maxStringLength
        appendInfoLine: "WARNING: L-system string exceeded MaxStringLength (", maxStringLength, ")"
        appendInfoLine: "         Truncating at iteration ", iter, " with length ", currentLength
        currentString$ = left$(currentString$, maxStringLength)
        currentLength = maxStringLength
        goto DONE_LSYSTEM
    endif
endfor

label DONE_LSYSTEM

# Final L-system string
lString$ = currentString$
lStringLength = length(lString$)

appendInfoLine: "L-system string generated:"
appendInfoLine: "  Iterations: ", iterations
appendInfoLine: "  Final length: ", lStringLength
if lStringLength <= 200
    appendInfoLine: "  String: ", lString$
else
    appendInfoLine: "  String (first 200 chars): ", left$(lString$, 200), "..."
endif
appendInfoLine: ""

###############################################################################
# 3. GRAIN DISCRETIZATION
###############################################################################

grainDur = grainDuration_ms / 1000.0
numGrains = floor(duration / grainDur)

# Ensure at least one grain
if numGrains < 1
    numGrains = 1
endif

appendInfoLine: "Grain configuration:"
appendInfoLine: "  Grain duration: ", fixed$(grainDur * 1000, 1), " ms"
appendInfoLine: "  Number of grains: ", numGrains
appendInfoLine: ""

###############################################################################
# 4. BUILD CUMULATIVE PITCH SCHEDULE (U/D affect NEXT grain)
###############################################################################

appendInfoLine: "Building cumulative pitch modulation..."

# Create arrays for grain info
cumPitch = basePitchShift_semitones
minPitchReached = cumPitch
maxPitchReached = cumPitch

# Create a table to store grain information
grainTable = Create Table with column names: "grainInfo", numGrains,
    ... "grainIndex symbol tStart tEnd tCenter cumPitch playGrain"

# Process each grain and determine pitch/playback behavior
for k from 1 to numGrains
    # Map grain index to L-system symbol (cyclic if needed)
    symbolIndex = ((k - 1) mod lStringLength) + 1
    symbol$ = mid$(lString$, symbolIndex, 1)
    
    # Calculate grain time boundaries
    tStart = startTime + (k - 1) * grainDur
    tEnd = tStart + grainDur
    if tEnd > endTime
        tEnd = endTime
    endif
    tCenter = (tStart + tEnd) / 2
    
    # Use CURRENT cumPitch for this grain (before updating)
    grainPitch = cumPitch
    
    # Then update cumPitch based on symbol for NEXT grain
    if symbol$ = "U"
        cumPitch = cumPitch + pitchStep_semitones
    elsif symbol$ = "D"
        cumPitch = cumPitch - pitchStep_semitones
    elsif symbol$ = "N"
        # No change
    elsif symbol$ = "G"
        # No pitch change for G (gating control only)
    elsif symbol$ = "S"
        # No pitch change for S (gating control only)
    endif
    
    # Clamp pitch to max range
    if cumPitch > maxPitchShift_semitones
        cumPitch = maxPitchShift_semitones
    elsif cumPitch < -maxPitchShift_semitones
        cumPitch = -maxPitchShift_semitones
    endif
    
    # Track min/max
    if grainPitch < minPitchReached
        minPitchReached = grainPitch
    endif
    if grainPitch > maxPitchReached
        maxPitchReached = grainPitch
    endif
    
    # Determine if grain should be played (G, U, D, N) or skipped (S)
    if symbol$ = "S"
        playGrain = 0
    else
        playGrain = 1
    endif
    
    # Store in table
    selectObject: grainTable
    Set numeric value: k, "grainIndex", k
    Set string value: k, "symbol", symbol$
    Set numeric value: k, "tStart", tStart
    Set numeric value: k, "tEnd", tEnd
    Set numeric value: k, "tCenter", tCenter
    Set numeric value: k, "cumPitch", grainPitch
    Set numeric value: k, "playGrain", playGrain
endfor

appendInfoLine: "Pitch modulation range:"
appendInfoLine: "  Min pitch shift: ", fixed$(minPitchReached, 2), " semitones"
appendInfoLine: "  Max pitch shift: ", fixed$(maxPitchReached, 2), " semitones"
appendInfoLine: ""

###############################################################################
# 5. PITCH MODIFICATION USING MANIPULATION OBJECT
###############################################################################

appendInfoLine: "Applying pitch modification using Manipulation object..."

selectObject: soundID

# Create Manipulation object
manipID = To Manipulation: 0.01, 75, 600

# Extract PitchTier
selectObject: manipID
pitchTierID = Extract pitch tier

# Clear existing points and add new ones based on cumulative pitch
selectObject: pitchTierID
Remove points between: startTime, endTime

# Get original pitch to use as base
selectObject: soundID
pitchID = To Pitch: 0.01, 75, 600

# Add pitch points for each grain
for k from 1 to numGrains
    selectObject: grainTable
    tCenter = Get value: k, "tCenter"
    cumPitch = Get value: k, "cumPitch"
    
    # Get original pitch at this time
    selectObject: pitchID
    origPitch = Get value at time: tCenter, "Hertz", "Linear"
    
    # If pitch is undefined, use a default (e.g., 200 Hz for average voice)
    if origPitch = undefined
        origPitch = 200
    endif
    
    # Calculate target pitch
    pitchFactor = 2 ^ (cumPitch / 12)
    targetPitch = origPitch * pitchFactor
    
    # Add point to PitchTier
    selectObject: pitchTierID
    Add point: tCenter, targetPitch
endfor

# Replace PitchTier in Manipulation
selectObject: manipID
plusObject: pitchTierID
Replace pitch tier

# Resynthesize
selectObject: manipID
resynthSound = Get resynthesis (overlap-add)
Rename: soundName$ + "_pitched"

# Clean up intermediate objects
removeObject: pitchID, pitchTierID, manipID

appendInfoLine: "Pitch modification complete."
appendInfoLine: ""

###############################################################################
# 6. GRAIN GATING (Apply G/S patterns to pitched sound)
###############################################################################

appendInfoLine: "Applying grain gating (G=play, S=skip)..."

# Start with the pitched sound
selectObject: resynthSound
outputSound = Copy: soundName$ + "_LSystemGranular"

# Get number of channels in output
selectObject: outputSound
outputChannels = Get number of channels

# Process each grain - gate directly using Formula (part)
for k from 1 to numGrains
    selectObject: grainTable
    tStart = Get value: k, "tStart"
    tEnd = Get value: k, "tEnd"
    playGrain = Get value: k, "playGrain"
    symbol$ = Get value: k, "symbol"
    
    # Ensure tEnd doesn't exceed sound duration
    if tEnd > endTime
        tEnd = endTime
    endif
    
    grainLength = tEnd - tStart
    if grainLength <= 0
        goto NEXT_GRAIN
    endif
    
    # Determine gain based on symbol
    if playGrain = 1
        # G, U, D, N - play the grain at repeatGain
        grainGain = repeatGain
    else
        # S - skip (mute or use baseSkipGain)
        grainGain = baseSkipGain
    endif
    
    # Apply gain to this grain region (all channels)
    selectObject: outputSound
    Formula (part): tStart, tEnd, 1, outputChannels, "self * " + string$(grainGain)
    
    # Apply crossfade/windowing if overlap is enabled and grain is playing
    if grainOverlap = 1 and playGrain = 1
        selectObject: outputSound
        fadeDur = min(grainLength / 4, 0.005)
        if fadeDur > 0
            # Fade in at grain start
            Formula (part): tStart, tStart + fadeDur, 1, outputChannels, 
                ... "self * ((x - " + string$(tStart) + ") / " + string$(fadeDur) + ")"
            # Fade out at grain end
            fadeStartTime = tEnd - fadeDur
            Formula (part): fadeStartTime, tEnd, 1, outputChannels, 
                ... "self * ((" + string$(tEnd) + " - x) / " + string$(fadeDur) + ")"
        endif
    endif
    
    label NEXT_GRAIN
endfor

appendInfoLine: "Grain gating complete."
appendInfoLine: ""

###############################################################################
# 7. CLEANUP AND OUTPUT
###############################################################################

# Clean up intermediate objects
removeObject: grainTable, resynthSound

# Select output sound
selectObject: outputSound

appendInfoLine: "=== Processing Complete ==="
appendInfoLine: "Output sound: ", soundName$, "_LSystemGranular"
appendInfoLine: ""

# Show statistics
countG = 0
countS = 0
countU = 0
countD = 0
countN = 0
countOther = 0

for i from 1 to lStringLength
    char$ = mid$(lString$, i, 1)
    if char$ = "G"
        countG = countG + 1
    elsif char$ = "S"
        countS = countS + 1
    elsif char$ = "U"
        countU = countU + 1
    elsif char$ = "D"
        countD = countD + 1
    elsif char$ = "N"
        countN = countN + 1
    else
        countOther = countOther + 1
    endif
endfor

appendInfoLine: "L-system symbol statistics:"
appendInfoLine: "  G (play): ", countG, " (", fixed$(100 * countG / lStringLength, 1), "%)"
appendInfoLine: "  S (skip): ", countS, " (", fixed$(100 * countS / lStringLength, 1), "%)"
appendInfoLine: "  U (pitch up next): ", countU, " (", fixed$(100 * countU / lStringLength, 1), "%)"
appendInfoLine: "  D (pitch down next): ", countD, " (", fixed$(100 * countD / lStringLength, 1), "%)"
appendInfoLine: "  N (neutral): ", countN, " (", fixed$(100 * countN / lStringLength, 1), "%)"
if countOther > 0
    appendInfoLine: "  Other: ", countOther
endif
appendInfoLine: ""
appendInfoLine: "=== Symbol Semantics ==="
appendInfoLine: "  G = Play grain (gate ON with RepeatGain)"
appendInfoLine: "  S = Skip grain (gate OFF or BaseSkipGain)"
appendInfoLine: "  U = Increase pitch of NEXT grain by PitchStep"
appendInfoLine: "  D = Decrease pitch of NEXT grain by PitchStep"
appendInfoLine: "  N = Neutral (no pitch change for next grain)"
appendInfoLine: ""
appendInfoLine: "Done!"
Play