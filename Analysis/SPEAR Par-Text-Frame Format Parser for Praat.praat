# SPEAR Par-Text-Frame Format Parser for Praat
# This script reads SPEAR's text export format and extracts frequency/amplitude data

clearinfo

# File path
file_path$ = "C:/Users/User/Desktop/sounds/Cello.txt"

# Read the SPEAR text file
Read Strings from raw text file... 'file_path$'
Rename... spear_data

# Get total number of lines
select Strings spear_data
n_lines = Get number of strings

appendInfoLine: "=== SPEAR Par-Text-Frame Format Parser ==="
appendInfoLine: "Total lines in file: 'n_lines'"
appendInfoLine: ""

# Parse header information
select Strings spear_data
line$ = Get string... 1
appendInfoLine: "Header: 'line$'"

# Initialize variables
current_line = 1
frame_count = 0
in_frame = 0

# Create a table to store the parsed data
Create Table with column names... spear_table 0 frame_number time frequency amplitude bandwidth phase

# Parse the file
for line from 1 to n_lines
    select Strings spear_data
    line$ = Get string... line
    
    # Remove leading/trailing whitespace
    line$ = replace_regex$ (line$, "^\s+", "", 0)
    line$ = replace_regex$ (line$, "\s+$", "", 0)
    
    # Check if this is a frame header
    if startsWith(line$, "frame")
        frame_count = frame_count + 1
        # Extract time from frame line (format: "frame 0.0232")
        time$ = replace_regex$(line$, "frame\s+", "", 1)
        current_time = number(time$)
        in_frame = 1
        
    # Check if this is the "partials" keyword (marks start of partial data)
    elsif line$ = "partials"
        in_frame = 1
        
    # Check if this is partial data (should have 4 or 5 numbers)
    elsif in_frame = 1 and line$ <> "" and line$ <> "partials" and not startsWith(line$, "par-text-frame")
        # Parse partial data: frequency amplitude bandwidth [phase]
        # Split by whitespace
        frequency$ = extractWord$(line$, "")
        
        # Check if line contains numbers
        if index_regex(line$, "^\d")
            # Extract values
            @parsePartialLine: line$
            
            if parsePartialLine.valid = 1
                select Table spear_table
                Append row
                row = Get number of rows
                Set numeric value... row frame_number frame_count
                Set numeric value... row time current_time
                Set numeric value... row frequency parsePartialLine.freq
                Set numeric value... row amplitude parsePartialLine.amp
                Set numeric value... row bandwidth parsePartialLine.bw
                Set numeric value... row phase parsePartialLine.phase
            endif
        endif
    endif
endfor

# Display results
select Table spear_table
n_rows = Get number of rows
appendInfoLine: ""
appendInfoLine: "=== Parsing Complete ==="
appendInfoLine: "Total frames parsed: 'frame_count'"
appendInfoLine: "Total partials extracted: 'n_rows'"
appendInfoLine: ""

# Show first 10 partials as example
appendInfoLine: "=== First 10 Partials ==="
appendInfoLine: "Frame | Time | Frequency | Amplitude | Bandwidth | Phase"
for row from 1 to min(10, n_rows)
    select Table spear_table
    frame = Get value... row frame_number
    time = Get value... row time
    freq = Get value... row frequency
    amp = Get value... row amplitude
    bw = Get value... row bandwidth
    phase = Get value... row phase
    appendInfoLine: "'frame' | 'time:4' | 'freq:2' Hz | 'amp:4' | 'bw:2' | 'phase:4'"
endfor

appendInfoLine: ""
appendInfoLine: "Data is now in Table 'spear_table'"
appendInfoLine: "You can now manipulate this data as needed!"

# Procedure to parse a partial line
procedure parsePartialLine: .line$
    .valid = 0
    .freq = 0
    .amp = 0
    .bw = 0
    .phase = 0
    
    # Count words in line
    .n_words = 0
    .temp$ = .line$
    while .temp$ <> ""
        .word$ = extractWord$(.temp$, "")
        if .word$ <> ""
            .n_words = .n_words + 1
            if .n_words = 1
                .freq = number(.word$)
            elsif .n_words = 2
                .amp = number(.word$)
            elsif .n_words = 3
                .bw = number(.word$)
            elsif .n_words = 4
                .phase = number(.word$)
            endif
            .temp$ = replace$(.temp$, .word$, "", 1)
            .temp$ = replace_regex$(.temp$, "^\s+", "", 0)
        else
            .temp$ = ""
        endif
    endwhile
    
    if .n_words >= 3
        .valid = 1
    endif
endproc