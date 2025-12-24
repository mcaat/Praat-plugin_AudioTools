# ============================================================
# Praat AudioTools - Autocorrelation-Based Self-Filtering.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Time-Varying Autocorrelation Convolution
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Time-Varying Autocorrelation Convolution
# Adaptive audio effect based on signal's own structure

form Time-Varying Autocorrelation Convolution
    comment Processing parameters:
    positive Window_duration_(seconds) 0.2
    positive Window_step_(seconds) 0.1
    comment IR parameters:
    positive Max_lag_(seconds) 0.02
    comment Effect intensity:
    optionmenu Effect_character 1
        option Tight/Metallic (lag=0.01s)
        option Medium/Resonant (lag=0.02s)
        option Loose/Ambient (lag=0.05s)
        option Custom (use Max_lag value above)
    comment Smoothing:
    positive Crossfade_duration_(seconds) 0.01
    boolean Play_result 1
    boolean Keep_original 1
endform

# Override maxLag based on effect character choice
if effect_character == 1
    maxLag = 0.01
elsif effect_character == 2
    maxLag = 0.02
elsif effect_character == 3
    maxLag = 0.05
else
    maxLag = max_lag
endif

# Get parameters from form
windowDuration = window_duration
windowStep = window_step
crossfadeDuration = crossfade_duration
playResult = play_result
keepOriginal = keep_original

# Get the selected sound
sound = selected("Sound")
soundName$ = selected$("Sound")
fs = Get sampling frequency
soundDuration = Get total duration

writeInfoLine: "Time-Varying Autocorrelation Convolution"
appendInfoLine: "========================================"
appendInfoLine: "Original: ", soundName$
appendInfoLine: "Duration: ", fixed$(soundDuration, 3), " s"
appendInfoLine: "Sample rate: ", fs, " Hz"
appendInfoLine: ""
appendInfoLine: "Parameters:"
appendInfoLine: "  Window duration: ", fixed$(windowDuration, 3), " s"
appendInfoLine: "  Window step: ", fixed$(windowStep, 3), " s"
appendInfoLine: "  Max lag (IR): ", fixed$(maxLag, 3), " s"
appendInfoLine: "  Crossfade: ", fixed$(crossfadeDuration, 3), " s"
appendInfoLine: ""

# Calculate number of windows to cover entire sound
numWindows = floor((soundDuration - windowDuration) / windowStep) + 1

# Check if we need to add one more window to reach the very end
lastWindowEnd = (numWindows - 1) * windowStep + windowDuration
if lastWindowEnd < soundDuration - 0.01
    numWindows = numWindows + 1
endif

appendInfoLine: "Processing ", numWindows, " overlapping windows..."
appendInfoLine: ""

# Process all windows
validWindows = 0
for iWindow from 1 to numWindows
    startTime = (iWindow - 1) * windowStep
    endTime = startTime + windowDuration
    
    # Adjust last window to exactly reach the end
    if iWindow == numWindows and endTime < soundDuration
        endTime = soundDuration
    endif
    
    if endTime > soundDuration
        endTime = soundDuration
    endif
    
    actualDur = endTime - startTime
    
    # Skip if window would be too short
    if actualDur < 0.05
        appendInfoLine: "Skipping window ", iWindow, " (too short)"
    else
        if iWindow mod 5 == 1 or iWindow == numWindows
            appendInfoLine: "Window ", iWindow, "/", numWindows, ": ", fixed$(startTime, 2), "-", fixed$(endTime, 2), " s"
        endif
        
        # Extract window
        select sound
        Extract part: startTime, endTime, "rectangular", 1, "no"
        windowSound = selected("Sound")
        
        # Autocorrelation
        select windowSound
        Autocorrelate: "sum", "zero"
        acSound = selected("Sound")
        
        acDur = Get total duration
        acCenter = acDur / 2
        
        # Extract IR
        Extract part: acCenter - maxLag, acCenter + maxLag, "rectangular", 1, "no"
        irSound = selected("Sound")
        
        # Normalize IR
        irMax = Get maximum: 0, 0, "None"
        if irMax > 0
            Formula: "self / irMax"
        endif
        
        # Window the IR
        irDur = Get total duration
        Formula: "self * (0.5 - 0.5 * cos(2 * pi * x / irDur))"
        
        # Convolve
        select windowSound
        plus irSound
        Convolve: "sum", "zero"
        convolved = selected("Sound")
        
        # Normalize
        convMax = Get maximum: 0, 0, "None"
        convMin = Get minimum: 0, 0, "None"
        convAbsMax = max(abs(convMax), abs(convMin))
        if convAbsMax > 0
            Formula: "self / convAbsMax * 0.5"
        endif
        
        # Extract center (original window length)
        convDur = Get total duration
        convCenter = convDur / 2
        Extract part: convCenter - actualDur/2, convCenter + actualDur/2, "rectangular", 1, "no"
        trimmed = selected("Sound")
        
        # Apply crossfade at edges
        trimSamples = Get number of samples
        fadeSamples = round(crossfadeDuration * fs)
        
        # Fade in at start (except first window)
        if iWindow > 1 and fadeSamples < trimSamples
            for i from 1 to fadeSamples
                select trimmed
                fade = i / fadeSamples
                currentVal = Get value at sample number: i, 1
                Set value at sample number: i, 1, currentVal * fade
            endfor
        endif
        
        # Fade out at end (except last window)
        if iWindow < numWindows and fadeSamples < trimSamples
            for i from 1 to fadeSamples
                select trimmed
                fade = i / fadeSamples
                sampleIndex = trimSamples - i + 1
                currentVal = Get value at sample number: sampleIndex, 1
                Set value at sample number: sampleIndex, 1, currentVal * fade
            endfor
        endif
        
        # Rename for concatenation
        select trimmed
        validWindows = validWindows + 1
        Rename: "proc_" + string$(validWindows)
        
        # Cleanup intermediates
        select windowSound
        plus acSound
        plus irSound
        plus convolved
        Remove
    endif
endfor

# Concatenate all processed windows
appendInfoLine: ""
appendInfoLine: "Concatenating ", validWindows, " windows..."

# Select first window
select Sound proc_1

# Add the rest
for iWindow from 2 to validWindows
    plus Sound proc_'iWindow'
endfor

Concatenate
outputSound = selected("Sound")
Rename: "adaptive_" + soundName$

outDur = Get total duration
outMax = Get maximum: 0, 0, "None"
outMin = Get minimum: 0, 0, "None"

appendInfoLine: ""
appendInfoLine: "Results:"
appendInfoLine: "--------"
appendInfoLine: "Input duration: ", fixed$(soundDuration, 3), " s"
appendInfoLine: "Output duration: ", fixed$(outDur, 3), " s"
appendInfoLine: "Peak level before normalization: ", fixed$(max(abs(outMax), abs(outMin)), 3)

# Final normalization
outAbsMax = max(abs(outMax), abs(outMin))
if outAbsMax > 0
    Formula: "self / outAbsMax * 0.9"
    appendInfoLine: "Normalized to: 0.9"
endif

# Cleanup individual windows
for iWindow from 1 to validWindows
    select Sound proc_'iWindow'
    Remove
endfor

select outputSound

# Play if requested
if playResult
    appendInfoLine: ""
    appendInfoLine: "Playing result..."
    Play
endif

# Clean up original if not keeping
if not keepOriginal
    select sound
    Remove
endif

select outputSound
appendInfoLine: ""
appendInfoLine: "========================================"
appendInfoLine: "Complete! Created: adaptive_", soundName$
appendInfoLine: ""
appendInfoLine: "Tips:"
appendInfoLine: "- Smaller window step = smoother transitions"
appendInfoLine: "- Larger max lag = more ambient/reverberant"
appendInfoLine: "- Smaller max lag = more metallic/robotic"