# ============================================================
# Praat AudioTools - Constraint-Based Duration Control
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   AConstraint-Based Duration Control
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# OT-Driven Audio Manipulation (Auto-Segmentation)
# ============================================================

form OT Audio Manipulation Settings
    comment --- Presets ---
    optionmenu Preset: 1
        option Custom
        option Staccato (Short notes)
        option Legato (Long notes)
        option Strict Timing (Force target)
        option Natural (Preserve original)
        option Balanced (Default)
    
    comment --- OT Constraints ---
    real weight_target_duration 2.0
    real weight_faithfulness 1.0
    comment Target Duration for Notes (seconds)
    real target_dur 0.4
    
    comment --- Auto-Segmentation Settings ---
    comment Min pitch (Hz) for analysis:
    real min_pitch 100
    comment Silence threshold (dB relative to max):
    real silence_threshold -25.0
    comment Min silent interval (s):
    real min_silent_dur 0.1
    comment Min sounding interval (s):
    real min_sounding_dur 0.1
    
    comment --- Playback ---
    boolean play_result 1
endform

# ============================================================
# APPLY PRESETS
# ============================================================

if preset = 2
    weight_target_duration = 5.0
    weight_faithfulness = 0.5
    target_dur = 0.2
elif preset = 3
    weight_target_duration = 1.0
    weight_faithfulness = 0.5
    target_dur = 0.8
elif preset = 4
    weight_target_duration = 10.0
    weight_faithfulness = 0.1
    target_dur = 0.4
elif preset = 5
    weight_target_duration = 0.1
    weight_faithfulness = 5.0
    target_dur = 0.4
elif preset = 6
    weight_target_duration = 2.0
    weight_faithfulness = 1.0
    target_dur = 0.4
endif

appendInfoLine: "============================================"
if preset = 1
    appendInfoLine: "Preset: Custom"
elif preset = 2
    appendInfoLine: "Preset: Staccato (Short notes)"
elif preset = 3
    appendInfoLine: "Preset: Legato (Long notes)"
elif preset = 4
    appendInfoLine: "Preset: Strict Timing"
elif preset = 5
    appendInfoLine: "Preset: Natural (Preserve original)"
elif preset = 6
    appendInfoLine: "Preset: Balanced"
endif
appendInfoLine: "Weight Target Duration: ", weight_target_duration
appendInfoLine: "Weight Faithfulness: ", weight_faithfulness
appendInfoLine: "Target Duration: ", target_dur, " s"
appendInfoLine: "============================================"

# 1. SETUP & AUTO-SEGMENTATION
# ============================================================
if numberOfSelected() <> 1
    exitScript: "Please select exactly one Sound object."
endif

soundID = selected("Sound")
selectObject: soundID

# Create TextGrid automatically based on Silences/Sound
textGridID = To TextGrid (silences): min_pitch, 0.0, silence_threshold, min_silent_dur, min_sounding_dur, "silent", "sounding"

# 2. SETUP MANIPULATION OBJECTS
# ============================================================
selectObject: soundID
manipID = To Manipulation: 0.01, min_pitch, 600
selectObject: manipID
durTierID = Extract duration tier

selectObject: textGridID
numIntervals = Get number of intervals: 1

# 3. OT EVALUATION LOOP
# ============================================================
intervals_processed = 0

for i to numIntervals
    selectObject: textGridID
    label$ = Get label of interval: 1, i
    
    if label$ = "sounding"
        start = Get start time of interval: 1, i
        end = Get end time of interval: 1, i
        current_dur = end - start
        
        # --- GEN: Create Candidates ---
        candA_val = current_dur
        candB_val = target_dur
        candC_val = (current_dur * 0.5) + (target_dur * 0.5)
        
        # --- EVAL: Calculate Harmonies ---
        viol_target_A = abs(candA_val - target_dur)
        viol_faith_A = 0
        score_A = (viol_target_A * weight_target_duration) + (viol_faith_A * weight_faithfulness)
        
        viol_target_B = 0
        viol_faith_B = abs(candB_val - current_dur)
        score_B = (viol_target_B * weight_target_duration) + (viol_faith_B * weight_faithfulness)
        
        viol_target_C = abs(candC_val - target_dur)
        viol_faith_C = abs(candC_val - current_dur)
        score_C = (viol_target_C * weight_target_duration) + (viol_faith_C * weight_faithfulness)
        
        # --- SELECTION: Pick the winner ---
        winner_val = candA_val
        best_score = score_A
        
        if score_B < best_score
            winner_val = candB_val
            best_score = score_B
        endif
        if score_C < best_score
            winner_val = candC_val
            best_score = score_C
        endif
        
        ratio = winner_val / current_dur
        
        selectObject: durTierID
        midpoint = (start + end) / 2
        Add point: midpoint, ratio
        
        intervals_processed = intervals_processed + 1
    endif
endfor

# 4. RESYNTHESIS & CLEANUP
# ============================================================
selectObject: manipID
plusObject: durTierID
Replace duration tier

selectObject: manipID
resynthID = Get resynthesis (overlap-add)
selectObject: resynthID
Rename: "OT_Manipulated_Output"

# Remove temporary objects
selectObject: textGridID
plusObject: manipID
plusObject: durTierID
Remove

appendInfoLine: ""
appendInfoLine: "OT Manipulation Complete!"
appendInfoLine: "Intervals processed: ", intervals_processed
appendInfoLine: "Created: OT_Manipulated_Output"
appendInfoLine: "============================================"

# 5. PLAYBACK
# ============================================================
if play_result
    appendInfoLine: ""
    appendInfoLine: "Playing: OT_Manipulated_Output..."
    selectObject: resynthID
    Play
endif
