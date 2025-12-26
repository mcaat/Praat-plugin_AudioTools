# ============================================================
# Praat AudioTools - NMF Spectral Resynthesizer 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025) - Optimized + Stereo
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   NMF Spectral Resynthesizer
#   Optimizations:
#   - Reusable temporary matrices (reduced object churn)
#   - Complete presets with all parameters
#   - Stereo support (shared W, independent H)
#   - Fast preview mode
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ENGINE: Dual-Mode NMF + Pitch-Locked Resynthesis.
# PRESETS: Fast Preview, Smooth Gliss, Clicks, Micro-Texture, High Definition.
# CONTROL: Manual mode uses settings below.

form NMF Spectral Resynthesizer
    optionmenu Preset 1
        option Manual (Use Settings Below)
        option Fast Preview
        option Smooth Gliss
        option Clicks
        option Texture
        option High Definition
    
    comment === Analysis Window ===
    positive Window_ms 10
    positive Step_ms 4.0
    
    comment === Smoothing ===
    positive Trans_decay 0.6
    integer Texture_blur_passes 4
    
    comment === Pitch Tracking ===
    positive Min_pitch 75
    positive Max_pitch 600
    positive Pitch_smoothing_hz 10
    
    comment === NMF Engine ===
    natural Max_freq_hz 4000
    integer N_components 4
    integer N_iterations 8
    
    comment === Output ===
    boolean Stereo_output 1
    boolean Play_output 1
endform

# ============================================
# PRESET LOGIC (Complete parameter sets)
# ============================================

if preset$ = "Fast Preview"
    # Quick preview - low quality but fast
    window_ms = 15
    step_ms = 8.0
    trans_decay = 0.5
    texture_blur_passes = 2
    max_freq_hz = 3000
    n_components = 2
    n_iterations = 4
    
elsif preset$ = "Smooth Gliss"
    # Long windows, high smoothing for glissando effects
    window_ms = 2.0
    step_ms = 50.0
    trans_decay = 0.9
    texture_blur_passes = 1
    max_freq_hz = 4000
    n_components = 3
    n_iterations = 10
    
elsif preset$ = "Clicks"
    # Short transients, percussive textures
    window_ms = 60.0
    step_ms = 15.0
    trans_decay = 0.4
    texture_blur_passes = 5
    max_freq_hz = 5000
    n_components = 5
    n_iterations = 8

elsif preset$ = "Texture"
    # Micro-granular, dense evolving textures
    window_ms = 1.0
    step_ms = 2.0
    trans_decay = 0.5
    texture_blur_passes = 2
    max_freq_hz = 4000
    n_components = 4
    n_iterations = 8
    
elsif preset$ = "High Definition"
    # Maximum quality, slow processing
    window_ms = 8
    step_ms = 3.0
    trans_decay = 0.6
    texture_blur_passes = 3
    max_freq_hz = 6000
    n_components = 6
    n_iterations = 15
endif

# ============================================
# SETUP & VALIDATION
# ============================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

clearinfo
writeInfoLine: "=== NMF SPECTRAL RESYNTHESIZER (Optimized) ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Window: ", window_ms, " ms | Step: ", step_ms, " ms"
appendInfoLine: "Components: ", n_components, " | Iterations: ", n_iterations
appendInfoLine: "Decay: ", trans_decay, " | Blur passes: ", texture_blur_passes
if stereo_output
    appendInfoLine: "Output: Stereo (shared W, independent H)"
else
    appendInfoLine: "Output: Mono"
endif
appendInfoLine: "=============================================="
appendInfoLine: ""

id_original = selected("Sound")
name_original$ = selected$("Sound")
selectObject: id_original
sampling_rate = Get sampling frequency
duration = Get total duration
original_channels = Get number of channels

# Convert to mono for analysis
if original_channels > 1
    id_mono = Convert to mono
    Rename: name_original$ + "_mono"
else
    id_mono = Copy: name_original$ + "_mono"
endif

# ============================================
# 1. SPECTROGRAM & INIT
# ============================================

appendInfoLine: "Creating spectrogram..."

selectObject: id_mono
spectrogram = To Spectrogram: window_ms/1000, max_freq_hz, step_ms/1000, 20, "Gaussian"
selectObject: spectrogram
matV = To Matrix
Rename: "NMF_V"
Formula: "self + 1e-9"
nRows = Get number of rows
nCols = Get number of columns

appendInfoLine: "  Matrix size: ", nRows, " x ", nCols

# Initialize W and H matrices
matW = Create simple Matrix: "NMF_W", nRows, n_components, "randomUniform(0.1, 1)"
matH = Create simple Matrix: "NMF_H", n_components, nCols, "randomUniform(0.1, 1)"

# ============================================
# 2. PRE-ALLOCATE TEMPORARY MATRICES (OPTIMIZATION)
# ============================================

# These are reused every iteration instead of create/delete
matNum_H = Create simple Matrix: "Num_H", n_components, nCols, "0"
matWtW = Create simple Matrix: "WtW", n_components, n_components, "0"
matDenom_H = Create simple Matrix: "Denom_H", n_components, nCols, "0"

matNum_W = Create simple Matrix: "Num_W", nRows, n_components, "0"
matHHt = Create simple Matrix: "HHt", n_components, n_components, "0"
matDenom_W = Create simple Matrix: "Denom_W", nRows, n_components, "0"

# ============================================
# 3. NMF LOOP (Optimized with reusable matrices)
# ============================================

appendInfoLine: "Decomposing (", n_iterations, " iterations)..."

for iter from 1 to n_iterations
    appendInfo: "."
    
    # --- UPDATE H ---
    # Compute Num_H = W' * V
    selectObject: matNum_H
    Formula: "0"
    for k from 1 to nRows
        k_str$ = fixed$(k, 0)
        selectObject: matNum_H
        Formula: "self + Matrix_NMF_W[" + k_str$ + ", row] * Matrix_NMF_V[" + k_str$ + ", col]"
    endfor
    
    # Compute WtW = W' * W
    selectObject: matWtW
    Formula: "0"
    for k from 1 to nRows
        k_str$ = fixed$(k, 0)
        selectObject: matWtW
        Formula: "self + Matrix_NMF_W[" + k_str$ + ", row] * Matrix_NMF_W[" + k_str$ + ", col]"
    endfor
    
    # Compute Denom_H = WtW * H
    selectObject: matDenom_H
    Formula: "0"
    for k from 1 to n_components
        k_str$ = fixed$(k, 0)
        selectObject: matDenom_H
        Formula: "self + Matrix_WtW[row, " + k_str$ + "] * Matrix_NMF_H[" + k_str$ + ", col]"
    endfor
    
    # Update H
    selectObject: matH
    Formula: "self * Matrix_Num_H[row,col] / (Matrix_Denom_H[row,col] + 1e-9)"

    # --- UPDATE W ---
    # Compute Num_W = V * H'
    selectObject: matNum_W
    Formula: "0"
    for k from 1 to nCols
        k_str$ = fixed$(k, 0)
        selectObject: matNum_W
        Formula: "self + Matrix_NMF_V[row, " + k_str$ + "] * Matrix_NMF_H[col, " + k_str$ + "]"
    endfor
    
    # Compute HHt = H * H'
    selectObject: matHHt
    Formula: "0"
    for k from 1 to nCols
        k_str$ = fixed$(k, 0)
        selectObject: matHHt
        Formula: "self + Matrix_NMF_H[row, " + k_str$ + "] * Matrix_NMF_H[col, " + k_str$ + "]"
    endfor
    
    # Compute Denom_W = W * HHt
    selectObject: matDenom_W
    Formula: "0"
    for k from 1 to n_components
        k_str$ = fixed$(k, 0)
        selectObject: matDenom_W
        Formula: "self + Matrix_NMF_W[row, " + k_str$ + "] * Matrix_HHt[" + k_str$ + ", col]"
    endfor
    
    # Update W
    selectObject: matW
    Formula: "self * Matrix_Num_W[row,col] / (Matrix_Denom_W[row,col] + 1e-9)"
endfor

appendInfoLine: " done"

# Clean up temp matrices
removeObject: matNum_H, matWtW, matDenom_H, matNum_W, matHHt, matDenom_W

# ============================================
# 4. DUAL-MODE SMOOTHING
# ============================================

appendInfoLine: "Applying smoothing..."

selectObject: matH

# Transient smoothing for low components (1-2)
if trans_decay > 0
    Formula: "if row <= 2 and col > 1 then (self * (1-trans_decay)) + (self[row, col-1] * trans_decay) else self fi"
endif

# Texture blur for higher components (3+)
for i from 1 to texture_blur_passes
    Formula: "if row > 2 and col > 1 and col < ncol then (self[row, col-1]*0.25 + self*0.5 + self[row, col+1]*0.25) else self fi"
endfor

# ============================================
# 5. RECONSTRUCT SPECTROGRAM
# ============================================

appendInfoLine: "Reconstructing spectrogram..."

selectObject: matV
matRecon = Copy: "V_Recon"
Formula: "0"

# Reconstruct: V_recon = W * H
for k from 1 to n_components
    k_str$ = fixed$(k, 0)
    selectObject: matRecon
    Formula: "self + Matrix_NMF_W[row, " + k_str$ + "] * Matrix_NMF_H[" + k_str$ + ", col]"
endfor

# ============================================
# 6. RESYNTHESIS (with stereo support)
# ============================================

if stereo_output
    n_passes = 2
else
    n_passes = 1
endif

# Extract original pitch for locking
appendInfoLine: "Extracting pitch contour..."
selectObject: id_mono
pitchOrig = To Pitch: 0.0, min_pitch, max_pitch
pitchSmooth = Smooth: pitch_smoothing_hz
pitchTier = Down to PitchTier
removeObject: pitchOrig, pitchSmooth

for pass from 1 to n_passes
    if stereo_output
        if pass = 1
            appendInfoLine: "Synthesizing LEFT channel..."
        else
            appendInfoLine: "Synthesizing RIGHT channel..."
            
            # For right channel, re-randomize H slightly for variation
            selectObject: matH
            Formula: "self * randomUniform(0.85, 1.15)"
            
            # Re-apply smoothing
            if trans_decay > 0
                Formula: "if row <= 2 and col > 1 then (self * (1-trans_decay)) + (self[row, col-1] * trans_decay) else self fi"
            endif
            for i from 1 to texture_blur_passes
                Formula: "if row > 2 and col > 1 and col < ncol then (self[row, col-1]*0.25 + self*0.5 + self[row, col+1]*0.25) else self fi"
            endfor
            
            # Reconstruct with varied H
            selectObject: matRecon
            Formula: "0"
            for k from 1 to n_components
                k_str$ = fixed$(k, 0)
                selectObject: matRecon
                Formula: "self + Matrix_NMF_W[row, " + k_str$ + "] * Matrix_NMF_H[" + k_str$ + ", col]"
            endfor
        endif
    else
        appendInfoLine: "Synthesizing..."
    endif
    
    # Convert matrix to spectrogram then to sound
    selectObject: matRecon
    specRecon = To Spectrogram
    selectObject: specRecon
    soundRecon = To Sound: sampling_rate
    Rename: "NMF_Raw_" + string$(pass)
    
    # Pitch locking
    selectObject: soundRecon
    manipulation = To Manipulation: 0.01, min_pitch, max_pitch
    selectObject: manipulation
    plusObject: pitchTier
    Replace pitch tier
    
    selectObject: manipulation
    soundPitched = Get resynthesis (overlap-add)
    
    removeObject: manipulation, soundRecon, specRecon
    
    # Store channel
    if pass = 1
        channel_left = soundPitched
        selectObject: channel_left
        Rename: "Channel_Left"
    else
        channel_right = soundPitched
        selectObject: channel_right
        Rename: "Channel_Right"
    endif
endfor

removeObject: pitchTier

# ============================================
# 7. COMBINE STEREO / FINALIZE
# ============================================

if stereo_output
    appendInfoLine: "Combining to stereo..."
    
    # Match durations
    selectObject: channel_left
    dur_left = Get total duration
    
    selectObject: channel_right
    dur_right = Get total duration
    
    if dur_left < dur_right
        selectObject: channel_right
        channel_right_trim = Extract part: 0, dur_left, "rectangular", 1.0, "no"
        removeObject: channel_right
        channel_right = channel_right_trim
    elsif dur_right < dur_left
        selectObject: channel_left
        channel_left_trim = Extract part: 0, dur_right, "rectangular", 1.0, "no"
        removeObject: channel_left
        channel_left = channel_left_trim
    endif
    
    selectObject: channel_left, channel_right
    soundFinal = Combine to stereo
    Rename: name_original$ + "_NMF_" + preset$ + "_stereo"
    
    removeObject: channel_left, channel_right
else
    soundFinal = channel_left
    Rename: name_original$ + "_NMF_" + preset$
endif

selectObject: soundFinal
Scale peak: 0.99

# ============================================
# 8. CLEANUP
# ============================================

removeObject: spectrogram, matV, matW, matH, matRecon, id_mono

selectObject: id_original
plusObject: soundFinal

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
selectObject: soundFinal
n_ch = Get number of channels
dur = Get total duration
appendInfoLine: "Output: ", selected$("Sound")
appendInfoLine: "Duration: ", fixed$(dur, 3), " s"
appendInfoLine: "Channels: ", n_ch

if play_output
    appendInfoLine: "Playing..."
    selectObject: soundFinal
    Play
endif

selectObject: soundFinal