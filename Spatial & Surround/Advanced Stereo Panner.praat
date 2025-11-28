# ============================================================
# Praat AudioTools - Advanced Stereo Panner
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 1.0 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Advanced stereo panning with four psychoacoustic cues:
#   - ILD (Interaural Level Difference)
#   - ITD (Interaural Time Difference)
#   - Spectral Cues (head shadow simulation)
#   - Distance Effects (amplitude & air absorption)
#   Inspired by Goodhertz Panpot
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose a preset or use Custom mode with manual parameters.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Stereo Panner Complete
    optionmenu Preset: 1
        option Center
        option Hard Left
        option Hard Right
        option Medium Left
        option Medium Right
        option Subtle Left
        option Subtle Right
        option Wide Left
        option Wide Right
        option Custom
    real Pan_position 0.0
    positive ILD_amount_(dB) 12
    positive Max_ITD_(ms) 0.65
    boolean Use_ITD 1
    boolean Use_spectral_cues 1
    positive High_freq_rolloff_(Hz) 8000
    boolean Use_distance 1
    positive Distance_(meters) 1.0
    positive Max_distance_(meters) 30.0
endform

# Apply presets
if preset = 1
    pan_position = 0.0
elsif preset = 2
    pan_position = -1.0
elsif preset = 3
    pan_position = 1.0
elsif preset = 4
    pan_position = -0.5
elsif preset = 5
    pan_position = 0.5
elsif preset = 6
    pan_position = -0.25
elsif preset = 7
    pan_position = 0.25
elsif preset = 8
    pan_position = -0.75
elsif preset = 9
    pan_position = 0.75
endif

if pan_position < -1 or pan_position > 1
    exitScript: "Pan position must be between -1 and 1"
endif

original = selected("Sound")
name$ = selected$("Sound")
sampleRate = Get sampling frequency
duration = Get total duration
numChannels = Get number of channels

if numChannels > 1
    mono = Convert to mono
else
    mono = Copy: name$ + "mono"
endif

# Calculate constant power panning
panNorm = (pan_position + 1) / 2
gain[1] = sqrt(1 - panNorm)
gain[2] = sqrt(panNorm)

# Apply ILD
if pan_position < 0
    gain[1] = gain[1] * 10^(abs(pan_position) * iLD_amount / 20)
    gain[2] = gain[2] * 10^(-abs(pan_position) * iLD_amount / 20)
else
    gain[1] = gain[1] * 10^(-pan_position * iLD_amount / 20)
    gain[2] = gain[2] * 10^(pan_position * iLD_amount / 20)
endif

# Distance attenuation (inverse square law)
distFactor = distance / max_distance
distGain = 1 / (1 + distFactor * 2)
if use_distance
    gain[1] = gain[1] * distGain
    gain[2] = gain[2] * distGain
endif

# ITD calculation
itd = 0
if use_ITD
    itd = abs(pan_position) * max_ITD / 1000
endif

# Create left channel
selectObject: mono
chL = Copy: "L"

# Apply spectral cue to left (shadow when panned right)
if use_spectral_cues
    if pan_position > 0
        selectObject: chL
        cutoff = high_freq_rolloff * (1 - pan_position * 0.5)
        Filter (pass Hann band): 0, cutoff, 100
        temp = selected("Sound")
        removeObject: chL
        chL = temp
    endif
endif

# Apply distance air absorption to left
if use_distance
    if distance > 1
        selectObject: chL
        airCutoff = 12000 / (1 + distFactor * 3)
        Filter (pass Hann band): 0, airCutoff, 200
        temp = selected("Sound")
        removeObject: chL
        chL = temp
    endif
endif

# Apply ITD to left (delay when panned right)
if use_ITD
    if pan_position > 0
        selectObject: chL
        silence = Create Sound from formula: "s", 1, 0, itd, sampleRate, "0"
        plusObject: chL
        concat = Concatenate
        selectObject: concat
        Extract part: 0, duration, "rectangular", 1, "no"
        temp = selected("Sound")
        removeObject: silence, concat, chL
        chL = temp
    endif
endif

selectObject: chL
Formula: "self * " + string$(gain[1])

# Create right channel
selectObject: mono
chR = Copy: "R"

# Apply spectral cue to right (shadow when panned left)
if use_spectral_cues
    if pan_position < 0
        selectObject: chR
        cutoff = high_freq_rolloff * (1 - abs(pan_position) * 0.5)
        Filter (pass Hann band): 0, cutoff, 100
        temp = selected("Sound")
        removeObject: chR
        chR = temp
    endif
endif

# Apply distance air absorption to right
if use_distance
    if distance > 1
        selectObject: chR
        airCutoff = 12000 / (1 + distFactor * 3)
        Filter (pass Hann band): 0, airCutoff, 200
        temp = selected("Sound")
        removeObject: chR
        chR = temp
    endif
endif

# Apply ITD to right (delay when panned left)
if use_ITD
    if pan_position < 0
        selectObject: chR
        silence = Create Sound from formula: "s", 1, 0, itd, sampleRate, "0"
        plusObject: chR
        concat = Concatenate
        selectObject: concat
        Extract part: 0, duration, "rectangular", 1, "no"
        temp = selected("Sound")
        removeObject: silence, concat, chR
        chR = temp
    endif
endif

selectObject: chR
Formula: "self * " + string$(gain[2])

# Combine
selectObject: chL
plusObject: chR
stereo = Combine to stereo

removeObject: chL, chR, mono

selectObject: stereo

# Generate preset name
presetName$ = ""
if preset = 1
    presetName$ = "Center"
elsif preset = 2
    presetName$ = "HardLeft"
elsif preset = 3
    presetName$ = "HardRight"
elsif preset = 4
    presetName$ = "MediumLeft"
elsif preset = 5
    presetName$ = "MediumRight"
elsif preset = 6
    presetName$ = "SubtleLeft"
elsif preset = 7
    presetName$ = "SubtleRight"
elsif preset = 8
    presetName$ = "WideLeft"
elsif preset = 9
    presetName$ = "WideRight"
elsif preset = 10
    presetName$ = "Custom"
endif

Rename: name$ + "_" + presetName$

writeInfoLine: "Advanced Stereo Panner Applied"
appendInfoLine: "================================"
appendInfoLine: "Preset: ", presetName$
appendInfoLine: "Pan: ", pan_position
appendInfoLine: "L gain: ", gain[1]
appendInfoLine: "R gain: ", gain[2]
appendInfoLine: "ITD: ", itd * 1000, " ms"
appendInfoLine: "Spectral cues: ", if use_spectral_cues then "ON" else "OFF" fi
appendInfoLine: "Distance: ", distance, "m (gain: ", distGain, ")"

Play