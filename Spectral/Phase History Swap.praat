# ============================================================
# Praat AudioTools - Phase History Swap .praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Phase History Swap 
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Phase History Swap (v7.0 - Optimized & Corrected)
# Creates wide stereo by processing L/R with slightly different split points.
# Improvements: 
# 1. Immediate memory cleanup to prevent RAM spikes.
# 2. Correct Frequency-Bin alignment (matches Hz to Hz).

form Phase History Swap - Wide Stereo
    comment Main Split Point (%):
    positive Split_at_percent 50
    
    comment Stereo Offset (%):
    positive Stereo_offset_percent 1.0
    comment (Left = Split, Right = Split + Offset)
    
    comment --- Tail Settings ---
    positive Fade_out_seconds 0.5
    
    boolean Preview_info 1
endform

# Get selected sound
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")
n_channels = Get number of channels

# 1. PREPARE INPUT (Force Mono Source)
if n_channels > 1
    selectObject: sound
    working_sound = Convert to mono
    Rename: "temp_mono_source"
else
    selectObject: sound
    working_sound = Copy: "temp_mono_source"
endif

if preview_info
    writeInfoLine: "Phase History Swap (Wide Stereo)"
    appendInfoLine: "Left Split: ", split_at_percent, "%"
    appendInfoLine: "Right Split: ", split_at_percent + stereo_offset_percent, "%"
endif

# 2. PROCESS LEFT CHANNEL (Base Split)
@FastPhaseSwap: working_sound, split_at_percent
left_result = selected("Sound")

# 3. PROCESS RIGHT CHANNEL (Split + Offset)
offset_split = split_at_percent + stereo_offset_percent

# Safety clamp
if offset_split >= 99
    offset_split = 99
endif

@FastPhaseSwap: working_sound, offset_split
right_result = selected("Sound")

# 4. COMBINE TO STEREO
selectObject: left_result
plusObject: right_result
stereo_final = Combine to stereo
Rename: sound_name$ + "_PhaseSwap_Wide"

# 5. APPLY FADEOUT
if fade_out_seconds > 0
    curr_dur = Get total duration
    actual_fade = min(fade_out_seconds, curr_dur)
    t_fade_start = curr_dur - actual_fade
    
    s_start$ = fixed$(t_fade_start, 6)
    s_dur$ = fixed$(actual_fade, 6)
    
    # Formula works on both channels automatically
    Formula: "if x > " + s_start$ + " then self * 0.5 * (1 + cos(pi * (x - " + s_start$ + ") / " + s_dur$ + ")) else self fi"
endif

# 6. CLEANUP
# Remove the mono source and the two mono processed chunks
removeObject: working_sound, left_result, right_result

if preview_info
    appendInfoLine: "Done."
endif

selectObject: stereo_final
Scale peak: 0.99
Play

# =======================================================
# PROCEDURE: Vectorized Matrix Swap (Optimized)
# =======================================================
procedure FastPhaseSwap: .src_id, .split_pct
    selectObject: .src_id
    .tot_dur = Get total duration
    .split_time = .tot_dur * (.split_pct / 100)
    .late_dur = .tot_dur - .split_time
    
    # --- A. Split ---
    .early = Extract part: 0, .split_time, "rectangular", 1, "no"
    selectObject: .src_id
    .late = Extract part: .split_time, .tot_dur, "rectangular", 1, "no"
    
    # --- B. Matrix Conversion & Immediate Cleanup ---
    # We convert to Matrix and immediately delete the Source/Spectrum
    # to keep memory footprint low.
    
    selectObject: .early
    .spec_e = To Spectrum: "yes"
    .mat_e = To Matrix
    .id_e = .mat_e
    .nc_e = Get number of columns
    removeObject: .early, .spec_e
    
    selectObject: .late
    .spec_l = To Spectrum: "yes"
    .mat_l = To Matrix
    .id_l = .mat_l
    removeObject: .late, .spec_l
    
    # --- C. Vectorized Math (Frequency Corrected) ---
    
    # [DSP FIX] 
    # To map 100Hz in the Late chunk to 100Hz in the Early chunk,
    # we must account for different bin widths caused by different durations.
    # BinWidth = 1/Duration.
    # The ratio is Early_Duration / Late_Duration.
    
    .dur_ratio = .split_time / .late_dur
    
    # Prepare Formula Strings (High Precision)
    .s_ratio$ = fixed$(.dur_ratio, 10)
    .s_nc_e$ = fixed$(.nc_e, 0)
    .s_id_e$ = fixed$(.id_e, 0)
    
    # 1. Map Columns (Frequency alignment)
    .c_raw$ = "round(col * " + .s_ratio$ + ")"
    # Clamp the index to ensure we don't look outside the Early matrix
    .c_safe$ = "(if " + .c_raw$ + " < 1 then 1 else (if " + .c_raw$ + " > " + .s_nc_e$ + " then " + .s_nc_e$ + " else " + .c_raw$ + " fi) fi)"
    
    # 2. Define Lookups
    # We look up the Real/Imaginary parts from the EARLY matrix (.id_e)
    # using the calculated column index (.c_safe$)
    .early_re$ = "object[" + .s_id_e$ + ", 1, " + .c_safe$ + "]"
    .early_im$ = "object[" + .s_id_e$ + ", 2, " + .c_safe$ + "]"
    
    # 3. Calculate Target Phase & Self Magnitude
    .target_phase$ = "arctan2(" + .early_im$ + ", " + .early_re$ + ")"
    .self_mag$ = "sqrt(self[1,col]^2 + self[2,col]^2)"
    
    # 4. Apply to the LATE matrix (Self)
    # Row 1 = Real, Row 2 = Imaginary
    Formula: "if row = 1 then " + .self_mag$ + " * cos(" + .target_phase$ + ") else " + .self_mag$ + " * sin(" + .target_phase$ + ") fi"
    
    # --- D. Reconstruct ---
    .spec_out = To Spectrum
    .snd_out = To Sound
    
    # Fix Duration to match exact tail length
    Extract part: 0, .late_dur, "rectangular", 1, "no"
    .final_id = selected("Sound")
    
    # --- E. Final Cleanup ---
    removeObject: .mat_e, .mat_l, .spec_out, .snd_out
    
    # Return the ID of the result
    selectObject: .final_id
endproc