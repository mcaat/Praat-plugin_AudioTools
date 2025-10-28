# ============================================================
# Praat AudioTools - Competing Modulators.praat
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

form Competing Modulators
    optionmenu Preset: 1
        option Custom
        option Gentle Chaos
        option Metallic Clash
        option Organic Swarm
        option Digital Warble
        option Harmonic Battle
        option Alien Chorus
        option Glitchy Modulation
        option Rhythmic Conflict
        option Spectral War
        option Cosmic Interference
        option Mechanical Discord
        option Liquid Modulation
        option Crystal Resonance
        option Neural Network
        option Quantum Entanglement
    
    optionmenu Envelope: 1
        option No Envelope
        option Percussive
        option Slow Fade
        option Reverse
        option Gate
        option Tremolo
        option Swell
        option ADSR
        option Stutter
        option Random Bursts
    
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Voices
        option Rotating Modulators
        option Binaural Chaos
        option Wide Field
        option Ping Pong War
    
    real Duration 8.0
    real Sampling_frequency 44100
    real Base_frequency 120
    real Modulation_intensity 0.5
    integer Number_voices 4
endform

echo Creating Competing Modulators...

# Apply presets
if preset > 1
    if preset = 2
        # Gentle Chaos
        base_frequency = 100
        modulation_intensity = 0.3
        number_voices = 3
        
    elsif preset = 3
        # Metallic Clash
        base_frequency = 180
        modulation_intensity = 0.8
        number_voices = 5
        
    elsif preset = 4
        # Organic Swarm
        base_frequency = 80
        modulation_intensity = 0.4
        number_voices = 6
        
    elsif preset = 5
        # Digital Warble
        base_frequency = 200
        modulation_intensity = 0.7
        number_voices = 4
        
    elsif preset = 6
        # Harmonic Battle
        base_frequency = 150
        modulation_intensity = 0.6
        number_voices = 4
        
    elsif preset = 7
        # Alien Chorus
        base_frequency = 140
        modulation_intensity = 0.9
        number_voices = 5
        
    elsif preset = 8
        # Glitchy Modulation
        base_frequency = 220
        modulation_intensity = 1.0
        number_voices = 3
        
    elsif preset = 9
        # Rhythmic Conflict
        base_frequency = 110
        modulation_intensity = 0.5
        number_voices = 4
        
    elsif preset = 10
        # Spectral War
        base_frequency = 160
        modulation_intensity = 0.8
        number_voices = 6
        
    elsif preset = 11
        # Cosmic Interference
        base_frequency = 90
        modulation_intensity = 0.7
        number_voices = 5
        
    elsif preset = 12
        # Mechanical Discord
        base_frequency = 130
        modulation_intensity = 0.9
        number_voices = 4
        
    elsif preset = 13
        # Liquid Modulation
        base_frequency = 70
        modulation_intensity = 0.4
        number_voices = 3
        
    elsif preset = 14
        # Crystal Resonance
        base_frequency = 240
        modulation_intensity = 0.6
        number_voices = 4
        
    elsif preset = 15
        # Neural Network
        base_frequency = 170
        modulation_intensity = 0.8
        number_voices = 5
        
    elsif preset = 16
        # Quantum Entanglement
        base_frequency = 190
        modulation_intensity = 1.0
        number_voices = 6
    endif
endif

echo Using preset: 'preset'

formula$ = "("

for voice to number_voices
    voice_amp = 1.0 / number_voices
    voice_ratio = 0.5 + (voice-1) * 0.3
    
    # Preset-specific modulation characteristics
    if preset = 2
        # Gentle Chaos - subtle modulations
        voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
        voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.2*(sin(2*pi*0.1*x) + 0.1*sin(2*pi*1.2*x))))"
        
    elsif preset = 3
        # Metallic Clash - harsh modulations
        voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
        voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.6*sin(2*pi*" + string$(voice*2) + "*x + 3*sin(2*pi*0.5*x))))"
        
    elsif preset = 4
        # Organic Swarm - natural modulations
        voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
        voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.3*sin(2*pi*" + string$(voice*0.7) + "*x + sin(2*pi*0.3*x))))"
        
    elsif preset = 7
        # Alien Chorus - extreme modulations
        voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
        voice_formula$ = voice_formula$ + "exp(" + string$(modulation_intensity) + "*0.4*sin(2*pi*" + string$(voice*3) + "*x)))"
        
    elsif preset = 13
        # Liquid Modulation - flowing modulations
        voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
        voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.4*sin(2*pi*" + string$(voice*1.5) + "*x * (1 + 0.2*sin(2*pi*0.2*x)))))"
        
    else
        # Default modulation patterns based on voice number
        if voice = 1
            # Brownian-like modulation
            voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
            voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.3*(sin(2*pi*0.2*x) + 0.2*sin(2*pi*1.7*x))))"
            
        elsif voice = 2
            # Chaotic modulation
            voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
            voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.4*sin(2*pi*3*x + 2*sin(2*pi*0.8*x))))"
            
        elsif voice = 3
            # Random walk simulation
            voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
            voice_formula$ = voice_formula$ + "(1 + " + string$(modulation_intensity) + "*0.5*(x/" + string$(duration) + ")*sin(2*pi*5*x)))"
            
        else
            # Exponential processes
            voice_formula$ = string$(voice_amp) + " * sin(2*pi*" + string$(base_frequency) + "*" + string$(voice_ratio) + "*x * "
            voice_formula$ = voice_formula$ + "exp(-0.5*" + string$(modulation_intensity) + "*sin(2*pi*2*x)))"
        endif
    endif
    
    if voice = 1
        formula$ = formula$ + voice_formula$
    else
        formula$ = formula$ + " + " + voice_formula$
    endif
endfor

formula$ = formula$ + ") * (0.6 + 0.4*sin(2*pi*0.1*x))"

Create Sound from formula: "modulators_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# Apply envelope
selectObject: "Sound modulators_output"
if envelope = 2
    # Percussive
    Formula: "self * exp(-x*3)"
    
elsif envelope = 3
    # Slow Fade
    Formula: "self * exp(-x*0.5)"
    
elsif envelope = 4
    # Reverse
    Formula: "self[" + string$(duration) + " - x]"
    
elsif envelope = 5
    # Gate
    gate_period = 0.2
    Formula: "self * if sin(2*pi*x/" + string$(gate_period) + ") > 0 then 1 else 0 fi"
    
elsif envelope = 6
    # Tremolo
    trem_rate = 6
    trem_depth = 0.5
    Formula: "self * (1 - " + string$(trem_depth) + " + " + string$(trem_depth) + "*sin(2*pi*" + string$(trem_rate) + "*x))"
    
elsif envelope = 7
    # Swell
    attack_time = duration * 0.4
    Formula: "self * if x < " + string$(attack_time) + " then x/" + string$(attack_time) + " else 1 fi"
    
elsif envelope = 8
    # ADSR
    attack = 0.05
    decay = 0.2
    sustain = 0.7
    release = 0.3
    decay_end = attack + decay
    release_start = duration - release
    Formula: "self * if x < " + string$(attack) + " then x/" + string$(attack) + " else if x < " + string$(decay_end) + " then 1-(1-" + string$(sustain) + ")*((x-" + string$(attack) + ")/" + string$(decay) + ") else if x < " + string$(release_start) + " then " + string$(sustain) + " else " + string$(sustain) + "*(1-(x-" + string$(release_start) + ")/" + string$(release) + ") fi fi fi"
    
elsif envelope = 9
    # Stutter
    stutter_rate = 12
    Formula: "self * if floor(x*" + string$(stutter_rate) + ") mod 2 = 0 then 1 else 0 fi"
    
elsif envelope = 10
    # Random Bursts
    burst_density = 8
    Formula: "self * if randomUniform(0,1) < " + string$(burst_density*0.1) + " then 1 else 0.3 fi"
endif

# ====== SPATIAL PROCESSING ======
selectObject: "Sound modulators_output"

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "competing_modulators_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO VOICES - Different voices in each channel
    Copy: "mod_left"
    left_sound = selected("Sound")
    
    selectObject: "Sound modulators_output"
    Copy: "mod_right" 
    right_sound = selected("Sound")
    
    # Left channel: emphasize lower modulation rates
    selectObject: left_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 0, 3000, 100
    
    # Right channel: emphasize higher modulation rates
    selectObject: right_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 200, 6000, 100
    
    # Combine to stereo
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "competing_modulators_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING MODULATORS - Modulators move around
    Copy: "mod_left"
    left_sound = selected("Sound")
    
    selectObject: "Sound modulators_output"
    Copy: "mod_right"
    right_sound = selected("Sound")
    
    # Apply rotating panning
    rotation_rate = 0.08
    selectObject: left_sound
    Formula: "self * (0.5 + 0.4 * cos(2*pi*" + string$(rotation_rate) + "*x))"
    
    selectObject: right_sound
    Formula: "self * (0.5 + 0.4 * sin(2*pi*" + string$(rotation_rate) + "*x))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "competing_modulators_rotating"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL CHAOS - 3D chaotic space
    Copy: "mod_left"
    left_sound = selected("Sound")
    
    selectObject: "Sound modulators_output"
    Copy: "mod_right"
    right_sound = selected("Sound")
    
    # Left channel: warm chaotic texture
    selectObject: left_sound
    Filter (pass Hann band): 50, 3500, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.15))"
    
    # Right channel: bright chaotic texture
    selectObject: right_sound
    Filter (pass Hann band): 100, 5000, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.25))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "competing_modulators_binaural"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 5
    # WIDE FIELD - Extreme stereo separation
    Copy: "mod_left"
    left_sound = selected("Sound")
    
    selectObject: "Sound modulators_output"
    Copy: "mod_right" 
    right_sound = selected("Sound")
    
    # Extreme frequency separation
    selectObject: left_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 2000, 150
    
    selectObject: right_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 300, 8000, 150
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "competing_modulators_wide"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 6
    # PING PONG WAR - Alternating conflict
    Copy: "mod_left"
    left_sound = selected("Sound")
    
    selectObject: "Sound modulators_output"
    Copy: "mod_right"
    right_sound = selected("Sound")
    
    # Fast alternating panning representing conflict
    pan_rate = 2.5
    selectObject: left_sound
    Formula: "self * (0.4 + 0.5 * abs(sin(2*pi*" + string$(pan_rate) + "*x)))"
    
    selectObject: right_sound
    Formula: "self * (0.4 + 0.5 * abs(cos(2*pi*" + string$(pan_rate) + "*x)))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "competing_modulators_pingpong"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
endif

selectObject: output_sound
Play

echo Competing Modulators complete!
echo Preset: 'preset'
echo Envelope: 'envelope'
echo Spatial mode: 'spatial_mode'
echo Number of voices: 'number_voices'