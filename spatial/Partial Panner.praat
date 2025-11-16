# ============================================================
# Praat AudioTools - Partial Panner.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#  Harmonic Spray / Partial Panner (Mono → Stereo) - Enhanced
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Harmonic Spray / Partial Panner (Mono → Stereo) 
# Pans different frequency bands across the stereo field
# Low frequencies → Left, High frequencies → Right

form Harmonic Spray / Partial Panner
    optionmenu Preset 1
        option Custom (edit below)
        option Subtle Widening
        option Standard Spread
        option Extreme Spray
        option Reverse (High→L / Low→R)
        option Dense Shimmer
        option Coarse Texture
    comment ─────────────────────────────────
    positive Number_of_bands 8
    comment Pan mapping: 0 = mono (center), 1 = full spread
    real Pan_width 0.8 (= 0.0 to 1.0)
    comment Bandwidth (fractional octave): 1/2 = half octave, 1/3 = third octave
    real Bandwidth_octaves 0.5 (= 0.25 to 2.0)
    comment LF protection (Hz): restrict panning below this frequency
    positive LF_protection_frequency 150
    comment Dry/Wet mix: 0 = all dry (original), 1 = all wet (processed)
    real Dry_wet_mix 1.0 (= 0.0 to 1.0)
endform

# Apply preset values (dry_wet_mix stays independent)
if preset = 2
    # Subtle Widening
    number_of_bands = 6
    pan_width = 0.5
    bandwidth_octaves = 0.5
elsif preset = 3
    # Standard Spread
    number_of_bands = 8
    pan_width = 0.8
    bandwidth_octaves = 0.5
elsif preset = 4
    # Extreme Spray
    number_of_bands = 16
    pan_width = 1.0
    bandwidth_octaves = 0.33
elsif preset = 5
    # Reverse (High→L / Low→R)
    number_of_bands = 10
    pan_width = -0.9
    bandwidth_octaves = 0.5
elsif preset = 6
    # Dense Shimmer
    number_of_bands = 20
    pan_width = 0.7
    bandwidth_octaves = 0.33
elsif preset = 7
    # Coarse Texture
    number_of_bands = 4
    pan_width = 1.0
    bandwidth_octaves = 1.0
endif

# Get selected sound
soundID = selected("Sound")
soundName$ = selected$("Sound")
duration = Get total duration
samplingFreq = Get sampling frequency
numberOfChannels = Get number of channels

# Convert to mono if stereo (keep original)
if numberOfChannels > 1
    select soundID
    monoID = Convert to mono
else
    select soundID
    monoID = Copy: "monotemporary"
endif

# Get frequency range
minFreq = 80
maxFreq = min(samplingFreq / 2 * 0.95, 16000)

# Calculate frequency bands (logarithmic spacing)
for i from 1 to number_of_bands
    band_center[i] = minFreq * (maxFreq / minFreq) ^ ((i - 0.5) / number_of_bands)
endfor

# Create left and right accumulator channels (start with silence)
select monoID
left_accum = Create Sound from formula: "leftaccum", 1, 0, duration, samplingFreq, "0"
right_accum = Create Sound from formula: "rightaccum", 1, 0, duration, samplingFreq, "0"

# Process each band
for i from 1 to number_of_bands
    # ENHANCEMENT 1: Proportional bandwidth (Q-based)
    # Calculate bandwidth in Hz based on fractional octave and center frequency
    bandwidth_multiplier = 2 ^ bandwidth_octaves
    freq_low = band_center[i] / sqrt(bandwidth_multiplier)
    freq_high = band_center[i] * sqrt(bandwidth_multiplier)
    smoothing_hz = (freq_high - freq_low) / 6
    
    # ENHANCEMENT 3: Nonlinear pan mapping (S-curve with tanh)
    # Normalized position: 0 (lowest band) to 1 (highest band)
    normalized_pos = (i - 1) / (number_of_bands - 1)
    # Apply S-curve: map through tanh for perceptually smoother distribution
    # tanh(3*x) where x is shifted to [-1,1] range
    s_curve_input = (normalized_pos * 2 - 1) * 2.5
    s_curve_output = tanh(s_curve_input)
    
    # ENHANCEMENT 2: Frequency-dependent pan width
    # Reduce panning at low frequencies, full width at high frequencies
    freq_normalized = log10(band_center[i] / minFreq) / log10(maxFreq / minFreq)
    # Curve: starts at 0.3 for lowest freq, reaches 1.0 at high freq
    freq_dependent_scale = 0.3 + 0.7 * freq_normalized ^ 0.7
    
    # ENHANCEMENT 4: Protect mono (restrict LF panning)
    if band_center[i] < lF_protection_frequency
        # Scale down panning for bass frequencies
        lf_scale = (band_center[i] / lF_protection_frequency) ^ 2
        freq_dependent_scale = freq_dependent_scale * (0.2 + 0.8 * lf_scale)
    endif
    
    # Combine all pan adjustments
    effective_pan_width = pan_width * freq_dependent_scale
    pan_position = s_curve_output * effective_pan_width
    
    # Calculate left and right gains (constant power panning)
    pan_angle = (pan_position + 1) / 2 * pi / 2
    gain_left = cos(pan_angle)
    gain_right = sin(pan_angle)
    
    # Create bandpass filter with proportional bandwidth
    select monoID
    filtered = Filter (pass Hann band): freq_low, freq_high, smoothing_hz
    
    # Create left contribution (copy first, then multiply)
    select filtered
    left_contrib = Copy: "lefttemp"
    Multiply: gain_left
    
    # Add to left accumulator using Combine to stereo → Convert to mono
    select left_accum
    plus left_contrib
    temp_stereo = Combine to stereo
    temp_mono = Convert to mono
    select left_accum
    Remove
    left_accum = temp_mono
    select temp_stereo
    Remove
    select left_contrib
    Remove
    
    # Create right contribution (copy from original filtered, then multiply)
    select filtered
    right_contrib = Copy: "righttemp"
    Multiply: gain_right
    
    # Add to right accumulator using Combine to stereo → Convert to mono
    select right_accum
    plus right_contrib
    temp_stereo = Combine to stereo
    temp_mono = Convert to mono
    select right_accum
    Remove
    right_accum = temp_mono
    select temp_stereo
    Remove
    select right_contrib
    Remove
    
    # Clean up filtered band
    select filtered
    Remove
endfor

# Combine left and right into stereo (WET signal)
select left_accum
plus right_accum
wet_stereo = Combine to stereo

# ENHANCEMENT 5: Master pan law trim (-3.5 dB compensation)
select wet_stereo
Formula: "self * 10^(-3.5/20)"

# Scale wet by dry_wet_mix
select wet_stereo
Multiply: dry_wet_mix

# Create DRY signal (mono centered in stereo)
select monoID
dry_left = Copy: "dryleft"
dry_right = Copy: "dryright"
select dry_left
plus dry_right
dry_stereo = Combine to stereo

# Scale dry by (1 - dry_wet_mix)
select dry_stereo
Multiply: (1 - dry_wet_mix)

# Get names for formula reference
select wet_stereo
wet_name$ = selected$("Sound")
select dry_stereo
dry_name$ = selected$("Sound")

# Create final output by copying wet and adding dry to it
select wet_stereo
final_output = Copy: soundName$ + "_spray"
Formula: "self + Sound_'dry_name$'[]"

# Normalize to prevent clipping
select final_output
Scale peak: 0.99
Play

# Clean up temp objects
select left_accum
plus right_accum
plus monoID
plus wet_stereo
plus dry_stereo
plus dry_left
plus dry_right
Remove

# Info
writeInfoLine: "Harmonic Spray / Partial Panner Complete (Enhanced)"
appendInfoLine: "Preset: ", preset$
appendInfoLine: "Bands: ", number_of_bands
appendInfoLine: "Pan width: ", pan_width
appendInfoLine: "Bandwidth: ", bandwidth_octaves, " octaves"
appendInfoLine: "LF protection: ", lF_protection_frequency, " Hz"
appendInfoLine: "Dry/Wet mix: ", dry_wet_mix * 100, "%"
appendInfoLine: "Frequency range: ", fixed$(minFreq, 0), " - ", fixed$(maxFreq, 0), " Hz"
appendInfoLine: ""
appendInfoLine: "✓ Q-based proportional bandwidth"
appendInfoLine: "✓ Frequency-dependent pan width"
appendInfoLine: "✓ S-curve spatial mapping"
appendInfoLine: "✓ Mono-safe bass protection"
appendInfoLine: "✓ Master pan law compensation (-3.5dB)"
appendInfoLine: "✓ Dry/Wet mix control"