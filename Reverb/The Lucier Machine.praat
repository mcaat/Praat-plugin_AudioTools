# ============================================================
# Praat AudioTools - The Lucier Machine 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Lucier-style "I Am Sitting in a Room" - Physically Model
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# =================================================================
# Lucier-style "I Am Sitting in a Room" - Physically Model
# =================================================================

# =================================================================
# USER FORM
# =================================================================

form Lucier Simulation (Physical Model)
    comment ═══ Room Acoustics ═══
    positive IR_duration_seconds 1.5
    positive RT60_seconds 1.0
    natural Number_of_reflections 1000
    
    comment ═══ Microphone Placement ═══
    positive Pre_delay_seconds 0.01
    real Microphone_proximity_gain 0.95
    comment (0.95-0.99 = Mic very close to speaker, slow degradation)
    comment (0.70-0.90 = Mic far from speaker, faster degradation)
    
    comment ═══ Simulation Settings ═══
    natural Number_of_iterations 30
    positive Normalization_level 0.99
endform

# =================================================================
# VALIDATION
# =================================================================

if numberOfSelected("Sound") <> 1
    exitScript: "Error: Please select exactly one Sound object (the speech source)."
endif

soundID = selected("Sound")
soundName$ = selected$("Sound")
samplingFrequency = Get sampling frequency
originalDuration = Get total duration

# =================================================================
# GENERATE IMPULSE RESPONSE (PHYSICS BASED)
# =================================================================

writeInfoLine: "==================================================================="
appendInfoLine: "Lucier 'I Am Sitting in a Room' - Physical Simulation"
appendInfoLine: "==================================================================="
appendInfoLine: ""
appendInfoLine: "Generating impulse response..."
appendInfoLine: "  Duration: ", fixed$(iR_duration_seconds, 2), " s"
appendInfoLine: "  RT60: ", fixed$(rT60_seconds, 2), " s"
appendInfoLine: "  Reflections: ", number_of_reflections
appendInfoLine: "  Pre-delay: ", fixed$(pre_delay_seconds * 1000, 1), " ms"
appendInfoLine: "  Microphone proximity gain: ", fixed$(microphone_proximity_gain, 3)
appendInfoLine: "  → Direct path: ", fixed$(microphone_proximity_gain * 100, 1), "%"
appendInfoLine: "  → Room reflections: ", fixed$((1-microphone_proximity_gain) * 100, 1), "%"
appendInfoLine: ""

# 1. Create the empty room timeline
Create Sound from formula: "IR", 1, 0, iR_duration_seconds, samplingFrequency, "0"
irID = selected("Sound")
totalSamples = Get number of samples

# 2. THE DIRECT PATH (The "Dry" signal physically traveling to mic)
directSample = round(pre_delay_seconds * samplingFrequency)
if directSample < 1
    directSample = 1
endif
if directSample <= totalSamples
    Set value at sample number: 1, directSample, microphone_proximity_gain
endif

# 3. THE REFLECTIONS (The "Room" sound)
decayCoeff = 6.9078 / rT60_seconds

# Reflection max volume is the remainder of the energy
reflectionMaxAmp = 1.0 - microphone_proximity_gain

if reflectionMaxAmp < 0.05
    reflectionMaxAmp = 0.05
endif

# Generate random reflections
for i from 1 to number_of_reflections
    # Random time *after* the direct sound
    randTime = pre_delay_seconds + randomUniform(0, iR_duration_seconds - pre_delay_seconds)
    
    # Calculate natural exponential decay for this reflection
    timeDelta = randTime - pre_delay_seconds
    naturalDecay = exp(-timeDelta * decayCoeff)
    
    # Randomize phase and amplitude
    amp = randomGauss(0, 0.3) * naturalDecay * reflectionMaxAmp
    
    # Place in buffer
    sampIdx = round(randTime * samplingFrequency)
    
    # Safety check to ensure we don't write outside the sound buffer
    if sampIdx >= 1 and sampIdx <= totalSamples
        oldVal = Get value at sample number: 1, sampIdx
        Set value at sample number: 1, sampIdx, oldVal + amp
    endif
endfor

# 4. Normalize the IR so it doesn't distort
selectObject: irID
Scale peak: 0.9
Rename: "IR_" + soundName$

appendInfoLine: "Impulse response generated successfully."
appendInfoLine: ""

# =================================================================
# ITERATIVE CONVOLUTION LOOP
# =================================================================

appendInfoLine: "Starting iterative convolution..."
appendInfoLine: "  Number of iterations: ", number_of_iterations
appendInfoLine: "  Normalization level: ", fixed$(normalization_level, 2)
appendInfoLine: ""

selectObject: soundID
currentID = Copy: soundName$ + "_iteration_0"

for iteration from 1 to number_of_iterations
    appendInfoLine: "Processing iteration ", iteration, "/", number_of_iterations, "..."
    
    # 1. Convolve (Physics simulation of sound playing in room)
    selectObject: currentID
    plusObject: irID
    convolveID = Convolve: "sum", "zero"
    
    # 2. Crop to original duration (prevent infinite growth)
    selectObject: convolveID
    Extract part: 0, originalDuration, "rectangular", 1, "no"
    croppedID = selected("Sound")
    
    # 3. Cleanup previous iteration
    removeObject: currentID, convolveID
    
    # 4. Normalize to prevent runaway gain
    selectObject: croppedID
    Scale peak: normalization_level
    
    # 5. Rename and prepare for next iteration
    Rename: soundName$ + "_iteration_" + string$(iteration)
    currentID = selected("Sound")
    
    # Progress indicator
    if iteration mod 5 = 0 or iteration = number_of_iterations
        selectObject: currentID
        currentPeak = Get absolute extremum: 0, 0, "None"
        appendInfoLine: "  → Peak level: ", fixed$(currentPeak, 4)
    endif
endfor

# =================================================================
# CLEANUP AND FINALIZATION
# =================================================================

appendInfoLine: ""
appendInfoLine: "Cleaning up intermediate objects..."

removeObject: irID

selectObject: currentID
finalPeak = Get absolute extremum: 0, 0, "None"
finalDuration = Get total duration
Play

# Final report
appendInfoLine: ""
appendInfoLine: "==================================================================="
appendInfoLine: "Processing complete!"
appendInfoLine: "==================================================================="
appendInfoLine: "Original sound: ", soundName$
appendInfoLine: "Final sound: ", selected$("Sound")
appendInfoLine: "Original duration: ", fixed$(originalDuration, 3), " s"
appendInfoLine: "Final duration: ", fixed$(finalDuration, 3), " s"
appendInfoLine: "Final peak level: ", fixed$(finalPeak, 4)
appendInfoLine: ""
appendInfoLine: "Physical model parameters:"
appendInfoLine: "  Microphone proximity: ", fixed$(microphone_proximity_gain, 3)
appendInfoLine: "  RT60: ", fixed$(rT60_seconds, 2), " s"
appendInfoLine: "  Iterations completed: ", number_of_iterations
appendInfoLine: ""
appendInfoLine: "TIPS:"
appendInfoLine: "  • If speech fades too quickly: increase proximity (try 0.97-0.99)"
appendInfoLine: "  • If effect too subtle: decrease proximity (try 0.85-0.92)"
appendInfoLine: "  • For classic Lucier: proximity 0.90-0.92, 25-30 iterations"
appendInfoLine: "==================================================================="