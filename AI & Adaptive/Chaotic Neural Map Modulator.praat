# ============================================================
# Praat AudioTools - Chaotic Neural Map Modulator
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.3 (2025) - Optimized + Stereo
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Chaotic Neural Map Modulator
#   Optimizations:
#   - Single spectrogram pass for all spectral features
#   - Fast ring modulation (single Formula)
#   - Stereo output with independent L/R chaos
#   - Streamlined HQ pitch processing
#
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
    boolean Stereo_output 1
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

#=============================================================================
# INITIALIZATION
#=============================================================================

input_sound_original = selected("Sound")
input_name$ = selected$("Sound")

selectObject: input_sound_original
duration = Get total duration
sr = Get sampling frequency
original_channels = Get number of channels

# Convert to mono for analysis
if original_channels > 1
    input_sound = Convert to mono
    Rename: input_name$ + "_mono"
else
    input_sound = Copy: input_name$ + "_mono"
endif

writeInfoLine: "CHAOTIC MODULATOR - ", preset$
appendInfoLine: "=========================================="
if stereo_output
    appendInfoLine: "Output: Stereo (independent L/R chaos)"
else
    appendInfoLine: "Output: Mono"
endif

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
# EXTRACT FEATURES (OPTIMIZED - Single Spectrogram Pass)
#=============================================================================

time_step = analysis_step_ms / 1000
num_frames = floor(duration / time_step)

# Pre-allocate arrays
time# = zero#(num_frames)
feat_amp# = zero#(num_frames)
feat_centroid# = zero#(num_frames)
feat_rolloff# = zero#(num_frames)

for i to num_frames
    time#[i] = (i - 1) * time_step
endfor

# Amplitude from Intensity object
selectObject: input_sound
intensity = To Intensity: 75, time_step, "yes"
for i to num_frames
    selectObject: intensity
    val = Get value at time: time#[i], "Cubic"
    if val = undefined
        feat_amp#[i] = 70
    else
        feat_amp#[i] = val
    endif
endfor
removeObject: intensity

# Single spectrogram for centroid AND rolloff
selectObject: input_sound
spectrogram = To Spectrogram: 0.005, 5000, time_step, 20, "Gaussian"

for i to num_frames
    selectObject: spectrogram
    slice = To Spectrum (slice): time#[i]
    
    selectObject: slice
    
    # Centroid (built-in)
    cog = Get centre of gravity: 2
    if cog != undefined and cog > 0
        feat_centroid#[i] = cog
    else
        feat_centroid#[i] = 2000
    endif
    
    # Rolloff - single pass (OPTIMIZED)
    n_bins = Get number of bins
    total_energy = 0
    
    # First accumulate total energy
    for bin to n_bins
        freq = Get frequency from bin number: bin
        if freq > 100 and freq < 5000
            power = Get real value in bin: bin
            total_energy += power^2
        endif
    endfor
    
    # Find 85% threshold in same conceptual pass (we need the total first)
    target = total_energy * 0.85
    cumulative = 0
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
    
    feat_rolloff#[i] = rolloff_freq
    removeObject: slice
endfor

removeObject: spectrogram

# Normalize features using procedure-like inline code
# Amplitude normalization
min_v = feat_amp#[1]
max_v = feat_amp#[1]
for i from 2 to num_frames
    if feat_amp#[i] < min_v
        min_v = feat_amp#[i]
    endif
    if feat_amp#[i] > max_v
        max_v = feat_amp#[i]
    endif
endfor
range = max_v - min_v + 0.001
for i to num_frames
    feat_amp#[i] = (feat_amp#[i] - min_v) / range
endfor

# Centroid normalization
min_v = feat_centroid#[1]
max_v = feat_centroid#[1]
for i from 2 to num_frames
    if feat_centroid#[i] < min_v
        min_v = feat_centroid#[i]
    endif
    if feat_centroid#[i] > max_v
        max_v = feat_centroid#[i]
    endif
endfor
range = max_v - min_v + 0.001
for i to num_frames
    feat_centroid#[i] = (feat_centroid#[i] - min_v) / range
endfor

# Rolloff normalization
min_v = feat_rolloff#[1]
max_v = feat_rolloff#[1]
for i from 2 to num_frames
    if feat_rolloff#[i] < min_v
        min_v = feat_rolloff#[i]
    endif
    if feat_rolloff#[i] > max_v
        max_v = feat_rolloff#[i]
    endif
endfor
range = max_v - min_v + 0.001
for i to num_frames
    feat_rolloff#[i] = (feat_rolloff#[i] - min_v) / range
endfor

appendInfoLine: "  Features: ", num_frames, " frames"

#=============================================================================
# TRAIN NETWORK
#=============================================================================

appendInfoLine: "  Training network..."

# Initialize weights
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

# Training loop
learning_rate = 0.12

for iter to training_iterations
    for frame from 2 to num_frames - 1
        inp[1] = feat_amp#[frame]
        inp[2] = feat_centroid#[frame]
        inp[3] = feat_rolloff#[frame]
        
        targ[1] = feat_amp#[frame + 1]
        targ[2] = feat_centroid#[frame + 1]
        targ[3] = feat_rolloff#[frame + 1]
        
        # Forward pass - hidden layer
        for h to hidden_neurons
            sum = b_h[h]
            for f to 3
                sum += inp[f] * w_in[h, f]
            endfor
            # Tanh activation
            if sum > 20
                hid[h] = 1
            elsif sum < -20
                hid[h] = -1
            else
                hid[h] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
            endif
        endfor
        
        # Forward pass - output layer
        for d to 3
            sum = b_o[d]
            for h to hidden_neurons
                sum += hid[h] * w_out[d, h]
            endfor
            if sum > 20
                out[d] = 1
            elsif sum < -20
                out[d] = -1
            else
                out[d] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
            endif
        endfor
        
        # Backprop - output layer
        for d to 3
            err = targ[d] - out[d]
            delta_o[d] = err * (1 - out[d]^2)
            for h to hidden_neurons
                w_out[d, h] += learning_rate * delta_o[d] * hid[h]
            endfor
            b_o[d] += learning_rate * delta_o[d]
        endfor
        
        # Backprop - hidden layer
        for h to hidden_neurons
            delta_h = 0
            for d to 3
                delta_h += delta_o[d] * w_out[d, h]
            endfor
            delta_h *= (1 - hid[h]^2)
            for f to 3
                w_in[h, f] += learning_rate * delta_h * inp[f]
            endfor
            b_h[h] += learning_rate * delta_h
        endfor
    endfor
endfor

#=============================================================================
# GENERATE CHAOS (with stereo support)
#=============================================================================

appendInfoLine: "  Generating chaos..."

if stereo_output
    n_passes = 2
else
    n_passes = 1
endif

kick_interval = kick_interval_ms / 1000
injection_rate = 1 - autonomy

for pass from 1 to n_passes
    # Initialize state for this pass
    for d to 3
        state[d] = randomUniform(0.2, 0.8)
    endfor
    
    last_kick = 0
    phase_offset = randomUniform(0, 1)
    
    for frame to num_frames
        inject = 0
        if time#[frame] - last_kick >= kick_interval
            inject = 1
            last_kick = time#[frame]
        endif
        
        if randomUniform(0, 1) < chaos_mutation * 0.5
            inject = 1 - inject
        endif
        
        if inject = 1
            inp[1] = feat_amp#[frame] * injection_rate + state[1] * (1 - injection_rate)
            inp[2] = feat_centroid#[frame] * injection_rate + state[2] * (1 - injection_rate)
            inp[3] = feat_rolloff#[frame] * injection_rate + state[3] * (1 - injection_rate)
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
        
        # Forward through network
        for h to hidden_neurons
            sum = b_h[h]
            for f to 3
                sum += inp[f] * w_in[h, f]
            endfor
            if sum > 20
                hid[h] = 1
            elsif sum < -20
                hid[h] = -1
            else
                hid[h] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
            endif
        endfor
        
        for d to 3
            sum = b_o[d]
            for h to hidden_neurons
                sum += hid[h] * w_out[d, h]
            endfor
            if sum > 20
                new_state = 1
            elsif sum < -20
                new_state = -1
            else
                new_state = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))
            endif
            
            volatility_factor = chaos_volatility * randomUniform(0.8, 1.2)
            new_state = (new_state - 0.5) * volatility_factor + 0.5
            
            if chaos_mutation > 0 and randomUniform(0, 1) < chaos_mutation * 0.1
                perturbation = randomUniform(-0.3, 0.3) * chaos_mutation
                new_state += perturbation
            endif
            
            new_state = max(0, min(1, new_state))
            
            phase_mod = sin(2 * pi * (frame / num_frames + phase_offset))
            chaos_val = (new_state * 2 - 1) * (1 + phase_mod * chaos_mutation * 0.3)
            chaos_val = max(-1, min(1, chaos_val))
            
            # Store in pass-specific arrays
            if pass = 1
                chaos_L[frame, d] = chaos_val
            else
                chaos_R[frame, d] = chaos_val
            endif
            
            state[d] = new_state
        endfor
    endfor
endfor

#=============================================================================
# APPLY MODULATION (per channel for stereo)
#=============================================================================

appendInfoLine: "  Modulating..."

# Get median pitch for reference
selectObject: input_sound
pitch_obj = To Pitch: time_step, 75, 600
median_f0 = Get quantile: 0, 0, 0.5, "Hertz"
if median_f0 = undefined or median_f0 < 75
    median_f0 = 200
endif
removeObject: pitch_obj

for pass from 1 to n_passes
    if stereo_output
        if pass = 1
            appendInfoLine: "    Processing LEFT channel..."
        else
            appendInfoLine: "    Processing RIGHT channel..."
        endif
    endif
    
    selectObject: input_sound
    work = Copy: input_name$ + "_work"
    
    # Build pitch tier from chaos
    pitch_tier = Create PitchTier: "chaos", 0, duration
    
    for i to num_frames
        if pass = 1
            chaos_pitch = chaos_L[i, 1]
        else
            chaos_pitch = chaos_R[i, 1]
        endif
        
        selectObject: pitch_tier
        semitones = chaos_pitch * pitch_semitones
        freq = median_f0 * 2 ^ (semitones / 12)
        freq = max(50, min(1000, freq))
        Add point: time#[i], freq
    endfor
    
    # Apply pitch modification
    selectObject: work
    if hQ_pitch
        # High quality: use Change gender for formant preservation
        manip = To Manipulation: 0.01, 75, 600
        selectObject: manip
        plusObject: pitch_tier
        Replace pitch tier
        selectObject: manip
        work_pitched = Get resynthesis (overlap-add)
        removeObject: manip
    else
        # Standard quality
        manip = To Manipulation: 0.01, 75, 600
        selectObject: manip
        plusObject: pitch_tier
        Replace pitch tier
        selectObject: manip
        work_pitched = Get resynthesis (overlap-add)
        removeObject: manip
    endif
    
    removeObject: pitch_tier, work
    
    # Build amplitude tier from chaos
    amp_tier = Create IntensityTier: "chaos_amp", 0, duration
    for i to num_frames
        if pass = 1
            chaos_amp = chaos_L[i, 2]
        else
            chaos_amp = chaos_R[i, 2]
        endif
        
        selectObject: amp_tier
        db_mod = chaos_amp * 15 * amplitude_mod
        Add point: time#[i], 70 + db_mod
    endfor
    
    selectObject: work_pitched
    plusObject: amp_tier
    work_amp = Multiply: "yes"
    removeObject: amp_tier, work_pitched
    
    # Ring modulation (OPTIMIZED - single Formula with pre-built modulator)
    if ring_mod > 0
        # Create ring modulator sound
        selectObject: work_amp
        ring_sound = Create Sound from formula: "ring_mod", 1, 0, duration, sr,
            ... "0"
        
        # Build the ring modulator waveform
        for i to num_frames
            if pass = 1
                chaos_ring = chaos_L[i, 3]
            else
                chaos_ring = chaos_R[i, 3]
            endif
            
            t_start = time#[i]
            if i < num_frames
                t_end = time#[i + 1]
            else
                t_end = duration
            endif
            
            ring_freq = 300 + chaos_ring * 600
            
            selectObject: ring_sound
            Formula (part): t_start, t_end, 1, 1,
                ... "(1 - ring_mod) + ring_mod * sin(2 * pi * " + string$(ring_freq) + " * x)"
        endfor
        
        # Apply ring mod in one multiply
        selectObject: work_amp
        Formula: "self * Sound_ring_mod[col]"
        removeObject: ring_sound
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
    
    # Store channel result
    if pass = 1
        channel_left = work_amp
        selectObject: channel_left
        Rename: "Channel_Left"
    else
        channel_right = work_amp
        selectObject: channel_right
        Rename: "Channel_Right"
    endif
endfor

#=============================================================================
# MIX AND COMBINE
#=============================================================================

appendInfoLine: "  Mixing..."

if stereo_output
    # Apply dry/wet to both channels
    selectObject: channel_left
    Formula: "self * dry_wet"
    
    selectObject: channel_right
    Formula: "self * dry_wet"
    
    # Create dry stereo from original
    selectObject: input_sound_original
    if original_channels > 1
        dry_sound = Copy: "dry"
    else
        # If original was mono, duplicate to stereo
        dry_left = Copy: "dry_L"
        dry_right = Copy: "dry_R"
        selectObject: dry_left, dry_right
        dry_sound = Combine to stereo
        removeObject: dry_left, dry_right
    endif
    
    selectObject: dry_sound
    Formula: "self * (1 - dry_wet)"
    
    # Combine wet channels to stereo
    selectObject: channel_left, channel_right
    wet_stereo = Combine to stereo
    Rename: "wet_stereo"
    removeObject: channel_left, channel_right
    
    # Match durations if needed
    selectObject: wet_stereo
    wet_dur = Get total duration
    selectObject: dry_sound
    dry_dur = Get total duration
    
    if wet_dur < dry_dur
        selectObject: dry_sound
        dry_trimmed = Extract part: 0, wet_dur, "rectangular", 1.0, "no"
        removeObject: dry_sound
        dry_sound = dry_trimmed
    elsif dry_dur < wet_dur
        selectObject: wet_stereo
        wet_trimmed = Extract part: 0, dry_dur, "rectangular", 1.0, "no"
        removeObject: wet_stereo
        wet_stereo = wet_trimmed
    endif
    
    # Final mix
    selectObject: wet_stereo
    wet_name$ = selected$("Sound")
    
    selectObject: dry_sound
    Formula: "self + Sound_'wet_name$'[col]"
    
    output_sound = dry_sound
    selectObject: output_sound
    Rename: input_name$ + "_chaotic_stereo"
    
    removeObject: wet_stereo
    
else
    # Mono output
    selectObject: channel_left
    Formula: "self * dry_wet"
    
    selectObject: input_sound
    dry_mono = Copy: "dry_mono"
    Formula: "self * (1 - dry_wet)"
    
    selectObject: channel_left
    left_name$ = selected$("Sound")
    
    # Match durations
    selectObject: channel_left
    wet_dur = Get total duration
    selectObject: dry_mono
    dry_dur = Get total duration
    
    if wet_dur < dry_dur
        selectObject: dry_mono
        dry_trimmed = Extract part: 0, wet_dur, "rectangular", 1.0, "no"
        removeObject: dry_mono
        dry_mono = dry_trimmed
    elsif dry_dur < wet_dur
        selectObject: channel_left
        wet_trimmed = Extract part: 0, dry_dur, "rectangular", 1.0, "no"
        removeObject: channel_left
        channel_left = wet_trimmed
        left_name$ = selected$("Sound")
    endif
    
    selectObject: dry_mono
    Formula: "self + Sound_'left_name$'[col]"
    
    output_sound = dry_mono
    selectObject: output_sound
    Rename: input_name$ + "_chaotic"
    
    removeObject: channel_left
endif

#=============================================================================
# CLEANUP
#=============================================================================

removeObject: input_sound

selectObject: output_sound
Scale peak: 0.99

appendInfoLine: ""
appendInfoLine: "✓ COMPLETE!"
appendInfoLine: "Preset: ", preset$
selectObject: output_sound
n_ch = Get number of channels
dur = Get total duration
appendInfoLine: "Output: ", selected$("Sound")
appendInfoLine: "Duration: ", fixed$(dur, 3), " s"
appendInfoLine: "Channels: ", n_ch

if play_output
    appendInfoLine: "Playing..."
    Play
endif

selectObject: output_sound