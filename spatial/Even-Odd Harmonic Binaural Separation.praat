# PRAAT Script: Even-Odd Harmonic Separation (Clean Version)
form Parameters
    positive Fundamental_frequency_(F0) 100
    positive Maximum_frequency 5000
    positive Filter_width_factor 0.4
    word Output_suffix _separated
    boolean Auto_detect_F0 1
endform

if numberOfSelected("Sound") = 0
    exitScript: "Please select a Sound object first."
endif

sound = selected("Sound")
soundName$ = selected$("Sound")
selectObject: sound
totalDuration = Get total duration
samplingFrequency = Get sampling frequency

# Make a working copy
selectObject: sound
extracted = Copy: soundName$ + "_working"

# Auto-detect F0
if auto_detect_F0
    selectObject: extracted
    pitch = To Pitch: 0.01, 75, 600
    f0 = Get mean: 0, 0, "Hertz"
    if f0 = undefined
        appendInfoLine: "Warning: Could not detect F0, using specified value: ", fundamental_frequency
        f0 = fundamental_frequency
    else
        appendInfoLine: "Detected F0: ", fixed$(f0, 2), " Hz"
    endif
    removeObject: pitch
else
    f0 = fundamental_frequency
    appendInfoLine: "Using specified F0: ", f0, " Hz"
endif

# Calculate filter widths
rejectWidth = f0 * filter_width_factor
maxHarmonic = floor(maximum_frequency / f0)

appendInfoLine: "Notch width: ±", fixed$(rejectWidth, 1), " Hz"
appendInfoLine: "Processing up to harmonic ", maxHarmonic

# Create ODD harmonics (remove EVEN)
appendInfoLine: "Creating odd harmonics (removing even)..."
selectObject: extracted
oddSound = Copy: "odd_temp"

harmonic = 2
while harmonic <= maxHarmonic
    freq = harmonic * f0
    
    if freq > samplingFrequency/2 - 200
        goto DONE_ODD
    endif
    
    lowFreq = freq - rejectWidth
    highFreq = freq + rejectWidth
    
    if lowFreq < 5
        lowFreq = 5
    endif
    
    selectObject: oddSound
    filtered = Filter (stop Hann band): lowFreq, highFreq, 100
    
    selectObject: oddSound
    Remove
    oddSound = filtered
    
    harmonic = harmonic + 2
endwhile

label DONE_ODD

# Create EVEN harmonics (remove ODD)
appendInfoLine: "Creating even harmonics (removing odd)..."
selectObject: extracted
evenSound = Copy: "even_temp"

harmonic = 1
while harmonic <= maxHarmonic
    freq = harmonic * f0
    
    if freq > samplingFrequency/2 - 200
        goto DONE_EVEN
    endif
    
    lowFreq = freq - rejectWidth
    highFreq = freq + rejectWidth
    
    if lowFreq < 5
        lowFreq = 5
    endif
    
    selectObject: evenSound
    filtered = Filter (stop Hann band): lowFreq, highFreq, 100
    
    selectObject: evenSound
    Remove
    evenSound = filtered
    
    harmonic = harmonic + 2
endwhile

label DONE_EVEN

# Normalize
selectObject: oddSound
Scale peak: 0.99

selectObject: evenSound
Scale peak: 0.99

# Create STEREO output: Odd=LEFT, Even=RIGHT
selectObject: oddSound, evenSound
stereoOutput = Combine to stereo
Rename: soundName$ + output_suffix$

# Cleanup - remove everything except original and result
selectObject: extracted, oddSound, evenSound
Remove

# Select original and result
selectObject: sound, stereoOutput

appendInfoLine: ""
appendInfoLine: "=== Complete ==="
appendInfoLine: "F0: ", fixed$(f0, 2), " Hz"
appendInfoLine: ""
appendInfoLine: "Result: ", soundName$ + output_suffix$
appendInfoLine: "  Left channel = Odd harmonics (1,3,5,7...)"
appendInfoLine: "  Right channel = Even harmonics (2,4,6,8...)"
appendInfoLine: ""
appendInfoLine: "Listen with headphones for binaural effect!"