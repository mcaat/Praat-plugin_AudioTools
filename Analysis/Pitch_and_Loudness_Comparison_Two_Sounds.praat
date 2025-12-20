# ============================================================
# compare_pitch_and_loudness_FIXED_STDDEV_ARGS.praat
# Merged from:
#   - compare loudness.praat
#   - compare pitch.praat
#
# Usage:
#   Select EXACTLY TWO Sound objects (Teacher=Sound1, Student=Sound2), then run.
# ============================================================

clearinfo

form Compare teacher vs student (Pitch and/or Loudness)
    choice analysis_type 1
        option Loudness_only
        option Pitch_only
        option Both_pitch_and_loudness
    real time_step 0.01
    real pitch_floor_hz 75
    real pitch_ceiling_hz 600
endform

nSounds = numberOfSelected ("Sound")
if nSounds <> 2
    writeInfoLine: "ERROR: Please select EXACTLY TWO Sound objects."
    writeInfoLine: "       (Teacher = first selected, Student = second selected)"
    exit
endif

sound1 = selected("Sound", 1)
sound2 = selected("Sound", 2)

selectObject: sound1
name1$ = selected$("Sound")
duration1 = Get total duration

selectObject: sound2
name2$ = selected$("Sound")
duration2 = Get total duration

appendInfoLine: "=========================================="
appendInfoLine: "COMPARE RESULTS (Teacher vs Student)"
appendInfoLine: "=========================================="
appendInfoLine: "Teacher (Sound 1): ", name1$, " (", fixed$(duration1, 3), " s)"
appendInfoLine: "Student (Sound 2): ", name2$, " (", fixed$(duration2, 3), " s)"
appendInfoLine: ""

# ============================================================
# A) LOUDNESS COMPARISON
# ============================================================
if analysis_type = 1 or analysis_type = 3
    appendInfoLine: "=== LOUDNESS COMPARISON ==="

    selectObject: sound1
    To Intensity: 75, time_step, "yes"
    intensity1 = selected()

    selectObject: sound2
    To Intensity: 75, time_step, "yes"
    intensity2 = selected()

    selectObject: intensity1
    frames1 = Get number of frames
    mean_db1 = Get mean: 0, 0, "energy"
    std_db1 = Get standard deviation: 0, 0
    min_db1 = Get minimum: 0, 0, "Parabolic"
    max_db1 = Get maximum: 0, 0, "Parabolic"

    selectObject: intensity2
    frames2 = Get number of frames
    mean_db2 = Get mean: 0, 0, "energy"
    std_db2 = Get standard deviation: 0, 0
    min_db2 = Get minimum: 0, 0, "Parabolic"
    max_db2 = Get maximum: 0, 0, "Parabolic"

    min_frames = min(frames1, frames2)

    total_db_distance = 0
    squared_differences = 0
    max_db_diff = 0
    min_db_diff = 1e9

    for frame from 1 to min_frames
        selectObject: intensity1
        db1 = Get value in frame: frame
        selectObject: intensity2
        db2 = Get value in frame: frame

        if db1 <> undefined and db2 <> undefined
            db_diff = abs(db1 - db2)
            total_db_distance += db_diff
            squared_differences += db_diff * db_diff

            if db_diff > max_db_diff
                max_db_diff = db_diff
            endif
            if db_diff < min_db_diff
                min_db_diff = db_diff
            endif
        endif
    endfor

    average_db_distance = total_db_distance / min_frames
    rms_db_distance = sqrt(squared_differences / min_frames)

    dynamic_range1 = max_db1 - min_db1
    dynamic_range2 = max_db2 - min_db2
    dynamic_range_diff = abs(dynamic_range1 - dynamic_range2)

    consistency_diff = abs(std_db1 - std_db2)

    appendInfoLine: ""
    appendInfoLine: "Frames compared: ", min_frames
    appendInfoLine: "Average dB difference: ", fixed$(average_db_distance, 3), " dB"
    appendInfoLine: "RMS dB difference: ", fixed$(rms_db_distance, 3), " dB"
    appendInfoLine: "Max dB difference: ", fixed$(max_db_diff, 3), " dB"
    appendInfoLine: "Min dB difference: ", fixed$(min_db_diff, 3), " dB"
    appendInfoLine: "Dynamic range difference: ", fixed$(dynamic_range_diff, 3), " dB"
    appendInfoLine: "Consistency difference (std): ", fixed$(consistency_diff, 3), " dB"
    appendInfoLine: ""

    # Cleanup
    selectObject: intensity1
    plusObject: intensity2
    Remove

    selectObject: sound1
    plusObject: sound2
endif

# ============================================================
# B) PITCH COMPARISON
# ============================================================
if analysis_type = 2 or analysis_type = 3
    appendInfoLine: ""
    appendInfoLine: "=== PITCH COMPARISON ==="

    selectObject: sound1
    To Pitch: time_step, pitch_floor_hz, pitch_ceiling_hz
    pitch1 = selected()

    selectObject: sound2
    To Pitch: time_step, pitch_floor_hz, pitch_ceiling_hz
    pitch2 = selected()

    selectObject: pitch1
    frames1 = Get number of frames
    mean_f0_1 = Get mean: 0, 0, "Hertz"
    std_f0_1 = Get standard deviation: 0, 0, "Hertz"
    min_f0_1 = Get minimum: 0, 0, "Hertz", "Parabolic"
    max_f0_1 = Get maximum: 0, 0, "Hertz", "Parabolic"

    selectObject: pitch2
    frames2 = Get number of frames
    mean_f0_2 = Get mean: 0, 0, "Hertz"
    std_f0_2 = Get standard deviation: 0, 0, "Hertz"
    min_f0_2 = Get minimum: 0, 0, "Hertz", "Parabolic"
    max_f0_2 = Get maximum: 0, 0, "Hertz", "Parabolic"

    min_frames = min(frames1, frames2)

    total_semitone_distance = 0
    voiced_frames = 0
    max_semitone_diff = 0

    for frame from 1 to min_frames
        selectObject: pitch1
        f1 = Get value in frame: frame, "Hertz"
        selectObject: pitch2
        f2 = Get value in frame: frame, "Hertz"

        if f1 > 0 and f2 > 0
            voiced_frames += 1
            semitone_diff = abs(12 * (ln(f2 / f1) / ln(2)))
            total_semitone_distance += semitone_diff
            if semitone_diff > max_semitone_diff
                max_semitone_diff = semitone_diff
            endif
        endif
    endfor

    if voiced_frames > 0
        average_semitone_distance = total_semitone_distance / voiced_frames
    else
        average_semitone_distance = 0
    endif

    appendInfoLine: "Voiced frames analyzed: ", voiced_frames, " out of ", min_frames
    appendInfoLine: "Average semitone difference: ", fixed$(average_semitone_distance, 3)
    appendInfoLine: "Max semitone difference: ", fixed$(max_semitone_diff, 3)

    # Cleanup
    selectObject: pitch1
    plusObject: pitch2
    Remove

    selectObject: sound1
    plusObject: sound2
endif

appendInfoLine: ""
appendInfoLine: "Done."
