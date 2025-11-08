# ============================================================
# Praat AudioTools - Adaptive Transient Decomposition.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Adaptive Transient Decomposition
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================
# FAST Chunked Adaptive Transient Decomposition (mono)
# - RMS per-frame thresholds on |residual| (no quantile / no self / no ternary)
# - Direct write to outputs when useInpainting = 0 (big speedup)
# - Detector stride to skip samples (another big speedup)
# - Progress printed (clearinfo)
#
# Outputs (same length as input):
#   <name>_transients  : detected bursts (optionally inpainted)
#   <name>_residual    : original - transients
# ============================================

form "Adaptive Transients (FAST, Chunked, Mono)"
    comment "LPC (ms scales with SR)"
    real    lpcOrder_ms           1.6
    positive windowSize_ms        10
    positive hopSize_ms           2.5
    positive preEmphasis_Hz       50
    comment "Detection via RMS on |residual| (per frame)"
    real    highRmsFactor         1.50
    real    lowRmsFactor          1.10
    positive burstPadding_ms      0.8
    comment "Speed controls"
    boolean useInpainting         0
    integer detectorStride        4
    positive chunkLength_s        8.0
    integer  progressEveryFrames  40
    integer  progressEverySamples 20000
endform

if numberOfSelected ("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

clearinfo
writeInfoLine: "Adaptive Transients — FAST mode starting..."

origId = selected ("Sound")
selectObject: origId
origName$ = selected$ ("Sound")
sr       = Get sampling frequency
durTotal = Get total duration
nch      = Get number of channels
nSampTot = Get number of samples

appendInfoLine: "File: ", origName$
appendInfoLine: "SR: ", sr, " Hz   |   Len: ", fixed$(durTotal,3), " s"
appendInfoLine: " "

# ---- mono only ----
if nch = 2
    appendInfoLine: "Converting stereo to mono..."
    monoId = Convert to mono
    selectObject: origId
    Remove
    origId = monoId
    selectObject: origId
elsif nch > 2
    exitScript: "Sound must be mono or stereo"
endif

# ---- params ----
winS   = windowSize_ms / 1000
hopS   = hopSize_ms    / 1000
padS   = burstPadding_ms / 1000
padN   = max(0, round(padS * sr))
winN   = max(1, round(winS * sr))
hopN   = max(1, round(hopS * sr))
if detectorStride < 1
    detectorStride = 1
endif

# ---- LPC order caps ----
lpcOrder = round(lpcOrder_ms * sr / 1000)
if lpcOrder < 8
    lpcOrder = 8
endif
maxOrder = max(8, round(0.4 * winN))
if lpcOrder > maxOrder
    lpcOrder = maxOrder
endif
if lpcOrder > 50
    lpcOrder = 50
endif

appendInfoLine: "LPC order: ", lpcOrder, " (~", fixed$(lpcOrder_ms,1), " ms)  |  Win/Hop: ", fixed$(winS*1000,1), "/", fixed$(hopS*1000,1), " ms"
appendInfoLine: "RMS factors H/L: ", fixed$(highRmsFactor,2), " / ", fixed$(lowRmsFactor,2), "  |  Pad: ", fixed$(padS*1000,1), " ms"

# print inpainting state without ternary
if useInpainting = 1
    inpaint$ = "on"
else
    inpaint$ = "off"
endif
appendInfoLine: "Inpainting: ", inpaint$, "  |  Detector stride: ", detectorStride
appendInfoLine: "Chunk: ", fixed$(chunkLength_s,1), " s"
appendInfoLine: " "

# ---- allocate outputs ----
appendInfoLine: "Allocating outputs..."
selectObject: origId
transAll = Copy: "transients_all"
residAll = Copy: "residual_all"
selectObject: transAll
for gi from 1 to nSampTot
    Set value at sample number: 1, gi, 0
endfor
selectObject: residAll
for gi from 1 to nSampTot
    Set value at sample number: 1, gi, 0
endfor

# ---- state across chunks ----
burstActivePrev = 0
gateOnTotal = 0

# ---- chunk loop ----
t0 = 0
chunkIndex = 0
nChunks = floor(durTotal / chunkLength_s)
if nChunks * chunkLength_s < durTotal
    nChunks = nChunks + 1
endif

while t0 < durTotal
    chunkIndex = chunkIndex + 1
    t1 = t0 + chunkLength_s
    if t1 > durTotal
        t1 = durTotal
    endif

    gStart = round(t0 * sr) + 1
    gEnd   = round(t1 * sr)
    if gEnd < gStart
        break
    endif

    appendInfoLine: "Chunk ", chunkIndex, "/", nChunks, "  [", fixed$(t0,2), "–", fixed$(t1,2), " s]"

    # Extract chunk
    selectObject: origId
    chunk = Extract part: t0, t1, "rectangular", 1, "yes"
    nSampChunk = Get number of samples
    lenChunk   = Get total duration

    # LPC + residual
    selectObject: chunk
    lpc = To LPC (burg): lpcOrder, winS, hopS, preEmphasis_Hz
    selectObject: chunk
    plusObject: lpc
    residual = Filter (inverse)

    # |residual|
    selectObject: residual
    absRes = Copy: "absRes"
    selectObject: absRes
    for i from 1 to nSampChunk
        v = Get value at sample number: 1, i
        if v < 0
            v = -v
        endif
        Set value at sample number: 1, i, v
    endfor

    # Gate init
    selectObject: residual
    gate = Copy: "gate"
    selectObject: gate
    for i from 1 to nSampChunk
        Set value at sample number: 1, i, 0
    endfor

    # Per-frame thresholds (RMS on |residual|) with hysteresis
    nFrames = max(1, floor((lenChunk - winS) / hopS) + 1)
    burstActive = burstActivePrev

    for f from 0 to nFrames - 1
        tc0 = f * hopN + 1
        tc1 = tc0 + winN - 1
        if tc1 > nSampChunk
            tc1 = nSampChunk
        endif

        # RMS(|res|) over frame
        sumSq = 0
        for i from tc0 to tc1
            selectObject: absRes
            v = Get value at sample number: 1, i
            sumSq = sumSq + v * v
        endfor
        count = tc1 - tc0 + 1
        if count < 1
            count = 1
        endif
        rms = sqrt(sumSq / count)
        if rms = 0
            rms = 1e-6
        endif

        thHigh = highRmsFactor * rms
        thLow  = lowRmsFactor  * rms
        if thLow > thHigh
            thLow = thHigh * 0.8
        endif

        # Hysteresis, STRIDED detection and paint over block
        i = tc0
        while i <= tc1
            selectObject: absRes
            av = Get value at sample number: 1, i

            selectObject: gate
            if burstActive = 0
                if av > thHigh
                    burstActive = 1
                    s0 = i
                    s1 = i + detectorStride - 1
                    if s1 > tc1
                        s1 = tc1
                    endif
                    for j from s0 to s1
                        Set value at sample number: 1, j, 1
                    endfor
                endif
            else
                if av < thLow
                    burstActive = 0
                else
                    s0 = i
                    s1 = i + detectorStride - 1
                    if s1 > tc1
                        s1 = tc1
                    endif
                    for j from s0 to s1
                        Set value at sample number: 1, j, 1
                    endfor
                endif
            endif

            i = i + detectorStride
        endwhile

        if (f mod progressEveryFrames) = 0
            percentFrames = round(100 * (f+1) / nFrames)
            appendInfoLine: "   Frames: ", (f+1), "/", nFrames, " (", percentFrames, "%)"
        endif
    endfor

    burstActivePrev = burstActive

    # Pad gate (±padN)
    selectObject: gate
    gatePad = Copy: "gatePad"
    for i from 1 to nSampChunk
        selectObject: gate
        gv = Get value at sample number: 1, i
        if gv > 0
            s0 = i - padN
            if s0 < 1
                s0 = 1
            endif
            s1 = i + padN
            if s1 > nSampChunk
                s1 = nSampChunk
            endif
            selectObject: gatePad
            for j from s0 to s1
                Set value at sample number: 1, j, 1
            endfor
        endif
    endfor

    # ---------- FAST WRITE OUT ----------
    if useInpainting = 0
        localGateOn = 0
        for i from 1 to nSampChunk
            gi = gStart + i - 1
            if gi >= 1 and gi <= nSampTot
                selectObject: gatePad
                gv = Get value at sample number: 1, i
                if gv > 0
                    localGateOn = localGateOn + 1
                endif

                selectObject: residual
                rv = Get value at sample number: 1, i
                if gv = 0
                    tv = 0
                else
                    tv = rv
                endif

                selectObject: chunk
                ov = Get value at sample number: 1, i
                rvOut = ov - tv

                selectObject: transAll
                Set value at sample number: 1, gi, tv
                selectObject: residAll
                Set value at sample number: 1, gi, rvOut

                if (i mod progressEverySamples) = 0
                    pSamp = round(100 * i / nSampChunk)
                    appendInfoLine: "   Writing: ", i, "/", nSampChunk, " (", pSamp, "%)"
                endif
            endif
        endfor
        gateOnTotal = gateOnTotal + localGateOn

    else
        # Inpainting branch (slower)
        selectObject: residual
        gated = Copy: "gated"
        localGateOn = 0
        for i from 1 to nSampChunk
            selectObject: gatePad
            gv = Get value at sample number: 1, i
            if gv > 0
                localGateOn = localGateOn + 1
            endif
            selectObject: residual
            rv = Get value at sample number: 1, i
            selectObject: gated
            if gv > 0
                Set value at sample number: 1, i, rv
            else
                Set value at sample number: 1, i, 0
            endif
        endfor
        gateOnTotal = gateOnTotal + localGateOn

        selectObject: gated
        plusObject: lpc
        transChunk = Filter: "no"

        for i from 1 to nSampChunk
            gi = gStart + i - 1
            if gi >= 1 and gi <= nSampTot
                selectObject: transChunk
                tv = Get value at sample number: 1, i
                selectObject: chunk
                ov = Get value at sample number: 1, i
                rvOut = ov - tv

                selectObject: transAll
                Set value at sample number: 1, gi, tv
                selectObject: residAll
                Set value at sample number: 1, gi, rvOut
            endif
        endfor

        selectObject: gated
        plusObject: transChunk
        Remove
    endif
    # ---------- end FAST WRITE OUT ----------

    appendInfoLine: "   Chunk ", chunkIndex, " done."

    # tidy per-chunk
    selectObject: lpc
    plusObject: residual
    plusObject: absRes
    plusObject: gate
    plusObject: gatePad
    plusObject: chunk
    Remove

    t0 = t1
endwhile

# finalize names
selectObject: transAll
Rename: origName$ + "_transients"
selectObject: residAll
Rename:  origName$ + "_residual"

# report coverage
gatePct = 100 * gateOnTotal / nSampTot
appendInfoLine: " "
appendInfoLine: "All chunks processed."
appendInfoLine: "Gate coverage: ", fixed$(gatePct,2), "% of samples flagged as transients"
appendInfoLine: "Outputs: ", origName$, "_transients  |  ", origName$, "_residual"

# Show all
selectObject: origId
plusObject: "Sound " + origName$ + "_transients"
plusObject: "Sound " + origName$ + "_residual"
