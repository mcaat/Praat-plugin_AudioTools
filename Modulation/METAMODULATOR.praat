# ============================================================
# Praat AudioTools - ADVANCED RING MODULATOR (Corrected & Merged)
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 2.0 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Modules Included (with ACCURATE formulas):
#  1. Cubic Phase Distortion (x^3)
#  2. Exponential Frequency Sweep
#  3. Logarithmic Frequency Sweep
#  4. Quadratic Phase Modulation (x^2 - TRUE quadratic)
#  5. Sinusoidal Frequency Modulation
#  6. Spiral Frequency Modulation
#  7. Time-Varying Ring Modulation (quadratic chirp)
#  8. Trembling Ring Modulation (vibrato + chirp)
#
# Usage:
#   Select a Sound object and run.
#   Choose a Preset for instant results, or 'Custom' to tweak manually.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit 
#   for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

form Advanced Ring Modulator
    comment ========================================
    comment           PRESETS
    comment ========================================
    optionmenu Preset 1
        option Custom (Use Manual Settings)
        option --- Cubic Phase Distortion ---
        option Cubic: Mild Distortion
        option Cubic: Strong Distortion
        option Cubic: High Frequency
        option --- Exponential Sweep ---
        option ExpSweep: Slow
        option ExpSweep: Fast
        option ExpSweep: Narrow Range
        option --- Logarithmic Sweep ---
        option LogSweep: Descending Classic
        option LogSweep: Fast Descent
        option --- Quadratic Phase ---
        option Quad: Gentle Bend
        option Quad: Classic Sweep
        option Quad: Dramatic Warp
        option Quad: Reverse Bend
        option Quad: Extreme Distortion
        option Quad: Subtle Shimmer
        option --- Sinusoidal FM ---
        option SinFM: Classic
        option SinFM: Deep Modulation
        option --- Spiral FM ---
        option Spiral: Gentle
        option Spiral: Classic Vortex
        option Spiral: Intense Whirlpool
        option Spiral: Deep Rotation
        option Spiral: Hypnotic Spin
        option Spiral: Cosmic
        option --- Time-Varying (Chirp) ---
        option TimeVar: Subtle Shimmer
        option TimeVar: Rising Metallic
        option TimeVar: Sci-Fi Sweep
        option TimeVar: Laser Beam
        option TimeVar: Extreme Glitch
        option --- Trembling (Vibrato+Chirp) ---
        option Tremble: Gentle Warble
        option Tremble: Radio Interference
        option Tremble: Deep Space
        option Tremble: Vintage Synth
        option Tremble: Alien Voice

    comment 
    comment ========================================
    comment      MANUAL SETTINGS (Custom Mode)
    comment ========================================
    comment Select Algorithm:
    optionmenu Manual_Algorithm 1
        option 1. Cubic Phase Distortion
        option 2. Exponential Frequency Sweep
        option 3. Logarithmic Frequency Sweep
        option 4. Quadratic Phase Modulation
        option 5. Sinusoidal FM
        option 6. Spiral FM
        option 7. Time-Varying (Chirp)
        option 8. Trembling (Vibrato+Chirp)
    
    comment --- Frequency Parameters ---
    positive Carrier_Frequency_Hz 200
    comment (base frequency for modulation)
    
    positive Start_Frequency_Hz 100
    comment (for sweep algorithms 2 and 3)
    
    positive End_Frequency_Hz 800
    comment (for sweep algorithms 2 and 3)
    
    comment --- Modulation/Distortion Parameters ---
    real Modulation_Factor 2.0
    comment (depth/amount: cubic_factor, phase_curve, mod_depth, etc.)
    
    positive Modulation_Rate_Hz 5.0
    comment (LFO rate for algorithms 5, 6, 8)
    
    comment --- Output Control ---
    positive Scale_peak 0.99
    boolean Play_result 1
endform

# ============================================================
# Check Selection
# ============================================================
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

sound = selected("Sound")
name$ = selected$("Sound")

# ============================================================
# PRESET LOGIC - Initialize with Manual Settings
# ============================================================
algo = manual_Algorithm
f0 = carrier_Frequency_Hz
f_start = start_Frequency_Hz
f_end = end_Frequency_Hz
mod_factor = modulation_Factor
mod_rate = modulation_Rate_Hz

# Override if preset is selected
if preset$ = "Cubic: Mild Distortion"
    algo = 1
    f0 = 100
    mod_factor = 1

elsif preset$ = "Cubic: Strong Distortion"
    algo = 1
    f0 = 200
    mod_factor = 4

elsif preset$ = "Cubic: High Frequency"
    algo = 1
    f0 = 300
    mod_factor = 2.5

elsif preset$ = "ExpSweep: Slow"
    algo = 2
    f_start = 100
    f_end = 600

elsif preset$ = "ExpSweep: Fast"
    algo = 2
    f_start = 50
    f_end = 1200

elsif preset$ = "ExpSweep: Narrow Range"
    algo = 2
    f_start = 200
    f_end = 400

elsif preset$ = "LogSweep: Descending Classic"
    algo = 3
    f_start = 800
    f_end = 50

elsif preset$ = "LogSweep: Fast Descent"
    algo = 3
    f_start = 1000
    f_end = 100

elsif preset$ = "Quad: Gentle Bend"
    algo = 4
    f0 = 150
    mod_factor = 0.3

elsif preset$ = "Quad: Classic Sweep"
    algo = 4
    f0 = 200
    mod_factor = 0.5

elsif preset$ = "Quad: Dramatic Warp"
    algo = 4
    f0 = 250
    mod_factor = 1.0

elsif preset$ = "Quad: Reverse Bend"
    algo = 4
    f0 = 180
    mod_factor = -0.4

elsif preset$ = "Quad: Extreme Distortion"
    algo = 4
    f0 = 300
    mod_factor = 1.5

elsif preset$ = "Quad: Subtle Shimmer"
    algo = 4
    f0 = 120
    mod_factor = 0.1

elsif preset$ = "SinFM: Classic"
    algo = 5
    f0 = 300
    mod_rate = 2
    mod_factor = 100

elsif preset$ = "SinFM: Deep Modulation"
    algo = 5
    f0 = 400
    mod_rate = 3
    mod_factor = 200

elsif preset$ = "Spiral: Gentle"
    algo = 6
    f0 = 200
    mod_rate = 0.5
    mod_factor = 80

elsif preset$ = "Spiral: Classic Vortex"
    algo = 6
    f0 = 250
    mod_rate = 0.8
    mod_factor = 150

elsif preset$ = "Spiral: Intense Whirlpool"
    algo = 6
    f0 = 300
    mod_rate = 1.2
    mod_factor = 200

elsif preset$ = "Spiral: Deep Rotation"
    algo = 6
    f0 = 150
    mod_rate = 0.6
    mod_factor = 120

elsif preset$ = "Spiral: Hypnotic Spin"
    algo = 6
    f0 = 400
    mod_rate = 1.5
    mod_factor = 180

elsif preset$ = "Spiral: Cosmic"
    algo = 6
    f0 = 180
    mod_rate = 0.7
    mod_factor = 250

elsif preset$ = "TimeVar: Subtle Shimmer"
    algo = 7
    f0 = 100

elsif preset$ = "TimeVar: Rising Metallic"
    algo = 7
    f0 = 200

elsif preset$ = "TimeVar: Sci-Fi Sweep"
    algo = 7
    f0 = 300

elsif preset$ = "TimeVar: Laser Beam"
    algo = 7
    f0 = 500

elsif preset$ = "TimeVar: Extreme Glitch"
    algo = 7
    f0 = 800

elsif preset$ = "Tremble: Gentle Warble"
    algo = 8
    f0 = 200
    mod_rate = 5
    mod_factor = 0.03

elsif preset$ = "Tremble: Radio Interference"
    algo = 8
    f0 = 440
    mod_rate = 25
    mod_factor = 0.08

elsif preset$ = "Tremble: Deep Space"
    algo = 8
    f0 = 100
    mod_rate = 10
    mod_factor = 0.1

elsif preset$ = "Tremble: Vintage Synth"
    algo = 8
    f0 = 300
    mod_rate = 20
    mod_factor = 0.06

elsif preset$ = "Tremble: Alien Voice"
    algo = 8
    f0 = 150
    mod_rate = 30
    mod_factor = 0.12

endif

# ============================================================
# Generate Suffix based on Algorithm
# ============================================================
algo_name$ = ""
if algo = 1
    algo_name$ = "_Cubic"
elsif algo = 2
    algo_name$ = "_ExpSweep"
elsif algo = 3
    algo_name$ = "_LogSweep"
elsif algo = 4
    algo_name$ = "_Quad"
elsif algo = 5
    algo_name$ = "_SinFM"
elsif algo = 6
    algo_name$ = "_Spiral"
elsif algo = 7
    algo_name$ = "_TimeVar"
elsif algo = 8
    algo_name$ = "_Tremble"
endif

# ============================================================
# Copy Sound and Apply Algorithm
# ============================================================
selectObject: sound
Copy: name$ + algo_name$

# ============================================================
# ALGORITHM IMPLEMENTATION (CORRECTED FORMULAS)
# ============================================================

# 1. CUBIC PHASE DISTORTION (x^3 - harsh, edgy distortion)
# Original formula: self * sin(2*pi*f0*x + cubic_factor*x^3)
if algo = 1
    Formula: "self * sin(2 * pi * 'f0' * x + 'mod_factor' * (x^3))"

# 2. EXPONENTIAL FREQUENCY SWEEP
# Original formula: self * sin(2*pi*f_start*exp(ln(f_end/f_start)*x/xmax)*x)
elsif algo = 2
    Formula: "self * sin(2 * pi * 'f_start' * exp(ln('f_end'/'f_start') * x/xmax) * x)"

# 3. LOGARITHMIC FREQUENCY SWEEP
# Original formula: self * sin(2*pi*f_start*exp(-ln(f_start/f_end)*x/xmax)*x)
elsif algo = 3
    Formula: "self * sin(2 * pi * 'f_start' * exp(-ln('f_start'/'f_end') * x/xmax) * x)"

# 4. QUADRATIC PHASE MODULATION (x^2 - softer, tubey distortion)
# CORRECTED: Changed from x^3 to x^2 for true quadratic behavior
elsif algo = 4
    Formula: "self * sin(2 * pi * 'f0' * x + 'mod_factor' * (x^2))"

# 5. SINUSOIDAL FREQUENCY MODULATION
# Original formula: self * sin(2*pi*(carrier_f0 + mod_depth*sin(2*pi*mod_rate*x))*x)
elsif algo = 5
    Formula: "self * sin(2 * pi * ('f0' + 'mod_factor' * sin(2 * pi * 'mod_rate' * x)) * x)"

# 6. SPIRAL FREQUENCY MODULATION
# Original formula: self * sin(2*pi*(center_f0 + spiral_depth*sin(spiral_rate*x)*x/xmax)*x)
elsif algo = 6
    Formula: "self * sin(2 * pi * ('f0' + 'mod_factor' * sin('mod_rate' * x) * x/xmax) * x)"

# 7. TIME VARYING RING MODULATION (quadratic chirp)
# Original formula: self * sin(2*pi*f0*x*x/2)
elsif algo = 7
    Formula: "self * sin(2 * pi * 'f0' * x * x / 2)"

# 8. TREMBLING RING MODULATION (vibrato + chirp)
# Original formula: self * sin(2*pi*f0*(1 + vibrato_depth*sin(2*pi*vibrato_rate*x))*x*x/2)
elsif algo = 8
    Formula: "self * sin(2 * pi * 'f0' * (1 + 'mod_factor' * sin(2 * pi * 'mod_rate' * x)) * x * x / 2)"

endif

# ============================================================
# Finalize Output
# ============================================================
Scale peak: scale_peak

if play_result
    Play
endif

# Done!