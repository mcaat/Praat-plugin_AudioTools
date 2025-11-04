# ============================================================
# Praat AudioTools - Higher-Order Ambisonic.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Higher-Order Ambisonic (HOA) Encoder with Stereo Output
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Higher-Order Ambisonic (HOA) Encoder with Stereo Output
# This script encodes a mono sound source into ambisonic channels
# Supports 1st, 2nd, and 3rd order ambisonics
# Then decodes to stereo output

form Ambisonic Encoder with Stereo Output
    comment Select a mono Sound object first, then run this script
    optionmenu Position_preset 1
        option Custom
        option Front center (0°, 0°)
        option Front left (315°, 0°)
        option Left (270°, 0°)
        option Rear left (225°, 0°)
        option Rear center (180°, 0°)
        option Rear right (135°, 0°)
        option Right (90°, 0°)
        option Front right (45°, 0°)
        option Above (0°, 90°)
        option Below (0°, -90°)
    real Azimuth_(degrees_0-360) 0
    real Elevation_(degrees_-90_to_90) 0
    optionmenu Ambisonic_order 1
        option 1st order (4 channels)
        option 2nd order (9 channels)
        option 3rd order (16 channels)
    boolean Normalize_output 1
    boolean Create_stereo_output 1
endform

if position_preset = 2
    azimuth = 0
    elevation = 0
elsif position_preset = 3
    azimuth = 315
    elevation = 0
elsif position_preset = 4
    azimuth = 270
    elevation = 0
elsif position_preset = 5
    azimuth = 225
    elevation = 0
elsif position_preset = 6
    azimuth = 180
    elevation = 0
elsif position_preset = 7
    azimuth = 135
    elevation = 0
elsif position_preset = 8
    azimuth = 90
    elevation = 0
elsif position_preset = 9
    azimuth = 45
    elevation = 0
elsif position_preset = 10
    azimuth = 0
    elevation = 90
elsif position_preset = 11
    azimuth = 0
    elevation = -90
endif

sound = selected("Sound")
sound_name$ = selected$("Sound")
duration = Get total duration
sampling_frequency = Get sampling frequency
number_of_samples = Get number of samples

azimuth_rad = azimuth * pi / 180
elevation_rad = elevation * pi / 180

cos_az = cos(azimuth_rad)
sin_az = sin(azimuth_rad)
cos_el = cos(elevation_rad)
sin_el = sin(elevation_rad)
cos_el_sq = cos_el * cos_el
sin_el_sq = sin_el * sin_el

sqrt2 = sqrt(2)
sqrt3 = sqrt(3)
sqrt5 = sqrt(5)
sqrt15 = sqrt(15)

writeInfoLine: "Encoding ambisonic channels..."

selectObject: sound
w = Copy: sound_name$ + "_W"
Formula: "self"
appendInfoLine: "Channel 0 (W): Omnidirectional"

selectObject: sound
y = Copy: sound_name$ + "_Y"
Formula: "self * " + string$(cos_el * sin_az)
appendInfoLine: "Channel 1 (Y): cos(el)*sin(az) = ", cos_el * sin_az

selectObject: sound
z = Copy: sound_name$ + "_Z"
Formula: "self * " + string$(sin_el)
appendInfoLine: "Channel 2 (Z): sin(el) = ", sin_el

selectObject: sound
x = Copy: sound_name$ + "_X"
Formula: "self * " + string$(cos_el * cos_az)
appendInfoLine: "Channel 3 (X): cos(el)*cos(az) = ", cos_el * cos_az

if ambisonic_order >= 2
    appendInfoLine: ""
    appendInfoLine: "Adding 2nd order channels..."
    
    selectObject: sound
    v = Copy: sound_name$ + "_V"
    val = sqrt3 * cos_el_sq * sin_az * cos_az
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 4 (V): ", val
    
    selectObject: sound
    t = Copy: sound_name$ + "_T"
    val = sqrt3 * sin_el * cos_el * sin_az
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 5 (T): ", val
    
    selectObject: sound
    r = Copy: sound_name$ + "_R"
    val = 0.5 * sqrt3 * (3 * sin_el_sq - 1)
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 6 (R): ", val
    
    selectObject: sound
    s = Copy: sound_name$ + "_S"
    val = sqrt3 * sin_el * cos_el * cos_az
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 7 (S): ", val
    
    selectObject: sound
    u = Copy: sound_name$ + "_U"
    val = sqrt3 * cos_el_sq * (cos_az * cos_az - sin_az * sin_az) * 0.5
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 8 (U): ", val
endif

if ambisonic_order >= 3
    appendInfoLine: ""
    appendInfoLine: "Adding 3rd order channels..."
    
    cos_2az = cos(2 * azimuth_rad)
    sin_2az = sin(2 * azimuth_rad)
    cos_3az = cos(3 * azimuth_rad)
    sin_3az = sin(3 * azimuth_rad)
    
    selectObject: sound
    q = Copy: sound_name$ + "_Q"
    val = sqrt5 * cos_el * cos_el_sq * sin_3az * 0.25
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 9 (Q): ", val
    
    selectObject: sound
    o = Copy: sound_name$ + "_O"
    val = sqrt15 * sin_el * cos_el_sq * sin_2az * 0.5
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 10 (O): ", val
    
    selectObject: sound
    m = Copy: sound_name$ + "_M"
    val = sqrt3 * cos_el * (5 * sin_el_sq - 1) * sin_az * 0.25
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 11 (M): ", val
    
    selectObject: sound
    k = Copy: sound_name$ + "_K"
    val = sqrt3 * sin_el * (5 * sin_el_sq - 3) * 0.25
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 12 (K): ", val
    
    selectObject: sound
    l = Copy: sound_name$ + "_L"
    val = sqrt3 * cos_el * (5 * sin_el_sq - 1) * cos_az * 0.25
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 13 (L): ", val
    
    selectObject: sound
    n = Copy: sound_name$ + "_N"
    val = sqrt15 * sin_el * cos_el_sq * cos_2az * 0.5
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 14 (N): ", val
    
    selectObject: sound
    p = Copy: sound_name$ + "_P"
    val = sqrt5 * cos_el * cos_el_sq * cos_3az * 0.25
    Formula: "self * " + string$(val)
    appendInfoLine: "Channel 15 (P): ", val
endif

if normalize_output
    appendInfoLine: ""
    appendInfoLine: "Normalizing channels..."
    selectObject: w
    Scale peak: 0.99
    selectObject: y
    Scale peak: 0.99
    selectObject: z
    Scale peak: 0.99
    selectObject: x
    Scale peak: 0.99
    
    if ambisonic_order >= 2
        selectObject: v
        Scale peak: 0.99
        selectObject: t
        Scale peak: 0.99
        selectObject: r
        Scale peak: 0.99
        selectObject: s
        Scale peak: 0.99
        selectObject: u
        Scale peak: 0.99
    endif
    
    if ambisonic_order >= 3
        selectObject: q
        Scale peak: 0.99
        selectObject: o
        Scale peak: 0.99
        selectObject: m
        Scale peak: 0.99
        selectObject: k
        Scale peak: 0.99
        selectObject: l
        Scale peak: 0.99
        selectObject: n
        Scale peak: 0.99
        selectObject: p
        Scale peak: 0.99
    endif
endif

if create_stereo_output
    appendInfoLine: ""
    appendInfoLine: "====================================="
    appendInfoLine: "Creating stereo output..."
    
    left_az_rad = 330 * pi / 180
    right_az_rad = 30 * pi / 180
    spk_el_rad = 0
    
    cos_left = cos(left_az_rad)
    sin_left = sin(left_az_rad)
    cos_right = cos(right_az_rad)
    sin_right = sin(right_az_rad)
    cos_spk_el = cos(spk_el_rad)
    sin_spk_el = sin(spk_el_rad)
    
    w_coef = 1.0
    x_coef_left = cos_left * cos_spk_el
    y_coef_left = sin_left * cos_spk_el
    z_coef_left = sin_spk_el
    
    x_coef_right = cos_right * cos_spk_el
    y_coef_right = sin_right * cos_spk_el
    z_coef_right = sin_spk_el
    
    selectObject: sound
    left_channel = Copy: sound_name$ + "_StereoLeft"
    right_channel = Copy: sound_name$ + "_StereoRight"
    
    selectObject: left_channel
    Formula: "0"
    selectObject: right_channel
    Formula: "0"
    
    selectObject: w
    w_left = Copy: "temp_w_left"
    Formula: "self * " + string$(w_coef)
    selectObject: left_channel
    plus w_left
    Formula: "self[col] + object[""Sound temp_w_left""][col]"
    selectObject: w_left
    Remove
    
    selectObject: x
    x_left = Copy: "temp_x_left"
    Formula: "self * " + string$(x_coef_left)
    selectObject: left_channel
    plus x_left
    Formula: "self[col] + object[""Sound temp_x_left""][col]"
    selectObject: x_left
    Remove
    
    selectObject: y
    y_left = Copy: "temp_y_left"
    Formula: "self * " + string$(y_coef_left)
    selectObject: left_channel
    plus y_left
    Formula: "self[col] + object[""Sound temp_y_left""][col]"
    selectObject: y_left
    Remove
    
    selectObject: z
    z_left = Copy: "temp_z_left"
    Formula: "self * " + string$(z_coef_left)
    selectObject: left_channel
    plus z_left
    Formula: "self[col] + object[""Sound temp_z_left""][col]"
    selectObject: z_left
    Remove
    
    selectObject: w
    w_right = Copy: "temp_w_right"
    Formula: "self * " + string$(w_coef)
    selectObject: right_channel
    plus w_right
    Formula: "self[col] + object[""Sound temp_w_right""][col]"
    selectObject: w_right
    Remove
    
    selectObject: x
    x_right = Copy: "temp_x_right"
    Formula: "self * " + string$(x_coef_right)
    selectObject: right_channel
    plus x_right
    Formula: "self[col] + object[""Sound temp_x_right""][col]"
    selectObject: x_right
    Remove
    
    selectObject: y
    y_right = Copy: "temp_y_right"
    Formula: "self * " + string$(y_coef_right)
    selectObject: right_channel
    plus y_right
    Formula: "self[col] + object[""Sound temp_y_right""][col]"
    selectObject: y_right
    Remove
    
    selectObject: z
    z_right = Copy: "temp_z_right"
    Formula: "self * " + string$(z_coef_right)
    selectObject: right_channel
    plus z_right
    Formula: "self[col] + object[""Sound temp_z_right""][col]"
    selectObject: z_right
    Remove
    
    selectObject: left_channel
    plus right_channel
    stereo = Combine to stereo
    Rename: sound_name$ + "_Stereo"
    Scale peak: 0.99
    
    selectObject: left_channel
    plus right_channel
    Remove
    
    appendInfoLine: "Stereo output created: ", sound_name$ + "_Stereo"
    appendInfoLine: "Left speaker: 330° (30° left of center)"
    appendInfoLine: "Right speaker: 30° (30° right of center)"
endif

appendInfoLine: ""
appendInfoLine: "====================================="
appendInfoLine: "Encoding complete!"
appendInfoLine: "Source position: ", azimuth, "° azimuth, ", elevation, "° elevation"
if ambisonic_order = 1
    appendInfoLine: "Created 4 ambisonic channels (1st order)"
elsif ambisonic_order = 2
    appendInfoLine: "Created 9 ambisonic channels (2nd order)"
else
    appendInfoLine: "Created 16 ambisonic channels (3rd order)"
endif

if create_stereo_output
    appendInfoLine: "Created stereo output for playback"
endif

appendInfoLine: "All channels are now in the Objects list"
appendInfoLine: "====================================="