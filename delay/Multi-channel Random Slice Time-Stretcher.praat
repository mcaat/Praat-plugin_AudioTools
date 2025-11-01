# ============================================================
# Praat AudioTools - Multi-channel Random Slice Time-Stretcher.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Multi-channel Random Slice Time-Stretcher
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
# Random Duration-Stretched Slices -> One Channel per Slice
# CH1 = Original Left (unchanged)
# CH2..CH(N+1) = Duration-stretched slices (one per channel)
# ===========================================================

form Random Duration-Stretched Slices (Multi-channel output)
    positive number_of_segments 4
    real min_duration 0.5
    real max_duration 2.0
    comment ---- Duration manipulation parameters ----
    optionmenu Preset: 1
        option "Normal (1.0)"
        option "Slow (1.5)"
        option "Fast (0.67)"
        option "Double speed (0.5)"
        option "Half speed (2.0)"
endform

# Apply preset value to duration_factor
if preset = 1
    duration_factor = 1.0
elsif preset = 2
    duration_factor = 1.5
elsif preset = 3
    duration_factor = 0.67
elsif preset = 4
    duration_factor = 0.5
elsif preset = 5
    duration_factor = 2.0
endif

# --------------------------------------------
# Preconditions
# --------------------------------------------
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object first."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")

selectObject: orig_id
total_duration = Get total duration
fs = Get sampling frequency
nchan = Get number of channels

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
if duration_factor <= 0
    exitScript: "Duration factor must be > 0."
endif

# --------------------------------------------
# Calculate padding needed
# --------------------------------------------
# Maximum stretched duration (when duration_factor < 1, segments get longer)
max_stretched_duration = max_duration / duration_factor
padding_duration = max_stretched_duration
padded_duration = total_duration + padding_duration

# --------------------------------------------
# Prepare channel 1 (LEFT original) and the slice source
# --------------------------------------------
if nchan = 2
    # CH1 = original LEFT
    selectObject: orig_id
    left_id = Extract one channel: 1
    tmpName$ = orig_name$ + "_CH1_LEFT_orig"
    Rename: tmpName$
    left_id = selected("Sound")
    
    # Pad left channel to padded_duration
    Create Sound from formula: "tmp_pad_left", 1, 0, padding_duration, fs, "0"
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
    Create Sound from formula: "tmp_pad_left_mono", 1, 0, padding_duration, fs, "0"
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

# --------------------------------------------
# Procedure: Duration stretch using Manipulation
# --------------------------------------------
procedure DurationStretchOnSelected: .duration_factor, .outname$
    .local_in_id = selected("Sound")
    selectObject: .local_in_id
    .dur = Get total duration
    
    # Create manipulation object
    .manipulation = To Manipulation: 0.01, 75, 600
    
    # Create duration tier with user-specified factor
    .durationTier = Create DurationTier: "duration", 0, .dur
    Add point: 0, .duration_factor
    Add point: .dur, .duration_factor
    
    # Replace duration tier in manipulation
    selectObject: .manipulation
    plusObject: .durationTier
    Replace duration tier
    
    # Resynthesize using overlap-add method
    selectObject: .manipulation
    .resynthesized = Get resynthesis (overlap-add)
    Rename: .outname$
    Scale peak: 0.99
    
    # Clean up intermediate objects
    removeObject: .durationTier, .manipulation
    
    selectObject: .resynthesized
endproc

# --------------------------------------------
# Build one full-length channel per slice (CH2..CH(N+1))
# Each channel has silence except the duration-stretched slice at its position
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

    # Duration stretch the segment
    selectObject: seg_id
    stretchName$ = orig_name$ + "_stretched_" + string$(i)
    @DurationStretchOnSelected: duration_factor, stretchName$
    stretched_id = selected("Sound")
    
    # Get the stretched duration
    selectObject: stretched_id
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
    selectObject: stretched_id
    n_samples_stretched = Get number of samples
    start_sample = round(stretched_start * fs) + 1
    
    for isamp from 1 to n_samples_stretched
        selectObject: stretched_id
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
    removeObject: seg_id, stretched_id
endfor

# --------------------------------------------
# Combine all channels into a (1 + N)-channel Sound
# CH1 = left original; CH2..CH(N+1) = one slice per channel
# --------------------------------------------
selectObject: left_id
for i to number_of_segments
    plusObject: chan_ids#[i]
endfor

# Multichannel combine
Combine to stereo
tmpName$ = orig_name$ + "_LEFT_plus_" + string$(number_of_segments) + "DurStretch_MULTICH"
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