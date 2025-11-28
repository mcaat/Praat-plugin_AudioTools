# ============================================================
# Praat AudioTools - Stereo Rotary Speaker.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Stereo Rotary Speaker (Leslie Model
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Stereo Rotary Speaker
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Chorale (Slow / Hymn)
        option Tremolo (Fast / Rock)
        option Transition (Ramping Up)
        option Wide Stereo Spin
        option Broken Cabinet (Wobbly)
    
    comment --- Rotation Mechanics ---
    positive Rotation_Speed_Hz 6.8
    comment (Chorale ~0.8Hz, Tremolo ~7Hz)
    
    comment --- Horn Physics (Treble) ---
    positive Doppler_Depth 0.12
    comment (Pitch wobble amount)
    positive Tremolo_Depth 0.5
    comment (Volume wobble amount)
    
    comment --- Microphone Placement ---
    positive Stereo_Width_Deg 140
    comment (Angle between Left/Right Microphones. 180 = Wide)
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check for selection
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# PRESET LOGIC
# ============================================================
if preset = 2
    # Chorale (Slow)
    rotation_Speed_Hz = 0.8
    doppler_Depth = 0.08
    tremolo_Depth = 0.3
    stereo_Width_Deg = 120
elsif preset = 3
    # Tremolo (Fast)
    rotation_Speed_Hz = 6.8
    doppler_Depth = 0.12
    tremolo_Depth = 0.5
    stereo_Width_Deg = 160
elsif preset = 4
    # Transition (Mid-speed blur)
    rotation_Speed_Hz = 4.0
    doppler_Depth = 0.15
    tremolo_Depth = 0.4
    stereo_Width_Deg = 180
elsif preset = 5
    # Wide Stereo Spin
    rotation_Speed_Hz = 2.5
    doppler_Depth = 0.10
    tremolo_Depth = 0.7
    stereo_Width_Deg = 180
elsif preset = 6
    # Broken Cabinet
    rotation_Speed_Hz = 9.0
    doppler_Depth = 0.25
    tremolo_Depth = 0.6
    stereo_Width_Deg = 45
endif

# ============================================================
# SETUP STEREO FIELD
# ============================================================
selectObject: original_sound_id
sampling = Get sampling frequency

# Force Stereo (Leslie is inherently stereo)
Convert to stereo
Rename: "Stereo_Temp"
stereo_id = selected("Sound")

# Parameters
base_delay_ms = 5.0
base_samp = round(base_delay_ms * sampling / 1000)
width_rad = stereo_Width_Deg * pi / 180

# ============================================================
# APPLY PHYSICAL MODEL FORMULA
# ============================================================

selectObject: stereo_id
Copy: original_name$ + "_rotary"
output_id = selected("Sound")

# The Fix: We removed "self *" from the start of the lines.
# Now it strictly calculates: (Volume_LFO) * (Delayed_Sample)

Formula: "
... if row = 1 then
...    (1 - 'tremolo_Depth' * 0.5 * (1 + sin(2*pi*'rotation_Speed_Hz'*x))) * Sound_Stereo_Temp[1, col - round('base_samp' * (1 + 'doppler_Depth' * sin(2*pi*'rotation_Speed_Hz'*x + 1.57)))]
... else
...    (1 - 'tremolo_Depth' * 0.5 * (1 + sin(2*pi*'rotation_Speed_Hz'*x + 'width_rad'))) * Sound_Stereo_Temp[2, col - round('base_samp' * (1 + 'doppler_Depth' * sin(2*pi*'rotation_Speed_Hz'*x + 'width_rad' + 1.57)))]
... fi"

# ============================================================
# CLEANUP
# ============================================================

removeObject: stereo_id
selectObject: original_sound_id
Rename: original_name$

selectObject: output_id
Scale peak: scale_peak

if play_after_processing
    Play
endif