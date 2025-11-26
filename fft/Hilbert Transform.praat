# ============================================================
# Praat AudioTools - Hilbert Transform.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Fast Envelope Shaper (RMS Method)
# v2.0 - Added "Reverse Envelope" toggle
# Speedup: Uses "Square-and-Smooth" logic (No FFT)

form Fast Envelope Shaper
    comment === DIRECTION ===
    boolean Reverse_envelope 0
    comment (Checked = Swell/Ghost effect, Unchecked = Gate/Expander effect)
    
    comment === PERFORMANCE ===
    boolean Use_downsampling 1
    positive Processing_sample_rate 16000
    
    comment === ENVELOPE SHAPE ===
    positive Envelope_smoothness_Hz 25
    comment (Lower = smoother/slower, Higher = tighter/faster)
    
    comment === OUTPUT ===
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# 1. SETUP
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly ONE Sound object first."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
orig_sr = Get sampling frequency
n_channels = Get number of channels

# 2. CREATE WORKING COPY (Mono)
selectObject: orig_id
if n_channels > 1
    mono_id = Convert to mono
    work_id = mono_id
else
    work_id = Copy: "working_copy"
endif

# 3. DOWNSAMPLE (For calculation speed)
selectObject: work_id
current_sr = Get sampling frequency
did_downsample = 0

if use_downsampling and processing_sample_rate < current_sr
    downsampled_id = Resample: processing_sample_rate, 50
    removeObject: work_id
    work_id = downsampled_id
    did_downsample = 1
endif

# 4. FAST ENVELOPE EXTRACTION (RMS Method)
selectObject: work_id
env_id = Copy: "envelope"

# A. Rectify (Square)
Formula: "self * self"

# B. Smooth (Low Pass)
Filter (pass Hann band): 0, envelope_smoothness_Hz, 20
filtered_env_id = selected("Sound")
removeObject: env_id
env_id = filtered_env_id

# C. Linearize (Root)
Formula: "sqrt(abs(self))"

# 5. REVERSE LOGIC (User Option)
# We only reverse if the checkbox is ticked
if reverse_envelope
    Reverse
    suffix$ = "_RevEnv"
else
    suffix$ = "_Expander"
endif

# 6. APPLY TO ORIGINAL AUDIO
selectObject: orig_id
result_id = Copy: orig_name$ + suffix$

s_env$ = string$(env_id)

# Apply formula (Praat interpolates the low-res envelope automatically)
Formula: "self * object(" + s_env$ + ", x)"

# 7. FINALIZE
Scale peak: scale_peak

if play_after_processing
    Play
endif

# 8. CLEANUP
removeObject: env_id
if did_downsample
    removeObject: work_id
else
    if n_channels > 1
        removeObject: work_id
    else
        removeObject: work_id
    endif
endif

selectObject: result_id
