# ============================================================
# Praat AudioTools - Parametric Autoencoder Resynthesis with Variations
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.2 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Parametric Autoencoder Resynthesis with Variations
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis—Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

## Parametric Autoencoder with PSOLA + Simple Network Visualization

form Parametric Autoencoder PSOLA
    positive time_step 0.01
    positive bottleneck_size 2
    positive epochs 100
    positive num_variations 3
    positive pitch_floor 60
    positive pitch_ceiling 500
    positive voicing_threshold 0.4
    boolean draw_network 1
endform

clearinfo
appendInfoLine: "--- Parametric Autoencoder with PSOLA ---"

# Check selection
if numberOfSelected() <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound_orig = selected()
sound_name$ = selected$("Sound")

selectObject: sound_orig

# Resample to 44100 Hz if necessary for stability
Resample: 44100, 50
sound = selected()
fs = Get sampling frequency

# Check if sound has sufficient energy
selectObject: sound
intensity_check = Get intensity (dB)
appendInfoLine: "Sound intensity: " + fixed$(intensity_check, 2) + " dB"

if intensity_check < 30
    appendInfoLine: "WARNING: Sound is very quiet. Amplifying..."
    Scale peak: 0.99
endif

# 1. Extract pitch and formant trajectories
appendInfoLine: "Extracting pitch and formant trajectories…"

# Create Pitch object
selectObject: sound
To Pitch (ac): 0.0, pitch_floor, 15, "no", 0.03, voicing_threshold, 0.01, 0.35, 0.14, pitch_ceiling
pitch_obj = selected()

# Check if pitch was detected
selectObject: pitch_obj
num_voiced = Count voiced frames
appendInfoLine: "Voiced frames detected: " + string$(num_voiced)

if num_voiced < 5
    appendInfoLine: "WARNING: Very few voiced frames detected!"
endif

# Create Formant object (Burg)
selectObject: sound
To Formant (burg): 0.0, 5, 5500, 0.025, 50.0
formant_obj = selected()

# Create Manipulation object for PSOLA
selectObject: sound
To Manipulation: 0.01, pitch_floor, pitch_ceiling
manipulation_orig = selected()

# Extract original pitch tier
Extract pitch tier
pitch_tier_orig = selected()

# Prepare time grid
selectObject: sound
start_time = Get start time
end_time = Get end time
dt = time_step
num_frames = round ((end_time - start_time) / dt) + 1

# Number of parameters: F0, F1, F2, F3, F4 (5 parameters)
nparams = 5

# Create matrix to hold parameter values
Create simple Matrix: "tmpParamMatrix", nparams, num_frames, "0"
Rename: "ParamMatrix"

# 2. Extract Data into Matrix
for col from 1 to num_frames
    t = start_time + (col - 1) * dt
    
    # Get F0
    selectObject: pitch_obj
    f0 = Get value at time: t, "Hertz", "Linear"
    if f0 = undefined
        f0 = 0
    endif
    
    # Get F1, F2, F3, F4
    selectObject: formant_obj
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    f4 = Get value at time: 4, t, "Hertz", "Linear"
    if f1 = undefined
        f1 = 500
    endif
    if f2 = undefined
        f2 = 1500
    endif
    if f3 = undefined
        f3 = 2500
    endif
    if f4 = undefined
        f4 = 3500
    endif
    
    # Fill Matrix
    selectObject: "Matrix ParamMatrix"
    Set value: 1, col, f0
    Set value: 2, col, f1
    Set value: 3, col, f2
    Set value: 4, col, f3
    Set value: 5, col, f4
endfor

# 3. Normalise
appendInfoLine: "Normalising parameters…"
selectObject: "Matrix ParamMatrix"
min_val = Get minimum
max_val = Get maximum
range_val = max_val - min_val
if range_val = 0
    range_val = 1
endif

Copy: "NormMat"
norm_mat = selected()
Formula: "(self - min_val) / range_val"
Formula: "if self < 0 then 0 else if self > 1 then 1 else self fi fi"

# Transpose for training (Rows=Frames, Cols=Params)
selectObject: norm_mat
Transpose
Rename: "NormMat_transposed"
train_mat = selected()

# 4. Neural Network Training
selectObject: train_mat
To Pattern: 1
pattern_in = selected()
selectObject: train_mat
To ActivationList
activ_out = selected()

# Create Network
Create FFNet: "ParamAutoencoder", nparams, nparams, bottleneck_size, 0
net = selected()

appendInfoLine: "Training autoencoder (Bottleneck=" + string$(bottleneck_size) + ")…"
selectObject: net
plusObject: pattern_in
plusObject: activ_out
Learn: epochs, 0.001, "Minimum-squared-error"

# ===== DRAW NETWORK VISUALIZATION =====
if draw_network = 1
    appendInfoLine: "Drawing network visualization…"
    
    selectObject: net
    
    # Clear picture
    Erase all
    
    # === TOPOLOGY (top) ===
    Select outer viewport: 1, 9, 1, 4
    Draw topology
    
    # Title
    Select outer viewport: 1, 9, 0.2, 0.8
    Text top: "yes", "Autoencoder: 5 inputs -> " + string$(bottleneck_size) + " hidden -> 5 outputs"
    
    # === WEIGHTS (bottom) ===
    # Input to Hidden
    Select outer viewport: 1, 4.5, 5, 8.5
    Draw weights: 1, "yes"
    Text top: "no", "Input to Hidden"
    
    # Hidden to Output
    Select outer viewport: 5.5, 9, 5, 8.5
    Draw weights: 2, "yes"
    Text top: "no", "Hidden to Output"
    
    # Info
    Select outer viewport: 1, 9, 8.7, 9.2
    Text top: "no", "Epochs: " + string$(epochs) + " | Darker = stronger weight"
    
    appendInfoLine: "  Network drawn to Picture window"
    appendInfoLine: "  Save: Picture -> Save as PDF"
endif

# 5. Reconstruction (get base reconstruction once)
appendInfoLine: "Getting base reconstruction…"
selectObject: train_mat
To Pattern: 1
pattern_in2 = selected()

# Get Output Activations (Layer 2)
selectObject: net
plusObject: pattern_in2
To ActivationList: 2
activ_recon = selected()

# Convert back to Matrix and Transpose
To Matrix
matrix_from_activ = selected()
Transpose
Rename: "ReconFull"
recon_mat_full = selected()

# Extract parameters
Create simple Matrix: "ReconParams", nparams, num_frames, "0"
recon_params_base = selected()

for param_row from 1 to nparams
    for col from 1 to num_frames
        selectObject: recon_mat_full
        val = Get value in cell: param_row, col 
        selectObject: recon_params_base
        Set value: param_row, col, val
    endfor
endfor

# Denormalise
selectObject: recon_params_base
Formula: "self * range_val + min_val"

# 6. CREATE VARIATIONS using PSOLA
for var_num from 0 to num_variations
    
    if var_num = 0
        appendInfoLine: "Creating original reconstruction (PSOLA)…"
        var_name$ = "Original"
        selectObject: recon_params_base
        Copy: "ReconParams_Var0"
        recon_params = selected()
    else
        appendInfoLine: "Creating variation " + string$(var_num) + " (PSOLA)…"
        var_name$ = "Var" + string$(var_num)
        selectObject: recon_params_base
        Copy: "ReconParams_Var" + string$(var_num)
        recon_params = selected()
        
        # DRAMATIC TRANSFORMATIONS
        if var_num = 1
            # EXTREME pitch shift up (chipmunk)
            Formula: "if row = 1 then self * 1.8 else self fi"
        elsif var_num = 2
            # EXTREME pitch down + formant shift (monster voice)
            Formula: "if row = 1 then self * 0.6 else if row >= 2 then self * 0.75 else self fi fi"
        elsif var_num = 3
            # RADICAL gender change
            Formula: "if row = 1 then self * 0.7 else if row >= 2 then self * 1.35 else self fi fi"
        elsif var_num = 4
            # Formant SCRAMBLE
            Formula: "if row = 2 then self[3, col] * 1.2 else if row = 3 then self[2, col] * 0.85 else self fi fi"
        elsif var_num = 5
            # Extreme VIBRATO
            Formula: "if row = 1 then self * (1 + 0.2 * sin(2 * pi * 5.5 * col * 'dt')) else self fi"
        elsif var_num = 6
            # CRUSH formants
            Formula: "if row >= 2 then 1200 + (self - 1200) * 0.4 else self fi"
        elsif var_num = 7
            # Pitch GLITCH
            Formula: "if row = 1 then self * (2 ^ floor(randomUniform(-1, 1.5))) else self fi"
        endif
    endif
    
    # 7. Apply PSOLA with modified pitch
    appendInfoLine: "  Applying PSOLA for " + var_name$ + "…"
    
    # A. Create new PitchTier from reconstructed parameters
    Create PitchTier: "ModifiedPitch_" + var_name$, start_time, end_time
    new_pitch_tier = selected()
    
    num_points_added = 0
    for col from 1 to num_frames
        time_t = start_time + (col - 1) * dt
        selectObject: recon_params
        f0_val = Get value in cell: 1, col 
        
        # Only add points for voiced regions
        if f0_val > 0
            # Ensure valid pitch
            if f0_val < pitch_floor
               f0_val = pitch_floor
            endif
            if f0_val > pitch_ceiling * 1.5
               f0_val = pitch_ceiling * 1.5
            endif
            
            selectObject: new_pitch_tier
            Add point: time_t, f0_val
            num_points_added = num_points_added + 1
        endif
    endfor
    
    appendInfoLine: "    Added " + string$(num_points_added) + " pitch points"
    
    # B. Create Manipulation with modified pitch (PSOLA happens here)
    selectObject: sound
    To Manipulation: 0.01, pitch_floor, pitch_ceiling
    manip_var = selected()
    
    # Replace pitch tier only if we have points
    if num_points_added > 0
        plusObject: new_pitch_tier
        Replace pitch tier
    endif
    
    # Get PSOLA resynthesis
    selectObject: manip_var
    Get resynthesis (overlap-add)
    Rename: "PSOLA_" + var_name$
    psola_sound = selected()
    
    # C. Apply smooth formant shifting
    selectObject: recon_params
    
    avg_f1_orig = 0
    avg_f2_orig = 0
    avg_f1_new = 0
    avg_f2_new = 0
    count = 0
    
    for col from 1 to min(50, num_frames)
        selectObject: "Matrix ParamMatrix"
        f1_o = Get value in cell: 2, col
        f2_o = Get value in cell: 3, col
        f0_check = Get value in cell: 1, col
        selectObject: recon_params
        f1_n = Get value in cell: 2, col
        f2_n = Get value in cell: 3, col
        
        # Only use voiced frames with valid formants
        if f0_check > 0 and f1_o > 200 and f2_o > 500
            avg_f1_orig = avg_f1_orig + f1_o
            avg_f2_orig = avg_f2_orig + f2_o
            avg_f1_new = avg_f1_new + f1_n
            avg_f2_new = avg_f2_new + f2_n
            count = count + 1
        endif
    endfor
    
    if count > 5
        avg_f1_orig = avg_f1_orig / count
        avg_f2_orig = avg_f2_orig / count
        avg_f1_new = avg_f1_new / count
        avg_f2_new = avg_f2_new / count
        
        # Calculate formant shift ratio (geometric mean)
        formant_shift_ratio = sqrt((avg_f1_new / avg_f1_orig) * (avg_f2_new / avg_f2_orig))
    else
        formant_shift_ratio = 1.0
    endif
    
    # Apply formant shifting if significant
    if abs(formant_shift_ratio - 1.0) > 0.05
        appendInfoLine: "    Applying formant shift: " + fixed$(formant_shift_ratio, 3)
        selectObject: psola_sound
        Change gender: pitch_floor, pitch_ceiling, formant_shift_ratio, 0, 1.0, 1.0
        Rename: "Resynth_" + sound_name$ + "_" + var_name$
        final_sound = selected()
        
        # Cleanup
        selectObject: psola_sound
        Remove
    else
        selectObject: psola_sound
        Rename: "Resynth_" + sound_name$ + "_" + var_name$
        final_sound = selected()
    endif
    
    # Normalize
    selectObject: final_sound
    Scale peak: 0.95
    
    # Cleanup temporary objects for this variation
    selectObject: recon_params
    plusObject: new_pitch_tier
    plusObject: manip_var
    Remove
endfor

# 8. Cleanup main objects
selectObject: sound
plusObject: pitch_obj
plusObject: formant_obj
plusObject: manipulation_orig
plusObject: pitch_tier_orig
plusObject: "Matrix ParamMatrix"
plusObject: norm_mat
plusObject: train_mat
plusObject: pattern_in
plusObject: activ_out
plusObject: net
plusObject: pattern_in2
plusObject: activ_recon
plusObject: matrix_from_activ
plusObject: recon_mat_full
plusObject: recon_params_base
Remove

# 9. Select all created sounds
selectObject: sound_orig
for var_num from 0 to num_variations
    if var_num = 0
        var_name$ = "Original"
    else
        var_name$ = "Var" + string$(var_num)
    endif
    plusObject: "Sound Resynth_" + sound_name$ + "_" + var_name$
endfor

appendInfoLine: ""
appendInfoLine: "=== DONE! ==="
appendInfoLine: "Created " + string$(num_variations + 1) + " PSOLA variations"
if draw_network = 1
    appendInfoLine: "Network visualization in Picture window"
endif
appendInfoLine: ""
appendInfoLine: "Original = exact autoencoder reconstruction"
appendInfoLine: "Var1 = CHIPMUNK"
appendInfoLine: "Var2 = MONSTER"
appendInfoLine: "Var3 = GENDER MORPH"