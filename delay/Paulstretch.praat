# ============================================================
# Praat AudioTools - Paulstretch.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Paulstretch
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Paulstretch algorithm for Praat 
# Creates extreme time-stretching with phase randomization

form Paulstretch parameters
    comment Select a Sound object first, then run this script
    comment WARNING: This is a long process - Praat may appear frozen!
    positive stretch_factor 4.0
    positive window_size 0.25
    positive overlap_percent 50
endform

# Check if a Sound is selected
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

# Get the input sound
original_sound = selected("Sound")
selectObject: original_sound
sound_name$ = selected$("Sound")
fs = Get sampling frequency
duration = Get total duration
n_channels = Get number of channels

# Convert to mono if needed
if n_channels > 1
    sound = Convert to mono
else
    sound = original_sound
endif

selectObject: sound

# Calculate parameters
window_samples = round(window_size * fs)
if window_samples mod 2 = 1
    window_samples += 1
endif

overlap_fraction = overlap_percent / 100
hop_out = window_size * (1 - overlap_fraction)
hop_in = hop_out / stretch_factor
output_duration = duration * stretch_factor

# Calculate number of frames
n_frames = ceiling(output_duration / hop_out) + 1

writeInfoLine: "Paulstretch Processing"
appendInfoLine: "Input duration: ", fixed$(duration, 3), " s"
appendInfoLine: "Output duration: ", fixed$(output_duration, 3), " s"
appendInfoLine: "Number of frames: ", n_frames
appendInfoLine: ""

# Create initial empty output sound
output_sound = Create Sound from formula: "temp_output", 1, 0, output_duration + window_size, fs, "0"

# Progress every N frames
progress_interval = max(1, round(n_frames / 20))

# Process each frame
for iframe from 0 to n_frames - 1
    # Progress indicator
    if iframe mod progress_interval = 0
        percent = iframe / n_frames * 100
        appendInfoLine: "Progress: ", fixed$(percent, 1), "% (frame ", iframe, "/", n_frames, ")"
    endif
    
    # Input center time
    t_in = iframe * hop_in
    t_start = t_in - window_size / 2
    t_end = t_in + window_size / 2
    
    # Extract frame from input with proper bounds
    selectObject: sound
    extract_start = max(0, t_start)
    extract_end = min(duration, t_end)
    
    # Only process if we have some audio to extract
    if extract_end > extract_start
        frame = Extract part: extract_start, extract_end, "rectangular", 1.0, "no"
        
        # Get actual frame duration
        selectObject: frame
        actual_dur = Get total duration
        
        # Pad if necessary to reach window_size
        if actual_dur < window_size
            # Need to pad
            if t_start < 0
                # Pad at start
                pad_dur = 0 - t_start
                if pad_dur > 0.001
                    pad = Create Sound from formula: "pad", 1, 0, pad_dur, fs, "0"
                    plusObject: frame
                    temp = Concatenate
                    removeObject: pad, frame
                    frame = temp
                endif
            endif
            
            selectObject: frame
            actual_dur = Get total duration
            
            if actual_dur < window_size
                # Pad at end
                pad_dur = window_size - actual_dur
                if pad_dur > 0.001
                    pad = Create Sound from formula: "pad", 1, 0, pad_dur, fs, "0"
                    selectObject: frame
                    plusObject: pad
                    temp = Concatenate
                    removeObject: pad, frame
                    frame = temp
                endif
            endif
        endif
        
        # Apply Hanning window
        selectObject: frame
        Multiply by window: "Hanning"
        
        # Convert to spectrum
        selectObject: frame
        spectrum = To Spectrum: "yes"
        
        # Get spectrum properties
        selectObject: spectrum
        n_bins = Get number of bins
        
        # Randomize phases bin by bin
        for i_bin from 1 to n_bins
            selectObject: spectrum
            re = Get real value in bin: i_bin
            im = Get imaginary value in bin: i_bin
            mag = sqrt(re * re + im * im)
            
            # Randomize phase (except DC and Nyquist)
            if i_bin = 1 or i_bin = n_bins
                phase = 0
            else
                phase = randomUniform(-pi, pi)
            endif
            
            # Set new values
            new_re = mag * cos(phase)
            new_im = mag * sin(phase)
            
            selectObject: spectrum
            Set real value in bin: i_bin, new_re
            Set imaginary value in bin: i_bin, new_im
        endfor
        
        # Convert back to sound
        selectObject: spectrum
        processed_sound = To Sound
        
        # Apply window again
        selectObject: processed_sound
        Multiply by window: "Hanning"
        
        # Manual overlap-add: read samples and add to output
        selectObject: processed_sound
        proc_n_samples = Get number of samples
        
        # Calculate output position in samples
        t_out = iframe * hop_out
        out_start_sample = round(t_out * fs) + 1
        
        selectObject: output_sound
        out_n_samples = Get number of samples
        
        # Add each sample to output
        for i_sample from 1 to proc_n_samples
            out_sample_index = out_start_sample + i_sample - 1
            
            if out_sample_index >= 1 and out_sample_index <= out_n_samples
                # Get value from processed sound
                selectObject: processed_sound
                add_value = Get value at sample number: 1, i_sample
                
                # Get current value from output
                selectObject: output_sound
                current_value = Get value at sample number: 1, out_sample_index
                
                # Add and set
                new_value = current_value + add_value
                Set value at sample number: 1, out_sample_index, new_value
            endif
        endfor
        
        # Clean up frame processing objects
        removeObject: frame, spectrum, processed_sound
    endif
endfor

# Finalize
selectObject: output_sound
Rename: sound_name$ + "_paulstretch_" + string$(stretch_factor) + "x"
Scale peak: 0.99
Play

# Clean up mono conversion if it was created
if n_channels > 1
    removeObject: sound
endif

appendInfoLine: ""
appendInfoLine: "Done!"
appendInfoLine: "Kept: Original sound + stretched result"

# Select both original and result for user
selectObject: original_sound
plusObject: output_sound