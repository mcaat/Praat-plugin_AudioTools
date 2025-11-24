# ============================================================
# Praat AudioTools - Knight's Tour Sonification.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  Knight's Tour Audio Mapping with Sonification & Real-time Visualization
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Knight's Tour Audio Mapping with Sonification & Real-time Visualization

form Knight's Tour Sonification
    comment Knight's Tour Path Preset
    optionmenu tourPreset 1
        option Warnsdorff (Classic)
        option Spiral Pattern
        option Diagonal Heavy
        option Center-Out
        option Alternating Sides
    comment Intensity (Loudness) Mapping
    real intensityMin 0.3
    real intensityMax 1.0
    comment Stereo Position Mapping
    real stereoMin 0.0
    real stereoMax 1.0
    comment Playback
    boolean playDuringProcessing 1
    comment Visualization
    positive visualizationDelay 0.05
endform

# Validate ranges
if intensityMin < 0
    intensityMin = 0
endif
if intensityMax > 1
    intensityMax = 1
endif
if intensityMin >= intensityMax
    exitScript: "Error: intensityMin must be less than intensityMax"
endif
if stereoMin < 0
    stereoMin = 0
endif
if stereoMax > 1
    stereoMax = 1
endif
if stereoMin >= stereoMax
    exitScript: "Error: stereoMin must be less than stereoMax"
endif

# Select sound object
soundName$ = selected$("Sound")
originalSound = selected("Sound")
duration = Get total duration
sampleRate = Get sampling frequency
nChannels = Get number of channels

# Convert to mono if stereo (we'll create new stereo output)
if nChannels = 2
    select originalSound
    Convert to mono
    monoSound = selected("Sound")
else
    monoSound = originalSound
endif

# Initialize arrays
for i to 64
    x[i] = 0
    y[i] = 0
endfor

# ===== LOAD SELECTED KNIGHT'S TOUR PRESET =====
if tourPreset = 1
    # Warnsdorff (Classic) - Traditional knight's tour
    x[1] = 1
    y[1] = 1
    x[2] = 2
    y[2] = 3
    x[3] = 1
    y[3] = 5
    x[4] = 2
    y[4] = 7
    x[5] = 4
    y[5] = 8
    x[6] = 6
    y[6] = 7
    x[7] = 8
    y[7] = 8
    x[8] = 7
    y[8] = 6
    x[9] = 8
    y[9] = 4
    x[10] = 7
    y[10] = 2
    x[11] = 5
    y[11] = 1
    x[12] = 3
    y[12] = 2
    x[13] = 1
    y[13] = 3
    x[14] = 2
    y[14] = 5
    x[15] = 1
    y[15] = 7
    x[16] = 3
    y[16] = 8
    x[17] = 5
    y[17] = 7
    x[18] = 7
    y[18] = 8
    x[19] = 8
    y[19] = 6
    x[20] = 7
    y[20] = 4
    x[21] = 8
    y[21] = 2
    x[22] = 6
    y[22] = 1
    x[23] = 4
    y[23] = 2
    x[24] = 2
    y[24] = 1
    x[25] = 1
    y[25] = 2
    x[26] = 3
    y[26] = 1
    x[27] = 5
    y[27] = 2
    x[28] = 7
    y[28] = 1
    x[29] = 8
    y[29] = 3
    x[30] = 6
    y[30] = 4
    x[31] = 8
    y[31] = 5
    x[32] = 7
    y[32] = 7
    x[33] = 5
    y[33] = 8
    x[34] = 3
    y[34] = 7
    x[35] = 1
    y[35] = 8
    x[36] = 2
    y[36] = 6
    x[37] = 4
    y[37] = 7
    x[38] = 6
    y[38] = 8
    x[39] = 8
    y[39] = 7
    x[40] = 7
    y[40] = 5
    x[41] = 5
    y[41] = 6
    x[42] = 3
    y[42] = 5
    x[43] = 1
    y[43] = 6
    x[44] = 2
    y[44] = 8
    x[45] = 4
    y[45] = 6
    x[46] = 6
    y[46] = 5
    x[47] = 8
    y[47] = 6
    x[48] = 7
    y[48] = 8
    x[49] = 5
    y[49] = 7
    x[50] = 3
    y[50] = 8
    x[51] = 1
    y[51] = 7
    x[52] = 2
    y[52] = 5
    x[53] = 4
    y[53] = 4
    x[54] = 6
    y[54] = 3
    x[55] = 8
    y[55] = 4
    x[56] = 7
    y[56] = 6
    x[57] = 5
    y[57] = 5
    x[58] = 3
    y[58] = 6
    x[59] = 1
    y[59] = 5
    x[60] = 2
    y[60] = 7
    x[61] = 4
    y[61] = 8
    x[62] = 6
    y[62] = 7
    x[63] = 8
    y[63] = 8
    x[64] = 7
    y[64] = 7
elsif tourPreset = 2
    # Spiral Pattern - moves outward in a spiral
    x[1] = 4
    y[1] = 4
    x[2] = 6
    y[2] = 5
    x[3] = 7
    y[3] = 7
    x[4] = 5
    y[4] = 8
    x[5] = 3
    y[5] = 7
    x[6] = 1
    y[6] = 8
    x[7] = 2
    y[7] = 6
    x[8] = 1
    y[8] = 4
    x[9] = 2
    y[9] = 2
    x[10] = 4
    y[10] = 1
    x[11] = 6
    y[11] = 2
    x[12] = 8
    y[12] = 1
    x[13] = 7
    y[13] = 3
    x[14] = 8
    y[14] = 5
    x[15] = 7
    y[15] = 7
    x[16] = 5
    y[16] = 6
    x[17] = 3
    y[17] = 5
    x[18] = 1
    y[18] = 6
    x[19] = 2
    y[19] = 4
    x[20] = 4
    y[20] = 3
    x[21] = 6
    y[21] = 4
    x[22] = 8
    y[22] = 3
    x[23] = 7
    y[23] = 5
    x[24] = 5
    y[24] = 4
    x[25] = 3
    y[25] = 3
    x[26] = 1
    y[26] = 2
    x[27] = 3
    y[27] = 1
    x[28] = 5
    y[28] = 2
    x[29] = 7
    y[29] = 1
    x[30] = 8
    y[30] = 3
    x[31] = 6
    y[31] = 4
    x[32] = 4
    y[32] = 5
    x[33] = 2
    y[33] = 4
    x[34] = 1
    y[34] = 6
    x[35] = 3
    y[35] = 7
    x[36] = 5
    y[36] = 8
    x[37] = 7
    y[37] = 7
    x[38] = 8
    y[38] = 5
    x[39] = 6
    y[39] = 6
    x[40] = 4
    y[40] = 7
    x[41] = 2
    y[41] = 8
    x[42] = 1
    y[42] = 6
    x[43] = 3
    y[43] = 5
    x[44] = 5
    y[44] = 6
    x[45] = 7
    y[45] = 5
    x[46] = 8
    y[46] = 7
    x[47] = 6
    y[47] = 8
    x[48] = 4
    y[48] = 7
    x[49] = 2
    y[49] = 6
    x[50] = 1
    y[50] = 4
    x[51] = 3
    y[51] = 3
    x[52] = 5
    y[52] = 4
    x[53] = 7
    y[53] = 3
    x[54] = 8
    y[54] = 1
    x[55] = 6
    y[55] = 2
    x[56] = 4
    y[56] = 3
    x[57] = 2
    y[57] = 2
    x[58] = 1
    y[58] = 4
    x[59] = 3
    y[59] = 5
    x[60] = 5
    y[60] = 4
    x[61] = 7
    y[61] = 5
    x[62] = 8
    y[62] = 7
    x[63] = 6
    y[63] = 6
    x[64] = 4
    y[64] = 5
elsif tourPreset = 3
    # Diagonal Heavy - emphasizes diagonal movements
    x[1] = 1
    y[1] = 1
    x[2] = 3
    y[2] = 2
    x[3] = 5
    y[3] = 3
    x[4] = 7
    y[4] = 4
    x[5] = 8
    y[5] = 6
    x[6] = 6
    y[6] = 7
    x[7] = 4
    y[7] = 8
    x[8] = 2
    y[8] = 7
    x[9] = 1
    y[9] = 5
    x[10] = 2
    y[10] = 3
    x[11] = 4
    y[11] = 2
    x[12] = 6
    y[12] = 1
    x[13] = 8
    y[13] = 2
    x[14] = 7
    y[14] = 4
    x[15] = 5
    y[15] = 5
    x[16] = 3
    y[16] = 6
    x[17] = 1
    y[17] = 7
    x[18] = 2
    y[18] = 5
    x[19] = 4
    y[19] = 4
    x[20] = 6
    y[20] = 3
    x[21] = 8
    y[21] = 4
    x[22] = 7
    y[22] = 6
    x[23] = 5
    y[23] = 7
    x[24] = 3
    y[24] = 8
    x[25] = 1
    y[25] = 7
    x[26] = 2
    y[26] = 5
    x[27] = 4
    y[27] = 6
    x[28] = 6
    y[28] = 5
    x[29] = 8
    y[29] = 6
    x[30] = 7
    y[30] = 8
    x[31] = 5
    y[31] = 7
    x[32] = 3
    y[32] = 6
    x[33] = 1
    y[33] = 5
    x[34] = 2
    y[34] = 3
    x[35] = 4
    y[35] = 4
    x[36] = 6
    y[36] = 5
    x[37] = 8
    y[37] = 4
    x[38] = 7
    y[38] = 2
    x[39] = 5
    y[39] = 1
    x[40] = 3
    y[40] = 2
    x[41] = 1
    y[41] = 3
    x[42] = 2
    y[42] = 5
    x[43] = 4
    y[43] = 6
    x[44] = 6
    y[44] = 7
    x[45] = 8
    y[45] = 8
    x[46] = 7
    y[46] = 6
    x[47] = 5
    y[47] = 5
    x[48] = 3
    y[48] = 4
    x[49] = 1
    y[49] = 3
    x[50] = 2
    y[50] = 1
    x[51] = 4
    y[51] = 2
    x[52] = 6
    y[52] = 3
    x[53] = 8
    y[53] = 2
    x[54] = 7
    y[54] = 4
    x[55] = 5
    y[55] = 3
    x[56] = 3
    y[56] = 4
    x[57] = 1
    y[57] = 5
    x[58] = 2
    y[58] = 7
    x[59] = 4
    y[59] = 8
    x[60] = 6
    y[60] = 7
    x[61] = 8
    y[61] = 8
    x[62] = 7
    y[62] = 6
    x[63] = 5
    y[63] = 5
    x[64] = 3
    y[64] = 6
elsif tourPreset = 4
    # Center-Out - starts in center, moves outward
    x[1] = 4
    y[1] = 4
    x[2] = 6
    y[2] = 5
    x[3] = 8
    y[3] = 4
    x[4] = 7
    y[4] = 6
    x[5] = 5
    y[5] = 7
    x[6] = 3
    y[6] = 8
    x[7] = 1
    y[7] = 7
    x[8] = 2
    y[8] = 5
    x[9] = 1
    y[9] = 3
    x[10] = 3
    y[10] = 2
    x[11] = 5
    y[11] = 1
    x[12] = 7
    y[12] = 2
    x[13] = 8
    y[13] = 4
    x[14] = 6
    y[14] = 5
    x[15] = 4
    y[15] = 6
    x[16] = 2
    y[16] = 7
    x[17] = 1
    y[17] = 5
    x[18] = 2
    y[18] = 3
    x[19] = 4
    y[19] = 2
    x[20] = 6
    y[20] = 1
    x[21] = 8
    y[21] = 2
    x[22] = 7
    y[22] = 4
    x[23] = 5
    y[23] = 5
    x[24] = 3
    y[24] = 6
    x[25] = 1
    y[25] = 7
    x[26] = 2
    y[26] = 5
    x[27] = 4
    y[27] = 4
    x[28] = 6
    y[28] = 3
    x[29] = 8
    y[29] = 4
    x[30] = 7
    y[30] = 6
    x[31] = 5
    y[31] = 7
    x[32] = 3
    y[32] = 8
    x[33] = 1
    y[33] = 7
    x[34] = 2
    y[34] = 5
    x[35] = 4
    y[35] = 6
    x[36] = 6
    y[36] = 7
    x[37] = 8
    y[37] = 8
    x[38] = 7
    y[38] = 6
    x[39] = 5
    y[39] = 5
    x[40] = 3
    y[40] = 4
    x[41] = 1
    y[41] = 3
    x[42] = 2
    y[42] = 1
    x[43] = 4
    y[43] = 2
    x[44] = 6
    y[44] = 3
    x[45] = 8
    y[45] = 2
    x[46] = 7
    y[46] = 4
    x[47] = 5
    y[47] = 3
    x[48] = 3
    y[48] = 2
    x[49] = 1
    y[49] = 1
    x[50] = 2
    y[50] = 3
    x[51] = 4
    y[51] = 4
    x[52] = 6
    y[52] = 5
    x[53] = 8
    y[53] = 6
    x[54] = 7
    y[54] = 8
    x[55] = 5
    y[55] = 7
    x[56] = 3
    y[56] = 6
    x[57] = 1
    y[57] = 5
    x[58] = 2
    y[58] = 7
    x[59] = 4
    y[59] = 8
    x[60] = 6
    y[60] = 7
    x[61] = 8
    y[61] = 8
    x[62] = 7
    y[62] = 6
    x[63] = 5
    y[63] = 5
    x[64] = 4
    y[64] = 4
elsif tourPreset = 5
    # Alternating Sides - jumps between left and right
    x[1] = 1
    y[1] = 1
    x[2] = 3
    y[2] = 2
    x[3] = 5
    y[3] = 1
    x[4] = 7
    y[4] = 2
    x[5] = 8
    y[5] = 4
    x[6] = 6
    y[6] = 5
    x[7] = 8
    y[7] = 6
    x[8] = 7
    y[8] = 8
    x[9] = 5
    y[9] = 7
    x[10] = 3
    y[10] = 8
    x[11] = 1
    y[11] = 7
    x[12] = 2
    y[12] = 5
    x[13] = 1
    y[13] = 3
    x[14] = 2
    y[14] = 1
    x[15] = 4
    y[15] = 2
    x[16] = 6
    y[16] = 1
    x[17] = 8
    y[17] = 2
    x[18] = 7
    y[18] = 4
    x[19] = 8
    y[19] = 6
    x[20] = 6
    y[20] = 7
    x[21] = 4
    y[21] = 8
    x[22] = 2
    y[22] = 7
    x[23] = 1
    y[23] = 5
    x[24] = 2
    y[24] = 3
    x[25] = 4
    y[25] = 4
    x[26] = 6
    y[26] = 3
    x[27] = 8
    y[27] = 4
    x[28] = 7
    y[28] = 6
    x[29] = 5
    y[29] = 5
    x[30] = 3
    y[30] = 6
    x[31] = 1
    y[31] = 7
    x[32] = 2
    y[32] = 5
    x[33] = 4
    y[33] = 6
    x[34] = 6
    y[34] = 5
    x[35] = 8
    y[35] = 6
    x[36] = 7
    y[36] = 8
    x[37] = 5
    y[37] = 7
    x[38] = 3
    y[38] = 8
    x[39] = 1
    y[39] = 7
    x[40] = 2
    y[40] = 5
    x[41] = 1
    y[41] = 3
    x[42] = 3
    y[42] = 2
    x[43] = 5
    y[43] = 3
    x[44] = 7
    y[44] = 2
    x[45] = 8
    y[45] = 4
    x[46] = 6
    y[46] = 5
    x[47] = 4
    y[47] = 4
    x[48] = 2
    y[48] = 3
    x[49] = 1
    y[49] = 1
    x[50] = 3
    y[50] = 2
    x[51] = 5
    y[51] = 1
    x[52] = 7
    y[52] = 2
    x[53] = 8
    y[53] = 4
    x[54] = 6
    y[54] = 3
    x[55] = 4
    y[55] = 2
    x[56] = 2
    y[56] = 1
    x[57] = 1
    y[57] = 3
    x[58] = 3
    y[58] = 4
    x[59] = 5
    y[59] = 5
    x[60] = 7
    y[60] = 6
    x[61] = 8
    y[61] = 8
    x[62] = 6
    y[62] = 7
    x[63] = 4
    y[63] = 6
    x[64] = 2
    y[64] = 5
endif

# Compute mappings for each step with user-defined ranges
# Map 64 segments of equal duration across the entire sound
for k to 64
    # Map x-coordinate (1-8) to stereo position with user-defined range
    rawStereo = (x[k] - 1) / 7
    stereo[k] = stereoMin + rawStereo * (stereoMax - stereoMin)
    
    # Map y-coordinate (1-8) to intensity factor with user-defined range
    rawIntensity = (y[k] - 1) / 7
    intensity[k] = intensityMin + rawIntensity * (intensityMax - intensityMin)
    
    # Map step k to its starting time (64 equal segments)
    time[k] = (k - 1) * duration / 64
    
    # Each segment has equal duration
    segmentDur[k] = duration / 64
endfor

# Get preset name for display
if tourPreset = 1
    presetName$ = "Warnsdorff (Classic)"
elsif tourPreset = 2
    presetName$ = "Spiral Pattern"
elsif tourPreset = 3
    presetName$ = "Diagonal Heavy"
elsif tourPreset = 4
    presetName$ = "Center-Out"
elsif tourPreset = 5
    presetName$ = "Alternating Sides"
endif

# ===== INITIAL SETUP FOR REAL-TIME VISUALIZATION =====
Erase all

# Info
writeInfoLine: "Knight's Tour Sonification - Processing..."
appendInfoLine: "Sound: ", soundName$
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: "Tour preset: ", presetName$
appendInfoLine: "Intensity range: ", fixed$(intensityMin, 2), " - ", fixed$(intensityMax, 2)
appendInfoLine: "Stereo range: ", fixed$(stereoMin, 2), " - ", fixed$(stereoMax, 2)
appendInfoLine: ""

# ===== PROCESS EACH STEP AND BUILD SOUND =====
for k to 64
    # Clear and redraw everything for this step
    Erase all
    
    # === PANEL A: Board Visualization (progressive) ===
    Select inner viewport: 0.5, 7.5, 0.5, 4.0
    Black
    Axes: 0, 9, 0, 9
    Marks left every: 1, 1, "yes", "yes", "no"
    Marks bottom every: 1, 1, "yes", "yes", "no"
    Text left: "yes", "Y coordinate"
    Text bottom: "yes", "X coordinate"
    Text top: "yes", "Knight's Tour ('presetName$') - Step 'k' of 64"
    
    # Draw grid
    Grey
    Line width: 1
    for i to 9
        Draw line: i, 0, i, 9
        Draw line: 0, i, 9, i
    endfor
    
    # Draw completed path segments
    Black
    Line width: 2
    for j from 1 to k-1
        Draw line: x[j], y[j], x[j+1], y[j+1]
    endfor
    
    # Draw completed circles and numbers
    for j to k
        if j = 1
            Red
            Line width: 3
        elsif j = k
            Blue
            Line width: 4
        else
            Black
            Line width: 2
        endif
        
        Draw circle: x[j], y[j], 0.25
        
        # Add step number
        if j = k
            Text: x[j], "centre", y[j], "half", "##'j'##"
        else
            Text: x[j], "centre", y[j], "half", "'j'"
        endif
    endfor
    
    # === PANEL B: Time Mapping Visualization (progressive) ===
    Select inner viewport: 0.5, 7.5, 4.5, 7.5
    
    Axes: 0, duration, -0.1, 1.1
    Black
    Line width: 1
    Marks bottom every: 1, 0.5, "yes", "yes", "no"
    Marks left every: 1, 0.2, "yes", "yes", "no"
    Text bottom: "yes", "Time (s)"
    Text left: "yes", "Value (0–1)"
    Text top: "yes", "Stereo (red) & Intensity (blue) - Processing step 'k'/64"
    
    # Draw reference lines
    Grey
    Line width: 1
    Draw line: 0, 0.5, duration, 0.5
    Draw line: 0, 0, duration, 0
    Draw line: 0, 1, duration, 1
    
    # Draw user-defined range indicators
    Lime
    Line width: 1
    dottedLine = 0.02
    numDots = duration / dottedLine
    for i to numDots
        t = (i - 1) * dottedLine
        Draw line: t, stereoMin, t + dottedLine/2, stereoMin
        Draw line: t, stereoMax, t + dottedLine/2, stereoMax
    endfor
    
    Magenta
    for i to numDots
        t = (i - 1) * dottedLine
        Draw line: t, intensityMin, t + dottedLine/2, intensityMin
        Draw line: t, intensityMax, t + dottedLine/2, intensityMax
    endfor
    
    # Draw stereo position curve (completed segments)
    Red
    Line width: 2
    for j from 1 to k-1
        Draw line: time[j], stereo[j], time[j+1], stereo[j+1]
    endfor
    
    # Draw stereo position points (completed)
    for j to k
        if j = 1
            Paint circle: "red", time[j], stereo[j], 0.015
        elsif j = k
            Paint circle: "red", time[j], stereo[j], 0.02
        else
            Paint circle: "red", time[j], stereo[j], 0.01
        endif
    endfor
    
    # Draw intensity curve (completed segments)
    Blue
    Line width: 2
    for j from 1 to k-1
        Draw line: time[j], intensity[j], time[j+1], intensity[j+1]
    endfor
    
    # Draw intensity points (completed)
    for j to k
        if j = 1
            Paint circle: "blue", time[j], intensity[j], 0.015
        elsif j = k
            Paint circle: "blue", time[j], intensity[j], 0.02
        else
            Paint circle: "blue", time[j], intensity[j], 0.01
        endif
    endfor
    
    # Current time marker
    Black
    Line width: 1
    Draw line: time[k], -0.1, time[k], 1.1
    
    # Add legend
    Black
    Line width: 1
    Text: duration * 0.65, "left", 0.95, "half", "Red = Stereo ['stereoMin:2'–'stereoMax:2']"
    Text: duration * 0.65, "left", 0.85, "half", "Blue = Intensity ['intensityMin:2'–'intensityMax:2']"
    
    # === Process audio for this step ===
    
    # Extract segment from original mono sound
    select monoSound
    startTime = time[k]
    endTime = startTime + segmentDur[k]
    if endTime > duration
        endTime = duration
    endif
    
    Extract part: startTime, endTime, "rectangular", 1, "no"
    segmentMono = selected("Sound")
    
    # Apply intensity scaling
    Formula: "self * intensity[k]"
    
    # Create stereo channels with panning
    # Use constant power panning
    panAngle = stereo[k] * (pi / 2)
    leftGain = cos(panAngle)
    rightGain = sin(panAngle)
    
    # Create left channel (make a copy first!)
    select segmentMono
    Copy: "L" + string$(k)
    leftChannel = selected("Sound")
    Formula: "self * leftGain"
    
    # Create right channel (copy from original segment)
    select segmentMono
    Copy: "R" + string$(k)
    rightChannel = selected("Sound")
    Formula: "self * rightGain"
    
    # Combine to stereo
    select leftChannel
    plus rightChannel
    Combine to stereo
    Rename: "Segment" + string$(k)
    segment = selected("Sound")
    
    # Play if requested
    if playDuringProcessing = 1
        select segment
        Play
    endif
    
    # Concatenate to output
    if k = 1
        # First segment becomes the output
        select segment
        Copy: "KnightsTour_" + soundName$
        outputSound = selected("Sound")
    else
        # Concatenate subsequent segments
        select outputSound
        plus segment
        Concatenate
        Rename: "KnightsTour_" + soundName$
        newOutput = selected("Sound")
        select outputSound
        Remove
        outputSound = newOutput
    endif
    
    # Clean up segment pieces
    select segmentMono
    plus leftChannel
    plus rightChannel
    plus segment
    Remove
    
    # Pause for visualization
    sleep: visualizationDelay
    
    # Update info
    appendInfo: "."
    if k mod 10 = 0
        appendInfoLine: " ", k
    endif
endfor

# ===== FINAL VISUALIZATION (complete) =====
Erase all

# === PANEL A: Board Visualization (complete) ===
Select inner viewport: 0.5, 7.5, 0.5, 4.0
Black
Axes: 0, 9, 0, 9
Marks left every: 1, 1, "yes", "yes", "no"
Marks bottom every: 1, 1, "yes", "yes", "no"
Text left: "yes", "Y coordinate"
Text bottom: "yes", "X coordinate"
Text top: "yes", "Knight's Tour ('presetName$') - COMPLETE"

# Draw grid
Grey
Line width: 1
for i to 9
    Draw line: i, 0, i, 9
    Draw line: 0, i, 9, i
endfor

# Draw complete knight's tour path
Black
Line width: 2
for k from 1 to 63
    Draw line: x[k], y[k], x[k+1], y[k+1]
endfor

# Draw all circles and step numbers
for k to 64
    if k = 1
        Red
        Line width: 3
    elsif k = 64
        Blue
        Line width: 3
    else
        Black
        Line width: 2
    endif
    
    Draw circle: x[k], y[k], 0.25
    Text: x[k], "centre", y[k], "half", "'k'"
endfor

# === PANEL B: Time Mapping Visualization (complete) ===
Select inner viewport: 0.5, 7.5, 4.5, 7.5

Axes: 0, duration, -0.1, 1.1
Black
Line width: 1
Marks bottom every: 1, 0.5, "yes", "yes", "no"
Marks left every: 1, 0.2, "yes", "yes", "no"
Text bottom: "yes", "Time (s)"
Text left: "yes", "Value (0–1)"
Text top: "yes", "Stereo Position (red) and Intensity (blue) - COMPLETE"

# Draw reference lines
Grey
Line width: 1
Draw line: 0, 0.5, duration, 0.5
Draw line: 0, 0, duration, 0
Draw line: 0, 1, duration, 1

# Draw user-defined range indicators
Lime
Line width: 1
dottedLine = 0.02
numDots = duration / dottedLine
for i to numDots
    t = (i - 1) * dottedLine
    Draw line: t, stereoMin, t + dottedLine/2, stereoMin
    Draw line: t, stereoMax, t + dottedLine/2, stereoMax
endfor

Magenta
for i to numDots
    t = (i - 1) * dottedLine
    Draw line: t, intensityMin, t + dottedLine/2, intensityMin
    Draw line: t, intensityMax, t + dottedLine/2, intensityMax
endfor

# Draw complete stereo position curve
Red
Line width: 2
for k from 1 to 63
    Draw line: time[k], stereo[k], time[k+1], stereo[k+1]
endfor

# Draw stereo position points
for k to 64
    if k = 1 or k = 64
        Paint circle: "red", time[k], stereo[k], 0.015
    else
        Paint circle: "red", time[k], stereo[k], 0.01
    endif
endfor

# Draw complete intensity curve
Blue
Line width: 2
for k from 1 to 63
    Draw line: time[k], intensity[k], time[k+1], intensity[k+1]
endfor

# Draw intensity points
for k to 64
    if k = 1 or k = 64
        Paint circle: "blue", time[k], intensity[k], 0.015
    else
        Paint circle: "blue", time[k], intensity[k], 0.01
    endif
endfor

# Add legend
Black
Line width: 1
Text: duration * 0.60, "left", 0.95, "half", "Red = Stereo ['stereoMin:2'–'stereoMax:2'] (range: lime)"
Text: duration * 0.60, "left", 0.85, "half", "Blue = Intensity ['intensityMin:2'–'intensityMax:2'] (range: magenta)"

# Summary information
Select inner viewport: 0.5, 7.5, 7.8, 8.5
Axes: 0, 1, 0, 1
Black
Line width: 1
Text: 0.5, "centre", 0.5, "half", "'presetName$' | 'soundName$' → KnightsTour_'soundName$' | 'duration:2's | I:['intensityMin:2'–'intensityMax:2'] S:['stereoMin:2'–'stereoMax:2']"

# Reset
Line width: 1
Black

# Clean up temporary mono sound if we created one
if nChannels = 2
    select monoSound
    Remove
endif

# Select and play the output sound
select outputSound
Play

# Final info
appendInfoLine: ""
appendInfoLine: "==================================="
appendInfoLine: "COMPLETE!"
appendInfoLine: "==================================="
appendInfoLine: "Original sound: ", soundName$
appendInfoLine: "Output sound: KnightsTour_", soundName$
appendInfoLine: "Tour preset: ", presetName$
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: "Number of steps: 64"
appendInfoLine: "Time per step: ", fixed$(duration/64, 4), " seconds"
appendInfoLine: ""
appendInfoLine: "Intensity range: ", fixed$(intensityMin, 2), " to ", fixed$(intensityMax, 2)
appendInfoLine: "Stereo range: ", fixed$(stereoMin, 2), " to ", fixed$(stereoMax, 2)
appendInfoLine: "  (0.0 = full left, 0.5 = center, 1.0 = full right)"
appendInfoLine: ""
appendInfoLine: "The new sound object has been created and selected."
appendInfoLine: "Original sound remains unmodified."
appendInfoLine: ""
appendInfoLine: "Now playing the processed result..."