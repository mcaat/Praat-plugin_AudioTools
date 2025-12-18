# ============================================================
# Praat AudioTools - Auto-Swell.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Auto-Swell
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Auto-Swell (Musical Dynamics) 
# Applies periodic or envelope-shaped amplitude modulations
# Input: Selected Sound object
# Output: Modified Sound object with stereo swell effects

form Auto-Swell Parameters
    comment Swell Type
    optionmenu Swell_shape: 1
        option Sine wave (smooth)
        option Triangle wave (linear)
        option Sawtooth (rise, instant drop)
        option Reverse sawtooth (instant rise, fall)
        option Square wave (hard gate)
        option Exponential rise
        option Exponential fall
        option S-curve (ease in-out)
        option Double peak (two swells per cycle)
        option Random walk (organic chaos)
        option Pulse gate (rhythmic chopping)
        option Rise-fall envelope (single arc)
    comment Timing Parameters
    positive Swell_rate_Hz 0.5
    comment (Number of swells per second, 0.1-10 Hz typical)
    positive Depth_percent 80
    comment (Modulation depth: 0-100%, where 100% = full dynamic range)
    comment Stereo Options
    optionmenu Stereo_mode: 2
        option Same effect both sides (mono)
        option Phase offset (left/right out of phase)
        option Different rates (polyrhythmic)
        option Different shapes (contrasting textures)
    positive Phase_offset_degrees 90
    comment (For Phase offset mode: 0-180 degrees)
    positive Right_rate_multiplier 1.5
    comment (For Different rates: multiplier for right channel)
    optionmenu Right_swell_shape: 2
        option Sine wave (smooth)
        option Triangle wave (linear)
        option Sawtooth (rise, instant drop)
        option Reverse sawtooth (instant rise, fall)
        option Square wave (hard gate)
        option Exponential rise
        option Exponential fall
        option S-curve (ease in-out)
        option Double peak (two swells per cycle)
        option Random walk (organic chaos)
        option Pulse gate (rhythmic chopping)
        option Rise-fall envelope (single arc)
    comment Advanced Options
    boolean Normalize_output 1
    optionmenu Phase_start: 1
        option Start at minimum (fade in)
        option Start at maximum (fade out)
        option Start at middle
    comment Special Options (for Pulse Gate and Random Walk)
    positive Pulse_width_percent 50
    comment (For Pulse gate: % of cycle that's ON, 1-99%)
    positive Random_smoothness 10
    comment (For Random walk: higher = smoother, 1-50)
endform

# Get selected sound
sound = selected("Sound")
soundName$ = selected$("Sound")
dur = Get total duration
sr = Get sampling frequency
nChannels = Get number of channels

# Convert parameters
depth = depth_percent / 100
swellPeriod = 1 / swell_rate_Hz
pulseWidth = pulse_width_percent / 100
phaseOffsetRad = phase_offset_degrees * pi / 180

# Convert to stereo if mono
if nChannels = 1
    selectObject: sound
    Convert to stereo
    sound = selected("Sound")
endif

# Extract left and right channels
selectObject: sound
Extract one channel: 1
leftChannel = selected("Sound")

selectObject: sound
Extract one channel: 2
rightChannel = selected("Sound")

# ====================
# CREATE LEFT MODULATION
# ====================
Create Sound from formula: "mod_left", 1, 0, dur, sr, "0"
call GenerateModulation swell_shape phase_start swell_rate_Hz pulseWidth random_smoothness 0
leftMod = selected("Sound")

# ====================
# CREATE RIGHT MODULATION
# ====================
if stereo_mode = 1
    # Same effect both sides
    selectObject: leftMod
    Copy: "mod_right"
    rightMod = selected("Sound")
    
elsif stereo_mode = 2
    # Phase offset
    Create Sound from formula: "mod_right", 1, 0, dur, sr, "0"
    call GenerateModulation swell_shape phase_start swell_rate_Hz pulseWidth random_smoothness phaseOffsetRad
    rightMod = selected("Sound")
    
elsif stereo_mode = 3
    # Different rates
    rightRate = swell_rate_Hz * right_rate_multiplier
    Create Sound from formula: "mod_right", 1, 0, dur, sr, "0"
    call GenerateModulation swell_shape phase_start rightRate pulseWidth random_smoothness 0
    rightMod = selected("Sound")
    
elsif stereo_mode = 4
    # Different shapes
    Create Sound from formula: "mod_right", 1, 0, dur, sr, "0"
    call GenerateModulation right_swell_shape phase_start swell_rate_Hz pulseWidth random_smoothness 0
    rightMod = selected("Sound")
endif

# Apply depth scaling to both modulations
selectObject: leftMod
Formula: "(1 - depth) + depth * self"

selectObject: rightMod
Formula: "(1 - depth) + depth * self"

# ====================
# APPLY MODULATIONS
# ====================
# Apply left modulation
selectObject: leftChannel
Formula: "self * object[leftMod, col]"
processedLeft = selected("Sound")

# Apply right modulation
selectObject: rightChannel
Formula: "self * object[rightMod, col]"
processedRight = selected("Sound")

# ====================
# COMBINE TO STEREO
# ====================
selectObject: processedLeft
plusObject: processedRight
Combine to stereo
stereoResult = selected("Sound")
Rename: soundName$ + "_autoswelled_stereo"

# Normalize if requested
if normalize_output
    selectObject: stereoResult
    Scale peak: 0.99
endif

# Clean up
selectObject: leftMod, rightMod, leftChannel, rightChannel, processedLeft, processedRight
Remove

selectObject: stereoResult

# ====================
# PROCEDURE: Generate Modulation Shape
# ====================
procedure GenerateModulation .shape .phase .rate .pulseW .smoothness .phaseOffset
    
    if .shape = 1
        # Sine wave
        if .phase = 1
            Formula: "0.5 + 0.5 * sin(2 * pi * .rate * x - pi/2 + .phaseOffset)"
        elsif .phase = 2
            Formula: "0.5 + 0.5 * sin(2 * pi * .rate * x + pi/2 + .phaseOffset)"
        else
            Formula: "0.5 + 0.5 * sin(2 * pi * .rate * x + .phaseOffset)"
        endif
        
    elsif .shape = 2
        # Triangle wave
        if .phase = 1
            Formula: "abs(((x * .rate + .phaseOffset/(2*pi)) mod 1) - 0.5) * 2"
        elsif .phase = 2
            Formula: "1 - abs(((x * .rate + .phaseOffset/(2*pi)) mod 1) - 0.5) * 2"
        else
            Formula: "if ((x * .rate + .phaseOffset/(2*pi)) mod 1) < 0.5 then 2 * ((x * .rate + .phaseOffset/(2*pi)) mod 1) else 2 * (1 - ((x * .rate + .phaseOffset/(2*pi)) mod 1)) fi"
        endif
        
    elsif .shape = 3
        # Sawtooth
        Formula: "(x * .rate + .phaseOffset/(2*pi)) mod 1"
        
    elsif .shape = 4
        # Reverse sawtooth
        Formula: "1 - ((x * .rate + .phaseOffset/(2*pi)) mod 1)"
        
    elsif .shape = 5
        # Square wave
        Formula: "if ((x * .rate + .phaseOffset/(2*pi)) mod 1) < 0.5 then 1 else 0 fi"
        
    elsif .shape = 6
        # Exponential rise
        Formula: "1 - exp(-6 * ((x * .rate + .phaseOffset/(2*pi)) mod 1))"
        
    elsif .shape = 7
        # Exponential fall
        Formula: "exp(-6 * ((x * .rate + .phaseOffset/(2*pi)) mod 1))"
        
    elsif .shape = 8
        # S-curve
        phase$ = "((x * .rate + .phaseOffset/(2*pi)) mod 1)"
        Formula: "if 'phase$' < 0.5 then 0.5 * (1 - cos(pi * 'phase$' * 2)) else 0.5 * (1 + cos(pi * ('phase$' - 0.5) * 2)) fi"
        
    elsif .shape = 9
        # Double peak
        Formula: "0.5 + 0.5 * sin(4 * pi * .rate * x + .phaseOffset)"
        Formula: "abs(self)"
        
    elsif .shape = 10
        # Random walk
        Formula: "randomGauss(0.5, 0.15)"
        smoothSamples = round(sr / (.rate * .smoothness))
        if smoothSamples > 1
            Formula: "self[col]"
            for i to 3
                Formula: "if col > 'smoothSamples' and col < ncol - 'smoothSamples' then (self[col - 'smoothSamples'] + self[col] + self[col + 'smoothSamples']) / 3 else self fi"
            endfor
        endif
        minVal = Get minimum: 0, 0, "None"
        maxVal = Get maximum: 0, 0, "None"
        Formula: "(self - minVal) / (maxVal - minVal)"
        
    elsif .shape = 11
        # Pulse gate
        Formula: "if ((x * .rate + .phaseOffset/(2*pi)) mod 1) < .pulseW then 1 else 0 fi"
        
    elsif .shape = 12
        # Rise-fall envelope
        Formula: "if x < dur/2 then (1 - exp(-6 * 2 * x / dur)) else exp(-6 * 2 * (x - dur/2) / dur) fi"
    endif
    
endproc
Play