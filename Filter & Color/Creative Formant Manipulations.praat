# ============================================================
# Praat AudioTools - Creative Formant Manipulations.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Creative Formant Manipulations script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Creative Formant Manipulations (v2.4 - Array Bounds Fixed)
# Fixes: "Undefined variable" crash in Crossfade section.
# Uses LPC Source-Filter model for clean results.

form Creative Formant Manipulations
    comment Select manipulation type:
    optionmenu Manipulation_type 1
        option Formant rotation (vowel morphing)
        option Formant reversal (spectral flip)
        option Formant scrambling (randomize)
        option Formant scaling (gender shift)
        option Formant LFO modulation
        option Formant crossfade (temporal blend)
        option Formant freezing (hold vowels)
    
    comment --- Analysis Parameters ---
    positive Time_step_(s) 0.005
    positive Max_number_of_formants 5
    positive Maximum_formant_(Hz) 5500
    positive Window_length_(s) 0.025
    positive Pre_emphasis_from_(Hz) 50
    
    comment --- Effect Parameters ---
    comment [Rotation] Semitones shift:
    real Rotation_amount 3.0
    
    comment [Scaling] Freq ratio / BW ratio:
    real Formant_shift_ratio 0.8
    real Formant_stretch_ratio 1.2
    
    comment [LFO] Rate (Hz) / Depth (semitones):
    positive LFO_rate_Hz 2.0
    positive LFO_depth_semitones 6.0
    
    comment [Crossfade] Number of cycles:
    positive Crossfade_cycles 3
    
    comment [Freeze] Interval (s) / Duration (s):
    positive Freeze_interval 0.3
    positive Freeze_duration 0.15
    
    boolean Play_result 1
endform

# Get selected sound
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
soundName$ = selected$("Sound")
dur = Get total duration
sr = Get sampling frequency

# 1. PREPARE SOURCE (The "Buzz")
writeInfoLine: "--- Processing Pipeline ---"
appendInfoLine: "[1/4] Extracting Source (LPC Inverse Filtering)..."

selectObject: sound
# We use standard LPC Burg for the inverse filter to get the source
lpc = To LPC (burg): max_number_of_formants, window_length, time_step, pre_emphasis_from
plusObject: sound
source = Filter (inverse)
Rename: "source_excitation"

# 2. ANALYZE FORMANTS (The "Filter")
appendInfoLine: "[2/4] Analyzing Formants..."
selectObject: sound
# We use FormantPath for the smooth manipulation base
fpath = To FormantPath (burg): time_step, max_number_of_formants, maximum_formant, window_length, pre_emphasis_from, 0.05, 4
formant = Extract Formant

# Store data in arrays (Caching for speed)
selectObject: formant
numFrames = Get number of frames
firstTime = Get time from frame number: 1

for i to numFrames
    t[i] = Get time from frame number: i
    nF[i] = Get number of formants: i
    for f to nF[i]
        val_f[i,f] = Get value at time: f, t[i], "hertz", "Linear"
        val_b[i,f] = Get bandwidth at time: f, t[i], "hertz", "Linear"
    endfor
endfor

# Convert to Grid for manipulation
selectObject: formant
fgrid = Down to FormantGrid

# 3. APPLY MANIPULATIONS
appendInfoLine: "[3/4] Applying Effect: ", manipulation_type$

selectObject: fgrid

# --- ROTATION ---
if manipulation_type = 1
    factor = 2^(rotation_amount / 12)
    for i to numFrames
        for f to nF[i]
            hz = val_f[i,f]
            if hz <> undefined
                new_hz = hz * factor
                if new_hz < maximum_formant
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], new_hz
                endif
            endif
        endfor
    endfor

# --- REVERSAL (Spectral Flip) ---
elsif manipulation_type = 2
    for i to numFrames
        for f to max_number_of_formants
            # Map F1->F5, F2->F4, etc.
            src_f = max_number_of_formants - f + 1
            
            # Safety check if source formant exists
            if src_f <= nF[i]
                hz = val_f[i, src_f]
                bw = val_b[i, src_f]
                
                if hz <> undefined
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], hz
                    # Swap bandwidths to prevent whistling
                    Remove bandwidth points between: f, t[i]-0.0001, t[i]+0.0001
                    Add bandwidth point: f, t[i], bw
                endif
            endif
        endfor
    endfor

# --- SCRAMBLING ---
elsif manipulation_type = 3
    for i to numFrames
        # Create shuffle array
        for k to max_number_of_formants
            perm[k] = k
        endfor
        
        # Standard Shuffle
        loop_count = max_number_of_formants - 1
        for step from 1 to loop_count
            k = max_number_of_formants - step + 1
            r = randomInteger(1, k)
            swap = perm[k]
            perm[k] = perm[r]
            perm[r] = swap
        endfor
        
        for f to max_number_of_formants
            src_f = perm[f]
            if src_f <= nF[i]
                hz = val_f[i, src_f]
                bw = val_b[i, src_f]
                if hz <> undefined
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], hz
                    Remove bandwidth points between: f, t[i]-0.0001, t[i]+0.0001
                    Add bandwidth point: f, t[i], bw
                endif
            endif
        endfor
    endfor

# --- SCALING ---
elsif manipulation_type = 4
    for i to numFrames
        for f to nF[i]
            hz = val_f[i,f]
            bw = val_b[i,f]
            if hz <> undefined
                new_hz = hz * formant_shift_ratio
                new_bw = bw * formant_stretch_ratio
                if new_hz < maximum_formant
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], new_hz
                    Remove bandwidth points between: f, t[i]-0.0001, t[i]+0.0001
                    Add bandwidth point: f, t[i], new_bw
                endif
            endif
        endfor
    endfor

# --- LFO ---
elsif manipulation_type = 5
    for i to numFrames
        lfo_val = sin(2 * pi * lFO_rate_Hz * t[i])
        mod_factor = 2^((lfo_val * lFO_depth_semitones) / 12)
        
        for f to nF[i]
            hz = val_f[i,f]
            if hz <> undefined
                new_hz = hz * mod_factor
                if new_hz < maximum_formant
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], new_hz
                endif
            endif
        endfor
    endfor

# --- CROSSFADE ---
elsif manipulation_type = 6
    for i to numFrames
        pos = (t[i] / dur) * crossfade_cycles
        fade = (sin(pos * 2 * pi) + 1) / 2
        for f to max_number_of_formants
            # [FIX] Check if formant 'f' exists in Start AND End frames
            # to prevent array out-of-bounds errors.
            if f <= nF[1] and f <= nF[numFrames]
                hz_start = val_f[1, f]
                hz_end = val_f[numFrames, f]
                
                if hz_start <> undefined and hz_end <> undefined
                    new_hz = hz_start * (1 - fade) + hz_end * fade
                    Remove formant points between: f, t[i]-0.0001, t[i]+0.0001
                    Add formant point: f, t[i], new_hz
                endif
            endif
        endfor
    endfor

# --- FREEZING ---
elsif manipulation_type = 7
    # Pre-calculate freeze masks
    curr_t = 0
    while curr_t < dur
        freeze_idx = round((curr_t / dur) * numFrames)
        if freeze_idx < 1 
            freeze_idx = 1 
        endif
        
        start_t = curr_t
        end_t = min(curr_t + freeze_duration, dur)
        
        start_frame = round((start_t / dur) * numFrames)
        end_frame = round((end_t / dur) * numFrames)
        
        if start_frame < 1
            start_frame = 1
        endif
        
        for k from start_frame to end_frame
            if k <= numFrames
                time_k = t[k]
                for f to max_number_of_formants
                     if f <= nF[freeze_idx]
                        hz_freeze = val_f[freeze_idx, f]
                        if hz_freeze <> undefined
                            Remove formant points between: f, time_k-0.0001, time_k+0.0001
                            Add formant point: f, time_k, hz_freeze
                        endif
                     endif
                endfor
            endif
        endfor
        curr_t = curr_t + freeze_interval
    endwhile
endif

# 4. SYNTHESIS (Source + New Filter)
appendInfoLine: "[4/4] Resynthesizing..."

selectObject: source
plusObject: fgrid
resynth = Filter
Rename: soundName$ + "_mod"

# Normalize
selectObject: sound
orig_int = Get intensity (dB)
selectObject: resynth
Scale intensity: orig_int

# Cleanup
removeObject: lpc, source, fpath, formant, fgrid

appendInfoLine: "Done."

if play_result
    selectObject: resynth
    Play
endif