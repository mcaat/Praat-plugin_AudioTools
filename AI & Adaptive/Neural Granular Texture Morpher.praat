# ============================================================
# Praat AudioTools - Neural Granular Texture Morpher
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Granular Texture Morpher

# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Granular Texture Morpher 
# - Fixed "Concatenate" error (Selection logic corrected).
# - Uses manual K-Means (No external dependencies).
# - Robust Table-based ID management.

form Neural Texture Morpher
    comment === Analysis Parameters ===
    positive grain_size_ms 60
    positive overlap_ratio 0.5
    positive max_frequency_hz 8000
    integer  number_of_clusters 4
    
    comment === Synthesis Parameters ===
    positive output_duration_sec 10.0
    positive morph_speed_hz 0.5
    
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

# Working Copy
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
stepSec = grainSec * (1 - overlap_ratio)
if dur < grainSec * 2
    removeObject: workSnd
    exitScript: "Sound is too short for granular analysis."
endif

# ===== 2. FEATURE EXTRACTION =====
writeInfoLine: "Analyzing grains..."

nGrains = floor((dur - grainSec) / stepSec)
nFeatures = 5

Create TableOfReal: "Features", nGrains, nFeatures
featTable = selected("TableOfReal")

# Analysis Objects
selectObject: workSnd
To Spectrogram: grainSec, max_frequency_hz, stepSec, 20, "Gaussian"
spec = selected("Spectrogram")

selectObject: workSnd
To Pitch: stepSec, 75, 600
pit = selected("Pitch")

selectObject: workSnd
To Harmonicity (cc): stepSec, 75, 0.1, 1.0
hnr = selected("Harmonicity")

selectObject: workSnd
To Intensity: 75, stepSec, "yes"
inten = selected("Intensity")

# Batch Extract
for i from 1 to nGrains
    t = (i - 0.5) * stepSec
    
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
    
    # 4. Intensity
    selectObject: inten
    in = Get value at time: t, "cubic"
    if in = undefined
        in = -100
    endif
    
    # Store
    selectObject: featTable
    Set value: i, 1, cent
    Set value: i, 2, band
    Set value: i, 3, f0
    Set value: i, 4, h
    Set value: i, 5, in
endfor

removeObject: spec, pit, hnr, inten

# ===== 3. MANUAL Z-SCORE NORMALIZATION =====
selectObject: featTable
nRows = Get number of rows
nCols = Get number of columns

for c from 1 to nCols
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
        d = v - mean
        sumSq = sumSq + d*d
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

# ===== 4. MANUAL K-MEANS CLUSTERING =====
writeInfoLine: "Learning textures (Training AI)..."

k = number_of_clusters
max_iter = 10

# Initialize Centroids
Create TableOfReal: "Centroids", k, nFeatures
centroids = selected("TableOfReal")

for c from 1 to k
    randRow = randomInteger(1, nGrains)
    for f from 1 to nFeatures
        selectObject: featTable
        val = Get value: randRow, f
        selectObject: centroids
        Set value: c, f, val
    endfor
endfor

# Initialize Assignments
Create TableOfReal: "Assignments", nGrains, 1
assigns = selected("TableOfReal")

# Training Loop
for iter from 1 to max_iter
    changes = 0
    
    # E-Step
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
    
    # M-Step
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

# Build Cluster Lists
for c from 1 to k
    count_cluster_'c' = 0
endfor

for i from 1 to nGrains
    selectObject: assigns
    c = Get value: i, 1
    
    idx = count_cluster_'c' + 1
    count_cluster_'c' = idx
    cluster_'c'_grain_'idx' = i
endfor

removeObject: featTable, centroids, assigns

# Check for empty clusters
valid_clusters = 0
for c from 1 to k
    if count_cluster_'c' > 0
        valid_clusters = valid_clusters + 1
    endif
endfor

if valid_clusters < 2
    removeObject: workSnd
    exitScript: "Analysis failed: Not enough distinct textures found."
endif

# ===== 5. GENERATIVE SYNTHESIS =====
writeInfoLine: "Synthesizing texture..."

grains_needed = ceiling(output_duration_sec / stepSec)
block_size = 50

# Output container
Create TableOfReal: "BlockIDs", 10000, 1
blockTable = selected("TableOfReal")
block_count = 0

total_generated = 0

while total_generated < grains_needed
    # Generate Block
    Create TableOfReal: "GrainIDs", block_size, 1
    grainTable = selected("TableOfReal")
    grains_in_block = 0
    
    for b from 1 to block_size
        total_generated = total_generated + 1
        
        # Morph Logic
        t_gen = total_generated * stepSec
        cycle_pos = (t_gen * morph_speed_hz) * k
        target_c_float = (cycle_pos mod k) + 1
        target_c = round(target_c_float)
        
        if target_c < 1
            target_c = 1
        endif
        if target_c > k
            target_c = k
        endif
        if count_cluster_'target_c' = 0
            target_c = 1
        endif
        
        max_g = count_cluster_'target_c'
        r_idx = randomInteger(1, max_g)
        grain_idx = cluster_'target_c'_grain_'r_idx'
        
        # Extract
        t_grain = (grain_idx - 0.5) * stepSec
        t_start = t_grain - (grainSec / 2)
        t_end = t_grain + (grainSec / 2)
        
        selectObject: workSnd
        Extract part: t_start, t_end, "Hanning", 1, "no"
        gid = selected("Sound")
        
        grains_in_block = grains_in_block + 1
        selectObject: grainTable
        Set value: grains_in_block, 1, gid
        
        if total_generated >= grains_needed
            goto finish_block
        endif
    endfor
    
    label finish_block
    
    # Concatenate Block (Safe Logic)
    if grains_in_block > 0
        # 1. Read IDs into variables first (Avoids selection conflict)
        selectObject: grainTable
        for g from 1 to grains_in_block
            grain_id_'g' = Get value: g, 1
        endfor
        
        # 2. Select IDs
        selectObject: grain_id_1
        for g from 2 to grains_in_block
            plusObject: grain_id_'g'
        endfor
        
        # 3. Concatenate or Copy
        if grains_in_block > 1
            Concatenate
            blockMix = selected("Sound")
        else
            selectObject: grain_id_1
            Copy: "Block"
            blockMix = selected("Sound")
        endif
        
        block_count = block_count + 1
        selectObject: blockTable
        Set value: block_count, 1, blockMix
        
        # Cleanup grains
        for g from 1 to grains_in_block
            selectObject: grain_id_'g'
            Remove
        endfor
    endif
    removeObject: grainTable
    
    if total_generated >= grains_needed
        goto finalize
    endif
endwhile

label finalize

# ===== 6. FINAL CONCATENATION (Safe Logic) =====
writeInfoLine: "Finalizing..."

if block_count > 0
    # 1. Read IDs into variables
    selectObject: blockTable
    for b from 1 to block_count
        blk_id_'b' = Get value: b, 1
    endfor
    
    # 2. Select IDs
    selectObject: blk_id_1
    for b from 2 to block_count
        plusObject: blk_id_'b'
    endfor
    
    # 3. Concatenate
    if block_count > 1
        Concatenate
        finalOut = selected("Sound")
    else
        selectObject: blk_id_1
        Copy: "Final"
        finalOut = selected("Sound")
    endif
    
    Rename: sndName$ + "_TextureMorph"
    Scale peak: 0.99
    
    # Cleanup blocks
    for b from 1 to block_count
        selectObject: blk_id_'b'
        Remove
    endfor
else
    exitScript: "Generation failed."
endif

# ===== CLEANUP =====
removeObject: workSnd, blockTable

appendInfoLine: "Done! Created ", output_duration_sec, "s of morphing texture."

if play_result
    selectObject: finalOut
    Play
endif
