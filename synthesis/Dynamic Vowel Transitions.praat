# ============================================================
# Praat AudioTools - Dynamic Vowel Transitions.praat
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

form Dynamic Vowel Transitions
    optionmenu Preset: 1
        option Custom
        option A_to_I
        option I_to_U
        option U_to_A
        option All_vowels
        option Vowel_Cycle
        option Formant_Glissando
        option Whisper_Transition
        option Singing_Vowels
        option Robot_Speech
        option Alien_Vowels
        option Choral_Shift
        option Spectral_Morph
        option Harmonic_Transition
        option Formant_Sweep
        option Vocal_Journey
    optionmenu Spatial_mode: 1
        option Mono
        option Stereo_Voice
        option Rotating_Formants
        option Binaural_Vowels
        option Wide_Transition
        option Panning_Morph
    real Duration 3.0
    real Sampling_frequency 44100
endform

echo Creating Dynamic Vowel Transitions...

# Apply presets
if preset > 1
    if preset = 2
        # A to I transition
        start_f1 = 730
        start_f2 = 1090
        start_f3 = 2440
        end_f1 = 270
        end_f2 = 2290
        end_f3 = 3010
        transition_name$ = "A_to_I"
        
    elsif preset = 3
        # I to U transition
        start_f1 = 270
        start_f2 = 2290
        start_f3 = 3010
        end_f1 = 300
        end_f2 = 870
        end_f3 = 2240
        transition_name$ = "I_to_U"
        
    elsif preset = 4
        # U to A transition
        start_f1 = 300
        start_f2 = 870
        start_f3 = 2240
        end_f1 = 730
        end_f2 = 1090
        end_f3 = 2440
        transition_name$ = "U_to_A"
        
    elsif preset = 5
        # All vowels - complex cycle
        start_f1 = 730
        start_f2 = 1090
        start_f3 = 2440
        end_f1 = 730
        end_f2 = 1090
        end_f3 = 2440
        transition_name$ = "All_vowels"
        
    elsif preset = 6
        # Vowel Cycle - smooth through all vowels
        start_f1 = 730
        start_f2 = 1090
        start_f3 = 2440
        end_f1 = 730
        end_f2 = 1090
        end_f3 = 2440
        transition_name$ = "Vowel_Cycle"
        
    elsif preset = 7
        # Formant Glissando - extreme transitions
        start_f1 = 200
        start_f2 = 800
        start_f3 = 2000
        end_f1 = 1000
        end_f2 = 3000
        end_f3 = 4000
        transition_name$ = "Formant_Glissando"
        
    elsif preset = 8
        # Whisper Transition - breathy vowels
        start_f1 = 600
        start_f2 = 1200
        start_f3 = 2400
        end_f1 = 400
        end_f2 = 1800
        end_f3 = 2800
        transition_name$ = "Whisper_Transition"
        
    elsif preset = 9
        # Singing Vowels - musical transitions
        start_f1 = 550
        start_f2 = 1100
        start_f3 = 2350
        end_f1 = 350
        end_f2 = 2000
        end_f3 = 3000
        transition_name$ = "Singing_Vowels"
        
    elsif preset = 10
        # Robot Speech - mechanical transitions
        start_f1 = 400
        start_f2 = 1200
        start_f3 = 2400
        end_f1 = 500
        end_f2 = 1500
        end_f3 = 2600
        transition_name$ = "Robot_Speech"
        
    elsif preset = 11
        # Alien Vowels - extreme formants
        start_f1 = 150
        start_f2 = 3000
        start_f3 = 4000
        end_f1 = 800
        end_f2 = 1200
        end_f3 = 3500
        transition_name$ = "Alien_Vowels"
        
    elsif preset = 12
        # Choral Shift - choir-like transitions
        start_f1 = 500
        start_f2 = 1000
        start_f3 = 2200
        end_f1 = 600
        end_f2 = 1400
        end_f3 = 2600
        transition_name$ = "Choral_Shift"
        
    elsif preset = 13
        # Spectral Morph - complex formant movement
        start_f1 = 300
        start_f2 = 900
        start_f3 = 2100
        end_f1 = 700
        end_f2 = 1800
        end_f3 = 2900
        transition_name$ = "Spectral_Morph"
        
    elsif preset = 14
        # Harmonic Transition - added harmonics
        start_f1 = 450
        start_f2 = 1300
        start_f3 = 2500
        end_f1 = 350
        end_f2 = 1600
        end_f3 = 2700
        transition_name$ = "Harmonic_Transition"
        
    elsif preset = 15
        # Formant Sweep - wide frequency range
        start_f1 = 250
        start_f2 = 700
        start_f3 = 1800
        end_f1 = 850
        end_f2 = 2400
        end_f3 = 3200
        transition_name$ = "Formant_Sweep"
        
    elsif preset = 16
        # Vocal Journey - through multiple vowels
        start_f1 = 730
        start_f2 = 1090
        start_f3 = 2440
        end_f1 = 730
        end_f2 = 1090
        end_f3 = 2440
        transition_name$ = "Vocal_Journey"
        
    else
        # Custom - use the selected transition
        if preset = 2
            start_f1 = 730; start_f2 = 1090; start_f3 = 2440
            end_f1 = 270; end_f2 = 2290; end_f3 = 3010
            transition_name$ = "A_to_I"
        elsif preset = 3
            start_f1 = 270; start_f2 = 2290; start_f3 = 3010
            end_f1 = 300; end_f2 = 870; end_f3 = 2240
            transition_name$ = "I_to_U"
        elsif preset = 4
            start_f1 = 300; start_f2 = 870; start_f3 = 2240
            end_f1 = 730; end_f2 = 1090; end_f3 = 2440
            transition_name$ = "U_to_A"
        else
            start_f1 = 730; start_f2 = 1090; start_f3 = 2440
            end_f1 = 730; end_f2 = 1090; end_f3 = 2440
            transition_name$ = "All_vowels"
        endif
    endif
endif

echo Using preset: 'preset' - 'transition_name$'

# Create the vowel transition sound
if preset = 5 or preset = 6 or preset = 16
    # Complex cycle through all vowels
    formula$ = "("
    formula$ = formula$ + "0.4*sin(2*pi*120*x) + "
    formula$ = formula$ + "0.6*sin(2*pi*(400 + 400*sin(2*pi*0.25*x))*x) + "  # F1 varies
    formula$ = formula$ + "0.5*sin(2*pi*(1000 + 1500*(0.5+0.5*sin(2*pi*0.2*x)))*x) + "  # F2 varies
    formula$ = formula$ + "0.3*sin(2*pi*(2000 + 1500*(0.5+0.5*sin(2*pi*0.15*x)))*x)"  # F3 varies
    formula$ = formula$ + ") * (0.7 + 0.3*sin(2*pi*0.1*x)) * exp(-0.1*x/" + string$(duration) + ")"
else
    # Smooth transition between two vowels
    formula$ = "("
    formula$ = formula$ + "0.4*sin(2*pi*120*x) + "
    formula$ = formula$ + "0.6*sin(2*pi*(" + string$(start_f1) + " + (" + string$(end_f1) + "-" + string$(start_f1) + ")*(x/" + string$(duration) + "))*x) + "
    formula$ = formula$ + "0.5*sin(2*pi*(" + string$(start_f2) + " + (" + string$(end_f2) + "-" + string$(start_f2) + ")*(x/" + string$(duration) + "))*x) + "
    formula$ = formula$ + "0.3*sin(2*pi*(" + string$(start_f3) + " + (" + string$(end_f3) + "-" + string$(start_f3) + ")*(x/" + string$(duration) + "))*x)"
    formula$ = formula$ + ") * (0.8 + 0.2*sin(2*pi*0.3*x)) * exp(-0.2*x/" + string$(duration) + ")"
endif

Create Sound from formula: "vowel_output", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9

# ====== SPATIAL PROCESSING ======
select Sound vowel_output

if spatial_mode = 1
    # MONO - Keep as is
    Rename: "vowel_transition_mono"
    output_sound = selected("Sound")
    
elsif spatial_mode = 2
    # STEREO VOICE - Formants spread across stereo
    Copy: "vowel_left"
    left_sound = selected("Sound")
    
    select Sound vowel_output
    Copy: "vowel_right" 
    right_sound = selected("Sound")
    
    # Left channel: emphasize lower formants
    select left_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 0, 2000, 100
    
    # Right channel: emphasize higher formants
    select right_sound
    Formula: "self * 0.9"
    Filter (pass Hann band): 150, 4000, 100
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "vowel_transition_stereo"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 3
    # ROTATING FORMANTS - Formants move around listener
    Copy: "vowel_left"
    left_sound = selected("Sound")
    
    select Sound vowel_output
    Copy: "vowel_right"
    right_sound = selected("Sound")
    
    # Apply rotating panning
    rotation_rate = 0.15
    select left_sound
    Formula: "self * (0.5 + 0.4 * cos(2*pi*rotation_rate*x))"
    
    select right_sound
    Formula: "self * (0.5 + 0.4 * sin(2*pi*rotation_rate*x))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "vowel_transition_rotating"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 4
    # BINAURAL VOWELS - 3D vocal space
    Copy: "vowel_left"
    left_sound = selected("Sound")
    
    select Sound vowel_output
    Copy: "vowel_right"
    right_sound = selected("Sound")
    
    # Left channel: warm, close
    select left_sound
    Filter (pass Hann band): 80, 3000, 80
    Formula: "self * (0.8 + 0.1 * sin(2*pi*x*0.2))"
    
    # Right channel: bright, slightly delayed
    select right_sound
    Filter (pass Hann band): 100, 3500, 80
    Formula: "self * (0.7 + 0.2 * cos(2*pi*x*0.25))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "vowel_transition_binaural"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 5
    # WIDE TRANSITION - Extreme stereo width
    Copy: "vowel_left"
    left_sound = selected("Sound")
    
    select Sound vowel_output
    Copy: "vowel_right" 
    right_sound = selected("Sound")
    
    # Left channel: very low frequencies
    select left_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 0, 1500, 120
    
    # Right channel: very high frequencies
    select right_sound
    Formula: "self * 0.8"
    Filter (pass Hann band): 200, 5000, 120
    
    # Combine to stereo
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "vowel_transition_wide"
    output_sound = selected("Sound")
    
    # Cleanup
    select left_sound
    plus right_sound
    Remove
    
elsif spatial_mode = 6
    # PANNING MORPH - Panning evolves with formants
    Copy: "vowel_left"
    left_sound = selected("Sound")
    
    select Sound vowel_output
    Copy: "vowel_right"
    right_sound = selected("Sound")
    
    # Panning evolves from left to right
    select left_sound
    Formula: "self * (0.6 + 0.3 * (1 - x/" + string$(duration) + "))"
    
    select right_sound
    Formula: "self * (0.6 + 0.3 * (x/" + string$(duration) + "))"
    
    select left_sound
    plus right_sound
    Combine to stereo
    Rename: "vowel_transition_panning"
    output_sound = selected("Sound")
    
    select left_sound
    plus right_sound
    Remove
endif

select output_sound
Play

echo Dynamic Vowel Transition complete!
echo Preset: 'preset' - 'transition_name$'
echo Spatial mode: 'spatial_mode'