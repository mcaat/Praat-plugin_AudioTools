# ============================================================
# Praat AudioTools - ChirikovStandardMap.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Create Sound from Chirikov Standard Map (chaotic dynamical system)
#   p(n+1) = p(n) + K*sin(theta(n))
#   theta(n+1) = theta(n) + p(n+1) (mod 2π)
#
# Usage:
#   Run this script to generate sound and visualize phase space.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Create sound from Chirikov Standard Map
    comment Presets:
    optionmenu Preset 1
        option Custom
        option Periodic_Islands
        option Onset_of_Chaos
        option Partial_Chaos
        option Strong_Chaos
        option Frequency_Shimmer
        option Stereo_Chaos
    positive Duration_(seconds) 5.0
    positive Sampling_frequency_(Hz) 44100
    comment Initial conditions:
    real Initial_theta 0.5
    real Initial_p 0.0
    comment Map parameters:
    positive K_parameter 1.5
    comment Sonification mapping:
    optionmenu Mapping_mode 1
        option Theta to amplitude
        option P to amplitude
        option Theta to frequency
        option Both (theta=L, p=R)
    positive Base_frequency_(Hz) 220
    positive Frequency_range_(Hz) 880
    comment Drawing parameters:
    boolean Draw_phase_space 1
    integer Drawing_steps 1000
endform

# Apply preset settings
if preset = 2
    # Periodic Islands (K < 1)
    k_parameter = 0.5
    initial_theta = 0.5
    initial_p = 0.0
    mapping_mode = 1
    base_frequency = 220
    frequency_range = 880
    draw_phase_space = 1
elsif preset = 3
    # Onset of Chaos (K ~ 1)
    k_parameter = 0.971635
    initial_theta = 1.0
    initial_p = 0.5
    mapping_mode = 1
    base_frequency = 220
    frequency_range = 880
    draw_phase_space = 1
elsif preset = 4
    # Partial Chaos (K ~ 1.5)
    k_parameter = 1.5
    initial_theta = 0.5
    initial_p = 0.0
    mapping_mode = 1
    base_frequency = 220
    frequency_range = 880
    draw_phase_space = 1
elsif preset = 5
    # Strong Chaos (K > 5)
    k_parameter = 5.0
    initial_theta = 0.1
    initial_p = 0.1
    mapping_mode = 2
    base_frequency = 220
    frequency_range = 880
    draw_phase_space = 1
elsif preset = 6
    # Frequency Shimmer
    k_parameter = 2.5
    initial_theta = 1.57
    initial_p = 0.0
    mapping_mode = 3
    base_frequency = 440
    frequency_range = 1760
    draw_phase_space = 1
elsif preset = 7
    # Stereo Chaos
    k_parameter = 3.0
    initial_theta = 0.8
    initial_p = 0.3
    mapping_mode = 4
    base_frequency = 220
    frequency_range = 880
    draw_phase_space = 1
endif

# Erase drawing area
if draw_phase_space
    Erase all
endif

# Calculate number of samples
samples = duration * sampling_frequency

# Create sound object
Create Sound from formula: "chirikov", 1, 0, duration, sampling_frequency, "0"

# Initialize map variables
theta = initial_theta
p = initial_p

# Initialize drawing variables
if draw_phase_space
    prevsx = theta / (2 * 3.14)
    prevsy = 0.5 + p / 10
endif

# Iterate through each sample
for i from 1 to samples
    # Compute Chirikov map iteration
    p_new = p + k_parameter * sin(theta)
    theta_new = theta + p_new
    
    # Apply modulo 2π to theta
    while theta_new > 2 * 3.14
        theta_new = theta_new - 2 * 3.14
    endwhile
    while theta_new < 0
        theta_new = theta_new + 2 * 3.14
    endwhile
    
    # Update variables
    p = p_new
    theta = theta_new
    
    # Draw phase space trajectory
    if draw_phase_space and (i mod (samples / drawing_steps)) = 0
        # Normalize coordinates for drawing
        # theta: 0 to 2π maps to 0 to 1
        sx = theta / (2 * 3.14)
        # p: scale to visible range (centered at 0.5)
        sy = 0.5 + p / 10
        
        # Keep within bounds
        if sy > 1
            sy = 1
        elsif sy < 0
            sy = 0
        endif
        
        # Draw line from previous point
        Draw line: prevsx, prevsy, sx, sy
        
        # Update previous coordinates
        prevsx = sx
        prevsy = sy
    endif
    
    # Map to audio based on selected mode
    if mapping_mode = 1
        # Theta to amplitude
        value = (theta / (2 * 3.14)) * 2 - 1
    elsif mapping_mode = 2
        # P to amplitude (normalize)
        value = p / (k_parameter + 2)
        if value > 1
            value = 1
        elsif value < -1
            value = -1
        endif
    elsif mapping_mode = 3
        # Theta to frequency modulation
        freq = base_frequency + (theta / (2 * 3.14)) * frequency_range
        time = (i - 1) / sampling_frequency
        value = sin(2 * 3.14 * freq * time)
    elsif mapping_mode = 4
        # Will handle stereo below
        value = (theta / (2 * 3.14)) * 2 - 1
    endif
    
    # Set sample value
    Set value at sample number: 1, i, value
endfor

# If stereo mode selected, convert to stereo
if mapping_mode = 4
    # Reset for second pass
    theta = initial_theta
    p = initial_p
    
    # Convert to stereo
    Convert to stereo
    
    # Fill right channel with p values
    for i from 1 to samples
        # Compute map iteration again
        p_new = p + k_parameter * sin(theta)
        theta_new = theta + p_new
        
        while theta_new > 2 * 3.14
            theta_new = theta_new - 2 * 3.14
        endwhile
        while theta_new < 0
            theta_new = theta_new + 2 * 3.14
        endwhile
        
        p = p_new
        theta = theta_new
        
        # P to amplitude for right channel
        value = p / (k_parameter + 2)
        if value > 1
            value = 1
        elsif value < -1
            value = -1
        endif
        
        Set value at sample number: 2, i, value
    endfor
endif

# Scale to prevent clipping
Scale peak: 0.99
Play