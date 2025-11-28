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

form PCA_Timbre_Selector
    comment === Timbre Presets ===
    optionmenu Preset: 1
        option Custom (use values below)
        option Bright/Clear (high spectral energy)
        option Dark/Mellow (low spectral energy)
        option Breathy/Airy (low harmonicity)
        option Strong/Focused (high harmonicity)
        option High Pitch
        option Low Pitch
        option Neutral (origin)
    comment === Analysis Parameters ===
    positive segment_ms 50
    positive frame_step_seconds 0.01
    positive f0_min 75
    positive f0_max 600
    integer n_components 3
    comment === Custom Target Values (if preset = Custom) ===
    real target_pc1 0.0
    real target_pc2 0.0
    real target_pc3 0.0
endform

# Apply preset values
if preset = 2
    # Bright/Clear - high spectral centroid
    target_pc1 = 1.5
    target_pc2 = 0.0
    target_pc3 = 0.0
elsif preset = 3
    # Dark/Mellow - low spectral centroid
    target_pc1 = -1.5
    target_pc2 = 0.0
    target_pc3 = 0.0
elsif preset = 4
    # Breathy/Airy - low HNR
    target_pc1 = 0.0
    target_pc2 = -1.5
    target_pc3 = 0.0
elsif preset = 5
    # Strong/Focused - high HNR
    target_pc1 = 0.0
    target_pc2 = 1.5
    target_pc3 = 0.0
elsif preset = 6
    # High Pitch
    target_pc1 = 0.0
    target_pc2 = 0.0
    target_pc3 = 1.5
elsif preset = 7
    # Low Pitch
    target_pc1 = 0.0
    target_pc2 = 0.0
    target_pc3 = -1.5
elsif preset = 8
    # Neutral
    target_pc1 = 0.0
    target_pc2 = 0.0
    target_pc3 = 0.0
endif
# If preset = 1 (Custom), use the values from the form

# ===== 0. Setup and Guards =====
snd = selected("Sound")
sndName$ = selected$("Sound")
if snd = 0
    exitScript: "No sound selected."
endif
selectObject: snd
dur = Get total duration
fs  = Get sampling frequency
nch = Get number of channels
if nch > 1
    Convert to mono
    snd = selected("Sound")
endif

# Alias and initial checks
segDur = segment_ms / 1000
if segDur < 0.02
    segDur = 0.02
endif
maxComp = n_components
if maxComp < 1 or maxComp > 8
    maxComp = 3
endif

# Create working copy for analysis
selectObject: snd
Copy: sndName$ + "_work"
workSnd = selected("Sound")

# ===== 1. Feature Analysis (Per Frame/Segment) =====
selectObject: workSnd
To Pitch: frame_step_seconds, f0_min, f0_max
pit = selected("Pitch")

selectObject: workSnd
To Intensity: 75, frame_step_seconds, "yes"
inten = selected("Intensity")

selectObject: workSnd
To Spectrogram: segDur, fs/2, frame_step_seconds, 20, "Gaussian"
specg = selected("Spectrogram")

selectObject: workSnd
To Harmonicity (ac): frame_step_seconds, f0_min, 0.1, 4.5
harmo = selected("Harmonicity")

# Time grid from Pitch
selectObject: pit
nF = Get number of frames
t0 = Get start time
dt = Get time step

if nF < 5
    removeObject: workSnd, pit, inten, specg, harmo
    exitScript: "Sound too short for analysis."
endif

# Feature table: 1-F0, 2-Intensity, 3-Centroid, 4-Spread, 5-Bandwidth(=2*spread),
# 6-Reserved(=0), 7-HNR, 8-DominantFreq
Create TableOfReal: "feat", nF, 8
feat = selected("TableOfReal")

for i from 1 to nF
    t = t0 + (i - 0.5) * dt

    # 1. F0
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 <> f0 or f0 < f0_min
        f0 = 0
    endif

    # 2. Intensity
    selectObject: inten
    intVal = Get value at time: t, "cubic"
    if intVal <> intVal
        intVal = 60
    endif

    # 3–5 & 8. Spectral features from slice at time t
    selectObject: specg
    To Spectrum (slice): t
    slice = selected("Spectrum")

    selectObject: slice
    cent = Get centre of gravity: 2
    if cent <> cent
        cent = 0
    endif
    spread = Get standard deviation: 2
    if spread <> spread
        spread = 0
    endif
    bw = 2 * spread

    selectObject: slice
    To Ltas (1-to-1)
    lt = selected("Ltas")
    selectObject: lt
    fmax = Get frequency of maximum: 0, 0, "Parabolic"
    if fmax <> fmax
        fmax = 0
    endif
    removeObject: lt, slice

    # 6. Reserved/placeholder
    slope_like = 0

    # 7. Harmonicity (HNR) at time t
    selectObject: harmo
    hnr = Get value at time: t, "cubic"
    if hnr <> hnr
        hnr = -200
    endif

    # Write row
    selectObject: feat
    Set value: i, 1, f0
    Set value: i, 2, intVal
    Set value: i, 3, cent
    Set value: i, 4, spread
    Set value: i, 5, bw
    Set value: i, 6, slope_like
    Set value: i, 7, hnr
    Set value: i, 8, fmax
endfor

# Remove analysis objects
removeObject: pit, inten, specg, harmo

# ===== 2. PCA & Score Calculation =====
selectObject: feat
Copy: "zfeat"
zfeat = selected("TableOfReal")

# Manual column-wise z-score
for c from 1 to 8
    # mean
    sum = 0
    cnt = 0
    for i from 1 to nF
        v = Get value: i, c
        if v = v
            sum = sum + v
            cnt = cnt + 1
        endif
    endfor
    if cnt > 0
        cm = sum / cnt
    else
        cm = 0
    endif
    # std
    s2 = 0
    cnt2 = 0
    for i from 1 to nF
        v = Get value: i, c
        if v = v
            dv = v - cm
            s2 = s2 + dv * dv
            cnt2 = cnt2 + 1
        endif
    endfor
    if cnt2 > 1
        cs = sqrt (s2 / cnt2)
    else
        cs = 0
    endif
    # normalize and replace undefineds
    for i from 1 to nF
        v = Get value: i, c
        if v <> v
            v = cm
        endif
        v = v - cm
        if cs > 0
            v = v / cs
        else
            v = 0
        endif
        Set value: i, c, v
    endfor
endfor

selectObject: zfeat
To PCA
pca = selected("PCA")

# Project standardized data onto first maxComp PCs -> Configuration (scores)
selectObject: zfeat, pca
To Configuration: maxComp
config = selected("Configuration")

# Convert Configuration to TableOfReal to access values
selectObject: config
To TableOfReal
scores = selected("TableOfReal")

# Number of scores equals number of frames
nScores = nF

# ===== 3. Timbre Selection Logic =====
Create TableOfReal: "distance", nScores, 1
distTbl = selected("TableOfReal")

target1 = target_pc1
target2 = target_pc2
target3 = target_pc3

for i from 1 to nScores
    dSq = 0
    for j from 1 to maxComp
        selectObject: scores
        val = Get value: i, j
        if val <> val
            val = 0
        endif
        if j = 1
            targetVal = target1
        elsif j = 2
            targetVal = target2
        elsif j = 3
            targetVal = target3
        else
            targetVal = 0
        endif
        diff = val - targetVal
        dSq = dSq + diff * diff
    endfor
    selectObject: distTbl
    Set value: i, 1, dSq
endfor

selectObject: distTbl
meanDist = Get column mean (index): 1
stdDevDist = Get column stdev (index): 1
threshold = meanDist + 0.5 * stdDevDist

# ===== 4. Sound Reconstruction =====
firstDone = 0
outS = 0

# Reuse the same frame times from Pitch grid
for i from 1 to nScores
    selectObject: distTbl
    dSq = Get value: i, 1
    if dSq < threshold
        t1 = t0 + (i - 1) * dt
        t2 = t1 + segDur
        if t2 > dur
            t2 = dur
        endif

        selectObject: workSnd
        Extract part: t1, t2, "Hamming", 1, "yes"
        seg = selected("Sound")

        if firstDone = 0
            selectObject: seg
            Copy: sndName$ + "_PCAFiltered"
            outS = selected("Sound")
            firstDone = 1
            selectObject: seg
            Remove
        else
            selectObject: outS
            plusObject: seg
            Concatenate recoverably
            newOut = selected("Sound")
            removeObject: outS, seg
            outS = newOut
        endif
    endif
endfor

# ===== 5. Finalization and Cleanup =====
# Remove all intermediate objects but keep original input and result
select all
minusObject: snd
if outS <> 0
    minusObject: outS
endif
Remove

if outS = 0
    exitScript: "No segments matched the target timbre. Try adjusting the target_pc values."
endif

selectObject: outS
Scale peak: 0.98
Play

selectObject: outS
outDur = Get total duration
estSegments = round(outDur / segDur)

pc1_str$ = fixed$(target_pc1, 2)
pc2_str$ = fixed$(target_pc2, 2)
pc3_str$ = fixed$(target_pc3, 2)

writeInfoLine: "=== PCA Timbre Selection Completed ==="
appendInfoLine: "Output Sound: ", selected$("Sound")
appendInfoLine: "Total segments in result: ", estSegments, " (estimated)"
appendInfoLine: "Target PC: (", pc1_str$, ", ", pc2_str$, ", ", pc3_str$, ")"
selectObject: snd
plusObject: outS