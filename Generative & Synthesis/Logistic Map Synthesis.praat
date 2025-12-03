# ============================================================
# Praat AudioTools - Logistic Map Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sound synthesis or generative algorithm script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Logistic Map Synthesis (Optimized & Cleaned)

form Logistic Map Synthesis
    optionmenu Preset: 6
        option Custom
        option Gentle Chaos
        option Wild Oscillations
        option Periodic Orbit
        option Edge of Chaos
        option Bifurcation Cascade
        option Strange Attractor
    optionmenu Spatial_mode: 2
        option Mono
        option Stereo Wide
        option Random Pan
    optionmenu Plot_type: 3
        option Cobweb Plot
        option Return Map (dots)
        option Both
    real Duration 10.0
    real Base_frequency 180
    real R_parameter 3.7
    real Initial_x 0.5
    positive Cobweb_iterations 50
    boolean Draw_logistic_map 1
    boolean Play_after 1
endform

# --- PRESET LOGIC ---
if preset = 2
    r_parameter = 3.5
    base_frequency = 150
    initial_x = 0.3
    preset_name$ = "GentleChaos"
elsif preset = 3
    r_parameter = 3.9
    base_frequency = 200
    initial_x = 0.1
    preset_name$ = "WildOscillations"
elsif preset = 4
    r_parameter = 3.2
    base_frequency = 120
    initial_x = 0.7
    preset_name$ = "PeriodicOrbit"
elsif preset = 5
    r_parameter = 3.56995
    base_frequency = 170
    initial_x = 0.5
    preset_name$ = "EdgeOfChaos"
elsif preset = 6
    r_parameter = 3.55
    base_frequency = 140
    initial_x = 0.4
    preset_name$ = "BifurcationCascade"
elsif preset = 7
    r_parameter = 3.8
    base_frequency = 190
    initial_x = 0.2
    preset_name$ = "StrangeAttractor"
else
    preset_name$ = "Custom"
endif

Erase all
writeInfoLine: "Synthesizing Logistic Map..."

# --- 1. THE MATH ENGINE (Control Signal) ---
# Create a low-sample-rate Sound object to hold the data.
control_rate = 200
Create Sound from formula: "Control_Signal", 1, 0, duration, control_rate, "0"

# Vectorized Loop
logistic_x = initial_x
total_samples = Get number of samples

for i to total_samples
    # The Logistic Map Equation
    logistic_x = r_parameter * logistic_x * (1 - logistic_x)
    
    # Store directly into the sound object
    Set value at sample number: 1, i, logistic_x
endfor

# --- 2. VISUALIZATION ---
if draw_logistic_map
    Select outer viewport: 0, 8, 0, 6
    Select inner viewport: 1, 7, 1, 5
    Axes: 0, 1, 0, 1
    Draw inner box
    Text top: "yes", "Logistic Map (R=" + string$(r_parameter) + ")"
    Marks bottom every: 0.2, 1, "yes", "yes", "no"
    Marks left every: 0.2, 1, "yes", "yes", "no"
    
    # Draw Parabola
    Colour: "Blue"
    Line width: 2
    Create Sound from formula: "Parabola", 1, 0, 1, 1000, "r_parameter * x * (1-x)"
    Draw: 0, 1, 0, 1, "no", "Curve"
    Remove
    
    # Draw Diagonal
    Colour: {0.6, 0.6, 0.6}
    Draw line: 0, 0, 1, 1
    
    # Draw Cobweb
    if plot_type = 1 or plot_type = 3
        selectObject: "Sound Control_Signal"
        curr_val = Get value at sample number: 1, 1
        
        Colour: "Red"
        Line width: 1
        
        # Limit iterations to prevent screen clutter
        iters = min(cobweb_iterations, total_samples-1)
        
        for i to iters
            next_val = Get value at sample number: 1, i+1
            # Vertical line
            Draw line: curr_val, curr_val, curr_val, next_val
            # Horizontal line
            Draw line: curr_val, next_val, next_val, next_val
            curr_val = next_val
        endfor
        
        # Start Point
        Colour: "Green"
        Paint circle (mm): "Green", initial_x, 0, 2
    endif
    
    # Draw Attractor Dots
    if plot_type = 2 or plot_type = 3
        selectObject: "Sound Control_Signal"
        
        # Orange Color
        Colour: {1, 0.5, 0}
        
        # Skip transient (first 20% of duration)
        start_idx = round(total_samples * 0.2)
        
        for i from start_idx to total_samples-1
            # Draw every 5th point to save time
            if (i mod 5) = 0
                val_x = Get value at sample number: 1, i
                val_y = Get value at sample number: 1, i+1
                Paint circle (mm): {1, 0.5, 0}, val_x, val_y, 0.5
            endif
        endfor
    endif
endif

# --- 3. AUDIO SYNTHESIS ---
selectObject: "Sound Control_Signal"
Copy: "Audio_Base"
# Upsample to Audio Rate
Resample: 44100, 50
Rename: "Logistic_Audio"

# Apply Frequency Modulation Formula
Formula: "0.3 * self * sin(2*pi * (base_frequency * (0.5 + self)) * x)"

# --- 4. SPATIAL PROCESSING ---
if spatial_mode = 2
    # Stereo Wide
    Copy: "Left"
    Formula: "self * 0.8"
    selectObject: "Sound Logistic_Audio"
    Copy: "Right"
    Formula: "self * 0.8"
    
    # Decorrelate channels with filters
    selectObject: "Sound Left"
    Filter (pass Hann band): 0, 2500, 100
    selectObject: "Sound Right"
    Filter (pass Hann band): 200, 5000, 100
    
    selectObject: "Sound Left"
    plusObject: "Sound Right"
    Combine to stereo
    Rename: "Logistic_Stereo"
    
    selectObject: "Sound Left"
    plusObject: "Sound Right"
    Remove
    
elsif spatial_mode = 3
    # Random Pan
    Copy: "Left"
    selectObject: "Sound Logistic_Audio"
    Copy: "Right"
    
    # Pan based on the chaotic signal itself
    selectObject: "Sound Left"
    Formula: "self * (0.5 + 0.5 * sin(2*pi*0.5*x))"
    selectObject: "Sound Right"
    Formula: "self * (0.5 + 0.5 * cos(2*pi*0.5*x))"
    
    Combine to stereo
    Rename: "Logistic_Pan"
    
    selectObject: "Sound Left"
    plusObject: "Sound Right"
    Remove
endif

# Cleanup
selectObject: "Sound Control_Signal"
Remove
selectObject: "Sound Audio_Base"
Remove

# Construct the output name based on mode
output_name$ = "Logistic_Audio"
if spatial_mode = 2
    output_name$ = "Logistic_Stereo"
elsif spatial_mode = 3
    output_name$ = "Logistic_Pan"
endif

selectObject: "Sound " + output_name$
Scale peak: 0.9

if play_after
    Play
endif