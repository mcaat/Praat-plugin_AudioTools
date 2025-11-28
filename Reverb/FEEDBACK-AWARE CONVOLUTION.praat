# ============================================================
# Praat AudioTools - FEEDBACK-AWARE CONVOLUTION
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   FEEDBACK-AWARE CONVOLUTION
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# ==============================================================================
# USER INTERFACE FORM
# ==============================================================================

form Feedback-Aware Convolution
    comment === PARAMETER EXTRACTION ===
    optionmenu Parameter_type: 1
        option Intensity
        option Pitch
    
    comment 
    comment === THRESHOLD DETECTION ===
    comment Detection threshold controls which parameter values trigger impulses:
    positive Detection_threshold 75
    comment   • Intensity mode: dB threshold (50-80 typical for speech/music)
    comment   • Pitch mode: Hz threshold (150-300 typical for melodic events)
    
    comment 
    comment === PITCH-SPECIFIC SETTINGS (ignored in Intensity mode) ===
    positive Pitch_floor_(Hz) 80
    comment   Sets minimum pitch for analysis (avoids low-frequency junk)
    comment   Typical: 80 Hz (male ~100-150 Hz, female ~180-250 Hz F0)
    
    positive Pitch_ceiling_(Hz) 600
    comment   Sets maximum pitch for analysis
    
    comment 
    comment === TEMPORAL CONTROL ===
    positive Minimum_impulse_spacing_(seconds) 0.05
    comment (Prevents impulse crowding - acts as refractory period)
    
    comment 
    comment === IMPULSE CHARACTERISTICS ===
    positive Impulse_duration_(seconds) 0.0003
    comment (Controls temporal width of each impulse)
    
    positive Amplitude_mapping_strength 1.0
    comment (0.5 = subtle, 1.0 = normal, 2.0 = intense modulation)
    
    comment 
    comment === ADVANCED OPTIONS ===
    positive Parameter_sample_rate_(Hz) 1000
    comment (Higher = more precision, slower processing)
endform

# ==============================================================================
# TRANSFER FORM VALUES TO VARIABLES
# ==============================================================================

# Convert form values to script variables
# Convert parameter type to lowercase for consistency
parameter_type$ = replace_regex$ (parameter_type$, ".", "\L&", 0)
detection_threshold = detection_threshold
pitch_floor = pitch_floor
pitch_ceiling = pitch_ceiling
min_impulse_spacing = minimum_impulse_spacing
impulse_duration = impulse_duration
amplitude_mapping_strength = amplitude_mapping_strength
parameter_sample_rate = parameter_sample_rate

# ==============================================================================
# SCRIPT EXECUTION
# ==============================================================================

# ------------------------------------------------------------------------------
# STEP 1: Get the selected sound
# ------------------------------------------------------------------------------
sound_name$ = selected$ ("Sound")
sound_id = selected ("Sound")

# Get sound properties
select sound_id
duration = Get total duration
sampling_frequency = Get sampling frequency
num_channels = Get number of channels

writeInfoLine: "=== Feedback-Aware Convolution ==="
appendInfoLine: "Sound: ", sound_name$
appendInfoLine: "Duration: ", fixed$ (duration, 3), " seconds"
appendInfoLine: "Sampling frequency: ", sampling_frequency, " Hz"
appendInfoLine: "Parameter type: ", parameter_type$
appendInfoLine: "Detection threshold: ", detection_threshold
appendInfoLine: "Min impulse spacing: ", min_impulse_spacing, " s"
appendInfoLine: ""

# ------------------------------------------------------------------------------
# STEP 2: Extract parameter (intensity or pitch) at high sampling rate
# ------------------------------------------------------------------------------
appendInfoLine: "Extracting ", parameter_type$, " parameter..."

if parameter_type$ = "intensity"
    # Extract intensity with high temporal resolution
    select sound_id
    To Intensity: 75, 0.001, "yes"
    intensity_id = selected ("Intensity")
    
    # Resample intensity to desired sampling rate
    select intensity_id
    Down to IntensityTier
    intensity_tier_id = selected ("IntensityTier")
    
    # Store parameter object for later use
    parameter_id = intensity_tier_id
    parameter_name$ = "Intensity"
    
    # Clean up intermediate objects
    select intensity_id
    Remove
    
elsif parameter_type$ = "pitch"
    # Extract pitch with user-specified analysis range
    appendInfoLine: "  Pitch analysis range: ", fixed$ (pitch_floor, 1), " - ", fixed$ (pitch_ceiling, 1), " Hz"
    
    select sound_id
    To Pitch: 0.001, pitch_floor, pitch_ceiling
    pitch_id = selected ("Pitch")
    
    # Store parameter object for later use (we'll sample it directly)
    parameter_id = pitch_id
    parameter_name$ = "Pitch"
else
    exitScript: "Error: parameter_type$ must be 'intensity' or 'pitch'"
endif

appendInfoLine: parameter_name$, " extracted successfully"
appendInfoLine: ""

# ------------------------------------------------------------------------------
# STEP 3: Detect threshold crossing events
# ------------------------------------------------------------------------------
appendInfoLine: "Detecting threshold crossings (threshold = ", detection_threshold, ")..."

# Create arrays to store impulse times and corresponding parameter values
# (Praat doesn't have dynamic arrays, so we'll use a reasonable maximum)
max_impulses = 10000
impulse_count = 0

if parameter_type$ = "intensity"
    # For intensity: iterate through IntensityTier points
    select parameter_id
    num_points = Get number of points
    
    last_impulse_time = -1
    for i from 1 to num_points
        select parameter_id
        time = Get time from index: i
        value = Get value at index: i
        
        # Check if value exceeds threshold and respects minimum spacing
        if value > detection_threshold and (time - last_impulse_time) >= min_impulse_spacing
            impulse_count += 1
            
            # Store impulse time and parameter value
            impulse_time_'impulse_count' = time
            impulse_value_'impulse_count' = value
            
            last_impulse_time = time
            
            # Safety check to prevent array overflow
            if impulse_count >= max_impulses
                appendInfoLine: "Warning: Maximum impulse count reached (", max_impulses, ")"
                goto end_detection
            endif
        endif
    endfor
    
elsif parameter_type$ = "pitch"
    # For pitch: sample at regular intervals
    select parameter_id
    time_step = 1 / parameter_sample_rate
    current_time = 0
    last_impulse_time = -1
    
    # Track pitch statistics for debugging
    min_pitch = 10000
    max_pitch = 0
    pitch_samples = 0
    defined_samples = 0
    
    while current_time <= duration
        select parameter_id
        value = Get value at time: current_time, "Hertz", "Linear"
        
        pitch_samples += 1
        
        # Check if pitch is defined (not undefined)
        if value <> undefined
            defined_samples += 1
            
            # Track min/max pitch
            if value < min_pitch
                min_pitch = value
            endif
            if value > max_pitch
                max_pitch = value
            endif
            
            # Check if value exceeds threshold and respects minimum spacing
            if value > detection_threshold and (current_time - last_impulse_time) >= min_impulse_spacing
                impulse_count += 1
                
                # Store impulse time and parameter value
                impulse_time_'impulse_count' = current_time
                impulse_value_'impulse_count' = value
                
                last_impulse_time = current_time
                
                # Safety check to prevent array overflow
                if impulse_count >= max_impulses
                    appendInfoLine: "Warning: Maximum impulse count reached (", max_impulses, ")"
                    goto end_detection
                endif
            endif
        endif
        
        current_time += time_step
    endwhile
    
    # Report pitch statistics
    appendInfoLine: "  Pitch statistics:"
    appendInfoLine: "    Defined pitch in ", defined_samples, "/", pitch_samples, " samples"
    if defined_samples > 0
        appendInfoLine: "    Pitch range: ", fixed$ (min_pitch, 1), " - ", fixed$ (max_pitch, 1), " Hz"
    endif
endif

label end_detection

appendInfoLine: "Detected ", impulse_count, " impulse events"
appendInfoLine: ""

# Check if any impulses were detected
if impulse_count = 0
    exitScript: "No impulses detected. Try lowering the threshold."
endif

# ------------------------------------------------------------------------------
# STEP 4: Generate impulse train based on detected events
# ------------------------------------------------------------------------------
appendInfoLine: "Generating impulse train..."

# Create a silent sound to hold the impulse train
select sound_id
Create Sound from formula: "impulse_train", num_channels, 0, duration, 
    ... sampling_frequency, "0"
impulse_train_id = selected ("Sound")

# Add impulses at detected times with parameter-mapped amplitudes
for i from 1 to impulse_count
    time = impulse_time_'i'
    value = impulse_value_'i'
    
    # Map parameter value to amplitude (normalize to 0-1 range)
    if parameter_type$ = "intensity"
        # Intensity typically ranges from 40-80 dB
        normalized_value = (value - 40) / 40
    elsif parameter_type$ = "pitch"
        # Pitch - normalize relative to threshold
        normalized_value = (value - detection_threshold) / detection_threshold
    endif
    
    # Clamp to valid range and apply mapping strength
    normalized_value = max (0, min (1, normalized_value))
    amplitude = normalized_value * amplitude_mapping_strength
    
    # Generate single impulse
    select impulse_train_id
    impulse_start = max (0, time - impulse_duration / 2)
    impulse_end = min (duration, time + impulse_duration / 2)
    
    # Create impulse formula (Gaussian envelope)
    Formula (part): impulse_start, impulse_end, 1, 1,
        ... "if x < 'time' - 'impulse_duration'/2 or x > 'time' + 'impulse_duration'/2 
        ... then self 
        ... else self + 'amplitude' * exp(-((x-'time')/('impulse_duration'/6))^2) 
        ... fi"
    
    if num_channels = 2
        Formula (part): impulse_start, impulse_end, 2, 2,
            ... "if x < 'time' - 'impulse_duration'/2 or x > 'time' + 'impulse_duration'/2 
            ... then self 
            ... else self + 'amplitude' * exp(-((x-'time')/('impulse_duration'/6))^2) 
            ... fi"
    endif
endfor

appendInfoLine: "Impulse train generated with ", impulse_count, " impulses"
appendInfoLine: ""

# ------------------------------------------------------------------------------
# STEP 5: Perform convolution
# ------------------------------------------------------------------------------
appendInfoLine: "Performing convolution..."

select sound_id
plus impulse_train_id
Convolve: "integral", "zero"
convolved_id = selected ("Sound")

# Normalize to prevent clipping
select convolved_id
Scale peak: 0.99

appendInfoLine: "Convolution complete"
appendInfoLine: ""

# ------------------------------------------------------------------------------
# STEP 6: Play the result
# ------------------------------------------------------------------------------
appendInfoLine: "Playing result..."

select convolved_id
Rename: sound_name$ + "_feedback_conv"
Play

appendInfoLine: ""
appendInfoLine: "=== Processing Complete ==="
appendInfoLine: "Result: ", selected$ ("Sound")
appendInfoLine: "Impulse count: ", impulse_count
appendInfoLine: ""

# ------------------------------------------------------------------------------
# CLEANUP - Remove intermediate objects
# ------------------------------------------------------------------------------
select impulse_train_id
Remove
select parameter_id
Remove

# Final selection
select convolved_id

###############################################################################
# END OF SCRIPT
###############################################################################

# ==============================================================================
# USAGE NOTES:
# ==============================================================================
# 1. Select a sound in the Praat object list before running this script
# 
# 2. The form dialog will appear with these parameters:
#
#    PARAMETER TYPE: Intensity or Pitch
#      Determines what acoustic feature drives the impulse generation
#
#    DETECTION THRESHOLD: 
#      *** SEMANTICS DIFFER BY MODE ***
#      • Intensity mode: dB threshold (e.g., 50-75 for speech/music)
#        Only intensity values ABOVE this trigger impulses
#      • Pitch mode: Hz threshold (e.g., 150-300 for melodic events)
#        Only pitch values ABOVE this trigger impulses
#
#    PITCH FLOOR & CEILING (pitch mode only):
#      Sets the analysis range for pitch detection
#      • Floor: Minimum pitch to analyze (default 80 Hz avoids low junk)
#      • Ceiling: Maximum pitch to analyze (default 600 Hz)
#      Note: Detection threshold operates WITHIN this analysis range
#
#    MINIMUM IMPULSE SPACING:
#      Refractory period - prevents too many impulses (default 0.05s)
#
#    IMPULSE DURATION:
#      Temporal width of each impulse (default 0.001s)
#
#    AMPLITUDE MAPPING STRENGTH:
#      How strongly parameter values modulate impulse amplitude
#      (0.5=subtle, 1.0=normal, 2.0=intense)
#
#    PARAMETER SAMPLE RATE:
#      Temporal resolution for detection (default 1000 Hz)
#
# 3. For intensity-based convolution:
#    - Lower threshold (50-60 dB) = more impulses, denser texture
#    - Higher threshold (70-80 dB) = fewer impulses, sparser texture
#    - Threshold is in dB SPL
#
# 4. For pitch-based convolution:
#    - Pitch floor/ceiling define analysis range (what CAN be detected)
#    - Detection threshold filters within that range (what WILL trigger impulses)
#    - Example: Floor=80, Ceiling=600, Threshold=200
#      → Analyzes 80-600 Hz, but only pitches >200 Hz trigger impulses
#    - Check Info window for actual pitch range in your sound
#    - Works best with sounds that have clear pitch (melodic, harmonic)
#
# 5. Creative applications:
#    - Self-modulating reverb/delay effects
#    - Dynamic convolution based on sound energy
#    - Pitch-triggered granulation
#    - Feedback-driven spectral processing
#    - Event-based sonic textures
#
# 6. Processing notes:
#    - Intermediate objects (impulse train, parameter tier) are auto-cleaned
#    - Processing info is displayed in the Info window
#    - Result is automatically played and selected
#    - Pitch mode shows min/max pitch range for threshold tuning
#
# ==============================================================================