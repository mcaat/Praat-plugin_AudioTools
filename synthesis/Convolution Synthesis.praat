# ============================================================
# Praat AudioTools - Convolution Synthesis.praat
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

form Convolution Synthesis
    optionmenu Preset: 1
        option Custom
        option Metallic Bell
        option Deep Gong
        option Glass Harmonica
        option Snare Drum
        option Kick Drum
        option Water Drops
        option Bubble Pop
        option Robot Voice
        option Alien Speech
        option Digital Glitch
        option Thunder Clap
        option Wind Chime
        option Crystal Shatter
        option Sci-Fi Laser
        option Magic Spell
    
    optionmenu Envelope: 1
        option No Envelope
        option Percussive
        option Slow Decay
        option Reverse
        option Gate
        option Tremolo
        option Swell
        option ADSR
        option Stutter
        option Random
    
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Rotating
        option Binaural
        option Ping Pong
        option Wide Field
    
    comment Common parameters:
    positive Duration 1.0
    positive Sampling_frequency 44100
    
    comment Type-specific parameters:
    positive Frequency_1 800
    positive Frequency_2 1200
    positive Decay_rate 20
    positive Modulation 2
endform

echo Creating Convolution Synthesis...

# Apply presets
if preset > 1
    if preset = 2
        # Metallic Bell
        frequency_1 = 800
        frequency_2 = 1200
        decay_rate = 15
        modulation = 3
        
    elsif preset = 3
        # Deep Gong
        frequency_1 = 200
        frequency_2 = 400
        decay_rate = 8
        modulation = 1
        
    elsif preset = 4
        # Glass Harmonica
        frequency_1 = 1200
        frequency_2 = 1800
        decay_rate = 25
        modulation = 5
        
    elsif preset = 5
        # Snare Drum
        frequency_1 = 150
        frequency_2 = 6000
        decay_rate = 50
        modulation = 8
        
    elsif preset = 6
        # Kick Drum
        frequency_1 = 60
        frequency_2 = 80
        decay_rate = 30
        modulation = 2
        
    elsif preset = 7
        # Water Drops
        frequency_1 = 600
        frequency_2 = 1200
        decay_rate = 40
        modulation = 15
        
    elsif preset = 8
        # Bubble Pop
        frequency_1 = 400
        frequency_2 = 800
        decay_rate = 60
        modulation = 20
        
    elsif preset = 9
        # Robot Voice
        frequency_1 = 300
        frequency_2 = 900
        decay_rate = 25
        modulation = 4
        
    elsif preset = 10
        # Alien Speech
        frequency_1 = 500
        frequency_2 = 2000
        decay_rate = 35
        modulation = 12
        
    elsif preset = 11
        # Digital Glitch
        frequency_1 = 1000
        frequency_2 = 3000
        decay_rate = 100
        modulation = 30
        
    elsif preset = 12
        # Thunder Clap
        frequency_1 = 80
        frequency_2 = 200
        decay_rate = 12
        modulation = 2
        
    elsif preset = 13
        # Wind Chime
        frequency_1 = 1000
        frequency_2 = 1500
        decay_rate = 20
        modulation = 8
        
    elsif preset = 14
        # Crystal Shatter
        frequency_1 = 2000
        frequency_2 = 4000
        decay_rate = 80
        modulation = 25
        
    elsif preset = 15
        # Sci-Fi Laser
        frequency_1 = 400
        frequency_2 = 1600
        decay_rate = 45
        modulation = 18
        
    elsif preset = 16
        # Magic Spell
        frequency_1 = 300
        frequency_2 = 1200
        decay_rate = 18
        modulation = 6
    endif
endif

echo Using preset: 'preset'

# Initialize variables based on sound type
if preset = 2 or preset = 3 or preset = 4 or preset = 13
    # Metallic/Bell types
    source_formula$ = "randomGauss(0,0.3)"
    filter_formula$ = "sin(2*pi*" + string$(frequency_1) + "*x) * exp(-" + string$(decay_rate) + "*x) + 0.7*sin(2*pi*" + string$(frequency_2) + "*x) * exp(-" + string$(decay_rate) + "*1.5*x)"
    
elsif preset = 5 or preset = 6 or preset = 12
    # Drum types
    source_formula$ = "if x < 0.001 then 1 else 0 fi"
    filter_formula$ = "sin(2*pi*" + string$(frequency_1) + "*x) * exp(-" + string$(decay_rate) + "*x) + 0.3*sin(2*pi*" + string$(frequency_2) + "*x) * exp(-" + string$(decay_rate) + "*1.2*x)"
    
elsif preset = 7 or preset = 8
    # Water/Bubble types
    source_formula$ = "if x < 0.01 then 1 else 0 fi"
    filter_formula$ = "sin(2*pi*" + string$(frequency_1) + "*x) * exp(-" + string$(decay_rate) + "*x) * sin(2*pi*" + string$(modulation) + "*x)"
    
elsif preset = 9 or preset = 10
    # Voice types
    source_formula$ = "0.5*sin(2*pi*" + string$(frequency_1) + "*x) + 0.3*sin(2*pi*" + string$(frequency_2) + "*x)"
    filter_formula$ = "sin(2*pi*" + string$(frequency_1) + "*0.3*x) * exp(-" + string$(decay_rate) + "*x) + 0.5*sin(2*pi*" + string$(frequency_2) + "*2*x) * exp(-" + string$(decay_rate) + "*1.5*x)"
    
elsif preset = 11 or preset = 14 or preset = 15 or preset = 16
    # Special effects
    source_formula$ = "randomGauss(0,0.5) * sin(2*pi*" + string$(modulation) + "*x)"
    filter_formula$ = "sin(2*pi*" + string$(frequency_1) + "*x) * exp(-" + string$(decay_rate) + "*x) + 0.8*sin(2*pi*" + string$(frequency_2) + "*x) * exp(-" + string$(decay_rate) + "*2*x)"
    
else
    # Custom
    source_formula$ = "sin(2*pi*" + string$(frequency_1) + "*x)"
    filter_formula$ = "sin(2*pi*" + string$(frequency_2) + "*x) * exp(-" + string$(decay_rate) + "*x)"
endif

# Create source sound
Create Sound from formula: "source", 1, 0, duration, sampling_frequency, source_formula$
source = selected("Sound")

# Create filter sound  
Create Sound from formula: "filter", 1, 0, duration/2, sampling_frequency, filter_formula$
filter = selected("Sound")

# Convolve them
selectObject: source, filter
Convolve: "sum", "zero"
result = selected("Sound")
Rename: "convolution_mono"
Scale peak: 0.99

# Apply envelope
selectObject: result
if envelope = 2
    # Percussive
    Formula: "self * exp(-x*8)"
    
elsif envelope = 3
    # Slow Decay
    Formula: "self * exp(-x*1.5)"
    
elsif envelope = 4
    # Reverse
    Formula: "self[" + string$(duration) + " - x]"
    
elsif envelope = 5
    # Gate
    gate_period = 0.1
    Formula: "self * if sin(2*pi*x/" + string$(gate_period) + ") > 0 then 1 else 0 fi"
    
elsif envelope = 6
    # Tremolo
    trem_rate = 8
    trem_depth = 0.4
    Formula: "self * (1 - " + string$(trem_depth) + " + " + string$(trem_depth) + "*sin(2*pi*" + string$(trem_rate) + "*x))"
    
elsif envelope = 7
    # Swell
    attack_time = duration * 0.3
    Formula: "self * if x < " + string$(attack_time) + " then x/" + string$(attack_time) + " else 1 fi"
    
elsif envelope = 8
    # ADSR
    attack = 0.01
    decay = 0.1
    sustain = 0.6
    release = 0.2
    decay_end = attack + decay
    release_start = duration - release
    Formula: "self * if x < " + string$(attack) + " then x/" + string$(attack) + " else if x < " + string$(decay_end) + " then 1-(1-" + string$(sustain) + ")*((x-" + string$(attack) + ")/" + string$(decay) + ") else if x < " + string$(release_start) + " then " + string$(sustain) + " else " + string$(sustain) + "*(1-(x-" + string$(release_start) + ")/" + string$(release) + ") fi fi fi"
    
elsif envelope = 9
    # Stutter
    stutter_rate = 15
    Formula: "self * if floor(x*" + string$(stutter_rate) + ") mod 2 = 0 then 1 else 0 fi"
    
elsif envelope = 10
    # Random
    Formula: "self * (0.7 + 0.3 * randomUniform(0,1))"
endif

# ====== SPATIAL PROCESSING ======
selectObject: result

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "convolution_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO WIDE - Wide stereo image
    Copy: "conv_left"
    left_sound = selected("Sound")
    
    selectObject: result
    Copy: "conv_right" 
    right_sound = selected("Sound")
    
    # Add spectral differences for width
    selectObject: left_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 0, 4000, 100
    
    selectObject: right_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 200, 8000, 100
    
    # Combine to stereo
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "convolution_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING - Circular panning motion
    Copy: "conv_left"
    left_sound = selected("Sound")
    
    selectObject: result
    Copy: "conv_right"
    right_sound = selected("Sound")
    
    # Apply rotation
    rotation_rate = 0.5
    selectObject: left_sound
    Formula: "self * (0.6 + 0.4 * cos(2*pi*" + string$(rotation_rate) + "*x))"
    
    selectObject: right_sound
    Formula: "self * (0.6 + 0.4 * sin(2*pi*" + string$(rotation_rate) + "*x))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "convolution_rotating"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL - 3D spatial effect
    Copy: "conv_left"
    left_sound = selected("Sound")
    
    selectObject: result
    Copy: "conv_right"
    right_sound = selected("Sound")
    
    # Left channel: warmer
    selectObject: left_sound
    Filter (pass Hann band): 50, 3000, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.3))"
    
    # Right channel: brighter with slight delay
    selectObject: right_sound
    Filter (pass Hann band): 100, 5000, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.4))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "convolution_binaural"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 5
    # PING PONG - Alternating left-right
    Copy: "conv_left"
    left_sound = selected("Sound")
    
    selectObject: result
    Copy: "conv_right"
    right_sound = selected("Sound")
    
    # Fast alternating panning
    pan_rate = 4.0
    selectObject: left_sound
    Formula: "self * (0.3 + 0.5 * abs(sin(2*pi*" + string$(pan_rate) + "*x)))"
    
    selectObject: right_sound
    Formula: "self * (0.3 + 0.5 * abs(cos(2*pi*" + string$(pan_rate) + "*x)))"
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "convolution_pingpong"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
    
elsif spatial_mode = 6
    # WIDE FIELD - Extreme stereo separation
    Copy: "conv_left"
    left_sound = selected("Sound")
    
    selectObject: result
    Copy: "conv_right" 
    right_sound = selected("Sound")
    
    # Extreme frequency separation
    selectObject: left_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 2000, 150
    
    selectObject: right_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 300, 10000, 150
    
    selectObject: left_sound
    plusObject: right_sound
    Combine to stereo
    Rename: "convolution_wide"
    output_sound = selected("Sound")
    
    selectObject: left_sound
    plusObject: right_sound
    Remove
endif

selectObject: output_sound
Play

# Clean up temporary objects
selectObject: source
plusObject: filter
Remove

echo Convolution Synthesis complete!
echo Preset: 'preset'
echo Envelope: 'envelope'
echo Spatial mode: 'spatial_mode'