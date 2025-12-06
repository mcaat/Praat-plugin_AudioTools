# ============================================================
# Praat AudioTools - Formant to MusicXML Chord Converter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Formant to MusicXML Chord Converter
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================


# Formant to MusicXML Chord Converter
# This script segments selected audio, extracts 4 formants from each segment,
# converts them to MIDI notes, and outputs MusicXML for MuseScore

# Check if a Sound object is selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

# Get the selected Sound
sound = selected("Sound")
soundName$ = selected$("Sound")

# Parameters
form Formant Analysis Parameters
    positive Number_of_segments 8
    positive Time_step 0.01
    positive Max_formant_Hz 5500
    positive Number_of_formants 5
    positive Window_length 0.025
    integer Transpose_semitones -24
    positive Tone_division 8
endform

# Clear info window
clearinfo

# Get sound duration
selectObject: sound
duration = Get total duration
segmentDuration = duration / number_of_segments

# Create Formant object
selectObject: sound
formant = To Formant (burg): time_step, number_of_formants, max_formant_Hz, window_length, 50

# Function to convert frequency (Hz) to MIDI note number and microtonal alter
procedure freqToMidi: .freq
    if .freq > 0
        .midiFloat = 69 + 12 * ln(.freq/440) / ln(2) + transpose_semitones
        .midiNote = floor(.midiFloat)
        # Calculate fractional part in semitones
        fractionalSemitones = .midiFloat - .midiNote
        # Round to nearest tone division step
        divisionSteps = round(fractionalSemitones * tone_division)
        # Convert back to fractional semitones for alter value
        .alter = divisionSteps / tone_division
        # Adjust MIDI note if alter >= 1
        if .alter >= 1
            .midiNote = .midiNote + floor(.alter)
            .alter = .alter - floor(.alter)
        endif
    else
        .midiNote = 0
        .alter = 0
    endif
endproc

# Function to get note name and octave from MIDI number (for base note only)
procedure midiToNoteName: .midiNum
    .octave = floor((.midiNum - 12) / 12)
    .pitchClass = (.midiNum - 12) mod 12
    
    if .pitchClass = 0
        .step$ = "C"
    elsif .pitchClass = 1
        .step$ = "C"
        .alter = 1
    elsif .pitchClass = 2
        .step$ = "D"
        .alter = 0
    elsif .pitchClass = 3
        .step$ = "D"
        .alter = 1
    elsif .pitchClass = 4
        .step$ = "E"
        .alter = 0
    elsif .pitchClass = 5
        .step$ = "F"
        .alter = 0
    elsif .pitchClass = 6
        .step$ = "F"
        .alter = 1
    elsif .pitchClass = 7
        .step$ = "G"
        .alter = 0
    elsif .pitchClass = 8
        .step$ = "G"
        .alter = 1
    elsif .pitchClass = 9
        .step$ = "A"
        .alter = 0
    elsif .pitchClass = 10
        .step$ = "A"
        .alter = 1
    elsif .pitchClass = 11
        .step$ = "B"
        .alter = 0
    endif
endproc

# Start MusicXML output
appendInfoLine: "<?xml version=""1.0"" encoding=""UTF-8""?>"
appendInfoLine: "<!DOCTYPE score-partwise PUBLIC ""-//Recordare//DTD MusicXML 3.1 Partwise//EN"" ""http://www.musicxml.org/dtds/partwise.dtd"">"
appendInfoLine: "<score-partwise version=""3.1"">"
appendInfoLine: "  <work>"
appendInfoLine: "    <work-title>Formant Analysis: ", soundName$, "</work-title>"
appendInfoLine: "  </work>"
appendInfoLine: "  <identification>"
appendInfoLine: "    <creator type=""software"">Praat Formant Analyzer</creator>"
appendInfoLine: "  </identification>"
appendInfoLine: "  <part-list>"
appendInfoLine: "    <score-part id=""P1"">"
appendInfoLine: "      <part-name>Formant Chords</part-name>"
appendInfoLine: "    </score-part>"
appendInfoLine: "  </part-list>"
appendInfoLine: "  <part id=""P1"">"

# Analyze each segment and create measures
for segment from 1 to number_of_segments
    # Calculate time point at center of segment
    startTime = (segment - 1) * segmentDuration
    endTime = segment * segmentDuration
    midTime = (startTime + endTime) / 2
    
    appendInfoLine: "    <measure number=""", segment, """>"
    
    # Add attributes only for first measure
    if segment = 1
            appendInfoLine: "      <attributes>"
        appendInfoLine: "        <divisions>1</divisions>"
        appendInfoLine: "        <key>"
        appendInfoLine: "          <fifths>0</fifths>"
        appendInfoLine: "        </key>"
        appendInfoLine: "        <time>"
        appendInfoLine: "          <beats>4</beats>"
        appendInfoLine: "          <beat-type>4</beat-type>"
        appendInfoLine: "        </time>"
        appendInfoLine: "        <clef>"
        appendInfoLine: "          <sign>G</sign>"
        appendInfoLine: "          <line>2</line>"
        appendInfoLine: "        </clef>"
        appendInfoLine: "      </attributes>"
    endif
    
    # Extract formants at midpoint
    selectObject: formant
    
    # Collect valid notes for the chord
    noteCount = 0
    for formantNum from 1 to 4
        freq = Get value at time: formantNum, midTime, "hertz", "Linear"
        
        if freq <> undefined and freq > 0
            call freqToMidi: freq
            midiNum[formantNum] = freqToMidi.midiNote
            alterValue[formantNum] = freqToMidi.alter
            noteCount += 1
        else
            midiNum[formantNum] = 0
            alterValue[formantNum] = 0
        endif
    endfor
    
    # Create notes (chord structure in MusicXML)
    noteIndex = 0
    for formantNum from 1 to 4
        if midiNum[formantNum] > 0
            noteIndex += 1
            
            call midiToNoteName: midiNum[formantNum]
            step$ = midiToNoteName.step$
            octave = midiToNoteName.octave
            
            appendInfoLine: "      <note>"
            
            # Add chord tag for notes after the first
            if noteIndex > 1
                appendInfoLine: "        <chord/>"
            endif
            
            appendInfoLine: "        <pitch>"
            appendInfoLine: "          <step>", step$, "</step>"
            
            # Combine the base note alter with the microtonal alter
            baseAlter = midiToNoteName.alter
            microAlter = alterValue[formantNum]
            totalAlter = baseAlter + microAlter
            
            if totalAlter <> 0
                appendInfoLine: "          <alter>", totalAlter, "</alter>"
            endif
            
            appendInfoLine: "          <octave>", octave, "</octave>"
            appendInfoLine: "        </pitch>"
            appendInfoLine: "        <duration>4</duration>"
            appendInfoLine: "        <type>whole</type>"
            appendInfoLine: "      </note>"
        endif
    endfor
    
    # If no valid notes, add a rest
    if noteCount = 0
        appendInfoLine: "      <note>"
        appendInfoLine: "        <rest/>"
        appendInfoLine: "        <duration>4</duration>"
        appendInfoLine: "        <type>whole</type>"
        appendInfoLine: "      </note>"
    endif
    
    appendInfoLine: "    </measure>"
endfor

# Close MusicXML
appendInfoLine: "  </part>"
appendInfoLine: "</score-partwise>"

# Clean up
removeObject: formant