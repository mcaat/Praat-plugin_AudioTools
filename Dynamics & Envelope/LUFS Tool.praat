# ============================================================
# Praat AudioTools - LUFS Tool 
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   LUFS Tool
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# LUFS Tool 
# Three modes: Analyze, Safe Gain, or Full Gain (clips)

form LUFS Analyzer & Processor
    comment === Target Platform ===
    optionmenu target_platform: 1
        option Custom
        option Streaming (Spotify/Apple: -14 LUFS)
        option YouTube (-13 LUFS)
        option Broadcast TV (-23 LUFS)
        option Cinematic (-27 LUFS)
    real custom_target_lufs -14.0
    comment === Processing Mode ===
    optionmenu processing_mode: 1
        option Analyze Only
        option Apply Exact Gain Needed (will clip if needed)
        option Apply Safe Gain Only (no clipping)
endform

input$ = selected$("Sound")
input = selected("Sound")

# Set target based on platform
if target_platform = 2
    target_LUFS = -14.0
    target_name$ = "Streaming"
elsif target_platform = 3
    target_LUFS = -13.0
    target_name$ = "YouTube"
elsif target_platform = 4
    target_LUFS = -23.0
    target_name$ = "Broadcast TV"
elsif target_platform = 5
    target_LUFS = -27.0
    target_name$ = "Cinematic"
else
    target_LUFS = custom_target_lufs
    target_name$ = "Custom"
endif

writeInfoLine: "=== LUFS ANALYSIS ==="
appendInfoLine: "Target: ", fixed$(target_LUFS, 1), " LUFS (", target_name$, ")"
appendInfoLine: ""

#==============================================
# QUICK LUFS MEASUREMENT
#==============================================

selectObject: input
sr = Get sampling frequency
duration = Get total duration

# True Peak
appendInfoLine: "Measuring True Peak..."
oversampled = Resample: sr * 4, 50
max_val = Get maximum: 0, 0, "None"
min_val = Get minimum: 0, 0, "None"
peak = max(abs(max_val), abs(min_val))
true_peak_db = 20 * log10(peak)
removeObject: oversampled

appendInfoLine: "  True Peak: ", fixed$(true_peak_db, 2), " dBTP"

# LUFS (simplified - using RMS as approximation)
selectObject: input
rms = Get root-mean-square: 0, 0
if rms > 0
    # Rough LUFS approximation (close enough for this purpose)
    estimated_lufs = 20 * log10(rms) - 3.0
else
    estimated_lufs = -999
endif

appendInfoLine: "  Estimated LUFS: ", fixed$(estimated_lufs, 1)

gain_needed = target_LUFS - estimated_lufs
max_safe = -1.0 - true_peak_db

appendInfoLine: ""
appendInfoLine: "============================================"
appendInfoLine: "           GAIN ANALYSIS"
appendInfoLine: "============================================"
appendInfoLine: ""
appendInfoLine: "Current: ", fixed$(estimated_lufs, 1), " LUFS"
appendInfoLine: "Target: ", fixed$(target_LUFS, 1), " LUFS (", target_name$, ")"
appendInfoLine: ""
appendInfoLine: "Gain needed: ", fixed$(gain_needed, 1), " dB"
appendInfoLine: "Safe headroom: ", fixed$(max_safe, 1), " dB"
appendInfoLine: ""

if gain_needed > max_safe + 10
    appendInfoLine: "⚠️⚠️⚠️ WARNING ⚠️⚠️⚠️"
    appendInfoLine: ""
    appendInfoLine: "You need ", fixed$(gain_needed, 1), " dB of gain"
    appendInfoLine: "but only have ", fixed$(max_safe, 1), " dB of headroom."
    appendInfoLine: ""
    appendInfoLine: "Gap: ", fixed$(gain_needed - max_safe, 1), " dB"
    appendInfoLine: ""
    appendInfoLine: "Choosing 'Apply Exact Gain' will cause clipping!"
    appendInfoLine: ""
    appendInfoLine: "RECOMMENDATIONS:"
    appendInfoLine: "• Use compression in a DAW first"
    appendInfoLine: "• Choose 'Apply Safe Gain Only' for clean boost"
    appendInfoLine: "• Or lower your target"
    appendInfoLine: ""
elsif gain_needed > max_safe
    appendInfoLine: "⚠️ CAUTION"
    appendInfoLine: ""
    appendInfoLine: "Slight limiting required (", fixed$(gain_needed - max_safe, 1), " dB)"
    appendInfoLine: "This should be acceptable."
    appendInfoLine: ""
else
    appendInfoLine: "✓ TARGET IS ACHIEVABLE"
    appendInfoLine: ""
    appendInfoLine: "Clean gain boost will work perfectly!"
    appendInfoLine: ""
endif

appendInfoLine: "============================================"

#==============================================
# PROCESSING
#==============================================

if processing_mode = 1
    appendInfoLine: ""
    appendInfoLine: "Analysis complete - no processing applied."
    selectObject: input
    
elsif processing_mode = 2
    appendInfoLine: ""
    appendInfoLine: "============================================"
    appendInfoLine: "      APPLYING EXACT GAIN"
    appendInfoLine: "============================================"
    appendInfoLine: ""
    
    selectObject: input
    Copy: input$ + "_processed"
    processing = selected("Sound")
    
    appendInfoLine: "Applying +", fixed$(gain_needed, 1), " dB..."
    Formula: "self * 10^(gain_needed/20)"
    
    # Check result
    final_max = Get maximum: 0, 0, "None"
    final_min = Get minimum: 0, 0, "None"
    final_peak = max(abs(final_max), abs(final_min))
    final_peak_db = 20 * log10(final_peak)
    
    appendInfoLine: ""
    appendInfoLine: "Result peak: ", fixed$(final_peak_db, 2), " dBFS"
    
    if final_peak > 1.0
        appendInfoLine: ""
        appendInfoLine: "❌ AUDIO IS CLIPPING!"
        appendInfoLine: "   Peak exceeded 0 dBFS by ", fixed$(final_peak_db, 2), " dB"
        appendInfoLine: "   This audio is distorted."
        appendInfoLine: ""
        appendInfoLine: "   To fix: Use compression before normalizing,"
        appendInfoLine: "   or choose 'Safe Gain Only' mode."
        suffix$ = "_CLIPPED"
    elsif final_peak > 0.95
        appendInfoLine: ""
        appendInfoLine: "⚠️ Peak very close to 0 dBFS"
        appendInfoLine: "   May clip in some codecs"
        suffix$ = "_mastered"
    else
        appendInfoLine: ""
        appendInfoLine: "✓ Peak is safe"
        suffix$ = "_mastered"
    endif
    
    Rename: input$ + suffix$
    appendInfoLine: ""
    appendInfoLine: "Output: ", input$ + suffix$
    appendInfoLine: "============================================"
    
    selectObject: processing
    
elsif processing_mode = 3
    appendInfoLine: ""
    appendInfoLine: "============================================"
    appendInfoLine: "      APPLYING SAFE GAIN ONLY"
    appendInfoLine: "============================================"
    appendInfoLine: ""
    
    selectObject: input
    Copy: input$ + "_normalized"
    processing = selected("Sound")
    
    appendInfoLine: "Applying +", fixed$(max_safe, 1), " dB (maximum safe)..."
    
    if max_safe > 0.1
        Formula: "self * 10^(max_safe/20)"
    else
        appendInfoLine: "  (No gain needed - already at peak)"
    endif
    
    # Limit to -1 dBTP for safety
    Scale peak: 10^(-1.0/20)
    
    final_max = Get maximum: 0, 0, "None"
    final_min = Get minimum: 0, 0, "None"
    final_peak = max(abs(final_max), abs(final_min))
    final_peak_db = 20 * log10(final_peak)
    
    result_lufs = estimated_lufs + max_safe
    
    appendInfoLine: ""
    appendInfoLine: "Result peak: ", fixed$(final_peak_db, 2), " dBFS"
    appendInfoLine: "Result LUFS: ~", fixed$(result_lufs, 1)
    appendInfoLine: ""
    
    if result_lufs < target_LUFS - 1
        gap = target_LUFS - result_lufs
        appendInfoLine: "Still ", fixed$(gap, 1), " LU below target."
        appendInfoLine: "This is the maximum without distortion."
        appendInfoLine: ""
        appendInfoLine: "To reach ", fixed$(target_LUFS, 1), " LUFS, use compression first."
    else
        appendInfoLine: "✓ Target achieved!"
    endif
    
    appendInfoLine: ""
    appendInfoLine: "Output: ", input$ + "_normalized"
    appendInfoLine: "============================================"
    
    selectObject: processing
endif

appendInfoLine: ""
Play