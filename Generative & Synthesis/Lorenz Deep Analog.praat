# ============================================================
# Praat AudioTools - Lorenz Chaos Explorer
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  Lorenz Chaos Explorer
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Lorenz Chaos Explorer 

form Lorenz Chaos Explorer
    optionmenu Preset: 2
        option Custom
        option Standard Butterfly
        option Deep Drone (Slow)
        option Nervous Insect (Fast)
        option Unstable Giant (High Rho)
    comment Custom Settings (Used only if Preset is 'Custom'):
    real Duration 15.0
    real Base_pitch 200
    real Chaos_speed 0.005
    real Rho 28.0
    boolean Debug_mode 0
endform

Erase all

# --- 1. APPLY PRESETS ---
scale_min_x = -25
scale_max_x = 25
scale_max_z = 50

if preset = 2
    # Standard Butterfly
    duration = 15.0
    base_pitch = 200
    chaos_speed = 0.005
    rho = 28.0
    
elsif preset = 3
    # Deep Drone
    duration = 30.0
    base_pitch = 60
    chaos_speed = 0.001
    rho = 28.0
    
elsif preset = 4
    # Nervous Insect
    duration = 10.0
    base_pitch = 350
    chaos_speed = 0.015
    rho = 28.0
    
elsif preset = 5
    # Unstable Giant
    duration = 20.0
    base_pitch = 120
    chaos_speed = 0.004
    rho = 90.0
    scale_min_x = -50
    scale_max_x = 50
    scale_max_z = 160
endif

if debug_mode
    writeInfoLine: "Preset: ", preset
    appendInfoLine: "Rho: ", rho, " Speed: ", chaos_speed
endif

# --- 2. SETUP MATH ---
control_rate = 500
total_samples = round(duration * control_rate)

# Create vectors for drawing
val_x# = zero#(total_samples)
val_z# = zero#(total_samples)

# Create Sound to hold audio data
Create Sound from formula: "Lorenz_Data", 1, 0, duration, control_rate, "0"

# --- 3. VARIABLES ---
lx = 0.1
ly = 0.1
lz = 0.1

sigma = 10.0
beta = 2.6667

# --- 4. THE LOOP ---
for i from 1 to total_samples
    # Lorenz Equations
    dx = sigma * (ly - lx) * chaos_speed
    dy = (lx * (rho - lz) - ly) * chaos_speed
    dz = (lx * ly - beta * lz) * chaos_speed
    
    # Update State
    lx = lx + dx
    ly = ly + dy
    lz = lz + dz
    
    # Store for Drawing
    val_x#[i] = lx
    val_z#[i] = lz
    
    # Store for Audio (X Axis -> Pitch)
    Set value at sample number: 1, i, lx
endfor

# --- 5. VISUALIZATION (X vs Z) ---
Select outer viewport: 0, 8, 0, 6
Select inner viewport: 1, 7, 1, 5

Axes: scale_min_x, scale_max_x, 0, scale_max_z
Draw inner box

Text top: "yes", "The Lorenz Attractor (X vs Z)"
Text bottom: "yes", "X Axis (Pitch)"
Text left: "yes", "Z Axis (Filter/Timbre)"

Colour: "Blue"

# Draw the shape
prev_x = val_x#[1]
prev_z = val_z#[1]

# Draw every 2nd point for speed
step = 2
for i from 2 to total_samples
    if (i mod step) = 0
        curr_x = val_x#[i]
        curr_z = val_z#[i]
        Draw line: prev_x, prev_z, curr_x, curr_z
        prev_x = curr_x
        prev_z = curr_z
    endif
endfor

# Mark the final spot
Colour: "Red"
Paint circle (mm): "Red", lx, lz, 2

# --- 6. AUDIO GENERATION ---
selectObject: "Sound Lorenz_Data"
Copy: "Audio_Temp"

# Resample to 44.1kHz (this creates a new object)
Resample: 44100, 50
Rename: "Lorenz_Chaos"

# Pitch Formula
mod_depth = 10
if rho > 50
    mod_depth = 5
endif

Formula: "0.5 * sin(2*pi * (base_pitch + (self * mod_depth)) * x)"

# Play
Play

# --- 7. CLEANUP ---
# Remove the Control Rate data and the Temporary Copy
removeObject: "Sound Lorenz_Data"
removeObject: "Sound Audio_Temp"

# Select the final result
selectObject: "Sound Lorenz_Chaos"