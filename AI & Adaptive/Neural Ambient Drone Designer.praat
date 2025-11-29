# ============================================================
# Praat AudioTools - Neural Ambient Drone Designer
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Ambient Drone Designer
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Ambient Drone Designer 
# - Generates an infinite lush drone.

form Neural Ambient Drone Designer
    comment === Synthesis Parameters ===
    positive output_duration_sec 20.0
    positive layer_density 3
    boolean  add_octave_shimmer 1
    
    comment === AI Analysis ===
    positive grain_size_ms 100
    integer  number_of_clusters 3
    
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

# Work on Mono Copy
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

# Duration Check
grainSec = grain_size_ms / 1000
stepSec = grainSec * 0.5 

if dur < grainSec * 2
    removeObject: workSnd
    exitScript: "Sound is too short."
endif

# ===== 2. FEATURE EXTRACTION =====
writeInfoLine: "Analyzing spectral stability..."

nGrains = floor((dur - grainSec) / stepSec)
nFeatures = 4

# Table: 1=Centroid, 2=Bandwidth, 3=HNR, 4=Pitch
Create TableOfReal: "Features", nGrains, nFeatures
featTable = selected("TableOfReal")

selectObject: workSnd
To Spectrogram: grainSec, 8000, stepSec, 20, "Gaussian"
spec = selected("Spectrogram")

selectObject: workSnd
To Harmonicity (cc): stepSec, 75, 0.1, 1.0
hnr = selected("Harmonicity")

selectObject: workSnd
To Pitch: stepSec, 75, 600
pit = selected("Pitch")

for i from 1 to nGrains
    t = (i - 0.5) * stepSec
    
    # Spectrum
    selectObject: spec
    To Spectrum (slice): t
    slice = selected("Spectrum")
    cent = Get centre of gravity: 2
    band = Get standard deviation: 2
    Remove
    
    # HNR
    selectObject: hnr
    h = Get value at time: t, "cubic"
    if h = undefined
        h = -50
    endif
    
    # Pitch
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined
        f0 = 0
    endif
    
    selectObject: featTable
    Set value: i, 1, cent
    Set value: i, 2, band
    Set value: i, 3, h
    Set value: i, 4, f0
endfor

removeObject: spec, hnr, pit

# ===== 3. NORMALIZE & CLUSTER =====
writeInfoLine: "Clustering textures..."

# Manual Z-Score
selectObject: featTable
for c from 1 to nFeatures
    sum = 0
    for r from 1 to nGrains
        v = Get value: r, c
        sum = sum + v
    endfor
    mean = sum / nGrains
    
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
    
    for r from 1 to nGrains
        v = Get value: r, c
        z = (v - mean) / sd
        Set value: r, c, z
    endfor
endfor

# Manual K-Means
k = number_of_clusters
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

# Training
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

# ===== 4. IDENTIFY "BEST" CLUSTER =====
# Select the cluster with the highest HNR (Column 3)
best_cluster = 1
max_hnr_score = -1e9

for c from 1 to k
    selectObject: centroids
    score = Get value: c, 3
    if score > max_hnr_score
        max_hnr_score = score
        best_cluster = c
    endif
endfor

appendInfoLine: "Selected Cluster ", best_cluster, " (Most Tonal)."

# Collect indices of the best grains
Create TableOfReal: "TonalGrains", nGrains, 1
tonalTable = selected("TableOfReal")
tonal_count = 0

selectObject: assigns
for i from 1 to nGrains
    cls = Get value: i, 1
    if cls = best_cluster
        tonal_count = tonal_count + 1
        selectObject: tonalTable
        Set value: tonal_count, 1, i
    endif
endfor

removeObject: featTable, centroids, assigns

if tonal_count = 0
    removeObject: workSnd, tonalTable
    exitScript: "Failed to find tonal segments."
endif

# ===== 5. GENERATIVE DRONE SYNTHESIS =====
writeInfoLine: "Generating drone layers..."

nLayers = layer_density
layer_dur = output_duration_sec

# List to hold layer IDs
Create TableOfReal: "Layers", nLayers, 1
layerTable = selected("TableOfReal")

# Using 'layer_idx' instead of 'L'
for layer_idx from 1 to nLayers
    grains_needed = ceiling(layer_dur / (grainSec * 0.5)) 
    
    block_size = 20
    total_generated = 0
    
    Create TableOfReal: "LayerBlocks", 5000, 1
    lbTable = selected("TableOfReal")
    lb_count = 0
    
    Create TableOfReal: "TempGrains", block_size, 1
    tgTable = selected("TableOfReal")
    
    while total_generated < grains_needed
        g_in_blk = 0
        for b from 1 to block_size
            rand_idx = randomInteger(1, tonal_count)
            selectObject: tonalTable
            g_idx = Get value: rand_idx, 1
            
            t_center = (g_idx - 0.5) * stepSec
            t1 = t_center - (grainSec / 2)
            t2 = t_center + (grainSec / 2)
            
            selectObject: workSnd
            Extract part: t1, t2, "Hanning", 1, "no"
            gid = selected("Sound")
            
            if add_octave_shimmer
                roll = randomInteger(1, 10)
                if roll = 1
                    sr = Get sampling frequency
                    Resample: sr * 0.5, 50
                    Override sampling frequency: sr
                    tmp = selected("Sound")
                    removeObject: gid
                    gid = tmp
                elsif roll = 10
                    sr = Get sampling frequency
                    Resample: sr * 2.0, 50
                    Override sampling frequency: sr
                    tmp = selected("Sound")
                    removeObject: gid
                    gid = tmp
                endif
            endif
            
            g_in_blk = g_in_blk + 1
            selectObject: tgTable
            Set value: g_in_blk, 1, gid
            
            total_generated = total_generated + 1
            if total_generated >= grains_needed
                goto end_block
            endif
        endfor
        
        label end_block
        
        # --- CONCATENATE BLOCK (FIXED LOGIC) ---
        if g_in_blk > 0
            # 1. READ IDs FIRST
            selectObject: tgTable
            for g from 1 to g_in_blk
                gid_'g' = Get value: g, 1
            endfor
            
            # 2. SELECT OBJECTS (Don't touch table)
            selectObject: gid_1
            for g from 2 to g_in_blk
                plusObject: gid_'g'
            endfor
            
            # 3. ACTION
            Concatenate
            blkSnd = selected("Sound")
            
            lb_count = lb_count + 1
            selectObject: lbTable
            Set value: lb_count, 1, blkSnd
            
            # Cleanup grains
            for g from 1 to g_in_blk
                selectObject: gid_'g'
                Remove
            endfor
        endif
    endwhile
    
    removeObject: tgTable
    
    # --- MERGE BLOCKS INTO LAYER (FIXED LOGIC) ---
    if lb_count > 0
        # 1. READ IDs
        selectObject: lbTable
        for b from 1 to lb_count
            lid_'b' = Get value: b, 1
        endfor
        
        # 2. SELECT
        selectObject: lid_1
        for b from 2 to lb_count
            plusObject: lid_'b'
        endfor
        
        # 3. ACTION
        Concatenate
        layerSnd = selected("Sound")
        
        # Trim to exact length
        Extract part: 0, layer_dur, "rectangular", 1, "no"
        finalLayer = selected("Sound")
        removeObject: layerSnd
        
        # Cleanup blocks
        for b from 1 to lb_count
            selectObject: lid_'b'
            Remove
        endfor
    endif
    removeObject: lbTable
    
    # Save Layer ID
    selectObject: layerTable
    Set value: layer_idx, 1, finalLayer
endfor

# ===== 6. MIX LAYERS =====
writeInfoLine: "Mixing drone..."

# 1. Read IDs
selectObject: layerTable
for layer_idx from 1 to nLayers
    lay_id_'layer_idx' = Get value: layer_idx, 1
endfor

# 2. Select All
selectObject: lay_id_1
for layer_idx from 2 to nLayers
    plusObject: lay_id_'layer_idx'
endfor

# 3. Mix
if nLayers > 1
    Combine to stereo
    stereoID = selected("Sound")
    Convert to mono
    finalOut = selected("Sound")
    
    # Remove stereo temp
    selectObject: stereoID
    Remove
else
    Copy: "Drone"
    finalOut = selected("Sound")
endif

# IMPORTANT FIX: Re-select the output before renaming
selectObject: finalOut
Rename: sndName$ + "_NeuralDrone"
Scale peak: 0.99

# Cleanup Layers
for layer_idx from 1 to nLayers
    selectObject: lay_id_'layer_idx'
    Remove
endfor

# ===== CLEANUP =====
removeObject: workSnd, tonalTable, layerTable

appendInfoLine: "Done! Created lush drone."

if play_result
    selectObject: finalOut
    Play
endif
