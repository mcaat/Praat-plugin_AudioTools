# ============================================================
# Praat AudioTools - Generative Sound System.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Generative Sound System script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Enhanced Generative System
    positive Duration_(sec) 10
    positive Base_frequency_(Hz) 110
    positive Number_of_layers 4
    real Evolution_rate 0.5 
    optionmenu Synthesis_mode: 1
        option Harmonic Drift
        option Granular Cloud
        option FM Chaos
        option Spectral Morph
        option Rhythmic Pulse
        option Subtractive Noise
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo Wide
        option Rotating
        option Binaural
    positive Fade_time_(sec) 2
    boolean Normalize_output 1
endform

# Validation
if number_of_layers > 16
    number_of_layers = 16
endif

# Initialize
sample_rate = 44100

# ====== SYNTHESIS ENGINE ======

# Initialize base canvas
if synthesis_mode = 6
    # Mode 6 needs a noise source
    Create Sound from formula: "gen_base", 1, 0, duration, sample_rate, "randomGauss(0, 0.5)"
    base_id = selected("Sound")
    Create Sound from formula: "gen_output", 1, 0, duration, sample_rate, "0"
    gen_id = selected("Sound")
else
    # All other modes start with silence
    Create Sound from formula: "gen_output", 1, 0, duration, sample_rate, "0"
    gen_id = selected("Sound")
endif

# --- MODE 1: HARMONIC DRIFT ---
if synthesis_mode = 1
    for layer from 1 to number_of_layers
        harmonic = layer
        freq = base_frequency * harmonic
        drift_rate = evolution_rate * (0.3 + layer * 0.1)
        detune = 1 + sin(layer * 1.7) * 0.02
        
        # Define formula in one robust block
        formula$ = "sin(2*pi*" + string$(freq) + "*" + string$(detune) + "*x + sin(2*pi*" + string$(drift_rate) + "*x)*2) * (1 / (" + string$(layer) + " + 1)) * (0.6 + sin(2*pi*" + string$(drift_rate) + "*0.5*x) * 0.4)"
        
        Create Sound from formula: "layer_" + string$(layer), 1, 0, duration, sample_rate, formula$
        
        call applyFadeEnvelope
        call addToOutput
    endfor

# --- MODE 2: GRANULAR CLOUD ---
elsif synthesis_mode = 2
    for layer from 1 to number_of_layers
        grain_freq = base_frequency * (1 + layer * 0.3)
        grain_rate = 20 + layer * 15
        grain_density = evolution_rate * 10
        
        formula$ = "sin(2*pi*" + string$(grain_freq) + "*x) * (abs(sin(2*pi*" + string$(grain_rate) + "*x + " + string$(layer) + ")) > 0.7) * exp(-abs(sin(2*pi*" + string$(grain_rate) + "*x)) * " + string$(grain_density) + ") * randomGauss(0, 0.15 + sin(2*pi*" + string$(evolution_rate) + "*x) * 0.1)"
        
        Create Sound from formula: "layer_" + string$(layer), 1, 0, duration, sample_rate, formula$
        
        call applyFadeEnvelope
        call addToOutput
    endfor

# --- MODE 3: FM CHAOS ---
elsif synthesis_mode = 3
    for layer from 1 to number_of_layers
        carrier = base_frequency * (1 + layer * 0.25)
        mod_freq = carrier * (1.5 + layer * 0.3)
        mod_index = 3 + sin(layer * 2.3) * 2
        chaos_rate = evolution_rate * (0.5 + layer * 0.2)
        
        # This was the line causing errors. Now fixed using string construction.
        formula$ = "sin(2*pi*" + string$(carrier) + "*x + " + string$(mod_index) + " * sin(2*pi*" + string$(mod_freq) + "*x * (1 + sin(2*pi*" + string$(chaos_rate) + "*x)*0.5))) * (0.5 / " + string$(number_of_layers) + ")"
        
        Create Sound from formula: "layer_" + string$(layer), 1, 0, duration, sample_rate, formula$
        
        call applyFadeEnvelope
        call addToOutput
    endfor

# --- MODE 4: SPECTRAL MORPH ---
elsif synthesis_mode = 4
    Create Sound from formula: "noise_base", 1, 0, duration, sample_rate, "randomGauss(0, 0.3)"
    noise_id = selected("Sound")
    
    for layer from 1 to number_of_layers
        selectObject: noise_id
        Copy: "layer_" + string$(layer)
        layer_id = selected("Sound")
        
        center_freq = base_frequency * (1 + layer * 2)
        sweep_range = center_freq * 0.5
        sweep_rate = evolution_rate * (0.2 + layer * 0.1)
        
        # Using string$ ensures values are inserted as numbers, not variable references
        formula$ = "self * (1 + sin(2*pi*(" + string$(center_freq) + " + " + string$(sweep_range) + " * sin(2*pi*" + string$(sweep_rate) + "*x))*x/44100) * 0.5)"
        Formula: formula$
        
        Filter (pass Hann band): center_freq * 0.7, center_freq * 1.5, 100
        
        call applyFadeEnvelope
        call addToOutput
    endfor
    
    selectObject: noise_id
    Remove

# --- MODE 5: RHYTHMIC PULSE ---
elsif synthesis_mode = 5
    for layer from 1 to number_of_layers
        pulse_freq = base_frequency * (1 + layer * 0.5)
        rhythm_rate = evolution_rate * (1 + layer * 0.5)
        
        formula$ = "(abs(sin(2*pi*" + string$(pulse_freq) + "*x)) > 0.95) * sin(2*pi*" + string$(pulse_freq) + "*x) * (0.5 + sin(2*pi*" + string$(rhythm_rate) + "*x) * 0.5) * (1 / sqrt(" + string$(layer) + "))"
        
        Create Sound from formula: "layer_" + string$(layer), 1, 0, duration, sample_rate, formula$
        
        call applyFadeEnvelope
        call addToOutput
    endfor

# --- MODE 6: SUBTRACTIVE NOISE ---
elsif synthesis_mode = 6
    for layer from 1 to number_of_layers
        selectObject: base_id
        Copy: "layer_" + string$(layer)
        layer_id = selected("Sound")
        
        filter_freq = base_frequency * (2 ^ layer)
        resonance = 50 + layer * 30
        sweep_rate = evolution_rate * 0.3
        
        formula$ = "self * (1 + sin(2*pi*" + string$(sweep_rate) + "*x)*0.3)"
        Formula: formula$
        
        Filter (pass Hann band): filter_freq * 0.8, filter_freq * 1.2, resonance
        
        call applyFadeEnvelope
        call addToOutput
    endfor
    
    selectObject: base_id
    Remove
endif

# ====== SPATIAL PROCESSING ======

selectObject: gen_id

if spatial_mode = 1
    # MONO
    output_id = gen_id
    
elsif spatial_mode = 2
    # STEREO WIDE
    Copy: "gen_left"
    left_id = selected("Sound")
    
    selectObject: gen_id
    Copy: "gen_right"
    right_id = selected("Sound")
    
    selectObject: left_id
    Formula: "self * 0.95"
    
    selectObject: right_id
    Formula: "Sound_gen_left[col + 50] * 1.05 + self * 0.05"
    
    selectObject: left_id
    plusObject: right_id
    Combine to stereo
    output_id = selected("Sound")
    
    selectObject: left_id
    plusObject: right_id
    Remove
    
elsif spatial_mode = 3
    # ROTATING
    Copy: "gen_left"
    left_id = selected("Sound")
    
    selectObject: gen_id
    Copy: "gen_right"
    right_id = selected("Sound")
    
    rotation_rate = 0.25
    selectObject: left_id
    Formula: "self * (0.5 + cos(2*pi*" + string$(rotation_rate) + "*x) * 0.5)"
    
    selectObject: right_id
    # Note: referencing original mono source for phase coherence
    Formula: "Sound_gen_output[] * (0.5 + sin(2*pi*" + string$(rotation_rate) + "*x) * 0.5)"
    
    selectObject: left_id
    plusObject: right_id
    Combine to stereo
    output_id = selected("Sound")
    
    selectObject: left_id
    plusObject: right_id
    Remove
    
elsif spatial_mode = 4
    # BINAURAL
    Copy: "gen_left"
    left_id = selected("Sound")
    Filter (pass Hann band): 0, base_frequency * 8, 100
    Scale intensity: 72
    
    selectObject: gen_id
    Copy: "gen_right"
    right_id = selected("Sound")
    
    delay_samples = 100
    Formula: "if col > " + string$(delay_samples) + " then self[col - " + string$(delay_samples) + "] else 0 fi"
    Filter (pass Hann band): base_frequency * 2, 0, 100
    Scale intensity: 72
    
    selectObject: left_id
    plusObject: right_id
    Combine to stereo
    output_id = selected("Sound")
    
    selectObject: left_id
    plusObject: right_id
    Remove
endif

# ====== FINALIZE ======

selectObject: output_id
Rename: "Generative_System"

# Normalize
if normalize_output
    Scale peak: 0.85
endif

Play

# CLEANUP LOGIC
if output_id != gen_id
    selectObject: gen_id
    Remove
    selectObject: output_id
endif

echo Generative System Complete.
echo Mode: 'synthesis_mode' | Spatial: 'spatial_mode'

# ====== PROCEDURES ======

procedure applyFadeEnvelope
    if fade_time > 0
        fs = fade_time * sample_rate
        ts = duration * sample_rate
        
        # We use string concatenation for formulas inside procedures too, to be safe
        form_fade$ = "if col < " + string$(fs) + " then self * (col/" + string$(fs) + ") else if col > (" + string$(ts) + " - " + string$(fs) + ") then self * ((" + string$(ts) + " - col)/" + string$(fs) + ") else self fi fi"
        Formula: form_fade$
    endif
endproc

procedure addToOutput
    current_layer_id = selected("Sound")
    selectObject: gen_id
    
    # We reference the layer by valid syntax
    Formula: "self + Sound_layer_" + string$(layer) + "[] / " + string$(number_of_layers)
    
    selectObject: current_layer_id
    Remove
endproc