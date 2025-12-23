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

# Logistic Map Synthesis (Fixed & Cleaned)

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
ctrl_id = Create Sound from formula: "Control_Signal", 1, 0, duration, control_rate, "0"

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
    # We use a temp sound just to draw the curve easily
    temp_curve = Create Sound from formula: "Parabola", 1, 0, 1, 1000, "r_parameter * x * (1-x)"
    Draw: 0, 1, 0, 1, "no", "Curve"
    Remove
    
    # Draw Diagonal
    Colour: {0.6, 0.6, 0.6}
    Draw line: 0, 0, 1, 1
    
    # Draw Cobweb
    if plot_type = 1 or plot_type = 3
        selectObject: ctrl_id
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
        selectObject: ctrl_id
        
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
selectObject: ctrl_id
# Create the base audio object by upsampling
audio_id = Resample: 44100, 50
Rename: "Logistic_Audio"

# Apply Frequency Modulation Formula
# Note: 'self' here is the logistic value (0 to 1)
# It modulates both Amplitude (AM) and Frequency (FM)
Formula: "0.3 * self * sin(2*pi * (base_frequency * (0.5 + self)) * x)"

# --- 4. SPATIAL PROCESSING ---
final_id = audio_id

if spatial_mode = 2
    # --- Stereo Wide ---
    selectObject: audio_id
    left_id = Copy: "Left"
    selectObject: audio_id
    right_id = Copy: "Right"
    
    # Filter LEFT (Low Pass)
    selectObject: left_id
    Filter (pass Hann band): 0, 2500, 100
    left_band_id = selected("Sound")
    # Clean up the unfiltered copy
    removeObject: left_id
    
    # Filter RIGHT (High Pass-ish)
    selectObject: right_id
    Filter (pass Hann band): 200, 5000, 100
    right_band_id = selected("Sound")
    # Clean up the unfiltered copy
    removeObject: right_id
    
    # Combine the FILTERED versions
    selectObject: left_band_id
    plusObject: right_band_id
    final_id = Combine to stereo
    Rename: "Logistic_Stereo"
    
    # Cleanup intermediate filtered files
    removeObject: left_band_id
    removeObject: right_band_id
    
    # We also don't need the original mono audio anymore
    removeObject: audio_id
    
elsif spatial_mode = 3
    # --- Random Pan ---
    selectObject: audio_id
    left_id = Copy: "Left"
    selectObject: audio_id
    right_id = Copy: "Right"
    
    # Pan based on the chaotic signal itself
    # We use a slow LFO for panning to avoid dizziness
    selectObject: left_id
    Formula: "self * (0.5 + 0.5 * sin(2*pi*0.5*x))"
    selectObject: right_id
    Formula: "self * (0.5 + 0.5 * cos(2*pi*0.5*x))"
    
    selectObject: left_id
    plusObject: right_id
    final_id = Combine to stereo
    Rename: "Logistic_Pan"
    
    removeObject: left_id
    removeObject: right_id
    removeObject: audio_id
endif

# Cleanup the control signal
selectObject: ctrl_id
Remove

# Select final output
selectObject: final_id
Scale peak: 0.9

if play_after
    Play
endif