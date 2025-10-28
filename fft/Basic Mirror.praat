# ============================================================
# Praat AudioTools - Basic Mirror.praat  (fixed to keep output selected)
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

form Spectral Mirroring
    comment This script mirrors the lower half of the spectrum
    comment WARNING: This process can have long runtime on long files
    comment due to FFT calculations
    comment Spectrum parameters:
    boolean fast_fourier yes
    comment Mirroring parameters:
    optionmenu Preset: 1
        option Mild mirroring (cutoff = nyquist/4)
        option Moderate mirroring (cutoff = nyquist/2)
        option Strong mirroring (cutoff = nyquist/8)
        option Custom cutoff
    positive cutoff_divisor 2
    comment (2 = mirror below nyquist/2, 4 = mirror below nyquist/4)
    comment Output options:
    positive scale_peak 0.9
    boolean play_after_processing 1
    boolean keep_intermediate_objects 0
endform

# Apply preset values
if preset = 1
    cutoff_divisor = 4
elsif preset = 2
    cutoff_divisor = 2
elsif preset = 3
    cutoff_divisor = 8
endif
# If preset = 4 (Custom), use the user-entered cutoff_divisor value

# --- Preconditions: need a selected Sound ---
if numberOfSelected ("Sound") <> 1
    exit ("Please select exactly ONE Sound object first.")
endif

# Remember original Sound name (for output naming)
originalName$ = selected$ ("Sound")

# Get sampling frequency while Sound is selected
sampling_rate = Get sampling frequency
nyquist = sampling_rate / 2

# Convert to Spectrum (store its object ID so we can clean up safely)
spectrumID = To Spectrum: fast_fourier

# Compute cutoff frequency (in Hz)
cutoff = nyquist / cutoff_divisor

# Apply spectral mirroring formula (operates on the selected Spectrum)
# NOTE: This uses the user's original formula as provided.
Formula: "if col < cutoff then self[1,col] + self[1,nyquist-col] else self[1,col] fi"

# Convert back to Sound; remember the new Sound's ID so we can reselect it later
To Sound
resultID = selected ("Sound")

# Rename the result
outName$ = originalName$ + "_spectral_mirrored"
Rename: outName$

# Scale to peak
Scale peak: scale_peak

# Optionally play
if play_after_processing
    Play
endif

# Clean up intermediate Spectrum unless requested otherwise
if not keep_intermediate_objects
    selectObject: spectrumID
    Remove
endif

# --- Ensure the output Sound is selected when we finish ---
selectObject: resultID