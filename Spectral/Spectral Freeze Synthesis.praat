# ============================================================
# Praat AudioTools - Spectral Freeze Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral Freeze Synthesis
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Fast Spectral Freeze (Matrix-Optimized)
# Optimized peak detection and synthesis

form Spectral Freeze (Optimized)
    optionmenu preset: 1
        option Custom (manual settings below)
        option Freeze (classic hold)
        option Gentle decay (slow fade)
        option Rising shimmer (decay + up)
        option Falling shimmer (decay + down)
    
    comment --- Analysis ---
    positive frame_step_ms 20
    comment (Larger = faster, 10-50ms typical)
    positive analysis_window_ms 35
    positive max_frequency_hz 8000
    integer  top_partials 10
    
    comment --- Transformation ---
    positive decay_factor 0.2
    real     glissando_oct_sec 0.1
    
    comment --- Output ---
    positive tail_duration_sec 2
    boolean  create_stereo_output 1
    positive stereo_delay_ms 8
    real     target_peak_db -1
    boolean  play_after 1
endform

# --- APPLY PRESETS ---
if preset = 2
    decay_factor = 0.999
    glissando_oct_sec = 0
elsif preset = 3
    decay_factor = 0.5
    glissando_oct_sec = 0
elsif preset = 4
    decay_factor = 0.3
    glissando_oct_sec = 0.15
elsif preset = 5
    decay_factor = 0.3
    glissando_oct_sec = -0.15
endif

# --- SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound."
endif

writeInfoLine: "Spectral Freeze (Optimized)"
appendInfoLine: "Preset: ", preset$
appendInfoLine: ""

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
orig_sr = Get sampling frequency
n_channels = Get number of channels

# 1. PREPARE INPUT (Mono)
if n_channels > 1
    selectObject: orig_id
    input_id = Convert to mono
else
    selectObject: orig_id
    input_id = Copy: "input"
endif

# Add Tail
selectObject: input_id
tail_id = Create Sound from formula: "tail", 1, 0, tail_duration_sec, orig_sr, "0"
selectObject: input_id
plusObject: tail_id
temp_id = Concatenate
removeObject: input_id, tail_id
input_id = temp_id

selectObject: input_id
tot_dur = Get total duration

# Calc Constants
dt = frame_step_ms / 1000
win_dur = analysis_window_ms / 1000
d_frame = decay_factor ^ dt
gliss_ratio = 2 ^ (glissando_oct_sec * dt)
stereo_delay_sec = stereo_delay_ms / 1000
nframes = floor((tot_dur - win_dur) / dt)

appendInfoLine: "Processing ", nframes, " frames (step: ", frame_step_ms, " ms)"
appendInfoLine: ""

# Create Output
out_chans = 1
if create_stereo_output
    out_chans = 2
endif
output_id = Create Sound from formula: "Freeze", out_chans, 0, tot_dur, orig_sr, "0"

# --- INITIALIZE ACCUMULATORS ---
acc_freq# = zero#(top_partials)
acc_amp# = zero#(top_partials)

# Pre-calc suppression
bin_hz = 1 / win_dur
suppress_bins = round(50 / bin_hz)
if suppress_bins < 1
    suppress_bins = 1
endif

# --- MAIN LOOP ---
for i from 0 to nframes - 1
    if i mod 20 = 0
        perc = i / nframes * 100
        appendInfoLine: "Progress: ", fixed$(perc, 1), "%"
    endif

    # Time bounds
    tc = i * dt + win_dur/2
    t_start = tc - win_dur/2
    t_end = tc + win_dur/2
    
    # 1. ANALYZE FRAME
    selectObject: input_id
    frame_id = Extract part: t_start, t_end, "hanning", 1, "yes"
    
    spec_id = To Spectrum: "yes"
    selectObject: spec_id
    mat_id = To Matrix
    
    # Single-pass magnitude calculation
    selectObject: mat_id
    Formula: "if row = 1 then sqrt(self^2 + self[2,col]^2) else 0 fi"
    
    nc = Get number of columns
    freq_step = (orig_sr/2) / (nc - 1)
    max_col = round(max_frequency_hz / freq_step) + 1
    if max_col > nc
        max_col = nc
    endif
    
    # Limit frequency range
    Formula: "if col > " + string$(max_col) + " then 0 else self fi"
    
    # 2. UPDATE ACCUMULATORS
    for k from 1 to top_partials
        acc_amp#[k] = acc_amp#[k] * d_frame
        if acc_freq#[k] > 0
            acc_freq#[k] = acc_freq#[k] * gliss_ratio
            if acc_freq#[k] > max_frequency_hz
                acc_freq#[k] = max_frequency_hz
            endif
        endif
    endfor
    
    # 3. FIND PEAKS (Manual search - unavoidable)
    for k from 1 to top_partials
        selectObject: mat_id
        
        cur_max = -1
        cur_col = -1
        
        # Search for maximum
        for c from 1 to max_col
            val = Get value in cell: 1, c
            if val > cur_max
                cur_max = val
                cur_col = c
            endif
        endfor
        
        if cur_max > 0.000001
            cur_freq = (cur_col - 1) * freq_step
            
            # Freeze logic
            if cur_max > acc_amp#[k]
                acc_amp#[k] = cur_max
                acc_freq#[k] = cur_freq
            endif
            
            # Suppress this peak
            sup_c1 = cur_col - suppress_bins
            sup_c2 = cur_col + suppress_bins
            Formula: "if col >= " + string$(sup_c1) + " and col <= " + string$(sup_c2) + " then 0 else self fi"
        endif
    endfor
    
    # 4. SYNTHESIZE GRAIN (Batch formula)
    Create Sound from formula: "grain", out_chans, 0, win_dur, orig_sr, "0"
    grain_id = selected("Sound")
    Shift times to: "start time", t_start
    
    # Build synthesis formula
    left_sum$ = ""
    right_sum$ = ""
    s_delay$ = fixed$(stereo_delay_sec, 6)
    
    found_partials = 0
    
    for k from 1 to top_partials
        freq = acc_freq#[k]
        amp = acc_amp#[k]
        
        if freq > 0 and amp > 0.000001
            amp_lin = amp / (win_dur * orig_sr / 4)
            s_freq$ = fixed$(freq, 2)
            s_amp$ = fixed$(amp_lin, 8)
            
            term_L$ = " + " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*x)"
            left_sum$ = left_sum$ + term_L$
            
            if out_chans = 2
                term_R$ = " + " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*(x - " + s_delay$ + "))"
                right_sum$ = right_sum$ + term_R$
            endif
            
            found_partials = 1
        endif
    endfor
    
    if found_partials
        if out_chans = 1
            Formula: "self" + left_sum$
        else
            Formula: "if row = 1 then self" + left_sum$ + " else self" + right_sum$ + " fi"
        endif
        
        # Apply Hanning window
        s_dur$ = fixed$(win_dur, 6)
        s_start$ = fixed$(t_start, 6)
        Formula: "self * 0.5 * (1 - cos(2*pi * (x - " + s_start$ + ") / " + s_dur$ + "))"
    endif
    
    # 5. MIX TO OUTPUT
    selectObject: output_id
    s_gid$ = string$(grain_id)
    s_end$ = fixed$(t_end, 6)
    Formula: "if x >= " + s_start$ + " and x <= " + s_end$ + " then self + object(" + s_gid$ + ", x) else self fi"
    
    # Cleanup
    removeObject: frame_id, spec_id, mat_id, grain_id
endfor

# --- FINALIZE ---
selectObject: output_id
Rename: orig_name$ + "_Freeze"
Scale peak: 10^(target_peak_db / 20)

removeObject: input_id

if play_after
    Play
endif

appendInfoLine: ""
appendInfoLine: "Done!"