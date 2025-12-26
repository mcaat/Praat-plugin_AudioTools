# ============================================================
# Praat AudioTools - Neural Delay Control
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.4 (2025) - Fast Mono
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Neural Delay Control - Fast block-based processing
#   Uses adaptive mix/feedback based on audio features
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Neural Delay Control
    comment === Preset ===
    optionmenu Preset 1
        option Manual (Use Settings Below)
        option Clean Digital
        option Analog Warmth
        option Slapback
        option Rhythmic Dotted
        option Ambient Wash
        option Modulated
    
    comment === Delay Parameters ===
    positive Delay_time_ms 250
    positive Feedback_base 0.4
    positive Mix_base 0.3
    integer Number_of_repeats 4
    
    comment === Feedback Filter ===
    boolean Enable_filter 1
    positive Filter_cutoff_hz 4000
    
    comment === Neural Control ===
    positive Frame_step_ms 20
    positive Smooth_ms 40
    
    comment === Adaptive Sensitivity ===
    positive Transient_suppression 0.25
    positive HNR_gain 0.3
    positive Pitch_bonus 0.15
    
    comment === Output ===
    boolean Play_result 1
endform

# ============================================
# PRESET LOGIC
# ============================================

if preset$ = "Clean Digital"
    delay_time_ms = 250
    feedback_base = 0.35
    mix_base = 0.3
    number_of_repeats = 4
    enable_filter = 0

elsif preset$ = "Analog Warmth"
    delay_time_ms = 300
    feedback_base = 0.5
    mix_base = 0.35
    number_of_repeats = 5
    enable_filter = 1
    filter_cutoff_hz = 3000

elsif preset$ = "Slapback"
    delay_time_ms = 80
    feedback_base = 0.15
    mix_base = 0.45
    number_of_repeats = 2
    enable_filter = 0

elsif preset$ = "Rhythmic Dotted"
    delay_time_ms = 375
    feedback_base = 0.45
    mix_base = 0.35
    number_of_repeats = 4
    enable_filter = 1
    filter_cutoff_hz = 4500

elsif preset$ = "Ambient Wash"
    delay_time_ms = 500
    feedback_base = 0.6
    mix_base = 0.4
    number_of_repeats = 6
    enable_filter = 1
    filter_cutoff_hz = 2500

elsif preset$ = "Modulated"
    delay_time_ms = 200
    feedback_base = 0.45
    mix_base = 0.35
    number_of_repeats = 4
    enable_filter = 1
    filter_cutoff_hz = 5000
endif

# ============================================
# SETUP
# ============================================

nSelected = numberOfSelected("Sound")
if nSelected <> 1
    exitScript: "Please select exactly one Sound object."
endif

original_sound = selected("Sound")
original_name$ = selected$("Sound")

selectObject: original_sound
duration = Get total duration
fs = Get sampling frequency

writeInfoLine: "=== NEURAL DELAY CONTROL (Fast) ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Delay: ", delay_time_ms, " ms | Feedback: ", fixed$(feedback_base, 2)
appendInfoLine: "Mix: ", fixed$(mix_base, 2), " | Repeats: ", number_of_repeats
if enable_filter
    appendInfoLine: "Filter: LP @ ", filter_cutoff_hz, " Hz"
endif
appendInfoLine: "===================================="
appendInfoLine: ""

# Work on mono copy
selectObject: original_sound
sound_work = Convert to mono
Rename: "Work"

delay_sec = delay_time_ms / 1000
frame_step_sec = frame_step_ms / 1000

# ============================================
# FEATURE EXTRACTION (Fast)
# ============================================

appendInfoLine: "Extracting features..."

nFrames = floor(duration / frame_step_sec)
if nFrames < 1
    nFrames = 1
endif

# Arrays for features and control
feat_intensity# = zero#(nFrames)
feat_hnr# = zero#(nFrames)
feat_pitch# = zero#(nFrames)
ctrl_mix# = zero#(nFrames)
ctrl_fb# = zero#(nFrames)

# Extract intensity
selectObject: sound_work
intensity_obj = To Intensity: 75, frame_step_sec, "yes"

# Extract HNR
selectObject: sound_work
hnr_obj = To Harmonicity (cc): frame_step_sec, 75, 0.1, 1.0

# Extract pitch
selectObject: sound_work
pitch_obj = To Pitch: frame_step_sec, 75, 600

for i from 1 to nFrames
    t = (i - 0.5) * frame_step_sec
    
    selectObject: intensity_obj
    iv = Get value at time: t, "cubic"
    if iv = undefined
        iv = 60
    endif
    feat_intensity#[i] = iv
    
    selectObject: hnr_obj
    hnr = Get value at time: t, "cubic"
    if hnr = undefined
        hnr = 0
    endif
    feat_hnr#[i] = max(0, min(1, (hnr + 10) / 40))
    
    selectObject: pitch_obj
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined or f0 <= 0
        feat_pitch#[i] = 0
    else
        feat_pitch#[i] = 1
    endif
endfor

removeObject: intensity_obj, hnr_obj, pitch_obj

# ============================================
# COMPUTE ADAPTIVE CONTROL
# ============================================

appendInfoLine: "Computing adaptive control..."

prev_int = feat_intensity#[1]

for i from 1 to nFrames
    # Transient detection
    dI = abs(feat_intensity#[i] - prev_int) / 20
    prev_int = feat_intensity#[i]
    trans = min(dI, 1)
    
    # Mix: higher for tonal, lower for transients
    mix0 = mix_base + hNR_gain * feat_hnr#[i] + pitch_bonus * feat_pitch#[i] - transient_suppression * trans
    ctrl_mix#[i] = max(0.05, min(0.8, mix0))
    
    # Feedback: higher for sustained, lower for transients
    fb0 = feedback_base + 0.2 * feat_hnr#[i] - 0.3 * trans
    ctrl_fb#[i] = max(0.1, min(0.7, fb0))
endfor

# Smooth control signals
win = round(smooth_ms / frame_step_ms)
if win < 1
    win = 1
endif

ctrl_mix_smooth# = zero#(nFrames)
ctrl_fb_smooth# = zero#(nFrames)

for i from 1 to nFrames
    i1 = max(1, i - win)
    i2 = min(nFrames, i + win)
    
    sum_m = 0
    sum_f = 0
    n = i2 - i1 + 1
    
    for k from i1 to i2
        sum_m += ctrl_mix#[k]
        sum_f += ctrl_fb#[k]
    endfor
    
    ctrl_mix_smooth#[i] = sum_m / n
    ctrl_fb_smooth#[i] = sum_f / n
endfor

# ============================================
# BUILD DELAY LAYERS (Block-based - FAST)
# ============================================

appendInfoLine: "Building delay layers..."

# Create output starting with dry signal
selectObject: sound_work
output = Copy: "Output"

# Extend output for delay tail
tail_duration = delay_sec * number_of_repeats
selectObject: output
output_dur = Get total duration

silence_tail = Create Sound from formula: "tail", 1, 0, tail_duration, fs, "0"
selectObject: output, silence_tail
output_extended = Concatenate
removeObject: output, silence_tail
output = output_extended
Rename: "Output"

# Process each repeat
for rep from 1 to number_of_repeats
    appendInfoLine: "  Repeat ", rep, "/", number_of_repeats
    
    rep_delay = delay_sec * rep
    fb_amount = feedback_base ^ rep  ; Exponential decay
    
    # Create delayed copy
    selectObject: sound_work
    delayed = Copy: "Delayed_" + string$(rep)
    
    # Apply feedback filter if enabled
    if enable_filter
        selectObject: delayed
        filtered = Filter (pass Hann band): 0, filter_cutoff_hz, filter_cutoff_hz * 0.1
        removeObject: delayed
        delayed = filtered
        
        # Apply filter again for later repeats (cumulative darkening)
        if rep > 2
            selectObject: delayed
            filtered = Filter (pass Hann band): 0, filter_cutoff_hz * 0.8, filter_cutoff_hz * 0.1
            removeObject: delayed
            delayed = filtered
        endif
    endif
    
    # Scale by feedback amount
    selectObject: delayed
    Formula: "self * " + string$(fb_amount)
    
    # Apply adaptive mix per frame (block-based)
    for i from 1 to nFrames
        t_start = (i - 1) * frame_step_sec
        t_end = i * frame_step_sec
        if t_end > duration
            t_end = duration
        endif
        
        mix_val = ctrl_mix_smooth#[i]
        
        selectObject: delayed
        Formula (part): t_start, t_end, 1, 1, "self * " + string$(mix_val)
    endfor
    
    # Add to output at delayed position
    selectObject: delayed
    delayed_name$ = selected$("Sound")
    
    selectObject: output
    Formula: "self + (if x >= " + string$(rep_delay) + " and x < " + string$(rep_delay + duration) + 
        ... " then Sound_'delayed_name$'(x - " + string$(rep_delay) + ") else 0 fi)"
    
    removeObject: delayed
endfor

# ============================================
# FINALIZE
# ============================================

selectObject: output
Scale peak: 0.99
Rename: original_name$ + "_neural_delay"
outS = selected("Sound")

removeObject: sound_work

selectObject: original_sound
plusObject: outS

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
selectObject: outS
out_dur = Get total duration
appendInfoLine: "Output: ", selected$("Sound")
appendInfoLine: "Duration: ", fixed$(out_dur, 2), " s"

if play_result
    appendInfoLine: "Playing..."
    selectObject: outS
    Play
endif

selectObject: outS
