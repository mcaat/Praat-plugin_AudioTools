# ============================================================
# Praat AudioTools - Universal Convolution Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Universal Convolution Generator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# --- STEP 1: Main Selection Window ---
beginPause: "Universal Convolver - Step 1"
    comment: "Select your generation algorithm:"
    optionmenu: "Algorithm", 1
        option: "Accelerando"
        option: "Bouncing Ball"
        option: "Bursts and Taps (Ping-Pong)"
        option: "Euclidean Rhythm"
        option: "Fibonacci (Mono)"
        option: "Golden Angle Drift"
        option: "Random Walk"
        option: "Stereo Fibonacci"
        option: "Swing"
    
    comment: "General Settings:"
    positive: "Duration", 2.0
    boolean: "Play after processing", 1
endPause: "Next >>", 1

# --- STEP 2: Context-Aware Parameter Window ---

if algorithm$ = "Accelerando"
    beginPause: "Settings: Accelerando"
        positive: "First hit time", 0.10
        natural: "Number of pulses", 24
        positive: "Gap shrink ratio (0-1)", 0.85
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1
    
    # Map variables
    accel_First_hit_time = first_hit_time
    accel_Number_of_pulses = number_of_pulses
    accel_Gap_shrink_ratio = gap_shrink_ratio

elsif algorithm$ = "Bouncing Ball"
    beginPause: "Settings: Bouncing Ball"
        positive: "First bounce time", 0.10
        positive: "Gravity", 9.81
        positive: "Initial velocity", 3.0
        positive: "Bounce coefficient", 0.60
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    ball_First_bounce_time = first_bounce_time
    ball_Gravity = gravity
    ball_Initial_velocity = initial_velocity
    ball_Bounce_coefficient = bounce_coefficient

elsif algorithm$ = "Bursts and Taps (Ping-Pong)"
    beginPause: "Settings: Bursts & Taps"
        positive: "Tap 1 time", 0.15
        positive: "Tap 2 time", 1.20
        natural: "Number of bursts", 3
        natural: "Points per burst", 10
        positive: "Burst StdDev", 0.035
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    burst_Tap_1_time = tap_1_time
    burst_Tap_2_time = tap_2_time
    burst_Number_of_bursts = number_of_bursts
    burst_Points_per_burst = points_per_burst
    burst_Stddev = burst_StdDev

elsif algorithm$ = "Euclidean Rhythm"
    beginPause: "Settings: Euclidean"
        natural: "Total Steps", 16
        natural: "Active Pulses", 5
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    euclid_Steps = total_Steps
    euclid_Pulses = active_Pulses

elsif algorithm$ = "Fibonacci (Mono)"
    beginPause: "Settings: Fibonacci"
        natural: "Number of impulses", 12
        positive: "Scale divisor", 100.0
        # Added Jitter parameter here to merge the 'random jitter' script
        positive: "Jitter (std dev)", 0.1
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    fib_Number_of_impulses = number_of_impulses
    fib_Scale_divisor = scale_divisor
    fib_Jitter = jitter

elsif algorithm$ = "Golden Angle Drift"
    beginPause: "Settings: Golden Angle"
        natural: "Number of impulses", 24
        positive: "Margin", 0.10
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    fib_Number_of_impulses = number_of_impulses
    golden_Margin_seconds = margin

elsif algorithm$ = "Random Walk"
    beginPause: "Settings: Random Walk"
        positive: "Initial gap", 0.18
        positive: "Gap variation", 0.015
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    random_Initial_gap = initial_gap
    random_Gap_variation = gap_variation

elsif algorithm$ = "Stereo Fibonacci"
    beginPause: "Settings: Stereo Fibonacci"
        natural: "Number of impulses", 12
        comment: "Left Channel Starts:"
        positive: "Left Start 1", 1
        positive: "Left Start 2", 1
        comment: "Right Channel Starts:"
        positive: "Right Start 1", 2
        positive: "Right Start 2", 3
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    fib_Number_of_impulses = number_of_impulses
    stereo_Left_fib_start_1 = left_Start_1
    stereo_Left_fib_start_2 = left_Start_2
    stereo_Right_fib_start_1 = right_Start_1
    stereo_Right_fib_start_2 = right_Start_2

elsif algorithm$ = "Swing"
    beginPause: "Settings: Swing"
        positive: "Tempo (BPM)", 120
        positive: "Swing Delay (s)", 0.06
        comment: "Technical:"
        positive: "Sampling frequency", 44100
    endPause: "Run", 1

    swing_Tempo_bpm = tempo
    swing_Delay_seconds = swing_Delay
endif

# --- Hardcoded Technical Defaults ---
pulse_amplitude = 1
pulse_width = 0.02
pulse_period = 2000
duration_seconds = duration

# --- EXECUTION LOGIC ---

# 1. Check Selection
if numberOfSelected("Sound") < 1
    exitScript: "Select a Sound in the Objects window first."
endif

selectObject: selected("Sound", 1)
originalName$ = selected$("Sound")
Copy: "XXXX_src"
selectObject: "Sound XXXX_src"
Resample: sampling_frequency, 50
Rename: "XXXX_resampled"

created_pulse_sound = 0

# 2. Algorithm Implementation
if algorithm$ = "Accelerando"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    remain = duration_seconds - accel_First_hit_time
    den = 1 - accel_Gap_shrink_ratio^accel_Number_of_pulses
    g0 = remain * (1 - accel_Gap_shrink_ratio) / den
    t = accel_First_hit_time
    i = 1
    while i <= accel_Number_of_pulses and t < duration_seconds
        Add point: t
        gap = g0 * accel_Gap_shrink_ratio^(i - 1)
        t = t + gap
        i = i + 1
    endwhile

elsif algorithm$ = "Bouncing Ball"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    t = ball_First_bounce_time
    v = ball_Initial_velocity
    if t > 0 and t < duration_seconds
        Add point: t
    endif
    dt = 2 * v / ball_Gravity
    count = 0
    while (t + dt < duration_seconds) and (dt >= 0.001) and (count < 50)
        t = t + dt
        Add point: t
        v = ball_Bounce_coefficient * v
        dt = 2 * v / ball_Gravity
        count = count + 1
    endwhile

elsif algorithm$ = "Bursts and Taps (Ping-Pong)"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    if burst_Tap_1_time < duration_seconds
        Add point: burst_Tap_1_time
    endif
    if burst_Tap_2_time < duration_seconds
        Add point: burst_Tap_2_time
    endif
    b = 1
    burst_min_time = 0.05 
    while b <= burst_Number_of_bursts
        c = randomUniform(burst_min_time, duration_seconds - burst_min_time)
        i = 1
        while i <= burst_Points_per_burst
            u = c + randomGauss(0, burst_Stddev)
            if u > 0 and u < duration_seconds
                Add point: u
            endif
            i = i + 1
        endwhile
        b = b + 1
    endwhile

elsif algorithm$ = "Euclidean Rhythm"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    step = duration_seconds / euclid_Steps
    i = 0
    while i < euclid_Steps
        if ((i * euclid_Pulses) mod euclid_Steps) < euclid_Pulses
            Add point: i * step
        endif
        i = i + 1
    endwhile

elsif algorithm$ = "Fibonacci (Mono)"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    f1 = 1
    f2 = 1
    for i from 1 to fib_Number_of_impulses
        # Standard calculation
        t_base = (f1 / fib_Scale_divisor) * duration_seconds
        
        # Apply Jitter (if any)
        if fib_Jitter > 0
            t = t_base + randomGauss(0, fib_Jitter)
        else
            t = t_base
        endif

        if t > 0 and t < duration_seconds
            Add point: t
        endif
        ft = f1 + f2
        f1 = f2
        f2 = ft
    endfor

elsif algorithm$ = "Golden Angle Drift"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    phi = (sqrt(5) - 1) / 2
    i = 1
    while i <= fib_Number_of_impulses
        u = (i * phi) - floor(i * phi)
        t = golden_Margin_seconds + u * (duration_seconds - 2 * golden_Margin_seconds)
        if t > 0 and t < duration_seconds
            Add point: t
        endif
        i = i + 1
    endwhile

elsif algorithm$ = "Random Walk"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    t = 0.10
    gap = random_Initial_gap
    i = 0
    while (t < duration_seconds) and (i < 400)
        Add point: t
        gap = gap + randomGauss(0, random_Gap_variation)
        if gap < 0.01
            gap = 0.01
        elsif gap > 0.65
            gap = 0.65
        endif
        t = t + gap
        i = i + 1
    endwhile

elsif algorithm$ = "Swing"
    Create empty PointProcess: "pp_gen", 0, duration_seconds
    selectObject: "PointProcess pp_gen"
    beat = 60 / swing_Tempo_bpm
    t = beat
    i = 1
    while t < duration_seconds
        if (i mod 2) = 0
            Add point: t + swing_Delay_seconds
        else
            Add point: t
        endif
        t = t + beat
        i = i + 1
    endwhile

elsif algorithm$ = "Stereo Fibonacci"
    # Left
    Create empty PointProcess: "pp_left", 0, duration_seconds
    f1 = stereo_Left_fib_start_1
    f2 = stereo_Left_fib_start_2
    for i from 1 to fib_Number_of_impulses
        t = (f1 / 100.0) * duration_seconds + randomGauss(0, 0.01)
        if t > 0 and t < duration_seconds
            Add point: t
        endif
        ft = f1 + f2
        f1 = f2
        f2 = ft
    endfor
    
    # Right
    Create empty PointProcess: "pp_right", 0, duration_seconds
    f1 = stereo_Right_fib_start_1
    f2 = stereo_Right_fib_start_2
    for i from 1 to fib_Number_of_impulses
        t = (f1 / 120.0) * duration_seconds + randomGauss(0, 0.02)
        if t > 0 and t < duration_seconds
            Add point: t
        endif
        ft = f1 + f2
        f1 = f2
        f2 = ft
    endfor
    
    selectObject: "PointProcess pp_left"
    To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
    Rename: "IMP_LEFT"
    
    selectObject: "PointProcess pp_right"
    To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
    Rename: "IMP_RIGHT"
    
    selectObject: "Sound IMP_LEFT"
    plusObject: "Sound IMP_RIGHT"
    Combine to stereo
    Rename: "IMPULSE_FINAL"
    
    removeObject: "Sound IMP_LEFT"
    removeObject: "Sound IMP_RIGHT"
    removeObject: "PointProcess pp_left"
    removeObject: "PointProcess pp_right"
    created_pulse_sound = 1
endif

# 3. Final Processing
if created_pulse_sound = 0
    selectObject: "PointProcess pp_gen"
    To Sound (pulse train): sampling_frequency, pulse_amplitude, pulse_width, pulse_period
    Rename: "IMPULSE_FINAL"
    Scale peak: 0.99
    removeObject: "PointProcess pp_gen"
endif

selectObject: "Sound XXXX_resampled"
plusObject: "Sound IMPULSE_FINAL"
Convolve: "peak 0.99", "zero"
Rename: originalName$ + "_conv_" + algorithm$

if play_after_processing
    Play
endif

removeObject: "Sound XXXX_src"
removeObject: "Sound XXXX_resampled"
removeObject: "Sound IMPULSE_FINAL"