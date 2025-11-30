# ============================================================
# Praat AudioTools - Frequency Shifter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Frequency Shifter
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Frequency Shifter (v7.1 - Safe & Presets)
# A professional Bode-style Frequency Shifter with Presets.
# Handles long files via chunking and uses fast Matrix math.

form Frequency Shifter (Presets)
    comment Preset Selection:
    optionmenu Preset 1
        option Custom
        option Subtle Detune (Thicken)
        option Metallic Ring (Dissonant)
        option Horror Radio (Alien)
        option Deep Sub (Heavy Downshift)
        option High Bell (Sparkle)
    
    comment --- Custom Parameters ---
    integer Frequency_shift_hz 200
    comment (Positive = Up, Negative = Down)
    
    comment --- Optimization ---
    positive Chunk_size_seconds 3.0
    positive Overlap_seconds 0.1
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_result 1
    
    comment --- Safety ---
    boolean Keep_original 1
endform

# --- 1. APPLY PRESETS ---
if preset = 2
    # Subtle Detune (Chorus-like thickening)
    frequency_shift_hz = 15
elsif preset = 3
    # Metallic Ring (Classic Inharmonic)
    frequency_shift_hz = 250
elsif preset = 4
    # Horror Radio (Speech becomes unintelligible)
    frequency_shift_hz = 666
elsif preset = 5
    # Deep Sub (Adds weight)
    frequency_shift_hz = -100
elsif preset = 6
    # High Bell (Glassy texture)
    frequency_shift_hz = 1200
endif

# --- 2. SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
original_name$ = selected$("Sound")
original_sr = Get sampling frequency
total_dur = Get total duration

# We determine the preset name for the file output
if preset = 1
    preset_name$ = "Custom"
elsif preset = 2
    preset_name$ = "Detune"
elsif preset = 3
    preset_name$ = "Metallic"
elsif preset = 4
    preset_name$ = "Alien"
elsif preset = 5
    preset_name$ = "Sub"
elsif preset = 6
    preset_name$ = "Bell"
endif

writeInfoLine: "Frequency Shifter (v7.1)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Shift: ", frequency_shift_hz, " Hz"

# --- 3. PREPARE CHUNK LOOP ---
# Split file into overlapping blocks to handle long files safely
num_chunks = floor(total_dur / chunk_size_seconds) + 1
current_time = 0

appendInfoLine: "Processing ", num_chunks, " chunks..."

for i from 1 to num_chunks
    selectObject: sound
    
    # Calculate timings
    start_t = current_time
    end_t = current_time + chunk_size_seconds + overlap_seconds
    
    # Check bounds
    if end_t > total_dur
        end_t = total_dur
    endif
    
    # A. EXTRACT CHUNK
    chunk = Extract part: start_t, end_t, "rectangular", 1, "no"
    chunk_name$ = "Chunk_" + string$(i)
    Rename: chunk_name$
    
    # B. PROCESS CHUNK (Matrix Shift)
    # 1. To Spectrum (Fast FFT)
    spectrum = To Spectrum: "yes"
    
    # 2. Calculate Bins
    bin_width = Get bin width
    shift_bins = round(frequency_shift_hz / bin_width)
    shift_str$ = fixed$(shift_bins, 0)
    
    # 3. To Matrix
    mat_src = To Matrix
    
    # 4. Create Target Matrix
    mat_tgt = Copy: "TargetMat"
    Formula: "0"
    
    # 5. Shift Formula
    # Target[col] = Source[col - shift]
    selectObject: mat_tgt
    Formula: "if (col - " + shift_str$ + ") >= 1 and (col - " + shift_str$ + ") <= ncol then Matrix_" + chunk_name$ + "[row, col - " + shift_str$ + "] else 0 fi"
    
    # 6. Convert Back
    # Matrix -> Spectrum -> Sound
    spec_out = To Spectrum
    sound_tmp = To Sound
    
    # 7. Fix Pitch (Restore Sample Rate)
    # Matrix conversion resets Hz to defaults. We override it to original.
    Override sampling frequency: original_sr
    
    # 8. Trim to exact length (remove FFT padding)
    exact_len = end_t - start_t
    Extract part: 0, exact_len, "rectangular", 1, "no"
    processed_chunk = selected("Sound")
    Rename: "Proc_" + string$(i)
    
    # Store ID
    chunks[i] = processed_chunk
    
    # Cleanup loop objects
    removeObject: chunk, spectrum, mat_src, mat_tgt, spec_out, sound_tmp
    
    # Advance time
    current_time = current_time + chunk_size_seconds
endfor

# --- 4. RECONSTRUCT ---
appendInfoLine: "Merging..."

selectObject: chunks[1]
for i from 2 to num_chunks
    plusObject: chunks[i]
endfor

# Simple Concatenation works best for frequency shifting
Concatenate
result_id = selected("Sound")
Rename: original_name$ + "_FreqShift_" + preset_name$
Scale peak: scale_peak

# --- 5. CLEANUP ---
for i from 1 to num_chunks
    removeObject: chunks[i]
endfor

# Only remove original if explicitly requested
if keep_original = 0
    selectObject: sound
    Remove
endif

appendInfoLine: "Done!"

if play_result
    selectObject: result_id
    Play
endif