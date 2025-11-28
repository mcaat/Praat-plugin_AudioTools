# ============================================================
# Praat AudioTools - Time Manipulation + Spectral Blur + Stereo Width
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.7 (2025) - Fake stereo effect
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Fast PSOLA time-stretching + spectral blur + stereo width effect
#
# Usage:
#   Select a Sound object in Praat and run this script.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Time Manipulation + Spectral Blur + Stereo Width
    comment ---- Presets ----
    optionmenu Preset: 1
        option "Custom (use settings below)"
        option "Normal Speed (1.0x, no blur)"
        option "Slow Motion (0.75x, subtle blur)"
        option "Time Lapse (1.5x, no blur)"
        option "Ambient Stretch (2.0x, moderate blur)"
        option "Paulstretch-like (4.0x, heavy blur)"
        option "Extreme Drone (8.0x, maximum blur)"
    comment ---- Manual Settings (active if Custom selected) ----
    real Duration_factor 4.0
    positive Blur_amount 3
    comment (1=subtle, 3=moderate, 5=heavy, 7=extreme)
    positive Lowpass_frequency 8000
    positive Highpass_frequency 80
    comment ---- Stereo Width Effect ----
    boolean Create_stereo_width 1
    positive Stereo_delay_ms 15
    comment (5-30 ms, smaller = subtle, larger = wide)
    positive Stereo_detune_amount 0.5
    comment (0=none, 0.5=subtle, 1.0=moderate difference)
    comment ---- Pitch Range for PSOLA ----
    positive Min_pitch 75
    positive Max_pitch 600
    comment ---- Output ----
    boolean Play_result 1
endform

# Apply preset values
if preset = 1
    # Custom - use manual settings as entered
elsif preset = 2
    # Normal Speed
    duration_factor = 1.0
    blur_amount = 0
    create_stereo_width = 0
elsif preset = 3
    # Slow Motion
    duration_factor = 0.75
    blur_amount = 1
    lowpass_frequency = 10000
elsif preset = 4
    # Time Lapse
    duration_factor = 1.5
    blur_amount = 0
    create_stereo_width = 0
elsif preset = 5
    # Ambient Stretch
    duration_factor = 2.0
    blur_amount = 3
    lowpass_frequency = 7000
    create_stereo_width = 1
elsif preset = 6
    # Paulstretch-like
    duration_factor = 4.0
    blur_amount = 5
    lowpass_frequency = 6000
    create_stereo_width = 1
elsif preset = 7
    # Extreme Drone
    duration_factor = 8.0
    blur_amount = 7
    lowpass_frequency = 5000
    highpass_frequency = 100
    create_stereo_width = 1
    stereo_delay_ms = 25
endif

# Determine if blur should be applied
if blur_amount > 0
    apply_spectral_blur = 1
else
    apply_spectral_blur = 0
endif

# Check if a sound object is selected
if numberOfSelected("Sound") = 0
    exit Please select a Sound object first
endif

# Get the selected sound
originalSound = selected("Sound")
selectObject: originalSound
sound_name$ = selected$("Sound")

# Get original properties
duration = Get total duration
n_channels = Get number of channels

writeInfoLine: "Time Manipulation + Spectral Blur + Stereo Width"
appendInfoLine: "Input duration: ", fixed$(duration, 3), " s"
appendInfoLine: "Input channels: ", n_channels
appendInfoLine: "Duration factor: ", duration_factor, "x"
appendInfoLine: "Blur amount: ", blur_amount
appendInfoLine: ""

# Convert to mono for processing
if n_channels > 1
    appendInfoLine: "Converting to mono for processing..."
    selectObject: originalSound
    sound = Convert to mono
else
    sound = originalSound
endif

# ============================================================
# STEP 1: Fast PSOLA Time-Stretching
# ============================================================
appendInfoLine: "1. PSOLA time-stretching..."

selectObject: sound
manipulation = To Manipulation: 0.01, min_pitch, max_pitch

durationTier = Create DurationTier: "duration", 0, duration
Add point: 0, duration_factor
Add point: duration, duration_factor

selectObject: manipulation
plusObject: durationTier
Replace duration tier

selectObject: manipulation
resynthesized = Get resynthesis (overlap-add)

removeObject: durationTier, manipulation

selectObject: resynthesized
stretched_duration = Get total duration
appendInfoLine: "   Stretched to: ", fixed$(stretched_duration, 3), " s"

# ============================================================
# STEP 2: Spectral Blur
# ============================================================
if apply_spectral_blur
    appendInfoLine: "2. Applying spectral blur..."
    
    selectObject: resynthesized
    
    # Bandpass first
    Filter (pass Hann band): highpass_frequency, 0, 100
    temp1 = selected("Sound")
    Filter (pass Hann band): 0, lowpass_frequency, 100
    bandpassed = selected("Sound")
    removeObject: temp1
    
    # Cascaded lowpass filters for blur
    selectObject: bandpassed
    current_sound = bandpassed
    
    for i_pass from 1 to blur_amount
        cutoff_ratio = 1.0 - (i_pass * 0.15)
        current_cutoff = lowpass_frequency * cutoff_ratio
        
        if current_cutoff > highpass_frequency + 500
            selectObject: current_sound
            Filter (pass Hann band): 0, current_cutoff, 100
            new_sound = selected("Sound")
            
            if i_pass > 1
                removeObject: current_sound
            endif
            current_sound = new_sound
            
            appendInfoLine: "   Pass ", i_pass, ": lowpass at ", round(current_cutoff), " Hz"
        endif
    endfor
    
    removeObject: resynthesized, bandpassed
    resynthesized = current_sound
    
    selectObject: resynthesized
    appendInfoLine: "   Spectral blur complete"
endif

# ============================================================
# STEP 3: Create Stereo Width Effect
# ============================================================
if create_stereo_width
    appendInfoLine: "3. Creating stereo width effect..."
    
    selectObject: resynthesized
    fs = Get sampling frequency
    
    # Create LEFT channel (original with slight filtering)
    selectObject: resynthesized
    Copy: "left"
    left_channel = selected("Sound")
    
    # Slightly darker on left
    if stereo_detune_amount > 0
        left_cutoff = lowpass_frequency * (1.0 - stereo_detune_amount * 0.1)
        Filter (pass Hann band): 0, left_cutoff, 50
        left_filtered = selected("Sound")
        removeObject: left_channel
        left_channel = left_filtered
    endif
    
    # Create RIGHT channel (delayed and slightly different filtering)
    selectObject: resynthesized
    Copy: "right"
    right_channel = selected("Sound")
    
    # Slightly brighter on right
    if stereo_detune_amount > 0
        right_cutoff = lowpass_frequency * (1.0 + stereo_detune_amount * 0.05)
        if right_cutoff < fs / 2
            Filter (pass Hann band): 0, right_cutoff, 50
            right_filtered = selected("Sound")
            removeObject: right_channel
            right_channel = right_filtered
        endif
    endif
    
    # Apply delay to right channel
    delay_seconds = stereo_delay_ms / 1000
    selectObject: right_channel
    
    # Add silence at start for delay
    silence_for_delay = Create Sound from formula: "delay_silence", 1, 0, delay_seconds, fs, "0"
    selectObject: silence_for_delay
    plusObject: right_channel
    right_delayed = Concatenate
    removeObject: silence_for_delay, right_channel
    
    # Trim left to match duration if needed
    selectObject: right_delayed
    right_dur = Get total duration
    selectObject: left_channel
    left_dur = Get total duration
    
    if right_dur > left_dur
        # Pad left with silence at end
        pad_needed = right_dur - left_dur
        silence_pad = Create Sound from formula: "pad", 1, 0, pad_needed, fs, "0"
        selectObject: left_channel
        plusObject: silence_pad
        left_padded = Concatenate
        removeObject: silence_pad, left_channel
        left_channel = left_padded
    endif
    
    # Combine to stereo
    selectObject: left_channel
    plusObject: right_delayed
    stereo_result = Combine to stereo
    
    removeObject: left_channel, right_delayed, resynthesized
    result = stereo_result
    
    appendInfoLine: "   Stereo width: ", stereo_delay_ms, " ms delay"
else
    result = resynthesized
endif

# ============================================================
# Finalize
# ============================================================
selectObject: result
final_duration = Get total duration
final_channels = Get number of channels
Rename: sound_name$ + "_stretched_" + string$(duration_factor) + "x"
Scale peak: 0.99

appendInfoLine: ""
appendInfoLine: "Done! Final duration: ", fixed$(final_duration, 3), " s"
appendInfoLine: "Output channels: ", final_channels

# Clean up
if n_channels > 1
    removeObject: sound
endif

# Play if requested
if play_result
    Play
endif

# Select both original and result
selectObject: originalSound
plusObject: result