# ============================================================
# Praat AudioTools - Formula Audio Manipulation.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Pitch-based transformation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ===================================================================
#  Advanced Formula Audio Manipulation
#  Applies complex modulations to selected audio
# ===================================================================

form Advanced Formula Audio Manipulation
    comment === PRESET CONFIGURATIONS ===
    optionmenu preset 1
        option Manual (configure below)
        option Gentle Modulation
        option Complex Textures
        option Chaotic Systems
        option Rhythmic Pulsing
        option Harmonic Richness
        option Extreme Modulation
        option Subtle Evolution
    comment ─────────────────────────────────────
    comment === MODULATION PARAMETERS ===
    real Base_frequency 0.8
    real Modulation_depth 0.85
    integer Complexity_level 3
    comment === PITCH MODULATION ===
    boolean Apply_pitch_modulation 1
    real Pitch_mod_rate 0.5
    real Pitch_mod_depth 0.4
    comment === RING MODULATION ===
    boolean Apply_ring_modulation 1
    real Ring_mod_frequency 120
    real Ring_mod_depth 0.6
    comment === OUTPUT OPTIONS ===
    boolean Play_result 1
    boolean Keep_intermediate_objects 0
endform

# Apply presets
if preset = 2    ; Gentle Modulation
    base_frequency = 0.3
    modulation_depth = 0.4
    complexity_level = 2
    apply_pitch_modulation = 1
    pitch_mod_rate = 0.2
    pitch_mod_depth = 0.2
    apply_ring_modulation = 0
elsif preset = 3    ; Complex Textures
    base_frequency = 1.2
    modulation_depth = 0.7
    complexity_level = 3
    apply_pitch_modulation = 1
    pitch_mod_rate = 0.8
    pitch_mod_depth = 0.3
    apply_ring_modulation = 1
    ring_mod_frequency = 80
    ring_mod_depth = 0.4
elsif preset = 4    ; Chaotic Systems
    base_frequency = 2.5
    modulation_depth = 0.9
    complexity_level = 3
    apply_pitch_modulation = 1
    pitch_mod_rate = 1.5
    pitch_mod_depth = 0.6
    apply_ring_modulation = 1
    ring_mod_frequency = 200
    ring_mod_depth = 0.8
elsif preset = 5    ; Rhythmic Pulsing
    base_frequency = 4.0
    modulation_depth = 0.6
    complexity_level = 2
    apply_pitch_modulation = 0
    apply_ring_modulation = 1
    ring_mod_frequency = 60
    ring_mod_depth = 0.7
elsif preset = 6    ; Harmonic Richness
    base_frequency = 0.5
    modulation_depth = 0.5
    complexity_level = 3
    apply_pitch_modulation = 1
    pitch_mod_rate = 0.3
    pitch_mod_depth = 0.4
    apply_ring_modulation = 1
    ring_mod_frequency = 150
    ring_mod_depth = 0.3
elsif preset = 7    ; Extreme Modulation
    base_frequency = 3.0
    modulation_depth = 1.0
    complexity_level = 3
    apply_pitch_modulation = 1
    pitch_mod_rate = 2.0
    pitch_mod_depth = 0.8
    apply_ring_modulation = 1
    ring_mod_frequency = 300
    ring_mod_depth = 0.9
elsif preset = 8    ; Subtle Evolution
    base_frequency = 0.2
    modulation_depth = 0.3
    complexity_level = 1
    apply_pitch_modulation = 1
    pitch_mod_rate = 0.1
    pitch_mod_depth = 0.15
    apply_ring_modulation = 0
endif

# Get selected Sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sampling_rate = Get sampling frequency

writeInfoLine: "Creating Advanced Formula Manipulation..."

# ===================================================================
# BUILD AMPLITUDE MODULATION ENVELOPE
# ===================================================================

if complexity_level = 1
    # Simple modulated envelope
    formula$ = "(0.5 + 0.5*sin(2*pi*'base_frequency'*x * (1 + 'modulation_depth'*0.6*sin(2*pi*2*x))))"
    
elsif complexity_level = 2
    # Multiple competing oscillators
    formula$ = "0.5 + 0.5*("
    formula$ = formula$ + "sin(2*pi*'base_frequency'*x * (1 + 0.4*sin(2*pi*1.5*x))) + "
    formula$ = formula$ + "0.6*sin(2*pi*'base_frequency'*1.618*x * (1 + 0.5*sin(2*pi*2.8*x))) + "
    formula$ = formula$ + "0.4*sin(2*pi*'base_frequency'*2.718*x * (1 + 0.6*sin(2*pi*0.9*x)))"
    formula$ = formula$ + ") / 2.0"
    
else
    # Complex chaotic system
    formula$ = "0.5 + 0.5*("
    formula$ = formula$ + "sin(2*pi*'base_frequency'*x * "
    formula$ = formula$ + "(1 + 'modulation_depth'*0.7*sin(2*pi*1.4*x + 2.5*sin(2*pi*0.4*x)))) + "
    formula$ = formula$ + "0.8*sin(2*pi*'base_frequency'*1.618*x * "
    formula$ = formula$ + "(1 + 'modulation_depth'*0.6*sin(2*pi*2.5*x + 1.5*sin(2*pi*0.7*x)))) + "
    formula$ = formula$ + "0.5*sin(2*pi*'base_frequency'*2.414*x * "
    formula$ = formula$ + "(1 + 'modulation_depth'*0.8*sin(2*pi*1.1*x + 2.0*sin(2*pi*0.3*x))))"
    formula$ = formula$ + ") / 2.3"
endif

Create Sound from formula: "am_envelope", 1, 0, duration, sampling_rate, formula$
am_envelope = selected("Sound")

# ===================================================================
# APPLY AMPLITUDE MODULATION
# ===================================================================

selectObject: sound
Copy: sound_name$ + "_modulated"
sound_mod = selected("Sound")
Formula: "self * object[am_envelope, col]"

# ===================================================================
# PITCH MODULATION (optional) - WITH DENSE POINT SAMPLING
# ===================================================================

if apply_pitch_modulation
    selectObject: sound_mod
    To Manipulation: 0.005, 75, 600
    manipulation = selected("Manipulation")
    
    # Get base pitch with better analysis
    selectObject: sound_mod
    To Pitch: 0.005, 75, 600
    pitch_obj = selected("Pitch")
    f0_base = Get quantile: 0, 0, 0.5, "Hertz"
    
    if f0_base = undefined
        f0_base = 150
    endif
    
    selectObject: pitch_obj
    Remove
    
    # Create modulated pitch tier with DENSE points
    selectObject: manipulation
    Create PitchTier: sound_name$ + "_pitch_mod", 0, duration
    pitchtier_new = selected("PitchTier")
    
    # Generate pitch modulation with dense sampling
    n_points = round(duration * 100)  
    # Much denser than original 50
    if n_points < 200
        n_points = 200
    endif
    if n_points > 2000
        n_points = 2000
    endif
    
    for i from 0 to n_points-1
        t = i * duration / n_points
        
        # Complex pitch modulation with multiple layers
        mod1 = sin(2*pi*pitch_mod_rate*t)
        mod2 = 0.5 * sin(2*pi*pitch_mod_rate*1.7*t + 0.5)
        mod3 = 0.3 * sin(2*pi*pitch_mod_rate*0.6*t + 1.2)
        
        mod_factor = 1 + pitch_mod_depth * (mod1 + mod2 + mod3) / 1.8
        f0 = f0_base * mod_factor
        
        # Clamp to reasonable range
        if f0 < 75
            f0 = 75
        elsif f0 > 600
            f0 = 600
        endif
        
        selectObject: pitchtier_new
        Add point: t, f0
    endfor
    
    # Replace pitch tier
    selectObject: manipulation
    plusObject: pitchtier_new
    Replace pitch tier
    
    # Resynthesize
    selectObject: manipulation
    sound_repitched = Get resynthesis (overlap-add)
    Rename: sound_name$ + "_pitch_mod"
    
    # Clean up
    if not keep_intermediate_objects
        removeObject: sound_mod, manipulation, pitchtier_new
    else
        removeObject: sound_mod
    endif
    sound_mod = sound_repitched
endif

# ===================================================================
# RING MODULATION (optional)
# ===================================================================

if apply_ring_modulation
    # Create carrier signal
    carrier_formula$ = "sin(2*pi*'ring_mod_frequency'*x)"
    Create Sound from formula: "carrier", 1, 0, duration, sampling_rate, carrier_formula$
    carrier = selected("Sound")
    
    # Apply ring modulation
    selectObject: sound_mod
    ring_formula$ = "self * (1 - 'ring_mod_depth' + 'ring_mod_depth' * object[carrier, col])"
    Formula: ring_formula$
    
    if not keep_intermediate_objects
        removeObject: carrier
    endif
endif

# ===================================================================
# FINAL PROCESSING
# ===================================================================

selectObject: sound_mod
Rename: sound_name$ + "_formula_manipulated"
Scale peak: 0.95

if not keep_intermediate_objects
    removeObject: am_envelope
endif

if play_result
    Play
endif

# ===================================================================
# REPORT RESULTS
# ===================================================================

appendInfoLine: "✓ Advanced Formula Manipulation complete!"
appendInfoLine: "  Preset: ", preset
appendInfoLine: "  Complexity level: ", complexity_level
appendInfoLine: "  Base modulation frequency: ", fixed$(base_frequency, 2), " Hz"
appendInfoLine: "  Modulation depth: ", fixed$(modulation_depth, 2)
if apply_pitch_modulation
    appendInfoLine: "  Pitch modulation: ON (", fixed$(pitch_mod_rate, 2), " Hz, depth ", fixed$(pitch_mod_depth, 2), ")"
endif
if apply_ring_modulation
    appendInfoLine: "  Ring modulation: ON (", ring_mod_frequency, " Hz, depth ", fixed$(ring_mod_depth, 2), ")"
endif