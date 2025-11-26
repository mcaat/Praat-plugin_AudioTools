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

# Phase History Swap (v6.1 - Clean Memory)
# Creates wide stereo by processing L/R with slightly different split points.
# Fixes "2 files" memory leak by cleaning up matrices properly.

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
total_dur = Get total duration
fs = Get sampling frequency

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

# 6. CLEANUP (Strict)
# Remove the mono source and the two mono processed chunks
removeObject: working_sound, left_result, right_result

if preview_info
    appendInfoLine: "Done."
endif

selectObject: stereo_final
Play

# =======================================================
# PROCEDURE: The Vectorized Matrix Swap Logic
# =======================================================
procedure FastPhaseSwap: .src_id, .split_pct
    selectObject: .src_id
    .tot_dur = Get total duration
    .split_time = .tot_dur * (.split_pct / 100)
    .late_dur = .tot_dur - .split_time
    
    # A. Split
    .early = Extract part: 0, .split_time, "rectangular", 1, "no"
    selectObject: .src_id
    .late = Extract part: .split_time, .tot_dur, "rectangular", 1, "no"
    
    # B. Matrix Conversion
    selectObject: .early
    .spec_e = To Spectrum: "yes"
    .mat_e = To Matrix
    .id_e = .mat_e
    .nc_e = Get number of columns
    
    selectObject: .late
    .spec_l = To Spectrum: "yes"
    .mat_l = To Matrix
    .nc_l = Get number of columns
    
    # C. Vectorized Math
    .ratio = .nc_e / .nc_l
    
    # Prepare Formula Strings
    .s_ratio$ = string$(.ratio)
    .s_nc_e$ = string$(.nc_e)
    .s_id_e$ = string$(.id_e)
    
    # 1. Map Columns
    .c_raw$ = "round(col * " + .s_ratio$ + ")"
    .c_safe$ = "(if " + .c_raw$ + " < 1 then 1 else (if " + .c_raw$ + " > " + .s_nc_e$ + " then " + .s_nc_e$ + " else " + .c_raw$ + " fi) fi)"
    
    # 2. Lookups
    .early_re$ = "object[" + .s_id_e$ + ", 1, " + .c_safe$ + "]"
    .early_im$ = "object[" + .s_id_e$ + ", 2, " + .c_safe$ + "]"
    
    # 3. Phase & Mag
    .target_phase$ = "arctan2(" + .early_im$ + ", " + .early_re$ + ")"
    .self_mag$ = "sqrt(self[1,col]^2 + self[2,col]^2)"
    
    # 4. Apply
    Formula: "if row = 1 then " + .self_mag$ + " * cos(" + .target_phase$ + ") else " + .self_mag$ + " * sin(" + .target_phase$ + ") fi"
    
    # D. Reconstruct
    .spec_out = To Spectrum
    .snd_out = To Sound
    
    # Fix Duration
    Extract part: 0, .late_dur, "rectangular", 1, "no"
    .final_id = selected("Sound")
    
    # CLEANUP (Fixed: Added .mat_l)
    removeObject: .early, .late, .spec_e, .mat_e, .spec_l, .mat_l, .spec_out, .snd_out
    
    # Return the ID of the result
    selectObject: .final_id
endproc