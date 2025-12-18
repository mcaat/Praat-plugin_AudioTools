# ============================================================
# Praat AudioTools - Polynomial Sound Shaper.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Polynomial Envelope Visualizer and Sound Shaper
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# ============================================================
# Polynomial Sound Shaper (v6.3)
# Optimization: Fully Vectorized (Instant Processing)
# Features: Perceptual Weighting + Dynamic Range Control
# ============================================================

form Apply Polynomial Envelope
    comment === Perceptual Tuning ===
    real perceptual_weight 3.0
    comment (1.0 = Linear, 3.0-4.0 = Natural Loudness)
    
    comment === Dynamic Range Control ===
    real min_gain 0.0
    real max_gain 1.0
    comment (e.g., 0.1 to 1.0 = -20dB to 0dB range)
    
    optionmenu envelope_type 1
        option Polynomial (standard)
        option Polynomial from product terms
    
    comment === Polynomial Presets (overrides manual coeffs) ===
    optionmenu poly_preset 1
        option custom
        option cubic_1
        option cubic_2
        option cubic_3
        option cubic_4
        option cubic_5
    
    comment === Manual Polynomial Coefficients ===
    real startx -3
    real endx 4
    real coefa 2
    real coefb -1
    real coefc -2
    real coefd 1
    
    comment === Product Terms Presets (overrides manual params) ===
    optionmenu product_preset 1
        option custom
        option fade in (0, 1)
        option fade out (-1, 0)
        option center peak (-1, 1)
        option double dip (-2, 0, 2)
        option asymmetric (0, 2)
        option steep rise (0, 0.5)
        option gentle (0, 3)
    
    comment === Manual Product Terms ===
    real param1 1
    real param2 2
    real param3 0
    
    real scalepeak 0.99
    real min_threshold 0.000001
    boolean draw_envelope 1
    boolean play_result 1
endform

# --- 1. APPLY PRESETS (These OVERRIDE manual values) ---
preset_used$ = ""

if envelope_type = 1
    if poly_preset = 2
        coefa = 2
        coefb = -1
        coefc = -2
        coefd = 1
        preset_used$ = "cubic_1"
    elsif poly_preset = 3
        coefa = -1
        coefb = 3
        coefc = -1
        coefd = 0.5
        preset_used$ = "cubic_2"
    elsif poly_preset = 4
        coefa = 1
        coefb = 0
        coefc = -3
        coefd = 1
        preset_used$ = "cubic_3"
    elsif poly_preset = 5
        coefa = 3
        coefb = -2
        coefc = 0
        coefd = 1
        preset_used$ = "cubic_4"
    elsif poly_preset = 6
        coefa = -2
        coefb = 1
        coefc = 1
        coefd = 0
        preset_used$ = "cubic_5"
    else
        preset_used$ = "custom"
    endif
endif

if envelope_type = 2
    if product_preset = 2
        param1 = 0
        param2 = 1
        param3 = 0
        preset_used$ = "fade in (0, 1)"
    elsif product_preset = 3
        param1 = -1
        param2 = 0
        param3 = 0
        preset_used$ = "fade out (-1, 0)"
    elsif product_preset = 4
        param1 = -1
        param2 = 1
        param3 = 0
        preset_used$ = "center peak (-1, 1)"
    elsif product_preset = 5
        param1 = -2
        param2 = 0
        param3 = 2
        preset_used$ = "double dip (-2, 0, 2)"
    elsif product_preset = 6
        param1 = 0
        param2 = 2
        param3 = 0
        preset_used$ = "asymmetric (0, 2)"
    elsif product_preset = 7
        param1 = 0
        param2 = 0.5
        param3 = 0
        preset_used$ = "steep rise (0, 0.5)"
    elsif product_preset = 8
        param1 = 0
        param2 = 3
        param3 = 0
        preset_used$ = "gentle (0, 3)"
    else
        preset_used$ = "custom"
    endif
endif

# --- 2. SETUP ---
if numberOfSelected("Sound") <> 1
    exitScript: "Please select exactly one Sound object."
endif

orig_id = selected("Sound")
orig_name$ = selected$("Sound")
dur = Get total duration

# --- 3. CREATE POLYNOMIAL OBJECT (for drawing) ---
# Force recreation each time to ensure preset changes are visible
if envelope_type = 1
    Create Polynomial: "envelope_poly", startx, endx, { coefa, coefb, coefc, coefd }
elsif envelope_type = 2
    if param3 = 0
        Create Polynomial from product terms: "envelope_poly", startx, endx, { param1, param2 }
    else
        Create Polynomial from product terms: "envelope_poly", startx, endx, { param1, param2, param3 }
    endif
endif

poly_id = selected("Polynomial")

# --- 4. CONSTRUCT PROCESSING FORMULA ---
# A. Normalized time variable (for processing)
norm_x_proc$ = "((x/" + string$(dur) + ") * (" + string$(endx) + " - " + string$(startx) + ") + " + string$(startx) + ")"

# B. Build the Core Polynomial String
if envelope_type = 1
    # Standard: a*x^3 + b*x^2...
    poly_proc$ = "(" + string$(coefa) + "*(" + norm_x_proc$ + "^3)) + (" + string$(coefb) + "*(" + norm_x_proc$ + "^2)) + (" + string$(coefc) + "*(" + norm_x_proc$ + ")) + " + string$(coefd)
else
    # Product: (x-p1)*(x-p2)...
    if param3 = 0
        poly_proc$ = "(" + norm_x_proc$ + " - " + string$(param1) + ") * (" + norm_x_proc$ + " - " + string$(param2) + ")"
    else
        poly_proc$ = "(" + norm_x_proc$ + " - " + string$(param1) + ") * (" + norm_x_proc$ + " - " + string$(param2) + ") * (" + norm_x_proc$ + " - " + string$(param3) + ")"
    endif
endif

# C. Apply Perceptual Weighting with Sign Preservation
s_weight$ = string$(perceptual_weight)
s_thresh$ = string$(min_threshold)

weighted_poly$ = "if (" + poly_proc$ + ") < 0 then -1 * (max(" + s_thresh$ + ", abs(" + poly_proc$ + "))^" + s_weight$ + ") else (max(" + s_thresh$ + ", abs(" + poly_proc$ + "))^" + s_weight$ + ") fi"

# D. Apply Dynamic Range Limiting (Sign-Aware)
s_min_gain$ = string$(min_gain)
s_max_gain$ = string$(max_gain)

clamped_envelope$ = "if (" + weighted_poly$ + ") < 0 then -1 * (max(" + s_min_gain$ + ", min(" + s_max_gain$ + ", abs(" + weighted_poly$ + ")))) else (max(" + s_min_gain$ + ", min(" + s_max_gain$ + ", abs(" + weighted_poly$ + ")))) fi"

final_proc_formula$ = "self * (" + clamped_envelope$ + ")"

# --- 5. DRAWING (Two graphs: Polynomial + Time-domain Intensity) ---
if draw_envelope
    Erase all
    
    # === TOP GRAPH: Raw Polynomial (Mathematical Function) ===
    selectObject: poly_id
    Select outer viewport: 0, 6, 0, 3
    Draw: 0, 0, 0, 0, "no", "yes"
    
    # Title with preset info
    if preset_used$ = "custom"
        Text top: "yes", "Polynomial Function (CUSTOM)"
    else
        Text top: "yes", "Polynomial Function (Preset: ##preset_used$#)"
    endif
    
    Marks bottom every: 1, 1, "yes", "yes", "no"
    Text bottom: "yes", "Domain"
    
    # === BOTTOM GRAPH: Actual Intensity Envelope Over Time ===
    Select outer viewport: 0, 6, 3.5, 6.5
    
    # Create a silent sound with the same duration as the original
    selectObject: orig_id
    Create Sound from formula: "envelope_preview", 1, 0, dur, 10000, clamped_envelope$
    env_id = selected("Sound")
    
    # Draw with FIXED Y-axis to show dynamic range limits
    # Y-axis from -max_gain to +max_gain to show symmetric range
    Draw: 0, dur, -max_gain, max_gain, "no", "Curve"
    
    # Draw horizontal lines showing the dynamic range boundaries
    Draw line: 0, max_gain, dur, max_gain
    Draw line: 0, min_gain, dur, min_gain
    Draw line: 0, 0, dur, 0
    if min_gain > 0
        Draw line: 0, -min_gain, dur, -min_gain
        Draw line: 0, -max_gain, dur, -max_gain
    endif
    
    # Add markers for dynamic range
    One mark left: min_gain, "yes", "yes", "no", string$(min_gain)
    One mark left: max_gain, "yes", "yes", "no", string$(max_gain)
    if min_gain > 0
        One mark left: -min_gain, "yes", "yes", "no", string$(-min_gain)
    endif
    One mark left: -max_gain, "yes", "yes", "no", string$(-max_gain)
    One mark left: 0, "yes", "yes", "yes", "0"
    
    Marks bottom every: 1, 0.1, "yes", "yes", "no"
    Text bottom: "yes", "Time (s)"
    Text top: "yes", "Intensity Envelope (Weight=" + string$(perceptual_weight) + ", Range=±" + s_min_gain$ + " to ±" + s_max_gain$ + ")"
    
    removeObject: env_id
    
    # Reset viewport
    Select outer viewport: 0, 6, 0, 6.5
endif

# --- 6. PROCESSING (VECTORIZED) ---
selectObject: orig_id
Copy: orig_name$ + "_shaped"

# Apply the weighted polynomial envelope with dynamic range limiting
Formula: final_proc_formula$

# --- 7. FINALIZE ---
Scale peak: scalepeak

if play_result
    Play
endif


writeInfoLine: "Envelope applied successfully!"
appendInfoLine: "Preset used: ", preset_used$
appendInfoLine: ""
if envelope_type = 1
    appendInfoLine: "Type: Polynomial (standard)"
    appendInfoLine: "Coeffs: a=", coefa, ", b=", coefb, ", c=", coefc, ", d=", coefd
else
    appendInfoLine: "Type: Product Terms"
    if param3 = 0
        appendInfoLine: "Roots: ", param1, ", ", param2
    else
        appendInfoLine: "Roots: ", param1, ", ", param2, ", ", param3
    endif
endif
appendInfoLine: "Domain: [", startx, ", ", endx, "]"
appendInfoLine: ""
appendInfoLine: "Perceptual Weight: ", perceptual_weight
if perceptual_weight = 1.0
    appendInfoLine: "  → Linear amplitude (raw math)"
elsif perceptual_weight >= 3.0 and perceptual_weight <= 4.0
    appendInfoLine: "  → Perceptual loudness (logarithmic)"
else
    appendInfoLine: "  → Custom power law"
endif
appendInfoLine: ""
appendInfoLine: "Dynamic Range: ±", min_gain, " to ±", max_gain
if min_gain > 0
    min_db = 20 * log10(min_gain)
    appendInfoLine: "  → Floor: ", fixed$(min_db, 1), " dB"
else
    appendInfoLine: "  → Floor: -∞ dB (silence allowed)"
endif
if max_gain < 1
    max_db = 20 * log10(max_gain)
    appendInfoLine: "  → Ceiling: ", fixed$(max_db, 1), " dB"
else
    appendInfoLine: "  → Ceiling: 0 dB (full scale)"
endif
appendInfoLine: ""
appendInfoLine: "Original: Sound ", orig_name$
appendInfoLine: "Result: Sound ", orig_name$, "_shaped"

