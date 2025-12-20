# ============================================================
# Praat AudioTools - Self-Similarity Matrix Calculator
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Self-Similarity Matrix Calculator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Self-Similarity Matrix (Turbo)
    comment === FEATURE CHOICE ===
    optionmenu feature_type: 3
        option Pitch only (fastest)
        option Pitch + Intensity
        option MFCC (best quality)
        option Spectral Entropy (texture-based)
        option LPC (vocal tract/formants)
        option Mel Features (perceptual spectrum)
    
    comment === PITCH SETTINGS (for options 1-2) ===
    positive pitch_floor 75
    positive pitch_ceiling 600
    
    comment === MFCC SETTINGS (for option 3) ===
    positive number_of_mfcc 12
    
    comment === ENTROPY SETTINGS (for option 4) ===
    positive freq_min_entropy 100
    positive freq_max_entropy 8000
    positive num_freq_bands 40
    
    comment === LPC SETTINGS (for option 5) ===
    positive lpc_order 16
    
    comment === MEL SETTINGS (for option 6) ===
    positive num_mel_bands 40
    positive freq_min_mel 100
    positive freq_max_mel 8000
    
    comment === GENERAL SETTINGS ===
    positive time_step 0.01
    positive window_length 0.025
    
    comment === SPEED OPTIMIZATION ===
    boolean use_mono_conversion 1
    boolean use_downsampling 1
    positive processing_sample_rate 22050
    positive frame_decimation 1
    
    comment === VISUALIZATION ===
    boolean draw_matrix 1
    boolean auto_contrast 1
endform

# ===================================================================
# SETUP
# ===================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object."
endif

originalID = selected("Sound")
originalName$ = selected$("Sound")
selectObject: originalID
original_duration = Get total duration
original_sr = Get sampling frequency
num_channels = Get number of channels

writeInfoLine: "=== SELF-SIMILARITY MATRIX (TURBO) ==="
appendInfoLine: "Sound: ", originalName$

if feature_type = 1
    feature_name$ = "Pitch"
elsif feature_type = 2
    feature_name$ = "Pitch+Intensity"
elsif feature_type = 3
    feature_name$ = "MFCC"
elsif feature_type = 4
    feature_name$ = "Spectral_Entropy"
elsif feature_type = 5
    feature_name$ = "LPC"
else
    feature_name$ = "Mel_Features"
endif

appendInfoLine: "Feature: ", feature_name$

# ===================================================================
# MONO CONVERSION (if stereo)
# ===================================================================

workingID = originalID
did_mono = 0

if use_mono_conversion and num_channels > 1
    selectObject: originalID
    monoID = Convert to mono
    workingID = monoID
    did_mono = 1
endif

# ===================================================================
# DOWNSAMPLE
# ===================================================================

did_downsample = 0

if use_downsampling and processing_sample_rate < original_sr
    selectObject: workingID
    downsampledID = Resample: processing_sample_rate, 50
    if did_mono
        removeObject: workingID
    endif
    workingID = downsampledID
    did_downsample = 1
endif

# ===================================================================
# EXTRACT FEATURES
# ===================================================================

selectObject: workingID

if feature_type = 1
    # --- PITCH ---
    To Pitch: time_step, pitch_floor, pitch_ceiling
    pitchID = selected("Pitch")
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = 1
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: pitchID
    out_f = 0
    for i to total_frames
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            val = Get value in frame: i, "Hertz"
            if val = undefined
                val = 0
            endif
            selectObject: featureMatrixID
            Set value: out_f, 1, val
            selectObject: pitchID
        endif
    endfor
    removeObject: pitchID

elsif feature_type = 2
    # --- PITCH + INTENSITY ---
    To Pitch: time_step, pitch_floor, pitch_ceiling
    pitchID = selected("Pitch")
    selectObject: workingID
    To Intensity: pitch_floor, time_step, "yes"
    intID = selected("Intensity")
    
    selectObject: pitchID
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = 2
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    out_f = 0
    for i to total_frames
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            selectObject: pitchID
            pval = Get value in frame: i, "Hertz"
            if pval = undefined
                pval = 0
            endif
            selectObject: intID
            ival = Get value in frame: i
            if ival = undefined
                ival = 0
            endif
            selectObject: featureMatrixID
            Set value: out_f, 1, pval
            Set value: out_f, 2, ival
        endif
    endfor
    removeObject: pitchID, intID

elsif feature_type = 3
    # --- MFCC ---
    To MFCC: number_of_mfcc, window_length, time_step, 100, 100, 0
    mfccID = selected("MFCC")
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = number_of_mfcc
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: mfccID
    out_f = 0
    for i to total_frames
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            for c to num_features
                val = Get value in frame: i, c
                selectObject: featureMatrixID
                Set value: out_f, c, val
                selectObject: mfccID
            endfor
        endif
    endfor
    removeObject: mfccID

elsif feature_type = 4
    # --- SPECTRAL ENTROPY (TURBO METHOD) ---
    To Spectrogram: window_length, 8000, time_step, 20, "Gaussian"
    specID = selected("Spectrogram")
    
    start_time = Get start time
    end_time = Get end time
    time_duration = end_time - start_time
    total_time_frames = floor(time_duration / time_step)
    
    num_frames = ceiling(total_time_frames / frame_decimation)
    num_features = 1
    
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    freq_step = (freq_max_entropy - freq_min_entropy) / num_freq_bands
    
    # Pre-calculate frequencies
    for b to num_freq_bands
        freq'b' = freq_min_entropy + (b-1)*freq_step
    endfor
    
    # TURBO: Minimal object switching
    selectObject: specID
    out_f = 0
    for i to total_time_frames
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            time = start_time + (i - 0.5) * time_step
            
            # Collect all power values for this frame
            tot_p = 0
            for b to num_freq_bands
                freq = freq'b'
                p = Get power at: time, freq
                if p < 0
                    p = 0
                endif
                power'b' = p
                if p > 0
                    tot_p = tot_p + p
                endif
            endfor
            
            # Calculate entropy
            entropy = 0
            if tot_p > 0
                for b to num_freq_bands
                    p = power'b'
                    if p > 0
                        prob = p / tot_p
                        entropy = entropy - (prob * ln(prob))
                    endif
                endfor
            endif
            
            # Switch to matrix once per frame
            selectObject: featureMatrixID
            Set value: out_f, 1, entropy
            selectObject: specID
        endif
    endfor
    removeObject: specID

elsif feature_type = 5
    # --- LPC ---
    To LPC (autocorrelation): lpc_order, window_length, time_step, 50
    lpcID = selected("LPC")
    Down to Matrix (lpc)
    matID = selected("Matrix")
    Transpose
    transID = selected("Matrix")
    
    num_rows = Get number of rows
    num_frames = ceiling(num_rows / frame_decimation)
    num_features = Get number of columns
    
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: transID
    out_f = 0
    for i to num_rows
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            for c to num_features
                val = Get value in cell: i, c
                selectObject: featureMatrixID
                Set value: out_f, c, val
                selectObject: transID
            endfor
        endif
    endfor
    removeObject: lpcID, matID, transID

else
    # --- MEL FEATURES (TURBO METHOD) ---
    To Spectrogram: window_length, 8000, time_step, 20, "Gaussian"
    specID = selected("Spectrogram")
    
    start_time = Get start time
    end_time = Get end time
    time_duration = end_time - start_time
    total_time_frames = floor(time_duration / time_step)
    
    num_frames = ceiling(total_time_frames / frame_decimation)
    num_features = num_mel_bands
    
    Create simple Matrix: "TheFeatureData", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    # Pre-calculate mel frequencies
    m_min = 2595 * log10(1 + freq_min_mel/700)
    m_max = 2595 * log10(1 + freq_max_mel/700)
    m_step = (m_max - m_min) / num_mel_bands
    for b to num_mel_bands
        m = m_min + (b-0.5)*m_step
        fc'b' = 700 * (10^(m/2595) - 1)
    endfor
    
    # TURBO: Minimal object switching
    selectObject: specID
    out_f = 0
    for i to total_time_frames
        if (i - 1) mod frame_decimation = 0
            out_f = out_f + 1
            time = start_time + (i - 0.5) * time_step
            
            # Collect all mel band powers for this frame
            for b to num_features
                freq = fc'b'
                p = Get power at: time, freq
                if p > 0
                    lp = 10 * log10(p) + 100
                    if lp < 0
                        lp = 0
                    endif
                else
                    lp = 0
                endif
                melpower'b' = lp
            endfor
            
            # Switch to matrix once per frame and write all values
            selectObject: featureMatrixID
            for b to num_features
                Set value: out_f, b, melpower'b'
            endfor
            selectObject: specID
        endif
    endfor
    removeObject: specID
endif

# ===================================================================
# NORMALIZE
# ===================================================================

selectObject: featureMatrixID
appendInfo: "Normalizing..."

if feature_type = 4
    # Min-Max Normalization for Entropy (1D)
    min_v = Get minimum
    max_v = Get maximum
    if max_v > min_v
        Formula: "(self - min_v) / (max_v - min_v)"
    endif
else
    # Unit Vector Normalization for others (Multidimensional)
    for r to num_frames
        sum_sq = 0
        for c to num_features
            val = Get value in cell: r, c
            sum_sq = sum_sq + val^2
        endfor
        if sum_sq > 0
            norm_factor = 1 / sqrt(sum_sq)
            for c to num_features
                val = Get value in cell: r, c
                Set value: r, c, val * norm_factor
            endfor
        endif
    endfor
endif
appendInfoLine: " done"

# ===================================================================
# COMPUTE SSM (USING FORMULA ONLY)
# ===================================================================

appendInfo: "Computing SSM (", num_frames, "x", num_frames, ")..."

Create simple Matrix: "SSM", num_frames, num_frames, "0"
ssmID = selected("Matrix")

if feature_type = 4 or feature_type = 1
    # For 1D data: Use Absolute Difference
    Formula: "1 - abs(Matrix_TheFeatureData[row, 1] - Matrix_TheFeatureData[col, 1])"
    
else
    # For Multidimensional data: Use Dot Product (Cosine Sim) via Formula
    formula_string$ = ""
    for c to num_features
        part$ = "Matrix_TheFeatureData[row, " + string$(c) + "] * Matrix_TheFeatureData[col, " + string$(c) + "]"
        if c = 1
            formula_string$ = part$
        else
            formula_string$ = formula_string$ + " + " + part$
        endif
    endfor
    
    Formula: formula_string$
endif

appendInfoLine: " done"

# ===================================================================
# POST-PROCESSING
# ===================================================================

if auto_contrast
    mean_val = Get mean: 0, 0, 0, 0
    if mean_val > 0.95
        pow = 20
    elsif mean_val > 0.90
        pow = 10
    elsif mean_val > 0.80
        pow = 5
    else
        pow = 3
    endif
    Formula: "self ^ " + string$(pow)
    
    min = Get minimum
    max = Get maximum
    if max > min
        Formula: "(self - min) / (max - min)"
    endif
endif

# ===================================================================
# DRAW
# ===================================================================

if draw_matrix
    Erase all
    Select outer viewport: 0, 6, 0, 6
    Paint cells: 0, 0, 0, 0, 0, 1
    Draw inner box
    Marks left every: 1, floor(num_frames/10), "yes", "yes", "no"
    Marks bottom every: 1, floor(num_frames/10), "yes", "yes", "no"
    Text top: "no", "SSM: " + originalName$ + " (" + feature_name$ + ")"
endif

# ===================================================================
# CLEANUP
# ===================================================================

selectObject: ssmID
Rename: originalName$ + "_SSM_" + feature_name$
removeObject: featureMatrixID

if did_mono and did_downsample
    removeObject: workingID
elsif did_mono
    removeObject: workingID
elsif did_downsample
    removeObject: workingID
endif

selectObject: ssmID