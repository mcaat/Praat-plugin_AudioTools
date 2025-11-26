# ============================================================
# Praat AudioTools - Kinematic Physics Envelope.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Kinematic Physics Envelope
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
# Kinematic Physics Envelope - Bouncing Ball Simulation
# With Creative Presets!
# ============================================================

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sampling_frequency = Get sampling frequency

# Preset selection
beginPause: "Kinematic Physics Envelope - Preset Selection"
    comment: "Choose a physics simulation preset:"
    optionMenu: "Preset", 1
        option: "Custom (set your own)"
        option: "Bouncy Rubber Ball"
        option: "Steel Ball Drop"
        option: "Ping Pong Frenzy"
        option: "Basketball Dribble"
        option: "Super Ball Chaos"
        option: "Dropping Stone (no bounce)"
        option: "Feather Falling"
        option: "Moon Gravity"
        option: "Tennis Ball"
        option: "Water Skipping Stone"
        option: "Earthquake Tremor"
        option: "Heartbeat Pulse"
        option: "Spring Oscillation"
        option: "Pendulum Swing"
        option: "Rolling Downhill"
endPause: "Cancel", "Next", 2, 1

# Set parameters based on preset
if preset = 1
    # Custom - user sets all parameters
    beginPause: "Custom Physics Parameters"
        comment: "Physics Simulation Parameters:"
        real: "Initial height", 1.0
        real: "Initial velocity (m/s)", 5.0
        real: "Gravity (m/s²)", 9.8
        real: "Bounce coefficient", 0.7
        natural: "Number of bounces", 5
        comment: " "
        comment: "Envelope Mapping:"
        optionMenu: "Mapping", 1
            option: "Height to amplitude (direct)"
            option: "Velocity to amplitude (kinetic energy)"
            option: "Combined (height + velocity)"
        real: "Amplitude scale", 1.0
    endPause: "Cancel", "Apply", 2, 1
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
    preset_name$ = "Bouncy Rubber Ball"
    
elif preset = 3
    # Steel Ball Drop
    initial_height = 2.0
    initial_velocity = 3.0
    gravity = 9.8
    bounce_coefficient = 0.92
    number_of_bounces = 12
    mapping = 1
    amplitude_scale = 1.2
    preset_name$ = "Steel Ball Drop"
    
elif preset = 4
    # Ping Pong Frenzy
    initial_height = 0.8
    initial_velocity = 10.0
    gravity = 9.8
    bounce_coefficient = 0.85
    number_of_bounces = 15
    mapping = 2
    amplitude_scale = 0.9
    preset_name$ = "Ping Pong Frenzy"
    
elif preset = 5
    # Basketball Dribble
    initial_height = 1.5
    initial_velocity = 4.0
    gravity = 9.8
    bounce_coefficient = 0.70
    number_of_bounces = 6
    mapping = 3
    amplitude_scale = 1.1
    preset_name$ = "Basketball Dribble"
    
elif preset = 6
    # Super Ball Chaos
    initial_height = 1.0
    initial_velocity = 8.0
    gravity = 9.8
    bounce_coefficient = 0.95
    number_of_bounces = 20
    mapping = 2
    amplitude_scale = 0.85
    preset_name$ = "Super Ball Chaos"
    
elif preset = 7
    # Dropping Stone (no bounce)
    initial_height = 3.0
    initial_velocity = 0.0
    gravity = 12.0
    bounce_coefficient = 0.0
    number_of_bounces = 0
    mapping = 2
    amplitude_scale = 1.5
    preset_name$ = "Dropping Stone"
    
elif preset = 8
    # Feather Falling
    initial_height = 2.0
    initial_velocity = 1.0
    gravity = 2.0
    bounce_coefficient = 0.3
    number_of_bounces = 3
    mapping = 1
    amplitude_scale = 0.8
    preset_name$ = "Feather Falling"
    
elif preset = 9
    # Moon Gravity
    initial_height = 1.5
    initial_velocity = 4.0
    gravity = 1.62
    bounce_coefficient = 0.65
    number_of_bounces = 8
    mapping = 3
    amplitude_scale = 1.0
    preset_name$ = "Moon Gravity"
    
elif preset = 10
    # Tennis Ball
    initial_height = 1.3
    initial_velocity = 5.5
    gravity = 9.8
    bounce_coefficient = 0.73
    number_of_bounces = 7
    mapping = 3
    amplitude_scale = 1.0
    preset_name$ = "Tennis Ball"
    
elif preset = 11
    # Water Skipping Stone
    initial_height = 0.5
    initial_velocity = 12.0
    gravity = 9.8
    bounce_coefficient = 0.60
    number_of_bounces = 10
    mapping = 2
    amplitude_scale = 0.75
    preset_name$ = "Water Skipping Stone"
    
elif preset = 12
    # Earthquake Tremor
    initial_height = 0.3
    initial_velocity = 3.0
    gravity = 15.0
    bounce_coefficient = 0.88
    number_of_bounces = 25
    mapping = 2
    amplitude_scale = 1.3
    preset_name$ = "Earthquake Tremor"
    
elif preset = 13
    # Heartbeat Pulse (double bounce pattern)
    initial_height = 0.8
    initial_velocity = 6.0
    gravity = 18.0
    bounce_coefficient = 0.65
    number_of_bounces = 12
    mapping = 2
    amplitude_scale = 1.4
    preset_name$ = "Heartbeat Pulse"
    
elif preset = 14
    # Spring Oscillation
    initial_height = 1.0
    initial_velocity = 7.0
    gravity = 8.0
    bounce_coefficient = 0.82
    number_of_bounces = 15
    mapping = 3
    amplitude_scale = 0.95
    preset_name$ = "Spring Oscillation"
    
elif preset = 15
    # Pendulum Swing
    initial_height = 1.8
    initial_velocity = 2.5
    gravity = 5.0
    bounce_coefficient = 0.90
    number_of_bounces = 10
    mapping = 1
    amplitude_scale = 1.1
    preset_name$ = "Pendulum Swing"
    
else
    # Rolling Downhill (accelerating)
    initial_height = 2.5
    initial_velocity = 1.0
    gravity = 15.0
    bounce_coefficient = 0.45
    number_of_bounces = 5
    mapping = 2
    amplitude_scale = 1.3
    preset_name$ = "Rolling Downhill"
endif

writeInfoLine: "=== Kinematic Physics Envelope ==="
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: ""
appendInfoLine: "Simulating physics..."
appendInfoLine: "  Initial height: ", initial_height, " m"
appendInfoLine: "  Initial velocity: ", initial_velocity, " m/s"
appendInfoLine: "  Gravity: ", gravity, " m/s²"
appendInfoLine: "  Bounce coefficient: ", bounce_coefficient
appendInfoLine: "  Max bounces: ", number_of_bounces

# === PHYSICS SIMULATION ===
numPoints = 500
timeStep = duration / (numPoints - 1)

# Arrays using simple variables
for i from 1 to numPoints
    time_'i' = 0
    height_'i' = 0
    velocity_'i' = 0
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
    
    # Update physics
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

appendInfoLine: ""
appendInfoLine: "Physics simulation complete!"
appendInfoLine: "  Actual bounces: ", bounces_done

# === MAP PHYSICS TO AMPLITUDE ENVELOPE ===
tier = Create IntensityTier: "physics_envelope", 0, duration

max_velocity = initial_velocity + gravity * duration

for i from 1 to numPoints
    t = time_'i'
    h = height_'i'
    v = velocity_'i'
    
    # Map to amplitude based on selected mapping
    if mapping = 1
        # Height to amplitude (potential energy)
        amp = h / initial_height
    elif mapping = 2
        # Velocity to amplitude (kinetic energy)
        amp = v / max_velocity
    else
        # Combined
        amp = (h / initial_height + v / max_velocity) / 2
    endif
    
    # Apply amplitude scale
    amp = amp * amplitude_scale
    
    # Clamp
    if amp < 0.01
        amp = 0.01
    endif
    if amp > 2.0
        amp = 2.0
    endif
    
    # Convert to dB
    db = 20 * log10(amp)
    
    selectObject: tier
    Add point: t, db
endfor

appendInfoLine: "Envelope created with ", numPoints, " control points"

# === APPLY ENVELOPE TO SOUND ===
selectObject: sound
plusObject: tier
result = Multiply: "yes"
Rename: sound_name$ + "_" + preset_name$

# Normalize
selectObject: result
Scale peak: 0.99

appendInfoLine: ""
appendInfoLine: "=== COMPLETE ==="
appendInfoLine: "Result: ", sound_name$ + "_" + preset_name$
appendInfoLine: ""
if mapping = 1
    mapping_text$ = "Height (potential energy)"
elif mapping = 2
    mapping_text$ = "Velocity (kinetic energy)"
else
    mapping_text$ = "Combined (height + velocity)"
endif
appendInfoLine: "Mapping: ", mapping_text$
appendInfoLine: ""
appendInfoLine: "🎵 Your sound now follows the physics of: ", preset_name$, "!"

# === VISUALIZATION ===
Erase all
Black

# Create trajectory sound
Create Sound from formula: "trajectory", 1, 0, duration, numPoints, "0"
trajectory_sound = selected("Sound")

# Fill with height values
for i from 1 to numPoints
    h = height_'i'
    selectObject: trajectory_sound
    Set value at sample number: 1, i, h
endfor

# Plot physics trajectory
selectObject: trajectory_sound
Select outer viewport: 0, 6, 0, 2
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Blue
Text left: "yes", "Physics: ##" + preset_name$ + "##"
Black

# Plot original sound
selectObject: sound
Select outer viewport: 0, 6, 2, 4
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Text left: "yes", "Original"

# Plot result
selectObject: result
Select outer viewport: 0, 6, 4, 6
Draw: 0, 0, 0, 0, "no", "Curve"
Draw inner box
Marks left every: 1, 0.5, "yes", "yes", "no"
Marks bottom every: 1, 0.5, "yes", "yes", "no"
Red
Text left: "yes", "Result"
Black
Text bottom: "yes", "Time (s)"

# Add preset description
Select outer viewport: 0, 6, 6.2, 6.8
Text top: "no", preset_name$

# Clean up
removeObject: tier, trajectory_sound

selectObject: result
Play