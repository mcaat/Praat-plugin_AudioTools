# ============================================================
# Praat AudioTools - 8-Channel Spectral Shift.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Creates 8-voice frequency shift canons via FFT frequency bin shifting.
#   Includes presets for Audio Figure B comparative studies.
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
clearinfo
form 8-Channel Frequency Shift Canon
    comment === PRESET SELECTION ===
    choice preset_choice 1
        option Custom (manual entry)
        option V1: Gentle shifts (100-300 Hz)
        option V2: Moderate shifts (400-800 Hz)
        option V3: Extreme shifts (1000-2000 Hz)
        option V4: Symmetrical shifts (mirror pattern)
        option V5: Microtonal shifts (50-150 Hz)
    
    comment === FREQUENCY SHIFT AMOUNTS (Hz) - POSITIVE ONLY ===
    positive shift_amount_1 100
    positive shift_amount_2 200
    positive shift_amount_3 300
    positive shift_amount_4 400
    positive shift_amount_5 500
    positive shift_amount_6 600
    positive shift_amount_7 700
    positive shift_amount_8 800
    
    comment === OUTPUT OPTIONS ===
    positive scale_peak 0.99
    boolean keep_intermediate_files 0
    boolean play_result 1
endform

# Apply preset values if selected
if preset_choice = 2
    # V1: Gentle shifts
    shift_amount_1 = 100
    shift_amount_2 = 150
    shift_amount_3 = 200
    shift_amount_4 = 250
    shift_amount_5 = 300
    shift_amount_6 = 250
    shift_amount_7 = 200
    shift_amount_8 = 150
    preset_name$ = "V1_gentle_shifts"
elsif preset_choice = 3
    # V2: Moderate shifts
    shift_amount_1 = 400
    shift_amount_2 = 500
    shift_amount_3 = 600
    shift_amount_4 = 700
    shift_amount_5 = 800
    shift_amount_6 = 700
    shift_amount_7 = 600
    shift_amount_8 = 500
    preset_name$ = "V2_moderate_shifts"
elsif preset_choice = 4
    # V3: Extreme shifts
    shift_amount_1 = 1000
    shift_amount_2 = 1200
    shift_amount_3 = 1400
    shift_amount_4 = 1600
    shift_amount_5 = 1800
    shift_amount_6 = 2000
    shift_amount_7 = 1800
    shift_amount_8 = 1600
    preset_name$ = "V3_extreme_shifts"
elsif preset_choice = 5
    # V4: Symmetrical shifts
    shift_amount_1 = 800
    shift_amount_2 = 600
    shift_amount_3 = 400
    shift_amount_4 = 200
    shift_amount_5 = 200
    shift_amount_6 = 400
    shift_amount_7 = 600
    shift_amount_8 = 800
    preset_name$ = "V4_symmetrical"
elsif preset_choice = 6
    # V5: Microtonal shifts
    shift_amount_1 = 50
    shift_amount_2 = 75
    shift_amount_3 = 100
    shift_amount_4 = 125
    shift_amount_5 = 150
    shift_amount_6 = 125
    shift_amount_7 = 100
    shift_amount_8 = 75
    preset_name$ = "V5_microtonal"
else
    # Custom - use manual values
    preset_name$ = "custom"
endif

# Must have a Sound selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Get original name
originalSound = selected("Sound")
originalName$ = selected$("Sound")

# Create base copies for processing
select originalSound
Copy: "base_original"
base_original_mono = Convert to mono

# Create 8 base copies
for i from 1 to 8
    select base_original_mono
    Copy: "base_'i'"
endfor

# Apply frequency shifts to each channel
select Sound base_1
spectrum1 = To Spectrum: "yes"
Formula: "if col + shift_amount_1 <= ncol then self[col + shift_amount_1] else 0 fi"
shift1 = To Sound
select spectrum1
Remove
select shift1
Scale peak: scale_peak
Rename: "'originalName$'_shifted_1"

select Sound base_2
spectrum2 = To Spectrum: "yes"
Formula: "if col + shift_amount_2 <= ncol then self[col + shift_amount_2] else 0 fi"
shift2 = To Sound
select spectrum2
Remove
select shift2
Scale peak: scale_peak
Rename: "'originalName$'_shifted_2"

select Sound base_3
spectrum3 = To Spectrum: "yes"
Formula: "if col + shift_amount_3 <= ncol then self[col + shift_amount_3] else 0 fi"
shift3 = To Sound
select spectrum3
Remove
select shift3
Scale peak: scale_peak
Rename: "'originalName$'_shifted_3"

select Sound base_4
spectrum4 = To Spectrum: "yes"
Formula: "if col + shift_amount_4 <= ncol then self[col + shift_amount_4] else 0 fi"
shift4 = To Sound
select spectrum4
Remove
select shift4
Scale peak: scale_peak
Rename: "'originalName$'_shifted_4"

select Sound base_5
spectrum5 = To Spectrum: "yes"
Formula: "if col + shift_amount_5 <= ncol then self[col + shift_amount_5] else 0 fi"
shift5 = To Sound
select spectrum5
Remove
select shift5
Scale peak: scale_peak
Rename: "'originalName$'_shifted_5"

select Sound base_6
spectrum6 = To Spectrum: "yes"
Formula: "if col + shift_amount_6 <= ncol then self[col + shift_amount_6] else 0 fi"
shift6 = To Sound
select spectrum6
Remove
select shift6
Scale peak: scale_peak
Rename: "'originalName$'_shifted_6"

select Sound base_7
spectrum7 = To Spectrum: "yes"
Formula: "if col + shift_amount_7 <= ncol then self[col + shift_amount_7] else 0 fi"
shift7 = To Sound
select spectrum7
Remove
select shift7
Scale peak: scale_peak
Rename: "'originalName$'_shifted_7"

select Sound base_8
spectrum8 = To Spectrum: "yes"
Formula: "if col + shift_amount_8 <= ncol then self[col + shift_amount_8] else 0 fi"
shift8 = To Sound
select spectrum8
Remove
select shift8
Scale peak: scale_peak
Rename: "'originalName$'_shifted_8"

# Create 4 stereo pairs
select shift1
plus shift2
Combine to stereo
Rename: "pair_1_2"

select shift3
plus shift4
Combine to stereo
Rename: "pair_3_4"

select shift5
plus shift6
Combine to stereo
Rename: "pair_5_6"

select shift7
plus shift8
Combine to stereo
Rename: "pair_7_8"

# Combine pairs into larger groups
select Sound pair_1_2
plus Sound pair_3_4
Combine to stereo
Rename: "channels_1234_mixed"

select Sound pair_5_6
plus Sound pair_7_8
Combine to stereo
Rename: "channels_5678_mixed"

# Final combination
select Sound channels_1234_mixed
plus Sound channels_5678_mixed
Combine to stereo
Rename: "canon_8ch_freq_shift_final"

# Rename with preset name
select Sound canon_8ch_freq_shift_final
if preset_choice > 1
    Rename: "'originalName$'_freq_canon_'preset_name$'"
else
    Rename: "'originalName$'_freq_canon_custom"
endif

final_name$ = selected$("Sound")

# Print processing info
appendInfoLine: "=== 8-Channel Frequency Shift Canon Complete ==="
appendInfoLine: "Source: '", originalName$, "'"
if preset_choice > 1
    appendInfoLine: "Preset: ", preset_name$
else
    appendInfoLine: "Mode: Custom frequency shifts"
endif
appendInfoLine: "Shift amounts (Hz): ", shift_amount_1, ", ", shift_amount_2, ", ", shift_amount_3, ", ", shift_amount_4, ", ", shift_amount_5, ", ", shift_amount_6, ", ", shift_amount_7, ", ", shift_amount_8
appendInfoLine: "Result: '", final_name$, "'"

# Play if requested
if play_result
    select Sound 'final_name$'
    Play
endif

# Clean up if not keeping intermediate files
if not keep_intermediate_files
    select Sound base_original
    plus base_original_mono
    plus Sound base_1
    plus Sound base_2
    plus Sound base_3
    plus Sound base_4
    plus Sound base_5
    plus Sound base_6
    plus Sound base_7
    plus Sound base_8
    plus shift1
    plus shift2
    plus shift3
    plus shift4
    plus shift5
    plus shift6
    plus shift7
    plus shift8
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