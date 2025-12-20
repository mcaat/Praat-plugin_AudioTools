# ============================================================
# ALL_FEATURES_6in1_FIXED_NO_BREAK.praat
# Same as previous, but WITHOUT using "break" (some Praat versions don't support it)
# ============================================================

clearinfo

number_of_selected_sounds = numberOfSelected ("Sound")
if number_of_selected_sounds = 0
    writeInfoLine: "ERROR: Please select one or more Sound objects first."
    exit
endif

for i to number_of_selected_sounds
    sound'i' = selected ("Sound", i)
endfor

Create Table with column names: "AudioTools_Results", number_of_selected_sounds, "Filename IntensityMean_dB HarmonicityMean_dB JitterLocal RollOff85_Hz Flatness Roughness SPR_dB SPR_LowBandMax_dBHz SPR_HighBandMax_dBHz"

appendInfoLine: "AudioTools batch analysis"
appendInfoLine: "======================="
appendInfoLine: "Files: ", number_of_selected_sounds
appendInfoLine: ""
appendInfoLine: "Filename", tab$, "Intensity", tab$, "Harmonicity", tab$, "Jitter", tab$, "RollOff85", tab$, "Flatness", tab$, "Roughness", tab$, "SPR"
appendInfoLine: "--------------------------------------------------------------------------------"

for s from 1 to number_of_selected_sounds
    currentSoundID = sound's'
    selectObject: currentSoundID
    name$ = selected$("Sound")

    intensityMean = undefined
    harmonicityMean = undefined
    jitterLocal = undefined
    rolloff85 = undefined
    flatness = undefined
    roughness = undefined
    spr = undefined
    lowbandmax = undefined
    highbandmax = undefined

    # 1) INTENSITY
    selectObject: currentSoundID
    To Intensity: 100, 0, "yes"
    intensityID = selected()
    intensityMean = Get mean: 0, 0, "energy"
    selectObject: intensityID
    Remove
    selectObject: currentSoundID

    # 2) HARMONICITY (cc)
    selectObject: currentSoundID
    To Harmonicity (cc): 0.01, 75, 0.1, 1
    harmID = selected()
    harmonicityMean = Get mean: 0, 0
    selectObject: harmID
    Remove
    selectObject: currentSoundID

    # 3) JITTER (local)
    selectObject: currentSoundID
    To PointProcess (extrema): 1, "yes", "no", "sinc70"
    ppID = selected()
    jitterLocal = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3
    selectObject: ppID
    Remove
    selectObject: currentSoundID

    # 4) SPECTRAL ROLL-OFF (85% energy) - NO break
    selectObject: currentSoundID
    To Spectrum... "yes"
    specID = selected()

    nBins = Get number of bins
    totalEnergy = 0
    for b from 1 to nBins
        amp = Get real value in bin: b
        totalEnergy += amp^2
    endfor

    if totalEnergy >= 1e-12
        targetEnergy = 0.85 * totalEnergy
        cumEnergy = 0
        found = 0
        for b from 1 to nBins
            if found = 0
                amp = Get real value in bin: b
                cumEnergy += amp^2
                if cumEnergy >= targetEnergy
                    rolloff85 = Get frequency from bin number: b
                    found = 1
                endif
            endif
        endfor
    endif

    selectObject: specID
    Remove
    selectObject: currentSoundID

    # 5) SPECTRAL FLATNESS + ROUGHNESS (80–5000 Hz)
    selectObject: currentSoundID
    To Spectrum... "yes"
    spec2ID = selected()

    minFreq = 80
    maxFreq = 5000

    nBins = Get number of bins
    binWidth = Get bin width

    lnSum = 0
    linearSum = 0
    validBins = 0

    roughnessSum = 0
    roughnessBins = 0

    for b from 1 to nBins
        freq = (b - 1) * binWidth
        if freq >= minFreq and freq <= maxFreq
            amp = Get real value in bin: b
            power = amp * amp
            if power < 1e-12
                power = 1e-12
            endif

            lnSum += ln(power)
            linearSum += power
            validBins += 1

            if b > 1 and b < nBins
                ampPrev = Get real value in bin: b - 1
                ampNext = Get real value in bin: b + 1
                roughnessSum += abs(amp - (ampPrev + ampNext) / 2)
                roughnessBins += 1
            endif
        endif
    endfor

    if validBins > 0
        flatness = exp(lnSum / validBins) / (linearSum / validBins)
    endif

    if roughnessBins > 0
        roughness = roughnessSum / roughnessBins
    endif

    selectObject: spec2ID
    Remove
    selectObject: currentSoundID

    # 6) SPR (Tabulate)
    selectObject: currentSoundID
    To Spectrum... "yes"
    spec3ID = selected()

    Tabulate: "no", "yes", "no", "no", "no", "yes"
    tabID = selected()

    selectObject: tabID
    Extract rows where column (number): "freq(Hz)", "greater than or equal to", 50
    low1ID = selected()
    Extract rows where column (number): "freq(Hz)", "less than or equal to", 2000
    low2ID = selected()
    lowbandmax = Get maximum: "pow(dB/Hz)"

    selectObject: tabID
    Extract rows where column (number): "freq(Hz)", "greater than or equal to", 2000
    high1ID = selected()
    Extract rows where column (number): "freq(Hz)", "less than or equal to", 4000
    high2ID = selected()
    highbandmax = Get maximum: "pow(dB/Hz)"

    spr = lowbandmax - highbandmax

    selectObject: spec3ID
    plusObject: tabID
    plusObject: low1ID
    plusObject: low2ID
    plusObject: high1ID
    plusObject: high2ID
    Remove

    selectObject: currentSoundID

    # WRITE TABLE
    selectObject: "Table AudioTools_Results"
    Set string value:  s, "Filename", name$

    Set numeric value: s, "IntensityMean_dB", intensityMean
    Set numeric value: s, "HarmonicityMean_dB", harmonicityMean
    Set numeric value: s, "JitterLocal", jitterLocal

    Set numeric value: s, "RollOff85_Hz", rolloff85
    Set numeric value: s, "Flatness", flatness
    Set numeric value: s, "Roughness", roughness

    Set numeric value: s, "SPR_dB", spr
    Set numeric value: s, "SPR_LowBandMax_dBHz", lowbandmax
    Set numeric value: s, "SPR_HighBandMax_dBHz", highbandmax

    appendInfoLine: name$, tab$, fixed$(intensityMean, 3), tab$, fixed$(harmonicityMean, 3), tab$, fixed$(jitterLocal, 6), tab$, fixed$(rolloff85, 2), tab$, fixed$(flatness, 6), tab$, fixed$(roughness, 6), tab$, fixed$(spr, 3)

endfor

selectObject: sound1
for i from 2 to number_of_selected_sounds
    plusObject: sound'i'
endfor

appendInfoLine: ""
appendInfoLine: "Done."
appendInfoLine: "Created: Table AudioTools_Results"
appendInfoLine: "Export: select the Table -> Save -> Save as comma-separated file..."
