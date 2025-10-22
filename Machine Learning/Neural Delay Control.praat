# ============================================================
# Praat AudioTools - Neural Delay Control (FFNet with adaptive feedback)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Delay Control (FFNet with adaptive feedback)

# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Neural Delay Control (FFNet with adaptive feedback)
    positive frame_step_seconds 0.02
    positive smooth_ms 40
    positive max_formant_hz 5500
    integer hidden_units 24
    integer training_epochs 60
    positive learn_tolerance 1e-6
    positive delay_time_ms 250
    positive feedback_base 0.4
    positive mix_base 0.3
    positive transient_suppression 0.25
    positive hnr_gain 0.3
    positive f0_bonus 0.15
    boolean play_result 0
endform

sound = selected("Sound")
sound_name$ = selected$("Sound")
if sound = 0
    exitScript: "No sound selected."
endif

selectObject: sound
duration = Get total duration
fs = Get sampling frequency
nChannels = Get number of channels
if duration <= 0
    exitScript: "Invalid sound duration."
endif
if duration < frame_step_seconds
    exitScript: "Sound too short for given frame step."
endif

if nChannels > 1
    selectObject: sound
    Convert to mono
    sound = selected("Sound")
endif

selectObject: sound
To Pitch: 0, 75, 600
pitch = selected("Pitch")
selectObject: sound
To Intensity: 75, 0, "yes"
intensity = selected("Intensity")
selectObject: sound
To Formant (burg): 0, 5, max_formant_hz, 0.025, 50
formant = selected("Formant")
selectObject: sound
To MFCC: 12, 0.025, frame_step_seconds, 100, 100, 0
mfcc = selected("MFCC")
selectObject: sound
To Harmonicity (cc): frame_step_seconds, 75, 0.1, 1.0
harmonicity = selected("Harmonicity")

selectObject: mfcc
nFrames_mfcc = Get number of frames
if nFrames_mfcc <= 0
    nFrames_mfcc = 1
endif
selectObject: intensity
nFrames_int = Get number of frames
if nFrames_int <= 0
    nFrames_int = 1
endif
selectObject: harmonicity
nFrames_hnr = Get number of frames
if nFrames_hnr <= 0
    nFrames_hnr = 1
endif
selectObject: pitch
nFrames_f0 = Get number of frames
if nFrames_f0 <= 0
    nFrames_f0 = 1
endif

rows_target = round (duration / frame_step_seconds)
if rows_target < 1
    rows_target = 1
endif
n_features = 18

Create TableOfReal: "features", rows_target, n_features
xtab = selected("TableOfReal")
Create TableOfReal: "targets", rows_target, 2
ytab = selected("TableOfReal")

selectObject: xtab
rows = Get number of rows
cols = Get number of columns
eps = frame_step_seconds * 0.25
if eps <= 0
    eps = 0.001
endif

prev_int = undefined

for i from 1 to rows
    t_raw = frame_step_seconds * (i - 0.5)
    if t_raw < 0
        t = 0
    elsif t_raw > duration - eps
        t = duration - eps
    else
        t = t_raw
    endif

    iI = i
    if iI > nFrames_int
        iI = nFrames_int
    endif
    if iI < 1
        iI = 1
    endif

    iH = i
    if iH > nFrames_hnr
        iH = nFrames_hnr
    endif
    if iH < 1
        iH = 1
    endif

    iP = i
    if iP > nFrames_f0
        iP = nFrames_f0
    endif
    if iP < 1
        iP = 1
    endif

    iM = i
    if iM > nFrames_mfcc
        iM = nFrames_mfcc
    endif
    if iM < 1
        iM = 1
    endif

    for c from 1 to 12
        selectObject: mfcc
        v = Get value in frame: iM, c
        if v = undefined or v <> v
            v = 0
        endif
        selectObject: xtab
        if c <= 3
            Set value: i, c, v
        else
            Set value: i, 9 + c - 3, v
        endif
    endfor

    selectObject: formant
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    if f1 = undefined or f1 <> f1
        f1 = 500
    endif
    if f2 = undefined or f2 <> f2
        f2 = 1500
    endif
    if f3 = undefined or f3 <> f3
        f3 = 2500
    endif

    selectObject: xtab
    Set value: i, 4, f1 / 1000
    Set value: i, 5, f2 / 1000
    Set value: i, 6, f3 / 1000

    selectObject: intensity
    iv = Get value at time: t, "cubic"
    if iv = undefined or iv <> iv
        iv = 60
    endif
    selectObject: xtab
    Set value: i, 7, (iv - 60) / 20

    selectObject: harmonicity
    hnr = Get value at time: t, "cubic"
    if hnr = undefined or hnr <> hnr
        hnr = 0
    endif
    selectObject: xtab
    Set value: i, 8, hnr / 20

    selectObject: pitch
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <> f0 or f0 <= 0
        z = 0.0
    else
        z = f0 / 500
        if z < 0
            z = 0
        endif
        if z > 1
            z = 1
        endif
    endif
    selectObject: xtab
    Set value: i, 9, z

    if prev_int = undefined or prev_int <> prev_int
        dI = 0
    else
        dI = iv - prev_int
        if dI < 0
            dI = -dI
        endif
    endif
    prev_int = iv

    hnr_n = hnr / 20
    if hnr_n < 0
        hnr_n = 0
    endif
    if hnr_n > 1
        hnr_n = 1
    endif

    f0v = 0
    if f0 > 0
        f0v = 1
    endif

    trans = dI / 30
    if trans > 1
        trans = 1
    endif
    if trans < 0
        trans = 0
    endif

    mix0 = mix_base + hnr_gain * hnr_n + f0_bonus * f0v - transient_suppression * trans
    if mix0 < 0.05
        mix0 = 0.05
    endif
    if mix0 > 0.8
        mix0 = 0.8
    endif

    fb0 = feedback_base + 0.3 * hnr_n - 0.25 * trans
    if fb0 < 0.1
        fb0 = 0.1
    endif
    if fb0 > 0.7
        fb0 = 0.7
    endif

    selectObject: ytab
    Set value: i, 1, mix0
    Set value: i, 2, fb0
endfor

selectObject: xtab
rows = Get number of rows
cols = Get number of columns
for j from 1 to cols
    cmin = 1e30
    cmax = -1e30
    for i from 1 to rows
        v = Get value: i, j
        if v = undefined or v <> v
            v = 0
        endif
        if v < cmin
            cmin = v
        endif
        if v > cmax
            cmax = v
        endif
    endfor
    rng = cmax - cmin
    if rng = 0
        rng = 1
    endif
    for i from 1 to rows
        v = Get value: i, j
        if v = undefined or v <> v
            v = 0
        endif
        nv = (v - cmin) / rng
        Set value: i, j, nv
    endfor
endfor

selectObject: ytab
rows_y = Get number of rows
cols_y = Get number of columns
for j from 1 to cols_y
    for i from 1 to rows_y
        v = Get value: i, j
        if v = undefined or v <> v
            v = 0.5
        endif
        if v < 0
            v = 0
        endif
        if v > 1
            v = 1
        endif
        Set value: i, j, v
    endfor
endfor

selectObject: ytab
To Matrix
ymat = selected("Matrix")
selectObject: ymat
To ActivationList
yal = selected("ActivationList")

selectObject: xtab
To Matrix
xmat = selected("Matrix")
selectObject: xmat
To Pattern: 1
pat = selected("Pattern")

nin = n_features
nout = 2
Create FFNet (linear outputs): "ffnet", nin, nout, hidden_units, 0
ff = selected("FFNet")

maxEpochs = training_epochs
tolerance = learn_tolerance
early_stopped = 0
epoch = 0
last_cost = 1e30

while epoch < maxEpochs
    epoch = epoch + 1
    selectObject: ff, pat, yal
    Learn: 1, tolerance, "Minimum-squared-error"
    selectObject: ff, pat, yal
    cost = Get total costs: "Minimum-squared-error"
    diff = cost - last_cost
    if diff < 0
        diff = -diff
    endif
    if diff < tolerance
        early_stopped = 1
        break
    endif
    last_cost = cost
endwhile

selectObject: ff, pat
To ActivationList: 1
afinal = selected("ActivationList")
selectObject: afinal
To Matrix
ypred = selected("Matrix")
selectObject: ypred
Formula: "if self < 0 then 0 else if self > 1 then 1 else self fi fi"

win = round (smooth_ms / (1000 * frame_step_seconds))
if win < 1
    win = 1
endif

Create TableOfReal: "Ctrl", rows, 2
ctrl = selected("TableOfReal")

for i from 1 to rows
    i1 = i - win
    if i1 < 1
        i1 = 1
    endif
    i2 = i + win
    if i2 > rows
        i2 = rows
    endif
    s1 = 0
    s2 = 0
    n = 0
    for k from i1 to i2
        selectObject: ypred
        mixv = Get value in cell: k, 1
        fbv = Get value in cell: k, 2
        if mixv = undefined or mixv <> mixv
            mixv = 0.3
        endif
        if fbv = undefined or fbv <> fbv
            fbv = 0.4
        endif
        s1 = s1 + mixv
        s2 = s2 + fbv
        n = n + 1
    endfor
    mixsm = s1 / n
    fbsm = s2 / n
    selectObject: ctrl
    Set value: i, 1, mixsm
    Set value: i, 2, fbsm
endfor

selectObject: sound
nSamples = Get number of samples
delaySamples = round (delay_time_ms * 0.001 * fs)
if delaySamples < 1
    delaySamples = 1
endif

Create Sound from formula: sound_name$ + "_delay", 1, 0, duration, fs, "0"
outS = selected("Sound")

for n from 1 to nSamples
    frameIdx = round (n / (fs * frame_step_seconds)) + 1
    if frameIdx < 1
        frameIdx = 1
    endif
    if frameIdx > rows
        frameIdx = rows
    endif
    
    selectObject: ctrl
    mix = Get value: frameIdx, 1
    feedback = Get value: frameIdx, 2
    
    selectObject: sound
    dry = Get value at sample number: 1, n
    
    delayed = 0
    nDelayed = n - delaySamples
    if nDelayed >= 1
        selectObject: outS
        delayed = Get value at sample number: 1, nDelayed
    endif
    
    y = dry + mix * feedback * delayed
    
    selectObject: outS
    Set value at sample number: 1, n, y
endfor

selectObject: outS
Scale peak: 0.99

selectObject: ctrl
To Matrix
ctrlMat = selected("Matrix")
selectObject: ctrlMat
nRows = Get number of rows

writeInfoLine: "=== Neural Delay System Analysis ==="
appendInfoLine: ""
appendInfoLine: "Input Audio:"
selectObject: sound
dur = Get total duration
srate = Get sampling frequency
appendInfoLine: "  Duration: ", fixed$ (dur, 3), " seconds"
appendInfoLine: "  Sample rate: ", srate, " Hz"
appendInfoLine: ""
appendInfoLine: "Delay Parameters:"
appendInfoLine: "  Delay time: ", delay_time_ms, " ms"
appendInfoLine: "  Base mix: ", fixed$ (mix_base, 3)
appendInfoLine: "  Base feedback: ", fixed$ (feedback_base, 3)
appendInfoLine: ""
appendInfoLine: "Neural Network:"
appendInfoLine: "  Training epochs: ", training_epochs
appendInfoLine: "  Hidden units: ", hidden_units
appendInfoLine: "  Input features: ", n_features
appendInfoLine: "  Outputs: 2 (mix, feedback)"
appendInfoLine: ""

selectObject: ctrlMat
mixMin = 1
mixMax = 0
fbMin = 1
fbMax = 0
mixSum = 0
fbSum = 0
for i from 1 to nRows
    m = Get value in cell: i, 1
    f = Get value in cell: i, 2
    if m < mixMin
        mixMin = m
    endif
    if m > mixMax
        mixMax = m
    endif
    if f < fbMin
        fbMin = f
    endif
    if f > fbMax
        fbMax = f
    endif
    mixSum = mixSum + m
    fbSum = fbSum + f
endfor
mixMean = mixSum / nRows
fbMean = fbSum / nRows

mixSumSq = 0
fbSumSq = 0
for i from 1 to nRows
    m = Get value in cell: i, 1
    f = Get value in cell: i, 2
    mixSumSq = mixSumSq + (m - mixMean) ^ 2
    fbSumSq = fbSumSq + (f - fbMean) ^ 2
endfor
mixStdev = sqrt (mixSumSq / nRows)
fbStdev = sqrt (fbSumSq / nRows)

appendInfoLine: "Control Parameter Statistics:"
appendInfoLine: "  Mix - Mean: ", fixed$ (mixMean, 3), " | Range: [", fixed$ (mixMin, 3), ", ", fixed$ (mixMax, 3), "] | StDev: ", fixed$ (mixStdev, 3)
appendInfoLine: "  Feedback - Mean: ", fixed$ (fbMean, 3), " | Range: [", fixed$ (fbMin, 3), ", ", fixed$ (fbMax, 3), "] | StDev: ", fixed$ (fbStdev, 3)
appendInfoLine: ""
appendInfoLine: "Adaptation Strategy:"
appendInfoLine: "  • Higher harmonicity (tonal sounds) → more mix & feedback"
appendInfoLine: "  • Pitched sounds (f0 detected) → increased effect"
appendInfoLine: "  • Transients (sudden changes) → reduced effect"
appendInfoLine: "  • Smoothing window: ", smooth_ms, " ms"
appendInfoLine: ""

appendInfoLine: "Sample Control Values (first 10 frames):"
appendInfoLine: "  Frame | Time(s) | Mix   | Feedback"
for i from 1 to 10
    if i <= nRows
        t = frame_step_seconds * (i - 0.5)
        selectObject: ctrlMat
        m = Get value in cell: i, 1
        f = Get value in cell: i, 2
        appendInfoLine: "  ", i, "     | ", fixed$ (t, 3), "   | ", fixed$ (m, 3), " | ", fixed$ (f, 3)
    endif
endfor
appendInfoLine: ""
appendInfoLine: "Processing complete!"
# --- Cleanup: keep only original input (sound) and output (outS) ---
procedure SafeRemove (id)
    if id <> 0 and id <> sound and id <> outS
        selectObject: id
        Remove
    endif
endproc

# Remove analysis & training artifacts
call SafeRemove: pitch
call SafeRemove: intensity
call SafeRemove: formant
call SafeRemove: mfcc
call SafeRemove: harmonicity

call SafeRemove: xtab       ; "features" TableOfReal
call SafeRemove: ytab       ; "targets"  TableOfReal
call SafeRemove: ymat       ; Matrix from ytab
call SafeRemove: yal        ; ActivationList (targets)
call SafeRemove: xmat       ; Matrix from xtab
call SafeRemove: pat        ; Pattern from xmat
call SafeRemove: ff         ; FFNet
call SafeRemove: afinal     ; ActivationList (predictions)
call SafeRemove: ypred      ; Matrix from afinal
call SafeRemove: ctrl       ; "Ctrl" TableOfReal
call SafeRemove: ctrlMat    ; Matrix from "Ctrl"
# --- End cleanup ---


if play_result <> 0
    selectObject: outS
    Play
endif

selectObject: outS