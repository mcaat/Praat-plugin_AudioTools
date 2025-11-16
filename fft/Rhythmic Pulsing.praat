# ============================================================
# Praat AudioTools - Rhythmic Pulsing.praat
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

form Rhythmic Pulsing Spectral Effect (Optimized)
    comment This script applies rhythmic pulsing with high-frequency rolloff
    comment === OPTIMIZATION SETTINGS ===
    boolean use_downsampling 1
    comment (Uncheck to preserve original sample rate)
    positive processing_sample_rate 32000
    comment (32000 Hz = good balance of speed/quality)
    positive chunk_duration 30
    comment (Process in chunks of N seconds)
    positive overlap_duration 2
    comment (Overlap between chunks - prevents artifacts)
    boolean use_power_of_two_padding 1
    comment (Power-of-2 padding speeds up FFT)
    comment Note: Stereo files are automatically converted to mono
    comment === PULSING PARAMETERS ===
    boolean fast_fourier yes
    optionmenu preset: 1
        option Default
        option Deep Pulsing
        option Subtle Pulsing
        option Frequent Pulses
        option Steep Rolloff
    positive frequency_cutoff 9000
    comment (transition point for high-frequency rolloff)
    positive pulse_center 0.5
    positive pulse_depth 0.5
    positive pulse_frequency_divisor 333
    comment (controls pulse spacing: higher = more frequent pulses)
    comment === HIGH-FREQUENCY ROLLOFF PARAMETERS ===
    positive rolloff_exponent 2
    comment (controls steepness of high-frequency attenuation)
    comment === OUTPUT OPTIONS ===
    positive scale_peak 0.86
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

# Apply preset values
if preset = 2
    pulse_depth = 0.8
elsif preset = 3
    pulse_depth = 0.2
elsif preset = 4
    pulse_frequency_divisor = 200
elsif preset = 5
    rolloff_exponent = 4
endif

# Check selection
if numberOfSelected ("Sound") <> 1
    exit Please select exactly ONE Sound object first.
endif

# Get original info
originalID = selected ("Sound")
originalName$ = selected$ ("Sound")
original_sr = Get sampling frequency
original_duration = Get total duration
num_channels = Get number of channels

writeInfoLine: "=== RHYTHMIC PULSING OPTIMIZATION ==="
appendInfoLine: "Original duration: ", original_duration, " seconds"
appendInfoLine: "Original rate: ", original_sr, " Hz"
appendInfoLine: "Channels: ", num_channels

# STEP 1: Convert to mono (always, since formula only processes channel 1)
workingID = originalID
converted_to_mono = 0
if num_channels > 1
    selectObject: originalID
    monoID = Convert to mono
    workingID = monoID
    converted_to_mono = 1
    appendInfoLine: "✓ Converted to mono (required for spectral processing)"
endif

# STEP 2: Downsample if requested
selectObject: workingID
current_sr = Get sampling frequency
did_downsample = 0

if use_downsampling and processing_sample_rate < current_sr
    downsampledID = Resample: processing_sample_rate, 50
    workingID = downsampledID
    did_downsample = 1
    appendInfoLine: "✓ Downsampled to ", processing_sample_rate, " Hz"
else
    processing_sample_rate = current_sr
    if use_downsampling
        appendInfoLine: "→ Downsampling skipped (target rate >= original)"
    else
        appendInfoLine: "→ Using original sample rate (no downsampling)"
    endif
endif

# STEP 3: Calculate chunk parameters
selectObject: workingID
total_duration = Get total duration

# Adjust cutoff if it exceeds Nyquist
nyquist = processing_sample_rate / 2
if frequency_cutoff > nyquist
    frequency_cutoff = nyquist
    appendInfoLine: "→ Cutoff adjusted to Nyquist: ", frequency_cutoff, " Hz"
endif

# Calculate number of chunks with overlap
hop_duration = chunk_duration - overlap_duration
num_chunks = floor ((total_duration - overlap_duration) / hop_duration)
if (total_duration - overlap_duration) - (num_chunks * hop_duration) > 0
    num_chunks = num_chunks + 1
endif

appendInfoLine: "✓ Processing ", num_chunks, " chunks with ", overlap_duration, "s overlap"
appendInfoLine: "  Frequency cutoff: ", frequency_cutoff, " Hz"
appendInfoLine: "  Pulse center: ", pulse_center
appendInfoLine: "  Pulse depth: ", pulse_depth
appendInfoLine: "  Pulse frequency divisor: ", pulse_frequency_divisor
appendInfoLine: "  Rolloff exponent: ", rolloff_exponent

# STEP 4: Process each chunk with overlap
for i to num_chunks
    # Calculate chunk boundaries with overlap
    chunk_start = (i - 1) * hop_duration
    chunk_end = chunk_start + chunk_duration
    
    # Adjust for last chunk
    if chunk_end > total_duration
        chunk_end = total_duration
    endif
    
    # Ensure first chunk starts at 0
    if i = 1
        chunk_start = 0
    endif
    
    appendInfo: "  Chunk ", i, "/", num_chunks, "..."
    
    # Extract chunk
    selectObject: workingID
    chunkID = Extract part: chunk_start, chunk_end, "rectangular", 1.0, "no"
    
    # Get chunk info
    chunk_dur = Get total duration
    chunk_samples = Get number of samples
    original_chunk_dur = chunk_dur
    
    # Apply power-of-2 padding if requested
    if use_power_of_two_padding
        # Find next power of 2
        test_samples = 2
        while test_samples < chunk_samples
            test_samples = test_samples * 2
        endwhile
        padded_samples = test_samples
        
        # Only pad if necessary
        if padded_samples > chunk_samples
            padding_samples = padded_samples - chunk_samples
            padding_duration = padding_samples / processing_sample_rate
            
            # Create mono silence for padding
            selectObject: chunkID
            silenceID = Create Sound from formula: "silence", 1, 0, padding_duration, processing_sample_rate, "0"
            
            # Concatenate chunk + silence
            selectObject: chunkID, silenceID
            paddedID = Concatenate
            removeObject: chunkID, silenceID
            chunkID = paddedID
        endif
    endif
    
    # Convert to Spectrum
    selectObject: chunkID
    spectrumID = To Spectrum: fast_fourier
    
    # Apply rhythmic pulsing with high-frequency rolloff (using explicit string concatenation)
    formula$ = "if col < " + string$(frequency_cutoff) + " then self[1, col] * (" + string$(pulse_center) + " + " + string$(pulse_depth) + " * cos(col / " + string$(pulse_frequency_divisor) + ")) else self[1, col] * (" + string$(pulse_center) + " + " + string$(pulse_depth) + " * cos(col / " + string$(pulse_frequency_divisor) + ")) * (col / " + string$(frequency_cutoff) + ") ^ (-" + string$(rolloff_exponent) + ") fi"
    Formula: formula$
    
    # Convert back to Sound
    processedID = To Sound
    
    # Trim padding if it was added
    if use_power_of_two_padding and padded_samples > chunk_samples
        selectObject: processedID
        trimmedID = Extract part: 0, original_chunk_dur, "rectangular", 1.0, "no"
        removeObject: processedID
        processedID = trimmedID
    endif
    
    # Apply fade in/out for overlap-add (except edges)
    selectObject: processedID
    actual_chunk_dur = Get total duration
    
    # Fade out at end (except last chunk)
    if i < num_chunks
        fade_start = actual_chunk_dur - overlap_duration
        if fade_start > 0
            Formula (part): fade_start, actual_chunk_dur, 1, 1, "self * (1 - (x - 'fade_start') / 'overlap_duration')"
        endif
    endif
    
    # Fade in at start (except first chunk)
    if i > 1
        fade_end = overlap_duration
        if fade_end < actual_chunk_dur
            Formula (part): 0, fade_end, 1, 1, "self * (x / 'overlap_duration')"
        endif
    endif
    
    # Store chunk
    chunk'i' = processedID
    
    # Cleanup
    removeObject: spectrumID
    if chunkID <> processedID
        removeObject: chunkID
    endif
    
    appendInfoLine: " done"
endfor

# STEP 5: Mix overlapping chunks
appendInfo: "✓ Mixing overlapping chunks..."

# Start with first chunk
selectObject: chunk1
first_dur = Get total duration
resultID = Copy: "temp_result"

# Mix in remaining chunks
for i from 2 to num_chunks
    selectObject: chunk'i'
    chunk_dur = Get total duration
    
    # Position where this chunk should start
    mix_position = (i - 1) * hop_duration
    
    # Mix this chunk into the result
    selectObject: resultID
    Formula (part): mix_position, mix_position + chunk_dur, 1, 1, "self + object[chunk'i', x - 'mix_position']"
endfor

appendInfoLine: " done"

# Clean up chunks
for i to num_chunks
    removeObject: chunk'i'
endfor

# STEP 6: Resample back if needed
selectObject: resultID
if did_downsample
    appendInfo: "✓ Resampling to original ", original_sr, " Hz..."
    resampledID = Resample: original_sr, 50
    removeObject: resultID
    resultID = resampledID
    appendInfoLine: " done"
endif

# STEP 7: Finalize
selectObject: resultID
outName$ = originalName$ + "_rhythmic_pulsing"
Rename: outName$
Scale peak: scale_peak

if play_after_processing
    Play
endif

appendInfoLine: "✓ Output: ", outName$
appendInfoLine: "=== COMPLETE ==="

# Cleanup intermediate objects
if not keep_intermediate_objects
    if converted_to_mono
        removeObject: monoID
    endif
    if did_downsample
        removeObject: downsampledID
    endif
endif

# Select result
selectObject: resultID