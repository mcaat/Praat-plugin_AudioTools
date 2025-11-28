# ============================================================
# Praat AudioTools - Rhythmic LFO Wah-Wah.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Rhythmic LFO Wah-Wah script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Rhythmic LFO Wah-Wah (Time-Sync) 
# Select a Sound object and run.

form Rhythmic LFO Wah
    comment --- BPM Calculation ---
    comment How many beats is the current selection? (Set 0 to use manual BPM)
    positive Beats_in_selection 4
    comment If above is 0, use this BPM:
    positive Manual_BPM 120
    
    comment --- Rhythm Settings ---
    optionmenu Note_value: 3
        option 1/1 (Whole Note)
        option 1/2 (Half Note)
        option 1/4 (Quarter Note)
        option 1/8 (Eighth Note)
        option 1/16 (Sixteenth Note)
        option 1/32 (Thirty-second Note)
    optionmenu Feel: 1
        option Straight
        option Dotted (1.5x slower)
        option Triplet (33% faster)
        
    comment --- Wah Tone ---
    positive min_cutoff_Hz 400
    positive max_cutoff_Hz 2500
    positive bandwidth_Hz 150
endform

# 1. Calculate BPM
id_sound = selected("Sound")
dur = Get total duration
name$ = selected$("Sound")

if beats_in_selection > 0
    # Calculate BPM based on the selection duration
    bpm = (beats_in_selection / dur) * 60
    appendInfoLine: "Detected Duration: ", fixed$(dur, 2), "s. Calculated BPM: ", fixed$(bpm, 1)
else
    bpm = manual_BPM
    appendInfoLine: "Using Manual BPM: ", bpm
endif

# 2. Calculate LFO Speed (Hz)
if note_value = 1
    beat_fraction = 4
elsif note_value = 2
    beat_fraction = 2
elsif note_value = 3
    beat_fraction = 1
elsif note_value = 4
    beat_fraction = 0.5
elsif note_value = 5
    beat_fraction = 0.25
elsif note_value = 6
    beat_fraction = 0.125
endif

# Apply Modifier (Straight, Dotted, Triplet)
if feel = 2
    # Dotted
    beat_fraction = beat_fraction * 1.5
elsif feel = 3
    # Triplet
    beat_fraction = beat_fraction * (2/3)
endif

# Duration of one cycle in seconds
cycle_dur = (60 / bpm) * beat_fraction
lfo_freq = 1 / cycle_dur

appendInfoLine: "LFO Rate: ", fixed$(lfo_freq, 2), " Hz (", note_value$, " ", feel$, ")"

# 3. Create the FormantGrid
id_grid = Create FormantGrid: name$ + "_lfo", 0, dur, 1, 550, 600, 50, 50

# 4. Generate the Sine Wave Curve
# 0.005 seconds = 5ms updates
time_step = 0.005
n_steps = floor(dur / time_step)

for i to n_steps
    t = i * time_step
    
    # LFO Math: Using 3.14 literal as requested
    # Formula: 0.5 * (1 + sin(2 * 3.14 * freq * t))
    
    oscillator = sin(2 * 3.14 * lfo_freq * t)
    
    # Norm 0 to 1
    norm_val = (1 + oscillator) / 2
    
    # Map to Frequency Range
    target_freq = min_cutoff_Hz + ((max_cutoff_Hz - min_cutoff_Hz) * norm_val)
    
    # Apply to Grid
    Add formant point: 1, t, target_freq
    Add bandwidth point: 1, t, bandwidth_Hz
endfor

# 5. Apply Filter
selectObject: id_sound
plusObject: id_grid
id_wah = Filter

# 6. Cleanup
selectObject: id_grid
Remove
selectObject: id_wah
Rename: name$ + "_LFO_" + string$(bpm) + "bpm"
Play

# Output
appendInfoLine: "Done."