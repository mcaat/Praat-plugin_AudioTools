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

form Chirikov Standard Map Generator (Bold)
    comment Presets:
    optionmenu Preset 1
        option Custom
        option Periodic Islands
        option Onset of Chaos
        option Partial Chaos
        option Strong Chaos
        option Frequency Shimmer
        option Stereo Chaos
    positive Duration_(s) 5.0
    positive Sampling_frequency_(Hz) 44100
    
    comment Initial Conditions:
    real Initial_theta 0.5
    real Initial_p 0.0
    
    comment Map Parameters:
    positive K_parameter 1.5
    
    comment Sonification:
    optionmenu Mapping_mode 1
        option Theta to Amplitude
        option P to Amplitude
        option Theta to Frequency (FM)
        option Both (Theta=L, P=R)
    positive Base_frequency_(Hz) 220
    positive Frequency_range_(Hz) 880
    
    comment Visualization:
    boolean Draw_phase_space 1
    # Decreased steps slightly so bold lines don't overlap too much
    integer Drawing_steps 1500 
endform

# --- 1. PRESET LOGIC ---
if preset = 2
    # Periodic Islands (K < 1)
    k_parameter = 0.5
    initial_theta = 0.5
    initial_p = 0.0
    mapping_mode = 1
    draw_phase_space = 1
elsif preset = 3
    # Onset of Chaos (K ~ 0.97)
    k_parameter = 0.971635
    initial_theta = 1.0
    initial_p = 0.5
    mapping_mode = 1
    draw_phase_space = 1
elsif preset = 4
    # Partial Chaos
    k_parameter = 1.5
    initial_theta = 0.5
    initial_p = 0.0
    mapping_mode = 1
    draw_phase_space = 1
elsif preset = 5
    # Strong Chaos
    k_parameter = 5.0
    initial_theta = 0.1
    initial_p = 0.1
    mapping_mode = 2
    draw_phase_space = 1
elsif preset = 6
    # Frequency Shimmer (FM)
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
    draw_phase_space = 1
endif

# --- 2. SETUP ---
#Initialize Variables needed for setup
theta = initial_theta
p = initial_p
two_pi = 2 * pi

if draw_phase_space
    Erase all
    Select outer viewport: 0, 8, 0, 8
    Axes: 0, 1, 0, 1
    
    # --- BOLD SETTING ---
    # Set line width to 2 (default is 1). Try 3 for extra bold.
    Line width: 2
    # --------------------
    
    Draw inner box
    Text top: "yes", "Chirikov Standard Map (K=" + string$(k_parameter) + ")"

    # Initialize previous coordinates for line drawing
    prev_sx = theta / two_pi
    prev_sy = 0.5 + p / 10
endif

samples = duration * sampling_frequency
channels = 1
if mapping_mode = 4
    channels = 2
endif

sound_id = Create Sound from formula: "Chirikov", channels, 0, duration, sampling_frequency, "0"

current_phase = 0

# Drawing stride
draw_stride = floor(samples / drawing_steps)
if draw_stride < 1
    draw_stride = 1
endif

# --- 3. MAIN LOOP ---
for i to samples
    # A. Map Equation
    p = p + k_parameter * sin(theta)
    theta = theta + p
    # Normalize Theta (Modulo 2pi safely)
    theta = theta - two_pi * floor(theta / two_pi)
    
    # B. Visualization (Bold Lines)
    if draw_phase_space and (i mod draw_stride = 0)
        # Normalize coords
        sx = theta / two_pi
        sy = 0.5 + (p / 20) 
        
        # Clamp to box
        if sy > 1
             sy = 1
        elsif sy < 0
             sy = 0
        endif
        
        # Draw bold line from previous point to current point
        Draw line: prev_sx, prev_sy, sx, sy
        
        # Update previous coordinates for next draw
        prev_sx = sx
        prev_sy = sy
    endif

    # C. Audio Mapping
    val_1 = 0
    val_2 = 0
    
    if mapping_mode = 1
        val_1 = (theta / pi) - 1
    elsif mapping_mode = 2
        val_1 = sin(p)
    elsif mapping_mode = 3
        # FM Synthesis with phase accumulation
        current_freq = base_frequency + (theta / two_pi) * frequency_range
        phase_inc = two_pi * current_freq / sampling_frequency
        current_phase = current_phase + phase_inc
        if current_phase > two_pi
            current_phase = current_phase - two_pi
        endif
        val_1 = sin(current_phase)
    elsif mapping_mode = 4
        val_1 = (theta / pi) - 1
        val_2 = sin(p)
    endif

    # D. Write to Sound
    if mapping_mode = 4
        Set value at sample number: 1, i, val_1
        Set value at sample number: 2, i, val_2
    else
        Set value at sample number: 1, i, val_1
    endif
endfor

# --- 4. FINALIZE ---
selectObject: sound_id
Scale peak: 0.9
Play