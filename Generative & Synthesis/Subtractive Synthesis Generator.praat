# ============================================================
# Praat AudioTools - Subtractive Synthesis Generator.praat
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

form Subtractive Synthesis Generator
    optionmenu Waveform: 1
        option Sawtooth
        option Square
        option Pulse
        option Triangle
        option Dual Saw
        option Super Saw
    positive Duration_(s) 3.0
    positive Frequency_(Hz) 220
    real Pulse_width_(0.1-0.9) 0.3
    optionmenu Filter_type: 2
        option No Filter
        option Low Pass 12dB
        option Low Pass 24dB
        option High Pass
        option Band Pass
        option Notch
    positive Cutoff_freq_(Hz) 1000
    real Resonance_(0-1) 0.3
    optionmenu Filter_envelope: 2
        option No Envelope
        option Short Sweep
        option Long Sweep
        option Attack Emphasis
        option Decay Sweep
    real Envelope_amount_(0-1) 0.7
    optionmenu Amplitude_envelope: 2
        option Percussive
        option Sustained
        option Slow Attack
        option Pluck
        option Gate
    real Volume 0.8
endform

sampling_frequency = 44100

# Create harmonically rich source waveform
if waveform = 1
    # Sawtooth - rich in harmonics
    sound = Create Sound from formula: "Sawtooth", 1, 0, duration, sampling_frequency,
    ... "0.9 * (2*(frequency*x - floor(frequency*x + 0.5)))"
    
elsif waveform = 2
    # Square - odd harmonics
    sound = Create Sound from formula: "Square", 1, 0, duration, sampling_frequency,
    ... "0.9 * if sin(2*pi*frequency*x) > 0 then 1 else -1 fi"
    
elsif waveform = 3
    # Pulse - variable spectrum based on pulse width
    sound = Create Sound from formula: "Pulse", 1, 0, duration, sampling_frequency,
    ... "0.9 * if (frequency*x - floor(frequency*x)) < pulse_width then 1 else -1 fi"
    
elsif waveform = 4
    # Triangle - fewer harmonics
    sound = Create Sound from formula: "Triangle", 1, 0, duration, sampling_frequency,
    ... "0.9 * (2/pi) * arcsin(sin(2*pi*frequency*x))"
    
elsif waveform = 5
    # Dual Saw - thicker sound
    detune = 7
    sound = Create Sound from formula: "DualSaw", 1, 0, duration, sampling_frequency,
    ... "0.6 * (2*(frequency*x - floor(frequency*x + 0.5)) + 2*((frequency+detune)*x - floor((frequency+detune)*x + 0.5)))"
    
elsif waveform = 6
    # Super Saw - very rich harmonics
    sound = Create Sound from formula: "SuperSaw", 1, 0, duration, sampling_frequency,
    ... "0.4 * (2*(frequency*x - floor(frequency*x + 0.5)) + 2*((frequency*1.005)*x - floor((frequency*1.005)*x + 0.5)) + 2*((frequency*0.995)*x - floor((frequency*0.995)*x + 0.5)) + 2*((frequency*1.01)*x - floor((frequency*1.01)*x + 0.5)) + 2*((frequency*0.99)*x - floor((frequency*0.99)*x + 0.5)))"
endif

selectObject: sound

# Apply FILTER ENVELOPE first (modulates cutoff over time)
if filter_envelope > 1
    if filter_envelope = 2
        # Short sweep - classic synth sound
        Formula: "self * (0.3 + 0.7 * exp(-x*8))"
        modulated_cutoff = cutoff_freq * (1 + envelope_amount * 2)
        
    elsif filter_envelope = 3
        # Long sweep - evolving texture
        Formula: "self * (0.5 + 0.5 * sin(2*pi*x*0.5))"
        modulated_cutoff = cutoff_freq * (1 + envelope_amount * 1.5)
        
    elsif filter_envelope = 4
        # Attack emphasis - bright attack, dark sustain
        Formula: "self * exp(-x*15)"
        modulated_cutoff = cutoff_freq * (1 + envelope_amount * 3)
        
    elsif filter_envelope = 5
        # Decay sweep - filter opens during decay
        Formula: "self * (1 - exp(-x*4))"
        modulated_cutoff = cutoff_freq * (1 + envelope_amount * 2)
    endif
else
    modulated_cutoff = cutoff_freq
endif

# Apply MAIN FILTER (this is the subtractive part!)
if filter_type = 2
    # Low Pass 12dB - gentle rolloff
    bandwidth = 100 + resonance * 200
    Filter (pass Hann band): 0, modulated_cutoff, bandwidth
    
elsif filter_type = 3
    # Low Pass 24dB - steeper rolloff (emulated)
    bandwidth = 50 + resonance * 100
    Filter (pass Hann band): 0, modulated_cutoff, bandwidth
    # Second pass for steeper slope
    Filter (pass Hann band): 0, modulated_cutoff, bandwidth * 1.2
    
elsif filter_type = 4
    # High Pass - remove low frequencies
    bandwidth = 100 + resonance * 200
    Filter (stop Hann band): 0, modulated_cutoff, bandwidth
    
elsif filter_type = 5
    # Band Pass - focus on specific frequency region
    bandwidth = 50 + (1 - resonance) * 150
    Filter (pass Hann band): modulated_cutoff - bandwidth/2, modulated_cutoff + bandwidth/2, bandwidth
    
elsif filter_type = 6
    # Notch - remove specific frequency
    bandwidth = 30 + resonance * 70
    Filter (stop Hann band): modulated_cutoff - bandwidth/2, modulated_cutoff + bandwidth/2, bandwidth
endif

# Apply AMPLITUDE ENVELOPE (after filtering)
selectObject: sound

if amplitude_envelope = 1
    # Percussive - quick decay
    Formula: "self * exp(-x*8)"
    
elsif amplitude_envelope = 2
    # Sustained - long decay
    Formula: "self * exp(-x*1.5)"
    
elsif amplitude_envelope = 3
    # Slow Attack - fade in
    attack_time = 0.5
    Formula: "self * if x < attack_time then x/attack_time else 1 fi"
    
elsif amplitude_envelope = 4
    # Pluck - very quick decay
    Formula: "self * exp(-x*20)"
    
elsif amplitude_envelope = 5
    # Gate - constant until end
    release_time = 0.1
    Formula: "self * if x < (duration - release_time) then 1 else (duration - x)/release_time fi"
endif

# Final volume adjustment
selectObject: sound
Formula: "self * volume"
Scale peak: 0.9

Play