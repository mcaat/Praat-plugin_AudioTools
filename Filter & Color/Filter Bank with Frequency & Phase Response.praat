# ============================================================
# Praat AudioTools - Classic Filter Bank with Frequency & Phase Response
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Implements: Bessel, Butterworth, Legendre, Chebyshev-I, Chebyshev-II, Elliptic
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Classic Filter Bank with Frequency & Phase Response + Z-Plane
# Implements: Bessel, Butterworth, Legendre, Chebyshev-I, Chebyshev-II, Elliptic

form Classic Filter Bank
    comment Select filter type:
    optionmenu Filter_type 2
        option Bessel
        option Butterworth
        option Legendre
        option Chebyshev Type I
        option Chebyshev Type II
        option Elliptic
    comment Filter configuration:
    optionmenu Filter_mode 1
        option Lowpass
        option Highpass
    comment Order (must be even: 2, 4, 6, 8):
    integer Order 4
    comment Cutoff frequency in Hz:
    positive Cutoff_frequency_(Hz) 1000
    comment Chebyshev/Elliptic parameters:
    positive Passband_ripple_(dB) 0.5
    positive Stopband_attenuation_(dB) 40
    boolean Plot_responses 1
    boolean Plot_zplane 1
    boolean Apply_filter 1
    boolean Play_result 1
endform

# Check that a Sound is selected
if numberOfSelected("Sound") = 0
    exitScript: "Please select a Sound object first"
endif

# Get selected sound
sound = selected("Sound")
sound_name$ = selected$("Sound")
fs = Get sampling frequency

# Validate
if order mod 2 != 0 or order < 2 or order > 8
    exitScript: "Order must be 2, 4, 6, or 8"
endif

if cutoff_frequency >= fs/2
    exitScript: "Cutoff must be below Nyquist (", fs/2, " Hz)"
endif

writeInfoLine: "Designing ", filter_type$, " ", filter_mode$, " filter..."

# Normalized frequency (0 to 1)
wn = cutoff_frequency / (fs/2)

# Pre-mirror the design frequency for highpass
if filter_mode = 2
    wn = 1 - wn
endif

# Number of second-order sections
nsections = order / 2

# Initialize coefficient arrays for each section
for sec to nsections
    sos_b0[sec] = 0
    sos_b1[sec] = 0
    sos_b2[sec] = 0
    sos_a0[sec] = 1
    sos_a1[sec] = 0
    sos_a2[sec] = 0
endfor

# Design filter based on type
if filter_type = 1
    @designBessel
elsif filter_type = 2
    @designButterworth
elsif filter_type = 3
    @designLegendre
elsif filter_type = 4
    @designChebyshev1
elsif filter_type = 5
    @designChebyshev2
elsif filter_type = 6
    @designElliptic
endif

appendInfoLine: "Filter design complete"

# Transform to highpass if needed
if filter_mode = 2
    @transformHighpass
endif

# Apply filter
if apply_filter
    selectObject: sound
    filtered = Copy: sound_name$ + "_" + filter_type$ + "_" + filter_mode$
    @applyCascadeFilter
    selectObject: filtered
    
    # Play result if requested
    if play_result
        Play
    endif
endif

# Plot everything
if plot_responses or plot_zplane
    Erase all
    
    if plot_responses
        @plotFrequencyResponse
    endif
    
    if plot_zplane
        @plotZPlane
    endif
endif

selectObject: sound
if apply_filter
    plusObject: filtered
endif

writeInfoLine: "Complete!"
appendInfoLine: "Cutoff: ", cutoff_frequency, " Hz"
appendInfoLine: "Mode: ", filter_mode$
appendInfoLine: "Type: ", filter_type$

# ============================================================
# BUTTERWORTH FILTER
# ============================================================
procedure designButterworth
    for sec_idx to nsections
        theta = pi/2 + pi*(2*sec_idx-1)/(2*order)
        pole_re = cos(theta)
        pole_im = sin(theta)
        @analogToDigitalSOS: sec_idx, pole_re, pole_im
    endfor
endproc

# ============================================================
# BESSEL FILTER
# ============================================================
procedure designBessel
    if order = 2
        poles_re[1] = -1.1030
        poles_im[1] = 0.6368
    elsif order = 4
        poles_re[1] = -0.9952
        poles_im[1] = 0.4105
        poles_re[2] = -1.3808
        poles_im[2] = 0.7179
    elsif order = 6
        poles_re[1] = -0.9606
        poles_im[1] = 0.3272
        poles_re[2] = -1.3808
        poles_im[2] = 0.5950
        poles_re[3] = -1.5715
        poles_im[3] = 0.6301
    elsif order = 8
        poles_re[1] = -0.9425
        poles_im[1] = 0.2735
        poles_re[2] = -1.3797
        poles_im[2] = 0.5120
        poles_re[3] = -1.6140
        poles_im[3] = 0.5950
        poles_re[4] = -1.7627
        poles_im[4] = 0.5787
    endif
    
    for sec_idx to nsections
        @analogToDigitalSOS: sec_idx, poles_re[sec_idx], poles_im[sec_idx]
    endfor
endproc

# ============================================================
# LEGENDRE FILTER
# ============================================================
procedure designLegendre
    for sec_idx to nsections
        theta = pi/2 + pi*(2*sec_idx-1)/(2*order)
        pole_re = 1.1 * cos(theta)
        pole_im = 1.1 * sin(theta)
        @analogToDigitalSOS: sec_idx, pole_re, pole_im
    endfor
endproc

# ============================================================
# CHEBYSHEV TYPE I
# ============================================================
procedure designChebyshev1
    epsilon = sqrt(10^(passband_ripple/10) - 1)
    sinh_val = arcsinh(1/epsilon) / order
    
    for sec_idx to nsections
        theta = pi*(2*sec_idx-1)/(2*order)
        pole_re = -sinh(sinh_val) * sin(theta)
        pole_im = cosh(sinh_val) * cos(theta)
        @analogToDigitalSOS: sec_idx, pole_re, pole_im
    endfor
endproc

# ============================================================
# CHEBYSHEV TYPE II
# ============================================================
procedure designChebyshev2
    epsilon = sqrt(10^(stopband_attenuation/10) - 1)
    sinh_val = arcsinh(epsilon) / order
    
    for sec_idx to nsections
        theta = pi*(2*sec_idx-1)/(2*order)
        s_re = sinh(sinh_val) * sin(theta)
        s_im = cosh(sinh_val) * cos(theta)
        mag_sq = s_re^2 + s_im^2
        pole_re = -s_re / mag_sq
        pole_im = s_im / mag_sq
        @analogToDigitalSOS: sec_idx, pole_re, pole_im
    endfor
endproc

# ============================================================
# ELLIPTIC FILTER
# ============================================================
procedure designElliptic
    epsilon = sqrt(10^(passband_ripple/10) - 1)
    sinh_val = arcsinh(1/epsilon) / order
    
    for sec_idx to nsections
        theta = pi*(2*sec_idx-1)/(2*order)
        pole_re = -0.95 * sinh(sinh_val) * sin(theta)
        pole_im = 0.95 * cosh(sinh_val) * cos(theta)
        @analogToDigitalSOS: sec_idx, pole_re, pole_im
    endfor
endproc

# ============================================================
# ANALOG TO DIGITAL CONVERSION
# ============================================================
procedure analogToDigitalSOS: .sec, .pr, .pi
    wp = 2 * tan(pi * wn / 2)
    pr_scaled = .pr * wp
    pi_scaled = .pi * wp
    r_sq = pr_scaled^2 + pi_scaled^2
    
    num0 = r_sq
    num1 = 2 * r_sq
    num2 = r_sq
    
    den0 = 4 - 4*pr_scaled + r_sq
    den1 = 2*r_sq - 8
    den2 = 4 + 4*pr_scaled + r_sq
    
    sos_b0[.sec] = num0 / den0
    sos_b1[.sec] = num1 / den0
    sos_b2[.sec] = num2 / den0
    sos_a0[.sec] = 1
    sos_a1[.sec] = den1 / den0
    sos_a2[.sec] = den2 / den0
endproc

# ============================================================
# TRANSFORM TO HIGHPASS
# ============================================================
procedure transformHighpass
    # Negate odd coefficients (z -> -z spectral inversion)
    for sec to nsections
        sos_b1[sec] = -sos_b1[sec]
        sos_a1[sec] = -sos_a1[sec]
    endfor
    
    # Normalize for unity gain at Nyquist
    total_gain = 1
    for sec to nsections
        num_nyq = sos_b0[sec] - sos_b1[sec] + sos_b2[sec]
        den_nyq = sos_a0[sec] - sos_a1[sec] + sos_a2[sec]
        if abs(den_nyq) > 0.0001
            total_gain *= num_nyq / den_nyq
        endif
    endfor
    
    if abs(total_gain) > 0.0001 and nsections > 0
        gain_per_section = total_gain^(1/nsections)
        for sec to nsections
            sos_b0[sec] /= gain_per_section
            sos_b1[sec] /= gain_per_section
            sos_b2[sec] /= gain_per_section
        endfor
    endif
endproc

# ============================================================
# APPLY CASCADE FILTER
# ============================================================
procedure applyCascadeFilter
    selectObject: filtered
    ns = Get number of samples
    nchannels = Get number of channels
    
    writeInfoLine: "Applying filter..."
    
    total_steps = nchannels * nsections * ns
    last_percent = -1
    
    for ch to nchannels
        for sec to nsections
            w1 = 0
            w2 = 0
            
            for n to ns
                if nchannels = 1
                    x = Get value at sample number: n
                else
                    x = Get value at sample number: ch, n
                endif
                
                y = sos_b0[sec] * x + w1
                w1 = sos_b1[sec] * x - sos_a1[sec] * y + w2
                w2 = sos_b2[sec] * x - sos_a2[sec] * y
                
                if nchannels = 1
                    Set value at sample number: n, y
                else
                    Set value at sample number: ch, n, y
                endif
                
                if n mod 5000 = 0
                    current_step = (ch-1) * nsections * ns + (sec-1) * ns + n
                    percentage = floor(current_step / total_steps * 100)
                    
                    if percentage != last_percent
                        writeInfoLine: "Filtering: ", percentage, "%"
                        last_percent = percentage
                    endif
                endif
            endfor
        endfor
    endfor
    
    writeInfoLine: "Filtering: 100%"
endproc

# ============================================================
# PLOT Z-PLANE (like Max/MSP zplane~)
# ============================================================
procedure plotZPlane
    # Calculate poles and zeros from SOS coefficients
    pole_count = 0
    zero_count = 0
    
    for sec to nsections
        # Extract zeros from numerator: b0*z^2 + b1*z + b2 = 0
        if abs(sos_b0[sec]) > 0.0001
            discriminant = sos_b1[sec]^2 - 4*sos_b0[sec]*sos_b2[sec]
            
            if discriminant >= 0
                sqrt_disc = sqrt(discriminant)
                zero_count += 1
                zero_re[zero_count] = (-sos_b1[sec] + sqrt_disc) / (2*sos_b0[sec])
                zero_im[zero_count] = 0
                
                zero_count += 1
                zero_re[zero_count] = (-sos_b1[sec] - sqrt_disc) / (2*sos_b0[sec])
                zero_im[zero_count] = 0
            else
                sqrt_disc = sqrt(-discriminant)
                zero_count += 1
                zero_re[zero_count] = -sos_b1[sec] / (2*sos_b0[sec])
                zero_im[zero_count] = sqrt_disc / (2*sos_b0[sec])
                
                zero_count += 1
                zero_re[zero_count] = -sos_b1[sec] / (2*sos_b0[sec])
                zero_im[zero_count] = -sqrt_disc / (2*sos_b0[sec])
            endif
        endif
        
        # Extract poles from denominator: a0*z^2 + a1*z + a2 = 0
        if abs(sos_a0[sec]) > 0.0001
            discriminant = sos_a1[sec]^2 - 4*sos_a0[sec]*sos_a2[sec]
            
            if discriminant >= 0
                sqrt_disc = sqrt(discriminant)
                pole_count += 1
                pole_re[pole_count] = (-sos_a1[sec] + sqrt_disc) / (2*sos_a0[sec])
                pole_im[pole_count] = 0
                
                pole_count += 1
                pole_re[pole_count] = (-sos_a1[sec] - sqrt_disc) / (2*sos_a0[sec])
                pole_im[pole_count] = 0
            else
                sqrt_disc = sqrt(-discriminant)
                pole_count += 1
                pole_re[pole_count] = -sos_a1[sec] / (2*sos_a0[sec])
                pole_im[pole_count] = sqrt_disc / (2*sos_a0[sec])
                
                pole_count += 1
                pole_re[pole_count] = -sos_a1[sec] / (2*sos_a0[sec])
                pole_im[pole_count] = -sqrt_disc / (2*sos_a0[sec])
            endif
        endif
    endfor
    
    # Draw Z-plane - BELOW the phase plot, centered
    Select outer viewport: 1.5, 5.5, 5.5, 9.5
    
    Axes: -1.3, 1.3, -1.3, 1.3
    Draw inner box
    Text left: "yes", "Imaginary"
    Text bottom: "yes", "Real"
    Text top: "no", "##Z-Plane: Poles & Zeros##"
    
    # Draw unit circle (stability boundary)
    Line width: 2
    Colour: "Blue"
    ncirc = 180
    for ang to ncirc
        rad = (ang - 1) * 2 * pi / ncirc
        x1 = cos(rad)
        y1 = sin(rad)
        rad2 = ang * 2 * pi / ncirc
        x2 = cos(rad2)
        y2 = sin(rad2)
        Draw line: x1, y1, x2, y2
    endfor
    
    # Draw axes
    Line width: 1
    Colour: "Silver"
    Draw line: -1.3, 0, 1.3, 0
    Draw line: 0, -1.3, 0, 1.3
    
    # Draw radial grid circles
    Colour: "{0.8,0.8,0.8}"
    for r to 3
        radius = r * 0.25
        for ang to 120
            rad = (ang - 1) * 2 * pi / 120
            x1 = radius * cos(rad)
            y1 = radius * sin(rad)
            rad2 = ang * 2 * pi / 120
            x2 = radius * cos(rad2)
            y2 = radius * sin(rad2)
            Draw line: x1, y1, x2, y2
        endfor
    endfor
    
    # Draw zeros (green circles O)
    Colour: "{0,0.7,0}"
    Line width: 3
    marker_size = 0.06
    for i to zero_count
        # Draw circle
        for ang to 24
            rad = (ang - 1) * 2 * pi / 24
            x1 = zero_re[i] + marker_size * cos(rad)
            y1 = zero_im[i] + marker_size * sin(rad)
            rad2 = ang * 2 * pi / 24
            x2 = zero_re[i] + marker_size * cos(rad2)
            y2 = zero_im[i] + marker_size * sin(rad2)
            Draw line: x1, y1, x2, y2
        endfor
    endfor
    
    # Draw poles (red X marks)
    Colour: "Red"
    Line width: 4
    for i to pole_count
        # Draw X
        Draw line: pole_re[i]-marker_size, pole_im[i]-marker_size, pole_re[i]+marker_size, pole_im[i]+marker_size
        Draw line: pole_re[i]-marker_size, pole_im[i]+marker_size, pole_re[i]+marker_size, pole_im[i]-marker_size
    endfor
    
    # Add legend
    Line width: 1
    Colour: "Black"
    Text top: "yes", "##X##=poles  ##O##=zeros"
    
    # Add info about pole/zero count
    Colour: "Black"
    Text bottom: "yes", "Poles: " + string$(pole_count) + "  Zeros: " + string$(zero_count)
    
    Line width: 1
endproc

# ============================================================
# PLOT FREQUENCY RESPONSE - SMALLER SIZE
# ============================================================
procedure plotFrequencyResponse
    npts = 512
    
    for i to npts
        freq[i] = (i-1) * fs / (2*npts)
        omega = 2 * pi * freq[i] / fs
        
        h_re = 1
        h_im = 0
        
        for sec to nsections
            cos1 = cos(omega)
            sin1 = sin(omega)
            cos2 = cos(2*omega)
            sin2 = sin(2*omega)
            
            num_re = sos_b0[sec] + sos_b1[sec]*cos1 + sos_b2[sec]*cos2
            num_im = -sos_b1[sec]*sin1 - sos_b2[sec]*sin2
            
            den_re = sos_a0[sec] + sos_a1[sec]*cos1 + sos_a2[sec]*cos2
            den_im = -sos_a1[sec]*sin1 - sos_a2[sec]*sin2
            
            den_mag = den_re^2 + den_im^2
            if den_mag > 0.00001
                sec_re = (num_re*den_re + num_im*den_im) / den_mag
                sec_im = (num_im*den_re - num_re*den_im) / den_mag
            else
                sec_re = 0
                sec_im = 0
            endif
            
            temp_re = h_re * sec_re - h_im * sec_im
            temp_im = h_re * sec_im + h_im * sec_re
            h_re = temp_re
            h_im = temp_im
        endfor
        
        mag = sqrt(h_re^2 + h_im^2)
        if mag > 0.00001
            mag_db[i] = 20 * log10(mag)
        else
            mag_db[i] = -120
        endif
        phase[i] = arctan2(h_im, h_re) * 180/pi
    endfor
    
    # Plot magnitude - SMALLER, at top
    Select outer viewport: 0, 6, 0, 2.5
    Axes: 0, fs/2, -80, 10
    Draw inner box
    Text left: "yes", "Magnitude (dB)"
    Text bottom: "yes", "Frequency (Hz)"
    Text top: "no", "##" + filter_type$ + " " + filter_mode$ + " Order=" + string$(order) + "##"
    Marks bottom every: 1, 2000, "yes", "yes", "no"
    Marks left every: 1, 20, "yes", "yes", "yes"
    
    Line width: 2
    Colour: "Red"
    for i from 2 to npts
        if mag_db[i] > -80 and mag_db[i-1] > -80
            Draw line: freq[i-1], mag_db[i-1], freq[i], mag_db[i]
        endif
    endfor
    
    Line width: 1
    Colour: "Blue"
    Draw line: 0, -3, fs/2, -3
    
    Colour: "Green"
    Draw line: cutoff_frequency, -80, cutoff_frequency, 10
    Colour: "Black"
    
    # Plot phase - SMALLER, in middle
    Select outer viewport: 0, 6, 2.7, 5.2
    Axes: 0, fs/2, -180, 180
    Draw inner box
    Text left: "yes", "Phase (degrees)"
    Text bottom: "yes", "Frequency (Hz)"
    Marks bottom every: 1, 2000, "yes", "yes", "no"
    Marks left every: 1, 90, "yes", "yes", "yes"
    
    Line width: 2
    Colour: "Blue"
    for i from 2 to npts
        diff = phase[i] - phase[i-1]
        if abs(diff) < 180
            Draw line: freq[i-1], phase[i-1], freq[i], phase[i]
        endif
    endfor
    
    Line width: 1
    Colour: "Green"
    Draw line: cutoff_frequency, -180, cutoff_frequency, 180
    
    Line width: 1
    Colour: "Black"
endproc