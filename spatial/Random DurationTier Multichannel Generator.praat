# ============================================================
# Praat AudioTools - Random DurationTier Multichannel Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Random DurationTier Multichannel Generator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Random DurationTier Multichannel Generator
# ----------------------- USER PARAMETERS --------------------------------------
nTiers        = 8
nInteriorPts  = 10
variability   = 0.40
minFactor     = 0.50
maxFactor     = 2.00
namePrefix$   = "DurRand_"
outStem$      = "dur8"
fmin          = 75
fmax          = 600
timestep      = 0.01
# -----------------------------------------------------------------------------


# ---- Require exactly one input Sound selected ----
if numberOfSelected ("Sound") <> 1
    exit ("Please select exactly ONE Sound before running this script.")
endif
orig = selected ("Sound")

# Domain for tiers
tmin = Get start time
tmax = Get end time

# Random-walk step sigma
stepSigma = variability / sqrt(nInteriorPts + 1)

# --------- Pre-create 8 DurationTiers (same length, start/end at 1.0) ---------
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
for k to nTiers
    selectObject: orig
    dupName$ = outStem$ + "_copy" + fixed$(k,0)
    Copy: dupName$
    dupId[k] = selected ("Sound")   ; remember duplicate Sound id

    To Manipulation: timestep, fmin, fmax
    man = selected ("Manipulation")

    selectObject: man
    plusObject: tierId[k]
    Replace duration tier

    selectObject: man
    Get resynthesis (overlap-add)
    Rename: outStem$ + "_var" + fixed$(k,0)
    resId[k] = selected ("Sound")

    # --- remove the Manipulation and the duplicate Sound copy ---
    selectObject: man
    Remove
    selectObject: dupId[k]
    Remove
endfor

# ----------------- Combine all variants to a multi-channel Sound --------------
for k to nTiers
    if k = 1
        selectObject: resId[k]
    else
        plusObject: resId[k]
    endif
endfor
Combine to stereo
Rename: outStem$ + "_8ch"

# Scale final result
Scale peak: 0.99
Play

# ----------------- Cleanup: remove mono variants and tiers, keep original+result
for k to nTiers
    selectObject: resId[k]
    Remove
    selectObject: tierId[k]
    Remove
endfor
