# ============================================================
# Praat AudioTools - OT Grammar Learning from Audio
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   MELODY OT ANALYSIS
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# =============================================================================
# UNIVERSAL MELODY EXTRACTION + OT ANALYSIS
# =============================================================================

form Melody Extraction Settings
    comment Instrument settings
    optionmenu Instrument: 1
        option Violin
        option Vocal
        option Guitar
        option Flute
        option Piano
        option Other
    comment Scale settings
    optionmenu Scale: 1
        option C major
        option G major
        option D major
        option A major
        option E major
        option F major
        option Bb major
        option Eb major
        option A minor
        option E minor
        option D minor
        option Chromatic (no quantization)
    boolean Quantize_to_scale 1
endform

clearinfo

# =============================================================================
# INSTRUMENT-SPECIFIC PITCH DETECTION SETTINGS
# =============================================================================

if instrument = 1
    minPitch = 180
    maxPitch = 800
    timeStep = 0.005
    voicingThreshold = 0.25
    appendInfoLine: "Instrument: Violin"
elsif instrument = 2
    minPitch = 75
    maxPitch = 600
    timeStep = 0.01
    voicingThreshold = 0.35
    appendInfoLine: "Instrument: Vocal"
elsif instrument = 3
    minPitch = 80
    maxPitch = 500
    timeStep = 0.01
    voicingThreshold = 0.30
    appendInfoLine: "Instrument: Guitar"
elsif instrument = 4
    minPitch = 200
    maxPitch = 2000
    timeStep = 0.005
    voicingThreshold = 0.40
    appendInfoLine: "Instrument: Flute"
elsif instrument = 5
    minPitch = 50
    maxPitch = 2000
    timeStep = 0.01
    voicingThreshold = 0.45
    appendInfoLine: "Instrument: Piano"
else
    minPitch = 75
    maxPitch = 600
    timeStep = 0.01
    voicingThreshold = 0.35
    appendInfoLine: "Instrument: Other (default settings)"
endif

# =============================================================================
# SCALE DEFINITION
# =============================================================================

# Define scale pitch classes (0-11)
if scale = 1
    scaleName$ = "C major"
    scalePC$ = "0 2 4 5 7 9 11"
elsif scale = 2
    scaleName$ = "G major"
    scalePC$ = "0 2 4 6 7 9 11"
elsif scale = 3
    scaleName$ = "D major"
    scalePC$ = "0 2 4 6 7 9 11"
elsif scale = 4
    scaleName$ = "A major"
    scalePC$ = "1 2 4 6 7 9 11"
elsif scale = 5
    scaleName$ = "E major"
    scalePC$ = "0 2 4 6 8 9 11"
elsif scale = 6
    scaleName$ = "F major"
    scalePC$ = "0 2 4 5 7 9 10"
elsif scale = 7
    scaleName$ = "Bb major"
    scalePC$ = "0 2 3 5 7 9 10"
elsif scale = 8
    scaleName$ = "Eb major"
    scalePC$ = "0 2 3 5 7 8 10"
elsif scale = 9
    scaleName$ = "A minor"
    scalePC$ = "0 2 3 5 7 8 10"
elsif scale = 10
    scaleName$ = "E minor"
    scalePC$ = "0 2 3 5 7 9 10"
elsif scale = 11
    scaleName$ = "D minor"
    scalePC$ = "0 2 3 5 7 9 10"
else
    scaleName$ = "Chromatic"
    scalePC$ = "0 1 2 3 4 5 6 7 8 9 10 11"
    quantize_to_scale = 0
endif

appendInfoLine: "Scale: ", scaleName$
if quantize_to_scale
    appendInfoLine: "Quantization: ON"
else
    appendInfoLine: "Quantization: OFF"
endif
appendInfoLine: ""

# Parse scale pitch classes into array
@parseScale: scalePC$

# =============================================================================
# MELODY EXTRACTION
# =============================================================================

if numberOfSelected() <> 1
    exitScript: "Please select exactly one Sound object."
endif

soundID = selected("Sound")
selectObject: soundID

pitchID = To Pitch (ac): timeStep, minPitch, 15, "no", 0.03, voicingThreshold, 0.01, 0.35, 0.14, maxPitch
selectObject: pitchID

melody$ = ""
lastMIDI = -999

numFrames = Get number of frames

for frame to numFrames
    f0 = Get value in frame: frame, "Hertz"
    
    if f0 <> undefined and f0 > 0
        midi = 69 + 12 * log2(f0 / 440)
        midiRound = round(midi)
        
        if quantize_to_scale
            pc = midiRound mod 12
            octave = floor(midiRound / 12)
            
            @quantizeToScale: pc
            quantPC = quantized_pc
            
            midiRound = octave * 12 + quantPC
        endif
        
        if midiRound <> lastMIDI
            if melody$ <> ""
                melody$ = melody$ + " "
            endif
            melody$ = melody$ + string$(midiRound)
            lastMIDI = midiRound
        endif
    endif
endfor

selectObject: pitchID
Remove

if melody$ = ""
    melody$ = "60"
endif

appendInfoLine: "=== EXTRACTED MELODY ==="
appendInfoLine: melody$
appendInfoLine: ""

@parseMelody: melody$
numNotes = parsed_count

appendInfoLine: "Number of notes: ", numNotes
appendInfoLine: ""
appendInfoLine: "=== COMPREHENSIVE OT ANALYSIS ==="
appendInfoLine: ""

# Calculate all violations
v_faith = 0
appendInfoLine: "FAITH (Faithfulness): ", v_faith

@countLeaps
v_leap = result
appendInfoLine: "*LEAP (Jumps >5 semitones): ", v_leap

@countTritones
v_tritone = result
appendInfoLine: "*TRITONE (Aug4/Dim5 intervals): ", v_tritone

@countNonSteps
v_nonstep = result
appendInfoLine: "STEP (Penalize >2 semitones): ", v_nonstep

@countRepeats
v_repeat = result
appendInfoLine: "*REPEAT (Repeated notes): ", v_repeat

@countSemitones
v_semitones = result
appendInfoLine: "SEMITONE-MOTION (Semitone intervals): ", v_semitones

@analyzeRange
v_wide = range_wide
v_narrow = range_narrow
appendInfoLine: "*WIDE-RANGE (Range >octave): ", v_wide
appendInfoLine: "*NARROW-RANGE (Range <5th): ", v_narrow

@countNonScale
v_nonscale = result
appendInfoLine: "*NON-SCALE (Outside ", scaleName$, "): ", v_nonscale

@checkCadence
v_cadence = result
appendInfoLine: "CADENCE (Proper ending): ", v_cadence

@checkTonicEnding
v_end = result
appendInfoLine: "*END (Non-tonic ending): ", v_end

@analyzePeakPosition
v_peak_early = peak_early
v_peak_late = peak_late
appendInfoLine: "*PEAK-EARLY (Climax 1st half): ", v_peak_early
appendInfoLine: "*PEAK-LATE (Climax 2nd half): ", v_peak_late

@checkArcShape
v_arc = result
appendInfoLine: "ARC (Arch-shaped contour): ", v_arc

@countDirectionChanges
v_dirchange = result
appendInfoLine: "*DIR-CHANGE (Many direction changes): ", v_dirchange

@checkMonotonic
v_monotonic = result
appendInfoLine: "MONOTONIC (Consistent direction): ", v_monotonic

total = v_leap + v_tritone + v_nonstep + v_repeat + v_semitones + v_wide + v_narrow + v_nonscale + v_cadence + v_end + v_peak_early + v_peak_late + v_arc + v_dirchange + v_monotonic

appendInfoLine: ""
appendInfoLine: "=========================================="
appendInfoLine: "TOTAL VIOLATIONS: ", total
appendInfoLine: "=========================================="

# =============================================================================
# PROCEDURES
# =============================================================================

procedure parseScale: .scaleString$
    .remaining$ = .scaleString$ + " "
    .count = 0
    
    while index(.remaining$, " ") > 0
        .spacePos = index(.remaining$, " ")
        .token$ = left$(.remaining$, .spacePos - 1)
        .remaining$ = mid$(.remaining$, .spacePos + 1, 10000)
        
        if .token$ <> ""
            .count = .count + 1
            scalePCs[.count] = number(.token$)
        endif
    endwhile
    
    numScalePCs = .count
endproc

procedure quantizeToScale: .pc
    .minDist = 12
    .closestPC = 0
    
    for .i to numScalePCs
        .scalePC = scalePCs[.i]
        .dist1 = abs(.pc - .scalePC)
        .dist2 = abs(.pc - (.scalePC + 12))
        .dist3 = abs(.pc - (.scalePC - 12))
        
        .dist = .dist1
        if .dist2 < .dist
            .dist = .dist2
        endif
        if .dist3 < .dist
            .dist = .dist3
        endif
        
        if .dist < .minDist
            .minDist = .dist
            .closestPC = .scalePC
        endif
    endfor
    
    quantized_pc = .closestPC
endproc

procedure parseMelody: .melody$
    .remaining$ = .melody$ + " "
    .count = 0
    
    while index(.remaining$, " ") > 0
        .spacePos = index(.remaining$, " ")
        .token$ = left$(.remaining$, .spacePos - 1)
        .remaining$ = mid$(.remaining$, .spacePos + 1, 10000)
        
        if .token$ <> ""
            .count = .count + 1
            notes[.count] = number(.token$)
        endif
    endwhile
    
    parsed_count = .count
endproc

procedure countLeaps
    .leaps = 0
    for .i from 2 to numNotes
        .interval = abs(notes[.i] - notes[.i-1])
        if .interval > 5
            .leaps = .leaps + 1
        endif
    endfor
    result = .leaps
endproc

procedure countTritones
    .tritones = 0
    for .i from 2 to numNotes
        .interval = abs(notes[.i] - notes[.i-1])
        if .interval = 6
            .tritones = .tritones + 1
        endif
    endfor
    result = .tritones
endproc

procedure countNonSteps
    .nonsteps = 0
    for .i from 2 to numNotes
        .interval = abs(notes[.i] - notes[.i-1])
        if .interval > 2
            .nonsteps = .nonsteps + 1
        endif
    endfor
    result = .nonsteps
endproc

procedure countRepeats
    .repeats = 0
    for .i from 2 to numNotes
        if notes[.i] = notes[.i-1]
            .repeats = .repeats + 1
        endif
    endfor
    result = .repeats
endproc

procedure countSemitones
    .count = 0
    for .i from 2 to numNotes
        .interval = abs(notes[.i] - notes[.i-1])
        if .interval = 1
            .count = .count + 1
        endif
    endfor
    result = .count
endproc

procedure analyzeRange
    .min = notes[1]
    .max = notes[1]
    
    for .i from 2 to numNotes
        if notes[.i] < .min
            .min = notes[.i]
        endif
        if notes[.i] > .max
            .max = notes[.i]
        endif
    endfor
    
    .range = .max - .min
    
    if .range > 12
        range_wide = 1
    else
        range_wide = 0
    endif
    
    if .range < 7
        range_narrow = 1
    else
        range_narrow = 0
    endif
endproc

procedure countNonScale
    .violations = 0
    
    for .i to numNotes
        .pc = notes[.i] mod 12
        .inScale = 0
        
        for .j to numScalePCs
            if .pc = scalePCs[.j]
                .inScale = 1
            endif
        endfor
        
        if .inScale = 0
            .violations = .violations + 1
        endif
    endfor
    
    result = .violations
endproc

procedure checkCadence
    if numNotes < 2
        result = 1
        goto DONE_CAD
    endif
    
    .last = notes[numNotes] mod 12
    .penult = notes[numNotes - 1] mod 12
    
    .tonic = scalePCs[1]
    
    if (.penult = 11 and .last = .tonic) or (.penult = 7 and .last = .tonic) or (.penult = 2 and .last = .tonic)
        result = 0
    else
        result = 1
    endif
    
    label DONE_CAD
endproc

procedure checkTonicEnding
    .last = notes[numNotes] mod 12
    .tonic = scalePCs[1]
    if .last <> .tonic
        result = 1
    else
        result = 0
    endif
endproc

procedure analyzePeakPosition
    .maxNote = notes[1]
    .maxPos = 1
    
    for .i from 2 to numNotes
        if notes[.i] > .maxNote
            .maxNote = notes[.i]
            .maxPos = .i
        endif
    endfor
    
    .midpoint = numNotes / 2
    
    if .maxPos <= .midpoint
        peak_early = 1
    else
        peak_early = 0
    endif
    
    if .maxPos > .midpoint
        peak_late = 1
    else
        peak_late = 0
    endif
endproc

procedure checkArcShape
    if numNotes < 3
        result = 0
        goto DONE_ARC
    endif
    
    .maxNote = notes[1]
    .maxPos = 1
    
    for .i from 2 to numNotes
        if notes[.i] > .maxNote
            .maxNote = notes[.i]
            .maxPos = .i
        endif
    endfor
    
    .ascendingViolations = 0
    for .i from 2 to .maxPos
        if notes[.i] < notes[.i-1]
            .ascendingViolations = .ascendingViolations + 1
        endif
    endfor
    
    .descendingViolations = 0
    for .i from (.maxPos + 1) to numNotes
        if notes[.i] > notes[.i-1]
            .descendingViolations = .descendingViolations + 1
        endif
    endfor
    
    .totalViolations = .ascendingViolations + .descendingViolations
    if .totalViolations > (numNotes / 4)
        result = 1
    else
        result = 0
    endif
    
    label DONE_ARC
endproc

procedure countDirectionChanges
    .changes = 0
    
    if numNotes < 3
        result = 0
        goto DONE_DIR
    endif
    
    for .i from 3 to numNotes
        .prev_dir = notes[.i-1] - notes[.i-2]
        .curr_dir = notes[.i] - notes[.i-1]
        
        if .prev_dir > 0 and .curr_dir < 0
            .changes = .changes + 1
        elsif .prev_dir < 0 and .curr_dir > 0
            .changes = .changes + 1
        endif
    endfor
    
    if .changes > (numNotes / 3)
        result = 1
    else
        result = 0
    endif
    
    label DONE_DIR
endproc

procedure checkMonotonic
    if numNotes < 2
        result = 0
        goto DONE_MONO
    endif
    
    .ascending = 0
    .descending = 0
    
    for .i from 2 to numNotes
        if notes[.i] > notes[.i-1]
            .ascending = .ascending + 1
        elsif notes[.i] < notes[.i-1]
            .descending = .descending + 1
        endif
    endfor
    
    .total_moves = .ascending + .descending
    .dominant = .ascending
    if .descending > .ascending
        .dominant = .descending
    endif
    
    if .total_moves > 0
        .ratio = .dominant / .total_moves
        if .ratio < 0.6
            result = 1
        else
            result = 0
        endif
    else
        result = 0
    endif
    
    label DONE_MONO
endproc