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
# Higher-Order Ambisonic (HOA) Encoder with Visualization
# This script encodes a mono sound source into ambisonic channels
# Supports 1st, 2nd, and 3rd order ambisonics
# Creates a multichannel sound object with all ambisonic channels
# Shows a top-down visualization of the source position
Erase all
form Ambisonic Encoder
    comment Select a Sound object first, then run this script
    optionmenu Position_preset 1
        option Custom
        option Front center (0°, 0°, 1.5m)
        option Front left (315°, 0°, 2m)
        option Left (270°, 0°, 2m)
        option Rear left (225°, 0°, 3m)
        option Rear center (180°, 0°, 3m)
        option Rear right (135°, 0°, 3m)
        option Right (90°, 0°, 2m)
        option Front right (45°, 0°, 2m)
        option Above (0°, 90°, 2.5m)
        option Below (0°, -90°, 2.5m)
    real Azimuth_(degrees_0-360) 0
    real Elevation_(degrees_-90_to_90) 0
    real Distance_(meters) 1.0
    real Reference_distance_(meters) 1.0
    optionmenu Ambisonic_order 1
        option 1st order (4 channels)
        option 2nd order (9 channels)
        option 3rd order (16 channels)
    boolean Normalize_output 1
    boolean Create_multichannel_sound 1
    boolean Show_visualization 1
endform

if position_preset = 2
    azimuth = 0
    elevation = 0
    distance = 1.5
elsif position_preset = 3
    azimuth = 315
    elevation = 0
    distance = 2.0
elsif position_preset = 4
    azimuth = 270
    elevation = 0
    distance = 2.0
elsif position_preset = 5
    azimuth = 225
    elevation = 0
    distance = 3.0
elsif position_preset = 6
    azimuth = 180
    elevation = 0
    distance = 3.0
elsif position_preset = 7
    azimuth = 135
    elevation = 0
    distance = 3.0
elsif position_preset = 8
    azimuth = 90
    elevation = 0
    distance = 2.0
elsif position_preset = 9
    azimuth = 45
    elevation = 0
    distance = 2.0
elsif position_preset = 10
    azimuth = 0
    elevation = 90
    distance = 2.5
elsif position_preset = 11
    azimuth = 0
    elevation = -90
    distance = 2.5
endif

original_sound = selected("Sound")
original_name$ = selected$("Sound")

num_channels = Get number of channels

writeInfoLine: "Preparing input sound..."
appendInfoLine: "Original file: ", original_name$
appendInfoLine: "Number of channels: ", num_channels

if num_channels > 1
    appendInfoLine: "Converting to mono..."
    selectObject: original_sound
    sound = Convert to mono
    sound_name$ = original_name$ + "_mono"
    Rename: sound_name$
    appendInfoLine: "Created mono version: ", sound_name$
else
    sound = original_sound
    sound_name$ = original_name$
    appendInfoLine: "Input is already mono"
endif

selectObject: sound
duration = Get total duration
sampling_frequency = Get sampling frequency
number_of_samples = Get number of samples

if distance <= 0
    distance = 0.001
endif
if reference_distance <= 0
    reference_distance = 1.0
endif

distance_gain = reference_distance / distance

appendInfoLine: ""
appendInfoLine: "Distance attenuation:"
appendInfoLine: "Distance: ", distance, " meters"
appendInfoLine: "Reference distance: ", reference_distance, " meters"
appendInfoLine: "Applied gain: ", distance_gain, " (", 20 * log10(distance_gain), " dB)"
appendInfoLine: ""

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

appendInfoLine: "Encoding ambisonic channels..."

selectObject: sound
w = Copy: sound_name$ + "_W"
Formula: "self * " + string$(distance_gain)
appendInfoLine: "Channel 0 (W): Omnidirectional"

selectObject: sound
y = Copy: sound_name$ + "_Y"
Formula: "self * " + string$(distance_gain * cos_el * sin_az)
appendInfoLine: "Channel 1 (Y): cos(el)*sin(az) = ", cos_el * sin_az

selectObject: sound
z = Copy: sound_name$ + "_Z"
Formula: "self * " + string$(distance_gain * sin_el)
appendInfoLine: "Channel 2 (Z): sin(el) = ", sin_el

selectObject: sound
x = Copy: sound_name$ + "_X"
Formula: "self * " + string$(distance_gain * cos_el * cos_az)
appendInfoLine: "Channel 3 (X): cos(el)*cos(az) = ", cos_el * cos_az

if ambisonic_order >= 2
    appendInfoLine: ""
    appendInfoLine: "Adding 2nd order channels..."
    
    selectObject: sound
    v = Copy: sound_name$ + "_V"
    val = sqrt3 * cos_el_sq * sin_az * cos_az
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 4 (V): ", val
    
    selectObject: sound
    t = Copy: sound_name$ + "_T"
    val = sqrt3 * sin_el * cos_el * sin_az
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 5 (T): ", val
    
    selectObject: sound
    r = Copy: sound_name$ + "_R"
    val = 0.5 * sqrt3 * (3 * sin_el_sq - 1)
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 6 (R): ", val
    
    selectObject: sound
    s = Copy: sound_name$ + "_S"
    val = sqrt3 * sin_el * cos_el * cos_az
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 7 (S): ", val
    
    selectObject: sound
    u = Copy: sound_name$ + "_U"
    val = sqrt3 * cos_el_sq * (cos_az * cos_az - sin_az * sin_az) * 0.5
    Formula: "self * " + string$(distance_gain * val)
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
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 9 (Q): ", val
    
    selectObject: sound
    o = Copy: sound_name$ + "_O"
    val = sqrt15 * sin_el * cos_el_sq * sin_2az * 0.5
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 10 (O): ", val
    
    selectObject: sound
    m = Copy: sound_name$ + "_M"
    val = sqrt3 * cos_el * (5 * sin_el_sq - 1) * sin_az * 0.25
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 11 (M): ", val
    
    selectObject: sound
    k = Copy: sound_name$ + "_K"
    val = sqrt3 * sin_el * (5 * sin_el_sq - 3) * 0.25
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 12 (K): ", val
    
    selectObject: sound
    l = Copy: sound_name$ + "_L"
    val = sqrt3 * cos_el * (5 * sin_el_sq - 1) * cos_az * 0.25
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 13 (L): ", val
    
    selectObject: sound
    n = Copy: sound_name$ + "_N"
    val = sqrt15 * sin_el * cos_el_sq * cos_2az * 0.5
    Formula: "self * " + string$(distance_gain * val)
    appendInfoLine: "Channel 14 (N): ", val
    
    selectObject: sound
    p = Copy: sound_name$ + "_P"
    val = sqrt5 * cos_el * cos_el_sq * cos_3az * 0.25
    Formula: "self * " + string$(distance_gain * val)
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

if create_multichannel_sound
    appendInfoLine: ""
    appendInfoLine: "====================================="
    appendInfoLine: "Creating multichannel sound object..."
    
    selectObject: w
    plus y
    plus z
    plus x
    
    if ambisonic_order >= 2
        plus v
        plus t
        plus r
        plus s
        plus u
    endif
    
    if ambisonic_order >= 3
        plus q
        plus o
        plus m
        plus k
        plus l
        plus n
        plus p
    endif
    
    if ambisonic_order = 1
        multichannel = Combine to stereo
        Rename: sound_name$ + "_Ambisonic_1st"
        appendInfoLine: "Created 4-channel sound: ", sound_name$ + "_Ambisonic_1st"
        appendInfoLine: "Channel order: W, Y, Z, X (ACN)"
    elsif ambisonic_order = 2
        multichannel = Concatenate
        Rename: sound_name$ + "_Ambisonic_2nd"
        appendInfoLine: "Created 9-channel sound: ", sound_name$ + "_Ambisonic_2nd"
        appendInfoLine: "Channel order: W, Y, Z, X, V, T, R, S, U (ACN)"
    else
        multichannel = Concatenate
        Rename: sound_name$ + "_Ambisonic_3rd"
        appendInfoLine: "Created 16-channel sound: ", sound_name$ + "_Ambisonic_3rd"
        appendInfoLine: "Channel order: W, Y, Z, X, V, T, R, S, U, Q, O, M, K, L, N, P (ACN)"
    endif
endif

if show_visualization
    appendInfoLine: ""
    appendInfoLine: "====================================="
    appendInfoLine: "Creating visualization..."
    
    Erase all
    
    Select outer viewport: 0, 6, 0, 6
    Axes: -4, 4, -4, 4
    
    Draw inner box
    
    Grey
    Line width: 1
    for i to 4
        Draw circle: 0, 0, i
    endfor
    
    Black
    Line width: 2
    Draw line: 0, -4, 0, 4
    Draw line: -4, 0, 4, 0
    
    Line width: 1
    angle = 45
    while angle <= 315
        angle_rad = angle * pi / 180
        x_end = 4 * cos(angle_rad)
        y_end = 4 * sin(angle_rad)
        Draw line: 0, 0, x_end, y_end
        angle = angle + 45
    endwhile
    
    Font size: 14
    Text: 0, "centre", 4.3, "half", "Front (0°)"
    Text: 0, "centre", -4.3, "half", "Back (180°)"
    Text: -4.3, "centre", 0, "half", "Left (270°)"
    Text: 4.3, "centre", 0, "half", "Right (90°)"
    
    Font size: 10
    Text: 0, "centre", 1, "half", "1m"
    Text: 0, "centre", 2, "half", "2m"
    Text: 0, "centre", 3, "half", "3m"
    Text: 0, "centre", 4, "half", "4m"
    
    source_x = distance * sin(azimuth_rad)
    source_y = distance * cos(azimuth_rad)
    
    Red
    Line width: 3
    Draw arrow: 0, 0, source_x, source_y
    
    Paint circle (mm): "Red", source_x, source_y, 3
    
    Black
    Font size: 12
    Text: source_x, "centre", source_y + 0.4, "half", "Source"
    
    Text: 0, "centre", -5, "half", "Azimuth: " + string$(azimuth) + "°, Distance: " + string$(distance) + "m"
    if elevation <> 0
        Text: 0, "centre", -5.5, "half", "Elevation: " + string$(elevation) + "°"
    endif
    
    appendInfoLine: "Visualization created in Picture window"
endif

appendInfoLine: ""
appendInfoLine: "====================================="
appendInfoLine: "Encoding complete!"
appendInfoLine: "Source position: ", azimuth, "° azimuth, ", elevation, "° elevation"
appendInfoLine: "Distance: ", distance, " meters (gain: ", distance_gain, ")"
if ambisonic_order = 1
    appendInfoLine: "Created 4 ambisonic channels (1st order)"
elsif ambisonic_order = 2
    appendInfoLine: "Created 9 ambisonic channels (2nd order)"
else
    appendInfoLine: "Created 16 ambisonic channels (3rd order)"
endif

if create_multichannel_sound
    appendInfoLine: "Created multichannel ambisonic sound object"
    appendInfoLine: "Individual channels (W, Y, Z, X, ...) are also available"
endif

appendInfoLine: "====================================="



