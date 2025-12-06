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

# Ray Tracing Room Acoustics Simulator
# Physically accurate ray tracing + diffuse tail

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
    positive number_of_rays 100
    comment (MORE RAYS = MORE ACCURATE, affects sound!)
    positive max_reflections 15
    comment (higher = longer reverb tail)
    positive listener_radius 1.5
    comment (capture radius around listener in meters)
    comment === Acoustic parameters ===
    positive wall_absorption 0.15
    positive speed_of_sound 343
    comment === Reverb parameters ===
    positive reverb_tail 1.5
    positive diffuse_level 0.15
    comment (diffuse tail density)
    positive early_reflection_level 0.6
    comment (traced reflections loudness)
    comment === Source and listener positions (meters) ===
    positive source_x 2
    positive source_y 3
    positive listener_x 6
    positive listener_y 3
endform

# Apply preset
if preset = 2
    room_width = 5
    room_height = 3
    room_depth = 4
    number_of_rays = 80
    max_reflections = 10
    wall_absorption = 0.4
    reverb_tail = 0.6
    diffuse_level = 0.10
    early_reflection_level = 0.5
    listener_radius = 1.0
    source_x = 1.5
    source_y = 1.5
    listener_x = 3.5
    listener_y = 1.5
elsif preset = 3
    room_width = 40
    room_height = 15
    room_depth = 20
    number_of_rays = 150
    max_reflections = 25
    wall_absorption = 0.15
    reverb_tail = 3.0
    diffuse_level = 0.20
    early_reflection_level = 0.7
    listener_radius = 2.5
    source_x = 20
    source_y = 7
    listener_x = 10
    listener_y = 7
elsif preset = 4
    room_width = 2.5
    room_height = 2.2
    room_depth = 2.0
    number_of_rays = 100
    max_reflections = 20
    wall_absorption = 0.05
    reverb_tail = 1.0
    diffuse_level = 0.25
    early_reflection_level = 0.8
    listener_radius = 0.8
    source_x = 0.8
    source_y = 1.1
    listener_x = 1.7
    listener_y = 1.1
elsif preset = 5
    room_width = 6
    room_height = 4
    room_depth = 5
    number_of_rays = 50
    max_reflections = 5
    wall_absorption = 0.70
    reverb_tail = 0.3
    diffuse_level = 0.05
    early_reflection_level = 0.3
    listener_radius = 1.0
    source_x = 2
    source_y = 2
    listener_x = 4
    listener_y = 2
elsif preset = 6
    room_width = 60
    room_height = 25
    room_depth = 40
    number_of_rays = 200
    max_reflections = 30
    wall_absorption = 0.08
    reverb_tail = 5.0
    diffuse_level = 0.25
    early_reflection_level = 0.75
    listener_radius = 3.0
    source_x = 30
    source_y = 12
    listener_x = 15
    listener_y = 12
elsif preset = 7
    room_width = 12
    room_height = 4
    room_depth = 10
    number_of_rays = 100
    max_reflections = 12
    wall_absorption = 0.25
    reverb_tail = 1.0
    diffuse_level = 0.12
    early_reflection_level = 0.6
    listener_radius = 1.5
    source_x = 3
    source_y = 2
    listener_x = 9
    listener_y = 2
elsif preset = 8
    room_width = 100
    room_height = 50
    room_depth = 100
    number_of_rays = 30
    max_reflections = 3
    wall_absorption = 0.95
    reverb_tail = 0.2
    diffuse_level = 0.02
    early_reflection_level = 0.15
    listener_radius = 2.0
    source_x = 20
    source_y = 25
    listener_x = 25
    listener_y = 25
elsif preset = 9
    room_width = 8
    room_height = 6
    room_depth = 7
    number_of_rays = 120
    max_reflections = 15
    wall_absorption = 0.12
    reverb_tail = 1.5
    diffuse_level = 0.18
    early_reflection_level = 0.7
    listener_radius = 1.2
    source_x = 2
    source_y = 3
    listener_x = 6
    listener_y = 3
endif

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
sound_sr = Get sampling frequency

# Draw room (top view)
Erase all
Select outer viewport: 0, 6, 0, 6
Axes: 0, room_width, 0, room_height
Draw inner box
Line width: 2
Draw rectangle: 0, room_width, 0, room_height
Paint circle (mm): "Red", source_x, source_y, 3
Paint circle (mm): "Blue", listener_x, listener_y, 3
# Draw listener capture radius
Colour: "Blue"
listener_radius_mm = listener_radius * 1000 / room_width
Draw circle (mm): listener_x, listener_y, listener_radius_mm
Text: source_x, "centre", source_y + 0.3, "half", "Source"
Text: listener_x, "centre", listener_y + 0.3, "half", "Listener"
Line width: 1

writeInfoLine: "=== TRUE RAY TRACING SIMULATION ==="
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Room: ", room_width, "m × ", room_height, "m × ", room_depth, "m"
appendInfoLine: "Rays: ", number_of_rays, " (affects sound!)"
appendInfoLine: "Max reflections per ray: ", max_reflections
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
appendInfoLine: "RT60 (Sabine): ", fixed$(rt60, 2), " seconds"
appendInfoLine: ""

# Create impulse response
ir_duration = rt60 + reverb_tail
Create Sound from formula: "room_ir", 1, 0, ir_duration, sound_sr, "0"

# Add direct sound
direct_distance = sqrt((listener_x - source_x)^2 + (listener_y - source_y)^2)
direct_delay = direct_distance / speed_of_sound
direct_sample = round(direct_delay * sound_sr)
if direct_sample < 1
    direct_sample = 1
endif
Formula (part): direct_sample / sound_sr, (direct_sample + 1) / sound_sr, 1, 1, "0.5"

appendInfoLine: "Direct sound at ", fixed$(direct_delay * 1000, 1), " ms"
appendInfoLine: "Ray tracing early reflections..."

# RAY TRACING - THIS ACTUALLY AFFECTS THE SOUND NOW!
reflection_count = 0
total_reflection_energy = 0

for ray from 1 to number_of_rays
    # Uniformly distributed ray directions
    angle = (ray - 1) * 360 / number_of_rays
    
    # Starting position and direction
    pos_x = source_x
    pos_y = source_y
    pos_z = room_depth / 2
    
    dir_x = cos(angle * pi / 180)
    dir_y = sin(angle * pi / 180)
    dir_z = 0
    
    energy = 1.0
    total_path = 0
    
    # Trace this ray through reflections
    for reflection from 1 to max_reflections
        # Find intersection with walls (2D)
        if dir_x > 0
            t_right = (room_width - pos_x) / dir_x
        else
            t_right = 1e10
        endif
        if dir_x < 0
            t_left = -pos_x / dir_x
        else
            t_left = 1e10
        endif
        if dir_y > 0
            t_top = (room_height - pos_y) / dir_y
        else
            t_top = 1e10
        endif
        if dir_y < 0
            t_bottom = -pos_y / dir_y
        else
            t_bottom = 1e10
        endif
        
        t_wall = min(t_right, min(t_left, min(t_top, t_bottom)))
        
        # New position at wall
        new_x = pos_x + dir_x * t_wall
        new_y = pos_y + dir_y * t_wall
        
        # Visualize first few reflections
        if reflection <= 3 and ray mod 5 = 0
            Colour: "Green"
            Draw line: pos_x, pos_y, new_x, new_y
        endif
        
        # Distance traveled
        segment_distance = sqrt((new_x - pos_x)^2 + (new_y - pos_y)^2)
        total_path = total_path + segment_distance
        
        # Energy absorption at wall
        energy = energy * (1 - wall_absorption)
        
        # CHECK IF RAY HITS LISTENER
        # Calculate distance from reflection point to listener
        dist_reflection_to_listener = sqrt((listener_x - new_x)^2 + (listener_y - new_y)^2)
        
        # ALSO check if ray SEGMENT passes near listener
        # Closest point on segment to listener
        dx_seg = new_x - pos_x
        dy_seg = new_y - pos_y
        if dx_seg = 0 and dy_seg = 0
            t_closest = 0
        else
            t_closest = ((listener_x - pos_x) * dx_seg + (listener_y - pos_y) * dy_seg) / (dx_seg^2 + dy_seg^2)
        endif
        
        if t_closest >= 0 and t_closest <= 1
            closest_x = pos_x + t_closest * dx_seg
            closest_y = pos_y + t_closest * dy_seg
            dist_segment_to_listener = sqrt((listener_x - closest_x)^2 + (listener_y - closest_y)^2)
        else
            dist_segment_to_listener = 1e10
        endif
        
        # Add reflection if close enough
        min_dist = min(dist_reflection_to_listener, dist_segment_to_listener)
        
        if min_dist < listener_radius and energy > 0.01
            # Calculate total acoustic path
            if dist_segment_to_listener < dist_reflection_to_listener
                # Ray segment passes near listener
                path_length = total_path - (1 - t_closest) * segment_distance + dist_segment_to_listener
            else
                # Reflection point is near listener
                path_length = total_path + dist_reflection_to_listener
            endif
            
            delay_time = path_length / speed_of_sound
            
            # Distance attenuation
            distance_atten = 1.0 / (1.0 + min_dist / 3.0)
            
            # Reflection amplitude
            amplitude = energy * early_reflection_level * distance_atten
            
            # Add to impulse response
            sample_pos = round(delay_time * sound_sr)
            if sample_pos > direct_sample and sample_pos < ir_duration * sound_sr
                Formula (part): sample_pos / sound_sr, (sample_pos + 1) / sound_sr, 1, 1, "self + amplitude"
                reflection_count = reflection_count + 1
                total_reflection_energy = total_reflection_energy + amplitude
            endif
        endif
        
        # Reflect ray direction
        if t_wall = t_right or t_wall = t_left
            dir_x = -dir_x
        endif
        if t_wall = t_top or t_wall = t_bottom
            dir_y = -dir_y
        endif
        
        # Update position
        pos_x = new_x
        pos_y = new_y
        
        # Stop if energy too low
        if energy < 0.01
            goto NEXT_RAY
        endif
    endfor
    
    label NEXT_RAY
endfor

appendInfoLine: "Captured ", reflection_count, " traced reflections"
appendInfoLine: "Total reflection energy: ", fixed$(total_reflection_energy, 3)
appendInfoLine: ""

# Add diffuse reverb tail (critical for reverb sound!)
appendInfoLine: "Adding diffuse tail..."
Formula: "self + diffuse_level * randomGauss(0, 1) * exp(-6.9 * x / rt60)"

# Normalize
Scale peak: 0.99
appendInfoLine: "IR created (", fixed$(ir_duration, 2), "s)"
appendInfoLine: ""

# Convolve
appendInfoLine: "Convolving..."
room_ir = selected("Sound")
select sound
plus room_ir
Convolve: "sum", "zero"
Rename: sound_name$ + "_raytraced"
Scale peak: 0.95

appendInfoLine: "✓ TRUE ray tracing complete!"
appendInfoLine: "Output: ", selected$("Sound")

# Clean up
select room_ir
Remove

# Play
select Sound 'sound_name$'_raytraced
Play