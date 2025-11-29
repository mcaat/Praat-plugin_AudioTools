# ============================================================
# Praat AudioTools - PCA_Timbre_Selector
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  PCA_Timbre_Selector

# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# PCA Timbre Selector (Fast Vectorized Version)
# - Fixed "Unknown variable" error in cleanup section.
# - Fixed "extractWord$" error by using Table for IDs.
# - Robust Concatenation logic.

form PCA_Timbre_Selector
    comment === Timbre Presets ===
    optionmenu Preset: 1
        option Custom (use values below)
        option Bright/Clear (High Spectral Centroid)
        option Dark/Mellow (Low Spectral Centroid)
        option Noisy/Breathy (Low HNR)
        option Tonal/Focused (High HNR)
        option High Pitch
        option Low Pitch
        option Center (Average Timbre)
    
    comment === Analysis Parameters ===
    positive segment_ms 25
    positive frame_step_seconds 0.01
    positive f0_min 75
    positive f0_max 600
    
    comment === Custom Target (Standard Deviations) ===
    real target_pc1 0.0
    real target_pc2 0.0
    real target_pc3 0.0
    
    comment === Output ===
    boolean play_result 1
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

# Create a working copy
selectObject: snd
Copy: "Analysis_Work"
workSnd = selected("Sound")

# Handle Stereo -> Mono conversion safely
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

if workSnd = 0
    exitScript: "Error: Failed to create analysis copy."
endif

# ===== 2. BATCH FEATURE EXTRACTION =====
writeInfoLine: "Extracting features..."

selectObject: workSnd
To Pitch: frame_step_seconds, f0_min, f0_max
pit = selected("Pitch")

selectObject: workSnd
To Intensity: 75, frame_step_seconds, "yes"
inten = selected("Intensity")

selectObject: workSnd
To Spectrogram: segment_ms/1000, fs/2, frame_step_seconds, 20, "Gaussian"
specg = selected("Spectrogram")

selectObject: workSnd
To Harmonicity (ac): frame_step_seconds, f0_min, 0.1, 4.5
harmo = selected("Harmonicity")

selectObject: pit
nF = Get number of frames
t0 = Get start time
dt = Get time step

if nF < 10
    removeObject: pit, inten, specg, harmo, workSnd
    exitScript: "Sound too short for analysis."
endif

Create TableOfReal: "raw_features", nF, 5
feat = selected("TableOfReal")

# 1. Pitch
selectObject: pit
for i from 1 to nF
    v = Get value in frame: i, "Hertz"
    if v = undefined
        v = 0
    endif
    selectObject: feat
    Set value: i, 1, v
    selectObject: pit
endfor

# 2. Intensity
selectObject: inten
for i from 1 to nF
    v = Get value in frame: i
    if v = undefined
        v = -100
    endif
    selectObject: feat
    Set value: i, 2, v
    selectObject: inten
endfor

# 3. Spectral Features
selectObject: specg
for i from 1 to nF
    t = t0 + (i-1)*dt
    selectObject: specg
    To Spectrum (slice): t
    spec = selected("Spectrum")
    cent = Get centre of gravity: 2
    spread = Get standard deviation: 2
    Remove
    
    selectObject: feat
    if cent = undefined
        cent = 0
    endif
    if spread = undefined
        spread = 0
    endif
    Set value: i, 3, cent
    Set value: i, 4, spread
endfor

# 4. Harmonicity
selectObject: harmo
for i from 1 to nF
    v = Get value in frame: i
    if v = undefined
        v = -50
    endif
    selectObject: feat
    Set value: i, 5, v
    selectObject: harmo
endfor

removeObject: pit, inten, specg, harmo

# ===== 3. PCA & STANDARDIZATION =====
writeInfoLine: "Running PCA..."

selectObject: feat
To PCA
pca = selected("PCA")

# Smart Axis Detection
selectObject: pca
eig_f0 = Get eigenvector element: 1, 1
eig_int = Get eigenvector element: 1, 2
eig_cent = Get eigenvector element: 1, 3
eig_hnr = Get eigenvector element: 1, 5

idx_bright = 1
sign_bright = 1
idx_hnr = 2
sign_hnr = 1
idx_pitch = 3
sign_pitch = 1

if abs(eig_cent) > 0.5
    idx_bright = 1
    if eig_cent < 0
        sign_bright = -1
    else
        sign_bright = 1
    endif
elsif abs(eig_hnr) > 0.5
    idx_hnr = 1
    if eig_hnr < 0
        sign_hnr = -1
    else
        sign_hnr = 1
    endif
elsif abs(eig_f0) > 0.5
    idx_pitch = 1
    if eig_f0 < 0
        sign_pitch = -1
    else
        sign_pitch = 1
    endif
endif

selectObject: feat
plusObject: pca
To Configuration: 3
scores = selected("Configuration")
To TableOfReal
scoresTbl = selected("TableOfReal")
removeObject: scores

# ===== 4. APPLY PRESETS =====
t1 = target_pc1
t2 = target_pc2
t3 = target_pc3

if preset = 2
    if idx_bright = 1
        t1 = 1.5 * sign_bright
    elsif idx_bright = 2
        t2 = 1.5 * sign_bright
    else
        t3 = 1.5 * sign_bright
    endif
elsif preset = 3
    if idx_bright = 1
        t1 = -1.5 * sign_bright
    elsif idx_bright = 2
        t2 = -1.5 * sign_bright
    else
        t3 = -1.5 * sign_bright
    endif
elsif preset = 4
    if idx_hnr = 1
        t1 = -1.5 * sign_hnr
    elsif idx_hnr = 2
        t2 = -1.5 * sign_hnr
    else
        t3 = -1.5 * sign_hnr
    endif
elsif preset = 5
    if idx_hnr = 1
        t1 = 1.5 * sign_hnr
    elsif idx_hnr = 2
        t2 = 1.5 * sign_hnr
    else
        t3 = 1.5 * sign_hnr
    endif
elsif preset = 6
    if idx_pitch = 1
        t1 = 1.5 * sign_pitch
    elsif idx_pitch = 2
        t2 = 1.5 * sign_pitch
    else
        t3 = 1.5 * sign_pitch
    endif
elsif preset = 7
    if idx_pitch = 1
        t1 = -1.5 * sign_pitch
    elsif idx_pitch = 2
        t2 = -1.5 * sign_pitch
    else
        t3 = -1.5 * sign_pitch
    endif
endif

appendInfoLine: "Targeting PCA: ", fixed$(t1, 2), " / ", fixed$(t2, 2), " / ", fixed$(t3, 2)

# ===== 5. SELECTION & RECONSTRUCTION =====

Create TableOfReal: "Distance", nF, 1
distTbl = selected("TableOfReal")

for i from 1 to nF
    selectObject: scoresTbl
    v1 = Get value: i, 1
    v2 = Get value: i, 2
    v3 = Get value: i, 3
    d2 = (v1-t1)^2 + (v2-t2)^2 + (v3-t3)^2
    selectObject: distTbl
    Set value: i, 1, d2
endfor

# Threshold Logic (Top 30% closest match)
meanD = Get column mean (index): 1
thresh = meanD * 0.7

# Create a Table to store Chunk IDs
Create TableOfReal: "ChunkIDs", nF, 1
chunkTable = selected("TableOfReal")
chunk_count = 0

selectObject: workSnd
chunk_start = -1
chunk_end = -1

# Scan frames and build Chunks
for i from 1 to nF
    selectObject: distTbl
    d = Get value: i, 1
    
    is_selected = 0
    if d < thresh
        is_selected = 1
    endif
    
    t_frame = t0 + (i-1)*dt
    t_s = t_frame
    t_e = t_frame + dt
    
    if is_selected
        if chunk_start = -1
            chunk_start = t_s
        endif
        chunk_end = t_e
    else
        # End of a chunk
        if chunk_start <> -1
            selectObject: workSnd
            Extract part: chunk_start, chunk_end, "rectangular", 1, "no"
            chunkID = selected("Sound")
            
            # Store ID in Table
            chunk_count = chunk_count + 1
            selectObject: chunkTable
            Set value: chunk_count, 1, chunkID
            
            chunk_start = -1
        endif
    endif
endfor

# Handle final chunk
if chunk_start <> -1
    selectObject: workSnd
    Extract part: chunk_start, chunk_end, "rectangular", 1, "no"
    chunkID = selected("Sound")
    
    chunk_count = chunk_count + 1
    selectObject: chunkTable
    Set value: chunk_count, 1, chunkID
endif

# Concatenate Chunks
if chunk_count > 0
    # Retrieve IDs from table into variables
    selectObject: chunkTable
    for i from 1 to chunk_count
        id = Get value: i, 1
        chunk_id_['i'] = id
    endfor
    
    # Select first
    first = chunk_id_[1]
    selectObject: first
    
    # Select rest
    for i from 2 to chunk_count
        nxt = chunk_id_['i']
        plusObject: nxt
    endfor
    
    Concatenate
    Rename: sndName$ + "_TimbreSelected"
    finalSnd = selected("Sound")
    
    # Remove chunks
    for i from 1 to chunk_count
        del = chunk_id_['i']
        selectObject: del
        Remove
    endfor
    
    appendInfoLine: "Success: Combined ", chunk_count, " segments."
else
    removeObject: feat, pca, scoresTbl, distTbl, workSnd, chunkTable
    exitScript: "No segments matched the target timbre criteria."
endif

# ===== CLEANUP =====
selectObject: feat
plusObject: pca
plusObject: scoresTbl
plusObject: distTbl
plusObject: workSnd
plusObject: chunkTable
Remove

if play_result
    selectObject: finalSnd
    Play
endif
