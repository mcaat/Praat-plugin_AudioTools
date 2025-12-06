# ============================================================
# Praat AudioTools - Ray Tracing Room Acoustics.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Ray Tracing Room Acoustics script
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
# PHYSICALLY ACCURATE Ray Tracing Room Acoustics
# ============================================================

form Ray Tracing Room Simulation
    comment === PRESETS ===
    optionmenu Preset: 4
        option Custom (use parameters below)
        option Small Living Room
        option Large Concert Hall
        option Bathroom (Bright)
        option Recording Studio (Dead)
        option Cathedral (Very Long)
        option Small Club
        option Outdoor (Minimal)
        option Bright Chamber
    comment === Room dimensions (meters) ===
    positive room_width 8
    positive room_height 6
    positive room_depth 5
    comment === RAY TRACING PARAMETERS ===
    positive number_of_rays 200
    comment (MORE RAYS = MORE ACCURATE, affects sound!)
    positive max_reflections 15
    comment (higher = longer reverb tail)
    positive listener_radius 0.5
    comment (capture radius around listener in meters)
    comment === Acoustic parameters ===
    positive wall_absorption 0.15
    positive air_absorption_per_meter 0.001
    comment (air absorption coefficient)
    positive speed_of_sound 343
    comment === Reverb parameters ===
    positive reverb_tail 1.5
    positive diffuse_level 0.15
    comment (diffuse tail density)
    comment === Source and listener positions (meters) ===
    positive source_x 2
    positive source_y 3
    positive source_z 1.5
    positive listener_x 6
    positive listener_y 3
    positive listener_z 1.5
endform

# Apply preset
if preset = 2
    room_width = 5
    room_height = 3
    room_depth = 4
    number_of_rays = 150
    max_reflections = 10
    wall_absorption = 0.4
    air_absorption_per_meter = 0.001
    reverb_tail = 0.6
    diffuse_level = 0.10
    listener_radius = 0.4
    source_x = 1.5
    source_y = 1.5
    source_z = 1.2
    listener_x = 3.5
    listener_y = 1.5
    listener_z = 1.2
elsif preset = 3
    room_width = 40
    room_height = 15
    room_depth = 20
    number_of_rays = 300
    max_reflections = 25
    wall_absorption = 0.15
    air_absorption_per_meter = 0.002
    reverb_tail = 3.0
    diffuse_level = 0.20
    listener_radius = 1.0
    source_x = 20
    source_y = 7
    source_z = 1.5
    listener_x = 10
    listener_y = 7
    listener_z = 1.5
elsif preset = 4
    room_width = 2.5
    room_height = 2.2
    room_depth = 2.0
    number_of_rays = 250
    max_reflections = 20
    wall_absorption = 0.05
    air_absorption_per_meter = 0.0005
    reverb_tail = 1.0
    diffuse_level = 0.25
    listener_radius = 0.3
    source_x = 0.8
    source_y = 1.1
    source_z = 1.0
    listener_x = 1.7
    listener_y = 1.1
    listener_z = 1.0
elsif preset = 5
    room_width = 6
    room_height = 4
    room_depth = 5
    number_of_rays = 100
    max_reflections = 5
    wall_absorption = 0.70
    air_absorption_per_meter = 0.0005
    reverb_tail = 0.3
    diffuse_level = 0.05
    listener_radius = 0.4
    source_x = 2
    source_y = 2
    source_z = 1.5
    listener_x = 4
    listener_y = 2
    listener_z = 1.5
elsif preset = 6
    room_width = 60
    room_height = 25
    room_depth = 40
    number_of_rays = 400
    max_reflections = 30
    wall_absorption = 0.08
    air_absorption_per_meter = 0.003
    reverb_tail = 5.0
    diffuse_level = 0.25
    listener_radius = 1.5
    source_x = 30
    source_y = 12
    source_z = 2.0
    listener_x = 15
    listener_y = 12
    listener_z = 2.0
elsif preset = 7
    room_width = 12
    room_height = 4
    room_depth = 10
    number_of_rays = 200
    max_reflections = 12
    wall_absorption = 0.25
    air_absorption_per_meter = 0.001
    reverb_tail = 1.0
    diffuse_level = 0.12
    listener_radius = 0.6
    source_x = 3
    source_y = 2
    source_z = 1.5
    listener_x = 9
    listener_y = 2
    listener_z = 1.5
elsif preset = 8
    room_width = 100
    room_height = 50
    room_depth = 100
    number_of_rays = 80
    max_reflections = 3
    wall_absorption = 0.95
    air_absorption_per_meter = 0.005
    reverb_tail = 0.2
    diffuse_level = 0.02
    listener_radius = 1.0
    source_x = 20
    source_y = 25
    source_z = 1.5
    listener_x = 25
    listener_y = 25
    listener_z = 1.5
elsif preset = 9
    room_width = 8
    room_height = 6
    room_depth = 7
    number_of_rays = 250
    max_reflections = 15
    wall_absorption = 0.12
    air_absorption_per_meter = 0.001
    reverb_tail = 1.5
    diffuse_level = 0.18
    listener_radius = 0.5
    source_x = 2
    source_y = 3
    source_z = 1.5
    listener_x = 6
    listener_y = 3
    listener_z = 1.5
endif

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
sound_sr = Get sampling frequency

# Draw room (top view)
Erase all
Select outer viewport: 0, 6, 0, 6
Axes: 0, room_width, 0, room_depth
Draw inner box
Line width: 2
Draw rectangle: 0, room_width, 0, room_depth
Paint circle (mm): "Red", source_x, source_z, 3
Paint circle (mm): "Blue", listener_x, listener_z, 3
Text: source_x, "centre", source_z + 0.3, "half", "Source"
Text: listener_x, "centre", listener_z + 0.3, "half", "Listener"
Line width: 1

writeInfoLine: "=== PHYSICALLY ACCURATE 3D RAY TRACING ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Room: ", room_width, " × ", room_depth, " × ", room_height, " m (W×D×H)"
appendInfoLine: "Source: (", fixed$(source_x, 1), ", ", fixed$(source_z, 1), ", ", fixed$(source_y, 1), ")"
appendInfoLine: "Listener: (", fixed$(listener_x, 1), ", ", fixed$(listener_z, 1), ", ", fixed$(listener_y, 1), ")"
appendInfoLine: "Rays: ", number_of_rays
appendInfoLine: ""

# Calculate RT60
volume = room_width * room_height * room_depth
surface_area = 2 * (room_width * room_height + room_width * room_depth + room_height * room_depth)
rt60 = 0.161 * volume / (wall_absorption * surface_area + 0.001)
if rt60 > 5.0
    rt60 = 5.0
endif
if rt60 < 0.05
    rt60 = 0.05
endif
appendInfoLine: "RT60 (Sabine): ", fixed$(rt60, 2), " s"
appendInfoLine: ""

# Create impulse response
ir_duration = rt60 + reverb_tail
Create Sound from formula: "room_ir", 1, 0, ir_duration, sound_sr, "0"

# FIX 1: DIRECT SOUND WITH INVERSE SQUARE LAW
direct_distance = sqrt((listener_x - source_x)^2 + (listener_y - source_y)^2 + (listener_z - source_z)^2)
direct_delay = direct_distance / speed_of_sound

# PHYSICALLY CORRECT: 1/r amplitude decay + air absorption
# Note: Added 1.0 to denominator to prevent division by zero at very close range
direct_amplitude = 1.0 / (1.0 + direct_distance) * exp(-air_absorption_per_meter * direct_distance)

direct_sample = round(direct_delay * sound_sr)
if direct_sample < 1
    direct_sample = 1
endif
# Using 'Set value at sample number' is safer/cleaner than Formula (part) for single samples
Set value at sample number: 1, direct_sample, direct_amplitude

appendInfoLine: "Direct sound: ", fixed$(direct_delay * 1000, 1), " ms"
appendInfoLine: "Direct amplitude: ", fixed$(direct_amplitude, 3), " (1/r law)"
appendInfoLine: ""
appendInfoLine: "3D Ray tracing..."

# FIX 2: TRUE 3D RAY TRACING (corrected loop)
reflection_count = 0
total_reflection_energy = 0

for ray from 1 to number_of_rays
    # 3D SPHERICAL distribution (Fibonacci sphere)
    golden_ratio = (1 + sqrt(5)) / 2
    theta = 2 * pi * ray / golden_ratio
    
    # === CORRECTION: ensure z_val is within [-1, 1] to prevent undefined arccos ===
    z_val = 1 - 2 * (ray - 0.5) / number_of_rays
    
    if z_val > 1
        z_val = 1
    endif
    if z_val < -1
        z_val = -1
    endif
    
    phi = arccos(z_val)
    
    # Starting position (source) and 3D direction
    pos_x = source_x
    pos_y = source_y
    pos_z = source_z
    
    dir_x = sin(phi) * cos(theta)
    dir_y = sin(phi) * sin(theta)
    dir_z = cos(phi)
    
    energy = 1.0
    total_path_length = 0
    
    # Trace through reflections
    for reflection from 1 to max_reflections
        # Find intersection with ALL 6 walls (3D)
        # We use strict checks to avoid division by zero
        if dir_x > 0.0001
            t_right = (room_width - pos_x) / dir_x
        else
            t_right = 1e10
        endif
        if dir_x < -0.0001
            t_left = -pos_x / dir_x
        else
            t_left = 1e10
        endif
        
        if dir_y > 0.0001
            t_top = (room_height - pos_y) / dir_y
        else
            t_top = 1e10
        endif
        if dir_y < -0.0001
            t_bottom = -pos_y / dir_y
        else
            t_bottom = 1e10
        endif
        
        if dir_z > 0.0001
            t_back = (room_depth - pos_z) / dir_z
        else
            t_back = 1e10
        endif
        if dir_z < -0.0001
            t_front = -pos_z / dir_z
        else
            t_front = 1e10
        endif
        
        # Find nearest wall
        t_wall = min(t_right, min(t_left, min(t_top, min(t_bottom, min(t_back, t_front)))))
        
        # New position at wall
        new_x = pos_x + dir_x * t_wall
        new_y = pos_y + dir_y * t_wall
        new_z = pos_z + dir_z * t_wall
        
        # Visualize (top view projection)
        if reflection <= 3 and ray mod 10 = 0
             if t_wall < 1000
                Colour: "Green"
                Draw line: pos_x, pos_z, new_x, new_z
             endif
        endif
        
        # PHYSICS: Accumulate total path length
        segment_distance = sqrt((new_x - pos_x)^2 + (new_y - pos_y)^2 + (new_z - pos_z)^2)
        total_path_length = total_path_length + segment_distance
        
        # Energy loss: wall absorption + air absorption
        energy = energy * (1 - wall_absorption) * exp(-air_absorption_per_meter * segment_distance)
        
        # Check if ray segment passes near listener
        dx_seg = new_x - pos_x
        dy_seg = new_y - pos_y
        dz_seg = new_z - pos_z
        seg_length_sq = dx_seg^2 + dy_seg^2 + dz_seg^2
        
        if seg_length_sq > 0
            t_closest = ((listener_x - pos_x) * dx_seg + (listener_y - pos_y) * dy_seg + (listener_z - pos_z) * dz_seg) / seg_length_sq
        else
            t_closest = 0
        endif
        
        if t_closest >= 0 and t_closest <= 1
            closest_x = pos_x + t_closest * dx_seg
            closest_y = pos_y + t_closest * dy_seg
            closest_z = pos_z + t_closest * dz_seg
            dist_to_listener = sqrt((listener_x - closest_x)^2 + (listener_y - closest_y)^2 + (listener_z - closest_z)^2)
            
            if dist_to_listener < listener_radius and energy > 0.001
                # Use TOTAL PATH LENGTH (source -> reflection point -> listener)
                path_to_reflection = total_path_length - (1 - t_closest) * segment_distance
                distance_to_listener_from_reflection = dist_to_listener
                total_acoustic_path = path_to_reflection + distance_to_listener_from_reflection
                
                # PHYSICS: 1/r amplitude + air absorption over entire path
                amplitude = energy / (1.0 + total_acoustic_path) * exp(-air_absorption_per_meter * total_acoustic_path)
                
                # Arrival time
                delay_time = total_acoustic_path / speed_of_sound
                sample_pos = round(delay_time * sound_sr)
                
                if sample_pos > direct_sample and sample_pos < ir_duration * sound_sr
                    Formula (part): sample_pos / sound_sr, (sample_pos + 1) / sound_sr, 1, 1, "self + amplitude"
                    reflection_count = reflection_count + 1
                    total_reflection_energy = total_reflection_energy + amplitude
                endif
            endif
        endif
        
        # Reflect ray direction (specular reflection)
        if t_wall = t_right or t_wall = t_left
            dir_x = -dir_x
        endif
        if t_wall = t_top or t_wall = t_bottom
            dir_y = -dir_y
        endif
        if t_wall = t_back or t_wall = t_front
            dir_z = -dir_z
        endif
        
        # Update position
        pos_x = new_x
        pos_y = new_y
        pos_z = new_z
        
        # Stop if energy too low
        if energy < 0.001
            goto NEXT_RAY
        endif
    endfor
    
    label NEXT_RAY
endfor

appendInfoLine: "Traced reflections: ", reflection_count
appendInfoLine: "Reflection energy: ", fixed$(total_reflection_energy, 3)
appendInfoLine: "Direct/Reverb ratio: ", fixed$(direct_amplitude / (total_reflection_energy + 0.001), 2)
appendInfoLine: ""

# Add diffuse reverb tail
appendInfoLine: "Adding diffuse tail..."
Formula: "self + diffuse_level * randomGauss(0, 1) * exp(-6.9 * x / rt60)"

# Normalize
Scale peak: 0.99
appendInfoLine: "IR complete (", fixed$(ir_duration, 2), "s)"
appendInfoLine: ""

# Convolve
appendInfoLine: "Convolving..."
room_ir = selected("Sound")
select sound
plus room_ir
Convolve: "sum", "zero"
Rename: sound_name$ + "_3D_raytraced"
Scale peak: 0.95

appendInfoLine: ""
appendInfoLine: "✓ PHYSICALLY ACCURATE ray tracing complete!"
appendInfoLine: "- TRUE 3D (ceiling/floor reflections)"
appendInfoLine: "- Inverse square law (1/r)"
appendInfoLine: "- Air absorption"
appendInfoLine: "- Distance-dependent direct sound"

# Clean up
select room_ir
Remove

# Play
select Sound 'sound_name$'_3D_raytraced
Play