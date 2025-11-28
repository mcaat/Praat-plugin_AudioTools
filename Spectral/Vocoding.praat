# ============================================================
# Praat AudioTools - Vocoding.praat
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

# Poly-Carrier Vocoder (v4.0 - Speed Optimized)
# Optimization: Downsampling reduces Filter Bank load by ~70%.
# Feature: Extracts Pitch from original source for accuracy, processes at low rate for speed.

form Poly-Carrier Vocoder (Fast)
    comment --- Performance ---
    choice processing_quality 2
        button Hi-Fi (Original Rate - Slow)
        button Vintage (16000 Hz - Fast)
        button Lo-Fi (8000 Hz - Super Fast)

    comment --- Vocoder Style ---
    optionmenu carrier_type: 2
        option 1. Noise (Whisper)
        option 2. Robot Drone (Sawtooth)
        option 3. Pitch-Tracking (Pulse)
    
    positive robot_pitch_hz 100
    
    comment --- Bands ---
    natural number_of_bands 20
    positive lower_freq_limit 50
    positive upper_freq_limit 7500
    
    comment --- Envelope ---
    positive envelope_smoothness_hz 100
    
    comment --- Output ---
    boolean play_after 1
endform

# --- SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
orig_sr = Get sampling frequency
n_channels = Get number of channels

# --- 1. PRE-CALCULATE PITCH (If needed) ---
# We do this BEFORE downsampling to get the most accurate pitch detection
if carrier_type = 3
    selectObject: orig_id
    # Pitch detection needs mono
    if n_channels > 1
        tmp_mono = Convert to mono
        selectObject: tmp_mono
    endif
    
    pitch_id = To Pitch: 0.0, 75, 600
    pp_id = To PointProcess
    
    if n_channels > 1
        removeObject: tmp_mono
    endif
endif

# --- 2. PREPARE INPUT & DOWNSAMPLE ---
selectObject: orig_id
if n_channels > 1
    input_id = Convert to mono
else
    input_id = Copy: "input"
endif

# Apply Optimization
target_sr = orig_sr
if processing_quality = 2
    target_sr = 16000
elsif processing_quality = 3
    target_sr = 8000
endif

if target_sr < orig_sr
    resampled_id = Resample: target_sr, 50
    removeObject: input_id
    input_id = resampled_id
endif

# Update working variables
selectObject: input_id
work_sr = Get sampling frequency
dur = Get total duration

# Output Buffer
output_id = Create Sound from formula: "Vocoder_Out", 1, 0, dur, work_sr, "0"

# --- 3. GENERATE CARRIER (At Working Rate) ---
if carrier_type = 1
    # NOISE
    Create Sound from formula: "Carrier", 1, 0, dur, work_sr, "randomGauss(0, 0.2)"
    carrier_id = selected("Sound")

elsif carrier_type = 2
    # ROBOT SAWTOOTH
    s_pitch$ = string$(robot_pitch_hz)
    Create Sound from formula: "Carrier", 1, 0, dur, work_sr, "0.2 * 2 * (x * " + s_pitch$ + " - floor(0.5 + x * " + s_pitch$ + "))"
    carrier_id = selected("Sound")

elsif carrier_type = 3
    # PITCH PULSE
    selectObject: pp_id
    # We generate the sound using the Pulse object we created earlier
    # but specifically at the NEW working sample rate
    To Sound (pulse train): work_sr, 1, 0.05, 2000
    Scale peak: 0.2
    Rename: "Carrier"
    carrier_id = selected("Sound")
    removeObject: pitch_id, pp_id
endif

# --- BARK SCALE CALCS ---
b_low = hertzToBark(lower_freq_limit)
b_high = hertzToBark(upper_freq_limit)
step = (b_high - b_low) / number_of_bands
filter_smoothing_hz = 50

writeInfoLine: "Vocoder Running at ", work_sr, " Hz..."

# --- 4. MAIN BAND LOOP ---
for i from 1 to number_of_bands
    # Frequency Calcs
    b_upper = b_low + i * step
    b_lower = b_upper - step
    f_low = barkToHertz(b_lower)
    f_high = barkToHertz(b_upper)
    
    # A. SOURCE (Modulator)
    selectObject: input_id
    src_band_id = Filter (pass Hann band): f_low, f_high, filter_smoothing_hz
    
    # B. ENVELOPE (Fast RMS)
    Formula: "self * self"
    # Smoothing filter
    Filter (pass Hann band): 0, envelope_smoothness_hz, 20
    env_id = selected("Sound")
    removeObject: src_band_id
    # Linearize
    Formula: "sqrt(abs(self))"
    
    # C. CARRIER
    selectObject: carrier_id
    carrier_band_id = Filter (pass Hann band): f_low, f_high, filter_smoothing_hz
    
    # D. MIX
    selectObject: output_id
    s_env$ = string$(env_id)
    s_carrier$ = string$(carrier_band_id)
    Formula: "self + object(" + s_carrier$ + ", x) * object(" + s_env$ + ", x)"
    
    # Cleanup
    removeObject: env_id, carrier_band_id
    
    if i mod 5 = 0
        appendInfoLine: "Band ", i, "/", number_of_bands
    endif
endfor

# --- 5. FINALIZE & RESTORE ---
selectObject: output_id
Rename: orig_name$ + "_Vocoder"
Scale peak: 0.99

# Restore Sample Rate if we downsampled
if work_sr <> orig_sr
    appendInfoLine: "Restoring sample rate..."
    final_resampled = Resample: orig_sr, 50
    removeObject: output_id
    output_id = final_resampled
    selectObject: output_id
    Rename: orig_name$ + "_Vocoder"
endif

# Cleanup
removeObject: input_id, carrier_id

appendInfoLine: "Done!"

if play_after
    Play
endif