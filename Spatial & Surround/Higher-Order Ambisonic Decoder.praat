# ============================================================
# Praat AudioTools - Ambisonic Decoder.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Higher-Order Ambisonic (HOA) Decoder
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

clearinfo

form Ambisonic Decoder
    comment Select ambisonic channel sounds (W, Y, Z, X, etc.)
    comment They should be selected in correct order before running
    optionmenu Ambisonic_order 1
        option 1st order (4 channels: W,Y,Z,X)
        option 2nd order (9 channels: W,Y,Z,X,V,T,R,S,U)
        option 3rd order (16 channels: W,Y,Z,X,V,T,R,S,U,Q,O,M,K,L,N,P)
    optionmenu Speaker_preset 1
        option Stereo (2 speakers)
        option Triangle (3 speakers)
        option Quad (4 speakers)
        option Pentagon (5 speakers)
        option Hexagon (6 speakers)
        option Surround 5.1 (6 speakers)
        option Surround 7.1 (8 speakers)
        option Octagon (8 speakers)
    optionmenu Decode_method 1
        option Basic (simple projection)
        option Max-rE (energy optimized)
    boolean Normalize_output 1
endform

expected_channels = 4
if ambisonic_order = 2
    expected_channels = 9
elsif ambisonic_order = 3
    expected_channels = 16
endif

num_selected = numberOfSelected("Sound")
if num_selected <> expected_channels
    exitScript: "Please select exactly ", expected_channels, " Sound objects for ", 
    ... string$(ambisonic_order), " order ambisonics (currently selected: ", num_selected, ")"
endif

appendInfoLine: "Ambisonic Decoder"
appendInfoLine: "=================="
appendInfoLine: "Ambisonic order: ", ambisonic_order
appendInfoLine: "Expected channels: ", expected_channels
appendInfoLine: "Selected sounds: ", num_selected

for i to num_selected
    ambi_channel'i' = selected("Sound", i)
endfor

for i to expected_channels
    selectObject: ambi_channel'i'
    channel_name'i'$ = selected$("Sound")
    appendInfoLine: "Channel ", i, ": ", channel_name'i'$
endfor

selectObject: ambi_channel1
duration = Get total duration
sampling_frequency = Get sampling frequency
num_samples = Get number of samples

appendInfoLine: ""
appendInfoLine: "Audio properties:"
appendInfoLine: "Duration: ", fixed$(duration, 3), " seconds"
appendInfoLine: "Sample rate: ", sampling_frequency, " Hz"
appendInfoLine: "Samples: ", num_samples

if speaker_preset = 1
    number_of_speakers = 2
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    
elsif speaker_preset = 2
    number_of_speakers = 3
    speakerX1 = -0.866
    speakerY1 = -0.5
    speakerX2 = 0.866
    speakerY2 = -0.5
    speakerX3 = 0.0
    speakerY3 = 1.0
    
elsif speaker_preset = 3
    number_of_speakers = 4
    for i to 4
        angle = (i - 1) * 2 * pi / 4
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor

elsif speaker_preset = 4
    number_of_speakers = 5
    for i to 5
        angle = (i - 1) * 2 * pi / 5 - pi / 2
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor

elsif speaker_preset = 5
    number_of_speakers = 6
    for i to 6
        angle = (i - 1) * 2 * pi / 6
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor
    
elsif speaker_preset = 6
    number_of_speakers = 6
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    speakerX3 = 0.0
    speakerY3 = 1.0
    speakerX4 = -0.7
    speakerY4 = -0.7
    speakerX5 = 0.7
    speakerY5 = -0.7
    speakerX6 = 0.0
    speakerY6 = 0.0

elsif speaker_preset = 7
    number_of_speakers = 8
    speakerX1 = -1.0
    speakerY1 = 0.0
    speakerX2 = 1.0
    speakerY2 = 0.0
    speakerX3 = 0.0
    speakerY3 = 1.0
    speakerX4 = -0.7
    speakerY4 = 0.7
    speakerX5 = 0.7
    speakerY5 = 0.7
    speakerX6 = -0.7
    speakerY6 = -0.7
    speakerX7 = 0.7
    speakerY7 = -0.7
    speakerX8 = 0.0
    speakerY8 = 0.0

elsif speaker_preset = 8
    number_of_speakers = 8
    for i to 8
        angle = (i - 1) * 2 * pi / 8
        speakerX'i' = cos(angle)
        speakerY'i' = sin(angle)
    endfor
endif

appendInfoLine: ""
appendInfoLine: "Speaker configuration:"
appendInfoLine: "Number of speakers: ", number_of_speakers
for i to number_of_speakers
    sp_x = speakerX'i'
    sp_y = speakerY'i'
    
    if sp_x = 0 and sp_y = 0
        sp_angle = 0
    elsif sp_y = 0
        if sp_x > 0
            sp_angle = 90
        else
            sp_angle = 270
        endif
    elsif sp_x = 0
        if sp_y > 0
            sp_angle = 0
        else
            sp_angle = 180
        endif
    else
        sp_angle = arctan(sp_x / sp_y) * 180 / pi
        if sp_y < 0
            sp_angle = sp_angle + 180
        elsif sp_x < 0
            sp_angle = sp_angle + 360
        endif
    endif
    
    appendInfoLine: "Speaker ", i, ": x=", fixed$(sp_x, 3), ", y=", fixed$(sp_y, 3), 
    ... " (", fixed$(sp_angle, 1), "°)"
endfor

sqrt2 = sqrt(2)
sqrt3 = sqrt(3)
sqrt5 = sqrt(5)
sqrt15 = sqrt(15)

appendInfoLine: ""
appendInfoLine: "Calculating decoder coefficients..."

for spk to number_of_speakers
    sp_x = speakerX'spk'
    sp_y = speakerY'spk'
    sp_z = 0.0
    
    if sp_x = 0 and sp_y = 0
        sp_azimuth = 0
    elsif sp_y = 0
        if sp_x > 0
            sp_azimuth = pi / 2
        else
            sp_azimuth = 3 * pi / 2
        endif
    elsif sp_x = 0
        if sp_y > 0
            sp_azimuth = 0
        else
            sp_azimuth = pi
        endif
    else
        sp_azimuth = arctan(sp_x / sp_y)
        if sp_y < 0
            sp_azimuth = sp_azimuth + pi
        elsif sp_x < 0
            sp_azimuth = sp_azimuth + 2 * pi
        endif
    endif
    
    sp_elevation = 0.0
    
    cos_az = cos(sp_azimuth)
    sin_az = sin(sp_azimuth)
    cos_el = cos(sp_elevation)
    sin_el = sin(sp_elevation)
    cos_el_sq = cos_el * cos_el
    sin_el_sq = sin_el * sin_el
    
    g_w = 1.0
    g_y = cos_el * sin_az
    g_z = sin_el
    g_x = cos_el * cos_az
    
    if decode_method = 2
        max_re_weight = sqrt(1.0 / number_of_speakers)
        g_w = g_w * max_re_weight
        g_y = g_y * max_re_weight
        g_z = g_z * max_re_weight
        g_x = g_x * max_re_weight
    endif
    
    decode_w'spk' = g_w
    decode_y'spk' = g_y
    decode_z'spk' = g_z
    decode_x'spk' = g_x
    
    if ambisonic_order >= 2
        g_v = sqrt3 * cos_el_sq * sin_az * cos_az
        g_t = sqrt3 * sin_el * cos_el * sin_az
        g_r = 0.5 * sqrt3 * (3 * sin_el_sq - 1)
        g_s = sqrt3 * sin_el * cos_el * cos_az
        g_u = sqrt3 * cos_el_sq * (cos_az * cos_az - sin_az * sin_az) * 0.5
        
        if decode_method = 2
            order2_weight = sqrt(3.0 / number_of_speakers)
            g_v = g_v * order2_weight
            g_t = g_t * order2_weight
            g_r = g_r * order2_weight
            g_s = g_s * order2_weight
            g_u = g_u * order2_weight
        endif
        
        decode_v'spk' = g_v
        decode_t'spk' = g_t
        decode_r'spk' = g_r
        decode_s'spk' = g_s
        decode_u'spk' = g_u
    endif
    
    if ambisonic_order >= 3
        cos_2az = cos(2 * sp_azimuth)
        sin_2az = sin(2 * sp_azimuth)
        cos_3az = cos(3 * sp_azimuth)
        sin_3az = sin(3 * sp_azimuth)
        
        g_q = sqrt5 * cos_el * cos_el_sq * sin_3az * 0.25
        g_o = sqrt15 * sin_el * cos_el_sq * sin_2az * 0.5
        g_m = sqrt3 * cos_el * (5 * sin_el_sq - 1) * sin_az * 0.25
        g_k = sqrt3 * sin_el * (5 * sin_el_sq - 3) * 0.25
        g_l = sqrt3 * cos_el * (5 * sin_el_sq - 1) * cos_az * 0.25
        g_n = sqrt15 * sin_el * cos_el_sq * cos_2az * 0.5
        g_p = sqrt5 * cos_el * cos_el_sq * cos_3az * 0.25
        
        if decode_method = 2
            order3_weight = sqrt(5.0 / number_of_speakers)
            g_q = g_q * order3_weight
            g_o = g_o * order3_weight
            g_m = g_m * order3_weight
            g_k = g_k * order3_weight
            g_l = g_l * order3_weight
            g_n = g_n * order3_weight
            g_p = g_p * order3_weight
        endif
        
        decode_q'spk' = g_q
        decode_o'spk' = g_o
        decode_m'spk' = g_m
        decode_k'spk' = g_k
        decode_l'spk' = g_l
        decode_n'spk' = g_n
        decode_p'spk' = g_p
    endif
endfor

appendInfoLine: "Decoder matrix calculated"
appendInfoLine: ""
appendInfoLine: "Decoding ambisonic channels to speakers..."

for spk to number_of_speakers
    appendInfoLine: "Processing speaker ", spk, "/", number_of_speakers
    
    selectObject: ambi_channel1
    speaker_sound = Copy: "Speaker_" + string$(spk)
    Formula: "self * " + string$(decode_w'spk')
    
    selectObject: ambi_channel2
    temp2 = Copy: "temp_y"
    Formula: "self * " + string$(decode_y'spk')
    selectObject: speaker_sound
    plusObject: temp2
    combined = Combine to stereo
    removeObject: speaker_sound
    removeObject: temp2
    selectObject: combined
    speaker_sound = Convert to mono
    removeObject: combined
    
    selectObject: ambi_channel3
    temp3 = Copy: "temp_z"
    Formula: "self * " + string$(decode_z'spk')
    selectObject: speaker_sound
    plusObject: temp3
    combined = Combine to stereo
    removeObject: speaker_sound
    removeObject: temp3
    selectObject: combined
    speaker_sound = Convert to mono
    removeObject: combined
    
    selectObject: ambi_channel4
    temp4 = Copy: "temp_x"
    Formula: "self * " + string$(decode_x'spk')
    selectObject: speaker_sound
    plusObject: temp4
    combined = Combine to stereo
    removeObject: speaker_sound
    removeObject: temp4
    selectObject: combined
    speaker_sound = Convert to mono
    removeObject: combined
    
    if ambisonic_order >= 2
        for ch from 5 to 9
            selectObject: ambi_channel'ch'
            temp = Copy: "temp_" + string$(ch)
            if ch = 5
                coeff = decode_v'spk'
            elsif ch = 6
                coeff = decode_t'spk'
            elsif ch = 7
                coeff = decode_r'spk'
            elsif ch = 8
                coeff = decode_s'spk'
            elsif ch = 9
                coeff = decode_u'spk'
            endif
            Formula: "self * " + string$(coeff)
            selectObject: speaker_sound
            plusObject: temp
            combined = Combine to stereo
            removeObject: speaker_sound
            removeObject: temp
            selectObject: combined
            speaker_sound = Convert to mono
            removeObject: combined
        endfor
    endif
    
    if ambisonic_order >= 3
        for ch from 10 to 16
            selectObject: ambi_channel'ch'
            temp = Copy: "temp_" + string$(ch)
            if ch = 10
                coeff = decode_q'spk'
            elsif ch = 11
                coeff = decode_o'spk'
            elsif ch = 12
                coeff = decode_m'spk'
            elsif ch = 13
                coeff = decode_k'spk'
            elsif ch = 14
                coeff = decode_l'spk'
            elsif ch = 15
                coeff = decode_n'spk'
            elsif ch = 16
                coeff = decode_p'spk'
            endif
            Formula: "self * " + string$(coeff)
            selectObject: speaker_sound
            plusObject: temp
            combined = Combine to stereo
            removeObject: speaker_sound
            removeObject: temp
            selectObject: combined
            speaker_sound = Convert to mono
            removeObject: combined
        endfor
    endif
    
    selectObject: speaker_sound
    Rename: "Speaker_" + string$(spk)
    speaker'spk' = speaker_sound
endfor

if normalize_output
    appendInfoLine: ""
    appendInfoLine: "Normalizing speaker outputs..."
    for spk to number_of_speakers
        selectObject: speaker'spk'
        Scale peak: 0.99
    endfor
endif

appendInfoLine: ""
appendInfoLine: "Combining speakers into multichannel output..."
selectObject: speaker1
for spk from 2 to number_of_speakers
    plusObject: speaker'spk'
endfor

if number_of_speakers = 2
    result = Combine to stereo
else
    result = Combine to stereo
endif

selectObject: result
Rename: "Ambisonic_Decoded_" + string$(number_of_speakers) + "ch"

appendInfoLine: ""
appendInfoLine: "====================================="
appendInfoLine: "Decoding complete!"
appendInfoLine: "Ambisonic order: ", ambisonic_order
appendInfoLine: "Decode method: ", if decode_method = 1 then "Basic" else "Max-rE" fi
appendInfoLine: "Output speakers: ", number_of_speakers
appendInfoLine: "Output sound: ", selected$("Sound")
appendInfoLine: "====================================="

selectObject: result
Play

for spk to number_of_speakers
    removeObject: speaker'spk'
endfor

selectObject: result