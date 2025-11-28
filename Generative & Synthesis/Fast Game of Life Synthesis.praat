# ============================================================
# Praat AudioTools - Fast Game of Life Synthesis.praat
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

form Fast Game of Life Synthesis
    optionmenu Preset: 1
        option Custom
        option Glider Gun
        option Pulsar
        option Random Chaos
        option Stable Patterns
        option Oscillators
        option Spaceships
        option Garden of Eden
        option Dense Life
        option Sparse Life
        option Exploding Patterns
        option Symmetrical
        option Chaotic Growth
        option Dying Universe
        option Complex Evolution
    real Duration 4.0
    real Sampling_frequency 44100
    integer Grid_size 12
    real Base_frequency 200
    integer Total_steps 25
endform

echo Pre-computing Game of Life...

step_duration = duration / total_steps
formula$ = "0"

call PrecomputeGameOfLife

for step to total_steps
    step_time = (step-1) * step_duration
    active_count = 0
    
    for i to grid_size
        for j to grid_size
            if ca[step,i,j] = 1
                active_count = active_count + 1
                freq = base_frequency + ((i+j)/(2*grid_size)) * 400
                amp = 0.5 / grid_size
                
                if step_time + step_duration > duration
                    current_dur = duration - step_time
                else
                    current_dur = step_duration
                endif
                
                if current_dur > 0.001
                    cell_formula$ = "if x >= " + string$(step_time) + " and x < " + string$(step_time + current_dur)
                    cell_formula$ = cell_formula$ + " then " + string$(amp)
                    cell_formula$ = cell_formula$ + " * sin(2*pi*" + string$(freq) + "*x)"
                    cell_formula$ = cell_formula$ + " else 0 fi"
                    
                    if formula$ = "0"
                        formula$ = cell_formula$
                    else
                        formula$ = formula$ + " + " + cell_formula$
                    endif
                endif
            endif
        endfor
    endfor
    
    if step mod 5 = 0
        echo Rendered step 'step'/'total_steps', Active cells: 'active_count'
    endif
endfor

Create Sound from formula: "fast_game_of_life", 1, 0, duration, sampling_frequency, formula$
Scale peak: 0.9
Play

echo Fast Game of Life Synthesis complete!
echo Preset: 'preset'

procedure PrecomputeGameOfLife
    # Initialize based on preset
    if preset = 2
        # Glider Gun - adjust grid size
        grid_size = 20
        # Initialize empty grid
        for i to grid_size
            for j to grid_size
                ca[1,i,j] = 0
            endfor
        endfor
        # Manually set Gosper glider gun points
        ca[1,1,5] = 1
        ca[1,1,6] = 1
        ca[1,2,5] = 1
        ca[1,2,6] = 1
        ca[1,11,5] = 1
        ca[1,11,6] = 1
        ca[1,11,7] = 1
        ca[1,12,4] = 1
        ca[1,12,8] = 1
        ca[1,13,3] = 1
        ca[1,13,9] = 1
        ca[1,14,3] = 1
        ca[1,14,9] = 1
        ca[1,15,6] = 1
        ca[1,16,4] = 1
        ca[1,16,8] = 1
        ca[1,17,5] = 1
        ca[1,17,6] = 1
        ca[1,17,7] = 1
        ca[1,18,6] = 1
        
    elsif preset = 3
        # Pulsar - adjust grid size
        grid_size = 15
        # Initialize empty grid
        for i to grid_size
            for j to grid_size
                ca[1,i,j] = 0
            endfor
        endfor
        # Manually set pulsar points
        ca[1,2,4] = 1
        ca[1,2,5] = 1
        ca[1,2,6] = 1
        ca[1,2,10] = 1
        ca[1,2,11] = 1
        ca[1,2,12] = 1
        ca[1,4,2] = 1
        ca[1,4,7] = 1
        ca[1,4,9] = 1
        ca[1,4,14] = 1
        ca[1,5,2] = 1
        ca[1,5,7] = 1
        ca[1,5,9] = 1
        ca[1,5,14] = 1
        ca[1,6,2] = 1
        ca[1,6,7] = 1
        ca[1,6,9] = 1
        ca[1,6,14] = 1
        ca[1,7,4] = 1
        ca[1,7,5] = 1
        ca[1,7,6] = 1
        ca[1,7,10] = 1
        ca[1,7,11] = 1
        ca[1,7,12] = 1
        ca[1,9,4] = 1
        ca[1,9,5] = 1
        ca[1,9,6] = 1
        ca[1,9,10] = 1
        ca[1,9,11] = 1
        ca[1,9,12] = 1
        ca[1,10,2] = 1
        ca[1,10,7] = 1
        ca[1,10,9] = 1
        ca[1,10,14] = 1
        ca[1,11,2] = 1
        ca[1,11,7] = 1
        ca[1,11,9] = 1
        ca[1,11,14] = 1
        ca[1,12,2] = 1
        ca[1,12,7] = 1
        ca[1,12,9] = 1
        ca[1,12,14] = 1
        ca[1,14,4] = 1
        ca[1,14,5] = 1
        ca[1,14,6] = 1
        ca[1,14,10] = 1
        ca[1,14,11] = 1
        ca[1,14,12] = 1
        
    elsif preset = 4
        # Random Chaos
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.5
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 5
        # Stable Patterns
        for i to grid_size
            for j to grid_size
                ca[1,i,j] = 0
            endfor
        endfor
        # Block pattern
        ca[1,5,5] = 1
        ca[1,5,6] = 1
        ca[1,6,5] = 1
        ca[1,6,6] = 1
        
    elsif preset = 6
        # Oscillators
        for i to grid_size
            for j to grid_size
                ca[1,i,j] = 0
            endfor
        endfor
        # Blinker pattern
        ca[1,5,4] = 1
        ca[1,5,5] = 1
        ca[1,5,6] = 1
        
    elsif preset = 7
        # Spaceships
        grid_size = 16
        for i to grid_size
            for j to grid_size
                ca[1,i,j] = 0
            endfor
        endfor
        # Glider pattern
        ca[1,2,1] = 1
        ca[1,3,2] = 1
        ca[1,1,3] = 1
        ca[1,2,3] = 1
        ca[1,3,3] = 1
        
    elsif preset = 8
        # Garden of Eden (sparse)
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.9
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 9
        # Dense Life
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.3
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 10
        # Sparse Life
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.85
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 11
        # Exploding Patterns
        for i to grid_size
            for j to grid_size
                if (i mod 3 = 0 and j mod 3 = 0) or randomUniform(0,1) > 0.8
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 12
        # Symmetrical
        for i to grid_size
            for j to grid_size
                if (i = j) or (i = grid_size - j + 1) or randomUniform(0,1) > 0.7
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 13
        # Chaotic Growth
        for i to grid_size
            for j to grid_size
                if i = round(grid_size/2) or j = round(grid_size/2) or randomUniform(0,1) > 0.6
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 14
        # Dying Universe
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.95
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    elsif preset = 15
        # Complex Evolution
        for i to grid_size
            for j to grid_size
                if (i + j) mod 4 = 0 or randomUniform(0,1) > 0.7
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
        
    else
        # Custom - original random initialization
        for i to grid_size
            for j to grid_size
                if randomUniform(0,1) > 0.7
                    ca[1,i,j] = 1
                else
                    ca[1,i,j] = 0
                endif
            endfor
        endfor
    endif

    # Run Game of Life simulation
    for step from 2 to total_steps
        for i to grid_size
            for j to grid_size
                neighbors = 0
                
                for di from -1 to 1
                    for dj from -1 to 1
                        if di != 0 or dj != 0
                            ni = i + di
                            nj = j + dj
                            if ni >= 1 and ni <= grid_size and nj >= 1 and nj <= grid_size
                                neighbors = neighbors + ca[step-1,ni,nj]
                            endif
                        endif
                    endfor
                endfor
                
                if ca[step-1,i,j] = 1
                    if neighbors < 2 or neighbors > 3
                        ca[step,i,j] = 0
                    else
                        ca[step,i,j] = 1
                    endif
                else
                    if neighbors = 3
                        ca[step,i,j] = 1
                    else
                        ca[step,i,j] = 0
                    endif
                endif
            endfor
        endfor
        
        if step mod 10 = 0
            echo Pre-computed step 'step'/'total_steps'
        endif
    endfor
endproc