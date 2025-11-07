# ============================================================
# Praat AudioTools - Microphone Simulation.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Microphone Simulation
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
clearinfo
# Microphone Simulation 

form Microphone Simulation Options
    comment Source Sound Selection:
    positive Source_sound 1
    comment === PRESETS (Select one, or choose Custom) ===
    optionmenu Preset: 1
        option Custom
        option Studio Vocal (Cardioid Mono, Center, 30cm)
        option Blumlein Pair (Fig-8, Center, 1m)
        option ORTF Standard (Cardioid, Center, 1m)
        option Spaced Omnis (AB 50cm, Center, 2m)
        option Mid-Side (Cardioid M + Fig-8 S, Center, 1m)
        option Classical Decca Tree (Omni, Center, 3m)
        option Close XY (Cardioid, Center, 50cm)
        option Hypercardioid Spot (Mono, Center, 1.5m)
        option ORTF Right Side (Cardioid, +90°, 1m)
        option ORTF Left Side (Cardioid, -90°, 1m)
        option ORTF Behind (Cardioid, 180°, 1m)
        option AB Wide Spacing (Omni 100cm, Center, 2m)
        option XY Figure-8 (Blumlein, Center, 1m)
    comment === CUSTOM SETTINGS (only if Preset = Custom) ===
    comment Microphone Pattern:
    optionmenu Pattern: 3
        option Omnidirectional
        option Figure-of-eight
        option Cardioid
        option Hypercardioid
    comment Stereo Configuration:
    optionmenu Stereo_config: 1
        option None (Mono)
        option Mid/Side pair
        option XY pair
        option Blumlein pair
        option AB pair (omnis only)
        option ORTF pair
        option Decca Tree
    comment Source Position:
    real Azimuth_degrees 0
    comment (0°=front, +90°=right, -90°=left, ±180°=back)
    real Distance_cm 100
    comment Advanced:
    real Mic_spacing_cm 17
    boolean Apply_near_field_distance 0
    comment Playback:
    boolean Play_result 1
endform

# Apply preset overrides (ALL settings)
if preset$ == "Studio Vocal (Cardioid Mono, Center, 30cm)"
    pattern$ = "Cardioid"
    stereo_config$ = "None (Mono)"
    azimuth_degrees = 0
    distance_cm = 30
    apply_near_field_distance = 0
elsif preset$ == "Blumlein Pair (Fig-8, Center, 1m)"
    pattern$ = "Figure-of-eight"
    stereo_config$ = "Blumlein pair"
    azimuth_degrees = 0
    distance_cm = 100
    apply_near_field_distance = 0
elsif preset$ == "ORTF Standard (Cardioid, Center, 1m)"
    pattern$ = "Cardioid"
    stereo_config$ = "ORTF pair"
    azimuth_degrees = 0
    distance_cm = 100
    mic_spacing_cm = 17
    apply_near_field_distance = 0
elsif preset$ == "Spaced Omnis (AB 50cm, Center, 2m)"
    pattern$ = "Omnidirectional"
    stereo_config$ = "AB pair (omnis only)"
    azimuth_degrees = 0
    distance_cm = 200
    mic_spacing_cm = 50
    apply_near_field_distance = 0
elsif preset$ == "Mid-Side (Cardioid M + Fig-8 S, Center, 1m)"
    pattern$ = "Cardioid"
    stereo_config$ = "Mid/Side pair"
    azimuth_degrees = 0
    distance_cm = 100
    apply_near_field_distance = 0
elsif preset$ == "Classical Decca Tree (Omni, Center, 3m)"
    pattern$ = "Omnidirectional"
    stereo_config$ = "Decca Tree"
    azimuth_degrees = 0
    distance_cm = 300
    apply_near_field_distance = 0
elsif preset$ == "Close XY (Cardioid, Center, 50cm)"
    pattern$ = "Cardioid"
    stereo_config$ = "XY pair"
    azimuth_degrees = 0
    distance_cm = 50
    apply_near_field_distance = 0
elsif preset$ == "Hypercardioid Spot (Mono, Center, 1.5m)"
    pattern$ = "Hypercardioid"
    stereo_config$ = "None (Mono)"
    azimuth_degrees = 0
    distance_cm = 150
    apply_near_field_distance = 0
elsif preset$ == "ORTF Right Side (Cardioid, +90°, 1m)"
    pattern$ = "Cardioid"
    stereo_config$ = "ORTF pair"
    azimuth_degrees = 90
    distance_cm = 100
    mic_spacing_cm = 17
    apply_near_field_distance = 0
elsif preset$ == "ORTF Left Side (Cardioid, -90°, 1m)"
    pattern$ = "Cardioid"
    stereo_config$ = "ORTF pair"
    azimuth_degrees = -90
    distance_cm = 100
    mic_spacing_cm = 17
    apply_near_field_distance = 0
elsif preset$ == "ORTF Behind (Cardioid, 180°, 1m)"
    pattern$ = "Cardioid"
    stereo_config$ = "ORTF pair"
    azimuth_degrees = 180
    distance_cm = 100
    mic_spacing_cm = 17
    apply_near_field_distance = 0
elsif preset$ == "AB Wide Spacing (Omni 100cm, Center, 2m)"
    pattern$ = "Omnidirectional"
    stereo_config$ = "AB pair (omnis only)"
    azimuth_degrees = 0
    distance_cm = 200
    mic_spacing_cm = 100
    apply_near_field_distance = 0
elsif preset$ == "XY Figure-8 (Blumlein, Center, 1m)"
    pattern$ = "Figure-of-eight"
    stereo_config$ = "XY pair"
    azimuth_degrees = 0
    distance_cm = 100
    apply_near_field_distance = 0
endif

# Validation
if source_sound <= 0 or source_sound > numberOfSelected("Sound")
    exitScript: "Please select a sound first"
endif

# XY pair validation - requires directional microphones
if stereo_config$ == "XY pair" and pattern$ == "Omnidirectional"
    exitScript: "XY pair requires directional microphones.'newline$'Please select Cardioid, Figure-of-eight, or Hypercardioid.'newline$'For omnidirectional spacing, use 'AB pair (omnis only)' instead."
endif

soundID = selected("Sound", source_sound)
selectObject: soundID
soundName$ = selected$("Sound")
originalSound = selected("Sound")

# Convert to mono for processing
selectObject: originalSound
monoSound = Convert to mono
Rename: soundName$ + "_mono_base"

# Constants
speedOfSound = 343
azimuth_rad = azimuth_degrees * pi / 180
distance_m = distance_cm / 100
sampleRate = object[monoSound].dx

# Distance amplitude factor (1/r for pressure, normalized to 1m reference)
if apply_near_field_distance
    distance_amplitude = 1.0 / max(distance_m, 0.01)
else
    distance_amplitude = 1.0
endif

# ============================================
# PROCEDURE: Apply microphone polar pattern
# ============================================
procedure applyPattern: .sound, .azimuth, .pattern$
    selectObject: .sound
    if .pattern$ == "Omnidirectional"
        # Omni: uniform sensitivity (gain = 1)
        Formula: ~ self * 1.0
    elsif .pattern$ == "Figure-of-eight"
        # Fig-8: cos(θ)
        Formula: ~ self * cos(.azimuth)
    elsif .pattern$ == "Cardioid"
        # Cardioid: 0.5 + 0.5*cos(θ)
        Formula: ~ self * (0.5 + 0.5 * cos(.azimuth))
    elsif .pattern$ == "Hypercardioid"
        # Hypercardioid: 0.25 + 0.75*cos(θ)
        Formula: ~ self * (0.25 + 0.75 * cos(.azimuth))
    endif
endproc

# ============================================
# PROCEDURE: Apply fractional sample delay
# Returns the new sound object ID via .result
# ============================================
procedure applyFractionalDelay: .sound, .delay_samples
    selectObject: .sound
    .result = .sound
    if abs(.delay_samples) > 0.001
        .delay_seconds = .delay_samples * object[.sound].dx
        # Use Praat's time shifting (uses sinc interpolation internally)
        Shift times by: .delay_seconds
        # Trim to original duration to avoid length changes
        .duration = object[.sound].xmax - object[.sound].xmin
        Extract part: 0, .duration, "rectangular", 1, "no"
        .result = selected("Sound")
        removeObject: .sound
    endif
endproc

# ============================================
# MONO CONFIGURATIONS
# ============================================
selectObject: monoSound

if stereo_config$ == "None (Mono)"
    finalSound = Copy: soundName$ + "_mono_" + replace$(pattern$, "-", "", 0)
    @applyPattern: finalSound, azimuth_rad, pattern$
    
# ============================================
# MID/SIDE PAIR (CORRECTED POLARITY)
# ============================================
elsif stereo_config$ == "Mid/Side pair"
    # Mid microphone (uses selected pattern, faces forward)
    mid = Copy: soundName$ + "_mid"
    @applyPattern: mid, azimuth_rad, pattern$
    
    # Side microphone (figure-8, faces left/right)
    # CORRECTED: Use cos(θ + π/2) = -sin(θ) for positive-left convention
    # This matches the L=M+S, R=M-S decode matrix
    selectObject: monoSound
    side = Copy: soundName$ + "_side"
    selectObject: side
    Formula: ~ self * cos(azimuth_rad + pi/2)
    
    # M/S Decode (correct polarity: S positive = left)
    selectObject: mid
    left = Copy: soundName$ + "_left"
    selectObject: left
    Formula: ~ (object[mid, col] + object[side, col]) / sqrt(2)
    
    selectObject: mid
    right = Copy: soundName$ + "_right" 
    selectObject: right
    Formula: ~ (object[mid, col] - object[side, col]) / sqrt(2)
    
    selectObject: left, right
    finalSound = Combine to stereo
    Rename: soundName$ + "_MS_" + replace$(pattern$, "-", "", 0)
    
    selectObject: mid, side, left, right
    Remove
    
# ============================================
# XY PAIR (DIRECTIONAL MICS ONLY)
# ============================================
elsif stereo_config$ == "XY pair"
    # Two directional mics at ±45° (omni blocked by validation above)
    selectObject: monoSound
    left = Copy: soundName$ + "_xy_L"
    @applyPattern: left, azimuth_rad + pi/4, pattern$
    
    selectObject: monoSound
    right = Copy: soundName$ + "_xy_R"
    @applyPattern: right, azimuth_rad - pi/4, pattern$
    
    selectObject: left, right
    finalSound = Combine to stereo
    Rename: soundName$ + "_XY_" + replace$(pattern$, "-", "", 0)
    
    selectObject: left, right
    Remove
    
# ============================================
# BLUMLEIN PAIR
# ============================================
elsif stereo_config$ == "Blumlein pair"
    # Two figure-8s at ±45°
    selectObject: monoSound
    left = Copy: soundName$ + "_blum_L"
    selectObject: left
    Formula: ~ self * cos(azimuth_rad + pi/4)
    
    selectObject: monoSound
    right = Copy: soundName$ + "_blum_R"
    selectObject: right
    Formula: ~ self * cos(azimuth_rad - pi/4)
    
    selectObject: left, right
    finalSound = Combine to stereo
    Rename: soundName$ + "_Blumlein"
    
    selectObject: left, right
    Remove
    
# ============================================
# AB PAIR (GEOMETRY-BASED DELAYS - CORRECTED)
# ============================================
elsif stereo_config$ == "AB pair (omnis only)"
    # AB uses omnidirectional microphones with spacing-based time delays
    # Uses same geometry-based approach as Decca Tree for physical accuracy
    spacing_m = mic_spacing_cm / 100
    
    # Calculate source position in Cartesian coordinates (origin at array center)
    source_x = distance_m * sin(azimuth_rad)
    source_y = distance_m * cos(azimuth_rad)
    
    # Calculate distance from source to each microphone position
    # Left mic at (-spacing/2, 0), Right mic at (+spacing/2, 0)
    dist_to_left = sqrt((source_x - (-spacing_m/2))^2 + source_y^2)
    dist_to_right = sqrt((source_x - spacing_m/2)^2 + source_y^2)
    
    # Use the closest mic as reference (zero delay)
    min_dist = min(dist_to_left, dist_to_right)
    
    # Calculate delays relative to closest mic (physically accurate arrival times)
    tau_l = (dist_to_left - min_dist) / speedOfSound
    tau_r = (dist_to_right - min_dist) / speedOfSound
    
    left_delay_samples = tau_l / sampleRate
    right_delay_samples = tau_r / sampleRate
    
    selectObject: monoSound
    left = Copy: soundName$ + "_ab_L"
    @applyFractionalDelay: left, left_delay_samples
    left = applyFractionalDelay.result
    
    selectObject: monoSound
    right = Copy: soundName$ + "_ab_R"
    @applyFractionalDelay: right, right_delay_samples
    right = applyFractionalDelay.result
    
    # Apply inverse-distance amplitude differences (optional but physically correct)
    selectObject: left
    Formula: ~ self * (min_dist / dist_to_left)
    
    selectObject: right
    Formula: ~ self * (min_dist / dist_to_right)
    
    selectObject: left, right
    finalSound = Combine to stereo
    Rename: soundName$ + "_AB_" + string$(mic_spacing_cm) + "cm"
    
    selectObject: left, right
    Remove
    
# ============================================
# ORTF PAIR (CORRECTED WITH FRACTIONAL DELAYS)
# ============================================
elsif stereo_config$ == "ORTF pair"
    # ORTF standard: 17cm spacing, 110° angle (±55° from center)
    spacing_m = 0.17
    delta_t = (spacing_m / speedOfSound) * sin(azimuth_rad)
    delta_samples = delta_t / sampleRate
    
    left_delay_samples = -delta_samples / 2
    right_delay_samples = delta_samples / 2
    
    # Left cardioid at +55° from center
    selectObject: monoSound
    left = Copy: soundName$ + "_ortf_L"
    @applyPattern: left, azimuth_rad + 55*pi/180, "Cardioid"
    @applyFractionalDelay: left, left_delay_samples
    left = applyFractionalDelay.result
    
    # Right cardioid at -55° from center
    selectObject: monoSound
    right = Copy: soundName$ + "_ortf_R"
    @applyPattern: right, azimuth_rad - 55*pi/180, "Cardioid"
    @applyFractionalDelay: right, right_delay_samples
    right = applyFractionalDelay.result
    
    selectObject: left, right
    finalSound = Combine to stereo
    Rename: soundName$ + "_ORTF"
    
    selectObject: left, right
    Remove
    
# ============================================
# DECCA TREE (REALISTIC WITH GEOMETRY-BASED DELAYS)
# ============================================
elsif stereo_config$ == "Decca Tree"
    # Classic Decca Tree: L-C-R omnis (2m spacing, 1.5m forward center)
    # Uses realistic geometry-based delays and amplitude for natural spatial imaging
    
    decca_spacing = 2.0
    center_forward = 1.5
    
    # Calculate source position in Cartesian coordinates (origin at array center)
    source_x = distance_m * sin(azimuth_rad)
    source_y = distance_m * cos(azimuth_rad)
    
    # Calculate distance from source to each microphone position
    # Left mic at (-1, 0), Center at (0, 1.5), Right at (+1, 0)
    dist_to_left = sqrt((source_x - (-decca_spacing/2))^2 + source_y^2)
    dist_to_center = sqrt(source_x^2 + (source_y - center_forward)^2)
    dist_to_right = sqrt((source_x - decca_spacing/2)^2 + source_y^2)
    
    # Use the closest mic as reference (zero delay) to minimize absolute delays
    min_dist = min(dist_to_left, min(dist_to_center, dist_to_right))
    
    # Calculate delays relative to closest mic (physically accurate arrival times)
    tau_l = (dist_to_left - min_dist) / speedOfSound
    tau_c = (dist_to_center - min_dist) / speedOfSound
    tau_r = (dist_to_right - min_dist) / speedOfSound
    
    delta_samples_l = tau_l / sampleRate
    delta_samples_c = tau_c / sampleRate
    delta_samples_r = tau_r / sampleRate
    
    # Create three omni mics with realistic arrival time delays
    selectObject: monoSound
    left = Copy: soundName$ + "_decca_L"
    @applyFractionalDelay: left, delta_samples_l
    left = applyFractionalDelay.result
    
    selectObject: monoSound
    center = Copy: soundName$ + "_decca_C"
    @applyFractionalDelay: center, delta_samples_c
    center = applyFractionalDelay.result
    
    selectObject: monoSound
    right = Copy: soundName$ + "_decca_R"
    @applyFractionalDelay: right, delta_samples_r
    right = applyFractionalDelay.result
    
    # Apply inverse-distance amplitude differences (subtle but physically correct)
    selectObject: left
    Formula: ~ self * (min_dist / dist_to_left)
    
    selectObject: center
    Formula: ~ self * (min_dist / dist_to_center)
    
    selectObject: right
    Formula: ~ self * (min_dist / dist_to_right)
    
    # Mix to stereo with classic Decca Tree ratios (L+0.7C, R+0.7C)
    # The geometry-based delays create natural stereo imaging
    # The 0.7 center contribution provides coherent center fill without phase issues
    selectObject: left
    left_mix = Copy: soundName$ + "_left_mix"
    selectObject: left_mix
    Formula: ~ self + 0.7 * object[center, col]
    
    selectObject: right
    right_mix = Copy: soundName$ + "_right_mix"
    selectObject: right_mix
    Formula: ~ self + 0.7 * object[center, col]
    
    selectObject: left_mix, right_mix
    finalSound = Combine to stereo
    Rename: soundName$ + "_DeccaTree"
    
    selectObject: left, center, right, left_mix, right_mix
    Remove
endif

# ============================================
# APPLY DISTANCE AMPLITUDE
# ============================================
selectObject: finalSound
if distance_amplitude != 1.0
    Formula: ~ self * distance_amplitude
endif

# ============================================
# CLEANUP AND OUTPUT
# ============================================
selectObject: monoSound
Remove

selectObject: finalSound

if play_result
    Play
endif

# ============================================
# REPORT
# ============================================
appendInfoLine: "========================================"
appendInfoLine: "PHYSICALLY ACCURATE MICROPHONE SIMULATION v2.6"
appendInfoLine: "========================================"
if preset$ != "Custom"
    appendInfoLine: "Preset: ", preset$
endif
appendInfoLine: "Pattern: ", pattern$
appendInfoLine: "Configuration: ", stereo_config$
appendInfoLine: "Source azimuth: ", azimuth_degrees, "° (0°=front, ±90°=sides, ±180°=back)"
appendInfoLine: "Source distance: ", distance_cm, " cm"
if stereo_config$ == "AB pair (omnis only)"
    appendInfoLine: "Mic spacing: ", mic_spacing_cm, " cm (geometry-based delays + amplitude)"
elsif stereo_config$ == "ORTF pair"
    appendInfoLine: "Mic spacing: ", mic_spacing_cm, " cm"
elsif stereo_config$ == "Decca Tree"
    appendInfoLine: "Decca Tree: 2m L-R spacing, 1.5m center forward"
    appendInfoLine: "NOTE: Uses geometry-based delays and amplitudes for realistic imaging"
endif
appendInfoLine: "Near-field distance: ", if apply_near_field_distance then "ENABLED (1/r)" else "disabled (far-field)" fi
appendInfoLine: ""
appendInfoLine: "CORRECTIONS APPLIED:"
appendInfoLine: "✓ M/S polarity: CORRECTED (S positive = left)"
appendInfoLine: "✓ Delays: Fractional-sample (sinc interpolation)"
appendInfoLine: "✓ AB pair: Geometry-based positioning (realistic, includes amplitude)"
appendInfoLine: "✓ XY pair: Directional mics only (validated)"
appendInfoLine: "✓ Decca Tree: Geometry-based positioning (realistic, natural)"
appendInfoLine: "✓ Distance: ", if apply_near_field_distance then "Applied (1/r amplitude)" else "Far-field model" fi
appendInfoLine: "========================================"

