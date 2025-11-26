# ============================================================
# Praat AudioTools - Physics-Based Stereo Dynamics.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Applies physics-based amplitude and stereo modulation using
#   bouncing ball simulation with gravity, velocity, and spatial
#   positioning. Creates dynamic stereo effects with distance-based
#   loudness attenuation.
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# Physics-Based Stereo Dynamics
# Features: Bouncing Physics + Distance Loudness + Stereo Panning
# ============================================================

# Get selected sound
if numberOfSelected("Sound") <> 1
    exitScript: "Please select a Sound object first."
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sampling_frequency = Get sampling frequency

# SINGLE UNIFIED FORM
beginPause: "Kinematic Physics Envelope - Stereo Edition"
    comment: "═══════════════════════════════════════"
    comment: "PRESET SELECTION"
    optionMenu: "Preset", 2
        option: "Custom (use parameters below)"
        option: "Bouncy Rubber Ball (L -> R)"
        option: "Steel Ball Drop (Center)"
        option: "Ping Pong Frenzy (Wide Stereo)"
        option: "Basketball Dribble (Right Side)"
        option: "Super Ball Chaos (Fast Pan)"
        option: "Dropping Stone (Center)"
        option: "Feather Falling (L -> R)"
        option: "Moon Gravity (Slow Pan)"
        option: "Tennis Ball (Cross Court)"
        option: "Water Skipping Stone (Fade away)"
        option: "Earthquake Tremor (Stereo Shake)"
        option: "Heartbeat Pulse (Center)"
        option: "Spring Oscillation (Pan Oscillation)"
        option: "Pendulum Swing (Wide Arc)"
        option: "Rolling Downhill (L -> R)"
    comment: "═══════════════════════════════════════"
    comment: "CUSTOM PARAMETERS (used if Custom selected)"
    comment: "Vertical Physics:"
    real: "Initial height", 1.2
    real: "Initial velocity (m/s)", 6.0
    real: "Gravity (m/s²)", 9.8
    real: "Bounce coefficient", 0.75
    natural: "Number of bounces", 8
    comment: "Lateral Physics (Stereo):"
    real: "Pan Start (-1=Left, +1=Right)", -0.9
    real: "Pan End (-1=Left, +1=Right)", 0.9
    real: "Distance attenuation", 0.3
    comment: "Envelope Mapping:"
    optionMenu: "Mapping", 3
        option: "Height to amplitude (potential energy)"
        option: "Velocity to amplitude (kinetic energy)"
        option: "Combined (height + velocity)"
    real: "Amplitude scale", 1.0
endPause: "Cancel", "Apply", 2, 1

# Set parameters based on preset
if preset = 1
    # Custom - use form values
    pan_start = pan_Start
    pan_end = pan_End
    distance_attenuation_strength = distance_attenuation
    preset_name$ = "Custom"
    
elif preset = 2
    # Bouncy Rubber Ball
    initial_height = 1.2
    initial_velocity = 6.0
    gravity = 9.8
    bounce_coefficient = 0.75
    number_of_bounces = 8
    mapping = 3
    amplitude_scale = 1.0
    pan_start = -0.9
    pan_end = 0.9
    distance_attenuation_strength = 0.3
    preset_name$ = "Bouncy_Rubber_Ball"
    
elif preset = 3
    # Steel Ball Drop
    initial_height = 2.0
    initial_velocity = 3.0
    gravity = 9.8
    bounce_coefficient = 0.92
    number_of_bounces = 12
    mapping = 1
    amplitude_scale = 1.2
    pan_start = 0.0
    pan_end = 0.0
    distance_attenuation_strength = 0.0
    preset_name$ = "Steel_Ball_Drop"
    
elif preset = 4
    # Ping Pong Frenzy
    initial_height = 0.8
    initial_velocity = 10.0
    gravity = 9.8
    bounce_coefficient = 0.85
    number_of_bounces = 15
    mapping = 2
    amplitude_scale = 0.9
    pan_start = -1.0
    pan_end = 1.0
    distance_attenuation_strength = 0.5
    preset_name$ = "Ping_Pong_Frenzy"
    
elif preset = 5
    # Basketball Dribble
    initial_height = 1.5
    initial_velocity = 4.0
    gravity = 9.8
    bounce_coefficient = 0.70
    number_of_bounces = 6
    mapping = 3
    amplitude_scale = 1.1
    pan_start = 0.5
    pan_end = 0.7
    distance_attenuation_strength = 0.2
    preset_name$ = "Basketball_Dribble"
    
elif preset = 6
    # Super Ball Chaos
    initial_height = 1.0
    initial_velocity = 8.0
    gravity = 9.8
    bounce_coefficient = 0.95
    number_of_bounces = 20
    mapping = 2
    amplitude_scale = 0.85
    pan_start = -0.8
    pan_end = 0.2
    distance_attenuation_strength = 0.4
    preset_name$ = "Super_Ball_Chaos"
    
elif preset = 7
    # Dropping Stone
    initial_height = 3.0
    initial_velocity = 0.0
    gravity = 12.0
    bounce_coefficient = 0.0
    number_of_bounces = 0
    mapping = 2
    amplitude_scale = 1.5
    pan_start = 0.0
    pan_end = 0.0
    distance_attenuation_strength = 0.0
    preset_name$ = "Dropping_Stone"
    
elif preset = 8
    # Feather Falling
    initial_height = 2.0
    initial_velocity = 1.0
    gravity = 2.0
    bounce_coefficient = 0.3
    number_of_bounces = 3
    mapping = 1
    amplitude_scale = 0.8
    pan_start = -0.5
    pan_end = 0.5
    distance_attenuation_strength = 0.2
    preset_name$ = "Feather_Falling"
    
elif preset = 9
    # Moon Gravity
    initial_height = 1.5
    initial_velocity = 4.0
    gravity = 1.62
    bounce_coefficient = 0.65
    number_of_bounces = 8
    mapping = 3
    amplitude_scale = 1.0
    pan_start = -0.8
    pan_end = 0.8
    distance_attenuation_strength = 0.2
    preset_name$ = "Moon_Gravity"
    
elif preset = 10
    # Tennis Ball
    initial_height = 1.3
    initial_velocity = 5.5
    gravity = 9.8
    bounce_coefficient = 0.73
    number_of_bounces = 7
    mapping = 3
    amplitude_scale = 1.0
    pan_start = -1.0
    pan_end = 1.0
    distance_attenuation_strength = 0.6
    preset_name$ = "Tennis_Ball"
    
elif preset = 11
    # Water Skipping Stone
    initial_height = 0.5
    initial_velocity = 12.0
    gravity = 9.8
    bounce_coefficient = 0.60
    number_of_bounces = 10
    mapping = 2
    amplitude_scale = 0.75
    pan_start = -0.2
    pan_end = 1.5 
    distance_attenuation_strength = 0.8
    preset_name$ = "Water_Skipping_Stone"
    
elif preset = 12
    # Earthquake Tremor
    initial_height = 0.3
    initial_velocity = 3.0
    gravity = 15.0
    bounce_coefficient = 0.88
    number_of_bounces = 25
    mapping = 2
    amplitude_scale = 1.3
    pan_start = -0.3
    pan_end = 0.3
    distance_attenuation_strength = 0.1
    preset_name$ = "Earthquake_Tremor"
    
elif preset = 13
    # Heartbeat Pulse
    initial_height = 0.8
    initial_velocity = 6.0
    gravity = 18.0
    bounce_coefficient = 0.65
    number_of_bounces = 12
    mapping = 2
    amplitude_scale = 1.4
    pan_start = 0.0
    pan_end = 0.0
    distance_attenuation_strength = 0.0
    preset_name$ = "Heartbeat_Pulse"
    
elif preset = 14
    # Spring Oscillation
    initial_height = 1.0
    initial_velocity = 7.0
    gravity = 8.0
    bounce_coefficient = 0.82
    number_of_bounces = 15
    mapping = 3
    amplitude_scale = 0.95
    pan_start = -1.0
    pan_end = 1.0
    distance_attenuation_strength = 0.4
    preset_name$ = "Spring_Oscillation"
    
elif preset = 15
    # Pendulum Swing
    initial_height = 1.8
    initial_velocity = 2.5
    gravity = 5.0
    bounce_coefficient = 0.90
    number_of_bounces = 10
    mapping = 1
    amplitude_scale = 1.1
    pan_start = -1.0
    pan_end = 1.0
    distance_attenuation_strength = 0.7
    preset_name$ = "Pendulum_Swing"
    
else
    # Rolling Downhill
    initial_height = 2.5
    initial_velocity = 1.0
    gravity = 15.0
    bounce_coefficient = 0.45
    number_of_bounces = 5
    mapping = 2
    amplitude_scale = 1.3
    pan_start = -1.0
    pan_end = 1.0
    distance_attenuation_strength = 0.5
    preset_name$ = "Rolling_Downhill"
endif

writeInfoLine: "=== Kinematic Physics Envelope (Stereo) ==="
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Panning: ", fixed$(pan_start, 2), " to ", fixed$(pan_end, 2)

# === PHYSICS SIMULATION ===
numPoints = 500
timeStep = duration / (numPoints - 1)

# Initialize Arrays
for i from 1 to numPoints
    time_'i' = 0
    height_'i' = 0
    velocity_'i' = 0
    pan_'i' = 0
endfor

# Physics simulation variables
current_height = initial_height
current_velocity = initial_velocity
current_time = 0
bounces_done = 0
ground_level = 0

# Simulate ball motion
for i from 1 to numPoints
    time_'i' = current_time
    height_'i' = current_height
    velocity_'i' = abs(current_velocity)
    
    # Calculate Lateral Position
    progress = (i - 1) / (numPoints - 1)
    if preset_name$ = "Spring_Oscillation" or preset_name$ = "Pendulum_Swing"
        pan_'i' = pan_start + (pan_end - pan_start) * sin(progress * pi * 4)
    else
        pan_'i' = pan_start + (pan_end - pan_start) * progress
    endif
    
    # Update Vertical Physics
    current_velocity = current_velocity - gravity * timeStep
    current_height = current_height + current_velocity * timeStep
    
    # Check for bounce
    if current_height <= ground_level and bounces_done < number_of_bounces
        current_height = ground_level
        current_velocity = -current_velocity * bounce_coefficient
        bounces_done = bounces_done + 1
    endif
    
    # Clamp to ground
    if current_height < ground_level
        current_height = ground_level
        current_velocity = 0
    endif
    
    current_time = current_time + timeStep
endfor

# === MAP PHYSICS TO AMPLITUDE & STEREO ===
tierL = Create IntensityTier: "envelope_left", 0, duration
tierR = Create IntensityTier: "envelope_right", 0, duration

max_velocity = initial_velocity + gravity * duration

for i from 1 to numPoints
    t = time_'i'
    h = height_'i'
    v = velocity_'i'
    p = pan_'i'
    
    # 1. Base Physical Amplitude
    if mapping = 1
        amp = h / initial_height
    elif mapping = 2
        amp = v / max_velocity
    else
        amp = (h / initial_height + v / max_velocity) / 2
    endif
    
    # 2. Distance-Based Loudness
    dist = abs(p)
    dist_factor = 1.0 / (1.0 + distance_attenuation_strength * dist)
    amp = amp * amplitude_scale * dist_factor
    
    if amp < 0.001
        amp = 0.001
    endif
    
    # 3. Stereo Panning (Square Root Law)
    p_clamped = p
    if p_clamped < -1
        p_clamped = -1
    endif
    if p_clamped > 1
        p_clamped = 1
    endif
    
    pan_norm = (p_clamped + 1) / 2
    
    amp_L = amp * sqrt(1 - pan_norm)
    amp_R = amp * sqrt(pan_norm)
    
    # CRITICAL FIX: Ensure minimum amplitude for log10
    if amp_L < 0.00001
        amp_L = 0.00001
    endif
    if amp_R < 0.00001
        amp_R = 0.00001
    endif
    
    db_L = 20 * log10(amp_L)
    db_R = 20 * log10(amp_R)
    
    selectObject: tierL
    Add point: t, db_L
    selectObject: tierR
    Add point: t, db_R
endfor

# === APPLY TO SOUND ===
# CRITICAL FIX: Always work on a copy to preserve original
selectObject: sound
Copy: "temp_working_copy"
working_copy = selected("Sound")

# Ensure it's stereo
n_ch_temp = Get number of channels
if n_ch_temp = 1
    Convert to stereo
endif

Extract all channels
ch1 = selected("Sound", 1)
ch2 = selected("Sound", 2)

selectObject: ch1
plusObject: tierL
Multiply: "yes"
ch1_mod = selected("Sound")

selectObject: ch2
plusObject: tierR
Multiply: "yes"
ch2_mod = selected("Sound")

selectObject: ch1_mod
plusObject: ch2_mod
Combine to stereo
Rename: sound_name$ + "_" + preset_name$
final_result = selected("Sound")

Scale peak: 0.99

# === CLEAN UP INTERMEDIATES (original is safe!) ===
selectObject: working_copy
plusObject: ch1
plusObject: ch2
plusObject: ch1_mod
plusObject: ch2_mod
plusObject: tierL
plusObject: tierR
Remove

# === VISUALIZATION ===
Erase all
Black

# Plot Original Sound
selectObject: sound
Select outer viewport: 0, 6, 0, 2
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Green
Text top: "no", "Original: " + sound_name$
Black

# Plot Stereo Result
selectObject: final_result
Select outer viewport: 0, 6, 2, 4
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Blue
Text top: "no", "Result: " + preset_name$
Black

# Visualize Lateral Motion (Pan Trajectory)
Select outer viewport: 0, 6, 4.5, 6.5
Axes: 0, duration, -1.5, 1.5
Draw inner box
Marks bottom every: 1, 0.5, "yes", "yes", "no"
Marks left every: 1, 0.5, "yes", "yes", "no"
Text left: "yes", "Pan Position"
Text bottom: "yes", "Time (s)"

# Draw center line
Grey
Draw line: 0, 0, duration, 0
Black

# Draw Pan Trajectory
Blue
Line width: 2
for i from 2 to numPoints
    prev_i = i - 1
    x_prev = time_'prev_i'
    y_prev = pan_'prev_i'
    x_curr = time_'i'
    y_curr = pan_'i'
    Draw line: x_prev, y_prev, x_curr, y_curr
endfor
Line width: 1
Black

# Draw height markers (bounce visualization)
# FIXED: Ensure marker_size is always > 0
for i from 1 to numPoints
    if i mod 25 = 0
        x = time_'i'
        y = pan_'i'
        h = height_'i'
        marker_size = h / initial_height * 0.15
        # CRITICAL FIX: Ensure radius > 0
        if marker_size < 0.01
            marker_size = 0.01
        endif
        Paint circle: "Red", x, y, marker_size
    endif
endfor

Red
Text top: "no", "Ball Trajectory (Top View)"
Black

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
appendInfoLine: "✓ Original sound preserved: ", sound_name$
appendInfoLine: "✓ Result created: ", sound_name$ + "_" + preset_name$
appendInfoLine: "✓ Pan range: ", fixed$(pan_start, 2), " to ", fixed$(pan_end, 2)
appendInfoLine: "✓ Distance attenuation: ", fixed$(distance_attenuation_strength, 2)
appendInfoLine: ""
appendInfoLine: "Both sounds are now in the Objects list!"

Play