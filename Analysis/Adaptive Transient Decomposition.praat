# ============================================================
# Praat AudioTools - Adaptive Transient Decomposition.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Adaptive Transient Decomposition
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================
# ATOMIC Adaptive Transients
# ============================================

form "Atomic Transients (Sigmoid Padded)"
    comment "Analysis"
    positive lpcOrder_ms      1.6
    positive integration_ms   5.0  
    comment "Detection"
    real     threshold_ratio  2.0
    positive burstPadding_ms  2.0
endform

# ---- Setup ----
if numberOfSelected ("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

clearinfo
writeInfoLine: "Starting Atomic Processing (v16)..."

origId = selected ("Sound")
origName$ = selected$ ("Sound")
nch = Get number of channels

# ---- Parameter Logic ----
env_rate = 1000 / integration_ms
floor_rate = 5
if burstPadding_ms > 0
    pad_rate = 1000 / burstPadding_ms
else
    pad_rate = 1000
endif

# ---- Stereo Logic ----
if nch = 1
    @processChannel: origId, ""
    
elsif nch = 2
    writeInfoLine: "Splitting Stereo..."
    selectObject: origId
    Extract all channels
    ch1 = selected("Sound", 1)
    ch2 = selected("Sound", 2)
    
    @processChannel: ch1, "_L"
    idTransL = selected("Sound", 1)
    idResL   = selected("Sound", 2)
    
    @processChannel: ch2, "_R"
    idTransR = selected("Sound", 1)
    idResR   = selected("Sound", 2)
    
    # Merge
    selectObject: idTransL
    plusObject: idTransR
    Combine to stereo
    Rename: origName$ + "_transients"
    finalTrans = selected("Sound")
    
    selectObject: idResL
    plusObject: idResR
    Combine to stereo
    Rename: origName$ + "_residual"
    finalRes = selected("Sound")
    
    # Cleanup
    selectObject: ch1
    plusObject: ch2
    plusObject: idTransL
    plusObject: idTransR
    plusObject: idResL
    plusObject: idResR
    Remove
    
    selectObject: origId
    plusObject: finalTrans
    plusObject: finalRes
endif

appendInfoLine: "Done."

# ============================================
# PROCEDURE: Vectorized Processing
# ============================================
procedure processChannel: .srcId, .suffix$
    selectObject: .srcId
    .totalDur = Get total duration
    .sr = Get sampling frequency
    
    # 1. PADDING (Prevents Edge Errors)
    # ----------------------------------
    .silence = Create Sound from formula: "silence", 1, 0, 0.5, .sr, "0"
    selectObject: .srcId
    plusObject: .silence
    .temp1 = Concatenate
    plusObject: .silence
    .padded = Concatenate
    Rename: "padded_src"
    removeObject: .silence
    removeObject: .temp1
    
    # 2. LPC Residual
    # ----------------------------------
    selectObject: .padded
    .ord = round(.sr/1000 * lpcOrder_ms)
    .lpc = To LPC (burg): .ord, 0.025, 0.005, 50
    plusObject: .padded
    .resid = Filter (inverse)
    Rename: "resid_calc"
    
    # 3. Fast Envelope (Container Method)
    # ----------------------------------
    selectObject: .resid
    .sq = Copy: "squared"
    Formula: "self * self"
    
    .lowEnv = Resample: env_rate, 50
    Rename: "low_env"
    
    # Create Container
    selectObject: .resid
    .env = Copy: "envelope"
    Formula: "Sound_low_env[]"
    Formula: "sqrt(self)"
    
    removeObject: .sq
    removeObject: .lowEnv
    
    # 4. Noise Floor
    # ----------------------------------
    selectObject: .env
    .lowFloor = Resample: floor_rate, 50
    Rename: "low_floor"
    
    selectObject: .resid
    .floor = Copy: "floor"
    Formula: "Sound_low_floor[]"
    
    removeObject: .lowFloor
    
    # 5. SOFT GATE (Sigmoid Math)
    # ----------------------------------
    # No "if/then", no ">". Just pure math.
    # Formula: 1 / (1 + exp( -Steepness * (Signal - Threshold) ))
    
    selectObject: .env
    .gate = Copy: "gate_raw"
    
    # Logic: Difference = Env - (Floor * Ratio)
    # If Diff > 0, we want 1. If Diff < 0, we want 0.
    Formula: "self - (Sound_floor[] * threshold_ratio)"
    
    # Apply Sigmoid (Steepness 50 is sharp enough)
    Formula: "1 / (1 + exp(-50 * self))"
    
    # 6. Dilate/Pad
    # ----------------------------------
    if burstPadding_ms > 0
        selectObject: .gate
        .lowGate = Resample: pad_rate, 50
        Rename: "low_gate"
        
        selectObject: .resid
        .gatePad = Copy: "gate_final"
        
        # Fill
        Formula: "Sound_low_gate[]"
        
        # Re-sharpen the smoothed gate using Sigmoid
        # Center the sigmoid at 0.01 (anything > 0.01 becomes 1)
        Formula: "self - 0.01"
        Formula: "1 / (1 + exp(-50 * self))"
        
        removeObject: .lowGate
        removeObject: .gate
        .gate = .gatePad
    else
        selectObject: .gate
        Rename: "gate_final"
    endif

    # 7. Apply Gate
    # ----------------------------------
    selectObject: .resid
    .transPadded = Copy: "trans_padded"
    # Pure math multiplication
    Formula: "self * Sound_gate_final[]"
    
    # 8. CROP BACK TO ORIGINAL
    # ----------------------------------
    # We added 0.5s at start.
    selectObject: .transPadded
    .trans = Extract part: 0.5, 0.5 + .totalDur, "rectangular", 1, "no"
    Rename: "transients" + .suffix$
    
    # 9. Residual
    # ----------------------------------
    selectObject: .trans
    Rename: "temp_trans"
    
    selectObject: .srcId
    .finalResid = Copy: "residual" + .suffix$
    Formula: "self - Sound_temp_trans[]"
    
    selectObject: .trans
    Rename: "transients" + .suffix$
    
    # 10. Cleanup
    selectObject: .padded
    plusObject: .lpc
    plusObject: .resid
    plusObject: .env
    plusObject: .floor
    plusObject: .gate
    plusObject: .transPadded
    Remove
    
    selectObject: .trans
    plusObject: .finalResid
endproc
