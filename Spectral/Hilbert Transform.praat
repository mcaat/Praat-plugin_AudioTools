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

form Hilbert Time-Reversed Envelope (Optimized)
    comment This script extracts envelope and applies it backwards in time
    comment === OPTIMIZATION SETTINGS ===
    boolean use_downsampling 1
    comment (Uncheck to preserve original sample rate)
    positive processing_sample_rate 32000
    comment (32000 Hz = good balance of speed/quality)
    comment Note: Stereo files are automatically converted to mono
    comment Note: This algorithm requires processing the entire file at once
    comment === SPECTRUM PARAMETERS ===
    boolean fast_fourier no
    comment (use "no" for Hilbert transform)
    comment === ENVELOPE PROCESSING ===
    boolean apply_envelope_sharpening 0
    positive sharpening_exponent 0.8
    comment (< 1 = sharper envelope, > 1 = smoother envelope)
    comment === HIGH-PASS FILTER PARAMETERS ===
    positive highpass_cutoff 50
    positive highpass_smoothing 10
    comment (reduces low-frequency dominance)
    comment === OUTPUT OPTIONS ===
    positive scale_peak 0.99
    boolean play_after_processing 1
    boolean show_info_report 1
    boolean keep_intermediate_objects 0
endform

# Check selection
if numberOfSelected ("Sound") <> 1
    exit Please select exactly ONE Sound object first.
endif

# Get original info
originalID = selected ("Sound")
sound$ = selected$ ("Sound")
original_sr = Get sampling frequency
original_duration = Get total duration
num_channels = Get number of channels

if show_info_report
    writeInfoLine: "=== HILBERT TRANSFORM OPTIMIZATION ==="
    appendInfoLine: "Original duration: ", original_duration, " seconds"
    appendInfoLine: "Original rate: ", original_sr, " Hz"
    appendInfoLine: "Channels: ", num_channels
endif

# STEP 1: Convert to mono (always, since algorithm works on mono)
workingID = originalID
converted_to_mono = 0
if num_channels > 1
    selectObject: originalID
    monoID = Convert to mono
    workingID = monoID
    converted_to_mono = 1
    if show_info_report
        appendInfoLine: "✓ Converted to mono (required for Hilbert transform)"
    endif
endif

# STEP 2: Downsample if requested
selectObject: workingID
current_sr = Get sampling frequency
did_downsample = 0

if use_downsampling and processing_sample_rate < current_sr
    downsampledID = Resample: processing_sample_rate, 50
    workingID = downsampledID
    did_downsample = 1
    if show_info_report
        appendInfoLine: "✓ Downsampled to ", processing_sample_rate, " Hz"
    endif
else
    processing_sample_rate = current_sr
    if show_info_report
        if use_downsampling
            appendInfoLine: "→ Downsampling skipped (target rate >= original)"
        else
            appendInfoLine: "→ Using original sample rate (no downsampling)"
        endif
    endif
endif

# Get working sound name
selectObject: workingID
working_sound$ = selected$ ("Sound")

if show_info_report
    appendInfoLine: "→ Processing: ", working_sound$
endif

# STEP 3: Convert to spectrum
selectObject: workingID
spectrum = To Spectrum: fast_fourier
Rename: "original_spectrum"

# STEP 4: Create Hilbert transform (90-degree phase shift)
hilbert_spectrum = Copy: "hilbert_spectrum"
Formula: "if row = 1 then Spectrum_original_spectrum[2, col] else -Spectrum_original_spectrum[1, col] fi"

# STEP 5: Convert back to time domain
hilbert_sound = To Sound
Rename: "hilbert_sound"

# STEP 6: Calculate envelope from analytic signal
selectObject: workingID
env_sound = Copy: "envelope_temp"
Formula: "sqrt(self ^ 2 + Sound_hilbert_sound[] ^ 2)"
Rename: working_sound$ + "_envelope"

# STEP 7: Scale the envelope
Scale peak: scale_peak

# STEP 8: Optional envelope sharpening
if apply_envelope_sharpening
    exponent_str$ = string$(sharpening_exponent)
    Formula: "self ^ " + exponent_str$
endif

# STEP 9: High-pass filter to reduce low-frequency dominance
Filter (pass Hann band): highpass_cutoff, 0, highpass_smoothing

# STEP 10: Create time-reversed version of original sound
selectObject: workingID
reverse_sound = Copy: working_sound$ + "_reversed"
Formula: "self[ncol - col + 1]"

# STEP 11: Apply envelope backwards in time
selectObject: reverse_sound
reversed_with_env = Copy: working_sound$ + "_reversed_with_env"
envelope_name$ = working_sound$ + "_envelope"
Formula: "self * Sound_" + envelope_name$ + "[col]"

# STEP 12: Reverse back to normal time
selectObject: reversed_with_env
final_sound = Copy: working_sound$ + "_time_reverse_env"
Formula: "self[ncol - col + 1]"

# STEP 13: Resample back if needed
selectObject: final_sound
if did_downsample
    if show_info_report
        appendInfo: "✓ Resampling to original ", original_sr, " Hz..."
    endif
    resampledID = Resample: original_sr, 50
    removeObject: final_sound
    final_sound = resampledID
    if show_info_report
        appendInfoLine: " done"
    endif
endif

# STEP 14: Final scaling and rename
selectObject: final_sound
Rename: sound$ + "_time_reverse_env"
Scale peak: scale_peak

# Show info report if requested
if show_info_report
    appendInfoLine: "✓ Time-reverse envelope processing complete!"
    appendInfoLine: "✓ Output: ", sound$, "_time_reverse_env"
    appendInfoLine: "=== COMPLETE ==="
endif

# Play if requested
if play_after_processing
    selectObject: final_sound
    Play
endif

# Cleanup intermediate objects unless requested to keep
if not keep_intermediate_objects
    selectObject: spectrum, hilbert_spectrum, hilbert_sound
    plusObject: reverse_sound, reversed_with_env, env_sound
    Remove
    if converted_to_mono
        removeObject: monoID
    endif
    if did_downsample
        removeObject: downsampledID
    endif
endif

# Select the final result
selectObject: final_sound
