# ============================================================
# Praat AudioTools - NMF Spectral Resynthesizer 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   NMF Spectral Resynthesizer 
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ENGINE: Dual-Mode NMF + Pitch-Locked Resynthesis.
# PRESETS: Smooth Gliss, Clicks, Micro-Texture.
# CONTROL: Manual mode is default.

form "NMF Spectral Resynthesizer"
    optionmenu preset 1
        option Manual (Use Settings Below)
        option Smooth Gliss
        option Clicks
        option Texture
    
    comment "--- MANUAL SETTINGS ---"
    positive window_ms 10
    positive step_ms 4.0
    
    comment "--- SMOOTHING ---"
    positive trans_decay 0.6
    integer texture_blur_passes 4
    
    comment "--- PITCH TRACKING ---"
    positive min_pitch 75
    positive max_pitch 600
    positive pitch_smoothing_hz 10
    
    comment "--- ENGINE ---"
    natural max_freq_hz 4000
    integer n_components 4
    integer n_iterations 8
endform

# ---- PRESET LOGIC ----
if preset$ = "Smooth Gliss"
    window_ms = 2.0
    step_ms = 50.0
    trans_decay = 0.9
    texture_blur_passes = 1
    
elsif preset$ = "Clicks"
    window_ms = 60.0
    step_ms = 15.0
    trans_decay = 0.4
    texture_blur_passes = 5

elsif preset$ = "Texture"
    window_ms = 1.0
    step_ms = 2.0
    trans_decay = 0.5
    texture_blur_passes = 2
endif

# ---- Setup ----
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

clearinfo
# --- DIAGNOSTIC READOUT ---
writeInfoLine: "--- NMF SPECTRAL RESYNTHESIZER ---"
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Window: ", window_ms, " ms"
appendInfoLine: "Step:   ", step_ms, " ms"
appendInfoLine: "Decay:  ", trans_decay
appendInfoLine: "Blur:   ", texture_blur_passes
appendInfoLine: "----------------------------------"

id_original = selected("Sound")
name_original$ = selected$("Sound")
sampling_rate = Get sampling frequency

# ============================================
# 1. SPECTROGRAM & INIT
# ============================================
selectObject: id_original
spectrogram = To Spectrogram: window_ms/1000, max_freq_hz, step_ms/1000, 20, "Gaussian"
selectObject: spectrogram
matV = To Matrix
Rename: "NMF_V"
Formula: "self + 1e-9"
nRows = Get number of rows
nCols = Get number of columns

matW = Create simple Matrix: "NMF_W", nRows, n_components, "randomUniform(0.1, 1)"
matH = Create simple Matrix: "NMF_H", n_components, nCols, "randomUniform(0.1, 1)"

# ============================================
# 2. NMF LOOP
# ============================================
appendInfoLine: "Decomposing..."

for iter from 1 to n_iterations
    if iter mod 2 = 0
        appendInfo: "."
    endif

    # --- UPDATE H ---
    matNum = Create simple Matrix: "Num", n_components, nCols, "0"
    for k from 1 to nRows
        k_str$ = fixed$(k, 0)
        selectObject: matNum
        Formula: "self + Matrix_NMF_W[" + k_str$ + ", row] * Matrix_NMF_V[" + k_str$ + ", col]"
    endfor
    
    matWtW = Create simple Matrix: "WtW", n_components, n_components, "0"
    for k from 1 to nRows
        k_str$ = fixed$(k, 0)
        selectObject: matWtW
        Formula: "self + Matrix_NMF_W[" + k_str$ + ", row] * Matrix_NMF_W[" + k_str$ + ", col]"
    endfor
    
    matDenom = Create simple Matrix: "Denom", n_components, nCols, "0"
    for k from 1 to n_components
        k_str$ = fixed$(k, 0)
        selectObject: matDenom
        Formula: "self + Matrix_WtW[row, " + k_str$ + "] * Matrix_NMF_H[" + k_str$ + ", col]"
    endfor
    
    selectObject: matH
    Formula: "self * Matrix_Num[row,col] / (Matrix_Denom[row,col] + 1e-9)"
    removeObject: matNum, matWtW, matDenom

    # --- UPDATE W ---
    matNum = Create simple Matrix: "Num", nRows, n_components, "0"
    for k from 1 to nCols
        k_str$ = fixed$(k, 0)
        selectObject: matNum
        Formula: "self + Matrix_NMF_V[row, " + k_str$ + "] * Matrix_NMF_H[col, " + k_str$ + "]"
    endfor
    
    matHHt = Create simple Matrix: "HHt", n_components, n_components, "0"
    for k from 1 to nCols
        k_str$ = fixed$(k, 0)
        selectObject: matHHt
        Formula: "self + Matrix_NMF_H[row, " + k_str$ + "] * Matrix_NMF_H[col, " + k_str$ + "]"
    endfor
    
    matDenom = Create simple Matrix: "Denom", nRows, n_components, "0"
    for k from 1 to n_components
        k_str$ = fixed$(k, 0)
        selectObject: matDenom
        Formula: "self + Matrix_NMF_W[row, " + k_str$ + "] * Matrix_HHt[" + k_str$ + ", col]"
    endfor
    
    selectObject: matW
    Formula: "self * Matrix_Num[row,col] / (Matrix_Denom[row,col] + 1e-9)"
    removeObject: matNum, matHHt, matDenom
endfor

# ============================================
# 3. DUAL-MODE SMOOTHING
# ============================================
selectObject: matH
if trans_decay > 0
    Formula: "if row <= 2 and col > 1 then (self * (1-trans_decay)) + (self[row, col-1] * trans_decay) else self fi"
endif
for i from 1 to texture_blur_passes
    Formula: "if row > 2 and col > 1 and col < ncol then (self[row, col-1]*0.25 + self*0.5 + self[row, col+1]*0.25) else self fi"
endfor

# ============================================
# 4. RECONSTRUCT & RESYNTHESIS
# ============================================
selectObject: matV
matRecon = Copy: "V_Recon"
Formula: "0"
for k from 1 to n_components
    k_str$ = fixed$(k, 0)
    selectObject: matRecon
    Formula: "self + Matrix_NMF_W[row, " + k_str$ + "] * Matrix_NMF_H[" + k_str$ + ", col]"
endfor

specRecon = To Spectrogram
selectObject: specRecon
soundRecon = To Sound: sampling_rate
Rename: "NMF_Raw_Output"

# --- PITCH LOCKING ---
appendInfoLine: "Locking Pitch..."

# A. Extract
selectObject: id_original
pitchOrig = To Pitch: 0.0, min_pitch, max_pitch
pitchSmooth = Smooth: pitch_smoothing_hz
pitchTier = Down to PitchTier

# B. Transplant
selectObject: soundRecon
manipulation = To Manipulation: 0.01, min_pitch, max_pitch
selectObject: manipulation
plusObject: pitchTier
Replace pitch tier

# C. Synthesize
selectObject: manipulation
soundFinal = Get resynthesis (overlap-add)
Rename: name_original$ + "_NMF_" + preset$
Scale peak: 0.99

# Cleanup
removeObject: spectrogram, matV, matW, matH, matRecon, specRecon
removeObject: pitchOrig, pitchSmooth, pitchTier, manipulation, soundRecon

selectObject: id_original
plusObject: soundFinal
appendInfoLine: "DONE."

selectObject: soundFinal
Play