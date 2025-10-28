# ============================================================
# Praat AudioTools - Markov Rhythm Generator.praat
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

form Markov Rhythm Generator
    optionmenu Preset: 1
        option Custom
        option Simple March
        option Complex Funk
        option Techno Pattern
        option Swing Feel
        option Broken Beat
        option Latin Rhythm
        option Polyrhythmic
        option Random Walk
    optionmenu Cannon_mode: 1
        option No Cannon
        option Cannon 2 voices
        option Cannon 3 voices
        option Cannon 4 voices
    real Cannon_delay 1.0
    real Duration 6.0
    real Sampling_frequency 44100
    integer Pattern_length 4
    real Tempo 120
    real Base_frequency 150
endform

echo Building Markov Rhythm Pattern...

# Apply presets
if preset > 1
    if preset = 2
        # Simple March
        tempo = 100
        pattern_length = 4
        base_frequency = 120
        
    elsif preset = 3
        # Complex Funk
        tempo = 110
        pattern_length = 8
        base_frequency = 180
        
    elsif preset = 4
        # Techno Pattern
        tempo = 130
        pattern_length = 4
        base_frequency = 80
        
    elsif preset = 5
        # Swing Feel
        tempo = 90
        pattern_length = 6
        base_frequency = 140
        
    elsif preset = 6
        # Broken Beat
        tempo = 140
        pattern_length = 7
        base_frequency = 160
        
    elsif preset = 7
        # Latin Rhythm
        tempo = 120
        pattern_length = 8
        base_frequency = 200
        
    elsif preset = 8
        # Polyrhythmic
        tempo = 100
        pattern_length = 5
        base_frequency = 130
        
    elsif preset = 9
        # Random Walk
        tempo = 80
        pattern_length = 4
        base_frequency = 170
    endif
endif

echo Using preset: 'preset'

beats_per_second = tempo / 60
beat_duration = 1 / beats_per_second
total_beats = round(duration * beats_per_second)

formula$ = "0"

rhythm_states = 8
current_rhythm = randomInteger(1, rhythm_states)

# Define rhythm patterns for each preset
if preset = 2
    # Simple March patterns
    rhythm_pattern$[1] = "1000"
    rhythm_pattern$[2] = "1010"
    rhythm_pattern$[3] = "1100"
    rhythm_pattern$[4] = "1001"
    rhythm_pattern$[5] = "1010"
    rhythm_pattern$[6] = "1100"
    rhythm_pattern$[7] = "1001"
    rhythm_pattern$[8] = "1110"
    
elsif preset = 3
    # Complex Funk patterns
    rhythm_pattern$[1] = "10101010"
    rhythm_pattern$[2] = "10011001"
    rhythm_pattern$[3] = "11001100"
    rhythm_pattern$[4] = "10110100"
    rhythm_pattern$[5] = "10010110"
    rhythm_pattern$[6] = "11010010"
    rhythm_pattern$[7] = "10100101"
    rhythm_pattern$[8] = "10001011"
    
elsif preset = 4
    # Techno Pattern
    rhythm_pattern$[1] = "1000"
    rhythm_pattern$[2] = "1001"
    rhythm_pattern$[3] = "1010"
    rhythm_pattern$[4] = "1011"
    rhythm_pattern$[5] = "1100"
    rhythm_pattern$[6] = "1101"
    rhythm_pattern$[7] = "1110"
    rhythm_pattern$[8] = "1111"
    
elsif preset = 5
    # Swing Feel
    rhythm_pattern$[1] = "100010"
    rhythm_pattern$[2] = "100100"
    rhythm_pattern$[3] = "101000"
    rhythm_pattern$[4] = "101010"
    rhythm_pattern$[5] = "110000"
    rhythm_pattern$[6] = "110010"
    rhythm_pattern$[7] = "100110"
    rhythm_pattern$[8] = "101100"
    
elsif preset = 6
    # Broken Beat
    rhythm_pattern$[1] = "1010101"
    rhythm_pattern$[2] = "1001011"
    rhythm_pattern$[3] = "1101001"
    rhythm_pattern$[4] = "1011010"
    rhythm_pattern$[5] = "1001101"
    rhythm_pattern$[6] = "1110010"
    rhythm_pattern$[7] = "1010110"
    rhythm_pattern$[8] = "1100110"
    
elsif preset = 7
    # Latin Rhythm
    rhythm_pattern$[1] = "10101010"
    rhythm_pattern$[2] = "10010101"
    rhythm_pattern$[3] = "10100101"
    rhythm_pattern$[4] = "10011010"
    rhythm_pattern$[5] = "10110010"
    rhythm_pattern$[6] = "10010110"
    rhythm_pattern$[7] = "10101100"
    rhythm_pattern$[8] = "10011001"
    
elsif preset = 8
    # Polyrhythmic
    rhythm_pattern$[1] = "10101"
    rhythm_pattern$[2] = "10010"
    rhythm_pattern$[3] = "11011"
    rhythm_pattern$[4] = "10110"
    rhythm_pattern$[5] = "10001"
    rhythm_pattern$[6] = "11100"
    rhythm_pattern$[7] = "10111"
    rhythm_pattern$[8] = "11001"
    
elsif preset = 9
    # Random Walk
    rhythm_pattern$[1] = "1000"
    rhythm_pattern$[2] = "1100"
    rhythm_pattern$[3] = "1010"
    rhythm_pattern$[4] = "1001"
    rhythm_pattern$[5] = "1110"
    rhythm_pattern$[6] = "1011"
    rhythm_pattern$[7] = "1101"
    rhythm_pattern$[8] = "1111"
    
else
    # Custom patterns
    rhythm_pattern$[1] = "1000"
    rhythm_pattern$[2] = "1010"
    rhythm_pattern$[3] = "1100"
    rhythm_pattern$[4] = "1110"
    rhythm_pattern$[5] = "1001"
    rhythm_pattern$[6] = "1011"
    rhythm_pattern$[7] = "1101"
    rhythm_pattern$[8] = "1111"
endif

for beat from 1 to total_beats
    current_pattern$ = rhythm_pattern$[current_rhythm]
    subdivisions = length(current_pattern$)
    
    for subdiv from 1 to subdivisions
        current_char$ = mid$(current_pattern$, subdiv, 1)
        
        if current_char$ = "1"
            start_time = (beat-1) * beat_duration + (subdiv-1) * (beat_duration/subdivisions)
            pulse_dur = beat_duration/subdivisions * 0.7
            
            pulse_formula$ = "if x >= " + string$(start_time) + " and x < " + string$(start_time + pulse_dur)
            pulse_formula$ = pulse_formula$ + " then 0.6 * sin(2*pi*" + string$(base_frequency) + "*x)"
            pulse_formula$ = pulse_formula$ + " * exp(-8*(x-" + string$(start_time) + ")/" + string$(pulse_dur) + ")"
            pulse_formula$ = pulse_formula$ + " else 0 fi"
            
            if formula$ = "0"
                formula$ = pulse_formula$
            else
                formula$ = formula$ + " + " + pulse_formula$
            endif
        endif
    endfor
    
    # Markov chain transition
    r = randomUniform(0,1)
    if r < 0.4
        current_rhythm = current_rhythm
    elsif r < 0.7
        current_rhythm = current_rhythm + 1
        if current_rhythm > rhythm_states
            current_rhythm = 1
        endif
    else
        current_rhythm = randomInteger(1, rhythm_states)
    endif
    
    if beat mod 16 = 0
        echo Generated 'beat'/'total_beats' beats...
    endif
endfor

echo Creating rhythm pattern...
Create Sound from formula: "markov_rhythm", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# Apply cannon effect if selected
if cannon_mode > 1
    cannon_voices = cannon_mode
    total_duration = duration + (cannon_voices - 1) * cannon_delay
    
    # Build left and right channel formulas separately
    left_formula$ = "0"
    right_formula$ = "0"
    
    for voice to cannon_voices
        voice_delay = (voice - 1) * cannon_delay
        
        # Strong panning with different frequencies
        if voice mod 2 = 1
            # Odd voices: hard left with lower frequency
            voice_freq = base_frequency * 0.7
            pan_left = 1.0
            pan_right = 0.0
        else
            # Even voices: hard right with higher frequency  
            voice_freq = base_frequency * 1.3
            pan_left = 0.0
            pan_right = 1.0
        endif
        
        # Build voice formula with time shift
        voice_formula$ = "if x >= " + string$(voice_delay) + " and x < " + string$(voice_delay + duration)
        voice_formula$ = voice_formula$ + " then ("
        
        # Recreate the rhythm pattern for this voice
        temp_rhythm = current_rhythm
        voice_pattern_formula$ = "0"
        
        for beat from 1 to total_beats
            current_pattern$ = rhythm_pattern$[temp_rhythm]
            subdivisions = length(current_pattern$)
            
            for subdiv from 1 to subdivisions
                current_char$ = mid$(current_pattern$, subdiv, 1)
                
                if current_char$ = "1"
                    start_time = (beat-1) * beat_duration + (subdiv-1) * (beat_duration/subdivisions) + voice_delay
                    pulse_dur = beat_duration/subdivisions * 0.7
                    
                    if start_time < total_duration
                        if start_time + pulse_dur > total_duration
                            pulse_dur = total_duration - start_time
                        endif
                        
                        pulse_formula$ = "if x >= " + string$(start_time) + " and x < " + string$(start_time + pulse_dur)
                        pulse_formula$ = pulse_formula$ + " then 0.6 * sin(2*pi*" + string$(voice_freq) + "*(x-" + string$(voice_delay) + "))"
                        pulse_formula$ = pulse_formula$ + " * exp(-8*(x-" + string$(start_time) + ")/" + string$(pulse_dur) + ")"
                        pulse_formula$ = pulse_formula$ + " else 0 fi"
                        
                        if voice_pattern_formula$ = "0"
                            voice_pattern_formula$ = pulse_formula$
                        else
                            voice_pattern_formula$ = voice_pattern_formula$ + " + " + pulse_formula$
                        endif
                    endif
                endif
            endfor
            
            # Markov transition for this voice
            r = randomUniform(0,1)
            if r < 0.4
                temp_rhythm = temp_rhythm
            elsif r < 0.7
                temp_rhythm = temp_rhythm + 1
                if temp_rhythm > rhythm_states
                    temp_rhythm = 1
                endif
            else
                temp_rhythm = randomInteger(1, rhythm_states)
            endif
        endfor
        
        voice_formula$ = voice_formula$ + voice_pattern_formula$ + ") else 0 fi"
        
        # Add to left and right channels
        if left_formula$ = "0"
            left_formula$ = "(" + voice_formula$ + ") * " + string$(pan_left)
        else
            left_formula$ = left_formula$ + " + (" + voice_formula$ + ") * " + string$(pan_left)
        endif
        
        if right_formula$ = "0"
            right_formula$ = "(" + voice_formula$ + ") * " + string$(pan_right)
        else
            right_formula$ = right_formula$ + " + (" + voice_formula$ + ") * " + string$(pan_right)
        endif
    endfor
    
    # Create separate left and right sounds
    Create Sound from formula: "cannon_left", 1, 0, total_duration, sampling_frequency, left_formula$
    Create Sound from formula: "cannon_right", 1, 0, total_duration, sampling_frequency, right_formula$
    
    # Combine to stereo
    selectObject: "Sound cannon_left"
    plusObject: "Sound cannon_right"
    Combine to stereo
    Rename: "markov_rhythm_cannon"
    Scale peak: 0.9
    output_sound = selected("Sound")
    
    # Clean up
    selectObject: "Sound cannon_left"
    plusObject: "Sound cannon_right"
    Remove
    
    # Remove original mono
    selectObject: "Sound markov_rhythm"
    Remove
    
else
    # No cannon - just use original mono
    selectObject: "Sound markov_rhythm"
    output_sound = selected("Sound")
endif

selectObject: output_sound
Play

echo Markov Rhythm complete!
echo Preset: 'preset'
echo Cannon: 'cannon_mode' voices with 'cannon_delay:2' s delay
echo Pattern length: 'pattern_length'
echo Tempo: 'tempo' BPM