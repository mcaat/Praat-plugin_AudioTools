# ============================================================
# Praat AudioTools - Organic No-Input Mixer
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Organic No-Input Mixer
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
# Organic No-Input Mixer 

form No-Input Mixer Parameters
    optionmenu Preset: 1
        option Custom (Use settings below)
        option Edge of Oscillation (Subtle)
        option Deep Throbbing Drone
        option High Frequency Whistle
        option Degraded Cassette Loop
    
    optionmenu Spatial_Mode: 2
        option Mono (Summed)
        option Stereo Wide (Freq Split)
        option Rotating (Auto-Pan)
        option Binaural (Delay/Filter)
        
    comment Global Settings
    real Duration_(s) 10.0
    positive Iterations 60
    
    comment Circuit Physics (Custom)
    positive Feedback_Gain 1.05
    positive Damping_Factor 0.94
    
    comment Filter Drift (Custom)
    positive Resonance_Center_(Hz) 220
    positive Resonance_Width_(Hz) 100
    positive Analog_Instability 0.05
endform

# --- 1. Preset Logic ---
if preset$ = "Edge of Oscillation (Subtle)"
    feedback_Gain = 1.01
    damping_Factor = 0.92
    resonance_Center = 440
    resonance_Width = 300
    analog_Instability = 0.02
elsif preset$ = "Deep Throbbing Drone"
    feedback_Gain = 1.4
    damping_Factor = 0.85
    resonance_Center = 60
    resonance_Width = 40
    analog_Instability = 0.1
elsif preset$ = "High Frequency Whistle"
    feedback_Gain = 1.1
    damping_Factor = 0.98
    resonance_Center = 2500
    resonance_Width = 50
    analog_Instability = 0.01
elsif preset$ = "Degraded Cassette Loop"
    feedback_Gain = 0.98
    damping_Factor = 0.99
    resonance_Center = 800
    resonance_Width = 1000
    analog_Instability = 0.2
endif

# --- 2. Initial Cleanup ---
select all
if numberOfSelected() > 0
    Remove
endif

# --- 3. Seed Injection (Stereo) ---
random_initialize = 1999
printline Initializing circuit...
Create Sound from formula: "Noise_L", 1, 0, duration, 44100, "randomGauss(0, 0.0001)"
Create Sound from formula: "Noise_R", 1, 0, duration, 44100, "randomGauss(0, 0.0001)"
Combine to stereo
Rename: "StereoLoop"
selectObject: "Sound Noise_L"
plusObject: "Sound Noise_R"
Remove

# --- 4. The Organic Feedback Loop ---
printline Starting feedback simulation...

for i from 1 to iterations
    selectObject: "Sound StereoLoop"
    Copy: "FeedbackPath"
    
    # Calculate Dynamic Drift
    drift_hz = resonance_Center * analog_Instability
    current_freq = resonance_Center + randomGauss(0, drift_hz)
    width_drift = resonance_Width * analog_Instability
    current_width = resonance_Width + randomGauss(0, width_drift)
    
    if current_width < 10
        current_width = 10
    endif
    if current_freq < 20
        current_freq = 20
    endif

    # Filter
    Filter (pass Hann band): current_freq - (current_width/2), current_freq + (current_width/2), 20
    Rename: "FilteredSignal"
    
    # Mixer Formula
    selectObject: "Sound StereoLoop"
    Formula: "2/pi * arctan( (self * damping_Factor) + (Sound_FilteredSignal[] * feedback_Gain) )"
    
    # Cleanup Loop Objects
    selectObject: "Sound FeedbackPath"
    plusObject: "Sound FilteredSignal"
    Remove
endfor

# --- 5. Spatial Post-Processing ---
selectObject: "Sound StereoLoop"

# Safety: Ensure Stereo
n_ch = Get number of channels
if n_ch = 1
    Convert to stereo
    Rename: "StereoLoop_Fixed"
    selectObject: "Sound StereoLoop"
    Remove
    selectObject: "Sound StereoLoop_Fixed"
    Rename: "StereoLoop"
endif

printline Applying Spatial Mode: 'spatial_Mode$'...

if spatial_Mode$ = "Mono (Summed)"
    Convert to mono
    Rename: "Final_Output"
    
else
    # Logic for all Stereo/Spatial modes
    selectObject: "Sound StereoLoop"
    Extract all channels
    
    id_L = selected("Sound", 1)
    id_R = selected("Sound", 2)
    
    selectObject: id_L
    Rename: "Ch_1"
    
    selectObject: id_R
    Rename: "Ch_2"
    
    # --- PROCESSING BLOCKS ---
    # Each block MUST create "Ch_1_filtered" and "Ch_2_filtered"
    # and leave "Ch_1" and "Ch_2" intact for cleanup.
    
    if spatial_Mode$ = "Stereo Wide (Freq Split)"
        selectObject: "Sound Ch_1"
        Filter (pass Hann band): 0, 4000, 100
        Rename: "Ch_1_filtered"
        
        selectObject: "Sound Ch_2"
        Filter (pass Hann band): 200, 22050, 100
        Rename: "Ch_2_filtered"
        
    elsif spatial_Mode$ = "Rotating (Auto-Pan)"
        rotation_rate = 0.2
        
        # FIX: Copy first, so we don't rename the original "Ch_1"
        selectObject: "Sound Ch_1"
        Copy: "Ch_1_filtered"
        Formula: "self * (0.6 + cos(2*pi*'rotation_rate'*x) * 0.4)"
        
        selectObject: "Sound Ch_2"
        Copy: "Ch_2_filtered"
        Formula: "self * (0.6 + sin(2*pi*'rotation_rate'*x) * 0.4)"
        
    elsif spatial_Mode$ = "Binaural (Delay/Filter)"
        selectObject: "Sound Ch_1"
        Filter (pass Hann band): 50, 3000, 80
        Rename: "Ch_1_filtered"
        
        selectObject: "Sound Ch_2"
        # We modify Ch_2 in place first, but Filter creates a NEW object anyway
        Formula: "if col > 30 then self[col - 30] else 0 fi"
        Filter (pass Hann band): 200, 6000, 80
        Rename: "Ch_2_filtered"
    endif
    
    # Recombine the PROCESSED versions
    selectObject: "Sound Ch_1_filtered"
    plusObject: "Sound Ch_2_filtered"
    Combine to stereo
    Rename: "Final_Output"
    
    # Cleanup Intermediate Filtered Files
    selectObject: "Sound Ch_1_filtered"
    plusObject: "Sound Ch_2_filtered"
    Remove
    
    # Cleanup Originals (Now safe for all modes)
    selectObject: "Sound Ch_1"
    plusObject: "Sound Ch_2"
    Remove
endif

# Clean up the original loop object
if spatial_Mode$ <> "Mono (Summed)"
    selectObject: "Sound StereoLoop"
    Remove
endif

# --- 6. Final Normalization ---
selectObject: "Sound Final_Output"
Scale peak: 0.95

Play
printline Process Complete.