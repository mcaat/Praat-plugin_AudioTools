# ============================================================
# Praat AudioTools - Envelope Application.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Envelope Application
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Envelope Application
# Applies various envelope shapes to selected sound
# Displays result in Picture window

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sampling_frequency = Get sampling frequency

# Envelope type selection
beginPause: "Envelope Type"
    comment: "Select envelope type:"
    optionMenu: "Envelope type", 1
        option: "Linear"
        option: "Exponential"
        option: "Sine"
        option: "Welch"
        option: "Step"
        option: "Linen (ADSR simplified)"
        option: "Perc (Percussive)"
        option: "ADSR (full)"
clicked = endPause: "Cancel", "Apply", 2, 1

if clicked = 1
    exitScript()
endif

# Get parameters based on envelope type
if envelope_type = 1
    # Linear
    beginPause: "Linear Envelope Parameters"
        real: "Start level", 0.1
        real: "End level", 1.0
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 2
    # Exponential
    beginPause: "Exponential Envelope Parameters"
        real: "Start level", 0.1
        real: "End level", 1.0
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 3
    # Sine
    beginPause: "Sine Envelope Parameters"
        real: "Start level", 0.1
        real: "End level", 1.0
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 4
    # Welch
    beginPause: "Welch Envelope Parameters"
        real: "Start level", 0.1
        real: "End level", 1.0
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 5
    # Step
    beginPause: "Step Envelope Parameters"
        real: "Step time (s)", duration/2
        real: "Level before", 0.1
        real: "Level after", 1.0
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 6
    # Linen
    beginPause: "Linen Envelope Parameters"
        real: "Attack time (s)", 0.1
        real: "Sustain time (s)", duration - 0.3
        real: "Release time (s)", 0.2
        real: "Peak level", 1.0
        optionMenu: "Curve", 1
            option: "linear"
            option: "exponential"
            option: "sine"
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 7
    # Perc
    beginPause: "Percussive Envelope Parameters"
        real: "Attack time (s)", 0.01
        real: "Release time (s)", 0.5
        real: "Peak level", 1.0
        real: "Curve", -4
    endPause: "Cancel", "OK", 2, 1
    
elif envelope_type = 8
    # ADSR
    beginPause: "ADSR Envelope Parameters"
        real: "Attack time (s)", 0.02
        real: "Decay time (s)", 0.2
        real: "Sustain level", 0.7
        real: "Sustain time (s)", duration - 0.5
        real: "Release time (s)", 0.28
        real: "Peak level", 1.0
        real: "Curve", -4
    endPause: "Cancel", "OK", 2, 1
endif

# Build formula string for envelope visualization
if envelope_type = 1
    # Linear
    formula$ = "start_level + (end_level - start_level) * (x / duration)"
    formula$ = replace$(formula$, "start_level", string$(start_level), 0)
    formula$ = replace$(formula$, "end_level", string$(end_level), 0)
    formula$ = replace$(formula$, "duration", string$(duration), 0)
    
elif envelope_type = 2
    # Exponential
    formula$ = "start_level * (end_level / start_level) ^ (x / duration)"
    formula$ = replace$(formula$, "start_level", string$(start_level), 0)
    formula$ = replace$(formula$, "end_level", string$(end_level), 0)
    formula$ = replace$(formula$, "duration", string$(duration), 0)
    
elif envelope_type = 3
    # Sine
    formula$ = "start_level + (end_level - start_level) * (1 - cos((x/duration) * pi)) / 2"
    formula$ = replace$(formula$, "start_level", string$(start_level), 0)
    formula$ = replace$(formula$, "end_level", string$(end_level), 0)
    formula$ = replace$(formula$, "duration", string$(duration), 0)
    
elif envelope_type = 4
    # Welch
    formula$ = "if x/duration < 0.5 then start_level + (end_level - start_level) * (1 - (1 - 2*x/duration)^2) else end_level - (end_level - start_level) * (1 - (2*x/duration - 1)^2) endif"
    formula$ = replace$(formula$, "start_level", string$(start_level), 0)
    formula$ = replace$(formula$, "end_level", string$(end_level), 0)
    formula$ = replace$(formula$, "duration", string$(duration), 0)
    
elif envelope_type = 5
    # Step
    formula$ = "if x < step_time then level_before else level_after endif"
    formula$ = replace$(formula$, "step_time", string$(step_time), 0)
    formula$ = replace$(formula$, "level_before", string$(level_before), 0)
    formula$ = replace$(formula$, "level_after", string$(level_after), 0)
    
elif envelope_type = 6
    # Linen
    total_time = attack_time + sustain_time + release_time
    if curve = 1
        # Linear
        formula$ = "if x < attack_time then peak_level * (x / attack_time) else if x < attack_time + sustain_time then peak_level else if x < total_time then peak_level * (1 - (x - attack_time - sustain_time) / release_time) else 0 endif endif endif"
    elif curve = 2
        # Exponential
        formula$ = "if x < attack_time then peak_level * (1 - exp(-5 * x / attack_time)) else if x < attack_time + sustain_time then peak_level else if x < total_time then peak_level * exp(-5 * (x - attack_time - sustain_time) / release_time) else 0 endif endif endif"
    else
        # Sine
        formula$ = "if x < attack_time then peak_level * (1 - cos((x/attack_time) * pi)) / 2 else if x < attack_time + sustain_time then peak_level else if x < total_time then peak_level * (1 + cos(((x - attack_time - sustain_time)/release_time) * pi)) / 2 else 0 endif endif endif"
    endif
    formula$ = replace$(formula$, "attack_time", string$(attack_time), 0)
    formula$ = replace$(formula$, "sustain_time", string$(sustain_time), 0)
    formula$ = replace$(formula$, "release_time", string$(release_time), 0)
    formula$ = replace$(formula$, "peak_level", string$(peak_level), 0)
    formula$ = replace$(formula$, "total_time", string$(total_time), 0)
    
elif envelope_type = 7
    # Perc
    total_time = attack_time + release_time
    if curve < 0
        curve_inv = -1 / curve
        formula$ = "if x < attack_time then peak_level * (x / attack_time) ^ curve_inv else if x < total_time then peak_level * (1 - (x - attack_time) / release_time) ^ curve_inv else 0 endif endif"
        formula$ = replace$(formula$, "curve_inv", string$(curve_inv), 0)
    else
        curve_plus = curve + 1
        formula$ = "if x < attack_time then peak_level * (1 - (1 - x / attack_time) ^ curve_plus) else if x < total_time then peak_level * (1 - (x - attack_time) / release_time) ^ curve_plus else 0 endif endif"
        formula$ = replace$(formula$, "curve_plus", string$(curve_plus), 0)
    endif
    formula$ = replace$(formula$, "attack_time", string$(attack_time), 0)
    formula$ = replace$(formula$, "release_time", string$(release_time), 0)
    formula$ = replace$(formula$, "peak_level", string$(peak_level), 0)
    formula$ = replace$(formula$, "total_time", string$(total_time), 0)
    
elif envelope_type = 8
    # ADSR
    total_time = attack_time + decay_time + sustain_time + release_time
    sustain_amp = sustain_level * peak_level
    if curve < 0
        curve_inv = -1 / curve
        formula$ = "if x < attack_time then peak_level * (x / attack_time) ^ curve_inv else if x < attack_time + decay_time then peak_level - (peak_level - sustain_amp) * ((x - attack_time) / decay_time) ^ curve_inv else if x < attack_time + decay_time + sustain_time then sustain_amp else if x < total_time then sustain_amp * (1 - (x - attack_time - decay_time - sustain_time) / release_time) ^ curve_inv else 0 endif endif endif endif"
        formula$ = replace$(formula$, "curve_inv", string$(curve_inv), 0)
    else
        curve_plus = curve + 1
        formula$ = "if x < attack_time then peak_level * (1 - (1 - x / attack_time) ^ curve_plus) else if x < attack_time + decay_time then peak_level - (peak_level - sustain_amp) * (1 - (1 - (x - attack_time) / decay_time) ^ curve_plus) else if x < attack_time + decay_time + sustain_time then sustain_amp else if x < total_time then sustain_amp * (1 - (x - attack_time - decay_time - sustain_time) / release_time) ^ curve_plus else 0 endif endif endif endif"
        formula$ = replace$(formula$, "curve_plus", string$(curve_plus), 0)
    endif
    formula$ = replace$(formula$, "attack_time", string$(attack_time), 0)
    formula$ = replace$(formula$, "decay_time", string$(decay_time), 0)
    formula$ = replace$(formula$, "sustain_time", string$(sustain_time), 0)
    formula$ = replace$(formula$, "release_time", string$(release_time), 0)
    formula$ = replace$(formula$, "peak_level", string$(peak_level), 0)
    formula$ = replace$(formula$, "sustain_amp", string$(sustain_amp), 0)
    formula$ = replace$(formula$, "total_time", string$(total_time), 0)
endif

# Create Sound for envelope visualization using the formula
envelope_viz = Create Sound from formula: "envelope", 1, 0, duration, 1000, formula$

# Create IntensityTier for envelope application
tier = Create IntensityTier: "envelope", 0, duration

# Number of points for smooth IntensityTier
numPoints = 200
timeStep = duration / (numPoints - 1)

# Build IntensityTier with points
for i from 0 to numPoints - 1
    t = i * timeStep
    if t > duration
        t = duration
    endif
    progress = t / duration
    
    if envelope_type = 1
        amp = start_level + (end_level - start_level) * progress
    elif envelope_type = 2
        amp = start_level * (end_level / start_level) ^ progress
    elif envelope_type = 3
        amp = start_level + (end_level - start_level) * (1 - cos(progress * pi)) / 2
    elif envelope_type = 4
        if progress < 0.5
            amp = start_level + (end_level - start_level) * (1 - (1 - 2*progress)^2)
        else
            amp = end_level - (end_level - start_level) * (1 - (2*progress - 1)^2)
        endif
    elif envelope_type = 5
        amp = if t < step_time then level_before else level_after endif
    elif envelope_type = 6
        total_time = attack_time + sustain_time + release_time
        if t < attack_time
            phase = t / attack_time
            if curve = 1
                amp = peak_level * phase
            elif curve = 2
                amp = peak_level * (1 - exp(-5 * phase))
            else
                amp = peak_level * (1 - cos(phase * pi)) / 2
            endif
        elif t < attack_time + sustain_time
            amp = peak_level
        elif t < total_time
            phase = (t - attack_time - sustain_time) / release_time
            if curve = 1
                amp = peak_level * (1 - phase)
            elif curve = 2
                amp = peak_level * exp(-5 * phase)
            else
                amp = peak_level * (1 + cos(phase * pi)) / 2
            endif
        else
            amp = 0
        endif
    elif envelope_type = 7
        total_time = attack_time + release_time
        if t < attack_time
            phase = t / attack_time
            if curve < 0
                amp = peak_level * phase ^ (-1/curve)
            else
                amp = peak_level * (1 - (1 - phase) ^ (curve + 1))
            endif
        elif t < total_time
            phase = (t - attack_time) / release_time
            if curve < 0
                amp = peak_level * (1 - phase) ^ (-1/curve)
            else
                amp = peak_level * (1 - phase) ^ (curve + 1)
            endif
        else
            amp = 0
        endif
    elif envelope_type = 8
        total_time = attack_time + decay_time + sustain_time + release_time
        if t < attack_time
            phase = t / attack_time
            if curve < 0
                amp = peak_level * phase ^ (-1/curve)
            else
                amp = peak_level * (1 - (1 - phase) ^ (curve + 1))
            endif
        elif t < attack_time + decay_time
            phase = (t - attack_time) / decay_time
            if curve < 0
                amp = peak_level - (peak_level - sustain_level * peak_level) * phase ^ (-1/curve)
            else
                amp = peak_level - (peak_level - sustain_level * peak_level) * (1 - (1 - phase) ^ (curve + 1))
            endif
        elif t < attack_time + decay_time + sustain_time
            amp = sustain_level * peak_level
        elif t < total_time
            phase = (t - attack_time - decay_time - sustain_time) / release_time
            if curve < 0
                amp = sustain_level * peak_level * (1 - phase) ^ (-1/curve)
            else
                amp = sustain_level * peak_level * (1 - phase) ^ (curve + 1)
            endif
        else
            amp = 0
        endif
    endif
    
    # Add to IntensityTier (in dB)
    if amp > 0
        db = 20 * log10(amp)
    else
        db = -100
    endif
    
    selectObject: tier
    Add point: t, db
endfor

# Apply envelope to sound
selectObject: sound, tier
result = Multiply
Rename: sound_name$ + "_enveloped"

# Plot in Picture window
Erase all
Black

# Plot original sound
selectObject: sound
Select outer viewport: 0, 6, 0, 2
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Text left: "yes", "Original"

# Plot envelope (as Sound)
selectObject: envelope_viz
Select outer viewport: 0, 6, 2, 4
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Text left: "yes", "Envelope"

# Plot result
selectObject: result
Select outer viewport: 0, 6, 4, 6
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Marks bottom every: 1, 0.5, "yes", "yes", "no"
Text left: "yes", "Result"
Text bottom: "yes", "Time (s)"

# Clean up
removeObject: tier, envelope_viz
selectObject: result

writeInfoLine: "Envelope applied successfully!"
appendInfoLine: "Result displayed in Picture window"
Play