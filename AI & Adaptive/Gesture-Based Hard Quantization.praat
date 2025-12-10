# ============================================================
# Praat AudioTools - Gesture-Based Hard Quantization
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Gesture-Based Hard Quantization
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Gesture Quantization Parameters
    comment ═══════════════════════════════════════
    comment PRESETS (select one, or choose Custom)
    comment ═══════════════════════════════════════
    optionmenu Preset 2
        option Maximum Variety (k=10, pen=0.8, seg=30)
        option Balanced (k=7, pen=0.7, seg=20)
        option Coherent (k=3, pen=0.3, seg=12)
        option Minimal (k=1, pen=0.0, seg=8)
        option Custom (use values below)
    comment ═══════════════════════════════════════
    comment CUSTOM SETTINGS (only used if Preset = Custom)
    comment ═══════════════════════════════════════
    positive Number_of_segments 20
    positive K_best_matches 7
    positive Repetition_penalty 0.5
    comment ═══════════════════════════════════════
    comment FEATURE EXTRACTION
    comment ═══════════════════════════════════════
    positive N_time_samples 50
    positive Pitch_floor 75
    positive Pitch_ceiling 600
    comment ═══════════════════════════════════════
    comment AUDIO PROCESSING
    comment ═══════════════════════════════════════
    positive Target_sample_rate 44100
    comment ═══════════════════════════════════════
    comment OUTPUT
    comment ═══════════════════════════════════════
    boolean Verbose_output 1
    boolean Play_result 1
endform

################################################################################
# APPLY PRESET
################################################################################

if preset = 1
    number_of_segments = 30
    k_best_matches = 10
    repetition_penalty = 0.8
    preset$ = "Maximum Variety"
elsif preset = 2
    number_of_segments = 20
    k_best_matches = 7
    repetition_penalty = 0.7
    preset$ = "Balanced"
elsif preset = 3
    number_of_segments = 12
    k_best_matches = 3
    repetition_penalty = 0.3
    preset$ = "Coherent"
elsif preset = 4
    number_of_segments = 8
    k_best_matches = 1
    repetition_penalty = 0.0
    preset$ = "Minimal"
else
    preset$ = "Custom"
endif

################################################################################
# DIRECTORY SELECTION
################################################################################

clearinfo

folder_path$ = chooseDirectory$("Select folder containing sound files (first file = reference)")

if folder_path$ = ""
    exitScript: "No folder selected. Script cancelled."
endif

if right$(folder_path$, 1) <> "/" and right$(folder_path$, 1) <> "\"
    if environment$("os") = "windows"
        folder_path$ = folder_path$ + "\"
    else
        folder_path$ = folder_path$ + "/"
    endif
endif

################################################################################
# HELPER PROCEDURES
################################################################################

procedure log: .message$
    if verbose_output
        appendInfoLine: .message$
    endif
endproc

procedure normalizeIntensity: .soundID
    selectObject: .soundID
    Scale intensity: 70
endproc

procedure convertToMono: .soundID
    selectObject: .soundID
    .nChannels = Get number of channels
    if .nChannels > 1
        .mono = Convert to mono
        removeObject: .soundID
        .soundID = .mono
    endif
    .result = .soundID
endproc

procedure resampleIfNeeded: .soundID, .targetRate
    selectObject: .soundID
    .currentRate = Get sampling frequency
    if .currentRate != .targetRate
        .resampled = Resample: .targetRate, 50
        removeObject: .soundID
        .soundID = .resampled
    endif
    .result = .soundID
endproc

procedure extractFeatureVector: .soundID, .nSamples
    selectObject: .soundID
    .dur = Get total duration
    .start = Get start time
    .end = Get end time
    
    .pitch = To Pitch: 0.01, pitch_floor, pitch_ceiling
    
    selectObject: .soundID
    .intensity = To Intensity: 100, 0, "yes"
    
    .timeStep = .dur / (.nSamples - 1)
    
    for .i to .nSamples
        .time = .start + (.i - 1) * .timeStep
        
        selectObject: .pitch
        .f0 = Get value at time: .time, "Hertz", "Linear"
        if .f0 = undefined
            .f0 = 0
        endif
        feature_vector[.i] = .f0
        
        selectObject: .intensity
        .db = Get value at time: .time, "Cubic"
        if .db = undefined
            .db = 0
        endif
        feature_vector[.nSamples + .i] = .db
    endfor
    
    removeObject: .pitch, .intensity
endproc

procedure normalizeFeatures: .vectorLength, .minPitch, .maxPitch, .minDB, .maxDB
    for .i to n_time_samples
        if .maxPitch > .minPitch
            feature_vector[.i] = (feature_vector[.i] - .minPitch) / (.maxPitch - .minPitch)
        else
            feature_vector[.i] = 0
        endif
    endfor
    
    for .i from n_time_samples + 1 to .vectorLength
        if .maxDB > .minDB
            feature_vector[.i] = (feature_vector[.i] - .minDB) / (.maxDB - .minDB)
        else
            feature_vector[.i] = 0
        endif
    endfor
endproc

procedure euclideanDistance: .vectorLength
    .distance = 0
    for .i to .vectorLength
        .diff = feature_vector[.i] - dict_vector[.i]
        .distance += .diff * .diff
    endfor
    .distance = sqrt(.distance)
endproc

procedure findKBestMatches: .nPatterns, .k, .lastChoice
    for .i to .nPatterns
        candidate_dist[.i] = 10000
        candidate_idx[.i] = .i
    endfor
    
    for .dictIdx to .nPatterns
        for .j to vectorLength
            dict_vector[.j] = dict_features[.dictIdx, .j]
        endfor
        
        @euclideanDistance: vectorLength
        .dist = euclideanDistance.distance
        
        if .dictIdx = .lastChoice and repetition_penalty > 0
            .dist = .dist * (1 + repetition_penalty)
        endif
        
        candidate_dist[.dictIdx] = .dist
    endfor
    
    for .i to .k
        .minIdx = .i
        .minDist = candidate_dist[.i]
        
        for .j from .i + 1 to .nPatterns
            if candidate_dist[.j] < .minDist
                .minDist = candidate_dist[.j]
                .minIdx = .j
            endif
        endfor
        
        if .minIdx <> .i
            .tempDist = candidate_dist[.i]
            .tempIdx = candidate_idx[.i]
            candidate_dist[.i] = candidate_dist[.minIdx]
            candidate_idx[.i] = candidate_idx[.minIdx]
            candidate_dist[.minIdx] = .tempDist
            candidate_idx[.minIdx] = .tempIdx
        endif
    endfor
    
    if .k = 1
        .chosenIdx = candidate_idx[1]
        .chosenDist = candidate_dist[1]
    else
        .randomChoice = randomInteger(1, .k)
        .chosenIdx = candidate_idx[.randomChoice]
        .chosenDist = candidate_dist[.randomChoice]
    endif
    
    .selectedIndex = .chosenIdx
    .selectedDistance = .chosenDist
endproc

################################################################################
# MAIN SCRIPT
################################################################################

if verbose_output
    appendInfoLine: "═══════════════════════════════════════════════════════"
    appendInfoLine: "  Gesture-Based Hard Quantization"
    appendInfoLine: "═══════════════════════════════════════════════════════"
    appendInfoLine: ""
    appendInfoLine: "Preset: ", preset$
    appendInfoLine: "  • Segments: ", number_of_segments
    appendInfoLine: "  • K-best: ", k_best_matches
    appendInfoLine: "  • Repetition penalty: ", fixed$(repetition_penalty, 2)
    appendInfoLine: ""
endif

@log: "Reading folder: " + folder_path$
.fileList = Create Strings as file list: "fileList", folder_path$ + "*.wav"
.nFiles = Get number of strings

if .nFiles < 2
    selectObject: .fileList
    Remove
    exitScript: "Error: Need at least 2 sound files (1 reference + 1 dictionary sound)"
endif

@log: "Found " + string$(.nFiles) + " sound files"
@log: ""

vectorLength = 2 * n_time_samples
nDictSounds = .nFiles - 1

for .i to nDictSounds
    for .j to vectorLength
        dict_features[.i, .j] = 0
    endfor
endfor

################################################################################
# LOAD AND PREPROCESS ALL SOUNDS
################################################################################

@log: "Loading and preprocessing sounds..."
@log: ""

minPitch = 10000
maxPitch = 0
minDB = 10000
maxDB = -10000

for .fileIdx to .nFiles
    selectObject: .fileList
    .filename$ = Get string: .fileIdx
    .filepath$ = folder_path$ + .filename$
    
    @log: "Loading: " + .filename$
    
    .sound = Read from file: .filepath$
    
    @convertToMono: .sound
    .sound = convertToMono.result
    
    @resampleIfNeeded: .sound, target_sample_rate
    .sound = resampleIfNeeded.result
    
    @normalizeIntensity: .sound
    
    soundID[.fileIdx] = .sound
    
    selectObject: .sound
    soundName$[.fileIdx] = selected$("Sound")
    
    @log: "  Preprocessed: " + soundName$[.fileIdx]
endfor

@log: ""

################################################################################
# EXTRACT DICTIONARY FEATURES
################################################################################

@log: "Building gesture dictionary (" + string$(nDictSounds) + " gestures)..."
@log: ""

for .dictIdx to nDictSounds
    .soundIdx = .dictIdx + 1
    .sound = soundID[.soundIdx]
    
    @log: "  Dictionary " + string$(.dictIdx) + ": " + soundName$[.soundIdx]
    
    @extractFeatureVector: .sound, n_time_samples
    
    for .j to vectorLength
        dict_features[.dictIdx, .j] = feature_vector[.j]
        
        if .j <= n_time_samples
            if feature_vector[.j] > 0
                if feature_vector[.j] < minPitch
                    minPitch = feature_vector[.j]
                endif
                if feature_vector[.j] > maxPitch
                    maxPitch = feature_vector[.j]
                endif
            endif
        else
            if feature_vector[.j] < minDB
                minDB = feature_vector[.j]
            endif
            if feature_vector[.j] > maxDB
                maxDB = feature_vector[.j]
            endif
        endif
    endfor
endfor

@log: ""
@log: "Normalization ranges:"
@log: "  Pitch: " + fixed$(minPitch, 1) + " - " + fixed$(maxPitch, 1) + " Hz"
@log: "  Intensity: " + fixed$(minDB, 1) + " - " + fixed$(maxDB, 1) + " dB"
@log: ""

@log: "Normalizing dictionary features..."
for .dictIdx to nDictSounds
    for .j to vectorLength
        feature_vector[.j] = dict_features[.dictIdx, .j]
    endfor
    
    @normalizeFeatures: vectorLength, minPitch, maxPitch, minDB, maxDB
    
    for .j to vectorLength
        dict_features[.dictIdx, .j] = feature_vector[.j]
    endfor
endfor

@log: "Dictionary ready."
@log: ""

################################################################################
# SEGMENT REFERENCE SOUND
################################################################################

@log: "Processing reference sound: " + soundName$[1]
@log: "Segmenting into " + string$(number_of_segments) + " equal parts..."
@log: ""

refSound = soundID[1]
selectObject: refSound
refDur = Get total duration
refStart = Get start time
segmentDur = refDur / number_of_segments

@log: "Segment duration: " + fixed$(segmentDur, 3) + " seconds"
@log: ""

for .segIdx to number_of_segments
    bestMatch[.segIdx] = 0
    bestDistance[.segIdx] = 10000
endfor

lastChoice = 0

################################################################################
# FIND CLOSEST MATCH FOR EACH SEGMENT
################################################################################

@log: "Finding closest dictionary matches..."
@log: ""

for .segIdx to number_of_segments
    .segStart = refStart + (.segIdx - 1) * segmentDur
    .segEnd = .segStart + segmentDur
    
    selectObject: refSound
    .segment = Extract part: .segStart, .segEnd, "rectangular", 1, "no"
    
    @extractFeatureVector: .segment, n_time_samples
    @normalizeFeatures: vectorLength, minPitch, maxPitch, minDB, maxDB
    
    @findKBestMatches: nDictSounds, k_best_matches, lastChoice
    
    .bestIdx = findKBestMatches.selectedIndex
    .minDist = findKBestMatches.selectedDistance
    
    bestMatch[.segIdx] = .bestIdx
    bestDistance[.segIdx] = .minDist
    
    lastChoice = .bestIdx
    
    .matchSoundIdx = .bestIdx + 1
    
    if k_best_matches > 1
        @log: "  Segment " + string$(.segIdx) + " → " + soundName$[.matchSoundIdx] + " (dist: " + fixed$(.minDist, 4) + ")"
    else
        @log: "  Segment " + string$(.segIdx) + " → " + soundName$[.matchSoundIdx] + " (dist: " + fixed$(.minDist, 4) + ", deterministic)"
    endif
    
    removeObject: .segment
endfor

@log: ""

################################################################################
# CONSTRUCT OUTPUT SOUND
################################################################################

@log: "Building quantized output sound..."
@log: "Trimming dictionary sounds to segment duration..."
@log: ""

for .segIdx to number_of_segments
    .dictIdx = bestMatch[.segIdx]
    .soundIdx = .dictIdx + 1
    .sound = soundID[.soundIdx]
    
    selectObject: .sound
    .dictDur = Get total duration
    .dictStart = Get start time
    
    if .dictDur >= segmentDur
        .extractedPart = Extract part: .dictStart, .dictStart + segmentDur, "rectangular", 1, "no"
    else
        .extractedPart = Copy: "temp_segment"
    endif
    
    if .segIdx = 1
        selectObject: .extractedPart
        output = Copy: "quantized"
        removeObject: .extractedPart
    else
        selectObject: output, .extractedPart
        .temp = Concatenate
        removeObject: output, .extractedPart
        output = .temp
    endif
endfor

selectObject: output
if preset = 5
    .outputName$ = "gesture_quantized_Custom_" + soundName$[1]
else
    .outputName$ = "gesture_quantized_" + preset$ + "_" + soundName$[1]
endif
.outputName$ = replace$(.outputName$, " ", "_", 0)
Rename: .outputName$

selectObject: output
.outputDur = Get total duration

@log: "Output sound created: " + .outputName$
@log: "Output duration: " + fixed$(.outputDur, 3) + " seconds"
@log: "Reference duration: " + fixed$(refDur, 3) + " seconds"
@log: ""

################################################################################
# STATISTICS
################################################################################

if verbose_output
    appendInfoLine: "════════════════════════════════════════════════════════"
    appendInfoLine: "  SUMMARY STATISTICS"
    appendInfoLine: "════════════════════════════════════════════════════════"
    appendInfoLine: ""
    appendInfoLine: "Preset: ", preset$
    appendInfoLine: "Reference sound: ", soundName$[1]
    appendInfoLine: "Dictionary size: ", nDictSounds, " gestures"
    appendInfoLine: ""
    appendInfoLine: "Parameters:"
    appendInfoLine: "  • Segments: ", number_of_segments
    appendInfoLine: "  • Segment duration: ", fixed$(segmentDur, 3), " seconds"
    appendInfoLine: "  • K-best matches: ", k_best_matches
    appendInfoLine: "  • Repetition penalty: ", fixed$(repetition_penalty, 2)
    appendInfoLine: "  • Feature dimension: ", vectorLength
    appendInfoLine: ""
    appendInfoLine: "Duration comparison:"
    appendInfoLine: "  Reference: ", fixed$(refDur, 3), " seconds"
    appendInfoLine: "  Output:    ", fixed$(.outputDur, 3), " seconds"
    appendInfoLine: ""
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "DISTANCE STATISTICS:"
    appendInfoLine: "------------------------------------------------------------"
    
    .sumDist = 0
    .minDist = bestDistance[1]
    .maxDist = bestDistance[1]
    
    for .segIdx to number_of_segments
        .sumDist += bestDistance[.segIdx]
        if bestDistance[.segIdx] < .minDist
            .minDist = bestDistance[.segIdx]
        endif
        if bestDistance[.segIdx] > .maxDist
            .maxDist = bestDistance[.segIdx]
        endif
    endfor
    .meanDist = .sumDist / number_of_segments
    
    .sumSqDiff = 0
    for .segIdx to number_of_segments
        .diff = bestDistance[.segIdx] - .meanDist
        .sumSqDiff += .diff * .diff
    endfor
    .stdDist = sqrt(.sumSqDiff / number_of_segments)
    
    appendInfoLine: "  Mean distance:    ", fixed$(.meanDist, 4)
    appendInfoLine: "  Std deviation:    ", fixed$(.stdDist, 4)
    appendInfoLine: "  Min distance:     ", fixed$(.minDist, 4)
    appendInfoLine: "  Max distance:     ", fixed$(.maxDist, 4)
    appendInfoLine: ""
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "GESTURE USAGE:"
    appendInfoLine: "------------------------------------------------------------"
    
    .uniqueCount = 0
    for .dictIdx to nDictSounds
        .count = 0
        for .segIdx to number_of_segments
            if bestMatch[.segIdx] = .dictIdx
                .count += 1
            endif
        endfor
        if .count > 0
            .uniqueCount += 1
            .soundIdx = .dictIdx + 1
            appendInfoLine: "  ", soundName$[.soundIdx], ": ", .count, " times"
        endif
    endfor
    
    .diversityPercent = (.uniqueCount / nDictSounds) * 100
    
    appendInfoLine: ""
    appendInfoLine: "Diversity: ", .uniqueCount, " / ", nDictSounds, " gestures used (", fixed$(.diversityPercent, 1), "%)"
    appendInfoLine: ""
    
    appendInfoLine: "════════════════════════════════════════════════════════"
    appendInfoLine: "PRESET GUIDE:"
    appendInfoLine: "════════════════════════════════════════════════════════"
    appendInfoLine: "• Maximum Variety: Explore full dictionary, high diversity"
    appendInfoLine: "• Balanced: Good mix of variety and coherence (recommended)"
    appendInfoLine: "• Coherent: More repetition, thematic blocks"
    appendInfoLine: "• Minimal: Simple quantization, clear gesture blocks"
    appendInfoLine: "• Custom: Full control over all parameters"
    appendInfoLine: ""
    appendInfoLine: "════════════════════════════════════════════════════════"
    appendInfoLine: "  SUCCESS!"
    appendInfoLine: "  Created: ", .outputName$
    appendInfoLine: "════════════════════════════════════════════════════════"
endif

################################################################################
# CLEANUP
################################################################################

@log: "Cleaning up temporary objects..."

for .i to .nFiles
    selectObject: soundID[.i]
    Remove
endfor

removeObject: .fileList

@log: "Cleanup complete."
@log: ""

if verbose_output
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: "Only the result remains in Praat:"
    selectObject: output
    .finalName$ = selected$("Sound")
    appendInfoLine: "  ", .finalName$
    appendInfoLine: "------------------------------------------------------------"
    appendInfoLine: ""
endif

################################################################################
# SELECT OUTPUT AND PLAY
################################################################################

selectObject: output

if play_result
    Play
endif