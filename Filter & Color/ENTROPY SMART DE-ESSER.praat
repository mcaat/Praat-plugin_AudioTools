# ============================================================
# Praat AudioTools - ENTROPY SMART DE-ESSER.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   ENTROPY SMART DE-ESSER
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================
# ENTROPY SMART DE-ESSER 
# ============================================

form Entropy Smart De-Esser (Fast)
    comment === Analysis Parameters ===
    positive analysis_window_size 0.015
    positive smoothing 0.05
    
    comment === De-Esser Settings ===
    real entropy_threshold 0.6
    positive max_reduction_db 12.0
    
    comment === Output Mode ===
    boolean listen_to_removed_signal 0
endform

# ============================================
# INITIALIZATION
# ============================================

sound = selected("Sound")
sound_name$ = selected$("Sound")
total_duration = Get total duration
sr = Get sampling frequency
min_gain_linear = 10 ^ (-max_reduction_db / 20)

writeInfoLine: "=== Entropy Smart De-Esser (Fast) ==="
appendInfoLine: "Processing: ", sound_name$

# ============================================
# STEP 1: Fast Spectral Entropy (Matrix Method)
# ============================================
appendInfoLine: "Step 1: Computing entropy via Matrix..."

selectObject: sound
To Spectrogram: analysis_window_size, 5000, 0.005, 20, "Gaussian"
spec = selected("Spectrogram")

# --- FIX: Safe Time Calculation ---
# Instead of "Get x1", we use frame time queries which always work
x1 = Get time from frame number: 1
t2 = Get time from frame number: 2
dx = t2 - x1

# Convert to Matrix
To Matrix
Rename: "spec_matrix"
m_spec = selected("Matrix")
nrows = Get number of rows
ncols = Get number of columns

Create TableOfReal: "entropy_data", ncols, 2
table = selected("TableOfReal")

# --- Loop through Time (Columns) ---
noprogress selectObject: m_spec
max_entropy_const = ln(nrows) / ln(2)

for j from 1 to ncols
    # 1. Calculate Total Power for this time frame (Sum of column)
    col_sum = 0
    for i from 1 to nrows
        val = Get value in cell: i, j
        col_sum += val
    endfor

    # 2. Calculate Entropy for this time frame
    entropy = 0
    if col_sum > 0
        for i from 1 to nrows
            val = Get value in cell: i, j
            p = val / col_sum
            if p > 0
                entropy -= p * ln(p) / ln(2)
            endif
        endfor
        entropy = entropy / max_entropy_const
    endif

    # 3. Store in table
    time = x1 + (j - 1) * dx
    selectObject: table
    Set value: j, 1, time
    Set value: j, 2, entropy
    
    selectObject: m_spec
endfor

# ============================================
# STEP 2: Smoothing
# ============================================
selectObject: table
prev_val = Get value: 1, 2
for i from 2 to ncols
    curr_val = Get value: i, 2
    smoothed = smoothing * curr_val + (1 - smoothing) * prev_val
    Set value: i, 2, smoothed
    prev_val = smoothed
endfor

Create IntensityTier: "entropy_tier", 0, total_duration
entropy_tier = selected("IntensityTier")
for i from 1 to ncols
    selectObject: table
    time = Get value: i, 1
    value = Get value: i, 2
    selectObject: entropy_tier
    Add point: time, value
endfor

# ============================================
# STEP 3: Gain Curve Formula
# ============================================
appendInfoLine: "Step 2: Applying gain reduction..."

selectObject: entropy_tier
Copy: "gain_curve"
gain_tier = selected("IntensityTier")

formula$ = "if self < " + string$(entropy_threshold) + " then 1 else " + 
... "1 - ((self - " + string$(entropy_threshold) + ") / (1 - " + string$(entropy_threshold) + ")) * (1 - " + string$(min_gain_linear) + ") endif"

Formula: formula$

# ============================================
# STEP 4: Apply & Output
# ============================================
selectObject: sound
Copy: "buffer"
buffer = selected("Sound")

if listen_to_removed_signal = 0
    # Clean Audio
    Formula: "self * IntensityTier_gain_curve(x)"
    Rename: sound_name$ + "_DeEssed"
else
    # Noise Only
    Formula: "self * (1 - IntensityTier_gain_curve(x))"
    Rename: sound_name$ + "_RemovedNoise"
endif
Scale peak: 0.99
Play

# ============================================
# CLEANUP
# ============================================
removeObject: spec, m_spec, table, entropy_tier, gain_tier
selectObject: buffer

appendInfoLine: "✓ Done."