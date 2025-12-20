# ========================================================================================
# Praat AudioTools - Continuous Pitch over MIDI Grid Visualizer (Enhanced)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 2.0 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#     Enhanced visualization of continuous pitch movement over MIDI grid
#     with color encoding, auto-scaling, and smoothing.
#
# Citation:
#     Cohen, S. (2025). Praat AudioTools: An Offline Analysis-Resynthesis Toolkit 
#     for Experimental Composition.
#     https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ========================================================================================

# ========================================================================================
# USER FORM - Simplified
# ========================================================================================

form Continuous Pitch MIDI Grid Visualizer
    comment === Analysis ===
    positive pitchFloor 75
    positive pitchCeiling 600
    positive timeStep 0.01
    
    comment === MIDI Range ===
    boolean autoMidiRange 1
    integer manualMidiMin 48
    integer manualMidiMax 84
    positive midiPadding 3
    
    comment === Smoothing ===
    optionmenu smoothing 1
        option No smoothing
        option Median 3-frame
        option Median 5-frame
        option Moving average
    
    comment === Color Scheme ===
    optionmenu colorScheme 1
        option Pitch+Loudness Rainbow
        option PitchClass+Loudness Wheel
        option Grayscale Loudness
        option Intensity Heatmap
        option Octave Spiral
    
    comment === Line Style ===
    optionmenu lineStyle 1
        option Thin continuous line
        option Thickness varies with loudness
        option Dots with size varies with loudness
    positive minDotSize 0.8
    positive maxDotSize 3.5
    comment (Dot size range for "Dots" style)
    
    comment === Display ===
    boolean showAllSemitones 1
    boolean showNoteLabels 1
    boolean showTimeGrid 0
    
    comment === Intensity ===
    positive intensityMinDb 40
    positive intensityMaxDb 80
    boolean useLogLoudness 1
endform

# ========================================================================================
# HELPER FUNCTIONS
# ========================================================================================

procedure hzToMidi: .hz
    if .hz > 0
        .midi = 69 + 12 * log2(.hz / 440)
    else
        .midi = undefined
    endif
endproc

procedure mapToRange: .value, .fromMin, .fromMax, .toMin, .toMax
    .value = max(.fromMin, min(.fromMax, .value))
    .result = .toMin + (.value - .fromMin) / (.fromMax - .fromMin) * (.toMax - .toMin)
endproc

procedure logCompress: .db, .minDb, .maxDb
    .normalized = (.db - .minDb) / (.maxDb - .minDb)
    .normalized = max(0, min(1, .normalized))
    if .normalized > 0
        .result = (log10(.normalized * 9 + 1)) / log10(10)
    else
        .result = 0
    endif
endproc

procedure getMidiNoteName: .midi
    .noteClass = .midi - 12 * floor(.midi / 12)
    .octave = floor(.midi / 12) - 1
    
    if .noteClass = 0
        .noteName$ = "C"
    elif .noteClass = 1
        .noteName$ = "C#"
    elif .noteClass = 2
        .noteName$ = "D"
    elif .noteClass = 3
        .noteName$ = "D#"
    elif .noteClass = 4
        .noteName$ = "E"
    elif .noteClass = 5
        .noteName$ = "F"
    elif .noteClass = 6
        .noteName$ = "F#"
    elif .noteClass = 7
        .noteName$ = "G"
    elif .noteClass = 8
        .noteName$ = "G#"
    elif .noteClass = 9
        .noteName$ = "A"
    elif .noteClass = 10
        .noteName$ = "A#"
    elif .noteClass = 11
        .noteName$ = "B"
    endif
    
    .fullName$ = .noteName$ + string$(.octave)
endproc

procedure medianFilter3: .i
    if .i = 1 or .i = numFrames
        .result = midiNote[.i]
    else
        if midiNote[.i-1] != undefined and midiNote[.i] != undefined and midiNote[.i+1] != undefined
            .a = midiNote[.i-1]
            .b = midiNote[.i]
            .c = midiNote[.i+1]
            
            if .a <= .b and .b <= .c
                .result = .b
            elif .a <= .c and .c <= .b
                .result = .c
            elif .b <= .a and .a <= .c
                .result = .a
            elif .b <= .c and .c <= .a
                .result = .c
            elif .c <= .a and .a <= .b
                .result = .a
            else
                .result = .b
            endif
        else
            .result = midiNote[.i]
        endif
    endif
endproc

procedure medianFilter5: .i
    if .i <= 2 or .i >= numFrames - 1
        .result = midiNote[.i]
    else
        .count = 0
        for .j from -2 to 2
            if midiNote[.i + .j] != undefined
                .count = .count + 1
                .val[.count] = midiNote[.i + .j]
            endif
        endfor
        
        if .count >= 3
            for .pass from 1 to .count - 1
                for .k from 1 to .count - .pass
                    if .val[.k] > .val[.k + 1]
                        .temp = .val[.k]
                        .val[.k] = .val[.k + 1]
                        .val[.k + 1] = .temp
                    endif
                endfor
            endfor
            .medianIdx = floor(.count / 2) + 1
            .result = .val[.medianIdx]
        else
            .result = midiNote[.i]
        endif
    endif
endproc

procedure movingAverage: .i
    if .i = 1 or .i = numFrames
        .result = midiNote[.i]
    else
        .count = 0
        .sum = 0
        for .j from -1 to 1
            if midiNote[.i + .j] != undefined
                .sum = .sum + midiNote[.i + .j]
                .count = .count + 1
            endif
        endfor
        if .count > 0
            .result = .sum / .count
        else
            .result = midiNote[.i]
        endif
    endif
endproc

procedure pitchClassToRGB: .midi, .brightness
    .noteClass = .midi - 12 * floor(.midi / 12)
    .hue = .noteClass / 12.0
    
    .h = .hue * 360
    .s = 0.8
    .v = .brightness
    
    .c = .v * .s
    .x = .c * (1 - abs(((.h / 60) mod 2) - 1))
    .m = .v - .c
    
    if .h < 60
        .r = .c
        .g = .x
        .b = 0
    elif .h < 120
        .r = .x
        .g = .c
        .b = 0
    elif .h < 180
        .r = 0
        .g = .c
        .b = .x
    elif .h < 240
        .r = 0
        .g = .x
        .b = .c
    elif .h < 300
        .r = .x
        .g = 0
        .b = .c
    else
        .r = .c
        .g = 0
        .b = .x
    endif
    
    .red = .r + .m
    .green = .g + .m
    .blue = .b + .m
endproc

procedure pitchHeightToRGB: .midi, .brightness
    @mapToRange: .midi, currentMidiMin, currentMidiMax, 0, 1
    .hue = mapToRange.result
    
    .h = (1 - .hue) * 240
    .s = 0.9
    .v = .brightness
    
    .c = .v * .s
    .x = .c * (1 - abs(((.h / 60) mod 2) - 1))
    .m = .v - .c
    
    if .h < 60
        .r = .c
        .g = .x
        .b = 0
    elif .h < 120
        .r = .x
        .g = .c
        .b = 0
    elif .h < 180
        .r = 0
        .g = .c
        .b = .x
    elif .h < 240
        .r = 0
        .g = .x
        .b = .c
    elif .h < 300
        .r = .x
        .g = 0
        .b = .c
    else
        .r = .c
        .g = 0
        .b = .x
    endif
    
    .red = .r + .m
    .green = .g + .m
    .blue = .b + .m
endproc

procedure octaveSpiralRGB: .midi, .brightness
    .noteClass = .midi - 12 * floor(.midi / 12)
    .octave = floor(.midi / 12) - 1
    
    .hue = (.noteClass / 12.0) * 360
    
    .octaveFactor = (.octave - 2) / 6.0
    .octaveFactor = max(0, min(1, .octaveFactor))
    
    .finalBrightness = .brightness * (0.4 + 0.6 * .octaveFactor)
    
    .s = 0.85
    .v = .finalBrightness
    
    .c = .v * .s
    .x = .c * (1 - abs(((.hue / 60) mod 2) - 1))
    .m = .v - .c
    
    if .hue < 60
        .r = .c
        .g = .x
        .b = 0
    elif .hue < 120
        .r = .x
        .g = .c
        .b = 0
    elif .hue < 180
        .r = 0
        .g = .c
        .b = .x
    elif .hue < 240
        .r = 0
        .g = .x
        .b = .c
    elif .hue < 300
        .r = .x
        .g = 0
        .b = .c
    else
        .r = .c
        .g = 0
        .b = .x
    endif
    
    .red = .r + .m
    .green = .g + .m
    .blue = .b + .m
endproc

# ========================================================================================
# MAIN SCRIPT
# ========================================================================================

sound$ = selected$("Sound")
soundID = selected("Sound")
duration = Get total duration
startTime = Get start time
endTime = Get end time

writeInfoLine: "Continuous Pitch MIDI Grid Visualizer v2.0"
appendInfoLine: "========================================================"
appendInfoLine: "Sound: ", sound$
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: ""

# ========================================================================================
# STEP 1: Extract Pitch and Intensity
# ========================================================================================

appendInfoLine: "Extracting pitch..."
selectObject: soundID
pitchID = To Pitch: timeStep, pitchFloor, pitchCeiling

appendInfoLine: "Extracting intensity..."
selectObject: soundID
intensityID = To Intensity: pitchFloor, timeStep, "yes"

# ========================================================================================
# STEP 2: Collect Data
# ========================================================================================

appendInfoLine: "Collecting data..."

selectObject: pitchID
numFrames = Get number of frames

midiMinFound = 1000
midiMaxFound = 0

for i from 1 to numFrames
    selectObject: pitchID
    t[i] = Get time from frame number: i
    f0[i] = Get value in frame: i, "Hertz"
    
    if f0[i] != undefined
        @hzToMidi: f0[i]
        midiNote[i] = hzToMidi.midi
        quantizedMidi[i] = round(midiNote[i])
        voiced[i] = 1
        
        if midiNote[i] < midiMinFound
            midiMinFound = midiNote[i]
        endif
        if midiNote[i] > midiMaxFound
            midiMaxFound = midiNote[i]
        endif
    else
        midiNote[i] = undefined
        quantizedMidi[i] = undefined
        voiced[i] = 0
    endif
    
    selectObject: intensityID
    intensity[i] = Get value at time: t[i], "Cubic"
    if intensity[i] = undefined
        intensity[i] = intensityMinDb
    endif
endfor

# Set MIDI range
if autoMidiRange and midiMinFound < 1000
    currentMidiMin = floor(midiMinFound) - midiPadding
    currentMidiMax = ceiling(midiMaxFound) + midiPadding
    appendInfoLine: "Auto MIDI range: ", currentMidiMin, " - ", currentMidiMax
else
    currentMidiMin = manualMidiMin
    currentMidiMax = manualMidiMax
    appendInfoLine: "Manual MIDI range: ", currentMidiMin, " - ", currentMidiMax
endif

# ========================================================================================
# STEP 3: Apply Smoothing
# ========================================================================================

if smoothing > 1
    appendInfoLine: "Smoothing: ", smoothing$, "..."
    
    for i from 1 to numFrames
        smoothedMidi[i] = midiNote[i]
    endfor
    
    for i from 1 to numFrames
        if voiced[i] = 1
            if smoothing = 2
                @medianFilter3: i
                smoothedMidi[i] = medianFilter3.result
            elif smoothing = 3
                @medianFilter5: i
                smoothedMidi[i] = medianFilter5.result
            elif smoothing = 4
                @movingAverage: i
                smoothedMidi[i] = movingAverage.result
            endif
        endif
    endfor
    
    for i from 1 to numFrames
        if voiced[i] = 1
            midiNote[i] = smoothedMidi[i]
        endif
    endfor
endif

# ========================================================================================
# STEP 4: Setup Picture Window
# ========================================================================================

Erase all
Select outer viewport: 0, 10, 0, 6
Font size: 10

# ========================================================================================
# STEP 5: Draw MIDI Grid
# ========================================================================================

appendInfoLine: "Drawing grid..."

Axes: startTime, endTime, currentMidiMin - 0.5, currentMidiMax + 0.5

# Horizontal grid lines
for midiLine from currentMidiMin to currentMidiMax
    @getMidiNoteName: midiLine
    noteClass = midiLine - 12 * floor(midiLine / 12)
    
    drawLine = 0
    
    if noteClass = 0
        Colour: "{0.65, 0.65, 0.65}"
        Line width: 2
        drawLine = 1
    elif (midiLine mod 12) = 0
        Colour: "{0.75, 0.75, 0.75}"
        Line width: 1.2
        drawLine = 1
    elif showAllSemitones
        Colour: "{0.92, 0.92, 0.92}"
        Line width: 0.4
        drawLine = 1
    endif
    
    if drawLine = 1
        Draw line: startTime, midiLine, endTime, midiLine
    endif
endfor

# Vertical time grid
if showTimeGrid
    Colour: "{0.95, 0.95, 0.95}"
    Line width: 0.3
    
    timeMarker = ceiling(startTime / 0.1) * 0.1
    while timeMarker <= endTime
        Draw line: timeMarker, currentMidiMin - 0.5, timeMarker, currentMidiMax + 0.5
        timeMarker = timeMarker + 0.1
    endwhile
endif

# ========================================================================================
# STEP 6: Draw Note Labels
# ========================================================================================

if showNoteLabels
    Font size: 8
    Colour: "{0.5, 0.5, 0.5}"
    
    for midiLine from currentMidiMin to currentMidiMax
        noteClass = midiLine - 12 * floor(midiLine / 12)
        
        if noteClass = 0
            @getMidiNoteName: midiLine
            Text: startTime - duration * 0.02, "right", midiLine, "half", getMidiNoteName.fullName$
        endif
    endfor
    
    Font size: 10
endif

# ========================================================================================
# STEP 7: Draw Pitch Curve with Line Style Options
# ========================================================================================

appendInfoLine: "Drawing pitch curve (", lineStyle$, ")..."

for i from 1 to numFrames - 1
    if voiced[i] = 1 and voiced[i+1] = 1
        
        # Calculate brightness from intensity
        if useLogLoudness
            @logCompress: intensity[i], intensityMinDb, intensityMaxDb
            brightness = 0.3 + 0.7 * logCompress.result
        else
            @mapToRange: intensity[i], intensityMinDb, intensityMaxDb, 0.3, 1.0
            brightness = mapToRange.result
        endif
        
        # Choose color scheme
        if colorScheme = 1
            @pitchHeightToRGB: midiNote[i], brightness
            r = pitchHeightToRGB.red
            g = pitchHeightToRGB.green
            b = pitchHeightToRGB.blue
            
        elif colorScheme = 2
            @pitchClassToRGB: midiNote[i], brightness
            r = pitchClassToRGB.red
            g = pitchClassToRGB.green
            b = pitchClassToRGB.blue
            
        elif colorScheme = 3
            r = brightness
            g = brightness
            b = brightness
            
        elif colorScheme = 4
            @mapToRange: intensity[i], intensityMinDb, intensityMaxDb, 0, 1
            heatValue = mapToRange.result
            
            if heatValue < 0.33
                r = 0
                g = heatValue * 3
                b = 1 - heatValue * 3
            elif heatValue < 0.66
                localVal = (heatValue - 0.33) * 3
                r = localVal
                g = 1
                b = 0
            else
                localVal = (heatValue - 0.66) * 3
                r = 1
                g = 1 - localVal
                b = 0
            endif
            
        elif colorScheme = 5
            @octaveSpiralRGB: midiNote[i], brightness
            r = octaveSpiralRGB.red
            g = octaveSpiralRGB.green
            b = octaveSpiralRGB.blue
        endif
        
        colourString$ = "{" + string$(r) + ", " + string$(g) + ", " + string$(b) + "}"
        Colour: colourString$
        
        # Apply line style
        if lineStyle = 1
            # Thin continuous line
            Line width: 1.5
            Draw line: t[i], midiNote[i], t[i+1], midiNote[i+1]
            
        elif lineStyle = 2
            # Thickness varies with loudness
            @mapToRange: intensity[i], intensityMinDb, intensityMaxDb, 0.5, 4.5
            Line width: mapToRange.result
            Draw line: t[i], midiNote[i], t[i+1], midiNote[i+1]
            
        elif lineStyle = 3
            # Dots with user-controlled size that varies with loudness
            @mapToRange: intensity[i], intensityMinDb, intensityMaxDb, minDotSize, maxDotSize
            dotSize = mapToRange.result
            Paint circle: colourString$, t[i], midiNote[i], dotSize
        endif
    endif
endfor

# ========================================================================================
# STEP 8: Labels
# ========================================================================================

Colour: "Black"
Line width: 1
Font size: 12

Text top: "yes", "Continuous Pitch over MIDI Grid: " + sound$
Text bottom: "yes", "Time (s)"
Text left: "yes", "MIDI Note"

Font size: 8
Select outer viewport: 0, 10, 0, 6
Text: 9.8, "right", currentMidiMax, "top", colorScheme$
if lineStyle = 3
    Text: 9.8, "right", currentMidiMax - 2, "top", "Dots: " + fixed$(minDotSize, 1) + "-" + fixed$(maxDotSize, 1)
else
    Text: 9.8, "right", currentMidiMax - 2, "top", lineStyle$
endif

# ========================================================================================
# CLEANUP
# ========================================================================================

appendInfoLine: ""
appendInfoLine: "========================================================"
appendInfoLine: "✓ Complete!"
appendInfoLine: "  Frames: ", numFrames
appendInfoLine: "  MIDI: ", currentMidiMin, "-", currentMidiMax
appendInfoLine: "  Line style: ", lineStyle$
if lineStyle = 3
    appendInfoLine: "  Dot size range: ", fixed$(minDotSize, 1), " - ", fixed$(maxDotSize, 1)
endif
if smoothing > 1
    appendInfoLine: "  Smoothing: ", smoothing$
endif
appendInfoLine: ""

removeObject: pitchID
removeObject: intensityID

appendInfoLine: "Done!"