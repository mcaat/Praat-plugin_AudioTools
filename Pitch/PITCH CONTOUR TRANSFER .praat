# ============================================================
# Praat AudioTools - PITCH CONTOUR TRANSFER 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   PITCH CONTOUR TRANSFER 
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ======================================================================
# PITCH CONTOUR TRANSFER 
# ======================================================================

form Pitch Contour Transfer
    comment Select Sound A (source style) and Sound B (target sound)
    real Analysis_time_step 0.01
    real Pitch_floor_A 75
    real Pitch_ceiling_A 300
    real Pitch_floor_B 50
    real Pitch_ceiling_B 300
    real Blend_strength 1.0
endform

numberOfSelected = numberOfSelected("Sound")
if numberOfSelected <> 2
    exitScript: "Please select exactly 2 Sound objects (A then B)"
endif

sound_a = selected("Sound", 1)
sound_b = selected("Sound", 2)

selectObject: sound_a
name_a$ = selected$("Sound")
selectObject: sound_b
name_b$ = selected$("Sound")

writeInfoLine: "PITCH MEAN SHIFT TRANSFER"
appendInfoLine: "Source: ", name_a$
appendInfoLine: "Target: ", name_b$
appendInfoLine: ""

# ======================================================================
# Analyze Sound A
# ======================================================================
selectObject: sound_a
pitch_a = To Pitch... analysis_time_step pitch_floor_A pitch_ceiling_A

selectObject: pitch_a
mean_a = Get mean... 0 0 Hertz

appendInfoLine: "Sound A: ", fixed$(mean_a, 1), " Hz"

# ======================================================================
# Analyze Sound B
# ======================================================================
selectObject: sound_b
pitch_b = To Pitch... analysis_time_step pitch_floor_B pitch_ceiling_B

selectObject: pitch_b
n_frames_b = Get number of frames
mean_b = Get mean... 0 0 Hertz
n_voiced_b = Count voiced frames
voiced_percent = (n_voiced_b / n_frames_b) * 100

appendInfoLine: "Sound B: ", fixed$(mean_b, 1), " Hz (", fixed$(voiced_percent, 1), "% voiced)"
appendInfoLine: ""

# Calculate shift
mean_shift = (mean_a - mean_b) * blend_strength
semitones = 12 * log2((mean_b + mean_shift) / mean_b)

appendInfoLine: "Shift: ", fixed$(mean_shift, 1), " Hz (", fixed$(semitones, 2), " semitones)"
appendInfoLine: ""

# ======================================================================
# Transform
# ======================================================================
selectObject: sound_b
manipulation = To Manipulation... analysis_time_step pitch_floor_B pitch_ceiling_B

selectObject: manipulation
pitch_tier = Extract pitch tier

selectObject: pitch_tier
Remove points between... 0 10000

n_points = 0

for i from 1 to n_frames_b
    selectObject: pitch_b
    t = Get time from frame number... i
    f0_b = Get value at time... t Hertz Linear
    
    if f0_b <> undefined
        target_f0 = f0_b + mean_shift
        
        if target_f0 < pitch_floor_B
            target_f0 = pitch_floor_B
        elsif target_f0 > pitch_ceiling_B
            target_f0 = pitch_ceiling_B
        endif
        
        selectObject: pitch_tier
        Add point... t target_f0
        n_points += 1
    endif
endfor

appendInfoLine: "Points added: ", n_points, " / ", n_frames_b
appendInfoLine: ""

# ======================================================================
# Resynthesize
# ======================================================================
selectObject: manipulation
plus pitch_tier
Replace pitch tier

selectObject: manipulation
sound_result = Get resynthesis (overlap-add)

selectObject: sound_result
Rename... 'name_b$'_shifted

# ======================================================================
# Results
# ======================================================================
selectObject: sound_result
pitch_result = To Pitch... analysis_time_step pitch_floor_B pitch_ceiling_B

mean_result = Get mean... 0 0 Hertz

appendInfoLine: "Result: ", fixed$(mean_b, 1), " → ", fixed$(mean_result, 1), " Hz"
appendInfoLine: ""
appendInfoLine: "Playing..."

# ======================================================================
# Playback
# ======================================================================
selectObject: sound_result
Play

appendInfoLine: ""
appendInfoLine: "Done: '", name_b$, "_shifted'"

# ======================================================================
# Cleanup
# ======================================================================
removeObject: manipulation, pitch_tier, pitch_a, pitch_b, pitch_result

selectObject: sound_result