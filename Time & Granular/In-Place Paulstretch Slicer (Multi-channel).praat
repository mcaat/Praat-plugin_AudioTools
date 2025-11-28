# ============================================================
# Praat AudioTools - In-Place Paulstretch Slicer (Multi-channel).praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   In-Place Paulstretch Slicer (Multi-channel)
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ===========================================================
# Random In-Place Paulstretch Slices -> Multi-channel output
# v3.0: Added "Mix Original" toggle + Fixed Multi-channel creation
# ===========================================================

form Random Paulstretch Slices (Multi-channel output)
    positive number_of_segments 4
    real min_duration 0.1
    real max_duration 0.5
    
    comment ---- Output Options ----
    # "0" means unchecked (NO) by default
    boolean Mix_original_channel_1 0
    
    comment ---- Paulstretch parameters ----
    positive stretch_factor 4.0
    positive window_size 0.25
    positive overlap_percent 50
endform

# --------------------------------------------
# Preconditions
# --------------------------------------------
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object first."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
Scale peak: 0.99
selectObject: orig_id

total_duration = Get total duration
fs = Get sampling frequency
nchan = Get number of channels

# Calculate padding
max_stretched_duration = max_duration * stretch_factor
padding_duration = max_stretched_duration
padded_duration = total_duration + padding_duration

# Validate user inputs
if min_duration <= 0 or max_duration <= 0
    exitScript: "Durations must be positive numbers."
endif
if min_duration > max_duration
    exitScript: "Minimum duration cannot be larger than maximum duration."
endif
if max_duration > total_duration
    exitScript: "Maximum duration cannot exceed the total sound duration."
endif
if overlap_percent <= 0 or overlap_percent >= 100
    exitScript: "Overlap must be in (0, 100)."
endif

# --------------------------------------------
# Prepare channel 1 (LEFT original) and the slice source
# --------------------------------------------
writeInfoLine: "Preparing channels..."

if nchan = 2
    # CH1 = original LEFT
    selectObject: orig_id
    left_id = Extract one channel: 1
    Rename: orig_name$ + "_CH1_LEFT_orig"
    
    # Pad left channel
    pad_left = Create Sound from formula: "pad", 1, 0, padding_duration, fs, "0"
    selectObject: left_id
    plusObject: pad_left
    left_padded = Concatenate
    removeObject: left_id, pad_left
    left_id = left_padded

    # Source for slices (RIGHT)
    selectObject: orig_id
    right_src_id = Extract one channel: 2
    Rename: orig_name$ + "_sliceSource_RIGHT"
else
    # Mono input
    selectObject: orig_id
    Copy: orig_name$ + "_CH1_LEFT_orig"
    left_id = selected("Sound")
    
    # Pad left channel
    pad_left_mono = Create Sound from formula: "pad", 1, 0, padding_duration, fs, "0"
    selectObject: left_id
    plusObject: pad_left_mono
    left_padded = Concatenate
    removeObject: left_id, pad_left_mono
    left_id = left_padded

    selectObject: orig_id
    Copy: orig_name$ + "_sliceSource_MONO"
    right_src_id = selected("Sound")
endif

# --------------------------------------------
# PROCEDURE: FAST PAULSTRETCH (Vectorized)
# --------------------------------------------
procedure PaulstretchFast: .id, .stretch, .win_size, .overlap_perc
    selectObject: .id
    .dur = Get total duration
    .sr  = Get sampling frequency
    
    .win_samples = round(.win_size * .sr)
    if .win_samples mod 2 = 1
        .win_samples += 1
    endif
    
    .overlap_frac = .overlap_perc / 100
    .hop_out = .win_size * (1 - .overlap_frac)
    .hop_in  = .hop_out / .stretch
    .out_dur = .dur * .stretch
    .n_frames = ceiling(.out_dur / .hop_out) + 1
    
    # Output buffer
    .out_id = Create Sound from formula: "ps_out", 1, 0, .out_dur + .win_size, .sr, "0"
    
    # Process frames
    for .i from 0 to .n_frames - 1
        .t_in = .i * .hop_in
        .t_mid_start = .t_in - .win_size / 2
        .t_mid_end   = .t_in + .win_size / 2
        
        selectObject: .id
        .ex_start = max(0, .t_mid_start)
        .ex_end   = min(.dur, .t_mid_end)
        
        if .ex_end > .ex_start
            .frame = Extract part: .ex_start, .ex_end, "rectangular", 1, "no"
            
            # Fast Padding using Formula
            .dur_frame = Get total duration
            if abs(.dur_frame - .win_size) > 0.00001
                .padded = Create Sound from formula: "pad", 1, 0, .win_size, .sr, "0"
                .offset = 0
                if .t_mid_start < 0
                    .offset = abs(.t_mid_start)
                endif
                .s_off$ = fixed$(.offset, 6)
                .s_end$ = fixed$(.offset+.dur_frame, 6)
                .fid = .frame
                Formula: "if x >= " + .s_off$ + " and x <= " + .s_end$ + " then self + object(" + string$(.fid) + ", x - " + .s_off$ + ") else self fi"
                removeObject: .frame
                .frame = .padded
            endif
            
            # Window 1
            selectObject: .frame
            Multiply by window: "Hanning"
            
            # Fast Phase Randomization (Matrix Clone Method)
            .spec = To Spectrum: "yes"
            selectObject: .spec
            .mat_c = To Matrix
            selectObject: .mat_c
            .mat_p = Copy: "phases"
            Formula: "randomUniform(-pi, pi)"
            
            selectObject: .mat_c
            .pid = .mat_p
            # Vectorized Matrix Math
            Formula: "if (col=1 or col=ncol) then self else (if row=1 then sqrt(self[1,col]^2 + self[2,col]^2) * cos(object[" + string$(.pid) + ",1,col]) else sqrt(self[1,col]^2 + self[2,col]^2) * sin(object[" + string$(.pid) + ",1,col]) fi) fi"
            
            .spec_mod = To Spectrum
            selectObject: .spec_mod
            .proc = To Sound
            
            # Window 2
            selectObject: .proc
            Multiply by window: "Hanning"
            
            # Fast Overlap Add
            .t_out = .i * .hop_out
            Shift times to: "start time", .t_out
            
            selectObject: .out_id
            .proc_id = .proc
            .s_t1$ = fixed$(.t_out, 6)
            .s_t2$ = fixed$(.t_out + .win_size, 6)
            
            # Vectorized Addition
            Formula: "if x >= " + .s_t1$ + " and x <= " + .s_t2$ + " then self + object(" + string$(.proc_id) + ", x) else self fi"
            
            removeObject: .frame, .spec, .mat_c, .mat_p, .spec_mod, .proc
        endif
    endfor
    
    selectObject: .out_id
endproc

# --------------------------------------------
# Main Processing Loop
# --------------------------------------------
chan_ids# = zero# (number_of_segments)

for i to number_of_segments
    selectObject: right_src_id
    total_src_dur = Get total duration
    
    seg_len = randomUniform(min_duration, max_duration)
    max_start = total_src_dur - seg_len
    win_start = randomUniform(0, max_start)
    win_end   = win_start + seg_len
    
    appendInfoLine: "Slice ", i, ": processing ", fixed$(seg_len, 3), "s segment..."

    # 1. Extract raw segment
    selectObject: right_src_id
    seg_id = Extract part: win_start, win_end, "rectangular", 1, "no"
    
    # 2. Fast Paulstretch
    @PaulstretchFast: seg_id, stretch_factor, window_size, overlap_percent
    ps_id = selected("Sound")
    Rename: "stretched_" + string$(i)
    
    # Normalize slice
    Scale peak: 0.99
    
    # 3. Calculate Placement
    selectObject: ps_id
    stretched_dur = Get total duration
    original_center = win_start + (seg_len / 2)
    target_start = original_center - (stretched_dur / 2)
    if target_start < 0
        target_start = 0
    endif
    
    # 4. Create Channel and Place Audio (FAST METHOD)
    Create Sound from formula: "CH" + string$(i+1), 1, 0, padded_duration, fs, "0"
    channel_id = selected("Sound")
    
    selectObject: ps_id
    Shift times to: "start time", target_start
    
    selectObject: channel_id
    # Prepare strings for formula
    ps_str_id$ = string$(ps_id)
    t_start$ = fixed$(target_start, 6)
    t_end$ = fixed$(target_start + stretched_dur, 6)
    
    # Instant placement
    Formula: "if x >= " + t_start$ + " and x <= " + t_end$ + " then self + object(" + ps_str_id$ + ", x) else self fi"
    
    chan_ids#[i] = channel_id
    
    # Cleanup
    removeObject: seg_id, ps_id
endfor

# --------------------------------------------
# COMBINE (Fixed for TRUE Multi-channel)
# --------------------------------------------
appendInfoLine: "Combining channels..."

# 1. Determine Output Channels
out_chans = number_of_segments
if mix_original_channel_1
    out_chans = out_chans + 1
endif

# 2. Create Master Sound container
Create Sound from formula: "MultiChannel_Output", out_chans, 0, padded_duration, fs, "0"
master_id = selected("Sound")

# 3. Fill channels loop
for i_ch from 1 to out_chans
    selectObject: master_id
    
    # Determine which object goes to this channel
    src_id = 0
    
    if mix_original_channel_1
        # If mixing: Ch1 is Left, Ch2 is Slice 1, etc.
        if i_ch = 1
            src_id = left_id
        else
            src_id = chan_ids#[i_ch - 1]
        endif
    else
        # If NOT mixing: Ch1 is Slice 1, Ch2 is Slice 2, etc.
        src_id = chan_ids#[i_ch]
    endif
    
    # Use Vectorized Copy
    # We only modify the specific row (channel) in the master file
    src_str$ = string$(src_id)
    Formula: "if row = " + string$(i_ch) + " then object(" + src_str$ + ", x) else self fi"
endfor

# Finalize
selectObject: master_id
Rename: orig_name$ + "_MultiChannel_PS_" + string$(out_chans) + "ch"
Scale peak: 0.99

# Cleanup
removeObject: left_id, right_src_id
for i to number_of_segments
    removeObject: chan_ids#[i]
endfor

appendInfoLine: "Done!"
Play

