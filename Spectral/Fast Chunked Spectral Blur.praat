# ============================================================
# Praat AudioTools - Fast Chunked Spectral Blur.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Fast Chunked Spectral Blur (v4.0 - Sound Design Edition)
# Optimized for Praat 6.x
# Adds Variable Window Sizes for distinct sonic textures

form Spectral Blur Texture
    comment Select a Vibe:
    optionmenu Preset: 1
        option 1. Standard Blur (Clean)
        option 2. Ethereal Pad (Drone-like)
        option 3. Underwater (Muffled)
        option 4. Robotic / Metallic (Gritty)
        option 5. Rhythmic Glitch (Stutter)
    
    comment Advanced Overrides (Ignored if using presets):
    boolean Override_settings 0
    positive Blur_radius 3.0
    positive Window_size_sec 0.025
    positive Chunk_size_sec 2.0
endform

# --- PRESET LOGIC ---
# We set 3 variables: Radius (smoothness), Window (texture), Chunk (continuity)

if override_settings = 0
    if preset = 1 ; Standard Blur
        blur_radius = 3.0
        window_size = 0.025
        chunk_size = 2.0
    
    elsif preset = 2 ; Ethereal Pad
        # Long window = High frequency resolution. 
        # Great for turning noise into chords/drones.
        blur_radius = 10.0
        window_size = 0.08
        chunk_size = 5.0  ; Long chunks for continuity
        
    elsif preset = 3 ; Underwater
        # Moderate window, massive blur.
        # Smears everything together.
        blur_radius = 20.0
        window_size = 0.03
        chunk_size = 3.0
        
    elsif preset = 4 ; Robotic / Metallic
        # Very short window = High time resolution, bad freq resolution.
        # Sounds like a vocoder or sci-fi scanner.
        blur_radius = 2.0
        window_size = 0.008 
        chunk_size = 1.0
        
    elsif preset = 5 ; Rhythmic Glitch
        # Short chunks create audible seams (clicks/rhythms)
        blur_radius = 5.0
        window_size = 0.02
        chunk_size = 0.25 ; Very short chunks create a "chopper" effect
    endif
else
    # User overrides
    blur_radius = blur_radius
    window_size = window_size_sec
    chunk_size = chunk_size_sec
endif

# --- STANDARD PROCESSING BELOW ---

if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object"
endif

sound_id = selected("Sound")
sound_name$ = selected$("Sound")
fs = Get sampling frequency
total_samples = Get number of samples

# Calculation parameters
chunk_samples = round(chunk_size * fs)
num_chunks = ceiling(total_samples / chunk_samples)

writeInfoLine: "Fast Spectral Blur: ", preset$
appendInfoLine: "Window: ", fixed$(window_size, 4), "s | Radius: ", blur_radius

chunk_ids# = zero# (num_chunks)

for i from 1 to num_chunks
    selectObject: sound_id
    
    start_sample = (i - 1) * chunk_samples + 1
    end_sample = min(start_sample + chunk_samples - 1, total_samples)
    
    start_time = (start_sample - 1) / fs
    end_time = (end_sample - 1) / fs
    
    if end_time > start_time
        chunk = Extract part: start_time, end_time, "rectangular", 1.0, "no"
        
        # 1. To Spectrogram (Using Dynamic Window Size)
        # We adjust the max freq and time step based on window size for stability
        time_step = window_size / 8
        To Spectrogram: window_size, 5000, time_step, 20, "Gaussian"
        spec = selected("Spectrogram")
        
        # 2. Vectorized Blur
        if blur_radius >= 1
            loop_count = round(blur_radius)
            for k from 1 to loop_count
                Formula: "if row > 1 and row < nrow then (self[row-1,col] + 2*self + self[row+1,col])/4 else self fi"
            endfor
        endif
        
        # 3. Back to Sound
        To Sound: fs
        processed_chunk = selected("Sound")
        chunk_ids#[i] = processed_chunk
        
        removeObject: chunk, spec
        
        if i mod 5 = 0
            perc = i / num_chunks * 100
            appendInfoLine: "Progress: ", fixed$(perc, 1), "%"
        endif
    endif
endfor

# Finalize
selectObject: chunk_ids#[1]
for i from 2 to num_chunks
    if chunk_ids#[i] > 0
        plusObject: chunk_ids#[i]
    endif
endfor

Concatenate
result_id = selected("Sound")
Rename: sound_name$ + "_Blur_" + string$(preset)
Scale peak: 0.99

for i from 1 to num_chunks
    if chunk_ids#[i] > 0
        removeObject: chunk_ids#[i]
    endif
endfor
Play