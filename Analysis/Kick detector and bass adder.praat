# ============================================================
# Praat AudioTools - Kick detector and bass adder.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Kick detector and bass adder
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

################################################################################
# Kick detector and bass adder                                                 #
# Select TWO Sounds: 1) Full drum loop, 2) Bass sample, then run              #
################################################################################

# ----------------------- User parameters --------------------------------------
lowBandMin    = 25      ; Hz (kick body)
lowBandMax    = 120     ; Hz
lowMidMin     = 120     ; Hz (helps reject toms/snares)
lowMidMax     = 250     ; Hz
smoothHz      = 100     ; Hz smoothing for Hann band filters

hop_default   = 0.01    ; s (target analysis hop)

mark$         = "kick"
tierName$     = "Kicks"

# ----------------------- Preconditions ----------------------------------------
if numberOfSelected ("Sound") <> 2
    exitScript: "Please select exactly TWO Sounds: 1) Full drum loop, 2) Bass sample, then run"
endif

# Get the two selected sounds
sound1$ = selected$ ("Sound", 1)
sound2$ = selected$ ("Sound", 2)

# Ask user which is which and get detection parameters
beginPause: "Kick Detector and Bass Adder"
    comment: "Select TWO Sounds: 1) Full drum loop, 2) Bass sample, then run"
    comment: ""
    comment: "You selected: '" + sound1$ + "' and '" + sound2$ + "'"
    comment: ""
    choice: "drumLoop", 1
        option: sound1$
        option: sound2$
    choice: "bassSample", 2
        option: sound1$
        option: sound2$
    comment: ""
    comment: "Detection parameters:"
    real: "scoreThresh", 0.80
    comment: "  (Lower = more sensitive, detect more kicks. Range: 0.5-1.5)"
    real: "dLowThresh", 0.60
    comment: "  (Lower = more sensitive. Range: 0.3-1.0)"
    real: "refractory", 0.09
    comment: "  (Minimum time between kicks in seconds)"
    comment: ""
    comment: "Timing adjustment:"
    real: "timeOffset", 0.052
    comment: "  (Shift detection forward in seconds, positive = later)"
    real: "kickWindowBefore", 0.01
    comment: "  (Not used in bass adding mode)"
    real: "kickWindowAfter", 0.11
    comment: "  (Not used in bass adding mode)"
    comment: ""
    comment: "Score weights:"
    real: "wLow", 1.0
    real: "wFlux", 0.5
    real: "wLowMidPen", 0.5
endPause: "Detect and Add Bass", 1

if drumLoop = bassSample
    exitScript: "Please select different sounds for drum loop and bass sample!"
endif

if drumLoop = 1
    orig$ = sound1$
    sample$ = sound2$
else
    orig$ = sound2$
    sample$ = sound1$
endif

selectObject: "Sound " + orig$
xmin = Get start time
xmax = Get end time
dur  = xmax - xmin
if dur <= 0.008
    exitScript: "Drum loop is too short (" + string$(dur) + " s) for analysis."
endif

# Get kick sample properties
selectObject: "Sound " + sample$
sampleDur = Get total duration
sampleChannels = Get number of channels

writeInfoLine: "Drum loop: '", orig$, "'"
appendInfoLine: "Bass sample: '", sample$, "' (", string$(sampleDur), " s)"

# ----------------------- Make a safe working copy ------------------------------
selectObject: "Sound " + orig$
Extract part: xmin, xmax, "rectangular", 1, "yes"
work$ = "KD_work_" + orig$
Rename: work$

# ----------------------- Adaptive Intensity window & hop ----------------------
safeWindow = min (0.5 * dur, 0.04)
safeWindow = max (safeWindow, 0.005)
minPitchForIntensity = 0.8 / safeWindow
hop = min (hop_default, safeWindow / 2)

# ----------------------- Bandpass filtering ------------------------------------
selectObject: "Sound " + work$
Filter (pass Hann band): lowBandMin, lowBandMax, smoothHz
Rename: "KD_low"

selectObject: "Sound " + work$
Filter (pass Hann band): lowMidMin, lowMidMax, smoothHz
Rename: "KD_lowmid"

# ----------------------- Intensities -------------------------------------------
selectObject: "Sound " + work$
To Intensity: minPitchForIntensity, hop, "yes"
Rename: "KD_I_broad"

selectObject: "Sound KD_low"
To Intensity: minPitchForIntensity, hop, "yes"
Rename: "KD_I_low"

selectObject: "Sound KD_lowmid"
To Intensity: minPitchForIntensity, hop, "yes"
Rename: "KD_I_lowmid"

# ----------------------- Read intensities into arrays --------------------------
selectObject: "Intensity KD_I_low"
n = Get number of frames
if n < 3
    exitScript: "Too few frames (" + string$(n) + ") for detection."
endif

time#     = zero# (n)
low#      = zero# (n)
lowmid#   = zero# (n)
broad#    = zero# (n)
dlow#     = zero# (n)
dbroad#   = zero# (n)
zLow#     = zero# (n)
zLowMid#  = zero# (n)
zDLow#    = zero# (n)
zDBroad#  = zero# (n)
zDBroadPos# = zero# (n)
score#    = zero# (n)

for i from 1 to n
    selectObject: "Intensity KD_I_low"
    time#[i] = Get time from frame: i
    lv = Get value in frame: i
    if lv = undefined
        lv = 0
    endif
    low#[i] = lv

    selectObject: "Intensity KD_I_lowmid"
    lmv = Get value in frame: i
    if lmv = undefined
        lmv = 0
    endif
    lowmid#[i] = lmv

    selectObject: "Intensity KD_I_broad"
    bv = Get value in frame: i
    if bv = undefined
        bv = 0
    endif
    broad#[i] = bv
endfor

# ----------------------- First differences -------------------------------------
for i from 1 to n
    if i = 1
        dlow#[i]   = 0
        dbroad#[i] = 0
    else
        dlow#[i]   = low#[i]   - low#[i-1]
        dbroad#[i] = broad#[i] - broad#[i-1]
    endif
endfor

# ----------------------- Z-score normalization ---------------------------------
muLow = 0
muLowMid = 0
muDLow = 0
muDBroad = 0
for i from 1 to n
    muLow    = muLow    + low#[i]
    muLowMid = muLowMid + lowmid#[i]
    muDLow   = muDLow   + dlow#[i]
    muDBroad = muDBroad + dbroad#[i]
endfor
muLow    = muLow    / n
muLowMid = muLowMid / n
muDLow   = muDLow   / n
muDBroad = muDBroad / n

varLow = 0
varLowMid = 0
varDLow = 0
varDBroad = 0
for i from 1 to n
    d = low#[i]      - muLow
    varLow    = varLow    + d*d
    d = lowmid#[i]   - muLowMid
    varLowMid = varLowMid + d*d
    d = dlow#[i]     - muDLow
    varDLow   = varDLow   + d*d
    d = dbroad#[i]   - muDBroad
    varDBroad = varDBroad + d*d
endfor
varLow    = varLow    / n
varLowMid = varLowMid / n
varDLow   = varDLow   / n
varDBroad = varDBroad / n

if varLow    <= 1e-12
    varLow    = 1e-12
endif
if varLowMid <= 1e-12
    varLowMid = 1e-12
endif
if varDLow   <= 1e-12
    varDLow   = 1e-12
endif
if varDBroad <= 1e-12
    varDBroad = 1e-12
endif

sdLow    = varLow    ^ 0.5
sdLowMid = varLowMid ^ 0.5
sdDLow   = varDLow   ^ 0.5
sdDBroad = varDBroad ^ 0.5

for i from 1 to n
    zLow#[i]    = (low#[i]    - muLow)    / sdLow
    zLowMid#[i] = (lowmid#[i] - muLowMid) / sdLowMid
    zDLow#[i]   = (dlow#[i]   - muDLow)   / sdDLow
    zDBroad#[i] = (dbroad#[i] - muDBroad) / sdDBroad
    if zDBroad#[i] > 0
        zDBroadPos#[i] = zDBroad#[i]
    else
        zDBroadPos#[i] = 0
    endif
endfor

# ----------------------- Scoring & detection -----------------------------------
for i from 1 to n
    score#[i] = wLow * zLow#[i] + wFlux * zDBroadPos#[i] - wLowMidPen * zLowMid#[i]
endfor

Create TextGrid: xmin, xmax, "dummy", ""
Rename: "KD_TextGrid"
Insert point tier: 1, tierName$
Remove tier: 2

lastHitTime = xmin - refractory

for i from 2 to n-1
    t = time#[i]
    if (score#[i] > scoreThresh) and (zDLow#[i] > dLowThresh) and (t - lastHitTime >= refractory)
        imax = i
        smax = score#[i]
        if score#[i-1] > smax
            imax = i-1
            smax = score#[i-1]
        endif
        if score#[i+1] > smax
            imax = i+1
            smax = score#[i+1]
        endif
        thit = time#[imax]
        thit = thit + timeOffset
        selectObject: "TextGrid KD_TextGrid"
        Insert point: 1, thit, mark$
        lastHitTime = thit
    endif
endfor

# ----------------------- Place bass sample at kick positions ------------------
selectObject: "TextGrid KD_TextGrid"
numKicks = Get number of points: 1

appendInfoLine: "Detected ", string$(numKicks), " kicks"
appendInfoLine: "Placing bass sample at kick positions..."

# Create copy of original and add bass samples to it
selectObject: "Sound " + orig$
Copy: orig$ + "_with_bass"
withBass$ = orig$ + "_with_bass"

if numKicks > 0
    selectObject: "Sound " + sample$
    sampleSamps = Get number of samples
    sampleChannels = Get number of channels
    
    selectObject: "Sound " + withBass$
    totalSamps = Get number of samples
    nChannels = Get number of channels
    srate = Get sampling frequency
    
    # Add bass sample at each kick position (mix with original)
    for k from 1 to numKicks
        selectObject: "TextGrid KD_TextGrid"
        kickTime = Get time of point: 1, k
        
        # Calculate insertion position
        insertSamp = round(kickTime * srate) + 1
        
        # Add the bass sample at this position
        for s from 1 to sampleSamps
            if insertSamp + s - 1 <= totalSamps and insertSamp + s - 1 >= 1
                selectObject: "Sound " + sample$
                for ch from 1 to min(sampleChannels, nChannels)
                    val = Get value at sample number: ch, s
                    selectObject: "Sound " + withBass$
                    existingVal = Get value at sample number: ch, insertSamp + s - 1
                    Set value at sample number: ch, insertSamp + s - 1, existingVal + val
                endfor
            endif
        endfor
    endfor
endif

# ----------------------- Cleanup -----------------------------------------------
removeObject: "Sound " + work$
removeObject: "Sound KD_low"
removeObject: "Sound KD_lowmid"
removeObject: "Intensity KD_I_broad"
removeObject: "Intensity KD_I_low"
removeObject: "Intensity KD_I_lowmid"

# ----------------------- Finish ------------------------------------------------
plusObject: "Sound " + withBass$
Play

appendInfoLine: ""
appendInfoLine: "=== Results ==="
appendInfoLine: "Original loop: '", orig$, "' (untouched)"
appendInfoLine: "Bass sample: '", sample$, "'"
appendInfoLine: "TextGrid: 'KD_TextGrid' (", string$(numKicks), " kick positions)"
appendInfoLine: "Mixed: '", withBass$, "'"
appendInfoLine: "  = Original loop + bass sample at each kick position"