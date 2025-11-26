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
# Fast Spectral Freeze (v4.0 - Ultimate Speed)
# Combines Formula Batching + Downsampling for maximum performance.

form Spectral Freeze (Ultimate)
    optionmenu preset: 1
        option Custom (manual settings below)
        option Freeze (classic hold)
        option Gentle decay (slow fade)
        option Rising shimmer (decay + up)
        option Falling shimmer (decay + down)
        option Ghostly rise (strong decay + up)
        option Deep dive (strong decay + down)
        option Crystalline (minimal decay + micro-up)
        option Submerge (minimal decay + micro-down)
    
    comment --- Performance ---
    choice   processing_quality 2
        button High (Original Rate - Slow)
        button Medium (22050 Hz - Fast)
        button Low (11025 Hz - Super Fast)

    comment --- Analysis ---
    positive frame_step_ms 10
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
elsif preset = 6
    decay_factor = 0.15
    glissando_oct_sec = 0.3
elsif preset = 7
    decay_factor = 0.15
    glissando_oct_sec = -0.3
elsif preset = 8
    decay_factor = 0.9
    glissando_oct_sec = 0.05
elsif preset = 9
    decay_factor = 0.9
    glissando_oct_sec = -0.05
endif

# --- SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
orig_sr = Get sampling frequency
n_channels = Get number of channels

# 1. PREPARE INPUT (Mono Copy)
if n_channels > 1
    selectObject: orig_id
    input_id = Convert to mono
else
    selectObject: orig_id
    input_id = Copy: "input"
endif

# 2. DOWNSAMPLE (The Speed Boost)
if processing_quality = 2
    Resample: 22050, 50
    temp_id = selected("Sound")
    removeObject: input_id
    input_id = temp_id
elsif processing_quality = 3
    Resample: 11025, 50
    temp_id = selected("Sound")
    removeObject: input_id
    input_id = temp_id
endif

# Get working parameters
selectObject: input_id
work_sr = Get sampling frequency
# Add Tail
tail_id = Create Sound from formula: "tail", 1, 0, tail_duration_sec, work_sr, "0"
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

# Create Output (at working rate)
out_chans = 1
if create_stereo_output
    out_chans = 2
endif
output_id = Create Sound from formula: "Freeze", out_chans, 0, tot_dur, work_sr, "0"

# --- INITIALIZE ACCUMULATORS ---
acc_freq# = zero#(top_partials)
acc_amp# = zero#(top_partials)

# Pre-calc bin width suppression
bin_hz = 1 / win_dur
suppress_bins = round(50 / bin_hz) 
if suppress_bins < 1 
    suppress_bins = 1 
endif

writeInfoLine: "Spectral Freeze (Ultimate): ", preset$
appendInfoLine: "Rate: ", work_sr, " Hz"
appendInfoLine: "Processing ", nframes, " frames..."

# --- MAIN LOOP ---
for i from 0 to nframes - 1
    if i mod 50 = 0
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
    
    # Calculate Magnitude (Row 1)
    Formula: "if row = 1 then sqrt(self^2 + self[2,col]^2) else 0 fi"
    
    nc = Get number of columns
    freq_step = (work_sr/2) / (nc - 1)
    
    # Limit Frequency Range via masking
    max_col = round(max_frequency_hz / freq_step) + 1
    if max_col > nc
        max_col = nc
    endif
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
    
    # 3. PICK NEW PEAKS
    for k from 1 to top_partials
        selectObject: mat_id
        
        # Manual Max Search
        cur_max = -1
        cur_col = -1
        
        for c from 1 to max_col
            val = Get value in cell: 1, c
            if val > cur_max
                cur_max = val
                cur_col = c
            endif
        endfor
        
        if cur_max > 0.000001
            cur_freq = (cur_col - 1) * freq_step
            
            # FREEZE LOGIC
            if cur_max > acc_amp#[k]
                acc_amp#[k] = cur_max
                acc_freq#[k] = cur_freq
            endif
            
            # Suppress
            sup_c1 = cur_col - suppress_bins
            sup_c2 = cur_col + suppress_bins
            Formula: "if col >= " + string$(sup_c1) + " and col <= " + string$(sup_c2) + " then 0 else self fi"
        endif
    endfor
    
    # 4. BATCH SYNTHESIS
    Create Sound from formula: "grain", out_chans, 0, win_dur, work_sr, "0"
    grain_id = selected("Sound")
    Shift times to: "start time", t_start
    
    left_sum$ = ""
    right_sum$ = ""
    s_delay$ = fixed$(stereo_delay_sec, 6)
    
    found_partials = 0
    
    for k from 1 to top_partials
        freq = acc_freq#[k]
        amp = acc_amp#[k]
        
        if freq > 0 and amp > 0.000001
            amp_lin = amp / (win_dur * work_sr / 4)
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
    endif
    
    # Window (Hanning)
    s_dur$ = fixed$(win_dur, 6)
    s_start$ = fixed$(t_start, 6)
    Formula: "self * 0.5 * (1 - cos(2*pi * (x - " + s_start$ + ") / " + s_dur$ + "))"
    
    # 5. ADD TO OUTPUT
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

# Normalize
Scale peak: 10^(target_peak_db / 20)

# Restore Sample Rate if needed
if work_sr <> orig_sr
    appendInfoLine: "Restoring sample rate to ", orig_sr, " Hz..."
    resampled_id = Resample: orig_sr, 50
    removeObject: output_id
    output_id = resampled_id
    selectObject: output_id
    Rename: orig_name$ + "_Freeze"
endif

# Clean inputs
removeObject: input_id

if play_after
    Play
endif

appendInfoLine: "Done!"