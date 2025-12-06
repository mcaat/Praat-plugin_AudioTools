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

# ============================================================
# Self-Similarity Matrix - Multi-Feature (COMPLETE)
# ============================================================
# Compare audio across time using different features:
# - Pitch: melodic/harmonic similarity
# - Pitch+Intensity: dynamics + melody
# - MFCC: spectral timbre similarity (slow, best quality)
# - Spectral Entropy: texture/complexity similarity
# - LPC: vocal tract/formant similarity
# - Mel Features: perceptually-weighted spectrum
# ============================================================

form Self-Similarity Matrix
    comment === FEATURE CHOICE ===
    optionmenu feature_type: 1
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
    comment (Typical: 12-16 for speech, 10-12 for music)
    
    comment === MEL SETTINGS (for option 6) ===
    positive num_mel_bands 40
    positive freq_min_mel 100
    positive freq_max_mel 8000
    
    comment === GENERAL SETTINGS ===
    positive time_step 0.01
    positive window_length 0.025
    
    comment === SPEED OPTIMIZATION ===
    boolean use_downsampling 1
    positive processing_sample_rate 22050
    
    positive frame_decimation 1
    comment (1=all frames, 2=2x faster, 5=5x faster, 10=10x faster)
    
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

writeInfoLine: "=== SELF-SIMILARITY MATRIX ==="
appendInfoLine: "Sound: ", originalName$
appendInfoLine: "Duration: ", fixed$(original_duration, 2), " s"

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
appendInfoLine: ""

# ===================================================================
# DOWNSAMPLE
# ===================================================================

workingID = originalID
did_downsample = 0

if use_downsampling and processing_sample_rate < original_sr
    appendInfo: "Downsampling to ", processing_sample_rate, " Hz..."
    selectObject: originalID
    downsampledID = Resample: processing_sample_rate, 50
    workingID = downsampledID
    did_downsample = 1
    appendInfoLine: " done"
endif

# ===================================================================
# EXTRACT FEATURES
# ===================================================================

selectObject: workingID

if feature_type = 1
    # ===============================================================
    # PITCH ONLY
    # ===============================================================
    appendInfo: "Extracting pitch..."
    To Pitch: time_step, pitch_floor, pitch_ceiling
    pitchID = selected("Pitch")
    
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = 1
    
    Create simple Matrix: "features", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: pitchID
    output_frame = 0
    for frame to total_frames
        if (frame - 1) mod frame_decimation = 0
            output_frame = output_frame + 1
            
            pitch_val = Get value in frame: frame, "Hertz"
            if pitch_val = undefined
                pitch_val = 0
            endif
            
            selectObject: featureMatrixID
            Set value: output_frame, 1, pitch_val
            selectObject: pitchID
        endif
    endfor
    
    removeObject: pitchID
    appendInfoLine: " done (", num_frames, " frames)"
    
elsif feature_type = 2
    # ===============================================================
    # PITCH + INTENSITY
    # ===============================================================
    appendInfo: "Extracting pitch + intensity..."
    
    To Pitch: time_step, pitch_floor, pitch_ceiling
    pitchID = selected("Pitch")
    
    selectObject: workingID
    To Intensity: pitch_floor, time_step, "yes"
    intensityID = selected("Intensity")
    
    selectObject: pitchID
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = 2
    
    Create simple Matrix: "features", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    output_frame = 0
    for frame to total_frames
        if (frame - 1) mod frame_decimation = 0
            output_frame = output_frame + 1
            
            selectObject: pitchID
            pitch_val = Get value in frame: frame, "Hertz"
            if pitch_val = undefined
                pitch_val = 0
            endif
            
            selectObject: intensityID
            int_val = Get value in frame: frame
            if int_val = undefined
                int_val = 0
            endif
            
            selectObject: featureMatrixID
            Set value: output_frame, 1, pitch_val
            Set value: output_frame, 2, int_val
        endif
    endfor
    
    removeObject: pitchID, intensityID
    appendInfoLine: " done (", num_frames, " frames)"
    
elsif feature_type = 3
    # ===============================================================
    # MFCC
    # ===============================================================
    appendInfo: "Extracting MFCCs..."
    
    current_sr = Get sampling frequency
    nyquist = current_sr / 2
    
    To MFCC: number_of_mfcc, window_length, time_step, 100, 100, nyquist
    mfccID = selected("MFCC")
    
    total_frames = Get number of frames
    num_frames = ceiling(total_frames / frame_decimation)
    num_features = number_of_mfcc
    
    Create simple Matrix: "features", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: mfccID
    output_frame = 0
    for frame to total_frames
        if (frame - 1) mod frame_decimation = 0
            output_frame = output_frame + 1
            
            for coef to num_features
                value = Get value in frame: frame, coef
                
                selectObject: featureMatrixID
                Set value: output_frame, coef, value
                selectObject: mfccID
            endfor
        endif
        
        if frame mod 100 = 0
            appendInfo: "."
        endif
    endfor
    
    removeObject: mfccID
    appendInfoLine: " done (", num_frames, " frames)"
    
elsif feature_type = 4
    # ===============================================================
    # SPECTRAL ENTROPY
    # ===============================================================
    appendInfo: "Extracting spectral entropy..."
    
    current_sr = Get sampling frequency
    nyquist = current_sr / 2
    
    freq_min = freq_min_entropy
    freq_max = freq_max_entropy
    
    if freq_max > nyquist
        freq_max = nyquist
    endif
    
    To Spectrogram: window_length, nyquist, time_step, 20, "Gaussian"
    spectrogramID = selected("Spectrogram")
    
    start_time = Get start time
    end_time = Get end time
    time_duration = end_time - start_time
    
    total_time_frames = floor(time_duration / time_step) + 1
    num_frames = ceiling(total_time_frames / frame_decimation)
    num_features = 1
    
    freq_step = (freq_max - freq_min) / num_freq_bands
    
    Create simple Matrix: "features", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: spectrogramID
    
    output_frame = 0
    for t_idx to total_time_frames
        if (t_idx - 1) mod frame_decimation = 0
            output_frame = output_frame + 1
            
            time = start_time + (t_idx - 1) * time_step
            
            # Calculate total power
            total_power = 0
            
            for band to num_freq_bands
                freq = freq_min + (band - 1) * freq_step
                power = Get power at: time, freq
                
                if power > 0
                    total_power = total_power + power
                endif
            endfor
            
            # Calculate entropy
            entropy = 0
            
            if total_power > 0
                for band to num_freq_bands
                    freq = freq_min + (band - 1) * freq_step
                    power = Get power at: time, freq
                    
                    if power > 0
                        p = power / total_power
                        entropy = entropy - (p * ln(p))
                    endif
                endfor
            endif
            
            selectObject: featureMatrixID
            Set value: output_frame, 1, entropy
            
            selectObject: spectrogramID
        endif
        
        if t_idx mod 50 = 0
            appendInfo: "."
        endif
    endfor
    
    removeObject: spectrogramID
    appendInfoLine: " done (", num_frames, " frames)"
    
elsif feature_type = 5
    # ===============================================================
    # LPC (Linear Predictive Coding)
    # ===============================================================
    appendInfo: "Extracting LPC..."
    
    To LPC (autocorrelation): lpc_order, window_length, time_step, 50
    lpcID = selected("LPC")
    
    total_frames = Get number of frames
    
    # Convert to Matrix
    Down to Matrix (lpc)
    lpcMatrixTempID = selected("Matrix")
    
    # Check orientation
    num_rows = Get number of rows
    num_cols = Get number of columns
    
    if num_cols = lpc_order
        # Correct orientation
        num_frames_full = num_rows
        num_features = num_cols
        lpcMatrixID = lpcMatrixTempID
    else
        # Transpose
        Transpose
        lpcMatrixID = selected("Matrix")
        removeObject: lpcMatrixTempID
        
        num_frames_full = Get number of rows
        num_features = Get number of columns
    endif
    
    # Decimate if needed
    if frame_decimation > 1
        num_frames = ceiling(num_frames_full / frame_decimation)
        
        Create simple Matrix: "features", num_frames, num_features, "0"
        featureMatrixID = selected("Matrix")
        
        selectObject: lpcMatrixID
        output_frame = 0
        for frame to num_frames_full
            if (frame - 1) mod frame_decimation = 0
                output_frame = output_frame + 1
                
                for coef to num_features
                    value = Get value in cell: frame, coef
                    
                    selectObject: featureMatrixID
                    Set value: output_frame, coef, value
                    
                    selectObject: lpcMatrixID
                endfor
            endif
        endfor
        
        removeObject: lpcMatrixID
    else
        num_frames = num_frames_full
        featureMatrixID = lpcMatrixID
    endif
    
    removeObject: lpcID
    appendInfoLine: " done (", num_frames, " frames)"
    
else
    # ===============================================================
    # MEL-LIKE FEATURES
    # ===============================================================
    appendInfo: "Extracting mel features..."
    
    current_sr = Get sampling frequency
    nyquist = current_sr / 2
    
    freq_min = freq_min_mel
    freq_max = freq_max_mel
    
    if freq_max > nyquist
        freq_max = nyquist
    endif
    
    To Spectrogram: window_length, nyquist, time_step, 20, "Gaussian"
    spectrogramID = selected("Spectrogram")
    
    start_time = Get start time
    end_time = Get end time
    time_duration = end_time - start_time
    
    # Create mel-spaced frequency bands
    mel_min = 2595 * log10(1 + freq_min / 700)
    mel_max = 2595 * log10(1 + freq_max / 700)
    mel_step = (mel_max - mel_min) / num_mel_bands
    
    # Create center frequencies
    for i to num_mel_bands
        mel = mel_min + (i - 0.5) * mel_step
        freq_center'i' = 700 * (10^(mel / 2595) - 1)
    endfor
    
    total_time_frames = floor(time_duration / time_step) + 1
    num_frames = ceiling(total_time_frames / frame_decimation)
    num_features = num_mel_bands
    
    Create simple Matrix: "features", num_frames, num_features, "0"
    featureMatrixID = selected("Matrix")
    
    selectObject: spectrogramID
    
    output_frame = 0
    for t_idx to total_time_frames
        if (t_idx - 1) mod frame_decimation = 0
            output_frame = output_frame + 1
            
            time = start_time + (t_idx - 1) * time_step
            
            # Get energy in each mel band
            for band to num_mel_bands
                freq = freq_center'band'
                
                power = Get power at: time, freq
                
                # Log compression (dB-like)
                if power > 0
                    log_power = 10 * log10(power) + 100
                    
                    if log_power < 0
                        log_power = 0
                    endif
                else
                    log_power = 0
                endif
                
                selectObject: featureMatrixID
                Set value: output_frame, band, log_power
                
                selectObject: spectrogramID
            endfor
        endif
        
        if t_idx mod 50 = 0
            appendInfo: "."
        endif
    endfor
    
    removeObject: spectrogramID
    appendInfoLine: " done (", num_frames, " frames)"
endif

appendInfoLine: "Features: ", num_frames, " frames × ", num_features, " dimensions"
appendInfoLine: ""

# ===================================================================
# NORMALIZE FEATURES
# ===================================================================

appendInfo: "Normalizing..."
selectObject: featureMatrixID

if feature_type = 4
    # Entropy: normalize to 0-1 range
    min_val = Get minimum
    max_val = Get maximum
    
    if max_val > min_val
        Formula: "(self - min_val) / (max_val - min_val)"
    endif
else
    # Pitch/MFCC/LPC/Mel: normalize to unit length
    for i to num_frames
        row_sum_sq = 0
        for j to num_features
            val = Get value in cell: i, j
            row_sum_sq = row_sum_sq + (val * val)
        endfor
        
        if row_sum_sq > 0
            row_norm = sqrt(row_sum_sq)
            for j to num_features
                val = Get value in cell: i, j
                Set value: i, j, val / row_norm
            endfor
        endif
        
        if i mod 50 = 0
            appendInfo: "."
        endif
    endfor
endif

appendInfoLine: " done"

# ===================================================================
# COMPUTE SSM
# ===================================================================

appendInfo: "Computing SSM (", num_frames, "×", num_frames, ")..."

Create simple Matrix: "SSM_temp", num_frames, num_frames, "0"
ssmID = selected("Matrix")

for i to num_frames
    for j to i
        selectObject: featureMatrixID
        
        if feature_type = 4
            # Entropy: use inverse of absolute difference
            entropy_i = Get value in cell: i, 1
            entropy_j = Get value in cell: j, 1
            diff = abs(entropy_i - entropy_j)
            similarity = 1 - diff
        else
            # Pitch/MFCC/LPC/Mel: use cosine similarity (dot product)
            dot_product = 0
            for k to num_features
                val_i = Get value in cell: i, k
                val_j = Get value in cell: j, k
                dot_product = dot_product + (val_i * val_j)
            endfor
            similarity = dot_product
        endif
        
        selectObject: ssmID
        Set value: i, j, similarity
        Set value: j, i, similarity
    endfor
    
    if i mod 20 = 0
        appendInfo: "."
    endif
endfor

appendInfoLine: " done"

# ===================================================================
# AUTO CONTRAST
# ===================================================================

selectObject: ssmID
min_val = Get minimum
max_val = Get maximum
mean_val = Get mean: 0, 0, 0, 0

appendInfoLine: ""
appendInfoLine: "SSM stats: min=", fixed$(min_val, 3), " mean=", fixed$(mean_val, 3)

if auto_contrast
    if mean_val > 0.95
        contrast_enhancement = 20
    elsif mean_val > 0.90
        contrast_enhancement = 10
    elsif mean_val > 0.80
        contrast_enhancement = 5
    else
        contrast_enhancement = 3
    endif
else
    contrast_enhancement = 3
endif

appendInfoLine: "Contrast: ", fixed$(contrast_enhancement, 0), "x"

Formula: "self^contrast_enhancement"
new_min = Get minimum
new_max = Get maximum
Formula: "(self - new_min) / (new_max - new_min)"

appendInfoLine: ""

# ===================================================================
# VISUALIZE
# ===================================================================

if draw_matrix
    appendInfo: "Drawing..."
    
    Erase all
    Select outer viewport: 0, 6, 0, 6
    
    selectObject: ssmID
    Paint cells: 0, 0, 0, 0, 0, 1
    
    Colour: "Black"
    Draw inner box
    
    marks_interval = ceiling(num_frames / 10)
    if marks_interval < 1
        marks_interval = 1
    endif
    
    Marks left every: 1, marks_interval, "yes", "yes", "no"
    Marks bottom every: 1, marks_interval, "yes", "yes", "no"
    
    Text left: "yes", "Time (frame)"
    Text bottom: "yes", "Time (frame)"
    Text top: "no", "SSM: " + originalName$ + " (" + feature_name$ + ")"
    
    appendInfoLine: " done"
endif

# ===================================================================
# FINALIZE
# ===================================================================

selectObject: ssmID
Rename: originalName$ + "_SSM_" + feature_name$

removeObject: featureMatrixID

if did_downsample
    removeObject: downsampledID
endif

# ===================================================================
# REPORT
# ===================================================================

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
appendInfoLine: ""
appendInfoLine: "FEATURE INTERPRETATION:"

if feature_type = 1
    appendInfoLine: "Pitch: Melodic/harmonic repetition"
elsif feature_type = 2
    appendInfoLine: "Pitch+Intensity: Melody + dynamics"
elsif feature_type = 3
    appendInfoLine: "MFCC: Spectral timbre similarity (best quality)"
elsif feature_type = 4
    appendInfoLine: "Spectral Entropy: Texture complexity"
    appendInfoLine: "  High = noisy/complex, Low = tonal/simple"
elsif feature_type = 5
    appendInfoLine: "LPC: Vocal tract/formant structure"
    appendInfoLine: "  Captures resonances and spectral envelope"
else
    appendInfoLine: "Mel Features: Perceptually-weighted spectrum"
    appendInfoLine: "  Log-spaced frequencies matching human hearing"
    appendInfoLine: "  Similar to MFCC but faster (no DCT)"
endif

appendInfoLine: ""
appendInfoLine: "SSM PATTERNS:"
appendInfoLine: "• Bright diagonal = self-similarity"
appendInfoLine: "• Off-diagonal blocks = repeated sections"
appendInfoLine: "• Parallel diagonals = periodic patterns"
appendInfoLine: "• Checkerboard = alternating structure"
appendInfoLine: ""
appendInfoLine: "SPEED TIPS:"
appendInfoLine: "• frame_decimation=2 → 2x faster"
appendInfoLine: "• frame_decimation=5 → 5x faster"
appendInfoLine: "• frame_decimation=10 → 10x faster"
appendInfoLine: "• use_downsampling → 4x faster"
appendInfoLine: "• Combine both for 20-40x speedup!"
appendInfoLine: ""
appendInfoLine: "Matrix: ", originalName$ + "_SSM_" + feature_name$

selectObject: ssmID