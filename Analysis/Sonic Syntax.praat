# ============================================================
# Praat AudioTools - Sonic Syntax
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sonic Syntax
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Sonic Syntax
# Description: Global Optimization CSP Solver (Dynamic Programming)
# "Caesura Logic" - Finds the globally optimal sequence of cuts


form PWConstraints: Global Boundary Detector
    comment === HARD CONSTRAINTS ===
    real Silence_threshold_relative_to_max_(dB) -25
    positive Min_duration_between_cuts_(s) 0.5
    
    comment === SOFT CONSTRAINTS (SCORING) ===
    comment (Weights determine importance)
    positive Weight_Pitch_Slope 2.0
    positive Weight_Centering 1.0
    
    comment === DENSITY CONTROL ===
    positive Insertion_bonus 50.0
    comment (Higher = more cuts allowed. Lower = strict quality control.)
    
    comment === ANALYSIS PARAMETERS ===
    positive Silent_interval_min_duration_(s) 0.05
    positive Pitch_analysis_window_(s) 0.05
    positive Pitch_floor_(Hz) 75
    positive Pitch_ceiling_(Hz) 500
    
    comment === OUTPUT ===
    boolean Create_TextGrid 1
    boolean Print_debug_log 1
    sentence Output_tier_name Boundaries
endform

##############################################
# 1. SETUP & FEATURE EXTRACTION
##############################################

if print_debug_log
    clearinfo
    appendInfoLine: "Running Global Optimization (Dynamic Programming)..."
    appendInfoLine: "Insertion Bonus: ", insertion_bonus
endif

sound_id = selected("Sound")
sound$ = selected$("Sound")
total_dur = Get total duration

# Create Analysis Objects
selectObject: sound_id
intensity_id = To Intensity: 100, 0, "yes"

selectObject: sound_id
pitch_id = To Pitch: 0, pitch_floor, pitch_ceiling

# Detect Silences (Candidates)
selectObject: intensity_id
# Ensure threshold is negative
if silence_threshold_relative_to_max > 0
    silence_threshold_relative_to_max = -silence_threshold_relative_to_max
endif

silence_tg = To TextGrid (silences): silence_threshold_relative_to_max, 
    ...silent_interval_min_duration, 1, "silent", "sounding"

# Count Candidates
n_intervals = Get number of intervals: 1
n_candidates = 0

# Count first to allocate arrays
for i to n_intervals
    label$ = Get label of interval: 1, i
    if label$ = "silent"
        n_candidates += 1
    endif
endfor

if n_candidates = 0
    exitScript: "No silence candidates found. Try adjusting threshold."
endif

# Initialize Candidate Arrays
cand_time# = zero#(n_candidates)
cand_score# = zero#(n_candidates)
cand_orig_index# = zero#(n_candidates)

# --- DP ARRAYS ---
# max_score_to_here[i]: The best possible total score ending at cut i
# best_prev_index[i]: The index of the cut coming before i in that best path
dp_max_score# = zero#(n_candidates)
dp_prev_index# = zero#(n_candidates)

# Fill Candidate Data
curr_cand = 0
for i to n_intervals
    selectObject: silence_tg
    label$ = Get label of interval: 1, i
    if label$ = "silent"
        curr_cand += 1
        start = Get start time of interval: 1, i
        end = Get end time of interval: 1, i
        
        # Strategy: Use Center of silence for stability
        time = (start + end) / 2
        cand_time#[curr_cand] = time
        cand_orig_index#[curr_cand] = i
        
        # --- CALCULATE LOCAL SCORE (SOFT CONSTRAINTS) ---
        selectObject: pitch_id
        # Get slope before cut
        p_start = Get value at time: time - pitch_analysis_window, "Hertz", "Linear"
        p_end = Get value at time: time, "Hertz", "Linear"
        
        slope_score = 0
        if p_start != undefined and p_end != undefined
            slope = (p_end - p_start) / pitch_analysis_window
            # Falling slope (negative) becomes positive score
            slope_score = -slope * weight_Pitch_Slope
        endif
        
        # Centering score
        mid = (start + end) / 2
        dev = abs(time - mid)
        center_score = -dev * 100 * weight_Centering
        
        # Total Local Score + INSERTION BONUS
        # The bonus ensures that "making a cut" is generally better than "skipping a cut"
        cand_score#[curr_cand] = slope_score + center_score + insertion_bonus
    endif
endfor

##############################################
# 2. THE SOLVER (DYNAMIC PROGRAMMING)
##############################################

if print_debug_log
    appendInfoLine: "Solving path for ", n_candidates, " candidates..."
endif

# Initialize DP arrays with a very low number
for i to n_candidates
    dp_max_score#[i] = -1000000
    dp_prev_index#[i] = 0
endfor

# --- Forward Pass ---
for i from 1 to n_candidates
    t_curr = cand_time#[i]
    local_s = cand_score#[i]
    
    # 1. Check if this can be the FIRST cut (valid from start 0.0)
    if t_curr >= min_duration_between_cuts
        # Score is just its own quality
        if local_s > dp_max_score#[i]
            dp_max_score#[i] = local_s
            # 0 means "Start of file"
            dp_prev_index#[i] = 0
        endif
    endif
    
    # 2. Check connections from all previous nodes j -> i
    for j from 1 to i-1
        t_prev = cand_time#[j]
        score_prev = dp_max_score#[j]
        
        # Hard Constraint: Min Duration
        dist = t_curr - t_prev
        
        # Only consider path if previous node was reachable (score > -infinity)
        if dist >= min_duration_between_cuts and score_prev > -999999
            # Bellman Equation: Score = Max(PrevScore) + CurrentScore
            new_total = score_prev + local_s
            
            if new_total > dp_max_score#[i]
                dp_max_score#[i] = new_total
                dp_prev_index#[i] = j
            endif
        endif
    endfor
endfor

##############################################
# 3. BACKTRACKING (PATH RECONSTRUCTION)
##############################################

# Find the best end-node
best_end_node = 0
max_final_score = -1000000

for i from 1 to n_candidates
    if dp_max_score#[i] > max_final_score
        max_final_score = dp_max_score#[i]
        best_end_node = i
    endif
endfor

if best_end_node = 0
    # Clean up before exit
    removeObject: intensity_id, pitch_id, silence_tg
    exitScript: "No valid path found satisfying constraints."
endif

# Trace back
# Upper bound size
final_cuts# = zero#(n_candidates)
count = 0
curr = best_end_node

while curr > 0
    count += 1
    final_cuts#[count] = cand_time#[curr]
    curr = dp_prev_index#[curr]
endwhile

##############################################
# 4. OUTPUT GENERATION
##############################################

if create_TextGrid
    selectObject: sound_id
    tg_out = To TextGrid: output_tier_name$, ""
    
    # Array is reversed (end -> start), so iterate backwards
    for k from 1 to count
        idx = count - k + 1
        t = final_cuts#[idx]
        Insert boundary: 1, t
    endfor
    
    # Label
    n_seg = Get number of intervals: 1
    for i from 1 to n_seg
        Set interval text: 1, i, "Phrase " + string$(i)
    endfor
    
    selectObject: tg_out
    plusObject: sound_id
    View & Edit
endif

# Clean up
removeObject: intensity_id, pitch_id, silence_tg

if print_debug_log
    appendInfoLine: "Success!"
    appendInfoLine: "Found global optimal path with ", count, " cuts."
    appendInfoLine: "Total Path Score: ", fixed$(max_final_score, 2)
endif