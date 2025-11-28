# ============================================================
# Praat AudioTools - Cross Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Filtering or timbral modification script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

clearinfo

numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds != 2
    exitScript: "Please select exactly 2 Sound objects."
endif

form Cross Synthesis v7.0 (Smooth LPC)
    comment S1=SOURCE (excitation), S2=FILTER (envelope)
    comment ─────────────────────────────────
    optionmenu Preset: 1
        option Custom
        option Speech (default)
        option Sustained tones
        option Percussive sounds
        option Vocal formants
        option Extreme smoothing
    positive Window_ms 50
    positive Step_ms 5
    positive LPC_order 16
    positive Envelope_smoothing 0.8
    real Transfer_amount 0.8
    positive Pre_emphasis 0.97
    boolean Energy_normalize 1
    boolean Match_durations 1
    optionmenu Duration_ref 3
        option SOURCE
        option FILTER
        option Shorter
    boolean Play_result 1
    real Gain_dB 0
endform

# Apply presets
if preset = 2
    # Speech (default)
    window_ms = 40
    step_ms = 5
    lPC_order = 16
    envelope_smoothing = 0.8
    transfer_amount = 0.8
    pre_emphasis = 0.97
elsif preset = 3
    # Sustained tones
    window_ms = 70
    step_ms = 8
    lPC_order = 18
    envelope_smoothing = 0.85
    transfer_amount = 0.9
    pre_emphasis = 0.95
elsif preset = 4
    # Percussive sounds
    window_ms = 30
    step_ms = 3
    lPC_order = 14
    envelope_smoothing = 0.65
    transfer_amount = 0.7
    pre_emphasis = 0.99
elsif preset = 5
    # Vocal formants
    window_ms = 45
    step_ms = 5
    lPC_order = 20
    envelope_smoothing = 0.75
    transfer_amount = 0.85
    pre_emphasis = 0.96
elsif preset = 6
    # Extreme smoothing
    window_ms = 60
    step_ms = 7
    lPC_order = 12
    envelope_smoothing = 0.9
    transfer_amount = 0.95
    pre_emphasis = 0.93
endif

# Constraints
if transfer_amount < 0
    transfer_amount = 0
elsif transfer_amount > 1
    transfer_amount = 1
endif

if envelope_smoothing < 0.3
    envelope_smoothing = 0.3
elsif envelope_smoothing > 0.95
    envelope_smoothing = 0.95
endif

window_size = window_ms / 1000
time_step = step_ms / 1000

sound1 = selected("Sound", 1)
sound1$ = selected$("Sound", 1)
sound2 = selected("Sound", 2)
sound2$ = selected$("Sound", 2)

printline ═══════════════════════════════════════════════════════
printline   CROSS-SYNTHESIS v7.0 (Smooth)
printline ═══════════════════════════════════════════════════════
printline SOURCE: 'sound1$'
printline FILTER: 'sound2$'
printline 
printline Window: 'window_ms:1' ms, Step: 'step_ms:1' ms
printline Smoothing: 'envelope_smoothing:2', Transfer: 'transfer_amount:2'
printline ───────────────────────────────────────────────────────

# ═══════════════════════════════════════════════════════════
# PREPROCESSING
# ═══════════════════════════════════════════════════════════

printline 
printline [Preprocessing...]

select sound1
sr1 = Get sampling frequency
ch1 = Get number of channels
dur1 = Get total duration

select sound2
sr2 = Get sampling frequency
ch2 = Get number of channels
dur2 = Get total duration

# Mono
if ch1 > 1
    select sound1
    sound1_m = Convert to mono
    select sound1
    Remove
    select sound1_m
    sound1 = selected("Sound")
    Rename: sound1$
endif

if ch2 > 1
    select sound2
    sound2_m = Convert to mono
    select sound2
    Remove
    select sound2_m
    sound2 = selected("Sound")
    Rename: sound2$
endif

# Resample
target_sr = max(sr1, sr2)
if sr1 != sr2
    if sr1 < target_sr
        select sound1
        s1_rs = Resample: target_sr, 50
        select sound1
        Remove
        select s1_rs
        sound1 = selected("Sound")
        Rename: sound1$
    endif
    if sr2 < target_sr
        select sound2
        s2_rs = Resample: target_sr, 50
        select sound2
        Remove
        select s2_rs
        sound2 = selected("Sound")
        Rename: sound2$
    endif
endif

# Duration matching
if match_durations
    if duration_ref = 1
        target_dur = dur1
    elsif duration_ref = 2
        target_dur = dur2
    else
        target_dur = min(dur1, dur2)
    endif
    
    if dur1 != target_dur
        select sound1
        if dur1 > target_dur
            s1_d = Extract part: 0, target_dur, "rectangular", 1.0, "no"
        else
            s1_d = Lengthen (overlap-add): 75, 600, target_dur / dur1
        endif
        select sound1
        Remove
        select s1_d
        sound1 = selected("Sound")
        Rename: sound1$
    endif
    
    if dur2 != target_dur
        select sound2
        if dur2 > target_dur
            s2_d = Extract part: 0, target_dur, "rectangular", 1.0, "no"
        else
            s2_d = Lengthen (overlap-add): 75, 600, target_dur / dur2
        endif
        select sound2
        Remove
        select s2_d
        sound2 = selected("Sound")
        Rename: sound2$
    endif
endif

# Get energy
if energy_normalize
    select sound1
    source_rms = Get root-mean-square: 0, 0
endif

printline   ✓ Complete

# ═══════════════════════════════════════════════════════════
# CROSS-SYNTHESIS
# ═══════════════════════════════════════════════════════════

printline 
printline [Cross-synthesis processing...]

# Pre-emphasis
printline   [1/6] Pre-emphasis...
select sound1
s1_pre = Copy: "s1_pre"
Formula: "self - pre_emphasis * self[col-1]"

select sound2
s2_pre = Copy: "s2_pre"
Formula: "self - pre_emphasis * self[col-1]"

# Extract SOURCE excitation
printline   [2/6] Extracting SOURCE excitation...
select s1_pre
lpc_s1 = To LPC (autocorrelation): lPC_order, window_size, time_step, 50

select s1_pre
plus lpc_s1
excitation = Filter (inverse)
Rename: "excitation"

# Extract FILTER envelope (smoothed)
printline   [3/6] Extracting FILTER spectral envelope...
# Calculate smooth order as integer
smooth_order = round(lPC_order * envelope_smoothing)
if smooth_order < 8
    smooth_order = 8
endif

printline   Using smoothed LPC order: 'smooth_order'

select s2_pre
lpc_s2 = To LPC (autocorrelation): smooth_order, window_size, time_step, 50

# Apply envelope
printline   [4/6] Applying FILTER envelope to SOURCE...
select excitation
plus lpc_s2
filtered = Filter: "no"

# De-emphasis
printline   [5/6] De-emphasis...
Formula: "self + pre_emphasis * self[col-1]"

# Blend with original
printline   [6/6] Blending...
if transfer_amount < 1.0
    select filtered
    filt_sc = Copy: "filt_sc"
    Formula: "self * transfer_amount"
    
    select sound1
    src_sc = Copy: "src_sc"
    Formula: "self * (1 - transfer_amount)"
    
    select filt_sc
    plus src_sc
    blend_st = Combine to stereo
    result = Convert to mono
    
    select filt_sc
    plus src_sc
    plus blend_st
    Remove
else
    select filtered
    result = Copy: "result"
endif

# Smooth the result to reduce artifacts
printline   [Post] Smoothing output...
select result
Formula: "(self + self[col-1] + self[col+1]) / 3"

# Energy normalization
if energy_normalize
    current_rms = Get root-mean-square: 0, 0
    if current_rms > 0.000001
        energy_factor = source_rms / current_rms
        Formula: "self * energy_factor"
    endif
endif

# Final processing
Scale peak: 0.99
gain_factor = 10^(gain_dB/20)
Formula: "self * gain_factor"
Scale peak: 0.99

Rename: "CrossSynth_'sound1$'_x_'sound2$'"
final_result = selected("Sound")

# Cleanup
select s1_pre
plus s2_pre
plus lpc_s1
plus excitation
plus lpc_s2
plus filtered
Remove

printline   ✓ Complete

# ═══════════════════════════════════════════════════════════
# PLAYBACK & SUMMARY
# ═══════════════════════════════════════════════════════════

if play_result
    printline 
    printline ♪ Playing result...
    select final_result
    Play
endif

printline 
printline ═══════════════════════════════════════════════════════
printline   Cross-Synthesis Complete! ✓
printline ═══════════════════════════════════════════════════════
printline 
printline Result: CrossSynth_'sound1$'_x_'sound2$'
printline 
printline Method: Smoothed LPC source-filter
printline   ✓ SOURCE excitation extraction
printline   ✓ FILTER envelope extraction (smoothed)
printline   ✓ Pre/de-emphasis processing
printline   ✓ Post-smoothing filter
printline   ✓ Energy normalization
printline 
printline Configuration:
printline   Window: 'window_ms:1' ms, Step: 'step_ms:1' ms
printline   LPC order: 'lPC_order' → smoothed to: 'smooth_order'
printline   Smoothing factor: 'envelope_smoothing:2'
printline   Transfer: 'transfer_amount:2'
printline 
printline Quality tips:
printline   • For sustained sounds: window 50-70ms, smoothing 0.7-0.8
printline   • For percussive: window 30-40ms, smoothing 0.6-0.7
printline   • For speech: window 40-50ms, smoothing 0.75-0.85
printline   • If artifacts remain: increase smoothing to 0.85-0.9
printline   • If too dull: reduce smoothing to 0.6-0.7
printline 
printline This version prioritizes smoothness over detail.
printline Works well for most material without pulsing artifacts.
printline 
printline ═══════════════════════════════════════════════════════