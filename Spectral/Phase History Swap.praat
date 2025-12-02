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

# Phase History Swap (v7.1 - With Presets - Fixed)
# Creates wide stereo by processing L/R with slightly different split points.

form Phase History Swap - Wide Stereo
    optionmenu preset: 1
        option Custom (use settings below)
        option Subtle Swap (50% split)
        option Early Swap (30% split)
        option Late Swap (70% split)
        option Extreme Early (20% split)
        option Extreme Late (80% split)
    
    comment === Custom Settings ===
    positive Split_at_percent 50
    positive Stereo_offset_percent 1.0
    comment (Left = Split, Right = Split + Offset)
    positive Fade_out_seconds 0.5
    boolean Preview_info 1
endform

# Apply presets
if preset = 2
    split_at_percent = 50
    stereo_offset_percent = 1.0
    preset_name$ = "Subtle"
elsif preset = 3
    split_at_percent = 30
    stereo_offset_percent = 1.5
    preset_name$ = "Early"
elsif preset = 4
    split_at_percent = 70
    stereo_offset_percent = 1.5
    preset_name$ = "Late"
elsif preset = 5
    split_at_percent = 20
    stereo_offset_percent = 2.0
    preset_name$ = "ExtremeEarly"
elsif preset = 6
    split_at_percent = 80
    stereo_offset_percent = 2.0
    preset_name$ = "ExtremeLate"
else
    preset_name$ = "Custom"
endif

# Get selected sound
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")
n_channels = Get number of channels
orig_sr = Get sampling frequency

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
    appendInfoLine: "Preset: ", preset_name$
    appendInfoLine: "Left Split: ", split_at_percent, "%"
    appendInfoLine: "Right Split: ", split_at_percent + stereo_offset_percent, "%"
endif

# 2. PROCESS LEFT CHANNEL (Base Split)
@FastPhaseSwap: working_sound, split_at_percent, orig_sr
left_result = selected("Sound")

# 3. PROCESS RIGHT CHANNEL (Split + Offset)
offset_split = split_at_percent + stereo_offset_percent

# Safety clamp
if offset_split >= 99
    offset_split = 99
endif

@FastPhaseSwap: working_sound, offset_split, orig_sr
right_result = selected("Sound")

# 4. COMBINE TO STEREO
selectObject: left_result
plusObject: right_result
stereo_final = Combine to stereo
Rename: sound_name$ + "_PhaseSwap_" + preset_name$

# 5. APPLY FADEOUT
if fade_out_seconds > 0
    curr_dur = Get total duration
    actual_fade = min(fade_out_seconds, curr_dur)
    t_fade_start = curr_dur - actual_fade
    
    s_start$ = fixed$(t_fade_start, 6)
    s_dur$ = fixed$(actual_fade, 6)
    
    Formula: "if x > " + s_start$ + " then self * 0.5 * (1 + cos(pi * (x - " + s_start$ + ") / " + s_dur$ + ")) else self fi"
endif

# 6. CLEANUP
removeObject: working_sound, left_result, right_result

if preview_info
    appendInfoLine: "Done."
endif

selectObject: stereo_final
Scale peak: 0.99
Play

# =======================================================
# PROCEDURE: Vectorized Matrix Swap (Fixed for extreme splits)
# =======================================================
procedure FastPhaseSwap: .src_id, .split_pct, .target_sr
    selectObject: .src_id
    .tot_dur = Get total duration
    .split_time = .tot_dur * (.split_pct / 100)
    .late_dur = .tot_dur - .split_time
    
    # --- A. Split ---
    .early = Extract part: 0, .split_time, "rectangular", 1, "no"
    selectObject: .src_id
    .late = Extract part: .split_time, .tot_dur, "rectangular", 1, "no"
    
    # --- B. Matrix Conversion & Immediate Cleanup ---
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
    .dur_ratio = .split_time / .late_dur
    
    # Prepare Formula Strings (High Precision)
    .s_ratio$ = fixed$(.dur_ratio, 10)
    .s_nc_e$ = fixed$(.nc_e, 0)
    .s_id_e$ = fixed$(.id_e, 0)
    
    # 1. Map Columns (Frequency alignment)
    .c_raw$ = "round(col * " + .s_ratio$ + ")"
    .c_safe$ = "(if " + .c_raw$ + " < 1 then 1 else (if " + .c_raw$ + " > " + .s_nc_e$ + " then " + .s_nc_e$ + " else " + .c_raw$ + " fi) fi)"
    
    # 2. Define Lookups
    .early_re$ = "object[" + .s_id_e$ + ", 1, " + .c_safe$ + "]"
    .early_im$ = "object[" + .s_id_e$ + ", 2, " + .c_safe$ + "]"
    
    # 3. Calculate Target Phase & Self Magnitude
    .target_phase$ = "arctan2(" + .early_im$ + ", " + .early_re$ + ")"
    .self_mag$ = "sqrt(self[1,col]^2 + self[2,col]^2)"
    
    # 4. Apply to the LATE matrix
    Formula: "if row = 1 then " + .self_mag$ + " * cos(" + .target_phase$ + ") else " + .self_mag$ + " * sin(" + .target_phase$ + ") fi"
    
    # --- D. Reconstruct ---
    .spec_out = To Spectrum
    .snd_out = To Sound
    
    # FIXED: Ensure exact sample rate and duration
    selectObject: .snd_out
    .actual_sr = Get sampling frequency
    .actual_dur = Get total duration
    
    # If sample rate doesn't match, resample
    if .actual_sr <> .target_sr
        Resample: .target_sr, 50
        .resampled = selected("Sound")
        removeObject: .snd_out
        .snd_out = .resampled
    endif
    
    # Extract to exact duration
    selectObject: .snd_out
    Extract part: 0, .late_dur, "rectangular", 1, "no"
    .final_id = selected("Sound")
    
    # --- E. Final Cleanup ---
    removeObject: .mat_e, .mat_l, .spec_out, .snd_out
    
    selectObject: .final_id
endproc