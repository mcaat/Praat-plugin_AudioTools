# ============================================================
# Praat AudioTools - Raised-cosine band boost.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Filtering or timbral modification script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Spectral Band Filter
    comment ==== Presets ====
    optionmenu Preset: 1
        option Custom
        option Telephone (300-3400Hz)
        option AM Radio (500-4500Hz)
        option High Pass (above 2000Hz)
        option Low Pass (below 1000Hz)
        option Mid Scoop (remove 1000-3000Hz)
        option Presence Boost (2000-5000Hz)
    comment ==== Filter parameters ====
    positive center_frequency 4500
    comment (center frequency of the filter in Hz)
    positive bandwidth 1000
    comment (bandwidth of the filter in Hz)
    optionmenu Filter_type: 1
        option Band-pass (keep center band)
        option Band-stop (remove center band)
    comment ==== Output options ====
    positive scale_peak 0.99
    boolean play_after_processing 1
endform

# Check if a Sound is selected
if not selected("Sound")
    exitScript: "Please select a Sound object first."
endif

# Apply preset values if not Custom
if preset = 2
    # Telephone
    center_frequency = 1850
    bandwidth = 3100
    filter_type = 1
elsif preset = 3
    # AM Radio
    center_frequency = 2500
    bandwidth = 4000
    filter_type = 1
elsif preset = 4
    # High Pass
    center_frequency = 1000
    bandwidth = 2000
    filter_type = 2
elsif preset = 5
    # Low Pass
    center_frequency = 2000
    bandwidth = 2000
    filter_type = 2
elsif preset = 6
    # Mid Scoop
    center_frequency = 2000
    bandwidth = 2000
    filter_type = 2
elsif preset = 7
    # Presence Boost
    center_frequency = 3500
    bandwidth = 3000
    filter_type = 1
endif

# Get the name of the original sound
originalName$ = selected$("Sound")
originalID = selected("Sound")

# Copy the sound object
Copy: originalName$ + "_filtered"
soundCopyID = selected("Sound")

# Convert to Spectrum
To Spectrum: "yes"
spectrumID = selected("Spectrum")

# Calculate filter boundaries
low_freq = center_frequency - bandwidth / 2
high_freq = center_frequency + bandwidth / 2

# Apply spectral filtering based on filter type
if filter_type = 1
    # Band-pass: keep the band
    Formula: "if x >= 'low_freq' and x <= 'high_freq' then self * 0.5 * (1 + cos(pi * (x - 'center_frequency') / ('bandwidth' / 2))) else 0 fi"
else
    # Band-stop: remove the band
    Formula: "if x >= 'low_freq' and x <= 'high_freq' then 0 else self fi"
endif

# Convert back to Sound
To Sound
filteredSoundID = selected("Sound")

# Scale to peak
Scale peak: scale_peak

# Cleanup: remove intermediate objects
select spectrumID
Remove
select soundCopyID
Remove

# Select the filtered sound
select filteredSoundID

# Play if requested
if play_after_processing
    Play
endif

# Select original sound for reference
plus originalID