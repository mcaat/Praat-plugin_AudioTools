# ============================================================
# Praat AudioTools - Neural Audio Mosaic
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Audio Mosaic

# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Neural Audio Mosaic 
# - Reconstructs 'Target' using 'Source' grains.

form Neural Audio Mosaic
    comment Select 2 Sounds: #1 = Target (Structure), #2 = Source (Texture)
    positive grain_size_ms 50
    # Changed to 'real' to allow 0.0 (no overlap)
    real overlap_ratio 0.0
    
    comment Search Parameters:
    integer  search_probes 50
    positive pitch_weight 0.3
    positive spectral_weight 1.0
    
    comment Output:
    boolean  normalize_volume 1
    boolean  play_result 1
endform

# ===== 1. SETUP & GUARDS =====
nSelected = numberOfSelected("Sound")
if nSelected <> 2
    exitScript: "Please select exactly TWO Sound objects. (1=Target, 2=Source)"
endif

# Identify Target and Source
id1 = selected("Sound", 1)
id2 = selected("Sound", 2)

selectObject: id1
targetName$ = selected$("Sound")
durTarget = Get total duration
fsTarget = Get sampling frequency

selectObject: id2
sourceName$ = selected$("Sound")
durSource = Get total duration
fsSource = Get sampling frequency

# Check Sampling Rate Match
if fsTarget <> fsSource
    exitScript: "Error: Both sounds must have the same sampling frequency."
endif

# Check Duration
grainSec = grain_size_ms / 1000
stepSec = grainSec * (1 - overlap_ratio)

if durTarget < grainSec or durSource < grainSec
    exitScript: "Sounds are too short for this grain size."
endif

# Make working copies (Target)
selectObject: id1
Copy: "Work_Target"
targetSnd = selected("Sound")
nCh = Get number of channels
if nCh > 1
    Convert to mono
    tmp = selected("Sound")
    removeObject: targetSnd
    targetSnd = tmp
    Rename: "Work_Target"
endif

# Make working copies (Source)
selectObject: id2
Copy: "Work_Source"
sourceSnd = selected("Sound")
nCh = Get number of channels
if nCh > 1
    Convert to mono
    tmp = selected("Sound")
    removeObject: sourceSnd
    sourceSnd = tmp
    Rename: "Work_Source"
endif

# ===== 2. FEATURE EXTRACTION (BATCH) =====
writeInfoLine: "Analyzing spectral features..."

# We analyze BOTH sounds using the same parameters
for sound_idx from 1 to 2
    if sound_idx = 1
        curSnd = targetSnd
        curDur = durTarget
        prefix$ = "T"
    else
        curSnd = sourceSnd
        curDur = durSource
        prefix$ = "S"
    endif
    
    selectObject: curSnd
    
    # Calculate frames
    nGrains = floor((curDur - grainSec) / stepSec)
    if nGrains < 1
        nGrains = 1
    endif
    
    # Store count in dynamic variable
    n_'prefix$' = nGrains
    
    # Create Feature Table
    Create TableOfReal: prefix$ + "_Feats", nGrains, 13
    tableID = selected("TableOfReal")
    id_'prefix$' = tableID
    
    # Analysis Objects
    selectObject: curSnd
    To MFCC: 12, 0.025, stepSec, 100, 100, 0
    mfcc = selected("MFCC")
    
    selectObject: curSnd
    To Pitch: stepSec, 75, 600
    pit = selected("Pitch")
    
    # Extract Loop (FIXED SELECTION LOGIC)
    for i from 1 to nGrains
        t = (i - 0.5) * stepSec
        
        # 1. READ PHASE (Collect all data first)
        selectObject: mfcc
        for c from 1 to 12
            val_'c' = Get value in frame: i, c
            if val_'c' = undefined
                val_'c' = 0
            endif
        endfor
        
        selectObject: pit
        f0 = Get value at time: t, "Hertz", "Linear"
        if f0 = undefined
            f0 = 0
        endif
        if f0 > 0
            logF0 = 12 * log2(f0 / 100)
        else
            logF0 = 0
        endif
        
        # 2. WRITE PHASE (Select table once and write)
        selectObject: tableID
        for c from 1 to 12
            Set value: i, c, val_'c'
        endfor
        Set value: i, 13, logF0
    endfor
    
    removeObject: mfcc, pit
endfor

# ===== 3. NORMALIZATION =====
writeInfoLine: "Normalizing features..."

for sound_idx from 1 to 2
    if sound_idx = 1
        tab = id_T
        rows = n_T
    else
        tab = id_S
        rows = n_S
    endif
    
    selectObject: tab
    for c from 1 to 13
        # Stats
        minV = 1e9
        maxV = -1e9
        for r from 1 to rows
            v = Get value: r, c
            if v < minV
                minV = v
            endif
            if v > maxV
                maxV = v
            endif
        endfor
        range = maxV - minV
        if range = 0
            range = 1
        endif
        
        # Apply Min-Max Norm
        for r from 1 to rows
            v = Get value: r, c
            norm = (v - minV) / range
            Set value: r, c, norm
        endfor
    endfor
endfor

# ===== 4. NEURAL SEARCH (STOCHASTIC) =====
writeInfoLine: "Running Neural Search (Mosaic)..."

# Output List Table
Create TableOfReal: "MosaicSequence", n_T, 1
seqTable = selected("TableOfReal")

# Weights
wSpec = spectral_weight
wPitch = pitch_weight

for i from 1 to n_T
    # Get Target Feature Vector
    selectObject: id_T
    for c from 1 to 12
        t_mfcc_'c' = Get value: i, c
    endfor
    t_pitch = Get value: i, 13
    
    # Stochastic Search in Source
    best_dist = 1e9
    best_idx = 1
    
    # Check 'search_probes' random grains
    for probe from 1 to search_probes
        r_idx = randomInteger(1, n_S)
        
        selectObject: id_S
        dist = 0
        
        # Spectral Dist
        for c from 1 to 12
            s_val = Get value: r_idx, c
            d = t_mfcc_'c' - s_val
            dist = dist + (d * d * wSpec)
        endfor
        
        # Pitch Dist
        s_pitch = Get value: r_idx, 13
        if t_pitch > 0 and s_pitch > 0
            dp = t_pitch - s_pitch
            dist = dist + (dp * dp * wPitch)
        endif
        
        if dist < best_dist
            best_dist = dist
            best_idx = r_idx
        endif
    endfor
    
    # Store best match
    selectObject: seqTable
    Set value: i, 1, best_idx
    
    if i mod 50 = 0
        perc = i / n_T * 100
        appendInfoLine: "Matching: ", fixed$(perc, 0), "%"
    endif
endfor

# ===== 5. RESYNTHESIS (GRANULAR) =====
writeInfoLine: "Constructing Mosaic..."

block_size = 50
current_frame = 0
block_count = 0

# Table to hold block IDs
n_blocks_total = ceiling(n_T / block_size) + 1
Create TableOfReal: "BlockList", n_blocks_total, 1
blockList = selected("TableOfReal")

# Temp table for grains
Create TableOfReal: "GrainList", block_size, 1
grainList = selected("TableOfReal")

while current_frame < n_T
    grains_in_block = 0
    
    for b from 1 to block_size
        current_frame = current_frame + 1
        
        # Lookup Source Index
        selectObject: seqTable
        src_idx = Get value: current_frame, 1
        
        # Calculate Time
        t_src = (src_idx - 0.5) * stepSec
        t1 = t_src - (grainSec / 2)
        t2 = t_src + (grainSec / 2)
        
        # Extract Grain from SOURCE
        selectObject: sourceSnd
        Extract part: t1, t2, "rectangular", 1, "no"
        gid = selected("Sound")
        
        grains_in_block = grains_in_block + 1
        selectObject: grainList
        Set value: grains_in_block, 1, gid
        
        if current_frame >= n_T
            goto finish_block
        endif
    endfor
    
    label finish_block
    
    # Concatenate Block
    if grains_in_block > 0
        # 1. Get IDs
        selectObject: grainList
        for g from 1 to grains_in_block
            gid_'g' = Get value: g, 1
        endfor
        
        # 2. Select
        selectObject: gid_1
        for g from 2 to grains_in_block
            plusObject: gid_'g'
        endfor
        
        # 3. Concatenate
        if grains_in_block > 1
            Concatenate
            blockMix = selected("Sound")
        else
            selectObject: gid_1
            Copy: "Block"
            blockMix = selected("Sound")
        endif
        
        block_count = block_count + 1
        selectObject: blockList
        Set value: block_count, 1, blockMix
        
        # Cleanup Grains
        for g from 1 to grains_in_block
            selectObject: gid_'g'
            Remove
        endfor
    endif
    
    if current_frame >= n_T
        goto finalize
    endif
endwhile

label finalize

# ===== 6. FINAL MERGE =====
writeInfoLine: "Finalizing..."

if block_count > 0
    # 1. Get Block IDs
    selectObject: blockList
    for b from 1 to block_count
        bid_'b' = Get value: b, 1
    endfor
    
    # 2. Select
    selectObject: bid_1
    for b from 2 to block_count
        plusObject: bid_'b'
    endfor
    
    # 3. Merge
    if block_count > 1
        Concatenate
        finalOut = selected("Sound")
    else
        selectObject: bid_1
        Copy: "Final"
        finalOut = selected("Sound")
    endif
    
    Rename: targetName$ + "_Mosaic"
    
    if normalize_volume
        Scale peak: 0.99
    endif
    
    # Cleanup Blocks
    for b from 1 to block_count
        selectObject: bid_'b'
        Remove
    endfor
else
    exitScript: "Synthesis failed."
endif

# ===== CLEANUP =====
selectObject: targetSnd
plusObject: sourceSnd
plusObject: id_T
plusObject: id_S
plusObject: seqTable
plusObject: blockList
plusObject: grainList
Remove

appendInfoLine: "Done! Mosaic created."

if play_result
    selectObject: finalOut
    Play
endif

selectObject: finalOut