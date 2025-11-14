# ============================================================
# Praat AudioTools - Whisper Morph.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Whisper Morph
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================

# Whisper Morph Script
# Gradually transition between original sound and whisper effect

form Whisper Morph Controls
	comment Choose morphing parameters:
	optionmenu Morph_type: 1
		option Dry to Wet (original → whisper)
		option Wet to Dry (whisper → original)
		option Dry to Wet to Dry (original → whisper → original)
endform

# Get original sound
s = selected("Sound")
s$ = selected$("Sound")
original_dur = Get total duration
int = Get intensity (dB)

if int <> undefined
	# Create whispered version
	selectObject: s
	original = Copy: "original_temp"
	
	selectObject: s
	workpre = Copy: s$ + "_workpre"
	sf = Get sampling frequency
	dur = Get total duration
	Scale peak: 0.99
	
	# Simple gate (instead of runScript)
	Formula: "if self < -0.01 then self else if self > 0.01 then self else 0 fi fi"
	
	tmp2 = Copy: "tmp2"
	Formula: "self + randomUniform(-0.00001, 0.00001)"
	pred_order = round(sf / 1000) + 2
	lpc = noprogress To LPC (burg): pred_order, 0.025, 0.01, 50
	
	noise = Create Sound from formula: "noise", 1, 0, dur, sf, "randomUniform(-1, 1)"
	plusObject: lpc
	tmp3 = noprogress Filter: "yes"
	
	# Restore original duration
	tmp3_resampled = Resample: sf, 50
	removeObject: tmp3
	selectObject: tmp3_resampled
	Override sampling frequency: sf
	Scale peak: 0.99
	
	# Apply EQ emphasis
	Formula: "self * 4"
	
	tmp6 = Copy: "tmp6"
	Scale peak: 0.99
	
	intensity_obj = noprogress To Intensity: 400, 0, "no"
	Formula: "if round(self) = 0 then 0 else if self > 85 then 1 / self - (self - 85) else 1 / self fi fi"
	intensitytier = Down to IntensityTier
	
	selectObject: tmp6
	plusObject: intensitytier
	tmp6_mult = Multiply: "yes"
	removeObject: tmp6
	selectObject: tmp6_mult
	
	# Fix DC offset
	Subtract mean
	
	Scale intensity: int
	
	whispered = Copy: "whispered_temp"
	
	# Create morphed sound with time-based crossfade
	selectObject: original
	morphed = Copy: "morphed_temp"
	
	# Apply time-varying mix formula
	if morph_type = 1
		# Dry to wet: mix goes from 0 to 1
		Formula: "self * (1 - x/dur) + object[whispered, col] * (x/dur)"
	elsif morph_type = 2
		# Wet to dry: mix goes from 1 to 0
		Formula: "self * (x/dur) + object[whispered, col] * (1 - x/dur)"
	else
		# Dry to wet to dry: mix goes 0→1→0
		Formula: "self * (1 - if x < dur/2 then x/(dur/2) else 1 - (x-dur/2)/(dur/2) fi) + object[whispered, col] * (if x < dur/2 then x/(dur/2) else 1 - (x-dur/2)/(dur/2) fi)"
	endif
	
	Rename: s$ + "-whisper-morph"
	
	# Clean up ALL temporary objects
	removeObject: original, workpre, tmp2, lpc, noise, tmp3_resampled
	removeObject: intensity_obj, intensitytier, whispered, tmp6_mult
else
	selectObject: s
	Copy: s$ + "-whisper-morph"
endif
Play