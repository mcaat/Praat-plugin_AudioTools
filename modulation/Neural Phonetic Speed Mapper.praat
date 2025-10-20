form Neural Phonetic Speed Mapper (FFNet, Adaptive++)
    positive confidence_threshold 0.10
    positive smooth_ms 20
    positive change_tolerance 0.03
    positive min_seg_ms 35
    positive max_gap_ms 100
    positive contrast_gain 2.2
    positive temperature 0.5

    positive speed_vowel 3.2
    positive speed_fric 0.30
    positive speed_other 2.4
    positive speed_silence 1.0

    boolean enable_vowel 1
    boolean enable_fric 1
    boolean enable_other 1
    boolean enable_silence 1

    positive voiced_boost 0.35

    integer hidden_units 24
    integer training_iterations 1000
    integer train_chunk 100
    positive early_stop_delta 0.005
    integer early_stop_patience 3

    positive learning_rate 0.001
    positive frame_step_seconds 0.005
    positive max_formant_hz 5500
    positive vowel_hnr_threshold 5.0
    positive fricative_hnr_max 3.0
    positive silence_intensity_threshold 45

    integer force_every_frames 2
    boolean Play_result 0
endform

sound = selected("Sound")
sound_name$ = selected$("Sound")
if sound = 0
    exitScript: "Error: No sound selected."
endif

selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency
if duration <= 0
    exitScript: "Error: No sound selected (zero/neg duration)."
endif
if duration < frame_step_seconds
    exitScript: "Error: Sound duration too short for frame_step_seconds."
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

rows_target = round(duration / frame_step_seconds)
if rows_target < 1
    rows_target = 1
endif
n_features = 18

Create TableOfReal: "features", rows_target, n_features
feature_matrix = selected("TableOfReal")

selectObject: feature_matrix
rows = Get number of rows
cols = Get number of columns
eps = frame_step_seconds * 0.25
if eps <= 0
    eps = 0.001
endif

for iframe from 1 to rows
    raw_time = frame_step_seconds * (iframe - 0.5)
    if raw_time < 0
        time = 0
    elsif raw_time > duration - eps
        time = duration - eps
    else
        time = raw_time
    endif

    iI = iframe
    if iI > nFrames_int
        iI = nFrames_int
    endif
    if iI < 1
        iI = 1
    endif

    iH = iframe
    if iH > nFrames_hnr
        iH = nFrames_hnr
    endif
    if iH < 1
        iH = 1
    endif

    iP = iframe
    if iP > nFrames_f0
        iP = nFrames_f0
    endif
    if iP < 1
        iP = 1
    endif

    iM = iframe
    if iM > nFrames_mfcc
        iM = nFrames_mfcc
    endif
    if iM < 1
        iM = 1
    endif

    for icoef from 1 to 12
        selectObject: mfcc
        v = Get value in frame: iM, icoef
        if v = undefined or v <> v
            v = 0
        endif
        selectObject: feature_matrix
        if icoef <= 3
            Set value: iframe, icoef, v
        else
            Set value: iframe, 9 + icoef - 3, v
        endif
    endfor

    selectObject: formant
    f1 = Get value at time: 1, time, "Hertz", "Linear"
    f2 = Get value at time: 2, time, "Hertz", "Linear"
    f3 = Get value at time: 3, time, "Hertz", "Linear"
    if f1 = undefined or f1 <> f1
        f1 = 500
    endif
    if f2 = undefined or f2 <> f2
        f2 = 1500
    endif
    if f3 = undefined or f3 <> f3
        f3 = 2500
    endif
    selectObject: feature_matrix
    Set value: iframe, 4, f1 / 1000
    Set value: iframe, 5, f2 / 1000
    Set value: iframe, 6, f3 / 1000

    selectObject: intensity
    it = Get value in frame: iI
    if it = undefined or it <> it
        it = 60
    endif
    selectObject: feature_matrix
    Set value: iframe, 7, (it - 60) / 20

    selectObject: harmonicity
    hnr = Get value in frame: iH
    if hnr = undefined or hnr <> hnr
        hnr = 0
    endif
    selectObject: feature_matrix
    Set value: iframe, 8, hnr / 20

    selectObject: pitch
    f0 = Get value in frame: iP, "Hertz"
    if f0 = undefined or f0 <> f0 or f0 <= 0
        z = 0.5
    else
        z = f0 / 500
        if z <= 0
            z = 0.5
        endif
    endif
    selectObject: feature_matrix
    Set value: iframe, 9, z
endfor

Create Categories: "output_categories"
output_categories = selected("Categories")
for iframe from 1 to rows
    raw_time = frame_step_seconds * (iframe - 0.5)
    if raw_time < 0
        time = 0
    elsif raw_time > duration - eps
        time = duration - eps
    else
        time = raw_time
    endif

    selectObject: intensity
    int_val = Get value at time: time, "cubic"
    if int_val = undefined or int_val <> int_val
        int_val = 60
    endif
    selectObject: harmonicity
    hnr_val = Get value at time: time, "cubic"
    if hnr_val = undefined or hnr_val <> hnr_val
        hnr_val = 0
    endif
    selectObject: formant
    f1_val = Get value at time: 1, time, "Hertz", "Linear"
    if f1_val = undefined or f1_val <> f1_val
        f1_val = 500
    endif
    selectObject: pitch
    f0_val = Get value at time: time, "Hertz", "Linear"
    if f0_val = undefined or f0_val <> f0_val
        f0_val = 0
    endif

    selectObject: output_categories
    if int_val < silence_intensity_threshold
        Append category: "silence"
    elsif hnr_val > vowel_hnr_threshold and f0_val > 0 and f1_val > 300
        Append category: "vowel"
    elsif int_val > silence_intensity_threshold and hnr_val < fricative_hnr_max and f0_val = 0
        Append category: "fricative"
    else
        Append category: "other"
    endif
endfor

selectObject: output_categories
n_categories = Get number of categories
if n_categories <> rows
    exitScript: "Error: Categories size mismatch."
endif

selectObject: feature_matrix
for j from 1 to cols
    col_min = 1e30
    col_max = -1e30
    for i from 1 to rows
        val = Get value: i, j
        if val = undefined or val <> val
            val = 0
        endif
        if val < col_min
            col_min = val
        endif
        if val > col_max
            col_max = val
        endif
    endfor
    range = col_max - col_min
    if range = undefined or range <> range or range = 0
        range = 1
    endif
    for i from 1 to rows
        val = Get value: i, j
        if val = undefined or val <> val
            val = 0
        endif
        norm = (val - col_min) / range
        if norm = undefined or norm <> norm
            norm = 0
        endif
        Set value: i, j, norm
    endfor
endfor

selectObject: feature_matrix
To Matrix
feature_matrix_m = selected("Matrix")

selectObject: feature_matrix_m
To Pattern: 1
pattern = selected("PatternList")

selectObject: pattern, output_categories
To FFNet: 'hidden_units', 0
ffnet = selected("FFNet")

total_trained = 0
stale_chunks = 0
prevActID = 0
chunk_count = 0
early_stopped = 0

while total_trained < training_iterations
    remaining = training_iterations - total_trained
    this_chunk = train_chunk
    if this_chunk > remaining
        this_chunk = remaining
    endif

    selectObject: ffnet, pattern, output_categories
    Learn: this_chunk, learning_rate, "Minimum-squared-error"
    total_trained = total_trained + this_chunk
    chunk_count = chunk_count + 1

    selectObject: ffnet, pattern
    To ActivationList: 1
    activ_tmp = selected("Activation")
    selectObject: activ_tmp
    To Matrix
    actID = selected("Matrix")
    selectObject: activ_tmp
    Remove

    if prevActID = 0
        prevActID = actID
    else
        selectObject: prevActID
        nR_prev = Get number of rows
        nC_prev = Get number of columns

        selectObject: actID
        nR_cur = Get number of rows
        nC_cur = Get number of columns

        nR = nR_prev
        if nR_cur < nR
            nR = nR_cur
        endif
        nC = nC_prev
        if nC_cur < nC
            nC = nC_cur
        endif
        if nR < 1
            nR = 1
        endif
        if nC < 1
            nC = 1
        endif

        maxSample = 100
        stepR = 1
        if nR > maxSample
            stepR = round(nR / maxSample)
            if stepR < 1
                stepR = 1
            endif
        endif

        sumdiff = 0
        countd = 0
        r = 1
        while r <= nR
            for c from 1 to nC
                selectObject: prevActID
                v1 = Get value in cell: r, c
                if v1 = undefined or v1 <> v1
                    v1 = 0
                endif
                selectObject: actID
                v2 = Get value in cell: r, c
                if v2 = undefined or v2 <> v2
                    v2 = 0
                endif
                d = v1 - v2
                if d < 0
                    d = -d
                endif
                sumdiff = sumdiff + d
                countd = countd + 1
            endfor
            r = r + stepR
        endwhile

        if countd = 0
            meanDiff = 0
        else
            meanDiff = sumdiff / countd
        endif

        selectObject: prevActID
        Remove
        prevActID = actID

        if meanDiff < early_stop_delta
            stale_chunks = stale_chunks + 1
        else
            stale_chunks = 0
        endif
        if stale_chunks >= early_stop_patience
            early_stopped = 1
            total_trained = training_iterations
        endif
    endif
endwhile

if prevActID <> 0
    selectObject: prevActID
    Remove
endif

selectObject: ffnet, pattern
To ActivationList: 1
activations = selected("Activation")

selectObject: activations
To Matrix
activation_matrix = selected("Matrix")

selectObject: sound
Copy: sound_name$ + "_ffnet_speed"
output_sound = selected("Sound")

durationTier = Create DurationTier: "ffnet_dur", 0, duration
selectObject: durationTier
epsT = 1e-6

Create TableOfReal: "frameFactor", rows, 1
frameFactor = selected("TableOfReal")

for iframe from 1 to rows
    selectObject: activation_matrix
    a1 = Get value in cell: iframe, 1
    a2 = Get value in cell: iframe, 2
    a3 = Get value in cell: iframe, 3
    a4 = Get value in cell: iframe, 4
    if a1 = undefined or a1 <> a1
        a1 = 0
    endif
    if a2 = undefined or a2 <> a2
        a2 = 0
    endif
    if a3 = undefined or a3 <> a3
        a3 = 0
    endif
    if a4 = undefined or a4 <> a4
        a4 = 0
    endif

    if enable_vowel = 0
        a1 = 0
    endif
    if enable_fric = 0
        a2 = 0
    endif
    if enable_other = 0
        a3 = 0
    endif
    if enable_silence = 0
        a4 = 0
    endif

    tdiv = temperature
    if tdiv <= 0.0001
        tdiv = 0.0001
    endif
    e1 = exp(a1 / tdiv)
    e2 = exp(a2 / tdiv)
    e3 = exp(a3 / tdiv)
    e4 = exp(a4 / tdiv)
    denom = e1 + e2 + e3 + e4
    if denom <= 0
        denom = 1e-12
    endif
    w1 = e1 / denom
    w2 = e2 / denom
    w3 = e3 / denom
    w4 = e4 / denom

    s1 = speed_vowel
    if enable_vowel = 0
        s1 = 1.0
    endif
    s2 = speed_fric
    if enable_fric = 0
        s2 = 1.0
    endif
    s3 = speed_other
    if enable_other = 0
        s3 = 1.0
    endif
    s4 = speed_silence
    if enable_silence = 0
        s4 = 1.0
    endif

    weighted = w1*s1 + w2*s2 + w3*s3 + w4*s4

    selectObject: harmonicity
    h = Get value in frame: iframe
    if h = undefined or h <> h
        h = 0
    endif
    vh = (h - 0) / 15
    if vh < 0
        vh = 0
    endif
    if vh > 1
        vh = 1
    endif

    selectObject: pitch
    f0c = Get value in frame: iframe, "Hertz"
    vflag = 0
    if f0c > 0
        vflag = 1
    endif
    voicedness = (0.5*vh + 0.5*vflag)
    adapt_weight = 1 + voiced_boost * (voicedness - 0.5) * 2
    weighted = 1 + adapt_weight * (weighted - 1)

    max_a = a1
    if a2 > max_a
        max_a = a2
    endif
    if a3 > max_a
        max_a = a3
    endif
    if a4 > max_a
        max_a = a4
    endif
    mix = (max_a - confidence_threshold) / (1 - confidence_threshold)
    if mix < 0
        mix = 0
    endif
    if mix > 1
        mix = 1
    endif

    factor = 1 + contrast_gain * mix * (weighted - 1)
    selectObject: frameFactor
    Set value: iframe, 1, factor
endfor

Create TableOfReal: "frameFactorSm", rows, 1
frameFactorSm = selected("TableOfReal")

win = round(smooth_ms / (1000 * frame_step_seconds))
if win < 1
    win = 1
endif

for i from 1 to rows
    i1 = i - win
    if i1 < 1
        i1 = 1
    endif
    i2 = i + win
    if i2 > rows
        i2 = rows
    endif
    sumv = 0
    countv = 0
    for k from i1 to i2
        selectObject: frameFactor
        v = Get value: k, 1
        if v = undefined or v <> v
            v = 1
        endif
        sumv = sumv + v
        countv = countv + 1
    endfor
    sm = sumv / countv
    selectObject: frameFactorSm
    Set value: i, 1, sm
endfor

min_seg = min_seg_ms / 1000
max_gap = max_gap_ms / 1000
segments_written = 0

selectObject: frameFactorSm
v0 = Get value: 1, 1
if v0 = undefined or v0 <> v0
    v0 = 1.0
endif

last_written_factor = v0
last_write_t = 0
cum_change = 0
last_forced_i = 1

selectObject: durationTier
Add point: 0, v0

for i from 2 to rows
    frame_center = frame_step_seconds * (i - 0.5)
    t = frame_center

    selectObject: frameFactorSm
    v = Get value: i, 1
    if v = undefined or v <> v
        v = last_written_factor
    endif

    dv = v - last_written_factor
    if dv < 0
        dv = -dv
    endif
    cum_change = cum_change + dv

    time_since = t - last_write_t
    do_force = 0
    if (i - last_forced_i) >= force_every_frames and time_since >= min_seg
        do_force = 1
    endif

    if ( (cum_change >= change_tolerance and time_since >= min_seg) or (time_since >= max_gap) or (do_force = 1) )
        selectObject: durationTier
        Add point: t, v
        last_written_factor = v
        last_write_t = t
        last_forced_i = i
        cum_change = 0
        segments_written = segments_written + 1
    endif
endfor

selectObject: durationTier
epsT = 1e-6
t_end_minus = duration - epsT
if t_end_minus < 0
    t_end_minus = 0
endif
Add point: t_end_minus, last_written_factor
Add point: duration, 1.0

selectObject: output_sound
manip = To Manipulation: 0.01, 75, 600
selectObject: manip
plusObject: durationTier
Replace duration tier
selectObject: manip
resynth = Get resynthesis (overlap-add)

selectObject: resynth
Scale peak: 0.99
Rename: sound_name$ + "_ffnet_speeded_adaptive_es"

clearinfo
writeInfoLine: "=== NEURAL FFNet SPEED (EARLY-STOP) ==="
appendInfo: "Frames (targeted): ", rows, newline$
appendInfo: "MFCC frames (raw): ", nFrames_mfcc, newline$
appendInfo: "Segments written: ", segments_written, newline$
appendInfo: "Smooth window (frames): ", win, newline$
appendInfo: "Change tolerance: ", change_tolerance, newline$
appendInfo: "Min seg (ms): ", min_seg_ms, "   Max gap (ms): ", max_gap_ms, newline$
appendInfo: "Contrast: ", contrast_gain, "   Temp: ", temperature, "   Voiced boost: ", voiced_boost, newline$
appendInfo: "Speeds (vowel, fric, other, silence): ", speed_vowel, ", ", speed_fric, ", ", speed_other, ", ", speed_silence, newline$
appendInfo: "Training chunks: ", chunk_count, "   Epochs trained: ", total_trained, " / ", training_iterations, newline$
appendInfo: "Early stopped: ", early_stopped, "   Delta: ", early_stop_delta, "   Patience: ", early_stop_patience, newline$

selectObject: pitch
plusObject: intensity
plusObject: formant
plusObject: mfcc
plusObject: harmonicity
plusObject: feature_matrix
plusObject: feature_matrix_m
plusObject: pattern
plusObject: output_categories
plusObject: ffnet
plusObject: activations
plusObject: activation_matrix
plusObject: frameFactor
plusObject: frameFactorSm
plusObject: durationTier
plusObject: manip
plusObject: output_sound
Remove

if play_result
    selectObject: resynth
    Play
endif

selectObject: resynth
