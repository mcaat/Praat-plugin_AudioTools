# ============================================================
# Praat AudioTools - ENTROPY-MODULATED DYNAMIC REVERB.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   ENTROPY-MODULATED DYNAMIC REVERB
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
# ENTROPY-MODULATED DYNAMIC REVERB 
# ============================================

form Entropy-Modulated Reverb
    comment === Analysis Parameters ===
    positive analysis_window_size 0.025
    positive hop_size 0.025
    positive smoothing_alpha 0.15
    
    comment === Reverb Parameters ===
    positive reverb_time_dark 2.5
    positive reverb_time_bright 1.0
    positive damping_dark 0.8
    positive damping_bright 0.3
    
    comment === Mix Parameters ===
    positive min_wet_amount 0.1
    positive max_wet_amount 0.9
    boolean invert_mapping 0
endform

# ============================================
# INITIALIZATION
# ============================================

sound = selected("Sound")
sound_name$ = selected$("Sound")
total_duration = Get total duration
sr = Get sampling frequency

writeInfoLine: "=== Entropy-Modulated Reverb (Fixed) ==="
appendInfoLine: "Processing: ", sound_name$

# ============================================
# STEP 1: Fast Spectral Entropy (Direct FFT)
# ============================================
appendInfoLine: "Step 1/4: Computing spectral entropy..."

selectObject: sound
To Spectrogram: analysis_window_size, 5000, hop_size, 20, "Gaussian"
spec = selected("Spectrogram")

num_frames = Get number of frames
Create TableOfReal: "entropy_raw", num_frames, 2
table_raw = selected("TableOfReal")

# Using 'noprogress' speeds up loops slightly by not updating UI
noprogress selectObject: spec
for iframe from 1 to num_frames
    selectObject: spec
    time = Get time from frame number: iframe
    
    To Spectrum (slice): time
    spectrum = selected("Spectrum")
    
    num_bins = Get number of bins
    total_power = 0
    
    # First pass: total power
    # (Note: For pure speed, we could assume power from Spectrogram, 
    # but calculating here ensures rigorous entropy normalization)
    for ibin from 1 to num_bins
        re = Get real value in bin: ibin
        im = Get imaginary value in bin: ibin
        power = re * re + im * im
        total_power += power
    endfor
    
    # Second pass: entropy
    entropy = 0
    if total_power > 0
        for ibin from 1 to num_bins
            re = Get real value in bin: ibin
            im = Get imaginary value in bin: ibin
            power = re * re + im * im
            p = power / total_power
            if p > 0.0000001
                entropy -= p * ln(p) / ln(2)
            endif
        endfor
        max_entropy = ln(num_bins) / ln(2)
        entropy = entropy / max_entropy
    endif
    
    selectObject: table_raw
    Set value: iframe, 1, time
    Set value: iframe, 2, entropy
    
    removeObject: spectrum
endfor

# ============================================
# STEP 2: Causal Low-Pass Filter + IntensityTier
# ============================================
appendInfoLine: "Step 2/4: Smoothing..."

selectObject: table_raw

# Exponential smoothing
prev_val = Get value: 1, 2
for i from 2 to num_frames
    curr_val = Get value: i, 2
    smoothed = smoothing_alpha * curr_val + (1 - smoothing_alpha) * prev_val
    Set value: i, 2, smoothed
    prev_val = smoothed
endfor

# Convert to IntensityTier with UNIQUE name for Formula reference later
Create IntensityTier: "entropy_control", 0, total_duration
entropy_tier = selected("IntensityTier")

for i from 1 to num_frames
    selectObject: table_raw
    time = Get value: i, 1
    value = Get value: i, 2
    selectObject: entropy_tier
    Add point: time, value
endfor

# ============================================
# STEP 3: Create Reverb Impulses & Convolve
# ============================================
appendInfoLine: "Step 3/4: Creating reverb..."

# Create Impulses
Create Sound from formula: "ir_dark", 1, 0, reverb_time_dark, sr,
    ... "randomGauss(0,1) * exp(-x*5/reverb_time_dark) * exp(-x*damping_dark*10/reverb_time_dark)"
ir_dark = selected("Sound")

Create Sound from formula: "ir_bright", 1, 0, reverb_time_bright, sr,
    ... "randomGauss(0,1) * exp(-x*8/reverb_time_bright) * exp(-x*damping_bright*3/reverb_time_bright)"
ir_bright = selected("Sound")

# Convolve (Whole file - prevents tail artifacts)
selectObject: sound, ir_dark
Convolve: "sum", "zero"
reverb_dark = selected("Sound")
Scale peak: 0.99

selectObject: sound, ir_bright
Convolve: "sum", "zero"
reverb_bright = selected("Sound")
Scale peak: 0.99

# ============================================
# STEP 4: FAST Matrix Mixing (No Loops!)
# ============================================
appendInfoLine: "Step 4/4: Fast matrix mixing..."

# 1. Create entropy control signal purely via Formula (Instant)
selectObject: reverb_dark
max_dur = Get total duration

Create Sound from formula: "entropy_sound", 1, 0, max_dur, sr,
    ... "IntensityTier_entropy_control(x)"
entropy_sound = selected("Sound")

# 2. Pad/Trim all signals to exact same length (max_dur)
selectObject: sound
Extract part: 0, max_dur, "rectangular", 1, "no"
sound_ext = selected("Sound")

selectObject: reverb_bright
Extract part: 0, max_dur, "rectangular", 1, "no"
bright_ext = selected("Sound")

# 3. Convert to Matrices with short, unique names
selectObject: sound_ext
Down to Matrix
Rename: "dry"
m_dry = selected("Matrix")

selectObject: reverb_dark
Down to Matrix
Rename: "dark"
m_dark = selected("Matrix")

selectObject: bright_ext
Down to Matrix
Rename: "bright"
m_bright = selected("Matrix")

selectObject: entropy_sound
Down to Matrix
Rename: "ent"
m_ent = selected("Matrix")

# 4. Create Wet/Mix Matrix
selectObject: m_ent
Copy: "wet"
m_wet = selected("Matrix")

# Apply Wet/Dry mapping
if invert_mapping = 0
    Formula: "min_wet_amount + (1 - self) * (max_wet_amount - min_wet_amount)"
else
    Formula: "min_wet_amount + self * (max_wet_amount - min_wet_amount)"
endif

# 5. Final Mix Formula
selectObject: m_dry
Copy: "output"
m_out = selected("Matrix")

# Mix logic: Dry*(1-Wet) + (Dark*(1-Ent) + Bright*Ent)*Wet
Formula: "Matrix_dry[]*(1-Matrix_wet[]) + (Matrix_dark[]*(1-Matrix_ent[]) + Matrix_bright[]*Matrix_ent[])*Matrix_wet[]"

To Sound
output = selected("Sound")
Scale peak: 0.98
Rename: sound_name$ + "_entropyReverb"

# ============================================
# CLEANUP
# ============================================

removeObject: spec, table_raw, entropy_tier
removeObject: ir_dark, ir_bright, reverb_dark, reverb_bright
removeObject: sound_ext, bright_ext, entropy_sound
removeObject: m_dry, m_dark, m_bright, m_ent, m_wet, m_out

selectObject: output
appendInfoLine: ""
appendInfoLine: "✓ COMPLETE: ", sound_name$ + "_entropyReverb"
Play