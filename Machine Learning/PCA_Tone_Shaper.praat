form PCA_Tone_Shaper
    positive chunk_ms 200
    positive frame_step_seconds 0.01
    positive max_formant_hz 5500
    integer  n_formants 5
    positive f0_min 75
    positive f0_max 600
    positive pca_strength 0.8
    positive low_hi_crossover1_hz 200
    positive low_hi_crossover2_hz 2000
    positive high_band_top_hz 8000
    positive headroom 0.97
    boolean  play_result 0
endform

# ===== inputs =====
snd = selected("Sound")
sndName$ = selected$("Sound")
if snd = 0
    exitScript: "No sound selected."
endif

# Preserve the original so we can keep it at the end
origSnd   = snd
origName$ = sndName$

# alias params
maxFmtHz = max_formant_hz
nFmt     = n_formants

selectObject: snd
dur = Get total duration
fs  = Get sampling frequency
if dur <= 0
    exitScript: "Invalid sound."
endif
nch = Get number of channels
if nch > 1
    Convert to mono
    snd = selected("Sound")   ; working copy
endif

# ===== guards =====
nyq = fs / 2
if high_band_top_hz > nyq - 50
    high_band_top_hz = nyq - 50
endif
if low_hi_crossover2_hz > high_band_top_hz - 50
    low_hi_crossover2_hz = high_band_top_hz - 50
endif
if low_hi_crossover1_hz < 20
    low_hi_crossover1_hz = 20
endif
if low_hi_crossover1_hz > low_hi_crossover2_hz - 20
    low_hi_crossover1_hz = low_hi_crossover2_hz - 20
endif
if maxFmtHz > nyq - 200
    maxFmtHz = nyq - 200
endif
if f0_min < 20
    f0_min = 20
endif
if f0_max > nyq - 50
    f0_max = nyq - 50
endif
if pca_strength < 0
    pca_strength = 0
endif
if pca_strength > 1.5
    pca_strength = 1.5
endif

# ===== analysis objects =====
selectObject: snd
To Pitch: 0, f0_min, f0_max
pit = selected("Pitch")

selectObject: snd
To Intensity: 75, 0, "yes"
inten = selected("Intensity")

selectObject: snd
To Harmonicity (cc): frame_step_seconds, f0_min, 0.1, 1.0
hnr = selected("Harmonicity")

selectObject: snd
To Formant (burg): 0, nFmt, maxFmtHz, 0.025, 50
fmtObj = selected("Formant")

# ===== frame grid =====
selectObject: pit
nF = Get number of frames
if nF < 3
    exitScript: "Not enough frames for PCA (need ≥ 3)."
endif
t0 = Get start time
dt = Get time step
if dt <= 0
    dt = frame_step_seconds
endif

# ===== feature table (nF x 8) =====
Create TableOfReal: "feat", nF, 8
feat = selected("TableOfReal")

for i from 1 to nF
    t = t0 + (i - 0.5) * dt
    # F1..F3
    selectObject: fmtObj
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    if f1 = undefined or f1 <> f1 or f1 <= 0
        f1 = 500
    endif
    if f2 = undefined or f2 <> f2 or f2 <= 0
        f2 = 1500
    endif
    if f3 = undefined or f3 <> f3 or f3 <= 0
        f3 = 2500
    endif
    r21 = f2 / f1
    r32 = f3 / f2

    # f0
    selectObject: pit
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <> f0 or f0 < 0
        f0 = 0
    endif

    # intensity
    selectObject: inten
    intVal = Get value at time: t, "cubic"
    if intVal = undefined or intVal <> intVal
        intVal = 60
    endif

    # hnr
    selectObject: hnr
    hnrVal = Get value in frame: i
    if hnrVal = undefined or hnrVal <> hnrVal
        hnrVal = 0
    endif

    # write row
    selectObject: feat
    Set value: i, 1, f1
    Set value: i, 2, f2
    Set value: i, 3, f3
    Set value: i, 4, r21
    Set value: i, 5, r32
    Set value: i, 6, f0
    Set value: i, 7, intVal
    Set value: i, 8, hnrVal
endfor

# ===== z-scores =====
selectObject: feat
nRows = Get number of rows
nCols = Get number of columns
Create TableOfReal: "zfeat", nRows, nCols
zfeat = selected("TableOfReal")

for col from 1 to nCols
    selectObject: feat
    sum = 0
    for row from 1 to nRows
        val = Get value: row, col
        sum = sum + val
    endfor
    mean = sum / nRows
    sumSq = 0
    for row from 1 to nRows
        selectObject: feat
        val = Get value: row, col
        diff = val - mean
        sumSq = sumSq + diff*diff
    endfor
    sd = sqrt(sumSq / nRows)
    if sd = 0
        sd = 1
    endif
    for row from 1 to nRows
        selectObject: feat
        val = Get value: row, col
        z = (val - mean) / sd
        selectObject: zfeat
        Set value: row, col, z
    endfor
endfor

# ===== PCA and scores =====
selectObject: zfeat
To PCA
pca = selected("PCA")
selectObject: zfeat, pca
To Configuration: 3
config = selected("Configuration")
selectObject: config
To TableOfReal
scr = selected("TableOfReal")

# ===== normalize PC1..3 to [-1,1] =====
selectObject: scr
nScores = Get number of rows
Create TableOfReal: "ctrl", nScores, 3
ctrl = selected("TableOfReal")

# PC1
selectObject: scr
mn = 1e30
mx = -1e30
for ii from 1 to nScores
    vv = Get value: ii, 1
    if vv < mn
        mn = vv
    endif
    if vv > mx
        mx = vv
    endif
endfor
rg = mx - mn
if rg = 0
    rg = 1
endif
for ii from 1 to nScores
    vv = Get value: ii, 1
    nv = 2*((vv - mn)/rg) - 1
    selectObject: ctrl
    Set value: ii, 1, nv
endfor

# PC2
selectObject: scr
mn = 1e30
mx = -1e30
for ii from 1 to nScores
    vv = Get value: ii, 2
    if vv < mn
        mn = vv
    endif
    if vv > mx
        mx = vv
    endif
endfor
rg = mx - mn
if rg = 0
    rg = 1
endif
for ii from 1 to nScores
    vv = Get value: ii, 2
    nv = 2*((vv - mn)/rg) - 1
    selectObject: ctrl
    Set value: ii, 2, nv
endfor

# PC3
selectObject: scr
mn = 1e30
mx = -1e30
for ii from 1 to nScores
    vv = Get value: ii, 3
    if vv < mn
        mn = vv
    endif
    if vv > mx
        mx = vv
    endif
endfor
rg = mx - mn
if rg = 0
    rg = 1
endif
for ii from 1 to nScores
    vv = Get value: ii, 3
    nv = 2*((vv - mn)/rg) - 1
    selectObject: ctrl
    Set value: ii, 3, nv
endfor

# ===== chunked processing =====
cDur = chunk_ms / 1000
if cDur < dt
    cDur = dt
endif
nChunks = round (dur / cDur + 0.4999)
if nChunks < 1
    nChunks = 1
endif

firstDone = 0
outS = 0

for k from 1 to nChunks
    t1 = (k - 1) * cDur
    t2 = t1 + cDur
    if t2 > dur
        t2 = dur
    endif
    if t2 > t1
        # frame indices
        f1i = round ((t1 - t0) / dt - 0.5) + 1
        f2i = round ((t2 - t0) / dt + 0.5)
        if f1i < 1
            f1i = 1
        endif
        if f2i > nScores
            f2i = nScores
        endif
        if f2i < f1i
            f2i = f1i
        endif

        # mean controls
        a1 = 0
        a2 = 0
        a3 = 0
        effCnt = 0
        selectObject: ctrl
        nCtrlRows = Get number of rows
        for frameIdx from f1i to f2i
            if frameIdx <= nCtrlRows
                val1 = Get value: frameIdx, 1
                val2 = Get value: frameIdx, 2
                val3 = Get value: frameIdx, 3
                a1 = a1 + val1
                a2 = a2 + val2
                a3 = a3 + val3
                effCnt = effCnt + 1
            endif
        endfor
        if effCnt = 0
            effCnt = 1
        endif
        pc1m = a1 / effCnt
        pc2m = a2 / effCnt
        pc3m = a3 / effCnt

        # map to band gains
        tilt     = 0.35 * pca_strength * pc1m
        presence = 0.20 * pca_strength * pc2m
        body     = 0.30 * pca_strength * pc3m
        gL = 1.0 -     tilt + 0.8*body
        gM = 1.0 + 0.3*presence - 0.2*body
        gH = 1.0 + 1.2*tilt + 0.7*presence - 0.2*body
        if gL < 0.5
            gL = 0.5
        endif
        if gL > 1.5
            gL = 1.5
        endif
        if gM < 0.5
            gM = 0.5
        endif
        if gM > 1.5
            gM = 1.5
        endif
        if gH < 0.5
            gH = 0.5
        endif
        if gH > 1.5
            gH = 1.5
        endif

        # extract chunk and bands
        selectObject: snd
        # *** FIX: Changed "rectangular" to "Hamming" to prevent clicks/stuttering ***
        Extract part: t1, t2, "Hamming", 1, "yes" 
        seg = selected("Sound")

        selectObject: seg
        To Spectrum: "yes"
        s_all = selected("Spectrum")

        selectObject: s_all
        Copy: "s_low"
        s_low = selected("Spectrum")
        Filter (pass Hann band): 0, low_hi_crossover1_hz, 100
        To Sound
        lowB = selected("Sound")

        selectObject: s_all
        Copy: "s_mid"
        s_mid = selected("Spectrum")
        Filter (pass Hann band): low_hi_crossover1_hz, low_hi_crossover2_hz, 200
        To Sound
        midB = selected("Sound")

        selectObject: s_all
        Copy: "s_high"
        s_high = selected("Spectrum")
        Filter (pass Hann band): low_hi_crossover2_hz, high_band_top_hz, 500
        To Sound
        highB = selected("Sound")

        # dispose spectra
        selectObject: s_low
        Remove
        selectObject: s_mid
        Remove
        selectObject: s_high
        Remove
        selectObject: s_all
        Remove

        # apply gains
        selectObject: lowB
        Formula: "self * 'gL'"
        selectObject: midB
        Formula: "self * 'gM'"
        selectObject: highB
        Formula: "self * 'gH'"

        # Mix to mono
        selectObject: lowB, midB
        Combine to stereo
        stereo1 = selected("Sound")
        Convert to mono
        lowMid = selected("Sound")

        selectObject: lowMid, highB
        Combine to stereo
        stereo2 = selected("Sound")
        Convert to mono
        segOut = selected("Sound")

        # cleanup intermed stereo
        selectObject: stereo1
        Remove
        selectObject: stereo2
        Remove
        selectObject: lowMid
        Remove

        if firstDone = 0
            selectObject: segOut
            Copy: origName$ + "_PCATone"
            outS = selected("Sound")
            firstDone = 1
            selectObject: segOut
            Remove
        else
            selectObject: outS
            plusObject: segOut
            Concatenate recoverably
            newOut = selected("Sound")
            selectObject: outS
            Remove
            selectObject: segOut
            Remove
            outS = newOut
        endif

        # cleanup chunk bits
        selectObject: seg
        Remove
        selectObject: lowB
        Remove
        selectObject: midB
        Remove
        selectObject: highB
        Remove
    endif
endfor

# ===== finalize & report =====
selectObject: outS
Scale peak: headroom

writeInfoLine: "=== PCA Tone Shaper (chunked) ==="
appendInfoLine: "Duration: ", fixed$ (dur, 3), " s | Fs: ", fs, " Hz"
appendInfoLine: "Chunk: ", chunk_ms, " ms"
appendInfoLine: "Bands (Hz): Low 0–", low_hi_crossover1_hz, " | Mid ", low_hi_crossover1_hz, "–", low_hi_crossover2_hz, " | High ", low_hi_crossover2_hz, "–", high_band_top_hz
appendInfoLine: "Strength: ", fixed$ (pca_strength, 2)

selectObject: pca
frac = Get fraction variance accounted for: 1, 3
expl = 100 * frac
appendInfoLine: "Explained variance PC1..3: ", fixed$ (expl, 1), "%"

if play_result <> 0
    selectObject: outS
    Play
endif

# ===== KEEP ONLY original + result (nuclear cleanup) =====
# Select everything, then deselect the two sounds we want to keep, then remove the rest.
select all
if origSnd <> 0
    minusObject: origSnd
endif
if outS <> 0
    minusObject: outS
endif
Remove

# Re-select the two survivors (optional)
selectObject: origSnd
plusObject: outS