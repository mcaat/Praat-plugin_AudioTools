# ============================================================
# Praat AudioTools - Partial Editing & Resynthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# FAST SPEAR-like Resynthesis (v11.0 - Click-Free)
# Fixed "Clicks" by replacing Gaussian window with Hanning window.
# Hanning guarantees the grain edges are exactly zero.

form Sinusoidal Texture Resynthesis
    comment --- Synthesis Parameters ---
    positive window_length            0.060
    positive hop_size                 0.015
    positive min_frequency            60
    positive max_frequency            8000
    integer  max_partials_per_frame   15
    
    comment --- Diffusion & Texture ---
    positive freq_jitter              3.0
    real     amp_jitter               0.1
    
    comment --- Scaling ---
    real     transpose_semitones      0
    real     formant_shift_ratio      1.0
    
    comment --- Optimization ---
    choice   processing_quality       2
        button High (Original Rate - Slow)
        button Medium (22050 Hz - Fast)
        button Low (11025 Hz - Very Fast)
    integer  progress_every           50
endform

# Preconditions
if numberOfSelected ("Sound") <> 1
    exitScript: "Please select exactly one Sound."
endif

# Setup Original
orig_id = selected("Sound")
orig_name$ = selected$("Sound")
orig_sr = Get sampling frequency
t1 = Get start time
t2 = Get end time
dur = t2 - t1

# 1. PREPARE WORKING COPY
selectObject: orig_id
input_id = Copy: "input"

# Handle Optimization Resampling
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
nyq = work_sr / 2
totdur = Get total duration

# 2. CREATE OUTPUT BUFFER
output_id = Create Sound from formula: "resynth", 1, 0, totdur, work_sr, "0"

# 3. CONSTANTS
tr = 2 ^ (transpose_semitones / 12)
fr = formant_shift_ratio
nframes = floor((totdur - window_length) / hop_size)

# Pre-calculate suppression width in bins
approx_bin_width = 1 / window_length
suppress_hz = 40 
suppress_bins = round(suppress_hz / approx_bin_width)
if suppress_bins < 1
    suppress_bins = 1
endif

writeInfoLine: "Starting Click-Free Resynthesis..."
appendInfoLine: "Partials: ", max_partials_per_frame
appendInfoLine: "Window: Hanning (Smooth Edges)"

# ===== FRAME LOOP =====
for i from 0 to nframes - 1
    if (i mod progress_every) = 0
        perc = i / nframes * 100
        appendInfoLine: "Progress: ", fixed$(perc, 1), "%"
    endif

    # Time calculations
    tc = i * hop_size + window_length/2
    t_start = tc - window_length/2
    t_end = tc + window_length/2
    
    if t_start < 0
        t_start = 0
    endif
    if t_end > totdur
        t_end = totdur
    endif
    current_win_dur = t_end - t_start

    # A. EXTRACT
    selectObject: input_id
    frame_id = Extract part: t_start, t_end, "hanning", 1, "yes"
    
    # B. ANALYZE
    spec_id = To Spectrum: "yes"
    
    # Convert directly to Matrix
    selectObject: spec_id
    mat_id = To Matrix
    
    # 1. Calculate Magnitude in Row 1
    Formula: "if row = 1 then sqrt(self^2 + self[2,col]^2) else 0 fi"
    
    # 2. Determine frequency step
    nc = Get number of columns
    freq_step = nyq / (nc - 1)

    # C. PRE-MASKING
    col_min = round(min_frequency / freq_step) + 1
    col_max = round(max_frequency / freq_step) + 1
    
    if col_min < 1 
        col_min = 1 
    endif
    if col_max > nc 
        col_max = nc 
    endif
    
    # Zero out frequencies outside range
    Formula: "if col < " + string$(col_min) + " or col > " + string$(col_max) + " then 0 else self fi"

    # D. FIND PEAKS & SYNTHESIZE
    Create Sound from formula: "grain", 1, 0, current_win_dur, work_sr, "0"
    grain_id = selected("Sound")
    
    # SHIFT GRAIN to absolute time
    Shift times to: "start time", t_start
    
    for k from 1 to max_partials_per_frame
        selectObject: mat_id
        
        # Manual Max Search
        current_max_val = -1
        current_max_col = -1
        
        for c from col_min to col_max
            val = Get value in cell: 1, c
            if val > current_max_val
                current_max_val = val
                current_max_col = c
            endif
        endfor
        
        if current_max_val > 0.000001
            # Exact Freq Calc
            freq_hz = (current_max_col - 1) * freq_step
            
            # --- TEXTURE & DIFFUSION ---
            amp_rand = randomUniform(1.0 - amp_jitter, 1.0 + amp_jitter)
            amp_linear = (current_max_val * amp_rand) / (window_length * work_sr / 4)
            
            freq_rand = randomUniform(-freq_jitter, freq_jitter)
            freq_target = (freq_hz + freq_rand) * tr * fr
            
            if freq_target < nyq
                selectObject: grain_id
                s_amp$ = fixed$(amp_linear, 6)
                s_freq$ = fixed$(freq_target, 2)
                
                Formula: "self + " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*x)"
            endif
            
            # Suppress peak
            selectObject: mat_id
            sup_c1 = current_max_col - suppress_bins
            sup_c2 = current_max_col + suppress_bins
            Formula: "if col >= " + string$(sup_c1) + " and col <= " + string$(sup_c2) + " then 0 else self fi"
        else
            k = max_partials_per_frame
        endif
    endfor
    
    # E. WINDOW GRAIN (THE CLICK FIX)
    selectObject: grain_id
    s_start$ = fixed$(t_start, 6)
    s_dur$ = fixed$(current_win_dur, 6)
    
    # Replaced Gaussian with Hanning Window
    # Hanning Formula: 0.5 * (1 - cos(2*pi * phase))
    # This guarantees the grain starts and ends at EXACTLY 0.0
    Formula: "self * 0.5 * (1 - cos(2*pi * (x - " + s_start$ + ") / " + s_dur$ + "))"
    
    # F. ADD TO OUTPUT
    selectObject: output_id
    s_grain_id$ = string$(grain_id)
    s_end$ = fixed$(t_end, 6)
    
    Formula: "if x >= " + s_start$ + " and x <= " + s_end$ + " then self + object(" + s_grain_id$ + ", x) else self fi"
    
    # Clean up
    removeObject: frame_id, spec_id, mat_id, grain_id
endfor

# 4. FINALIZE & RESTORE RATE
selectObject: output_id
Rename: orig_name$ + "_Texture"
Scale intensity: 70

if work_sr <> orig_sr
    appendInfoLine: "Restoring sample rate to ", orig_sr, " Hz..."
    resampled_id = Resample: orig_sr, 50
    removeObject: output_id
    output_id = resampled_id
    selectObject: output_id
    Rename: orig_name$ + "_Texture"
endif

Play

# Clean input copy
removeObject: input_id

appendInfoLine: "Done!"
