# ============================================================
# Praat AudioTools - Stretch-Tremolo Ambience.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Stretch-Tremolo Ambience
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Stretch-Tremolo Ambience
    comment --- Presets ---
    optionmenu Preset 1
        option Custom (Use settings below)
        option Ethereal Pad (Smooth)
        option Ghostly Trail (Slow pulse)
        option Dark Drone (Deep stretch)
        option Shimmering Tail (Fast wobble)
    
    comment --- Stretch Parameters ---
    positive Stretch_factor 3.0
    comment (Higher = smoother, longer texture)
    
    comment --- Cloud Modulation ---
    positive Cloud_Rate_Hz 2.0
    positive Cloud_Depth 0.5
    
    comment --- Mix ---
    positive Dry_Mix 1.0
    positive Wet_Cloud_Mix 0.6
    
    comment --- Output ---
    positive Scale_peak 0.99
    boolean Play_after_processing 1
endform

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# ============================================================
# SAFETY: RENAME SOUND
# ============================================================
# We rename the source to a safe name so we can always restore it later
original_sound_id = selected("Sound")
original_name$ = selected$("Sound")
selectObject: original_sound_id
Rename: "SourceAudio_Temp"

# ============================================================
# PRESET LOGIC
# ============================================================

if preset = 2
    # Ethereal Pad
    stretch_factor = 4.0; cloud_Rate_Hz = 0.5; cloud_Depth = 0.3; wet_Cloud_Mix = 0.5
elsif preset = 3
    # Ghostly Trail
    stretch_factor = 2.5; cloud_Rate_Hz = 4.0; cloud_Depth = 0.6; wet_Cloud_Mix = 0.4
elsif preset = 4
    # Dark Drone
    stretch_factor = 8.0; cloud_Rate_Hz = 0.2; cloud_Depth = 0.2; wet_Cloud_Mix = 0.7
elsif preset = 5
    # Shimmering Tail
    stretch_factor = 3.0; cloud_Rate_Hz = 6.0; cloud_Depth = 0.5; wet_Cloud_Mix = 0.4
endif

# ============================================================
# PROCESSING
# ============================================================

selectObject: original_sound_id
dur = Get total duration
sampling = Get sampling frequency

# 1. Create the Cloud Layer
Convert to mono
cloud_id = selected("Sound")
Lengthen (overlap-add): 75, 600, stretch_factor
Rename: "Cloud_Raw"
stretched_id = selected("Sound")
removeObject: cloud_id

# 2. Modulate the Cloud Layer (Tremolo)
selectObject: stretched_id
Formula: "self * (1 - 'cloud_Depth' * (1 + sin(2 * pi * 'cloud_Rate_Hz' * x)) / 2)"

# 3. Crop and RENAME the Cloud
# This was the fix: We explicitly rename the result to "CloudAudio_Temp"
Extract part: 0, dur, "rectangular", 1, "no"
Rename: "CloudAudio_Temp"
cloud_final_id = selected("Sound")
removeObject: stretched_id

# 4. Mix Original + Cloud
# We create a copy of the original to apply the mix formula
selectObject: original_sound_id
Copy: original_name$ + "_cloud"
output_id = selected("Sound")

# Apply Mix Formula
# Now we reference Sound_CloudAudio_Temp which is guaranteed to exist
# We use [col] to safely map mono cloud to stereo original if needed
Formula: "self * 'dry_Mix' + Sound_CloudAudio_Temp[col] * 'wet_Cloud_Mix'"

# ============================================================
# CLEANUP
# ============================================================

removeObject: cloud_final_id
selectObject: original_sound_id
Rename: original_name$

selectObject: output_id
Scale peak: scale_peak

if play_after_processing
    Play
endif