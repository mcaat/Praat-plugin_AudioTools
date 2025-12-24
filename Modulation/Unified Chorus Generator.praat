# ============================================================
# Praat AudioTools - Unified Chorus Generator (v2.0)
# Based on original scripts by Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 2.0 (Merged including Orbit)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   A flexible Chorus/Ensemble effect offering Dual Tap, Tri Tap, 
#   and Orbit (Drifting Phase) modes.
#
# Citation:
#   Cohen, S. (2025).
#   Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Unified Chorus Generator
    comment Mode Selection
    choice Chorus_Mode 2
        button Dual Tap (Standard 2-Voice)
        button Tri Tap (Rich 3-Voice)
        button Orbit (Counter-Rotating Phase)
    
    comment Presets (Overwrites custom settings if not 'Custom')
    optionmenu Preset 1
        option Custom
        option Subtle Chorus
        option Classic Chorus
        option Rich Ensemble
        option Deep Shimmer
        option Space Orbit (Orbit Mode)
    
    comment --- Signal Balance ---
    positive Dry_Mix 0.7
    positive Wet_Mix 0.5
    
    comment --- Delay Settings ---
    positive Base_delay_ms 10.0
    positive Modulation_depth 0.15
    
    comment --- Standard Rates (Hz) ---
    positive Rate_1 2.5
    positive Rate_2 4.2
    positive Rate_3 6.3
    
    comment --- Orbit Settings (Mode 3 Only) ---
    positive Phase_drift_hz 0.2
    
    comment --- Output Options ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# ============================================================
# PRESET LOGIC
# ============================================================
if preset = 2
    # Subtle
    base_delay_ms = 8.0; modulation_depth = 0.08
    rate_1 = 2.0; rate_2 = 3.5; rate_3 = 5.0
elsif preset = 3
    # Classic
    base_delay_ms = 12.0; modulation_depth = 0.15
    rate_1 = 2.5; rate_2 = 4.2; rate_3 = 6.3
elsif preset = 4
    # Rich Ensemble
    base_delay_ms = 15.0; modulation_depth = 0.2
    rate_1 = 1.5; rate_2 = 3.8; rate_3 = 5.5
elsif preset = 5
    # Deep Shimmer
    base_delay_ms = 20.0; modulation_depth = 0.25
    rate_1 = 0.8; rate_2 = 2.4; rate_3 = 4.0
elsif preset = 6
    # Space Orbit
    chorus_Mode = 3
    base_delay_ms = 10.0; modulation_depth = 0.2
    rate_1 = 3.0 
    phase_drift_hz = 0.15
endif

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original sound info
sound = selected("Sound")
sound$ = selected$("Sound")
selectObject: sound
sampling = Get sampling frequency

# Calculate base delay in samples
base = round(base_delay_ms * sampling / 1000)

# Create output name
if chorus_Mode = 1
    suffix$ = "_chorus_dual"
elsif chorus_Mode = 2
    suffix$ = "_chorus_tri"
else
    suffix$ = "_chorus_orbit"
endif

Copy: sound$ + suffix$

# ============================================================
# APPLY EFFECT
# ============================================================

if chorus_Mode = 1
    # DUAL TAP (Standard)
    # Tap 1 and Tap 2 have fixed distinct rates
    Formula: "'dry_Mix' * self + 'wet_Mix' * (self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_1'*x)))] + self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_2'*x + 2.0)))]) / 2"

elsif chorus_Mode = 2
    # TRI TAP (Rich)
    # 3 Taps with fixed distinct rates
    Formula: "'dry_Mix' * self + 'wet_Mix' * (self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_1'*x)))] + self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_2'*x + 2.1)))] + self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_3'*x + 4.2)))]) / 3"

elsif chorus_Mode = 3
    # ORBIT (Drifting Phase)
    # Tap 1 drifts Forward (+drift), Tap 2 drifts Backward (-drift)
    # They both use Rate 1 as the base speed
    Formula: "'dry_Mix' * self + 'wet_Mix' * (self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_1'*x + 2*pi*'phase_drift_hz'*x)))] + self[col - round('base' * (1 + 'modulation_depth' * sin(2*pi*'rate_1'*x - 2*pi*'phase_drift_hz'*x + 3.14)))]) / 2"

endif

# Scale to peak
Scale peak: scale_peak

if play_after_processing
    Play
endif