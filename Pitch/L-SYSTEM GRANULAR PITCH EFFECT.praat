# ============================================================
# Praat AudioTools - L-SYSTEM GRANULAR PITCH EFFECT.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   L-SYSTEM GRANULAR PITCH EFFECT
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form L-System Granular Gating + Pitch Effect
    comment === Presets ===
    optionmenu Preset 9
        option Rhythmic Stutter
        option Pitch Walk Up
        option Pitch Walk Down
        option Chaotic Glitch
        option Melodic Arpeggio
        option Sparse Texture
        option Dense Granular
        option Fibonacci Pattern
        option Custom
    
    comment === L-System Configuration ===
    sentence Axiom G
    sentence Rule_G GSUN
    sentence Rule_S N
    sentence Rule_U UD
    sentence Rule_D DU
    sentence Rule_N G
    positive Iterations 3
    positive MaxStringLength 10000
    
    comment === Granular Processing ===
    positive GrainDuration_ms 50
    boolean GrainOverlap 1
    real BaseSkipGain 0.0 (= 0.0)
    real RepeatGain 1.0 (= 1.0)
    
    comment === Pitch Control ===
    real BasePitchShift_semitones 0 (= 0)
    real PitchStep_semitones 2 (= 2)
    positive MaxPitchShift_semitones 12
endform

# --- 1. Apply Preset ---
axiom$ = axiom$
rule_G$ = rule_G$
rule_S$ = rule_S$
rule_U$ = rule_U$
rule_D$ = rule_D$
rule_N$ = rule_N$

if preset = 1
    # Rhythmic Stutter
    axiom$ = "GS"
    rule_G$ = "GSS"
    rule_S$ = "SG"
    rule_U$ = "U"
    rule_D$ = "D"
    rule_N$ = "N"
    iterations = 4
    grainDuration_ms = 40
    grainOverlap = 1
    baseSkipGain = 0.0
    repeatGain = 1.0
    basePitchShift_semitones = 0
    pitchStep_semitones = 1
elsif preset = 2
    # Pitch Walk Up
    axiom$ = "GU"
    rule_G$ = "GUN"
    rule_S$ = "N"
    rule_U$ = "UUN"
    rule_D$ = "N"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 60
    basePitchShift_semitones = -6
    pitchStep_semitones = 1
elsif preset = 3
    # Pitch Walk Down
    axiom$ = "GD"
    rule_G$ = "GDN"
    rule_S$ = "N"
    rule_U$ = "N"
    rule_D$ = "DDN"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 60
    basePitchShift_semitones = 6
    pitchStep_semitones = 1
elsif preset = 4
    # Chaotic Glitch
    axiom$ = "GSUD"
    rule_G$ = "GSUN"
    rule_S$ = "N"
    rule_U$ = "UD"
    rule_D$ = "DU"
    rule_N$ = "G"
    iterations = 3
    grainDuration_ms = 50
    basePitchShift_semitones = 0
    pitchStep_semitones = 2
elsif preset = 5
    # Melodic Arpeggio
    axiom$ = "GUUUDDD"
    rule_G$ = "G"
    rule_S$ = "G"
    rule_U$ = "UN"
    rule_D$ = "DN"
    rule_N$ = "N"
    iterations = 2
    grainDuration_ms = 80
    basePitchShift_semitones = -4
    pitchStep_semitones = 2
elsif preset = 6
    # Sparse Texture
    axiom$ = "S"
    rule_G$ = "GSSS"
    rule_S$ = "SSSG"
    rule_U$ = "U"
    rule_D$ = "D"
    rule_N$ = "S"
    iterations = 4
    grainDuration_ms = 30
    baseSkipGain = 0.05
    repeatGain = 0.8
    pitchStep_semitones = 3
elsif preset = 7
    # Dense Granular
    axiom$ = "G"
    rule_G$ = "GGUNG"
    rule_S$ = "G"
    rule_U$ = "UNG"
    rule_D$ = "DNG"
    rule_N$ = "NG"
    iterations = 3
    grainDuration_ms = 25
    baseSkipGain = 0.2
    repeatGain = 0.9
    pitchStep_semitones = 1
elsif preset = 8
    # Fibonacci Pattern
    axiom$ = "G"
    rule_G$ = "GN"
    rule_S$ = "S"
    rule_U$ = "UN"
    rule_D$ = "DN"
    rule_N$ = "G"
    iterations = 5
    grainDuration_ms = 45
    pitchStep_semitones = 2
endif

# --- 2. Error Check ---
if not selected("Sound")
    exitScript: "ERROR: Please select a Sound object first."
endif

id_sound = selected("Sound")
name$ = selected$("Sound")
dur = Get total duration
sr = Get sampling frequency
start_t = Get start time
end_t = Get end time
n_ch = Get number of channels

# --- 3. L-System Generation ---
writeInfoLine: "Generating L-System..."

curr_str$ = axiom$
curr_len = length(curr_str$)

for iter from 1 to iterations
    next_str$ = ""
    for i from 1 to curr_len
        char$ = mid$(curr_str$, i, 1)
        rep$ = char$
        if char$ == "G"
            rep$ = rule_G$
        elsif char$ == "S"
            rep$ = rule_S$
        elsif char$ == "U"
            rep$ = rule_U$
        elsif char$ == "D"
            rep$ = rule_D$
        elsif char$ == "N"
            rep$ = rule_N$
        endif
        next_str$ = next_str$ + rep$
    endfor
    curr_str$ = next_str$
    curr_len = length(curr_str$)
    
    if curr_len > maxStringLength
        curr_str$ = left$(curr_str$, maxStringLength)
        curr_len = maxStringLength
        goto END_LSYSTEM
    endif
endfor
label END_LSYSTEM

l_sys$ = curr_str$
l_len = curr_len

# --- 4. Grain Schedule ---
grain_dur_sec = grainDuration_ms / 1000
n_grains = floor(dur / grain_dur_sec)
if n_grains < 1
    n_grains = 1
endif

id_table = Create Table with column names: "schedule", n_grains, 
    ... "idx symbol tStart tEnd tCenter pitchShift play"

cum_pitch = basePitchShift_semitones
appendInfoLine: "Building Grain Schedule (", n_grains, " grains)..."

for k from 1 to n_grains
    sym_idx = ((k - 1) mod l_len) + 1
    sym$ = mid$(l_sys$, sym_idx, 1)
    
    t1 = start_t + (k - 1) * grain_dur_sec
    t2 = t1 + grain_dur_sec
    if t2 > end_t
        t2 = end_t
    endif
    tc = (t1 + t2) / 2
    
    this_pitch = cum_pitch
    
    if sym$ == "U"
        cum_pitch = cum_pitch + pitchStep_semitones
    elsif sym$ == "D"
        cum_pitch = cum_pitch - pitchStep_semitones
    endif
    
    if cum_pitch > maxPitchShift_semitones
        cum_pitch = maxPitchShift_semitones
    elsif cum_pitch < -maxPitchShift_semitones
        cum_pitch = -maxPitchShift_semitones
    endif
    
    do_play = 1
    if sym$ == "S"
        do_play = 0
    endif
    
    selectObject: id_table
    Set numeric value: k, "idx", k
    Set string value: k, "symbol", sym$
    Set numeric value: k, "tStart", t1
    Set numeric value: k, "tEnd", t2
    Set numeric value: k, "tCenter", tc
    Set numeric value: k, "pitchShift", this_pitch
    Set numeric value: k, "play", do_play
endfor

# --- 5. Pitch Processing ---
appendInfoLine: "Applying Pitch Shifting..."

selectObject: id_sound
id_manip = To Manipulation: 0.01, 75, 600

selectObject: id_manip
id_tier = Extract pitch tier
selectObject: id_tier
Remove points between: start_t, end_t

selectObject: id_sound
id_ref_pitch = To Pitch: 0.01, 75, 600

for k from 1 to n_grains
    selectObject: id_table
    tc = Get value: k, "tCenter"
    shift = Get value: k, "pitchShift"
    
    selectObject: id_ref_pitch
    f_orig = Get value at time: tc, "Hertz", "Linear"
    if f_orig = undefined
        f_orig = 150
    endif
    
    f_target = f_orig * (2 ^ (shift / 12))
    
    selectObject: id_tier
    Add point: tc, f_target
endfor

selectObject: id_manip
plusObject: id_tier
Replace pitch tier

selectObject: id_manip
id_resynth = Get resynthesis (overlap-add)
Rename: name$ + "_pitched"

removeObject: id_manip, id_tier, id_ref_pitch

# --- 6. Granular Gating ---
selectObject: id_resynth
id_out = Copy: name$ + "_LSystem"
channels = Get number of channels

fade_time = min(grain_dur_sec / 4, 0.005)

appendInfoLine: "Applying Granular Gating..."

for k from 1 to n_grains
    selectObject: id_table
    t1 = Get value: k, "tStart"
    t2 = Get value: k, "tEnd"
    play = Get value: k, "play"
    
    len = t2 - t1
    if len > 0
        gain = baseSkipGain
        if play == 1
            gain = repeatGain
        endif
        
        # Build optimized formula (Robust Syntax)
        form$ = "self * " + string$(gain)
        
        if grainOverlap and play
             # Fade In
             t_fade_in_end = t1 + fade_time
             form$ = form$ + " * (if x < " + string$(t_fade_in_end) + " then (x - " + string$(t1) + ") / " + string$(fade_time) + " else 1 fi)"
             
             # Fade Out
             t_fade_out_start = t2 - fade_time
             form$ = form$ + " * (if x > " + string$(t_fade_out_start) + " then (" + string$(t2) + " - x) / " + string$(fade_time) + " else 1 fi)"
        endif
        
        selectObject: id_out
        Formula (part): t1, t2, 1, channels, form$
    endif
    
    # FIX: Replaced 'ceil' with 'ceiling'
    if k mod ceiling(n_grains/10) = 0
        p = round(k / n_grains * 100)
        appendInfoLine: "... " + string$(p) + "%"
    endif
endfor

# --- 7. Cleanup ---
removeObject: id_table, id_resynth
selectObject: id_out
appendInfoLine: "Done!"
Play