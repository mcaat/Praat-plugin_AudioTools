# ============================================================
# Praat AudioTools - Random DurationTier Multichannel Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025) - Enhanced with presets
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Random DurationTier Multichannel Generator with Presets
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Random DurationTier Multichannel Generator
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Subtle Variations (4 channels, gentle)
        option Standard Multi-texture (8 channels, moderate)
        option Extreme Time-stretch (8 channels, wild)
        option Dense Polyrhythm (12 channels, complex)
        option Minimal Duo (2 channels, subtle)
        option Chaotic Cluster (16 channels, maximum variation)
    comment ==== Channel Settings ====
    integer nTiers 8
    comment (number of output channels/variants)
    comment ==== Duration Variation ====
    integer nInteriorPts 10
    comment (number of control points per tier)
    positive variability 0.40
    comment (random walk variability, 0-1)
    positive minFactor 0.50
    comment (minimum time-stretch factor)
    positive maxFactor 2.00
    comment (maximum time-stretch factor)
    comment ==== Pitch Analysis ====
    positive fmin 75
    comment (minimum pitch for analysis in Hz)
    positive fmax 600
    comment (maximum pitch for analysis in Hz)
    positive timestep 0.01
    comment (time step for analysis in seconds)
    comment ==== Output Options ====
    word namePrefix DurRand_
    comment (prefix for DurationTier names)
    word outStem dur8
    comment (stem name for output files)
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Apply preset values if not Custom
if preset = 2
    # Subtle Variations
    nTiers = 4
    nInteriorPts = 8
    variability = 0.20
    minFactor = 0.80
    maxFactor = 1.25
    fmin = 75
    fmax = 600
    timestep = 0.01
elsif preset = 3
    # Standard Multi-texture
    nTiers = 8
    nInteriorPts = 10
    variability = 0.40
    minFactor = 0.50
    maxFactor = 2.00
    fmin = 75
    fmax = 600
    timestep = 0.01
elsif preset = 4
    # Extreme Time-stretch
    nTiers = 8
    nInteriorPts = 15
    variability = 0.60
    minFactor = 0.25
    maxFactor = 4.00
    fmin = 75
    fmax = 600
    timestep = 0.01
elsif preset = 5
    # Dense Polyrhythm
    nTiers = 12
    nInteriorPts = 20
    variability = 0.50
    minFactor = 0.40
    maxFactor = 2.50
    fmin = 75
    fmax = 600
    timestep = 0.008
elsif preset = 6
    # Minimal Duo
    nTiers = 2
    nInteriorPts = 6
    variability = 0.25
    minFactor = 0.70
    maxFactor = 1.50
    fmin = 75
    fmax = 600
    timestep = 0.01
elsif preset = 7
    # Chaotic Cluster
    nTiers = 16
    nInteriorPts = 25
    variability = 0.70
    minFactor = 0.20
    maxFactor = 5.00
    fmin = 75
    fmax = 600
    timestep = 0.008
endif

# ---- Require exactly one input Sound selected ----
if numberOfSelected ("Sound") <> 1
    exitScript: "Please select exactly ONE Sound before running this script."
endif
orig = selected ("Sound")
origName$ = selected$ ("Sound")

# Domain for tiers
tmin = Get start time
tmax = Get end time

writeInfoLine: "=== Random DurationTier Multichannel Generator ==="
appendInfoLine: "Processing: ", origName$
appendInfoLine: "Number of channels: ", nTiers
appendInfoLine: "Control points per channel: ", nInteriorPts
appendInfoLine: "Variability: ", fixed$(variability, 2)
appendInfoLine: "Time-stretch range: ", fixed$(minFactor, 2), " to ", fixed$(maxFactor, 2)
appendInfoLine: ""

# Random-walk step sigma
stepSigma = variability / sqrt(nInteriorPts + 1)

# --------- Pre-create DurationTiers (same length, start/end at 1.0) ---------
appendInfoLine: "Creating ", nTiers, " duration tiers..."
for k to nTiers
    tierName$ = namePrefix$ + fixed$(k,0)
    Create DurationTier: tierName$, tmin, tmax
    Add point: tmin, 1.0
    state = 1.0
    for j to nInteriorPts
        time = tmin + j * (tmax - tmin) / (nInteriorPts + 1)
        step = randomGauss (0, stepSigma)
        state = state + step
        if state < minFactor
            state = minFactor
        endif
        if state > maxFactor
            state = maxFactor
        endif
        Add point: time, state
    endfor
    Add point: tmax, 1.0
    tierId[k] = selected ("DurationTier")
endfor

# ----------------- For each tier, make a manipulated copy ---------------------
appendInfoLine: "Generating ", nTiers, " time-stretched variants..."
for k to nTiers
    selectObject: orig
    dupName$ = outStem$ + "_copy" + fixed$(k,0)
    Copy: dupName$
    dupId[k] = selected ("Sound")

    To Manipulation: timestep, fmin, fmax
    man = selected ("Manipulation")

    selectObject: man
    plusObject: tierId[k]
    Replace duration tier

    selectObject: man
    Get resynthesis (overlap-add)
    Rename: outStem$ + "_var" + fixed$(k,0)
    resId[k] = selected ("Sound")

    # Remove the Manipulation and the duplicate Sound copy
    selectObject: man
    Remove
    selectObject: dupId[k]
    Remove
    
    if k mod 4 = 0
        appendInfoLine: "  Processed ", k, " / ", nTiers, " channels..."
    endif
endfor

# ----------------- Combine all variants to a multi-channel Sound --------------
appendInfoLine: "Combining channels into multichannel output..."
for k to nTiers
    if k = 1
        selectObject: resId[k]
    else
        plusObject: resId[k]
    endif
endfor

# Handle different channel counts appropriately
if nTiers = 1
    # Single channel - just rename
    selectObject: resId[1]
    Rename: outStem$ + "_1ch"
elsif nTiers = 2
    Combine to stereo
    Rename: outStem$ + "_2ch"
else
    # 3+ channels - combine to stereo (Praat limitation)
    Combine to stereo
    Rename: outStem$ + "_" + fixed$(nTiers, 0) + "ch"
endif

multiChannelSound = selected ("Sound")

# Scale final result
Scale peak: scale_peak

appendInfoLine: ""
appendInfoLine: "Processing complete!"
appendInfoLine: "Output: ", selected$ ("Sound")
appendInfoLine: "Channels created: ", nTiers
appendInfoLine: "Peak amplitude: ", fixed$(scale_peak, 2)

# Play if requested
if play_after_processing
    Play
endif

# ----------------- Cleanup: remove mono variants and tiers -------------------
for k to nTiers
    selectObject: resId[k]
    Remove
    selectObject: tierId[k]
    Remove
endfor

# Select final result and original for comparison
selectObject: multiChannelSound
plusObject: orig

appendInfoLine: ""
appendInfoLine: "Ready! Both original and processed sounds are selected."