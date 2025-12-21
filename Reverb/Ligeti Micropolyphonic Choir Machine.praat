# ============================================================
# Praat AudioTools - Ligeti Micropolyphonic Choir Machine 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Ligeti Micropolyphonic Choir Machine
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Ligeti Micropolyphonic Choir Machine 
# Features: Formal Arcs, Gaussian Distributions, Stereo Asymmetry

form Ligeti Structural Choir
    comment Behavioral Presets
    optionmenu Preset 1
        option Custom
        option Static Spectral Fog (Gaussian Mass)
        option Fracturing Mass (Gradual Detuning Arc)
        option Stereo Torsion (Left=Pure, Right=Detuned)
        option Bimodal Web (High/Low Split)
        option Breathing Field (Uniform Cloud)
    
    comment === Custom parameters (if Preset = Custom) ===
    positive Number_of_voices 60
    positive Time_offset_range_s 0.8
    positive Duration_var_ratio 0.05
    positive Max_pitch_cents 15.0
    boolean Stereo_spread 1
    positive Attack_fade_ms 30
    positive Voice_gain 1.0
    boolean Normalize_output 1
endform

# --- 1. BEHAVIOR SETUP (The "Meta" Logic) ---

# Defaults (Standard Uniform Cloud)
structure$ = "uniform"
dist_shape$ = "flat"
time_range = 0.5
pitch_max = 15
dur_var = 0.05
n_voices = 50
gain = 1.0
fade = 25

if preset = 2
    # === STATIC SPECTRAL FOG ===
    # Logic: Gaussian distribution creates a dense "core" with wispy edges.
    # No motion, just weight.
    structure$ = "uniform"
    dist_shape$ = "gaussian"   ; <--- The key to the "Fog" sound
    n_voices = 60
    time_range = 0.5
    pitch_max = 8              ; Very tight pitch
    dur_var = 0.02             ; Almost frozen duration
    gain = 0.8
    fade = 50

elsif preset = 3
    # === FRACTURING MASS ===
    # Logic: Formal Arc. Voice 1 is pure; Voice 60 is microtonal chaos.
    structure$ = "arc_fracture" ; <--- Pitch expands over voice index
    dist_shape$ = "flat"
    n_voices = 60
    time_range = 1.0
    pitch_max = 35             ; Ends very wide
    dur_var = 0.08
    gain = 0.7
    fade = 30

elsif preset = 4
    # === STEREO TORSION ===
    # Logic: Asymmetry. The Left ear is stable, the Right ear is detuned.
    # This creates structural tension across space.
    structure$ = "asymmetry"   ; <--- Pitch depends on Pan
    dist_shape$ = "flat"
    n_voices = 50
    time_range = 0.6
    pitch_max = 25
    dur_var = 0.05
    gain = 0.9
    fade = 20

elsif preset = 5
    # === BIMODAL WEB ===
    # Logic: Two distinct layers (High/Short vs Low/Long) woven together.
    structure$ = "bimodal"
    dist_shape$ = "flat"
    n_voices = 40
    time_range = 0.8
    pitch_max = 20
    dur_var = 0.1
    gain = 0.85
    fade = 15

elsif preset = 6
    # === BREATHING FIELD ===
    # Classic Ligeti (Lux Aeterna). Uniform distribution.
    structure$ = "uniform"
    dist_shape$ = "flat"
    n_voices = 40
    time_range = 1.2
    pitch_max = 12
    dur_var = 0.08
    gain = 0.8
    fade = 40
endif

# Overrides for Custom
if preset = 1
    n_voices = number_of_voices
    time_range = time_offset_range_s
    pitch_max = max_pitch_cents
    dur_var = duration_var_ratio
    gain = voice_gain
    fade = attack_fade_ms
endif

# --- INITIALIZATION ---
if n_voices < 2
    exitScript: "Need at least 2 voices."
endif

source = selected("Sound")
source_name$ = selected$("Sound")
source_dur = Get total duration
source_sr = Get sampling frequency
source_channels = Get number of channels

# Output buffer
output_dur = source_dur + time_range + 0.5
output = Create Sound from formula: "Ligeti_" + structure$, 
    ... source_channels, 
    ... 0, output_dur, source_sr, "0"

writeInfoLine: "=== Ligeti Structural Machine ==="
appendInfoLine: "Mode: ", structure$, " | Distribution: ", dist_shape$
appendInfoLine: "Generating ", n_voices, " voices..."

# --- GENERATION LOOP ---
for voice from 1 to n_voices
    
    if voice mod 5 = 0
        appendInfoLine: "Processing voice ", voice, " / ", n_voices
    endif

    selectObject: source
    voice_copy = Copy: "temp"
    
    # Reset start time (Safety)
    t_start = Get start time
    Shift times by: -t_start

    # === 1. CALCULATE PARAMETERS BASED ON BEHAVIOR ===
    
    # A. PANNING (Calculated early for Asymmetry mode)
    pan_pos = randomUniform(-1, 1)
    
    # B. PITCH DRIFT CALCULATION
    current_pitch_cents = 0
    
    if structure$ = "uniform"
        current_pitch_cents = randomUniform(-pitch_max, pitch_max)
        
    elsif structure$ = "arc_fracture"
        # The higher the voice index, the wider the pitch range
        # Voice 1 = 0 cents, Voice 60 = +/- pitch_max
        intensity = voice / n_voices
        current_range = pitch_max * intensity
        current_pitch_cents = randomUniform(-current_range, current_range)
        
    elsif structure$ = "asymmetry"
        # Left (pan -1) = 0 drift. Right (pan +1) = Max drift.
        # Scale pan (-1 to 1) to (0 to 1)
        tension = (pan_pos + 1) / 2
        current_range = pitch_max * tension
        current_pitch_cents = randomUniform(-current_range, current_range)
        
    elsif structure$ = "bimodal"
        # Even voices = Pitched UP. Odd voices = Pitched DOWN.
        if voice mod 2 = 0
            current_pitch_cents = randomUniform(5, pitch_max)
        else
            current_pitch_cents = randomUniform(-pitch_max, -5)
        endif
    endif

    # === 2. APPLY PITCH SHIFT ===
    pitch_ratio = 2 ^ (current_pitch_cents / 1200)
    
    if abs(current_pitch_cents) > 0.1
        new_sr = source_sr * pitch_ratio
        Override sampling frequency: new_sr
        Resample: source_sr, 50
        removeObject: voice_copy
        voice_copy = selected("Sound")
        Rename: "temp"
    endif

    # === 3. TIME STRETCH (Compensated) ===
    # Apply distribution shape to duration too
    if dist_shape$ = "gaussian"
        # Bias towards 1.0 (mean)
        raw_rand = (randomUniform(-1, 1) + randomUniform(-1, 1)) / 2
        dur_factor = 1 + (raw_rand * dur_var)
    else
        dur_factor = 1 + randomUniform(-dur_var, dur_var)
    endif
    
    total_stretch = dur_factor * pitch_ratio
    
    if abs(total_stretch - 1) > 0.001
        selectObject: voice_copy
        v_ch = Get number of channels
        if v_ch = 1
             s_str = Lengthen (overlap-add): 75, 600, total_stretch
        else
             ch1 = Extract one channel: 1
             s1 = Lengthen (overlap-add): 75, 600, total_stretch
             selectObject: voice_copy
             ch2 = Extract one channel: 2
             s2 = Lengthen (overlap-add): 75, 600, total_stretch
             selectObject: s1
             plusObject: s2
             s_str = Combine to stereo
             removeObject: ch1, ch2, s1, s2
        endif
        removeObject: voice_copy
        voice_copy = s_str
    endif

    # === 4. ENVELOPE ===
    if fade > 0
        selectObject: voice_copy
        fade_sec = fade / 1000
        Formula... self * (if (x - xmin) < fade_sec then (x - xmin)/fade_sec else if (xmax - x) < fade_sec then (xmax - x)/fade_sec else 1 fi fi)
    endif

    # === 5. GAIN ===
    selectObject: voice_copy
    Formula... self * gain / sqrt(n_voices)

    # === 6. PANNING ===
    selectObject: voice_copy
    curr_ch = Get number of channels
    if stereo_spread and curr_ch = 1 and source_channels = 1
        # Use the pan_pos we calculated earlier
        l_gain = sqrt((1-pan_pos)/2)
        r_gain = sqrt((1+pan_pos)/2)
        s_left = Copy: "L"
        Formula... self * l_gain
        selectObject: voice_copy
        s_right = Copy: "R"
        Formula... self * r_gain
        selectObject: s_left
        plusObject: s_right
        v_stereo = Combine to stereo
        removeObject: voice_copy, s_left, s_right
        voice_copy = v_stereo
    endif

    # === 7. TIME OFFSET (Distribution Logic) ===
    selectObject: voice_copy
    
    offset = 0
    if dist_shape$ = "gaussian"
        # Bell curve around 0. Result is mostly center, tails at edges.
        # Range approx -0.5 to +0.5 of time_range
        r1 = randomUniform(-0.5, 0.5)
        r2 = randomUniform(-0.5, 0.5)
        offset = (r1 + r2) * time_range
    else
        # Flat distribution centered on 0
        offset = randomUniform(-time_range/2, time_range/2)
    endif

    # Apply Offset (Negative = Cut, Positive = Pad)
    if offset < 0
        cut_dur = abs(offset)
        curr_dur = Get total duration
        if cut_dur < curr_dur
            v_cut = Extract part: cut_dur, curr_dur, "rectangular", 1, "no"
            removeObject: voice_copy
            voice_copy = v_cut
        endif
    else
        if offset > 0.001
            sil = Create Sound from formula: "sil", source_channels, 0, offset, source_sr, "0"
            selectObject: sil
            plusObject: voice_copy
            cat = Concatenate
            removeObject: sil, voice_copy
            voice_copy = cat
        endif
    endif

    # === 8. MIX ===
    # Pad tail to match output
    selectObject: voice_copy
    curr_dur = Get total duration
    rem_dur = output_dur - curr_dur
    if rem_dur > 0
        sil_end = Create Sound from formula: "sil", source_channels, 0, rem_dur, source_sr, "0"
        selectObject: voice_copy
        plusObject: sil_end
        cat2 = Concatenate
        removeObject: sil_end, voice_copy
        voice_copy = cat2
    endif

    # Clamp and Mix
    selectObject: voice_copy
    Rename: "ready"
    ready = Extract part: 0, output_dur, "rectangular", 1, "no"
    removeObject: voice_copy
    
    selectObject: output
    plusObject: ready
    Formula... self + object[ready]
    removeObject: ready

endfor

# --- CLEANUP ---
selectObject: output
if normalize_output
    Scale peak: 0.99
endif

appendInfoLine: "Generated Structural Texture: ", structure$
Play