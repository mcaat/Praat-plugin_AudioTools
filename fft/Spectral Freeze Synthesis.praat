# ============================================================
# Praat AudioTools - Spectral Freeze Synthesis.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral Freeze Synthesis
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Spectral Freeze with Decay and Glissando

form Spectral Freeze with Decay & Gliss
    optionmenu Preset: 1
        option Custom (manual settings below)
        option Freeze (classic hold)
        option Gentle decay (slow fade)
        option Rising shimmer (decay + up)
        option Falling shimmer (decay + down)
        option Ghostly rise (strong decay + up)
        option Deep dive (strong decay + down)
        option Crystalline (minimal decay + micro-up)
        option Submerge (minimal decay + micro-down)
    
    comment ─────────────────────────────────────
    comment Manual settings (for Custom preset only):
    comment Analysis parameters
    positive Frame_step_(ms) 10
    positive Analysis_window_(ms) 35
    positive Max_frequency_(Hz) 8000
    integer Top_partials_(K) 10
    
    comment Spectral transformation
    positive Decay_factor_(d) 0.2
    real Glissando_(octaves_per_sec) 0.1
    
    comment Output
    positive Tail_duration_(seconds) 2
    boolean Create_stereo_output 1
    positive Stereo_delay_(ms) 8
    real Target_peak_(dB) -1
    boolean Apply_light_filtering 0
    boolean Play_after_processing 1
endform

# Apply preset values
if preset = 2
    # Freeze (classic hold)
    decay_factor = 0.999
    glissando = 0
elsif preset = 3
    # Gentle decay (slow fade)
    decay_factor = 0.5
    glissando = 0
elsif preset = 4
    # Rising shimmer (decay + up)
    decay_factor = 0.3
    glissando = 0.15
elsif preset = 5
    # Falling shimmer (decay + down)
    decay_factor = 0.3
    glissando = -0.15
elsif preset = 6
    # Ghostly rise (strong decay + up)
    decay_factor = 0.15
    glissando = 0.3
elsif preset = 7
    # Deep dive (strong decay + down)
    decay_factor = 0.15
    glissando = -0.3
elsif preset = 8
    # Crystalline (minimal decay + micro-up)
    decay_factor = 0.9
    glissando = 0.05
elsif preset = 9
    # Submerge (minimal decay + micro-down)
    decay_factor = 0.9
    glissando = -0.05
endif

# Convert parameters
dt = frame_step / 1000
windowDuration = analysis_window / 1000
d_frame = decay_factor ^ dt
gliss_ratio = 2 ^ (glissando * dt)
k = top_partials
stereoDelaySeconds = stereo_delay / 1000

writeInfoLine: "Spectral Freeze Processing..."
appendInfoLine: "Preset: ", preset$
appendInfoLine: "d_frame = ", fixed$(d_frame, 4)
appendInfoLine: "gliss_ratio = ", fixed$(gliss_ratio, 6)

# Get input sound
sound = selected("Sound")
selectObject: sound
soundName$ = selected$("Sound")
originalDuration = Get total duration
sampleRate = Get sampling frequency
channels = Get number of channels

# Convert to mono if stereo
if channels = 2
    appendInfoLine: "Converting stereo to mono for processing..."
    Convert to mono
    monoSound = selected("Sound")
else
    monoSound = sound
endif

selectObject: monoSound

# Add silent tail
appendInfoLine: "Adding ", tail_duration, "s tail..."
silentTail = Create Sound from formula: "silent_tail", 1, 0, tail_duration, sampleRate, "0"

selectObject: monoSound
plusObject: silentTail
Concatenate
extendedSound = selected("Sound")
Rename: soundName$ + "_extended"

selectObject: extendedSound
duration = Get total duration
numberOfFrames = floor(duration / dt)

appendInfoLine: "Total duration with tail: ", fixed$(duration, 2), " s"
appendInfoLine: "Frames to process: ", numberOfFrames

# Initialize accumulator arrays
for i to k
    a_freq_'i' = 0
    a_amp_'i' = 0
endfor

# Main analysis loop - store per-frame snapshots
for frame to numberOfFrames
    # Progress indicator
    if frame mod 50 = 0
        appendInfoLine: "Analyzing frame ", frame, "/", numberOfFrames
    endif
    
    # Time markers for this frame
    tCenter = (frame - 0.5) * dt
    tStart = tCenter - windowDuration/2
    tEnd = tCenter + windowDuration/2
    
    # Extract windowed segment
    selectObject: extendedSound
    if tStart >= 0 and tEnd <= duration
        Extract part: tStart, tEnd, "Hanning", 1, "no"
        segment = selected("Sound")
        
        # Get spectrum of this segment
        To Spectrum: "yes"
        segSpectrum = selected("Spectrum")
        
        # Find top K spectral peaks
        nBins = Get number of bins
        binWidth = Get bin width
        maxBin = min(nBins, floor(max_frequency / binWidth) + 1)
        
        # Collect all spectral magnitudes up to maxFreq
        for bin to maxBin
            freq = (bin - 1) * binWidth
            re = Get real value in bin: bin
            im = Get imaginary value in bin: bin
            mag_'bin' = sqrt(re^2 + im^2)
            freq_bin_'bin' = freq
        endfor
        
        # Find K largest peaks
        for i to k
            maxMag = 0
            maxBinIdx = 0
            for bin to maxBin
                if mag_'bin' > maxMag
                    maxMag = mag_'bin'
                    maxBinIdx = bin
                endif
            endfor
            
            if maxBinIdx > 0
                peak_freq_'i' = freq_bin_'maxBinIdx'
                peak_amp_'i' = mag_'maxBinIdx'
                # Zero out this peak and neighbors
                for bin from max(1, maxBinIdx-2) to min(maxBin, maxBinIdx+2)
                    mag_'bin' = 0
                endfor
            else
                peak_freq_'i' = 0
                peak_amp_'i' = 0
            endif
        endfor
        
        # Clean up
        selectObject: segSpectrum
        Remove
        selectObject: segment
        Remove
        
        # Update accumulators
        for i to k
            # Apply decay
            a_amp_'i' = a_amp_'i' * d_frame
            
            # Apply glissando
            if a_freq_'i' > 0
                a_freq_'i' = a_freq_'i' * gliss_ratio
                if a_freq_'i' > max_frequency
                    a_freq_'i' = max_frequency
                endif
            endif
            
            # Replace if current peak is louder
            if peak_amp_'i' >= a_amp_'i' and peak_freq_'i' > 0
                a_amp_'i' = peak_amp_'i'
                a_freq_'i' = peak_freq_'i'
            endif
            
            # STORE SNAPSHOT for this frame
            f_freq_'frame'_'i' = a_freq_'i'
            f_amp_'frame'_'i' = a_amp_'i'
        endfor
    else
        # Out of bounds - store zeros
        for i to k
            f_freq_'frame'_'i' = 0
            f_amp_'frame'_'i' = 0
        endfor
    endif
endfor

appendInfoLine: "Synthesizing..."

# Determine number of output channels
if create_stereo_output
    numChannels = 2
else
    numChannels = 1
endif

# Create output sound
output = Create Sound from formula: soundName$ + "_freeze", numChannels, 0, duration, sampleRate, "0"

# Resynthesize using stored per-frame values
for frame to numberOfFrames
    if frame mod 50 = 0
        appendInfoLine: "Synthesizing frame ", frame, "/", numberOfFrames
    endif
    
    tFrameStart = (frame - 1) * dt
    tFrameEnd = frame * dt
    
    # Add each partial for this frame
    for i to k
        freq_val = f_freq_'frame'_'i'
        amp_val = f_amp_'frame'_'i'
        
        if freq_val > 0 and amp_val > 0
            selectObject: output
            # Channel 1 (left) - original
            Formula (part): tFrameStart, tFrameEnd, 1, 1, 
                ... ~self + amp_val * sin(2*pi*freq_val*x) * (0.5 - 0.5*cos(2*pi*(x-tFrameStart)/dt))
            
            # Channel 2 (right) - if stereo, add with delay
            if create_stereo_output
                # Right channel gets delayed version
                delayTime = stereoDelaySeconds
                Formula (part): tFrameStart, tFrameEnd, 2, 2, 
                    ... ~self + amp_val * sin(2*pi*freq_val*(x-delayTime)) * (0.5 - 0.5*cos(2*pi*((x-delayTime)-tFrameStart)/dt))
            endif
        endif
    endfor
endfor

# Apply subtle filtering difference if stereo
if create_stereo_output
    appendInfoLine: "Applying stereo differentiation..."
    selectObject: output
    # Subtle HF boost on right channel only
    Formula (part): 0, duration, 2, 2, "self + 0.08*(self - self(x - 1/sampleRate))"
    Formula (part): 0, duration, 2, 2, "self * 0.99"
endif

# Optional filtering
if apply_light_filtering
    appendInfoLine: "Applying light filtering..."
    selectObject: output
    Filter (pass Hann band): 20, max_frequency, 100
endif

appendInfoLine: "Normalizing output..."

# Normalize output
selectObject: output
Scale peak: 10^(target_peak / 20)

# Cleanup intermediate objects
if channels = 2 and monoSound != sound
    selectObject: monoSound
    Remove
endif
selectObject: silentTail
plusObject: extendedSound
Remove

appendInfoLine: "Done!"

# Select output and optionally play
selectObject: output
if play_after_processing
    Play
endif