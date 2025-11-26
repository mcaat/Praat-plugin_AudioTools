# ============================================================
# Praat AudioTools - Paulstretch.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Paulstretch
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Fast Paulstretch algorithm for Praat 

form Paulstretch parameters
    comment Select a Sound object first, then run this script
    positive stretch_factor 4.0
    positive window_size 0.25
    positive overlap_percent 50
endform

# Check if a Sound is selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

# Get the input sound
original_sound = selected("Sound")
selectObject: original_sound
sound_name$ = selected$("Sound")
fs = Get sampling frequency
duration = Get total duration
n_channels = Get number of channels

# Convert to mono if needed
if n_channels > 1
    sound = Convert to mono
else
    sound = original_sound
endif

selectObject: sound

# Calculate parameters
window_samples = round(window_size * fs)
if window_samples mod 2 = 1
    window_samples += 1
endif

overlap_fraction = overlap_percent / 100
hop_out = window_size * (1 - overlap_fraction)
hop_in = hop_out / stretch_factor
output_duration = duration * stretch_factor

# Calculate number of frames
n_frames = ceiling(output_duration / hop_out) + 1

writeInfoLine: "Paulstretch Processing (Fast Mode)"
appendInfoLine: "Input duration: ", fixed$(duration, 3), " s"
appendInfoLine: "Output duration: ", fixed$(output_duration, 3), " s"
appendInfoLine: "Number of frames: ", n_frames

# Create empty output sound
output_sound = Create Sound from formula: "temp_output", 1, 0, output_duration + window_size, fs, "0"

# Progress reporting
progress_interval = max(1, round(n_frames / 20))

# Process each frame
for iframe from 0 to n_frames - 1
    if iframe mod progress_interval = 0
        percent = iframe / n_frames * 100
        appendInfoLine: "Progress: ", fixed$(percent, 1), "%"
    endif
    
    # Input center time
    t_in = iframe * hop_in
    t_start = t_in - window_size / 2
    t_end = t_in + window_size / 2
    
    # 1. EXTRACT FRAME
    selectObject: sound
    extract_start = max(0, t_start)
    extract_end = min(duration, t_end)
    
    # Only process if we have a valid time range
    if extract_end > extract_start
        frame = Extract part: extract_start, extract_end, "rectangular", 1.0, "no"
        
        # 2. PAD FRAME
        selectObject: frame
        dur_frame = Get total duration
        
        if abs(dur_frame - window_size) > 0.00001
            padded = Create Sound from formula: "padded", 1, 0, window_size, fs, "0"
            
            offset = 0
            if t_start < 0
                offset = abs(t_start)
            endif
            
            s_offset$ = fixed$(offset, 6)
            s_end$ = fixed$(offset+dur_frame, 6)
            frame_id = frame
            
            selectObject: padded
            Formula: "if x >= " + s_offset$ + " and x <= " + s_end$ + " then self + object(" + string$(frame_id) + ", x - " + s_offset$ + ") else self fi"
            
            removeObject: frame
            frame = padded
        endif

        # 3. APPLY WINDOW 
        selectObject: frame
        Multiply by window: "Hanning"

        # 4. FAST PHASE RANDOMIZATION
        selectObject: frame
        spectrum = To Spectrum: "yes"
        selectObject: spectrum
        mat_complex = To Matrix
        
        # Clone Matrix for Phases (Robust dimension handling)
        selectObject: mat_complex
        mat_phase = Copy: "phase_matrix"
        Formula: "randomUniform(-pi, pi)"
        
        # Apply Phases
        selectObject: mat_complex
        phase_id = mat_phase
        
        # Use object[id, row, col] syntax
        Formula: "if (col=1 or col=ncol) then self else (if row=1 then sqrt(self[1,col]^2 + self[2,col]^2) * cos(object[" + string$(phase_id) + ",1,col]) else sqrt(self[1,col]^2 + self[2,col]^2) * sin(object[" + string$(phase_id) + ",1,col]) fi) fi"

        # Convert back
        selectObject: mat_complex
        spectrum_mod = To Spectrum
        selectObject: spectrum_mod
        processed_sound = To Sound
        
        # 5. APPLY WINDOW AGAIN
        selectObject: processed_sound
        Multiply by window: "Hanning"
        
        # 6. FAST OVERLAP-ADD (Universal Method)
        t_out = iframe * hop_out
        Shift times to: "start time", t_out
        
        selectObject: output_sound
        t_add_end = t_out + window_size
        
        # Prepare string variables for the formula
        # This prevents the formula parser from getting confused by variable names
        proc_id = processed_sound
        s_t_out$ = fixed$(t_out, 6)
        s_t_end$ = fixed$(t_add_end, 6)
        
        # The Universal Fast Method:
        # We use a standard Formula with a conditional check.
        # This adds the processed frame to the output ONLY within the relevant time window.
        Formula: "if x >= " + s_t_out$ + " and x <= " + s_t_end$ + " then self + object(" + string$(proc_id) + ", x) else self fi"
        
        # Cleanup
        removeObject: frame, spectrum, mat_complex, mat_phase, spectrum_mod, processed_sound
    endif
endfor

# Finalize
selectObject: output_sound
Rename: sound_name$ + "_paulstretch_fast_" + string$(stretch_factor) + "x"
Scale peak: 0.99
Play

if n_channels > 1
    removeObject: sound
endif

appendInfoLine: "Done!"