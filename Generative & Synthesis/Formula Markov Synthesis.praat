# ============================================================
# Praat AudioTools - Formula Markov Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sound synthesis or generative algorithm script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Direct Formula Markov Synthesis
    real Duration 12.0
    real Sampling_frequency 44100
    integer Number_states 8
    real Base_frequency 100
    real Event_density 5.0
    optionmenu Markov_type: 1
        option Simple_chain
        option Circular_chain
        option Random_walk
        option Biased_chain
    boolean Enable_harmonics yes
    boolean Enable_envelopes yes
    real Transition_randomness 0.3
endform

echo Building Markov Chain Formula...

# Initialize vectors (Required for Praat to use arrays)
state_freq# = zero#(number_states)
state_dur# = zero#(number_states)
state_amp# = zero#(number_states)
state_bw# = zero#(number_states)
state_history# = zero#(1000)

total_events = round(duration * event_density)
formula$ = "0"

current_state = randomInteger(1, number_states)

# Define State Properties
for state from 1 to number_states
    state_freq#[state] = base_frequency * (2^((state-1)/number_states))
    state_dur#[state] = 0.15 + (state/number_states) * 0.2
    state_amp#[state] = 0.4 + (state/number_states) * 0.4
    state_bw#[state] = 0.1 + (state/number_states) * 0.4
endfor

current_time = 0
event_count = 0
state_history#[1] = current_state

# Build the Giant Formula
while current_time < duration and event_count < total_events * 3
    event_count = event_count + 1
    
    current_freq = state_freq#[current_state]
    current_dur = state_dur#[current_state] * (0.7 + 0.6 * randomUniform(0,1))
    current_amp = state_amp#[current_state] * (0.8 + 0.4 * randomUniform(0,1))
    current_bw = state_bw#[current_state]
    
    if current_time + current_dur > duration
        current_dur = duration - current_time
    endif
    
    if current_dur > 0.01
        if enable_harmonics
            harmonic_content$ = ""
            for harmonic to 3
                harmonic_amp = current_amp / (harmonic * 1.5)
                harmonic_freq = current_freq * harmonic
                if harmonic = 1
                    harmonic_content$ = string$(harmonic_amp) + "*sin(2*pi*" + string$(harmonic_freq) + "*x)"
                else
                    harmonic_content$ = harmonic_content$ + " + " + string$(harmonic_amp) + "*sin(2*pi*" + string$(harmonic_freq) + "*x)"
                endif
            endfor
            wave_formula$ = "(" + harmonic_content$ + ")"
        else
            wave_formula$ = string$(current_amp) + "*sin(2*pi*" + string$(current_freq) + "*x)"
        endif
        
        if enable_envelopes
            envelope$ = " * (1 - cos(2*pi*(x-" + string$(current_time) + ")/" + string$(current_dur) + "))/2"
        else
            envelope$ = " * exp(-3*(x-" + string$(current_time) + ")/" + string$(current_dur) + ")"
        endif
        
        event_formula$ = "if x >= " + string$(current_time) + " and x < " + string$(current_time + current_dur)
        event_formula$ = event_formula$ + " then " + wave_formula$ + envelope$ + " else 0 fi"
        
        if formula$ = "0"
            formula$ = event_formula$
        else
            formula$ = formula$ + " + " + event_formula$
        endif
    endif
    
    old_state = current_state
    
    # Markov Logic
    if markov_type = 1
        r = randomUniform(0,1)
        if r < 0.6 - transition_randomness/2
            current_state = current_state
        elsif r < 0.9 - transition_randomness/3
            direction = randomInteger(0,1) * 2 - 1
            current_state = current_state + direction
            current_state = max(1, min(number_states, current_state))
        else
            current_state = randomInteger(1, number_states)
        endif
        
    elsif markov_type = 2
        current_state = current_state + 1
        if current_state > number_states
            current_state = 1
        endif
        
    elsif markov_type = 3
        step = randomInteger(-2, 2)
        current_state = current_state + step
        current_state = max(1, min(number_states, current_state))
        
    else
        center_state = round(number_states/2)
        if current_state < center_state
            current_state = current_state + 1
        elsif current_state > center_state
            current_state = current_state - 1
        else
            if randomUniform(0,1) < 0.7
                current_state = current_state
            else
                current_state = current_state + randomInteger(-1,1)
                current_state = max(1, min(number_states, current_state))
            endif
        endif
    endif
    
    if event_count < 1000
        state_history#[event_count] = current_state
    endif
    current_time = current_time + current_dur
    
    if event_count mod 50 = 0
        echo Built 'event_count' events...
    endif
endwhile

echo Synthesizing...
Create Sound from formula: "markov_raw", 1, 0, duration, sampling_frequency, formula$

# Filter and Finalize
Copy: "markov_filtered"
Filter (pass Hann band): base_frequency*0.5, base_frequency*8, 100
Scale peak: 0.9

# Rename to final output
Rename: "Markov_Synthesis"

# CLEANUP: Remove the raw and intermediate files
selectObject: "Sound markov_raw"
Remove
selectObject: "Sound markov_filtered"
Remove

# Select and Play the final result
selectObject: "Sound Markov_Synthesis"
Play

echo Markov Synthesis complete!
echo Total events: 'event_count'