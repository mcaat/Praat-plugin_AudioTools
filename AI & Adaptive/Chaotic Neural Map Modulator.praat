# ============================================================
# Praat AudioTools - Chaotic Neural Map Modulator
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Chaotic Neural Map Modulator
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Chaotic Neural Map Modulator 
# Each run produces significantly different chaos

form Chaotic Neural Map Modulator
    comment === PRESETS (override settings below) ===
    optionmenu Preset 2
        option Custom (use settings below)
        option Subtle Organic
        option Balanced Chaos
        option Wild Unstable
        option Tightly Controlled
        option Maximum Variation
        option Glitch Machine
    
    comment === Features & Network ===
    real Analysis_step_ms 60
    integer Hidden_neurons 10
    integer Training_iterations 200
    
    comment === Chaos Behavior ===
    real Autonomy 0.85
    comment (0 = follows features, 1 = pure chaos)
    real Chaos_volatility 2.5
    comment (1 = subtle, 4 = extreme swings)
    real Kick_interval_ms 200
    comment (How often chaos realigns with sound)
    real Chaos_mutation 0.3
    comment (0 = deterministic, 1 = max randomness)
    
    comment === Modulation ===
    real Pitch_semitones 12
    real Amplitude_mod 0.8
    real Ring_mod 0.4
    boolean HQ_pitch 0
    
    comment === Output ===
    real Dry_wet 0.8
    real HF_boost_dB 3
    boolean Play_output 1
    integer Random_seed 0
    comment (0 = always different)
endform

#=============================================================================
# APPLY PRESET OVERRIDES
#=============================================================================

if preset$ = "Subtle Organic"
    autonomy = 0.7
    chaos_volatility = 1.2
    kick_interval_ms = 100
    chaos_mutation = 0.15
    pitch_semitones = 6
    amplitude_mod = 0.5
    ring_mod = 0.2
    dry_wet = 0.5
    
elsif preset$ = "Balanced Chaos"
    autonomy = 0.85
    chaos_volatility = 2.5
    kick_interval_ms = 200
    chaos_mutation = 0.3
    pitch_semitones = 12
    amplitude_mod = 0.8
    ring_mod = 0.4
    dry_wet = 0.8
    
elsif preset$ = "Wild Unstable"
    autonomy = 0.95
    chaos_volatility = 4.0
    kick_interval_ms = 500
    chaos_mutation = 0.7
    pitch_semitones = 18
    amplitude_mod = 0.9
    ring_mod = 0.6
    dry_wet = 1.0
    
elsif preset$ = "Tightly Controlled"
    autonomy = 0.5
    chaos_volatility = 1.0
    kick_interval_ms = 50
    chaos_mutation = 0.1
    pitch_semitones = 8
    amplitude_mod = 0.6
    ring_mod = 0.3
    dry_wet = 0.6
    
elsif preset$ = "Maximum Variation"
    autonomy = 0.9
    chaos_volatility = 3.5
    kick_interval_ms = 300
    chaos_mutation = 0.9
    pitch_semitones = 15
    amplitude_mod = 0.85
    ring_mod = 0.5
    dry_wet = 0.9
    
elsif preset$ = "Glitch Machine"
    autonomy = 0.98
    chaos_volatility = 5.0
    kick_interval_ms = 800
    chaos_mutation = 0.95
    pitch_semitones = 24
    amplitude_mod = 1.0
    ring_mod = 0.8
    dry_wet = 1.0
endif

input_sound = selected("Sound")
input_name$ = selected$("Sound")
duration = Get total duration
sr = Get sampling frequency

# Check if mono, convert if needed
num_channels = Get number of channels
if num_channels > 1
    input_sound = Convert to mono
endif

writeInfoLine: "CHAOTIC MODULATOR - ", preset$
appendInfoLine: "=========================================="

#=============================================================================
# SEED RANDOM NUMBER GENERATOR
#=============================================================================

if random_seed = 0
    date$ = date$()
    time_val = extractNumber(date$, ":")
    seed = round(time_val * 10000 + randomUniform(0, 1000)) mod 100000
    for i to seed
        dummy = randomUniform(0, 1)
    endfor
    appendInfoLine: "Random seed: ", seed
else
    for i to random_seed
        dummy = randomUniform(0, 1)
    endfor
    appendInfoLine: "Random seed: ", random_seed, " (fixed)"
endif

appendInfoLine: ""
appendInfoLine: "Settings:"
appendInfoLine: "  Autonomy: ", round(autonomy * 100), "%"
appendInfoLine: "  Volatility: ", chaos_volatility
appendInfoLine: "  Kick interval: ", kick_interval_ms, " ms"
appendInfoLine: "  Mutation: ", round(chaos_mutation * 100), "%"
appendInfoLine: ""
appendInfoLine: "Processing..."

#=============================================================================
# EXTRACT FEATURES
#=============================================================================

time_step = analysis_step_ms / 1000
num_frames = floor(duration / time_step)

for i to num_frames
    time[i] = (i - 1) * time_step
    feat_amp[i] = 0
    feat_centroid[i] = 0
    feat_rolloff[i] = 0
endfor

# Amplitude
selectObject: input_sound
intensity = To Intensity: 75, time_step, "yes"
for i to num_frames
    selectObject: intensity
    feat_amp[i] = Get value at time: time[i], "Cubic"
    if feat_amp[i] = undefined
        feat_amp[i] = 70
    endif
endfor
removeObject: intensity

min_v = feat_amp[1]
max_v = feat_amp[1]
for i from 2 to num_frames
    if feat_amp[i] < min_v
        min_v = feat_amp[i]
    endif
    if feat_amp[i] > max_v
        max_v = feat_amp[i]
    endif
endfor
for i to num_frames
    feat_amp[i] = (feat_amp[i] - min_v) / (max_v - min_v + 0.001)
endfor

# Spectral centroid
selectObject: input_sound
spectrogram = To Spectrogram: 0.005, 5000, time_step, 20, "Gaussian"

for i to num_frames
    selectObject: spectrogram
    slice = To Spectrum (slice): time[i]
    selectObject: slice
    cog = Get centre of gravity: 2
    if cog != undefined and cog > 0
        feat_centroid[i] = cog
    else
        feat_centroid[i] = 2000
    endif
    removeObject: slice
endfor

removeObject: spectrogram

min_v = feat_centroid[1]
max_v = feat_centroid[1]
for i from 2 to num_frames
    if feat_centroid[i] < min_v
        min_v = feat_centroid[i]
    endif
    if feat_centroid[i] > max_v
        max_v = feat_centroid[i]
    endif
endfor
for i to num_frames
    feat_centroid[i] = (feat_centroid[i] - min_v) / (max_v - min_v + 0.001)
endfor

# Spectral rolloff
selectObject: input_sound
spectrogram = To Spectrogram: 0.005, 5000, time_step, 20, "Gaussian"

for i to num_frames
    selectObject: spectrogram
    slice = To Spectrum (slice): time[i]
    
    selectObject: slice
    total_energy = 0
    n_bins = Get number of bins
    
    for bin to n_bins
        freq = Get frequency from bin number: bin
        if freq > 100 and freq < 5000
            power = Get real value in bin: bin
            total_energy += power^2
        endif
    endfor
    
    cumulative = 0
    target = total_energy * 0.85
    rolloff_freq = 2500
    
    for bin to n_bins
        freq = Get frequency from bin number: bin
        if freq > 100 and freq < 5000
            power = Get real value in bin: bin
            cumulative += power^2
            if cumulative >= target
                rolloff_freq = freq
                bin = n_bins + 1
            endif
        endif
    endfor
    
    feat_rolloff[i] = rolloff_freq
    removeObject: slice
endfor

removeObject: spectrogram

min_v = feat_rolloff[1]
max_v = feat_rolloff[1]
for i from 2 to num_frames
    if feat_rolloff[i] < min_v
        min_v = feat_rolloff[i]
    endif
    if feat_rolloff[i] > max_v
        max_v = feat_rolloff[i]
    endif
endfor
for i to num_frames
    feat_rolloff[i] = (feat_rolloff[i] - min_v) / (max_v - min_v + 0.001)
endfor

appendInfoLine: "  Features: ", num_frames, " frames"

#=============================================================================
# TRAIN NETWORK
#=============================================================================

appendInfoLine: "  Training network..."

for h to hidden_neurons
    w_in[h, 1] = randomUniform(-0.5, 0.5)
    w_in[h, 2] = randomUniform(-0.5, 0.5)
    w_in[h, 3] = randomUniform(-0.5, 0.5)
    b_h[h] = randomUniform(-0.5, 0.5)
endfor

for d to 3
    for h to hidden_neurons
        w_out[d, h] = randomUniform(-0.5, 0.5)
    endfor
    b_o[d] = randomUniform(-0.5, 0.5)
endfor

for iter to training_iterations
    for frame from 2 to num_frames - 1
        inp[1] = feat_amp[frame]
        inp[2] = feat_centroid[frame]
        inp[3] = feat_rolloff[frame]
        
        targ[1] = feat_amp[frame + 1]
        targ[2] = feat_centroid[frame + 1]
        targ[3] = feat_rolloff[frame + 1]
        
        for h to hidden_neurons
            sum = b_h[h]
            for f to 3
                sum += inp[f] * w_in[h, f]
            endfor
            hid[h] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
        endfor
        
        for d to 3
            sum = b_o[d]
            for h to hidden_neurons
                sum += hid[h] * w_out[d, h]
            endfor
            out[d] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
        endfor
        
        for d to 3
            err = targ[d] - out[d]
            delta_o[d] = err * (1 - out[d]^2)
            for h to hidden_neurons
                w_out[d, h] += 0.12 * delta_o[d] * hid[h]
            endfor
            b_o[d] += 0.12 * delta_o[d]
        endfor
        
        for h to hidden_neurons
            delta_h = 0
            for d to 3
                delta_h += delta_o[d] * w_out[d, h]
            endfor
            delta_h *= (1 - hid[h]^2)
            for f to 3
                w_in[h, f] += 0.12 * delta_h * inp[f]
            endfor
            b_h[h] += 0.12 * delta_h
        endfor
    endfor
endfor

#=============================================================================
# GENERATE CHAOS
#=============================================================================

appendInfoLine: "  Generating chaos..."

for d to 3
    state[d] = randomUniform(0.2, 0.8)
endfor

kick_interval = kick_interval_ms / 1000
last_kick = 0
injection_rate = 1 - autonomy
phase_offset = randomUniform(0, 1)

for frame to num_frames
    inject = 0
    if time[frame] - last_kick >= kick_interval
        inject = 1
        last_kick = time[frame]
    endif
    
    if randomUniform(0, 1) < chaos_mutation * 0.5
        inject = 1 - inject
    endif
    
    if inject = 1
        inp[1] = feat_amp[frame] * injection_rate + state[1] * (1 - injection_rate)
        inp[2] = feat_centroid[frame] * injection_rate + state[2] * (1 - injection_rate)
        inp[3] = feat_rolloff[frame] * injection_rate + state[3] * (1 - injection_rate)
    else
        inp[1] = state[1]
        inp[2] = state[2]
        inp[3] = state[3]
    endif
    
    if chaos_mutation > 0
        for f to 3
            mutation = randomUniform(-1, 1) * chaos_mutation * 0.2
            inp[f] += mutation
            inp[f] = max(0, min(1, inp[f]))
        endfor
    endif
    
    for h to hidden_neurons
        sum = b_h[h]
        for f to 3
            sum += inp[f] * w_in[h, f]
        endfor
        hid[h] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
    endfor
    
    for d to 3
        sum = b_o[d]
        for h to hidden_neurons
            sum += hid[h] * w_out[d, h]
        endfor
        new_state = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
        
        volatility_factor = chaos_volatility * randomUniform(0.8, 1.2)
        new_state = (new_state - 0.5) * volatility_factor + 0.5
        
        if chaos_mutation > 0 and randomUniform(0, 1) < chaos_mutation * 0.1
            perturbation = randomUniform(-0.3, 0.3) * chaos_mutation
            new_state += perturbation
        endif
        
        new_state = max(0, min(1, new_state))
        
        phase_mod = sin(2 * pi * (frame / num_frames + phase_offset))
        chaos[frame, d] = (new_state * 2 - 1) * (1 + phase_mod * chaos_mutation * 0.3)
        chaos[frame, d] = max(-1, min(1, chaos[frame, d]))
        
        state[d] = new_state
    endfor
endfor

#=============================================================================
# APPLY MODULATION
#=============================================================================

appendInfoLine: "  Modulating..."

selectObject: input_sound
work = Copy: input_name$ + "_work"

# Pitch
pitch_tier = Create PitchTier: "chaos", 0, duration

selectObject: input_sound
pitch_obj = To Pitch: time_step, 75, 600
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"
if median_f0 = undefined or median_f0 < 75
    median_f0 = 200
endif
removeObject: pitch_obj

for i to num_frames
    selectObject: pitch_tier
    semitones = chaos[i, 1] * pitch_semitones
    freq = median_f0 * 2 ^ (semitones / 12)
    freq = max(50, min(1000, freq))
    Add point: time[i], freq
endfor

selectObject: work
if hQ_pitch
    selectObject: work
    work_mono = Convert to mono
    selectObject: work_mono
    work_pitched = Change gender: 75, 600, 1.0, 0, 1.0, 1.0
    removeObject: work_mono
    
    selectObject: work_pitched
    manip = To Manipulation: 0.01, 75, 600
    selectObject: manip
    plusObject: pitch_tier
    Replace pitch tier
    selectObject: manip
    work_final = Get resynthesis (overlap-add)
    removeObject: work_pitched, manip
    work_pitched = work_final
else
    manip = To Manipulation: 0.01, 75, 600
    selectObject: manip
    plusObject: pitch_tier
    Replace pitch tier
    selectObject: manip
    work_pitched = Get resynthesis (overlap-add)
    removeObject: manip
endif

removeObject: pitch_tier, work

# Amplitude
amp_tier = Create IntensityTier: "chaos_amp", 0, duration
for i to num_frames
    selectObject: amp_tier
    db_mod = chaos[i, 2] * 15 * amplitude_mod
    Add point: time[i], 70 + db_mod
endfor

selectObject: work_pitched
plusObject: amp_tier
work_amp = Multiply: "yes"
removeObject: amp_tier, work_pitched

# Ring mod
if ring_mod > 0
    selectObject: work_amp
    for i to num_frames
        t_start = time[i]
        t_end = min(duration, time[i] + time_step)
        ring_freq = 300 + chaos[i, 3] * 600
        ring_mod_val = ring_mod
        selectObject: work_amp
        Formula (part): t_start, t_end, 1, 1, "self * (1 - ring_mod_val + ring_mod_val * sin(2 * pi * ring_freq * x))"
    endfor
endif

# HF boost
if hF_boost_dB > 0
    selectObject: work_amp
    work_boosted = Filter (de-emphasis): 50
    selectObject: work_boosted
    boost_factor = 10 ^ (hF_boost_dB / 20)
    Formula: "self * boost_factor"
    removeObject: work_amp
    work_amp = work_boosted
endif

#=============================================================================
# MIX
#=============================================================================

selectObject: work_amp
Formula: "self * dry_wet"

selectObject: input_sound
output_sound = Copy: input_name$ + "_chaotic"
Formula: "self * (1 - dry_wet)"

selectObject: work_amp
work_name$ = selected$("Sound")

selectObject: output_sound
Formula: "self + Sound_'work_name$'[col]"

removeObject: work_amp

if num_channels > 1
    removeObject: input_sound
endif

selectObject: output_sound

appendInfoLine: ""
appendInfoLine: "✓ COMPLETE!"
appendInfoLine: "Preset: ", preset$

if play_output
    appendInfoLine: "Playing..."
    Play
endif

selectObject: output_sound