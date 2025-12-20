# ============================================================
# Praat AudioTools - Multi-Band Onset Detector.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Multi-Band Onset Detector
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Multi-Band Onset Detector

# ===== CONFIGURATION =====
form Multi-Band Onset Detector
    comment Detection parameters
    real Transient_threshold_(dB) -30
    real Attack_window_(ms) 20
    real Release_window_(ms) 50
    comment Frequency range
    real Low_frequency_(Hz) 100
    real High_frequency_(Hz) 8000
    integer Number_of_bands 4
    comment More bands = better resolution but slower (3-6 recommended)
    comment Performance
    real Working_sample_rate_(Hz) 8000
    comment Lower = faster (4000-16000)
    comment Output options
    boolean Create_transient_sound 1
    boolean Create_sustain_sound 1
    boolean Swap_outputs_for_speech 0
    comment (Enable for speech: vowels→sustain, consonants→transients)
    boolean Normalize_outputs 1
    real Peak_amplitude 0.99
endform

# ===== INITIAL CHECKS =====
numberOfSelectedSounds = numberOfSelected("Sound")
if numberOfSelectedSounds = 0
    exitScript: "Error: Please select a Sound object first"
endif

original_sound = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound
duration = Get total duration
original_sampleRate = Get sampling frequency
n_channels = Get number of channels

writeInfoLine: "=== Multi-Band Onset Detector ==="
appendInfoLine: "Input: ", original_name$
appendInfoLine: "Original: ", n_channels, " ch, ", original_sampleRate, " Hz"
appendInfoLine: ""

# ===== PREPROCESSING: MONO + DOWNSAMPLE =====
appendInfoLine: "Preprocessing..."

selectObject: original_sound

# Convert to mono if needed
if n_channels > 1
    appendInfoLine: "  Converting to mono..."
    mono_sound = Convert to mono
else
    mono_sound = original_sound
endif

# Downsample for speed
if working_sample_rate > 0 and working_sample_rate < original_sampleRate
    appendInfoLine: "  Downsampling to ", working_sample_rate, " Hz..."
    selectObject: mono_sound
    working_sound = Resample: working_sample_rate, 50
    sampleRate = working_sample_rate
    if mono_sound != original_sound
        removeObject: mono_sound
    endif
else
    working_sound = mono_sound
    sampleRate = original_sampleRate
endif

selectObject: working_sound
n_samples = Get number of samples
appendInfoLine: "  Working: ", sampleRate, " Hz, ", n_samples, " samples"

if swap_outputs_for_speech
    appendInfoLine: "  Mode: SPEECH (outputs swapped)"
else
    appendInfoLine: "  Mode: MUSIC (normal)"
endif
appendInfoLine: ""

# ===== STEP 1: MULTI-BAND FILTERING =====
appendInfoLine: "Step 1: Creating ", number_of_bands, "-band filterbank..."

# Logarithmic band spacing
for i from 0 to number_of_bands
    band_edge[i] = low_frequency * (high_frequency / low_frequency) ^ (i / number_of_bands)
endfor

# Create combined envelope initialized to zero
selectObject: working_sound
combined_envelope = Copy: "combined_env"
Formula: "0"

for i from 1 to number_of_bands
    appendInfoLine: "  Band ", i, "/", number_of_bands, ": ", fixed$(band_edge[i-1], 0), "-", fixed$(band_edge[i], 0), " Hz"
    
    # Filter
    selectObject: working_sound
    filtered = Filter (pass Hann band): band_edge[i-1], band_edge[i], 100
    
    # Rectify
    Formula: "abs(self)"
    
    # Smooth (envelope)
    smooth = Filter (pass Hann band): 0, 50, 20
    smooth_id = selected("Sound")
    
    # Add to combined envelope using explicit ID
    selectObject: combined_envelope
    combined_id = selected("Sound")
    Formula: "self + object[smooth_id]"
    
    removeObject: filtered, smooth
endfor

# ===== STEP 2: COMPUTE ONSET FUNCTION (DERIVATIVE) =====
appendInfoLine: ""
appendInfoLine: "Step 2: Computing onset function..."

selectObject: combined_envelope
onset_function = Copy: "onset_func"

# Differentiate using formula (much faster than loop!)
Formula: "if col > 1 then max(0, self - self[col-1]) else 0 endif"

max_onset = Get maximum: 0, 0, "None"
threshold_linear = 10^(transient_threshold / 20) * max_onset

appendInfoLine: "  Max onset: ", fixed$(max_onset, 6)
appendInfoLine: "  Threshold: ", fixed$(threshold_linear, 6)

# ===== STEP 3: CREATE TRANSIENT MASK =====
appendInfoLine: ""
appendInfoLine: "Step 3: Creating onset mask..."

selectObject: onset_function
transient_mask = Copy: "trans_mask"

# Simple threshold to binary mask
Formula: "if self > threshold_linear then 1 else 0 endif"

# Expand mask with attack/release windows
attack_samples = round((attack_window / 1000) * sampleRate)
release_samples = round((release_window / 1000) * sampleRate)

# Dilate mask (expand regions)
total_window = attack_samples + release_samples

if total_window > 0
    # Create smoothing window
    window_dur = total_window / sampleRate
    Create Sound from formula: "smooth_window", 1, 0, window_dur, sampleRate,
        ... "if x < attack_window/1000 then x/(attack_window/1000) else exp(-5*(x-attack_window/1000)/(release_window/1000)) endif"
    smooth_win = selected("Sound")
    
    # Convolve mask with window (dilates and shapes)
    selectObject: transient_mask, smooth_win
    convolved = Convolve: "sum", "zero"
    
    # Clip to 0-1 range
    Formula: "if self > 1 then 1 else if self < 0 then 0 else self endif endif"
    
    removeObject: transient_mask, smooth_win
    transient_mask = convolved
    Rename: "trans_mask"
endif

# ===== STEP 4: EXTRACT TRANSIENTS AND SUSTAIN =====
appendInfoLine: ""
appendInfoLine: "Step 4: Extracting components..."

mask_id = transient_mask

# Decide which output gets which based on swap setting
if swap_outputs_for_speech
    # For speech: swap so vowels→sustain, consonants→transients
    transient_formula$ = "self * (1 - object[mask_id])"
    sustain_formula$ = "self * object[mask_id]"
    transient_label$ = "_transients"
    sustain_label$ = "_sustain"
else
    # For music: normal (attacks→transients, body→sustain)
    transient_formula$ = "self * object[mask_id]"
    sustain_formula$ = "self * (1 - object[mask_id])"
    transient_label$ = "_transients"
    sustain_label$ = "_sustain"
endif

if create_transient_sound
    selectObject: working_sound
    transients_work = Copy: "trans_temp"
    Formula: transient_formula$
    
    # Resample back if needed
    if working_sound != mono_sound
        transients = Resample: original_sampleRate, 50
        removeObject: transients_work
    else
        transients = transients_work
    endif
    
    Rename: original_name$ + transient_label$
    
    if normalize_outputs
        Scale peak: peak_amplitude
    endif
    
    appendInfoLine: "  Created transients"
endif

if create_sustain_sound
    selectObject: working_sound
    sustain_work = Copy: "sust_temp"
    Formula: sustain_formula$
    
    # Resample back if needed
    if working_sound != mono_sound
        sustain = Resample: original_sampleRate, 50
        removeObject: sustain_work
    else
        sustain = sustain_work
    endif
    
    Rename: original_name$ + sustain_label$
    
    if normalize_outputs
        Scale peak: peak_amplitude
    endif
    
    appendInfoLine: "  Created sustain"
endif

# ===== CLEANUP =====
removeObject: combined_envelope, onset_function, transient_mask

if working_sound != original_sound
    if working_sound != mono_sound
        removeObject: working_sound
    endif
endif

# ===== SUMMARY =====
appendInfoLine: ""
appendInfoLine: "=== Complete ==="
appendInfoLine: ""

if swap_outputs_for_speech
    appendInfoLine: "SPEECH MODE (swapped outputs):"
    appendInfoLine: "  • Transients = consonants, bursts, fricatives"
    appendInfoLine: "  • Sustain = vowels, sustained harmonics"
else
    appendInfoLine: "MUSIC MODE (normal):"
    appendInfoLine: "  • Transients = attacks, onsets, percussive events"
    appendInfoLine: "  • Sustain = resonances, sustained tones"
endif

appendInfoLine: ""
appendInfoLine: "Method: Multi-band energy onset detection"
appendInfoLine: "  - Analyzes energy increases across frequency bands"
appendInfoLine: "  - Best for rhythmic/percussive material (music mode)"
appendInfoLine: "  - Use swap for speech/vocal analysis"
appendInfoLine: ""
appendInfoLine: "Compositional applications:"
appendInfoLine: "  - Gesture vs. texture separation (spectromorphology)"
appendInfoLine: "  - Isolate attacks from sustained material"
appendInfoLine: "  - Morphological analysis of sound events"

# Select outputs
if create_transient_sound and create_sustain_sound
    selectObject: transients, sustain
elsif create_transient_sound
    selectObject: transients
elsif create_sustain_sound
    selectObject: sustain
endif