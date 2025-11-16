# ============================================================
# Praat AudioTools - Artificial Room.praat  
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Spectral analysis or frequency-domain processing script
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Artificial Room (Preset → IR → Convolution)
# 1) Select exactly one dry Sound (mono/stereo) in the Objects window.
# 2) Run this script, choose a room preset and IR options.
# 3) It will create Sound "IR" (synthetic impulse response) and
#    Sound "Reverb_<yourSound>" (the reverberated result).


# Safety check: ensure exactly one Sound is selected
if numberOfSelected ("Sound") <> 1
    exit ("Select exactly one Sound before running.")
endif
inputID = selected ("Sound")
selectObject: inputID
inputName$ = selected$ ("Sound")
fs = Get sampling frequency

# ------------------------------------------------------------------------------
# 1) Materials and absorption data
# ------------------------------------------------------------------------------

materials$[1]  = "BrickPainted"
materials$[2]  = "Concrete"
materials$[3]  = "WoodFloor"
materials$[4]  = "CarpetConcrete"
materials$[5]  = "CurtainLight"
materials$[6]  = "CurtainHeavy"
materials$[7]  = "GypsumBoard"
materials$[8]  = "GlassWindow"
materials$[9]  = "AcousticFoam25mm"
materials$[10] = "AcousticFoam50mm"
materials$[11] = "Audience"
materials$[12] = "WoodPanel"
materials$[13] = "PlasterWall"
materials$[14] = "PlywoodPanel"
materials$[15] = "MineralWool50mm"
materials$[16] = "MineralWool100mm"
materials$[17] = "CarpetOnFelt"
materials$[18] = "Linoleum"
materials$[19] = "OpenWindow"
materials$[20] = "AcousticCeilingTile"

# Correct absorption coefficients per octave band (indices 1..20)
alpha125[1] = 0.01  ; alpha125[2] = 0.01  ; alpha125[3] = 0.15  ; alpha125[4] = 0.08  ; alpha125[5] = 0.05
alpha125[6] = 0.14  ; alpha125[7] = 0.10  ; alpha125[8] = 0.35  ; alpha125[9] = 0.15  ; alpha125[10] = 0.30
alpha125[11] = 0.30 ; alpha125[12] = 0.15 ; alpha125[13] = 0.02 ; alpha125[14] = 0.10 ; alpha125[15] = 0.25
alpha125[16] = 0.45 ; alpha125[17] = 0.10 ; alpha125[18] = 0.02 ; alpha125[19] = 1.00 ; alpha125[20] = 0.70

alpha250[1] = 0.01  ; alpha250[2] = 0.01  ; alpha250[3] = 0.11  ; alpha250[4] = 0.24  ; alpha250[5] = 0.15
alpha250[6] = 0.35  ; alpha250[7] = 0.08  ; alpha250[8] = 0.25  ; alpha250[9] = 0.40  ; alpha250[10] = 0.60
alpha250[11] = 0.45 ; alpha250[12] = 0.10 ; alpha250[13] = 0.02 ; alpha250[14] = 0.08 ; alpha250[15] = 0.55
alpha250[16] = 0.80 ; alpha250[17] = 0.35 ; alpha250[18] = 0.03 ; alpha250[19] = 1.00 ; alpha250[20] = 0.75

alpha500[1] = 0.02  ; alpha500[2]  = 0.02  ; alpha500[3]  = 0.10  ; alpha500[4]  = 0.57  ; alpha500[5]  = 0.35
alpha500[6] = 0.55  ; alpha500[7]  = 0.05  ; alpha500[8]  = 0.18  ; alpha500[9]  = 0.70  ; alpha500[10] = 0.90
alpha500[11] = 0.55 ; alpha500[12] = 0.08 ; alpha500[13] = 0.03 ; alpha500[14] = 0.06 ; alpha500[15] = 0.85
alpha500[16] = 0.95 ; alpha500[17] = 0.55 ; alpha500[18] = 0.04 ; alpha500[19] = 1.00 ; alpha500[20] = 0.85

alpha1000[1] = 0.02  ; alpha1000[2]  = 0.02  ; alpha1000[3]  = 0.07  ; alpha1000[4]  = 0.69  ; alpha1000[5]  = 0.55
alpha1000[6] = 0.72  ; alpha1000[7]  = 0.03  ; alpha1000[8]  = 0.12  ; alpha1000[9]  = 0.85  ; alpha1000[10] = 0.95
alpha1000[11] = 0.60 ; alpha1000[12] = 0.07 ; alpha1000[13] = 0.03 ; alpha1000[14] = 0.05 ; alpha1000[15] = 0.95
alpha1000[16] = 0.95 ; alpha1000[17] = 0.65 ; alpha1000[18] = 0.05 ; alpha1000[19] = 1.00 ; alpha1000[20] = 0.90

alpha2000[1] = 0.02  ; alpha2000[2]  = 0.02  ; alpha2000[3]  = 0.06  ; alpha2000[4]  = 0.71  ; alpha2000[5]  = 0.60
alpha2000[6] = 0.70  ; alpha2000[7]  = 0.03  ; alpha2000[8]  = 0.07  ; alpha2000[9]  = 0.90  ; alpha2000[10] = 0.95
alpha2000[11] = 0.60 ; alpha2000[12] = 0.06 ; alpha2000[13] = 0.03 ; alpha2000[14] = 0.05 ; alpha2000[15] = 0.95
alpha2000[16] = 0.95 ; alpha2000[17] = 0.70 ; alpha2000[18] = 0.05 ; alpha2000[19] = 1.00 ; alpha2000[20] = 0.90

alpha4000[1] = 0.02  ; alpha4000[2]  = 0.02  ; alpha4000[3]  = 0.07  ; alpha4000[4]  = 0.73  ; alpha4000[5]  = 0.55
alpha4000[6] = 0.65  ; alpha4000[7]  = 0.03  ; alpha4000[8]  = 0.05  ; alpha4000[9]  = 0.90  ; alpha4000[10] = 0.90
alpha4000[11] = 0.55 ; alpha4000[12] = 0.07 ; alpha4000[13] = 0.03 ; alpha4000[14] = 0.05 ; alpha4000[15] = 0.90
alpha4000[16] = 0.90 ; alpha4000[17] = 0.75 ; alpha4000[18] = 0.05 ; alpha4000[19] = 1.00 ; alpha4000[20] = 0.85

# Octave centres and band edges
sqrtTwo = sqrt(2)
cen[1]=125
low[1]=125/sqrtTwo
high[1]=125*sqrtTwo
cen[2]=250
low[2]=250/sqrtTwo
high[2]=250*sqrtTwo
cen[3]=500
low[3]=500/sqrtTwo
high[3]=500*sqrtTwo
cen[4]=1000
low[4]=1000/sqrtTwo
high[4]=1000*sqrtTwo
cen[5]=2000
low[5]=2000/sqrtTwo
high[5]=2000*sqrtTwo
cen[6]=4000
low[6]=4000/sqrtTwo
high[6]=4000*sqrtTwo

# ------------------------------------------------------------------------------
# 2) Choose preset and IR options
# ------------------------------------------------------------------------------
form Choose preset & IR options
    comment Room Preset (or customize dimensions below)
    choice roomPreset: 1
        option SmallBooth
        option Office
        option Classroom
        option LiveRoom
        option Custom
    comment Custom Room Dimensions (used only if Custom selected)
    positive custom_length_m: 5.0
    positive custom_width_m: 4.0
    positive custom_height_m: 2.8
    comment Materials (used only if Custom selected)
    optionmenu floor_material: 4
        option BrickPainted
        option Concrete
        option WoodFloor
        option CarpetConcrete
        option CurtainLight
        option CurtainHeavy
        option GypsumBoard
        option GlassWindow
        option AcousticFoam25mm
        option AcousticFoam50mm
        option Audience
        option WoodPanel
        option PlasterWall
        option PlywoodPanel
        option MineralWool50mm
        option MineralWool100mm
        option CarpetOnFelt
        option Linoleum
        option OpenWindow
        option AcousticCeilingTile
    optionmenu ceiling_material: 20
        option BrickPainted
        option Concrete
        option WoodFloor
        option CarpetConcrete
        option CurtainLight
        option CurtainHeavy
        option GypsumBoard
        option GlassWindow
        option AcousticFoam25mm
        option AcousticFoam50mm
        option Audience
        option WoodPanel
        option PlasterWall
        option PlywoodPanel
        option MineralWool50mm
        option MineralWool100mm
        option CarpetOnFelt
        option Linoleum
        option OpenWindow
        option AcousticCeilingTile
    optionmenu wall_material: 7
        option BrickPainted
        option Concrete
        option WoodFloor
        option CarpetConcrete
        option CurtainLight
        option CurtainHeavy
        option GypsumBoard
        option GlassWindow
        option AcousticFoam25mm
        option AcousticFoam50mm
        option Audience
        option WoodPanel
        option PlasterWall
        option PlywoodPanel
        option MineralWool50mm
        option MineralWool100mm
        option CarpetOnFelt
        option Linoleum
        option OpenWindow
        option AcousticCeilingTile
    positive audience_area_m2: 0.1
    comment Impulse Response Settings
    positive ir_predelay_ms: 12.0
    real ir_early_gain_dB: -6.0
    positive ir_length_factor: 2.0
    positive early_reflections_count: 8
endform

# Initialize
roomL = 0
roomW = 0
roomH = 0
mFloor$ = ""
cFloor = 0
mCeil$ = ""
cCeil = 0
mW1$ = ""
cW1 = 0
mW2$ = ""
cW2 = 0
mW3$ = ""
cW3 = 0
mW4$ = ""
cW4 = 0
audience_m2 = 0

# Assign preset values
if roomPreset = 1
    roomL = 2.2
    roomW = 1.6
    roomH = 2.2
    mFloor$ = "CarpetConcrete"
    cFloor = 1.0
    mCeil$  = "MineralWool50mm"
    cCeil = 0.7
    mW1$ = "MineralWool50mm"
    cW1 = 0.6
    mW2$ = "MineralWool50mm"
    cW2 = 0.6
    mW3$ = "MineralWool50mm"
    cW3 = 0.6
    mW4$ = "MineralWool50mm"
    cW4 = 0.6
    audience_m2 = 0.0
elsif roomPreset = 2
    roomL = 4.5
    roomW = 3.5
    roomH = 2.7
    mFloor$ = "CarpetOnFelt"
    cFloor = 1.0
    mCeil$  = "AcousticCeilingTile"
    cCeil = 1.0
    mW1$ = "GypsumBoard"
    cW1 = 0.9
    mW2$ = "GypsumBoard"
    cW2 = 0.9
    mW3$ = "GlassWindow"
    cW3 = 0.3
    mW4$ = "CurtainLight"
    cW4 = 0.6
    audience_m2 = 1.5
elsif roomPreset = 3
    roomL = 8.0
    roomW = 6.0
    roomH = 3.2
    mFloor$ = "Linoleum"
    cFloor = 1.0
    mCeil$  = "AcousticCeilingTile"
    cCeil = 1.0
    mW1$ = "GypsumBoard"
    cW1 = 1.0
    mW2$ = "GypsumBoard"
    cW2 = 1.0
    mW3$ = "GypsumBoard"
    cW3 = 1.0
    mW4$ = "GypsumBoard"
    cW4 = 1.0
    audience_m2 = 8.0
elsif roomPreset = 4
    roomL = 7.0
    roomW = 5.0
    roomH = 3.0
    mFloor$ = "WoodFloor"
    cFloor = 1.0
    mCeil$  = "GypsumBoard"
    cCeil = 1.0
    mW1$ = "GypsumBoard"
    cW1 = 1.0
    mW2$ = "GypsumBoard"
    cW2 = 1.0
    mW3$ = "CurtainHeavy"
    cW3 = 0.5
    mW4$ = "MineralWool50mm"
    cW4 = 0.4
    audience_m2 = 0.0
elsif roomPreset = 5
    roomL = custom_length_m
    roomW = custom_width_m
    roomH = custom_height_m
    mFloor$ = materials$[floor_material]
    cFloor = 1.0
    mCeil$ = materials$[ceiling_material]
    cCeil = 1.0
    mW1$ = materials$[wall_material]
    cW1 = 1.0
    mW2$ = materials$[wall_material]
    cW2 = 1.0
    mW3$ = materials$[wall_material]
    cW3 = 1.0
    mW4$ = materials$[wall_material]
    cW4 = 1.0
    audience_m2 = audience_area_m2
endif

# Compute surfaces step by step
lengthTemp = roomL
widthTemp = roomW
heightTemp = roomH
temp1 = lengthTemp * widthTemp
sfloor = temp1
sceiling = sfloor
temp2 = lengthTemp * heightTemp
sw1 = temp2
sw2 = temp2
temp3 = widthTemp * heightTemp
sw3 = temp3
sw4 = temp3
temp4 = sfloor + sceiling
temp5 = sw1 + sw2
temp6 = sw3 + sw4
temp7 = temp4 + temp5
stotal = temp7 + temp6
temp8 = lengthTemp * widthTemp
v = temp8 * heightTemp

# ------------------------------------------------------------------------------
# 3) Get material indices - build lookup function
# ------------------------------------------------------------------------------
procedure findMaterialIndex: mat$
    .result = 1
    .found = 0
    for .jj from 1 to 20
        if .found = 0
            if materials$[.jj] = mat$
                .result = .jj
                .found = 1
            endif
        endif
    endfor
endproc

# Floor
call findMaterialIndex: mFloor$
iFloor = findMaterialIndex.result

# Ceiling
call findMaterialIndex: mCeil$
iCeil = findMaterialIndex.result

# Wall1
call findMaterialIndex: mW1$
iW1 = findMaterialIndex.result

# Wall2
call findMaterialIndex: mW2$
iW2 = findMaterialIndex.result

# Wall3
call findMaterialIndex: mW3$
iW3 = findMaterialIndex.result

# Wall4
call findMaterialIndex: mW4$
iW4 = findMaterialIndex.result

# ------------------------------------------------------------------------------
# 4) Compute absorption area and T60 per band (Eyring)
# ------------------------------------------------------------------------------
# Band 1: 125 Hz
aF = alpha125[iFloor] * cFloor
aC = alpha125[iCeil] * cCeil
a1 = alpha125[iW1] * cW1
a2 = alpha125[iW2] * cW2
a3 = alpha125[iW3] * cW3
a4 = alpha125[iW4] * cW4
aAud = alpha125[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_1 = temp_sum5 + aAud
alphaBar1 = abs_area_1 / stotal
if alphaBar1 > 0.98
    alphaBar1 = 0.98
endif
temp_diff = 1 - alphaBar1
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_1 = 0.161 * temp_ratio
if t60_1 < 0.12
    t60_1 = 0.12
endif
if t60_1 > 5.0
    t60_1 = 5.0
endif

# Band 2: 250 Hz
aF = alpha250[iFloor] * cFloor
aC = alpha250[iCeil] * cCeil
a1 = alpha250[iW1] * cW1
a2 = alpha250[iW2] * cW2
a3 = alpha250[iW3] * cW3
a4 = alpha250[iW4] * cW4
aAud = alpha250[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_2 = temp_sum5 + aAud
alphaBar2 = abs_area_2 / stotal
if alphaBar2 > 0.98
    alphaBar2 = 0.98
endif
temp_diff = 1 - alphaBar2
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_2 = 0.161 * temp_ratio
if t60_2 < 0.12
    t60_2 = 0.12
endif
if t60_2 > 5.0
    t60_2 = 5.0
endif

# Band 3: 500 Hz
aF = alpha500[iFloor] * cFloor
aC = alpha500[iCeil] * cCeil
a1 = alpha500[iW1] * cW1
a2 = alpha500[iW2] * cW2
a3 = alpha500[iW3] * cW3
a4 = alpha500[iW4] * cW4
aAud = alpha500[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_3 = temp_sum5 + aAud
alphaBar3 = abs_area_3 / stotal
if alphaBar3 > 0.98
    alphaBar3 = 0.98
endif
temp_diff = 1 - alphaBar3
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_3 = 0.161 * temp_ratio
if t60_3 < 0.12
    t60_3 = 0.12
endif
if t60_3 > 5.0
    t60_3 = 5.0
endif

# Band 4: 1000 Hz
aF = alpha1000[iFloor] * cFloor
aC = alpha1000[iCeil] * cCeil
a1 = alpha1000[iW1] * cW1
a2 = alpha1000[iW2] * cW2
a3 = alpha1000[iW3] * cW3
a4 = alpha1000[iW4] * cW4
aAud = alpha1000[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_4 = temp_sum5 + aAud
alphaBar4 = abs_area_4 / stotal
if alphaBar4 > 0.98
    alphaBar4 = 0.98
endif
temp_diff = 1 - alphaBar4
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_4 = 0.161 * temp_ratio
if t60_4 < 0.12
    t60_4 = 0.12
endif
if t60_4 > 5.0
    t60_4 = 5.0
endif

# Band 5: 2000 Hz
aF = alpha2000[iFloor] * cFloor
aC = alpha2000[iCeil] * cCeil
a1 = alpha2000[iW1] * cW1
a2 = alpha2000[iW2] * cW2
a3 = alpha2000[iW3] * cW3
a4 = alpha2000[iW4] * cW4
aAud = alpha2000[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_5 = temp_sum5 + aAud
alphaBar5 = abs_area_5 / stotal
if alphaBar5 > 0.98
    alphaBar5 = 0.98
endif
temp_diff = 1 - alphaBar5
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_5 = 0.161 * temp_ratio
if t60_5 < 0.12
    t60_5 = 0.12
endif
if t60_5 > 5.0
    t60_5 = 5.0
endif

# Band 6: 4000 Hz
aF = alpha4000[iFloor] * cFloor
aC = alpha4000[iCeil] * cCeil
a1 = alpha4000[iW1] * cW1
a2 = alpha4000[iW2] * cW2
a3 = alpha4000[iW3] * cW3
a4 = alpha4000[iW4] * cW4
aAud = alpha4000[11] * audience_m2
temp_a1 = aF * sfloor
temp_a2 = aC * sceiling
temp_a3 = a1 * sw1
temp_a4 = a2 * sw2
temp_a5 = a3 * sw3
temp_a6 = a4 * sw4
temp_sum1 = temp_a1 + temp_a2
temp_sum2 = temp_a3 + temp_a4
temp_sum3 = temp_a5 + temp_a6
temp_sum4 = temp_sum1 + temp_sum2
temp_sum5 = temp_sum4 + temp_sum3
abs_area_6 = temp_sum5 + aAud
alphaBar6 = abs_area_6 / stotal
if alphaBar6 > 0.98
    alphaBar6 = 0.98
endif
temp_diff = 1 - alphaBar6
temp_ln = ln(temp_diff)
temp_neg = 0 - temp_ln
temp_prod = stotal * temp_neg
temp_ratio = v / temp_prod
t60_6 = 0.161 * temp_ratio
if t60_6 < 0.12
    t60_6 = 0.12
endif
if t60_6 > 5.0
    t60_6 = 5.0
endif

# Determine IR length
maxT = t60_1
if t60_2 > maxT
    maxT = t60_2
endif
if t60_3 > maxT
    maxT = t60_3
endif
if t60_4 > maxT
    maxT = t60_4
endif
if t60_5 > maxT
    maxT = t60_5
endif
if t60_6 > maxT
    maxT = t60_6
endif
if ir_length_factor < 0.8
    ir_length_factor = 0.8
endif
if ir_length_factor > 4.0
    ir_length_factor = 4.0
endif
ir_length = maxT * ir_length_factor
pre_delay = ir_predelay_ms / 1000

# ------------------------------------------------------------------------------
# 5) Build synthetic IR
# ------------------------------------------------------------------------------
Create Sound from formula: "IR_base", 1, 0, ir_length, fs, "0"

nTaps = early_reflections_count
pulse_dur = 0.0007
for k from 1 to nTaps
    t0 = pre_delay + randomUniform(0.004, 0.050)
    k_minus = k - 1
    gain_db = ir_early_gain_dB - (k_minus * 2.5)
    gain_factor = 10^(gain_db / 20)
    rand_var = randomUniform(0.9, 1.1)
    g = gain_factor * rand_var
    tapName$ = "IR_tap" + string$(k)
    
    t0_str$ = string$(t0)
    t0_plus_dur = t0 + pulse_dur
    t0_plus_str$ = string$(t0_plus_dur)
    g_str$ = string$(g)
    dur_str$ = string$(pulse_dur)
    pi_val = 2 * pi
    pi_str$ = string$(pi_val)
    
    expr$ = "if x >= " + t0_str$ + " and x <= " + t0_plus_str$ + " then " + g_str$ + " * 0.5 * (1 - cos(" + pi_str$ + " * (x - " + t0_str$ + ") / " + dur_str$ + ")) else 0 fi"
    
    Create Sound from formula: tapName$, 1, 0, ir_length, fs, expr$
    selectObject: "Sound IR_base"
    plusObject: "Sound " + tapName$
    Formula: "self + Sound_" + tapName$ + "[]"
    selectObject: "Sound " + tapName$
    Remove
endfor

for b from 1 to 6
    tau = t60_1 / 6
    if b = 2
        tau = t60_2 / 6
    elsif b = 3
        tau = t60_3 / 6
    elsif b = 4
        tau = t60_4 / 6
    elsif b = 5
        tau = t60_5 / 6
    elsif b = 6
        tau = t60_6 / 6
    endif
    
    low_freq = low[b]
    high_freq = high[b]
    cen_freq = cen[b]
    
    tau_str$ = string$(tau)
    noiseName$ = "IR_noise" + string$(b)
    expr_noise$ = "randomGauss(0, 1) * exp(0 - x / " + tau_str$ + ")"
    Create Sound from formula: noiseName$, 1, 0, ir_length, fs, expr_noise$
    Filter (pass Hann band): low_freq, high_freq, 100
    filteredName$ = noiseName$ + "_band"
    
    if cen_freq >= 2000
        fac = 10^(-0.75 / 20)
        fac_str$ = string$(fac)
        Formula: "self * " + fac_str$
    endif
    
    selectObject: "Sound IR_base"
    plusObject: "Sound " + filteredName$
    Formula: "self + Sound_" + filteredName$ + "[]"
    
    selectObject: "Sound " + noiseName$
    Remove
    selectObject: "Sound " + filteredName$
    Remove
endfor

selectObject: "Sound IR_base"
Scale peak: 0.6
Rename: "IR"

# ------------------------------------------------------------------------------
# 6) Convolve dry sound with IR
# ------------------------------------------------------------------------------
selectObject: inputID
plusObject: "Sound IR"
Convolve: "sum", "zero"
Rename: "Reverb_" + inputName$
Scale peak: 0.99
Play

# ------------------------------------------------------------------------------
# 7) Cleanup - Remove IR, keep original and result
# ------------------------------------------------------------------------------
selectObject: "Sound IR"
Remove

# ------------------------------------------------------------------------------
# 8) Report T60 values
# ------------------------------------------------------------------------------
clearinfo
if roomPreset = 1
    presetName$ = "SmallBooth"
elsif roomPreset = 2
    presetName$ = "Office"
elsif roomPreset = 3
    presetName$ = "Classroom"
elsif roomPreset = 4
    presetName$ = "LiveRoom"
else
    presetName$ = "Custom"
endif

appendInfoLine: "Preset: ", presetName$
appendInfoLine: "Room dimensions (m): ", fixed$(lengthTemp, 2), " × ", fixed$(widthTemp, 2), " × ", fixed$(heightTemp, 2)
appendInfoLine: "Volume (m³): ", fixed$(v, 2)
appendInfoLine: "Floor: ", mFloor$
appendInfoLine: "Ceiling: ", mCeil$
appendInfoLine: "Walls: ", mW1$
if audience_m2 > 0
    appendInfoLine: "Audience area (m²): ", fixed$(audience_m2, 1)
endif
appendInfoLine: ""
appendInfoLine: "RT60 per octave (s):"
appendInfoLine: "  125 Hz: ", fixed$(t60_1, 3)
appendInfoLine: "  250 Hz: ", fixed$(t60_2, 3)
appendInfoLine: "  500 Hz: ", fixed$(t60_3, 3)
appendInfoLine: "  1000 Hz: ", fixed$(t60_4, 3)
appendInfoLine: "  2000 Hz: ", fixed$(t60_5, 3)
appendInfoLine: "  4000 Hz: ", fixed$(t60_6, 3)
appendInfoLine: ""
appendInfoLine: "IR Settings:"
appendInfoLine: "  Pre-delay: ", fixed$(ir_predelay_ms, 1), " ms"
appendInfoLine: "  Early reflections: ", early_reflections_count
appendInfoLine: "  IR length factor: ", fixed$(ir_length_factor, 1)
appendInfoLine: ""
appendInfoLine: "Created:"
appendInfoLine: "- Sound 'Reverb_", inputName$, "' (reverberated result)"