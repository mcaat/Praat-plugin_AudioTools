# ============================================================
# Praat AudioTools - CHORD DETECTION
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   CHORD DETECTION
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Choose preset or enter custom shift amounts.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ============================================================================
# CHORD DETECTION - COMPLETE WITH PEAK LIMITING
# ============================================================================

form Chord Detection Parameters
    comment === Time Analysis ===
    positive Window_size_(ms) 100
    positive Time_step_(ms) 50
    positive Skip_initial_transient_(ms) 10
    
    comment === Frequency Analysis ===
    positive Min_frequency_(Hz) 80
    positive Max_frequency_(Hz) 2000
    
    comment === Peak Detection ===
    positive Min_peak_separation_(Hz) 40
    positive Harmonic_tolerance_(cents) 75
    boolean Remove_harmonic_duplicates 1
    positive Max_peaks_to_keep 4
    
    comment === Output ===
    natural Diagnostic_frames_to_analyze 10
    positive Minimum_chord_duration_(ms) 200
    boolean Show_all_detections 0
endform

window_size = window_size / 1000
time_step = time_step / 1000
skip_transient = skip_initial_transient / 1000
min_chord_duration = minimum_chord_duration / 1000

sound = selected("Sound")
sound_name$ = selected$("Sound")
selectObject: sound
duration = Get total duration
sampling_rate = Get sampling frequency

clearinfo
appendInfoLine: "=== CHORD DETECTION ANALYSIS ==="
appendInfoLine: "Sound: ", sound_name$
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: ""

selectObject: sound
textgrid = To TextGrid: "chords notes", ""

analysis_time = skip_transient
frame_number = 0

previous_chord$ = ""
current_chord_start = 0
current_chord$ = ""

while analysis_time < (duration - window_size)
    frame_number += 1
    
    selectObject: sound
    start_time = analysis_time
    end_time = analysis_time + window_size
    
    extract = Extract part: start_time, end_time, "rectangular", 1.0, "no"
    spectrum = To Spectrum: "no"
    
    selectObject: spectrum
    n_bins = Get number of bins
    
    n_peaks = 0
    max_power_db = -999
    
    # Find maximum power
    for i_bin from 1 to n_bins
        freq = Get frequency from bin number: i_bin
        
        if freq >= min_frequency and freq <= max_frequency
            real = Get real value in bin: i_bin
            imag = Get imaginary value in bin: i_bin
            power = sqrt(real^2 + imag^2)
            
            if power > 0
                power_db = 20 * log10(power)
            else
                power_db = -999
            endif
            
            if power_db > max_power_db
                max_power_db = power_db
            endif
        endif
    endfor
    
    relative_threshold_db = 25
    effective_threshold = max_power_db - relative_threshold_db
    
    # Peak detection
    for i_bin from 2 to n_bins - 1
        freq = Get frequency from bin number: i_bin
        
        if freq >= min_frequency and freq <= max_frequency
            real = Get real value in bin: i_bin
            imag = Get imaginary value in bin: i_bin
            power = sqrt(real^2 + imag^2)
            
            power_db = -999
            if power > 0
                power_db = 20 * log10(power)
            endif
            
            if power_db >= effective_threshold
                real_prev = Get real value in bin: i_bin - 1
                imag_prev = Get imaginary value in bin: i_bin - 1
                power_prev = sqrt(real_prev^2 + imag_prev^2)
                
                power_prev_db = -999
                if power_prev > 0
                    power_prev_db = 20 * log10(power_prev)
                endif
                
                real_next = Get real value in bin: i_bin + 1
                imag_next = Get imaginary value in bin: i_bin + 1
                power_next = sqrt(real_next^2 + imag_next^2)
                
                power_next_db = -999
                if power_next > 0
                    power_next_db = 20 * log10(power_next)
                endif
                
                is_peak = 0
                if power_db > power_prev_db
                    if power_db > power_next_db
                        is_peak = 1
                    endif
                endif
                
                if is_peak
                    too_close = 0
                    for i_check from 1 to n_peaks
                        freq_diff = abs(freq - peak_freq_'i_check')
                        if freq_diff < min_peak_separation
                            if power_db > peak_power_'i_check'
                                peak_freq_'i_check' = freq
                                peak_power_'i_check' = power_db
                            endif
                            too_close = 1
                        endif
                    endfor
                    
                    if not too_close
                        n_peaks += 1
                        peak_freq_'n_peaks' = freq
                        peak_power_'n_peaks' = power_db
                    endif
                endif
            endif
        endif
    endfor
    
    # KEEP ONLY THE STRONGEST PEAKS
    if n_peaks > max_peaks_to_keep
        # Sort peaks by power (descending)
        for i from 1 to n_peaks - 1
            for j from 1 to n_peaks - i
                j_plus_1 = j + 1
                power_j = peak_power_'j'
                power_j_plus_1 = peak_power_'j_plus_1'
                
                if power_j < power_j_plus_1
                    temp_freq = peak_freq_'j'
                    peak_freq_'j' = peak_freq_'j_plus_1'
                    peak_freq_'j_plus_1' = temp_freq
                    
                    temp_power = peak_power_'j'
                    peak_power_'j' = peak_power_'j_plus_1'
                    peak_power_'j_plus_1' = temp_power
                endif
            endfor
        endfor
        
        # Keep only top N peaks
        n_peaks = max_peaks_to_keep
    endif
    
    # Convert to notes
    n_notes = 0
    notes_list$ = ""
    
    for i_peak from 1 to n_peaks
        freq = peak_freq_'i_peak'
        power = peak_power_'i_peak'
        
        midi_note = 69 + 12 * (ln(freq/440) / ln(2))
        midi_rounded = round(midi_note)
        pitch_class = midi_rounded mod 12
        
        n_notes += 1
        note_freq_'n_notes' = freq
        note_midi_'n_notes' = midi_rounded
        note_power_'n_notes' = power
        note_pitch_class_'n_notes' = pitch_class
        
        call pitchClassToName: pitch_class
        if i_peak > 1
            notes_list$ = notes_list$ + " "
        endif
        notes_list$ = notes_list$ + pitchClassToName.result$
    endfor
    
    # Harmonic removal
    if remove_harmonic_duplicates
        if n_notes > 1
            for i from 1 to n_notes
                note_keep_'i' = 1
            endfor
            
            for i from 1 to n_notes
                current_freq = note_freq_'i'
                current_power = note_power_'i'
                
                for j from 1 to n_notes
                    if j != i
                        if note_power_'j' > current_power
                            fundamental_freq = note_freq_'j'
                            
                            for harmonic from 2 to 6
                                expected_harmonic = fundamental_freq * harmonic
                                freq_ratio = current_freq / expected_harmonic
                                cents_diff = 1200 * abs(ln(freq_ratio) / ln(2))
                                
                                if cents_diff < harmonic_tolerance
                                    note_keep_'i' = 0
                                endif
                            endfor
                        endif
                    endif
                endfor
            endfor
            
            n_notes_filtered = 0
            for i from 1 to n_notes
                if note_keep_'i' = 1
                    n_notes_filtered += 1
                    note_pitch_class_filtered_'n_notes_filtered' = note_pitch_class_'i'
                endif
            endfor
            
            n_notes = n_notes_filtered
            for i from 1 to n_notes
                note_pitch_class_'i' = note_pitch_class_filtered_'i'
            endfor
        endif
    endif
    
    # Build chord name
    chord_name$ = ""
    
    if n_notes >= 2
        call createPitchClassSet: n_notes
        pc_set_size = pitchClassSet.n
        call matchChord: pc_set_size
        chord_name$ = matchChord.result$
    elsif n_notes = 1
        call pitchClassToName: note_pitch_class_1
        chord_name$ = pitchClassToName.result$
    else
        chord_name$ = "Silence"
    endif
    
    if show_all_detections
        if chord_name$ <> "Silence"
            appendInfoLine: fixed$(analysis_time, 3), "s: ", chord_name$
        endif
    endif
    
    # CHORD CHANGE DETECTION
    if chord_name$ <> previous_chord$
        if previous_chord$ <> ""
            chord_duration = analysis_time - current_chord_start
            if chord_duration >= min_chord_duration
                selectObject: textgrid
                
                if analysis_time < (duration - 0.001)
                    Insert boundary: 1, analysis_time
                endif
                
                interval_num = Get interval at time: 1, current_chord_start + 0.001
                Set interval text: 1, interval_num, current_chord$
                
                if not show_all_detections
                    appendInfoLine: "SEGMENT: ", fixed$(current_chord_start, 3), " - ", fixed$(analysis_time, 3), " s: ", current_chord$
                endif
            endif
        endif
        
        current_chord$ = chord_name$
        current_chord_start = analysis_time
        previous_chord$ = chord_name$
    endif
    
    # Add notes to tier 2
    selectObject: textgrid
    next_boundary_time = analysis_time + time_step
    if next_boundary_time < (duration - 0.001)
        Insert boundary: 2, next_boundary_time
    endif
    interval_num = Get interval at time: 2, analysis_time + (time_step / 2)
    if notes_list$ <> ""
        Set interval text: 2, interval_num, notes_list$
    endif
    
    selectObject: extract, spectrum
    Remove
    
    analysis_time += time_step
endwhile

# Close final chord
if current_chord$ <> ""
    selectObject: textgrid
    n_intervals = Get number of intervals: 1
    Set interval text: 1, n_intervals, current_chord$
    if not show_all_detections
        appendInfoLine: "SEGMENT: ", fixed$(current_chord_start, 3), " - ", fixed$(duration, 3), " s: ", current_chord$
    endif
endif

appendInfoLine: ""
appendInfoLine: "=== ANALYSIS COMPLETE ==="
appendInfoLine: "Analyzed ", frame_number, " frames"

selectObject: textgrid
n_chord_intervals = Get number of intervals: 1
appendInfoLine: "Detected ", n_chord_intervals, " chord segments"

selectObject: textgrid
plus sound
View & Edit

selectObject: sound

# ============================================================================
# PROCEDURES
# ============================================================================

procedure pitchClassToName: .pitch_class
    if .pitch_class = 0
        .result$ = "C"
    elsif .pitch_class = 1
        .result$ = "C#"
    elsif .pitch_class = 2
        .result$ = "D"
    elsif .pitch_class = 3
        .result$ = "D#"
    elsif .pitch_class = 4
        .result$ = "E"
    elsif .pitch_class = 5
        .result$ = "F"
    elsif .pitch_class = 6
        .result$ = "F#"
    elsif .pitch_class = 7
        .result$ = "G"
    elsif .pitch_class = 8
        .result$ = "G#"
    elsif .pitch_class = 9
        .result$ = "A"
    elsif .pitch_class = 10
        .result$ = "A#"
    elsif .pitch_class = 11
        .result$ = "B"
    endif
endproc

procedure createPitchClassSet: .n_notes
    .n = 0
    for .i from 1 to .n_notes
        .pc = note_pitch_class_'.i'
        .already_exists = 0
        for .j from 1 to .n
            .existing_pc = pitchClassSet.class_'.j'
            if .pc = .existing_pc
                .already_exists = 1
            endif
        endfor
        if not .already_exists
            .n += 1
            pitchClassSet.class_'.n' = .pc
        endif
    endfor
    
    # Sort the pitch class set
    for .i from 1 to .n - 1
        for .j from 1 to .n - .i
            .j_plus_1 = .j + 1
            .val_j = pitchClassSet.class_'.j'
            .val_j_plus_1 = pitchClassSet.class_'.j_plus_1'
            
            if .val_j > .val_j_plus_1
                temp_val = .val_j
                pitchClassSet.class_'.j' = .val_j_plus_1
                pitchClassSet.class_'.j_plus_1' = temp_val
            endif
        endfor
    endfor
    
    pitchClassSet.n = .n
    pitchClassSet.root = pitchClassSet.class_1
endproc

procedure matchChord: .n_classes
    .result$ = "Unknown"
    
    # Try all possible roots (transpositions)
    for .try_root from 0 to 11
        
        # Calculate intervals from this root
        for .i from 1 to .n_classes
            .pc_val = pitchClassSet.class_'.i'
            .interval_'.i' = (.pc_val - .try_root + 12) mod 12
        endfor
        
        # SORT the intervals
        for .i from 1 to .n_classes - 1
            for .j from 1 to .n_classes - .i
                .j_plus_1 = .j + 1
                .val_j = .interval_'.j'
                .val_j_plus_1 = .interval_'.j_plus_1'
                
                if .val_j > .val_j_plus_1
                    temp_interval = .val_j
                    .interval_'.j' = .val_j_plus_1
                    .interval_'.j_plus_1' = temp_interval
                endif
            endfor
        endfor
        
        # Build pattern string
        .pattern$ = ""
        for .i from 1 to .n_classes
            if .i > 1
                .pattern$ = .pattern$ + ","
            endif
            .pattern$ = .pattern$ + string$(.interval_'.i')
        endfor
        
        # COMPREHENSIVE CHORD DICTIONARY
        # 2-note chords (dyads & power chords)
        if .pattern$ = "0,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + "5"
        elsif .pattern$ = "0,5"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + "4"
        elsif .pattern$ = "0,3"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " min3"
        elsif .pattern$ = "0,4"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " maj3"
        
        # 3-note triads
        elsif .pattern$ = "0,4,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Major"
        elsif .pattern$ = "0,3,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor"
        elsif .pattern$ = "0,3,6"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Diminished"
        elsif .pattern$ = "0,4,8"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Augmented"
        elsif .pattern$ = "0,5,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Sus4"
        elsif .pattern$ = "0,2,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Sus2"
        
        # 4-note 7th chords
        elsif .pattern$ = "0,4,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Dominant 7th"
        elsif .pattern$ = "0,4,7,11"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Major 7th"
        elsif .pattern$ = "0,3,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor 7th"
        elsif .pattern$ = "0,3,6,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Half-Diminished 7th"
        elsif .pattern$ = "0,3,6,9"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Diminished 7th"
        elsif .pattern$ = "0,4,8,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Augmented 7th"
        elsif .pattern$ = "0,3,7,11"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor-Major 7th"
        
        # 9th chords (5 notes)
        elsif .pattern$ = "0,2,4,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " 9th"
        elsif .pattern$ = "0,2,4,7,11"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Major 9th"
        elsif .pattern$ = "0,2,3,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor 9th"
        
        # 6th chords
        elsif .pattern$ = "0,4,7,9"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Major 6th"
        elsif .pattern$ = "0,3,7,9"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor 6th"
        
        # Sus7 variations
        elsif .pattern$ = "0,5,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " 7sus4"
        elsif .pattern$ = "0,2,7,10"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " 7sus2"
        
        # Add9/Add11
        elsif .pattern$ = "0,2,4,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Add9"
        elsif .pattern$ = "0,2,3,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Minor Add9"
        elsif .pattern$ = "0,4,5,7"
            call pitchClassToName: .try_root
            .result$ = pitchClassToName.result$ + " Add11"
        
        endif
        
        # If we found a match, stop searching
        if .result$ <> "Unknown"
            .i = .n_classes
            .try_root = 12
        endif
    endfor
    
    # If no match found, just list the notes
    if .result$ = "Unknown"
        .result$ = ""
        for .i from 1 to .n_classes
            .pc_val = pitchClassSet.class_'.i'
            call pitchClassToName: .pc_val
            if .i > 1
                .result$ = .result$ + "+"
            endif
            .result$ = .result$ + pitchClassToName.result$
        endfor
    endif
endproc