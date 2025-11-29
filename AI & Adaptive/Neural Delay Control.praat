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

# Neural Delay Control (FFNet with adaptive feedback) 
# - Fixed "No sound selected" error by using strict ID tracking.
# - Preserves original sound.
# - Validates selection at every step.

form Neural Delay Control
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
    boolean play_result 1
endform

# --- 1. Setup and Preprocessing ---

# Check number of selected sounds
nSelected = numberOfSelected("Sound")
if nSelected <> 1
    exitScript: "Please select exactly one Sound object."
endif

original_sound = selected("Sound")
original_name$ = selected$("Sound")

selectObject: original_sound
duration = Get total duration
fs = Get sampling frequency
nChannels = Get number of channels

if duration < frame_step_seconds
    exitScript: "Sound too short for given frame step."
endif

# WORK ON A COPY (Preserve Original)
selectObject: original_sound
Copy: "Analysis_Copy"
sound_work = selected("Sound")

# Ensure Mono for analysis (ID-Safe Method)
if nChannels > 1
    selectObject: sound_work
    # Convert to mono creates a new object and selects it
    Convert to mono
    sound_mono_id = selected("Sound")
    
    # Remove the stereo copy
    selectObject: sound_work
    Remove
    
    # Update our working ID to the new mono sound
    sound_work = sound_mono_id
    selectObject: sound_work
    Rename: "Analysis_Copy"
endif

# Verify we still have a sound
if not sound_work
    exitScript: "Error: Lost track of the sound object during setup."
endif

# --- 2. Feature Extraction ---

selectObject: sound_work
To Pitch: 0, 75, 600
pitch = selected("Pitch")

selectObject: sound_work
To Intensity: 75, 0, "yes"
intensity = selected("Intensity")

selectObject: sound_work
To Formant (burg): 0, 5, max_formant_hz, 0.025, 50
formant = selected("Formant")

selectObject: sound_work
To MFCC: 12, 0.025, frame_step_seconds, 100, 100, 0
mfcc = selected("MFCC")

selectObject: sound_work
To Harmonicity (cc): frame_step_seconds, 75, 0.1, 1.0
harmonicity = selected("Harmonicity")

# Get Frame Counts
selectObject: mfcc
nFrames_mfcc = Get number of frames
selectObject: intensity
nFrames_int = Get number of frames
selectObject: harmonicity
nFrames_hnr = Get number of frames
selectObject: pitch
nFrames_f0 = Get number of frames

rows_target = round(duration / frame_step_seconds)
if rows_target < 1
    rows_target = 1
endif
n_features = 18

Create TableOfReal: "features", rows_target, n_features
xtab = selected("TableOfReal")
Create TableOfReal: "targets", rows_target, 2
ytab = selected("TableOfReal")

# --- 3. Dataset Generation (Heuristics) ---

selectObject: xtab
eps = frame_step_seconds * 0.25
prev_int = undefined

for i from 1 to rows_target
    t_raw = frame_step_seconds * (i - 0.5)
    t = t_raw
    if t < 0
        t = 0
    elsif t > duration - eps
        t = duration - eps
    endif

    # -- Safe Indexing --
    iM = i
    if iM > nFrames_mfcc
        iM = nFrames_mfcc
    endif

    # -- MFCC Extraction --
    for c from 1 to 12
        selectObject: mfcc
        v = Get value in frame: iM, c
        if v = undefined
            v = 0
        endif
        selectObject: xtab
        if c <= 3
            Set value: i, c, v
        else
            Set value: i, 9 + c - 3, v
        endif
    endfor

    # -- Formant Extraction --
    selectObject: formant
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    if f1 = undefined
        f1 = 500
    endif
    if f2 = undefined
        f2 = 1500
    endif
    if f3 = undefined
        f3 = 2500
    endif
    
    selectObject: xtab
    Set value: i, 4, f1 / 1000
    Set value: i, 5, f2 / 1000
    Set value: i, 6, f3 / 1000

    # -- Intensity Extraction --
    selectObject: intensity
    iv = Get value at time: t, "cubic"
    if iv = undefined
        iv = 60
    endif
    selectObject: xtab
    Set value: i, 7, (iv - 60) / 20

    # -- Harmonicity Extraction --
    selectObject: harmonicity
    hnr = Get value at time: t, "cubic"
    if hnr = undefined
        hnr = 0
    endif
    selectObject: xtab
    Set value: i, 8, hnr / 20

    # -- Pitch Extraction --
    selectObject: pitch
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        z = 0.0
    else
        z = f0 / 500
        if z > 1
            z = 1
        endif
    endif
    selectObject: xtab
    Set value: i, 9, z

    # -- Target Calculation (Heuristics) --
    if prev_int = undefined
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
    elsif hnr_n > 1
        hnr_n = 1
    endif

    f0v = 0
    if f0 > 0
        f0v = 1
    endif

    trans = dI / 30
    if trans > 1
        trans = 1
    elsif trans < 0
        trans = 0
    endif

    # Target Logic
    mix0 = mix_base + hnr_gain * hnr_n + f0_bonus * f0v - transient_suppression * trans
    if mix0 < 0.05
        mix0 = 0.05
    elsif mix0 > 0.8
        mix0 = 0.8
    endif

    fb0 = feedback_base + 0.3 * hnr_n - 0.25 * trans
    if fb0 < 0.1
        fb0 = 0.1
    elsif fb0 > 0.7
        fb0 = 0.7
    endif

    selectObject: ytab
    Set value: i, 1, mix0
    Set value: i, 2, fb0
endfor

# --- 4. Normalization ---

selectObject: xtab
cols = Get number of columns
for j from 1 to cols
    cmin = 1e30
    cmax = -1e30
    for i from 1 to rows_target
        v = Get value: i, j
        if v = undefined
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
    for i from 1 to rows_target
        v = Get value: i, j
        if v = undefined
            v = 0
        endif
        nv = (v - cmin) / rng
        Set value: i, j, nv
    endfor
endfor

# --- 5. Neural Network Training ---

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

epoch = 0
last_cost = 1e30

while epoch < training_epochs
    epoch = epoch + 1
    selectObject: ff
    plusObject: pat
    plusObject: yal
    Learn: 1, learn_tolerance, "Minimum-squared-error"
    
    selectObject: ff
    plusObject: pat
    plusObject: yal
    cost = Get total costs: "Minimum-squared-error"
    
    diff = abs(cost - last_cost)
    if diff < learn_tolerance
        break
    endif
    last_cost = cost
endwhile

# Predict
selectObject: ff
plusObject: pat
To ActivationList: 1
afinal = selected("ActivationList")
selectObject: afinal
To Matrix
ypred = selected("Matrix")

# Clamp output
selectObject: ypred
Formula: "if self < 0 then 0 else if self > 1 then 1 else self fi fi"

# --- 6. Smoothing & Control Signal Generation ---

win = round(smooth_ms / (1000 * frame_step_seconds))
if win < 1
    win = 1
endif

Create TableOfReal: "Ctrl", rows_target, 2
ctrl = selected("TableOfReal")

# Simple moving average
for i from 1 to rows_target
    i1 = i - win
    if i1 < 1
        i1 = 1
    endif
    i2 = i + win
    if i2 > rows_target
        i2 = rows_target
    endif
    
    # Calculate means
    s1 = 0
    s2 = 0
    n = 0
    for k from i1 to i2
        selectObject: ypred
        m_val = Get value in cell: k, 1
        f_val = Get value in cell: k, 2
        s1 = s1 + m_val
        s2 = s2 + f_val
        n = n + 1
    endfor
    
    selectObject: ctrl
    Set value: i, 1, s1 / n
    Set value: i, 2, s2 / n
endfor

# --- 7. Fast Signal Processing (Block Processing Method) ---

# A. Convert Control to Sound (2 Channels: Mix, FB)
selectObject: ctrl
To Matrix
ctrlMat = selected("Matrix")
selectObject: ctrlMat
Transpose
ctrlMatT = selected("Matrix")
selectObject: ctrlMatT
To Sound
Rename: "Control_LowRes"
Override sampling frequency: 1 / frame_step_seconds
Resample: fs, 50
Rename: "Control_Signals"
controlSound = selected("Sound")

# B. Prepare Blocks
selectObject: sound_work
dur = Get total duration
delay_sec = delay_time_ms / 1000
n_blocks = ceiling(dur / delay_sec)

# Create a Table to store the IDs of the processed blocks
Create TableOfReal: "BlockIDs", n_blocks, 1
idsTable = selected("TableOfReal")

# Create a blank sound for the "Previous Block" (Initial state = Silence)
Create Sound from formula: "Prev_Block", 1, 0, delay_sec, fs, "0"
prev_block_id = selected("Sound")

writeInfoLine: "Processing blocks..."

# C. Block Loop
for b from 1 to n_blocks
    t_start = (b - 1) * delay_sec
    t_end = b * delay_sec
    if t_end > dur
        t_end = dur
    endif
    
    # 1. Extract Dry Chunk
    selectObject: sound_work
    Extract part: t_start, t_end, "rectangular", 1, "no"
    Rename: "Block_Dry"
    dry_id = selected("Sound")
    
    # 2. Extract Control Chunk (Mix and FB)
    selectObject: controlSound
    Extract part: t_start, t_end, "rectangular", 1, "no"
    Rename: "Block_Ctrl"
    ctrl_id = selected("Sound")
    
    # 3. Apply Feedback Formula
    selectObject: dry_id
    plusObject: ctrl_id
    plusObject: prev_block_id
    
    Formula: "self + Sound_Prev_Block[col] * Sound_Block_Ctrl[1, col] * Sound_Block_Ctrl[2, col]"
    
    # 4. Store result ID in our Table
    selectObject: idsTable
    Set value: b, 1, dry_id
    
    # 5. Update Prev_Block for next iteration
    selectObject: prev_block_id
    Remove
    selectObject: dry_id
    Copy: "Prev_Block"
    prev_block_id = selected("Sound")
    
    # Clean up temp objects
    selectObject: ctrl_id
    Remove
endfor

# D. Concatenate (Safe ID-Table Method)

# 1. Read IDs into variables
selectObject: idsTable
for b from 1 to n_blocks
    block_id_['b'] = Get value: b, 1
endfor

# 2. Select first block
first_id = block_id_[1]
selectObject: first_id

# 3. Add remaining blocks
for b from 2 to n_blocks
    next_id = block_id_['b']
    plusObject: next_id
endfor

# 4. Concatenate
Concatenate
Rename: original_name$ + "_neural_delay"
outS = selected("Sound")
Scale peak: 0.99

# Remove individual blocks
for b from 1 to n_blocks
    del_id = block_id_['b']
    selectObject: del_id
    Remove
endfor

# --- 8. Reporting ---

appendInfoLine: "Processing Complete."

# --- 9. Cleanup ---

selectObject: prev_block_id
Remove
selectObject: idsTable
Remove
selectObject: sound_work
Remove

procedure SafeRemove (id)
    if id <> 0
        selectObject: id
        Remove
    endif
endproc

call SafeRemove: pitch
call SafeRemove: intensity
call SafeRemove: formant
call SafeRemove: mfcc
call SafeRemove: harmonicity
call SafeRemove: xtab
call SafeRemove: ytab
call SafeRemove: ymat
call SafeRemove: yal
call SafeRemove: xmat
call SafeRemove: pat
call SafeRemove: ff
call SafeRemove: afinal
call SafeRemove: ypred
call SafeRemove: ctrl
call SafeRemove: ctrlMat
call SafeRemove: ctrlMatT
selectObject: controlSound
Remove
selectObject: "Sound Control_LowRes"
Remove

# Play Result (Optional)
if play_result
    selectObject: outS
    Play
endif

