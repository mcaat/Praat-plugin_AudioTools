# ============================================================
# Praat AudioTools - Unified Multi-Mode Vibrato (v2.0)
# Based on original scripts by Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 2.0 (Merged)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   A comprehensive vibrato tool offering Standard, Chirped, 
#   Rate-Modulated, Swarm, and Enveloped modes.
#
# Citation:
#   Cohen, S. (2025).
#   Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Unified Vibrato Generator (Final)
    comment Select a Preset or choose 'Custom' to tweak settings:
    optionmenu Preset 1
        option Custom (Select Mode below)
        option Classic Vocal Vibrato
        option Subtle Warmth
        option Leslie Speaker (Fast)
        option Leslie Speaker (Slow)
        option Ghostly Chirp (Accelerating)
        option Drunk Tape (Wobbly Speed)
        option Insect Swarm (Chorus)
        option Fade-In Vibrato
        option -- TAPE EFFECTS --
        option Vintage Cassette (Wow & Flutter)
        option Old Reel-to-Reel (Slow Wow)
        option Damaged Tape (Heavy)
        option Warped Vinyl (Slow)
        option VHS Tracking (Fast Flutter)
    
    comment --- Custom Mode (Used only if Preset is 'Custom') ---
    optionmenu Manual_Mode 1
        option Standard
        option Chirped
        option Rate Mod
        option Swarm
        option Enveloped
        option Rotary
        option Tape (Wow & Flutter)
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# 1. INITIALIZE DEFAULTS
# ============================================================
base_delay_ms = 5.0
modulation_depth = 0.10
base_rate_hz = 5.0
sweep_rate_hz_per_sec = 2.0
rate_sensitivity = 3.0
rate_mod_freq_hz = 0.8
number_of_layers = 6
layer_spread_hz = 0.5
attack_time_sec = 0.5
release_time_sec = 0.5
rotary_AM_Depth = 0.4
wow_Rate_Hz = 0.5
wow_Depth = 0.15
flutter_Rate_Hz = 6.0
flutter_Depth = 0.05

# ============================================================
# 2. PRESET LOGIC (Unpacked for Safety)
# ============================================================

if preset = 1
    # --- CUSTOM MODE (Pop-up Forms) ---
    mode = manual_Mode
    
    if mode = 1
        beginPause("Standard Vibrato Settings")
            positive: "base_delay_ms", 5.0
            positive: "modulation_depth", 0.10
            positive: "base_rate_hz", 5.0
        endPause("Run", 1)
    elsif mode = 2
        beginPause("Chirped Vibrato Settings")
            positive: "base_delay_ms", 5.0
            positive: "modulation_depth", 0.12
            positive: "base_rate_hz", 2.0
            positive: "sweep_rate_hz_per_sec", 2.0
        endPause("Run", 1)
    elsif mode = 3
        beginPause("Rate Modulation Settings")
            positive: "base_delay_ms", 10.0
            positive: "modulation_depth", 0.15
            positive: "base_rate_hz", 0.5
            positive: "rate_sensitivity", 3.0
            positive: "rate_mod_freq_hz", 0.8
        endPause("Run", 1)
    elsif mode = 4
        beginPause("Swarm / Chorus Settings")
            positive: "base_delay_ms", 5.0
            positive: "modulation_depth", 0.08
            positive: "base_rate_hz", 8.0
            natural: "number_of_layers", 6
            positive: "layer_spread_hz", 0.5
        endPause("Run", 1)
    elsif mode = 5
        beginPause("Enveloped Vibrato Settings")
            positive: "base_delay_ms", 6.0
            positive: "modulation_depth", 0.15
            positive: "base_rate_hz", 5.5
            positive: "attack_time_sec", 0.5
            positive: "release_time_sec", 0.5
        endPause("Run", 1)
    elsif mode = 6
        beginPause("Rotary Speaker Settings")
            positive: "base_delay_ms", 5.0
            positive: "modulation_depth", 0.10
            positive: "base_rate_hz", 5.0
            positive: "rotary_AM_Depth", 0.4
        endPause("Run", 1)
    elsif mode = 7
        beginPause("Tape (Wow & Flutter) Settings")
            positive: "base_delay_ms", 5.0
            positive: "wow_Rate_Hz", 0.5
            positive: "wow_Depth", 0.15
            positive: "flutter_Rate_Hz", 6.0
            positive: "flutter_Depth", 0.05
        endPause("Run", 1)
    endif

else
    # --- LOAD PRESETS (Hardcoded Values) ---
    
    if preset = 2
        # Classic Vocal
        mode = 1
        base_delay_ms = 5.0
        modulation_depth = 0.08
        base_rate_hz = 5.5
        
    elsif preset = 3
        # Subtle Warmth
        mode = 1
        base_delay_ms = 3.0
        modulation_depth = 0.04
        base_rate_hz = 4.0
        
    elsif preset = 4
        # Leslie Fast
        mode = 6
        base_delay_ms = 5.0
        modulation_depth = 0.12
        base_rate_hz = 6.8
        rotary_AM_Depth = 0.5
        
    elsif preset = 5
        # Leslie Slow
        mode = 6
        base_delay_ms = 8.0
        modulation_depth = 0.15
        base_rate_hz = 1.2
        rotary_AM_Depth = 0.3
        
    elsif preset = 6
        # Ghostly Chirp
        mode = 2
        base_delay_ms = 6.0
        modulation_depth = 0.15
        base_rate_hz = 2.0
        sweep_rate_hz_per_sec = 3.0
        
    elsif preset = 7
        # Drunk Tape
        mode = 3
        base_delay_ms = 10.0
        modulation_depth = 0.2
        base_rate_hz = 0.5
        rate_sensitivity = 4.0
        rate_mod_freq_hz = 0.2
        
    elsif preset = 8
        # Insect Swarm
        mode = 4
        base_delay_ms = 5.0
        modulation_depth = 0.08
        base_rate_hz = 8.0
        number_of_layers = 8
        layer_spread_hz = 1.5
        
    elsif preset = 9
        # Fade-In
        mode = 5
        base_delay_ms = 6.0
        modulation_depth = 0.15
        base_rate_hz = 5.0
        attack_time_sec = 1.0
        release_time_sec = 0.1
        
    elsif preset = 11
        # Vintage Cassette
        mode = 7
        base_delay_ms = 5.0
        wow_Rate_Hz = 0.8
        wow_Depth = 0.1
        flutter_Rate_Hz = 12.0
        flutter_Depth = 0.03
        
    elsif preset = 12
        # Old Reel-to-Reel
        mode = 7
        base_delay_ms = 8.0
        wow_Rate_Hz = 0.3
        wow_Depth = 0.2
        flutter_Rate_Hz = 4.0
        flutter_Depth = 0.05
        
    elsif preset = 13
        # Damaged Tape
        mode = 7
        base_delay_ms = 10.0
        wow_Rate_Hz = 1.5
        wow_Depth = 0.3
        flutter_Rate_Hz = 15.0
        flutter_Depth = 0.1
        
    elsif preset = 14
        # Warped Vinyl
        mode = 7
        base_delay_ms = 12.0
        wow_Rate_Hz = 0.2
        wow_Depth = 0.25
        flutter_Rate_Hz = 0.0
        flutter_Depth = 0.0
        
    elsif preset = 15
        # VHS Tracking
        mode = 7
        base_delay_ms = 4.0
        wow_Rate_Hz = 2.0
        wow_Depth = 0.05
        flutter_Rate_Hz = 25.0
        flutter_Depth = 0.08
    endif
endif

# ============================================================
# 3. PROCESSING ENGINE
# ============================================================

selectObject: original_sound_id
duration = Get total duration
sampling = Get sampling frequency
base = round(base_delay_ms * sampling / 1000)

# Create Output Object
Copy: original_name$ + "_processed"
processed_id = selected("Sound")

# IMPORTANT: Using [row, col] ensures we read the correct channel for stereo files.

if mode = 1
    # STANDARD
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x)))))]"

elsif mode = 2
    # CHIRPED
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' + 'base' * 'modulation_depth' * sin(2 * pi * ('base_rate_hz' * x + 0.5 * 'sweep_rate_hz_per_sec' * x^2)))))]"

elsif mode = 3
    # RATE MOD
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' + 'base' * 'modulation_depth' * sin(2 * pi * ('base_rate_hz' + 'rate_sensitivity' * sin(2 * pi * 'rate_mod_freq_hz' * x)) * x))))]"

elsif mode = 4
    # SWARM (Additive)
    # Start with silence
    Formula: "0"
    for d from 1 to number_of_layers
        current_rate = base_rate_hz + (d - 1) * layer_spread_hz
        current_phase = d * (2 * pi / number_of_layers)
        weight = 1 / number_of_layers
        Formula: "self + Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' * (1 + 'modulation_depth' * sin(2 * pi * current_rate * x + current_phase))))) ] * weight"
    endfor

elsif mode = 5
    # ENVELOPED
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' + 'base' * 'modulation_depth' * max(0, min(1, min(x/'attack_time_sec', ('duration' - x)/'release_time_sec'))) * sin(2 * pi * 'base_rate_hz' * x))))]"

elsif mode = 6
    # ROTARY
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' * (1 + 'modulation_depth' * sin(2 * pi * 'base_rate_hz' * x)))))] * (1 - 'rotary_AM_Depth' * 0.5 * (1 + sin(2 * pi * 'base_rate_hz' * x + 1.57)))"

elsif mode = 7
    # TAPE (WOW & FLUTTER)
    Formula: "Sound_SourceAudio_Temp[row, max(1, min(ncol, col - round('base' * (1 + 'wow_Depth' * sin(2 * pi * 'wow_Rate_Hz' * x) + 'flutter_Depth' * sin(2 * pi * 'flutter_Rate_Hz' * x)))))]"

endif

# ============================================================
# 4. CLEANUP
# ============================================================

# Restore original name
selectObject: original_sound_id
Rename: original_name$

# Finalize output
selectObject: processed_id
Scale peak: scale_peak

if play_after_processing
    Play
endif
