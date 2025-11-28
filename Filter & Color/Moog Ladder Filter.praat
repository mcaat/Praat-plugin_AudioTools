# ============================================================
# Praat AudioTools - Moog Ladder Filter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Moog Ladder Filter
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Moog Ladder Filter - TPT with Automation
# Fast processing with optional parameter sweeps

form Moog Ladder Filter (TPT + Automation)
    optionmenu Preset 1
        option Custom
        option Bass Filter (300 Hz, res 0.3)
        option Warm Pad (800 Hz, res 0.5)
        option Vocal Formant (1500 Hz, res 0.65)
        option Bright Sweep (2500 Hz, res 0.55)
        option Resonant Peak (1200 Hz, res 0.75)
        option Telephone (2800 Hz, res 0.35)
        option Sub Bass (150 Hz, res 0.2)
        option Acid Bass (500 Hz, res 0.75)
        option Cutoff Sweep Up (200->3000 Hz)
        option Cutoff Sweep Down (3000->200 Hz)
        option Resonance Sweep (static cutoff, res sweep)
    comment Static parameters (used if preset = Custom):
    positive Cutoff_frequency_(Hz) 1000
    real Resonance_(0-1) 0.7
    comment Automation parameters (for sweep presets):
    positive Start_cutoff_(Hz) 200
    positive End_cutoff_(Hz) 3000
    real Start_resonance_(0-1) 0.2
    real End_resonance_(0-1) 0.8
    boolean DC_blocker 1
    optionmenu Limiter_type 1
        option Soft (x/(1+|x|))
        option Analog-style (tanh)
    real Output_trim_(dB) 0
endform

# Apply preset values
if preset == 2
    cutoff_frequency = 300
    resonance = 0.3
    use_automation = 0
elsif preset == 3
    cutoff_frequency = 800
    resonance = 0.5
    use_automation = 0
elsif preset == 4
    cutoff_frequency = 1500
    resonance = 0.65
    use_automation = 0
elsif preset == 5
    cutoff_frequency = 2500
    resonance = 0.55
    use_automation = 0
elsif preset == 6
    cutoff_frequency = 1200
    resonance = 0.75
    use_automation = 0
elsif preset == 7
    cutoff_frequency = 2800
    resonance = 0.35
    use_automation = 0
elsif preset == 8
    cutoff_frequency = 150
    resonance = 0.2
    use_automation = 0
elsif preset == 9
    cutoff_frequency = 500
    resonance = 0.75
    use_automation = 0
elsif preset == 10
    # Cutoff Sweep Up
    start_cutoff = 200
    end_cutoff = 3000
    start_resonance = 0.5
    end_resonance = 0.5
    use_automation = 1
elsif preset == 11
    # Cutoff Sweep Down
    start_cutoff = 3000
    end_cutoff = 200
    start_resonance = 0.5
    end_resonance = 0.5
    use_automation = 1
elsif preset == 12
    # Resonance Sweep
    start_cutoff = 800
    end_cutoff = 800
    start_resonance = 0.1
    end_resonance = 0.85
    use_automation = 1
else
    # Custom - no automation
    use_automation = 0
endif

# Get selected sound
sound = selected("Sound")
soundName$ = selected$("Sound")
samplingFrequency = Get sampling frequency
duration = Get total duration
numberOfChannels = Get number of channels

# Output trim
trimGain = 10 ^ (output_trim / 20)

# ============================================================
# AUTOMATION MODE: Process in small chunks with interpolated parameters
# ============================================================
if use_automation
    
    # Chunk size for parameter updates (10ms = good balance)
    chunkDuration = 0.01
    numberOfChunks = ceiling(duration / chunkDuration)
    
    # Array to store processed chunks
    processedChunks# = zero# (numberOfChunks)
    
    # Process each chunk
    for chunkIndex from 0 to numberOfChunks - 1
        
        # Calculate time range for this chunk
        t_start = chunkIndex * chunkDuration
        t_end = (chunkIndex + 1) * chunkDuration
        if t_end > duration
            t_end = duration
        endif
        
        # Interpolate parameters at chunk midpoint
        t_mid = (t_start + t_end) / 2
        progress = t_mid / duration
        
        # Exponential interpolation for cutoff (musical)
        cutoff_frequency = start_cutoff * exp(ln(end_cutoff / start_cutoff) * progress)
        
        # Linear interpolation for resonance
        resonance = start_resonance + (end_resonance - start_resonance) * progress
        
        # Extract chunk
        selectObject: sound
        chunk = Extract part: t_start, t_end, "rectangular", 1, "no"
        
        # Calculate TPT coefficients for this chunk
        fc = cutoff_frequency / samplingFrequency
        wc = 2 * pi * fc
        g = tan(wc / 2)
        gg = g / (1 + g)
        gg_comp = 1 - gg
        
        # Resonance with power curve
        k = 4 * (resonance ^ 1.5)
        
        # Adaptive k cap
        k_max = 3.9
        if g > 0.6
            k_max = 3.9 - (g - 0.6) * 3.0
            if k_max < 3.0
                k_max = 3.0
            endif
        endif
        if k > k_max
            k = k_max
        endif
        
        # Adaptive iterations
        iterations = 2
        if k > 3.0 or g > 0.5
            iterations = 3
        endif
        if k > 3.4 and g > 0.5
            iterations = 4
        endif
        
        # Process chunk with ladder filter
        stage1 = Copy: "stage1"
        stage2 = Copy: "stage2"
        stage3 = Copy: "stage3"
        stage4 = Copy: "stage4"
        feedback = Copy: "feedback"
        chunk_result = Copy: "chunk_result"
        
        selectObject: feedback
        Formula: "0"
        
        for iteration from 1 to iterations
            selectObject: stage1
            Formula: "object[chunk, col] - " + string$(k) + " * object[feedback, col]"
            Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
            
            selectObject: stage2
            Formula: "object[stage1, col]"
            Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
            
            selectObject: stage3
            Formula: "object[stage2, col]"
            Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
            
            selectObject: stage4
            Formula: "object[stage3, col]"
            Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
            
            selectObject: feedback
            Formula: "object[stage4, col-1]"
        endfor
        
        selectObject: chunk_result
        Formula: "object[stage4, col] * " + string$(trimGain)
        
        # Apply limiting
        if limiter_type == 1
            Formula: "self / (1 + abs(self))"
        else
            Formula: "tanh(0.8 * self)"
        endif
        
        # Store processed chunk ID
        processedChunks# [chunkIndex + 1] = chunk_result
        
        # Cleanup chunk processing (keep chunk_result)
        removeObject: stage1, stage2, stage3, stage4, feedback, chunk
        
    endfor
    
    # Concatenate all processed chunks
    selectObject: processedChunks# [1]
    for chunkIndex from 2 to numberOfChunks
        plusObject: processedChunks# [chunkIndex]
    endfor
    result = Concatenate
    Rename: soundName$ + "_moog_sweep"
    
    # Cleanup chunk results
    for chunkIndex from 1 to numberOfChunks
        removeObject: processedChunks# [chunkIndex]
    endfor
    
    # Apply DC blocker to final result
    if dC_blocker
        selectObject: result
        dcInput = Copy: "dc_input"
        dcOutput = Copy: "dc_output"
        
        alpha_dc = exp(-2 * pi * 20 / samplingFrequency)
        
        selectObject: dcInput
        Formula: "object[result, col]"
        
        selectObject: dcOutput
        Formula: "object[dcInput, col] - object[dcInput, col-1] + " + string$(alpha_dc) + " * self[col-1]"
        
        selectObject: result
        Formula: "object[dcOutput, col]"
        
        removeObject: dcInput, dcOutput
    endif

# ============================================================
# STATIC MODE: Single-pass processing
# ============================================================
else
    
    # Calculate TPT coefficients
    fc = cutoff_frequency / samplingFrequency
    wc = 2 * pi * fc
    g = tan(wc / 2)
    gg = g / (1 + g)
    gg_comp = 1 - gg
    
    # Resonance with power curve
    k = 4 * (resonance ^ 1.5)
    
    # Adaptive k cap
    k_max = 3.9
    if g > 0.6
        k_max = 3.9 - (g - 0.6) * 3.0
        if k_max < 3.0
            k_max = 3.0
        endif
    endif
    if k > k_max
        k = k_max
    endif
    
    # Adaptive iterations
    iterations = 2
    if k > 3.0 or g > 0.5
        iterations = 3
    endif
    if k > 3.4 and g > 0.5
        iterations = 4
    endif
    
    # Create working copies
    selectObject: sound
    stage1 = Copy: "stage1"
    stage2 = Copy: "stage2"
    stage3 = Copy: "stage3"
    stage4 = Copy: "stage4"
    feedback = Copy: "feedback"
    result = Copy: soundName$ + "_moog"
    
    selectObject: feedback
    Formula: "0"
    
    for iteration from 1 to iterations
        selectObject: stage1
        Formula: "object[sound, col] - " + string$(k) + " * object[feedback, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        selectObject: stage2
        Formula: "object[stage1, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        selectObject: stage3
        Formula: "object[stage2, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        selectObject: stage4
        Formula: "object[stage3, col]"
        Formula: "self[col] * " + string$(gg) + " + self[col-1] * " + string$(gg_comp)
        
        selectObject: feedback
        Formula: "object[stage4, col-1]"
    endfor
    
    selectObject: result
    Formula: "object[stage4, col] * " + string$(trimGain)
    
    # Apply limiting
    if limiter_type == 1
        Formula: "self / (1 + abs(self))"
    else
        Formula: "tanh(0.8 * self)"
    endif
    
    # DC blocker
    if dC_blocker
        selectObject: result
        dcInput = Copy: "dc_input"
        dcOutput = Copy: "dc_output"
        
        alpha_dc = exp(-2 * pi * 20 / samplingFrequency)
        
        selectObject: dcInput
        Formula: "object[result, col]"
        
        selectObject: dcOutput
        Formula: "object[dcInput, col] - object[dcInput, col-1] + " + string$(alpha_dc) + " * self[col-1]"
        
        selectObject: result
        Formula: "object[dcOutput, col]"
        
        removeObject: dcInput, dcOutput
    endif
    
    # Cleanup
    removeObject: stage1, stage2, stage3, stage4, feedback

endif

# Select output
selectObject: result
Play