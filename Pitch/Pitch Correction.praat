# ============================================================
# Praat AudioTools - Pitch Correction.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch Correction
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
# Praat AudioTools - Pitch Correction v3 (Scales & Modes)
# ============================================================

form Pitch Correction Tool
    comment === PRESETS ===
    optionmenu Preset 1
        option Custom
        option Natural Correction
        option Hard Auto-Tune
        option Robot / Monotone
    
    comment === MUSICAL KEY ===
    optionmenu Root_Note 1
        option C
        option C# / Db
        option D
        option D# / Eb
        option E
        option F
        option F# / Gb
        option G
        option G# / Ab
        option A
        option A# / Bb
        option B
    
    optionmenu Scale_Type 2
        option Chromatic (All notes)
        option Major (Ionian)
        option Minor (Natural)
        option Minor (Harmonic)
        option Pentatonic Major
        option Pentatonic Minor
        option Dorian
        option Phrygian
        option Lydian
        option Mixolydian
        
    comment === CORRECTION PARAMS ===
    integer Transpose_Output 0
    positive Strength_Percent 100
    
    comment === ANALYSIS ===
    positive Pitch_Time_Step 0.01
    positive Min_Pitch 75
    positive Max_Pitch 600
    
    comment === OUTPUT ===
    boolean Play_Result 1
endform

# --- 1. Preset Logic ---
strength = strength_Percent
smooth_amount = 0

if preset == 2
    # Natural
    strength = 60
    smooth_amount = 2.0
elsif preset == 3
    # Hard Auto-Tune
    strength = 100
    smooth_amount = 0
elsif preset == 4
    # Robot
    strength = 100
    smooth_amount = 10.0
endif

# --- 2. Input Check ---
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

id_sound = selected("Sound")
name$ = selected$("Sound")

# --- 3. Define Scale Patterns ---
# Patterns represent semitones 0-11. "1"=Allowed, "0"=Skip.
# Standard: C, C#, D, D#, E, F, F#, G, G#, A, A#, B

pat$ = "111111111111" ; Default Chromatic

if scale_Type == 2
    # Major (W W H W W W H) -> 0 2 4 5 7 9 11
    pat$ = "101011010101"
elsif scale_Type == 3
    # Minor Natural (W H W W H W W) -> 0 2 3 5 7 8 10
    pat$ = "101101011010"
elsif scale_Type == 4
    # Minor Harmonic (Raise 7th) -> 0 2 3 5 7 8 11
    pat$ = "101101011001"
elsif scale_Type == 5
    # Pentatonic Major (0 2 4 7 9)
    pat$ = "101010010100"
elsif scale_Type == 6
    # Pentatonic Minor (0 3 5 7 10)
    pat$ = "100101010010"
elsif scale_Type == 7
    # Dorian (Minor with natural 6) -> 0 2 3 5 7 9 10
    pat$ = "101101010110"
elsif scale_Type == 8
    # Phrygian (Minor with flat 2) -> 0 1 3 5 7 8 10
    pat$ = "110101011010"
elsif scale_Type == 9
    # Lydian (Major with sharp 4) -> 0 2 4 6 7 9 11
    pat$ = "101010110101"
elsif scale_Type == 10
    # Mixolydian (Major with flat 7) -> 0 2 4 5 7 9 10
    pat$ = "101011010110"
endif

# Map Root Note to Index (0=C, 1=C#, etc)
# The form returns index 1..12, so we subtract 1.
root_idx = root_Note - 1

# --- 4. Pipeline ---
selectObject: id_sound
id_manip = To Manipulation: pitch_Time_Step, min_Pitch, max_Pitch

selectObject: id_manip
id_pitch = Extract pitch tier

# --- 5. Smoothing (FIXED) ---
if smooth_amount > 0
    selectObject: id_pitch
    # PitchTiers use 'Stylize' to smooth curves, not 'Smooth'
    Stylize: smooth_amount, "Hz"
endif

# --- 6. Correction Logic ---
selectObject: id_pitch
Copy: "Corrected"
id_corr = selected("PitchTier")

n = Get number of points
for i from 1 to n
    selectObject: id_corr
    val = Get value at index: i
    time = Get time from index: i
    
    if val > 50 and val < 1000
        # A. Convert Hz to MIDI Note Number (C-1 = 0, A440 = 69)
        midi_float = 69 + 12 * log2(val / 440)
        midi_round = round(midi_float)
        
        # B. Determine Pitch Class relative to Root (0-11)
        # (midi_round - root_idx) mod 12
        # We perform modulo math carefully for negative numbers
        pc_raw = (midi_round - root_idx) mod 12
        if pc_raw < 0
            pc_raw = pc_raw + 12
        endif
        
        # C. Check Scale Pattern
        # String index is 1-based, so add 1
        is_allowed$ = mid$(pat$, pc_raw + 1, 1)
        
        if is_allowed$ == "0"
            # Note is OUT of scale. Find nearest neighbor.
            # We look +/- 1 semitone.
            
            # Check Upper (+1)
            pc_up = (pc_raw + 1) mod 12
            allowed_up$ = mid$(pat$, pc_up + 1, 1)
            
            # Check Lower (-1)
            pc_down = (pc_raw - 1)
            if pc_down < 0 
                pc_down = 11 
            endif
            allowed_down$ = mid$(pat$, pc_down + 1, 1)
            
            # Decide where to snap
            if allowed_up$ == "1" and allowed_down$ == "0"
                midi_round = midi_round + 1
            elsif allowed_down$ == "1" and allowed_up$ == "0"
                midi_round = midi_round - 1
            elsif allowed_down$ == "1" and allowed_up$ == "1"
                # Both neighbors valid? Snap to physically closer one.
                diff = midi_float - midi_round
                if diff > 0
                    midi_round = midi_round + 1
                else
                    midi_round = midi_round - 1
                endif
            endif
        endif
        
        # D. Convert Target MIDI back to Hz
        target_val = 440 * (2 ^ ((midi_round - 69) / 12))
        
        # E. Apply Transpose (Output only)
        # We apply transpose AFTER finding the scale tone
        if transpose_Output != 0
             target_val = target_val * (2 ^ (transpose_Output / 12))
        endif

        # F. Blend (Strength)
        final_val = val + (target_val - val) * (strength / 100)
        
        Remove point: i
        Add point: time, final_val
    endif
endfor

# --- 7. Resynthesis ---
selectObject: id_manip
plusObject: id_corr
Replace pitch tier

selectObject: id_manip
id_out = Get resynthesis (overlap-add)
Rename: name$ + "_fixed"

# --- 8. Cleanup ---
selectObject: id_manip
plusObject: id_pitch
plusObject: id_corr
Remove

selectObject: id_out
if play_Result
    Play
endif