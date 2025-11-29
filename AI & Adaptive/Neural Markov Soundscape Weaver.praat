# ============================================================
# Praat AudioTools - Neural Markov Soundscape Weaver
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Markov Soundscape Weaver
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Markov Soundscape Weaver
# - Deconstructs audio into grains.
# - Learns "Texture States" using K-Means Clustering.
# - Learns "Temporal Grammar" (Transition Probabilities) using Markov Chains.
# - Generates a new, infinite stream that follows the natural flow of the original.

form Neural Markov Soundscape Weaver
    comment === Analysis ===
    positive grain_size_ms 80
    integer  number_of_states 5
    
    comment === Synthesis ===
    positive output_duration_sec 15.0
    
    comment === Output ===
    boolean  play_result 1
endform

# ===== 1. SETUP =====
nSelected = numberOfSelected("Sound")
if nSelected <> 1
    exitScript: "Please select exactly one Sound object."
endif

snd = selected("Sound")
sndName$ = selected$("Sound")

selectObject: snd
dur = Get total duration
fs  = Get sampling frequency
nch = Get number of channels

# Work on Copy
selectObject: snd
Copy: "Analysis_Work"
workSnd = selected("Sound")

if nch > 1
    selectObject: workSnd
    Convert to mono
    monoSnd = selected("Sound")
    selectObject: workSnd
    Remove
    workSnd = monoSnd
    selectObject: workSnd
    Rename: "Analysis_Work"
endif

# Check Duration
grainSec = grain_size_ms / 1000
if dur < grainSec * 4
    removeObject: workSnd
    exitScript: "Sound is too short for analysis."
endif

# ===== 2. FEATURE EXTRACTION =====
writeInfoLine: "Analyzing audio structure..."

# We use non-overlapping grains to build a discrete sequence
nGrains = floor(dur / grainSec)
nFeatures = 4

Create TableOfReal: "Features", nGrains, nFeatures
featTable = selected("TableOfReal")

selectObject: workSnd
To Spectrogram: grainSec, 8000, grainSec, 20, "Gaussian"
spec = selected("Spectrogram")

selectObject: workSnd
To Pitch: grainSec, 75, 600
pit = selected("Pitch")

selectObject: workSnd
To Harmonicity (cc): grainSec, 75, 0.1, 1.0
hnr = selected("Harmonicity")

for i from 1 to nGrains
    t = (i - 0.5) * grainSec
    
    # 1. Spectral Centroid
    selectObject: spec
    To Spectrum (slice): t
    slice = selected("Spectrum")
    cent = Get centre of gravity: 2
    band = Get standard deviation: 2
    Remove
    
    # 2. Pitch
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined
        f0 = 0
    endif
    
    # 3. HNR
    selectObject: hnr
    h = Get value at time: t, "cubic"
    if h = undefined
        h = -50
    endif
    
    selectObject: featTable
    Set value: i, 1, cent
    Set value: i, 2, band
    Set value: i, 3, f0
    Set value: i, 4, h
endfor

removeObject: spec, pit, hnr

# ===== 3. NORMALIZE & CLUSTER (MANUAL K-MEANS) =====
writeInfoLine: "Learning states (Clustering)..."

# Z-Score Normalization
selectObject: featTable
for c from 1 to nFeatures
    # Mean
    sum = 0
    for r from 1 to nGrains
        v = Get value: r, c
        sum = sum + v
    endfor
    mean = sum / nGrains
    
    # Stdev
    sumSq = 0
    for r from 1 to nGrains
        v = Get value: r, c
        diff = v - mean
        sumSq = sumSq + diff*diff
    endfor
    sd = sqrt(sumSq / nGrains)
    if sd = 0
        sd = 1
    endif
    
    # Apply
    for r from 1 to nGrains
        v = Get value: r, c
        z = (v - mean) / sd
        Set value: r, c, z
    endfor
endfor

# K-Means
k = number_of_states
max_iter = 10

Create TableOfReal: "Centroids", k, nFeatures
centroids = selected("TableOfReal")

# Init Centroids
for c from 1 to k
    randRow = randomInteger(1, nGrains)
    for f from 1 to nFeatures
        selectObject: featTable
        val = Get value: randRow, f
        selectObject: centroids
        Set value: c, f, val
    endfor
endfor

Create TableOfReal: "Assignments", nGrains, 1
assigns = selected("TableOfReal")

# Training Loop
for iter from 1 to max_iter
    changes = 0
    
    # E-Step (Assign)
    for i from 1 to nGrains
        minDist = 1e9
        bestK = 1
        
        for f from 1 to nFeatures
            selectObject: featTable
            feat_'f' = Get value: i, f
        endfor
        
        for c from 1 to k
            distSq = 0
            for f from 1 to nFeatures
                selectObject: centroids
                cVal = Get value: c, f
                d = feat_'f' - cVal
                distSq = distSq + d*d
            endfor
            if distSq < minDist
                minDist = distSq
                bestK = c
            endif
        endfor
        
        selectObject: assigns
        oldK = Get value: i, 1
        if oldK <> bestK
            Set value: i, 1, bestK
            changes = changes + 1
        endif
    endfor
    
    # M-Step (Update)
    for c from 1 to k
        count = 0
        for f from 1 to nFeatures
            sum_'f' = 0
        endfor
        for i from 1 to nGrains
            selectObject: assigns
            myK = Get value: i, 1
            if myK = c
                count = count + 1
                for f from 1 to nFeatures
                    selectObject: featTable
                    val = Get value: i, f
                    sum_'f' = sum_'f' + val
                endfor
            endif
        endfor
        if count > 0
            for f from 1 to nFeatures
                avg = sum_'f' / count
                selectObject: centroids
                Set value: c, f, avg
            endfor
        endif
    endfor
    
    if changes = 0
        goto converged
    endif
endfor
label converged

# ===== 4. BUILD MARKOV CHAIN =====
writeInfoLine: "Learning grammar (Markov Chain)..."

# 1. Store State Sequence
# 2. Store List of Grains per State (so we can pick one later)

for c from 1 to k
    count_in_state_'c' = 0
endfor

# Parse assignments to build lists
for i from 1 to nGrains
    selectObject: assigns
    state = Get value: i, 1
    
    # Save sequence for Markov
    seq_'i' = state
    
    # Save grain index for Synthesis
    idx = count_in_state_'state' + 1
    count_in_state_'state' = idx
    state_'state'_grain_'idx' = i
endfor

# Build Transition Matrix (K x K)
# Row = Current State, Col = Next State Probability
Create TableOfReal: "Transitions", k, k
transMat = selected("TableOfReal")

# Count transitions
for i from 1 to nGrains-1
    curr = seq_'i'
    next = seq_'i'+1
    # Note: seq_'i+1' syntax is tricky, pre-calc index
    next_idx = i + 1
    next = seq_'next_idx'
    
    selectObject: transMat
    oldVal = Get value: curr, next
    Set value: curr, next, oldVal + 1
endfor

# Normalize Rows to Probabilities
for r from 1 to k
    rowSum = 0
    selectObject: transMat
    for c from 1 to k
        val = Get value: r, c
        rowSum = rowSum + val
    endfor
    
    if rowSum > 0
        for c from 1 to k
            val = Get value: r, c
            Set value: r, c, val / rowSum
        endfor
    else
        # If dead end, uniform probability to all
        for c from 1 to k
            Set value: r, c, 1/k
        endfor
    endif
endfor

removeObject: featTable, centroids, assigns

# ===== 5. GENERATIVE SYNTHESIS =====
writeInfoLine: "Weaving soundscape..."

# We generate blocks to manage memory
grains_needed = ceiling(output_duration_sec / grainSec)
block_size = 50

# Output Containers
Create TableOfReal: "BlockIDs", 10000, 1
blockTable = selected("TableOfReal")
block_count = 0

Create TableOfReal: "GrainIDs", block_size, 1
grainTable = selected("TableOfReal")

# Start at random state
current_state = randomInteger(1, k)
total_generated = 0

while total_generated < grains_needed
    grains_in_block = 0
    
    for b from 1 to block_size
        # 1. Pick a grain from the CURRENT state
        # (This is the texture for this moment)
        if count_in_state_'current_state' > 0
            max_g = count_in_state_'current_state'
            r_idx = randomInteger(1, max_g)
            grain_index = state_'current_state'_grain_'r_idx'
            
            # Extract
            t_start = (grain_index - 1) * grainSec
            t_end = t_start + grainSec
            
            selectObject: workSnd
            # Use Hanning for smooth crossfade, or Rectangular for rhythmic
            # Let's use Hanning for ambient flow
            Extract part: t_start, t_end, "Hanning", 1, "no"
            gid = selected("Sound")
            
            grains_in_block = grains_in_block + 1
            selectObject: grainTable
            Set value: grains_in_block, 1, gid
        endif
        
        # 2. Determine NEXT state using Markov Matrix
        roll = randomUniform(0, 1)
        cumSum = 0
        next_state = 1
        
        selectObject: transMat
        for c from 1 to k
            prob = Get value: current_state, c
            cumSum = cumSum + prob
            if roll <= cumSum
                next_state = c
                goto found_next
            endif
        endfor
        
        # Fallback (rounding errors)
        next_state = k 
        
        label found_next
        current_state = next_state
        
        total_generated = total_generated + 1
        if total_generated >= grains_needed
            goto finish_block
        endif
    endfor
    
    label finish_block
    
    # Concatenate Block (Safe Logic)
    if grains_in_block > 0
        # Read IDs
        selectObject: grainTable
        for g from 1 to grains_in_block
            gid_'g' = Get value: g, 1
        endfor
        
        # Select
        selectObject: gid_1
        for g from 2 to grains_in_block
            plusObject: gid_'g'
        endfor
        
        # Concatenate (Standard Concatenate works fine with Hanning -> Constant Power)
        if grains_in_block > 1
            Concatenate
            blockMix = selected("Sound")
        else
            selectObject: gid_1
            Copy: "Block"
            blockMix = selected("Sound")
        endif
        
        block_count = block_count + 1
        selectObject: blockTable
        Set value: block_count, 1, blockMix
        
        # Cleanup grains
        for g from 1 to grains_in_block
            selectObject: gid_'g'
            Remove
        endfor
    endif
    
    if total_generated >= grains_needed
        goto finalize
    endif
endwhile

label finalize

# ===== 6. FINAL MERGE =====
writeInfoLine: "Finalizing..."

if block_count > 0
    # Read IDs
    selectObject: blockTable
    for b from 1 to block_count
        bid_'b' = Get value: b, 1
    endfor
    
    # Select
    selectObject: bid_1
    for b from 2 to block_count
        plusObject: bid_'b'
    endfor
    
    # Merge
    if block_count > 1
        Concatenate
        finalOut = selected("Sound")
    else
        selectObject: bid_1
        Copy: "Final"
        finalOut = selected("Sound")
    endif
    
    Rename: sndName$ + "_MarkovWeave"
    Scale peak: 0.99
    
    # Cleanup Blocks
    for b from 1 to block_count
        selectObject: bid_'b'
        Remove
    endfor
else
    exitScript: "Synthesis failed."
endif

# ===== CLEANUP =====
removeObject: workSnd, transMat, blockTable, grainTable

appendInfoLine: "Done! Created ", output_duration_sec, "s of Markov-generated audio."

if play_result
    selectObject: finalOut
    Play
endif

