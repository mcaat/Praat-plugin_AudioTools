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
# Random In-Place Paulstretch Slices -> One Channel per Slice
# CH1 = Original Left (unchanged)
# CH2..CH(N+1) = In-place Paulstretched slices (one per channel)
# ===========================================================

form Random Paulstretch Slices (Multi-channel output)
    positive number_of_segments 4
    real min_duration 0.1
    real max_duration 0.5
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

# Add padding at the end to accommodate stretched segments
# Calculate maximum possible stretched duration
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
if window_size <= 0
    exitScript: "Window size must be > 0."
endif
if stretch_factor <= 0
    exitScript: "Stretch factor must be > 0."
endif

# --------------------------------------------
# Prepare channel 1 (LEFT original) and the slice source
# --------------------------------------------
if nchan = 2
    # CH1 = original LEFT
    left_id = Extract one channel: 1
    tmpName$ = orig_name$ + "_CH1_LEFT_orig"
    Rename: tmpName$
    left_id = selected("Sound")
    
    # Pad left channel to padded_duration
    @MakeSilence: "tmp_pad_left", padding_duration, fs
    pad_left = selected("Sound")
    selectObject: left_id
    plusObject: pad_left
    left_padded = Concatenate
    removeObject: left_id, pad_left
    left_id = left_padded

    selectObject: orig_id
    right_src_id = Extract one channel: 2
    tmpName$ = orig_name$ + "_sliceSource_RIGHT"
    Rename: tmpName$
    right_src_id = selected("Sound")
else
    # Mono input: duplicate for left + slice source
    selectObject: orig_id
    Copy...
    tmpName$ = orig_name$ + "_CH1_LEFT_orig"
    Rename: tmpName$
    left_id = selected("Sound")
    
    # Pad left channel to padded_duration
    @MakeSilence: "tmp_pad_left_mono", padding_duration, fs
    pad_left_mono = selected("Sound")
    selectObject: left_id
    plusObject: pad_left_mono
    left_padded = Concatenate
    removeObject: left_id, pad_left_mono
    left_id = left_padded

    selectObject: orig_id
    Copy...
    tmpName$ = orig_name$ + "_sliceSource_MONO"
    Rename: tmpName$
    right_src_id = selected("Sound")
endif

# Helper: make silence (mono) of duration d
# --------------------------------------------
procedure MakeSilence: .name$, .d, .sr
    Create Sound from formula: .name$, 1, 0, .d, .sr, "0"
endproc

# Procedure: Paulstretch on the CURRENTLY SELECTED mono Sound
# Produces a new Sound named outname$ and leaves it selected.
# --------------------------------------------
procedure PaulstretchOnSelected: .stretch_factor, .window_size, .overlap_percent, .outname$
    .local_in_id = selected("Sound")
    selectObject: .local_in_id
    .dur = Get total duration
    .sr  = Get sampling frequency

    .window_samples = round(.window_size * .sr)
    if .window_samples mod 2 = 1
        .window_samples += 1
    endif
    .win_sec = .window_samples / .sr

    .overlap_fraction = .overlap_percent / 100
    .hop_out = .win_sec * (1 - .overlap_fraction)
    .hop_in  = .hop_out / .stretch_factor
    .out_dur = .dur * .stretch_factor

    if .hop_out <= 0 or .hop_in <= 0
        exitScript: "Internal error: hop sizes invalid; check stretch/overlap/window."
    endif

    .n_frames = ceiling(.out_dur / .hop_out) + 1

    # output buffer (silent)
    Create Sound from formula: "ps_out_tmp", 1, 0, .out_dur + .win_sec, .sr, "0"
    .output_id = selected("Sound")

    .progress_interval = max(1, round(.n_frames / 20))

    for .iframe from 0 to .n_frames - 1
        if .iframe mod .progress_interval = 0
            .percent = .iframe / .n_frames * 100
            writeInfoLine: "Paulstretch: ", fixed$(.percent, 1), "% (frame ", .iframe, "/", .n_frames, ")"
        endif

        .t_in = .iframe * .hop_in
        .t_start = .t_in - .win_sec / 2
        .t_end   = .t_in + .win_sec / 2

        selectObject: .local_in_id
        .ex_start = max(0, .t_start)
        .ex_end   = min(.dur, .t_end)

        if .ex_end > .ex_start
            .frame_id = Extract part: .ex_start, .ex_end, "rectangular", 1, "no"
            selectObject: .frame_id
            .actual_dur = Get total duration

            # Pad at start if needed
            if .actual_dur < .win_sec and .t_start < 0
                @MakeSilence: "tmp_padA", -.t_start, .sr
                .padA = selected("Sound")
                selectObject: .padA
                plusObject: .frame_id
                .tmp = Concatenate
                removeObject: .padA, .frame_id
                .frame_id = .tmp
            endif

            # Recheck and pad at end if needed
            selectObject: .frame_id
            .actual_dur = Get total duration
            if .actual_dur < .win_sec
                @MakeSilence: "tmp_padB", .win_sec - .actual_dur, .sr
                .padB = selected("Sound")
                selectObject: .frame_id
                plusObject: .padB
                .tmp2 = Concatenate
                removeObject: .frame_id, .padB
                .frame_id = .tmp2
            endif

            # Hanning window
            selectObject: .frame_id
            Multiply by window: "Hanning"

            # Spectrum, randomize phases
            .spec_id = To Spectrum: "yes"
            selectObject: .spec_id
            .n_bins = Get number of bins
            for .ibin from 1 to .n_bins
                selectObject: .spec_id
                .re = Get real value in bin: .ibin
                .im = Get imaginary value in bin: .ibin
                .mag = sqrt(.re*.re + .im*.im)
                if .ibin = 1 or .ibin = .n_bins
                    .phase = 0
                else
                    .phase = randomUniform(-pi, pi)
                endif
                Set real value in bin: .ibin, .mag * cos(.phase)
                Set imaginary value in bin: .ibin, .mag * sin(.phase)
            endfor

            # Back to time, window again
            .sel = To Sound
            Multiply by window: "Hanning"

            # Overlap-add into output
            selectObject: .sel
            .n_samp = Get number of samples
            .t_out = .iframe * .hop_out
            .out_start_sample = round(.t_out * .sr) + 1

            for .isamp from 1 to .n_samp
                .out_idx = .out_start_sample + .isamp - 1

                selectObject: .output_id
                .out_n = Get number of samples
                if .out_idx >= 1 and .out_idx <= .out_n
                    selectObject: .sel
                    .add_val = Get value at sample number: 1, .isamp

                    selectObject: .output_id
                    .cur_val = Get value at sample number: 1, .out_idx
                    Set value at sample number: 1, .out_idx, .cur_val + .add_val
                endif
            endfor

            removeObject: .frame_id, .spec_id, .sel
        endif
    endfor

    # Finalize
    selectObject: .output_id
    Extract part: 0, .out_dur, "rectangular", 1, "no"
    .final_id = selected("Sound")
    Rename: .outname$
    Scale peak: 0.99
    
    # Cleanup temporary output buffer
    removeObject: .output_id
    selectObject: .final_id
endproc

# --------------------------------------------
# Build one full-length channel per slice (CH2..CH(N+1))
# Each channel has silence except the Paulstretched slice at its position
# --------------------------------------------
chan_ids# = zero# (number_of_segments)

for i to number_of_segments
    seg_len = randomUniform(min_duration, max_duration)
    max_start = total_duration - seg_len
    win_start = randomUniform(0, max_start)
    win_end   = win_start + seg_len
    
    writeInfoLine: "Slice ", i, ": extracting from ", fixed$(win_start, 3), " to ", fixed$(win_end, 3), " (duration: ", fixed$(seg_len, 3), ")"

    # Extract raw (mono) segment from slice source
    selectObject: right_src_id
    seg_id = Extract part: win_start, win_end, "rectangular", 1, "no"
    tmpName$ = orig_name$ + "_rawseg_" + string$(i)
    Rename: tmpName$
    seg_id = selected("Sound")

    # Paulstretch the segment (inline)
    selectObject: seg_id
    psName$ = orig_name$ + "_ps_" + string$(i)
    @PaulstretchOnSelected: stretch_factor, window_size, overlap_percent, psName$
    ps_id = selected("Sound")
    
    # Get the stretched duration
    selectObject: ps_id
    stretched_dur = Get total duration
    
    # Calculate center of original segment
    original_center = win_start + (seg_len / 2)
    
    # Calculate start position so stretched segment is centered on original position
    stretched_start = original_center - (stretched_dur / 2)
    
    # Ensure we don't go negative
    if stretched_start < 0
        stretched_start = 0
    endif
    
    writeInfoLine: "Slice ", i, ": stretched duration = ", fixed$(stretched_dur, 3), ", placing at ", fixed$(stretched_start, 3)

    # Create full-length channel with silence
    Create Sound from formula: "channel_" + string$(i), 1, 0, padded_duration, fs, "0"
    channel_id = selected("Sound")
    
    # Copy samples from stretched segment into the channel at the correct position
    selectObject: ps_id
    n_samples_ps = Get number of samples
    start_sample = round(stretched_start * fs) + 1
    
    for isamp from 1 to n_samples_ps
        selectObject: ps_id
        val = Get value at sample number: 1, isamp
        
        target_sample = start_sample + isamp - 1
        selectObject: channel_id
        n_samples_ch = Get number of samples
        
        if target_sample >= 1 and target_sample <= n_samples_ch
            Set value at sample number: 1, target_sample, val
        endif
    endfor
    
    selectObject: channel_id
    tmpName$ = orig_name$ + "_CH" + string$(i+1) + "_slice"
    Rename: tmpName$
    chan_ids#[i] = selected("Sound")

    # cleanup per-iteration objects
    removeObject: seg_id, ps_id
endfor

# --------------------------------------------
# Combine all channels into a (1 + N)-channel Sound
# CH1 = left original; CH2..CH(N+1) = one slice per channel
# --------------------------------------------
selectObject: left_id
for i to number_of_segments
    plusObject: chan_ids#[i]
endfor

# Multichannel combine (Praat ≥ 6.x)
Combine to stereo
tmpName$ = orig_name$ + "_LEFT_plus_" + string$(number_of_segments) + "PSlices_MULTICH"
Rename: tmpName$

# Optional: scale peak across all channels
Scale peak: 0.99
Play

# Store the result ID
result_id = selected("Sound")

# Cleanup temporary objects (keep original + result)
removeObject: left_id, right_src_id
for i to number_of_segments
    removeObject: chan_ids#[i]
endfor

# Select both original and result for user
selectObject: orig_id
plusObject: result_id