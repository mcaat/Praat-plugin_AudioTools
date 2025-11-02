# ============================================================
# Praat AudioTools - Polynomial Sound Shaper.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Polynomial Envelope Visualizer and Sound Shaper
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
form apply polynomial envelope
    optionmenu envelope_type 1
        option Polynomial (standard)
        option Polynomial from product terms
    
    optionmenu poly_preset 1
        option custom
        option cubic_1
        option cubic_2
        option cubic_3
        option cubic_4
        option cubic_5
    
    real startx -3
    real endx 4
    real coefa 2
    real coefb -1
    real coefc -2
    real coefd 1
    
    comment === Product Terms Presets ===
    optionmenu product_preset 1
        option custom
        option fade in (0, 1)
        option fade out (-1, 0)
        option center peak (-1, 1)
        option double dip (-2, 0, 2)
        option asymmetric (0, 2)
        option steep rise (0, 0.5)
        option gentle (0, 3)
    
    comment === Custom Product Terms ===
    real param1 1
    real param2 2
    real param3 0
    
    real scalepeak 0.99
    real min_threshold 1.
    boolean draw_envelope 1
    boolean play_result 1
endform

# Apply polynomial presets
if envelope_type = 1
    if poly_preset = 2
        coefa = 2
        coefb = -1
        coefc = -2
        coefd = 1
    elsif poly_preset = 3
        coefa = -1
        coefb = 3
        coefc = -1
        coefd = 0.5
    elsif poly_preset = 4
        coefa = 1
        coefb = 0
        coefc = -3
        coefd = 1
    elsif poly_preset = 5
        coefa = 3
        coefb = -2
        coefc = 0
        coefd = 1
    elsif poly_preset = 6
        coefa = -2
        coefb = 1
        coefc = 1
        coefd = 0
    endif
endif

# Apply product terms presets
if envelope_type = 2
    if product_preset = 2
        # fade in (0, 1)
        param1 = 0
        param2 = 1
        param3 = 0
    elsif product_preset = 3
        # fade out (-1, 0)
        param1 = -1
        param2 = 0
        param3 = 0
    elsif product_preset = 4
        # center peak (-1, 1)
        param1 = -1
        param2 = 1
        param3 = 0
    elsif product_preset = 5
        # double dip (-2, 0, 2)
        param1 = -2
        param2 = 0
        param3 = 2
    elsif product_preset = 6
        # asymmetric (0, 2)
        param1 = 0
        param2 = 2
        param3 = 0
    elsif product_preset = 7
        # steep rise (0, 0.5)
        param1 = 0
        param2 = 0.5
        param3 = 0
    elsif product_preset = 8
        # gentle (0, 3)
        param1 = 0
        param2 = 3
        param3 = 0
    endif
endif

soundname$ = selected$("Sound")
if soundname$ = ""
    exit please select a sound first.
endif

dur = Get total duration

# Create the appropriate envelope function
if envelope_type = 1
    Create Polynomial: "p", startx, endx, { coefa, coefb, coefc, coefd }
elsif envelope_type = 2
    if param3 = 0
        Create Polynomial from product terms: "p", startx, endx, { param1, param2 }
    else
        Create Polynomial from product terms: "p", startx, endx, { param1, param2, param3 }
    endif
endif

if draw_envelope = 1
    Erase all
    Draw: 0, 0, 0, 0, "no", "yes"
    Text top: "yes", "Envelope Function"
endif

selectObject: "Sound " + soundname$
Copy: soundname$ + "_shaped"

selectObject: "Sound " + soundname$ + "_shaped"

if envelope_type = 1
    Formula: "self * max(min_threshold, coefa*((x/dur)*(endx-startx)+startx)^3 + coefb*((x/dur)*(endx-startx)+startx)^2 + coefc*((x/dur)*(endx-startx)+startx) + coefd)"
else
    num_samples = Get number of samples
    chunk_size = 10000
    start_sample = 1
    
    while start_sample <= num_samples
        end_sample = start_sample + chunk_size - 1
        if end_sample > num_samples
            end_sample = num_samples
        endif
        
        for i from start_sample to end_sample
            t = Get time from sample number: i
            x_val = (t / dur) * (endx - startx) + startx
            
            selectObject: "Polynomial p"
            env_val = Get value: x_val
            
            # Apply threshold
            if env_val < min_threshold
                env_val = min_threshold
            endif
            
            selectObject: "Sound " + soundname$ + "_shaped"
            sample_val = Get value at sample number: 1, i
            Set value at sample number: 1, i, sample_val * env_val
        endfor
        
        percent = round((end_sample / num_samples) * 100)
        writeInfo: "Processing: ", percent, "%", newline$
        
        start_sample = start_sample + chunk_size
    endwhile
    
    writeInfoLine: "Processing: 100% complete"
endif

Scale peak: scalepeak

if play_result = 1
    Play
endif

plusObject: "Polynomial p"
plusObject: "Sound " + soundname$

writeInfoLine: "Envelope applied successfully!"
if envelope_type = 1
    appendInfoLine: "Type: Polynomial (standard)"
    appendInfoLine: "Coefficients: a=", coefa, " b=", coefb, " c=", coefc, " d=", coefd
elsif envelope_type = 2
    appendInfoLine: "Type: Polynomial from product terms"
    if param3 = 0
        appendInfoLine: "Product: (x - ", param1, ")(x - ", param2, ")"
    else
        appendInfoLine: "Product: (x - ", param1, ")(x - ", param2, ")(x - ", param3, ")"
    endif
endif
appendInfoLine: "Domain: [", startx, ", ", endx, "]"
appendInfoLine: "Min threshold: ", min_threshold
appendInfoLine: "Original: Sound ", soundname$
appendInfoLine: "Result: Sound ", soundname$, "_shaped"