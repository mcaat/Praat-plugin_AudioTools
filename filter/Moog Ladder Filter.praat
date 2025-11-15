# ============================================================
# Praat AudioTools - Moog Ladder Filter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Moog Ladder Filter
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Moog Ladder Filter - Production TPT Implementation
# Fast Formula-based processing with adaptive stability and gentle limiting

form Moog Ladder Filter (TPT)
    optionmenu Preset 1
        option Custom
        option Bass Filter (300 Hz, res 0.3)
        option Warm Pad (800 Hz, res 0.5)
        option Vocal Formant (1500 Hz, res 0.65)
        option Bright Sweep (2500 Hz, res 0.55)
        option Resonant Peak (1200 Hz, res 0.75)
        option Telephone (2800 Hz, res 0.35)
        option Sub Bass (150 Hz, res 0.2)
        option Acid Bass (500 Hz, res 0.75)
    positive Cutoff_frequency_(Hz) 1000
    real Resonance_(0-1) 0.7
    boolean DC_blocker 1
    optionmenu Limiter_type 1
        option Soft (x/(1+|x|))
        option Analog-style (tanh)
    real Output_trim_(dB) 0
    comment Fast TPT ladder with adaptive stability
endform

# Apply preset values
if preset == 2
    cutoff_frequency = 300
    resonance = 0.3
elsif preset == 3
    cutoff_frequency = 800
    resonance = 0.5
elsif preset == 4
    cutoff_frequency = 1500
    resonance = 0.65
elsif preset == 5
    cutoff_frequency = 2500
    resonance = 0.55
elsif preset == 6
    cutoff_frequency = 1200
    resonance = 0.75
elsif preset == 7
    cutoff_frequency = 2800
    resonance = 0.35
elsif preset == 8
    cutoff_frequency = 150
    resonance = 0.2
elsif preset == 9
    cutoff_frequency = 500
    resonance = 0.75
endif

# Get selected sound
sound = selected("Sound")
soundName$ = selected$("Sound")
samplingFrequency = Get sampling frequency
numberOfChannels = Get number of channels

# TPT coefficients
fc = cutoff_frequency / samplingFrequency
wc = 2 * pi * fc
g = tan(wc / 2)
gg = g / (1 + g)
gg_comp = 1 - gg

# Resonance with power curve for smoother control
k = 4 * (resonance ^ 1.5)

# Adaptive resonance cap: tighten limit at high cutoff
k_max = 3.9
if g > 0.6
    # Taper max k as we approach Nyquist
    k_max = 3.9 - (g - 0.6) * 3.0
    if k_max < 3.0
        k_max = 3.0
    endif
endif
if k > k_max
    k = k_max
endif

# Adaptive iterations based on resonance and cutoff
iterations = 2
if k > 3.0 or g > 0.5
    iterations = 3
endif
if k > 3.4 and g > 0.5
    iterations = 4
endif

# Output trim
trimGain = 10 ^ (output_trim / 20)

# Process each channel independently
for channel from 1 to numberOfChannels
    
    # Extract single channel for processing
    selectObject: sound
    channel_sound = Extract one channel: channel
    
    # Create working copies (per-channel state)
    stage1 = Copy: "stage1"
    stage2 = Copy: "stage2"
    stage3 = Copy: "stage3"
    stage4 = Copy: "stage4"
    feedback = Copy: "feedback"
    channel_result = Copy: "channel_result"
    
    # Initialize feedback to zero (implicit edge guard)
    selectObject: feedback
    Formula: "0"
    
    # Iterative cascade with feedback
    for iteration from 1 to iterations
        
        # Stage 1 - input minus feedback from previous sample
        # col-1 at col=1 is automatically 0 in Praat (edge guard)
        selectObject: stage1
        Formula: "object[channel_sound, col] - " + string$(k) + " * object[feedback, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        # Stage 2
        selectObject: stage2
        Formula: "object[stage1, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        # Stage 3
        selectObject: stage3
        Formula: "object[stage2, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        # Stage 4
        selectObject: stage4
        Formula: "object[stage3, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        # Update feedback with delayed output
        selectObject: feedback
        Formula: "object[stage4, col-1]"
        
    endfor
    
    # Copy to result with output trim
    selectObject: channel_result
    Formula: "object[stage4, col] * " + string$(trimGain)
    
    # Soft limiting (after ladder, not in feedback loop)
    selectObject: channel_result
    if limiter_type == 1
        # Gentle soft limiting: y = x / (1 + |x|)
        Formula: "self / (1 + abs(self))"
    else
        # Analog-style: tanh with drive
        Formula: "tanh(0.8 * self)"
    endif
    
    # Proper DC blocker (1-pole HPF at 20 Hz)
    if dC_blocker
        selectObject: channel_result
        dcInput = Copy: "dc_input"
        dcOutput = Copy: "dc_output"
        
        # DC blocker coefficient
        alpha_dc = exp(-2 * pi * 20 / samplingFrequency)
        
        # Store input
        selectObject: dcInput
        Formula: "object[channel_result, col]"
        
        # Compute: y[n] = x[n] - x[n-1] + alpha * y[n-1]
        # col-1 at col=1 is 0 (edge guard)
        selectObject: dcOutput
        Formula: "object[dcInput, col] - object[dcInput, col-1] + " + string$(alpha_dc) + " * self[col-1]"
        
        # Copy back to result
        selectObject: channel_result
        Formula: "object[dcOutput, col]"
        
        # Cleanup DC blocker buffers
        removeObject: dcInput, dcOutput
    endif
    
    # Store processed channel
    if channel == 1
        selectObject: channel_result
        result = Copy: soundName$ + "_moog"
    else
        # Combine channels
        selectObject: result
        plusObject: channel_result
        temp = Combine to stereo
        removeObject: result
        result = temp
    endif
    
    # Cleanup channel processing buffers
    removeObject: stage1, stage2, stage3, stage4, feedback, channel_result, channel_sound
    
endfor

# Select output
selectObject: result
Play

# Note on parameter smoothing:
# This implementation processes entire buffers at once (Formula mode).
# For click-free cutoff/resonance sweeps, use Praat's built-in automation
# or external modulation tools before calling this script.