# ============================================================
# Praat AudioTools - Cellular Automata Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Sound synthesis or generative algorithm script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Cellular Automata Synthesis (Ultra-Fast - Complete)

form Cellular Automata Synthesis
    optionmenu preset: 1
        option Custom (use settings below)
        option Rule 30 Classic
        option Rule 110 Complex
        option Rule 90 Symmetric
        option Game of Life Dense
        option Brian's Brain Chaotic
    
    comment === Custom Settings ===
    real Duration 8.0
    integer Grid_size 32
    choice Rule_type: 1
        button Elementary_CA
        button Game_of_Life
        button Brian_Brain
    integer Rule_number 30
    real Segment_duration 0.1
    real Base_frequency 150
    real Frequency_spread 200
    boolean Play_after 1
endform

# Apply presets
if preset = 2
    duration = 8.0
    grid_size = 32
    rule_type = 1
    rule_number = 30
    segment_duration = 0.1
    base_frequency = 150
    frequency_spread = 200
    preset_name$ = "Rule30"
elsif preset = 3
    duration = 10.0
    grid_size = 40
    rule_type = 1
    rule_number = 110
    segment_duration = 0.08
    base_frequency = 120
    frequency_spread = 250
    preset_name$ = "Rule110"
elsif preset = 4
    duration = 8.0
    grid_size = 32
    rule_type = 1
    rule_number = 90
    segment_duration = 0.1
    base_frequency = 180
    frequency_spread = 180
    preset_name$ = "Rule90"
elsif preset = 5
    duration = 12.0
    grid_size = 24
    rule_type = 2
    rule_number = 0
    segment_duration = 0.15
    base_frequency = 100
    frequency_spread = 300
    preset_name$ = "GameOfLife"
elsif preset = 6
    duration = 10.0
    grid_size = 28
    rule_type = 3
    rule_number = 0
    segment_duration = 0.12
    base_frequency = 130
    frequency_spread = 200
    preset_name$ = "BrianBrain"
else
    preset_name$ = "Custom"
endif

writeInfoLine: "Cellular Automata Synthesis (Ultra-Fast)"
appendInfoLine: "Preset: ", preset_name$
appendInfoLine: "Grid size: ", grid_size
appendInfoLine: "Duration: ", duration, " s"
appendInfoLine: ""

sample_rate = 44100
total_segments = round(duration / segment_duration)
chunk_segments = 20

# Initialize CA
if rule_type = 1
    appendInfoLine: "Initializing Elementary CA Rule ", rule_number
    @InitElementaryCA
elsif rule_type = 2
    appendInfoLine: "Initializing Game of Life"
    @InitGameOfLife
else
    appendInfoLine: "Initializing Brian's Brain"
    @InitBrianBrain
endif

# Evolve all CA states
appendInfo: "Computing CA evolution..."

if rule_type = 1
    # Elementary CA
    for segment from 1 to total_segments - 1
        @EvolveElementaryCA: segment
    endfor
elsif rule_type = 2
    # Game of Life - store history
    for segment from 1 to total_segments
        # Save current state
        for i to grid_size
            for j to grid_size
                ca_history[segment, i, j] = ca[i, j]
            endfor
        endfor
        
        # Evolve for next
        if segment < total_segments
            @EvolveGameOfLife
        endif
    endfor
else
    # Brian's Brain - store history
    for segment from 1 to total_segments
        # Save current state
        for i to grid_size
            for j to grid_size
                ca_history[segment, i, j] = ca[i, j]
            endfor
        endfor
        
        # Evolve for next
        if segment < total_segments
            @EvolveBrianBrain
        endif
    endfor
endif

appendInfoLine: " done"

# Process in chunks
num_chunks = ceiling(total_segments / chunk_segments)
appendInfoLine: "Creating ", num_chunks, " chunks..."

for chunk from 1 to num_chunks
    segment_start = (chunk - 1) * chunk_segments + 1
    segment_end = min(chunk * chunk_segments, total_segments)
    
    appendInfo: "  Chunk ", chunk, "/", num_chunks, "..."
    
    chunk_formula$ = "0"
    
    for segment from segment_start to segment_end
        segment_time = (segment - 1) * segment_duration
        chunk_local_time = segment_time - (segment_start - 1) * segment_duration
        
        # Add active cells based on CA type
        if rule_type = 1
            # Elementary CA: 1D
            for cell to grid_size
                if ca[segment, cell] = 1
                    freq = base_frequency + (cell / grid_size) * frequency_spread
                    amp = 0.6 / sqrt(grid_size)
                    dur = segment_duration
                    
                    if segment_time + dur > duration
                        dur = duration - segment_time
                    endif
                    
                    if dur > 0.001
                        s_time$ = fixed$(chunk_local_time, 6)
                        s_end$ = fixed$(chunk_local_time + dur, 6)
                        s_amp$ = fixed$(amp, 6)
                        s_freq$ = fixed$(freq, 2)
                        s_dur$ = fixed$(dur, 6)
                        s_global_time$ = fixed$((segment_start - 1) * segment_duration, 6)
                        
                        term$ = " + if x >= " + s_time$ + " and x < " + s_end$ + " then " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*(x + " + s_global_time$ + ")) * (1 - cos(2*pi*(x - " + s_time$ + ")/" + s_dur$ + "))/2 else 0 fi"
                        chunk_formula$ = chunk_formula$ + term$
                    endif
                endif
            endfor
        else
            # 2D CA (Game of Life / Brian's Brain)
            for i to grid_size
                for j to grid_size
                    if (rule_type = 2 and ca_history[segment, i, j] = 1) or (rule_type = 3 and ca_history[segment, i, j] = 1)
                        if rule_type = 2
                            freq_x = base_frequency + (i / grid_size) * frequency_spread
                            freq_y = base_frequency / 2 + (j / grid_size) * frequency_spread / 2
                            freq = (freq_x + freq_y) / 2
                            amp = 0.4 / grid_size
                        else
                            freq = base_frequency + ((i + j) / (2 * grid_size)) * frequency_spread
                            amp = 0.5 / grid_size
                        endif
                        
                        dur = segment_duration
                        if segment_time + dur > duration
                            dur = duration - segment_time
                        endif
                        
                        if dur > 0.001
                            s_time$ = fixed$(chunk_local_time, 6)
                            s_end$ = fixed$(chunk_local_time + dur, 6)
                            s_amp$ = fixed$(amp, 6)
                            s_freq$ = fixed$(freq, 2)
                            s_global_time$ = fixed$((segment_start - 1) * segment_duration, 6)
                            
                            term$ = " + if x >= " + s_time$ + " and x < " + s_end$ + " then " + s_amp$ + " * sin(2*pi*" + s_freq$ + "*(x + " + s_global_time$ + ")) else 0 fi"
                            chunk_formula$ = chunk_formula$ + term$
                        endif
                    endif
                endfor
            endfor
        endif
    endfor
    
    chunk_duration = (segment_end - segment_start + 1) * segment_duration
    
    if chunk_formula$ <> "0"
        Create Sound from formula: "chunk_'chunk'", 1, 0, chunk_duration, sample_rate, chunk_formula$
    else
        Create Sound from formula: "chunk_'chunk'", 1, 0, chunk_duration, sample_rate, "0"
    endif
    
    appendInfoLine: " done"
endfor

# Concatenate all chunks
appendInfo: "Concatenating chunks..."
selectObject: "Sound chunk_1"
for chunk from 2 to num_chunks
    plusObject: "Sound chunk_" + string$(chunk)
endfor

final_sound = Concatenate
Rename: "ca_" + preset_name$

# Cleanup chunks
for chunk from 1 to num_chunks
    removeObject: "Sound chunk_" + string$(chunk)
endfor

appendInfoLine: " done"

selectObject: final_sound
Scale peak: 0.9

final_dur = Get total duration
appendInfoLine: ""
appendInfoLine: "Complete! Duration: ", final_dur, " s"

if play_after
    Play
endif

# ========== PROCEDURES ==========

procedure InitElementaryCA
    for i to grid_size
        if i = round(grid_size / 2)
            ca[1, i] = 1
        else
            ca[1, i] = 0
        endif
    endfor
endproc

procedure InitGameOfLife
    for i to grid_size
        for j to grid_size
            if randomUniform(0, 1) > 0.7
                ca[i, j] = 1
            else
                ca[i, j] = 0
            endif
        endfor
    endfor
endproc

procedure InitBrianBrain
    for i to grid_size
        for j to grid_size
            r = randomUniform(0, 1)
            if r < 0.3
                ca[i, j] = 1
            elsif r < 0.5
                ca[i, j] = 2
            else
                ca[i, j] = 0
            endif
        endfor
    endfor
endproc

procedure EvolveElementaryCA: .segment
    for cell to grid_size
        left = 0
        center = 0
        right = 0
        
        if cell > 1
            left = ca[.segment, cell - 1]
        endif
        center = ca[.segment, cell]
        if cell < grid_size
            right = ca[.segment, cell + 1]
        endif
        
        pattern = 4 * left + 2 * center + right
        rule_bit = (rule_number mod (2 ^ (pattern + 1))) div (2 ^ pattern)
        ca[.segment + 1, cell] = rule_bit
    endfor
endproc

procedure EvolveGameOfLife
    for i to grid_size
        for j to grid_size
            neighbors = 0
            
            for di from -1 to 1
                for dj from -1 to 1
                    if di <> 0 or dj <> 0
                        ni = i + di
                        nj = j + dj
                        if ni >= 1 and ni <= grid_size and nj >= 1 and nj <= grid_size
                            neighbors = neighbors + ca[ni, nj]
                        endif
                    endif
                endfor
            endfor
            
            if ca[i, j] = 1
                if neighbors < 2 or neighbors > 3
                    next_ca[i, j] = 0
                else
                    next_ca[i, j] = 1
                endif
            else
                if neighbors = 3
                    next_ca[i, j] = 1
                else
                    next_ca[i, j] = 0
                endif
            endif
        endfor
    endfor
    
    for i to grid_size
        for j to grid_size
            ca[i, j] = next_ca[i, j]
        endfor
    endfor
endproc

procedure EvolveBrianBrain
    for i to grid_size
        for j to grid_size
            neighbors = 0
            
            for di from -1 to 1
                for dj from -1 to 1
                    if di <> 0 or dj <> 0
                        ni = i + di
                        nj = j + dj
                        if ni >= 1 and ni <= grid_size and nj >= 1 and nj <= grid_size
                            if ca[ni, nj] = 1
                                neighbors = neighbors + 1
                            endif
                        endif
                    endif
                endfor
            endfor
            
            if ca[i, j] = 0
                if neighbors = 2
                    next_ca[i, j] = 1
                else
                    next_ca[i, j] = 0
                endif
            elsif ca[i, j] = 1
                next_ca[i, j] = 2
            else
                next_ca[i, j] = 0
            endif
        endfor
    endfor
    
    for i to grid_size
        for j to grid_size
            ca[i, j] = next_ca[i, j]
        endfor
    endfor
endproc