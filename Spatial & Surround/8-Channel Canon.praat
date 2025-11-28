# ============================================================
# Praat AudioTools - 8-Channel Canon.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Multichannel or spatialisation script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================
# Praat AudioTools - 8-Channel Canon.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Creates 8-voice pitch canons via sampling rate override.
#   Includes presets for Audio Figure B comparative studies.
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift rates.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form 8-Channel Canon
    comment === PRESET SELECTION ===
    choice preset_choice 1
        option Custom (manual entry)
        option V1: Default cluster spacing (1-3 semitones)
        option V2: Wide interval spread (4-10 semitones)
        option V3: Microtonal cluster (quarter-tones)
        option V4: Symmetrical canon (mirror intervals)
        option V5: Octave doublings (harmonic reinforcement)
    
    comment === SAMPLING RATE ===
    positive resample_frequency 44100
    
    comment === SHIFT RATES (Hz) - ignored if using preset ===
    positive shift_rate_1 44100
    positive shift_rate_2 46698
    positive shift_rate_3 49466
    positive shift_rate_4 52406
    positive shift_rate_5 44100
    positive shift_rate_6 41606
    positive shift_rate_7 39289
    positive shift_rate_8 37084
    
    comment === OPTIONS ===
    boolean keep_intermediate_files 0
    boolean play_result 1
endform

# Apply preset values if selected
if preset_choice = 2
    # V1: Default cluster spacing
    shift_rate_1 = 44100
    shift_rate_2 = 46698
    shift_rate_3 = 49466
    shift_rate_4 = 52406
    shift_rate_5 = 44100
    shift_rate_6 = 41606
    shift_rate_7 = 39289
    shift_rate_8 = 37084
    preset_name$ = "V1_default_cluster"
elsif preset_choice = 3
    # V2: Wide interval spread
    shift_rate_1 = 44100
    shift_rate_2 = 55440
    shift_rate_3 = 62231
    shift_rate_4 = 69926
    shift_rate_5 = 44100
    shift_rate_6 = 35025
    shift_rate_7 = 31217
    shift_rate_8 = 27781
    preset_name$ = "V2_wide_interval"
elsif preset_choice = 4
    # V3: Microtonal cluster
    shift_rate_1 = 44100
    shift_rate_2 = 45426
    shift_rate_3 = 46787
    shift_rate_4 = 48185
    shift_rate_5 = 49621
    shift_rate_6 = 42828
    shift_rate_7 = 41606
    shift_rate_8 = 40432
    preset_name$ = "V3_microtonal"
elsif preset_choice = 5
    # V4: Symmetrical canon
    shift_rate_1 = 52406
    shift_rate_2 = 49466
    shift_rate_3 = 46698
    shift_rate_4 = 44100
    shift_rate_5 = 44100
    shift_rate_6 = 41606
    shift_rate_7 = 39289
    shift_rate_8 = 37084
    preset_name$ = "V4_symmetrical"
elsif preset_choice = 6
    # V5: Octave doublings
    shift_rate_1 = 44100
    shift_rate_2 = 88200
    shift_rate_3 = 22050
    shift_rate_4 = 44100
    shift_rate_5 = 88200
    shift_rate_6 = 22050
    shift_rate_7 = 176400
    shift_rate_8 = 11025
    preset_name$ = "V5_octave_doublings"
else
    # Custom - use manual values
    preset_name$ = "custom"
endif

# Must have a Sound selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object first."
endif

# Get original name and create base mono
orig$ = selected$("Sound")
select Sound 'orig$'
Copy... base_original
Convert to mono
Resample... resample_frequency 50

# Create all necessary copies of the base sound first
select Sound base_original
Copy... base1
Copy... base2
Copy... base3
Copy... base4
Copy... base5
Copy... base6
Copy... base7
Copy... base8

# Create shifted version 1
select Sound base1
Override sampling frequency... shift_rate_1
Resample... resample_frequency 50
Rename... shift1

# Create shifted version 2  
select Sound base2
Override sampling frequency... shift_rate_2
Resample... resample_frequency 50
Rename... shift2

# Create shifted version 3
select Sound base3
Override sampling frequency... shift_rate_3
Resample... resample_frequency 50
Rename... shift3

# Create shifted version 4
select Sound base4
Override sampling frequency... shift_rate_4
Resample... resample_frequency 50
Rename... shift4

# Create shifted version 5
select Sound base5
Override sampling frequency... shift_rate_5
Resample... resample_frequency 50
Rename... shift5

# Create shifted version 6
select Sound base6
Override sampling frequency... shift_rate_6
Resample... resample_frequency 50
Rename... shift6

# Create shifted version 7
select Sound base7
Override sampling frequency... shift_rate_7
Resample... resample_frequency 50
Rename... shift7

# Create shifted version 8
select Sound base8
Override sampling frequency... shift_rate_8
Resample... resample_frequency 50
Rename... shift8

# Create 4 stereo pairs
select Sound shift1
plus Sound shift2
Combine to stereo
Rename... pair_1_2

select Sound shift3
plus Sound shift4
Combine to stereo
Rename... pair_3_4

select Sound shift5
plus Sound shift6
Combine to stereo
Rename... pair_5_6

select Sound shift7
plus Sound shift8
Combine to stereo
Rename... pair_7_8

# Combine pairs into larger groups
select Sound pair_1_2
plus Sound pair_3_4
Combine to stereo
Rename... channels_1234_mixed

select Sound pair_5_6
plus Sound pair_7_8
Combine to stereo
Rename... channels_5678_mixed

# Final combination
select Sound channels_1234_mixed
plus Sound channels_5678_mixed
Combine to stereo
Rename... canon_8ch_final_mix

# Rename with preset name
select Sound canon_8ch_final_mix
if preset_choice > 1
    Rename... 'orig$'_canon_'preset_name$'
else
    Rename... 'orig$'_canon_custom
endif

final_name$ = selected$("Sound")

# Print processing info
appendInfoLine: "=== 8-Channel Canon Complete ==="
appendInfoLine: "Source: '", orig$, "'"
if preset_choice > 1
    appendInfoLine: "Preset: ", preset_name$
else
    appendInfoLine: "Mode: Custom shift rates"
endif
appendInfoLine: "Shift rates (Hz): ", shift_rate_1, ", ", shift_rate_2, ", ", shift_rate_3, ", ", shift_rate_4, ", ", shift_rate_5, ", ", shift_rate_6, ", ", shift_rate_7, ", ", shift_rate_8
appendInfoLine: "Result: '", final_name$, "'"

# Play if requested
if play_result
    select Sound 'final_name$'
    Play
endif

# Clean up if not keeping intermediate files
if not keep_intermediate_files
    select Sound base_original
    plus Sound base_original_mono
    plus Sound base_original_mono_44100
    plus Sound base1
    plus Sound base2
    plus Sound base3
    plus Sound base4
    plus Sound base5
    plus Sound base6
    plus Sound base7
    plus Sound base8
    plus Sound shift1
    plus Sound shift2
    plus Sound shift3
    plus Sound shift4
    plus Sound shift5
    plus Sound shift6
    plus Sound shift7
    plus Sound shift8
    plus Sound pair_1_2
    plus Sound pair_3_4
    plus Sound pair_5_6
    plus Sound pair_7_8
    plus Sound channels_1234_mixed
    plus Sound channels_5678_mixed
    Remove
endif

# Select final result
select Sound 'final_name$'