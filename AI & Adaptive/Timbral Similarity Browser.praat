# ============================================================
# Praat AudioTools - Timbral Similarity Browser
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Timbral Similarity Browser
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Timbral Similarity Browser
    comment Loading Options
    integer max_files_to_load 0 (= load all files)
    comment Playback Options
    boolean auto_play 1
endform

clearinfo
writeInfoLine: "===== TIMBRAL SIMILARITY BROWSER ====="
appendInfoLine: ""

# ========== STEP 1: LOAD SOUNDS ==========
appendInfoLine: "STEP 1: Loading sounds from folder"
appendInfoLine: "===================================="

directory$ = chooseDirectory$: "Select folder containing .wav files"
if directory$ = ""
    exitScript: "No folder selected."
endif

if right$(directory$, 1) <> "/"
    directory$ = directory$ + "/"
endif

appendInfoLine: "Loading from: ", directory$

files$# = fileNames_caseInsensitive$# (directory$ + "*.wav")
nFiles = size(files$#)

if nFiles = 0
    exitScript: "No .wav files found in folder."
endif

appendInfoLine: "Found ", nFiles, " file(s) in folder"

if max_files_to_load > 0 and max_files_to_load < nFiles
    nFiles = max_files_to_load
    appendInfoLine: "Will load only first ", nFiles, " file(s)"
endif

appendInfoLine: ""

loadCount = 0

for i from 1 to nFiles
    f$ = files$# [i]
    appendInfoLine: "[", i, "/", nFiles, "] Loading: ", f$
    
    nocheck Read from file: directory$ + f$
    
    if selected("Sound") = undefined
        appendInfoLine: "    FAILED to load"
    else
        loadCount = loadCount + 1
        s_id = selected("Sound")
        name$ = selected$("Sound")
        nCh = Get number of channels
        
        if nCh > 1
            appendInfoLine: "    OK (stereo - converting to mono)"
            Convert to mono
            mono_id = selected("Sound")
            select s_id
            Remove
            select mono_id
            Rename: name$
            sound'loadCount' = mono_id
        else
            appendInfoLine: "    OK (mono)"
            sound'loadCount' = s_id
        endif
        
        appendInfoLine: "    Stored as sound", loadCount, " (ID=", sound'loadCount', ")"
    endif
endfor

appendInfoLine: ""
appendInfoLine: "Successfully loaded: ", loadCount, " sounds (all mono)"

if loadCount = 0
    exitScript: "No sounds were loaded successfully."
endif

number_of_sounds = loadCount

appendInfoLine: ""
appendInfoLine: ""

# ========== STEP 2: VERIFY SOUND IDS ==========
appendInfoLine: "STEP 2: Verifying sound IDs"
appendInfoLine: "============================"

for i to number_of_sounds
    select sound'i'
    name$ = selected$("Sound")
    appendInfoLine: "  [", i, "] ID=", sound'i', " Name=", name$
endfor

appendInfoLine: ""

# ========== STEP 3: MFCC ANALYSIS ==========
appendInfoLine: "STEP 3: MFCC Analysis"
appendInfoLine: "====================="

appendInfoLine: "Creating MFCC for each sound..."
appendInfoLine: "Parameters: 12 coefficients, window=0.015s, step=0.005s"
appendInfoLine: ""

analyzed = 0
failed_mfcc = 0

for i from 1 to number_of_sounds
    select sound'i'
    name$ = selected$("Sound")
    
    appendInfoLine: "[", i, "/", number_of_sounds, "] ", name$
    
    dur = Get total duration
    
    if dur < 0.02
        appendInfoLine: "    SKIPPED (too short)"
        failed_mfcc = failed_mfcc + 1
        goto NEXT_SOUND
    endif
    
    To MFCC: 12, 0.015, 0.005, 100, 100, 0.0
    mfcc'i' = selected("MFCC")
    
    select mfcc'i'
    nFrames = Get number of frames
    appendInfoLine: "    OK (", nFrames, " frames)"
    analyzed = analyzed + 1
    
    label NEXT_SOUND
endfor

appendInfoLine: ""
appendInfoLine: "Successfully analyzed: ", analyzed
appendInfoLine: "Failed/Skipped: ", failed_mfcc

if analyzed = 0
    exitScript: "No sounds were successfully analyzed."
endif

n = analyzed

appendInfoLine: ""
appendInfoLine: ""

# ========== STEP 4: SIMILARITY COMPUTATION ==========
appendInfoLine: "STEP 4: Computing Similarity"
appendInfoLine: "============================="

appendInfoLine: "Computing mean MFCC vectors..."

Create TableOfReal: "MFCC_Features", n, 12
featureTable = selected("TableOfReal")

for i from 1 to n
    select mfcc'i'
    nFrames = Get number of frames
    
    select sound'i'
    name$ = selected$("Sound")
    
    appendInfoLine: "  [", i, "] ", name$
    
    for coef from 1 to 12
        sum = 0
        count = 0
        
        select mfcc'i'
        for frame from 1 to nFrames
            value = Get value in frame: frame, coef
            if value <> undefined
                sum = sum + value
                count = count + 1
            endif
        endfor
        
        if count > 0
            mean_value = sum / count
        else
            mean_value = 0
        endif
        
        select featureTable
        Set value: i, coef, mean_value
    endfor
    
    select featureTable
    Set row label (index): i, name$
endfor

appendInfoLine: ""
appendInfoLine: "Computing pairwise distances..."

Create TableOfReal: "Distance_Matrix", n, n
distMatrix = selected("TableOfReal")

for i from 1 to n
    select sound'i'
    name$ = selected$("Sound")
    
    select distMatrix
    Set row label (index): i, name$
    Set column label (index): i, name$
endfor

for i from 1 to n
    for j from i to n
        dist = 0
        
        select featureTable
        for coef from 1 to 12
            val_i = Get value: i, coef
            val_j = Get value: j, coef
            diff = val_i - val_j
            dist = dist + diff * diff
        endfor
        
        dist = sqrt(dist)
        
        select distMatrix
        Set value: i, j, dist
        Set value: j, i, dist
    endfor
endfor

appendInfoLine: "Creating nearest-neighbor similarity path..."

visited# = zero# (n)
path# = zero# (n)
current = 1
path#[1] = 1
visited#[1] = 1

for step from 2 to n
    min_dist = 1e30
    next_sound = 0
    
    select distMatrix
    for candidate from 1 to n
        if visited#[candidate] = 0
            dist = Get value: current, candidate
            if dist < min_dist
                min_dist = dist
                next_sound = candidate
            endif
        endif
    endfor
    
    if next_sound > 0
        path#[step] = next_sound
        visited#[next_sound] = 1
        current = next_sound
    endif
endfor

appendInfoLine: ""
appendInfoLine: "===== SIMILARITY PATH ====="
appendInfoLine: "(Ordered by timbral similarity)"
appendInfoLine: ""

for i from 1 to n
    idx = path#[i]
    select sound'idx'
    name$ = selected$("Sound")
    appendInfoLine: "  ", i, ". ", name$
endfor

appendInfoLine: ""
appendInfoLine: ""

# ========== STEP 5: CONCATENATE IN SIMILARITY ORDER ==========
appendInfoLine: "STEP 5: Concatenating sounds in similarity order"
appendInfoLine: "================================================="

first_idx = path#[1]
select sound'first_idx'

for i from 2 to n
    idx = path#[i]
    plus sound'idx'
endfor

appendInfoLine: "Concatenating..."
Concatenate
outputSound = selected("Sound")
Rename: "Timbral_Similarity_Path"

totalDur = Get total duration
appendInfoLine: "Output duration: ", fixed$(totalDur, 2), " seconds"

appendInfoLine: ""

# ========== STEP 6: CLEANUP ==========
appendInfoLine: "STEP 6: Cleanup"
appendInfoLine: "==============="

appendInfoLine: "Removing temporary objects..."

for i from 1 to n
    select sound'i'
    Remove
    
    select mfcc'i'
    Remove
endfor

select featureTable
Remove

select distMatrix
Remove

appendInfoLine: "Cleanup complete!"
appendInfoLine: ""

# ========== STEP 7: PLAY ==========
if auto_play
    appendInfoLine: "Playing concatenated result..."
    appendInfoLine: "(Playback is asynchronous - script will complete while playing)"
    appendInfoLine: ""
    select outputSound
    Play
endif

appendInfoLine: "===== COMPLETE ====="
appendInfoLine: ""
appendInfoLine: "Only the concatenated output remains:"
appendInfoLine: "  - Sound Timbral_Similarity_Path (", fixed$(totalDur, 2), " sec)"
appendInfoLine: ""
appendInfoLine: "All temporary objects have been removed."

select outputSound