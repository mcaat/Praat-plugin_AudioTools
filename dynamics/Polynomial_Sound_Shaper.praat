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
form apply polynomial envelope
    choice preset 1
        option cubic_1
        option cubic_2
        option cubic_3
        option cubic_4
        option cubic_5
    real startx -3
    real endx 4
    real coefa 2
    real coefb -1
    real coefc -2
    real coefd 1
    real scalepeak 0.99
endform

if preset = 1
    coefa = 2
    coefb = -1
    coefc = -2
    coefd = 1
elsif preset = 2
    coefa = -1
    coefb = 3
    coefc = -1
    coefd = 0.5
elsif preset = 3
    coefa = 1
    coefb = 0
    coefc = -3
    coefd = 1
elsif preset = 4
    coefa = 3
    coefb = -2
    coefc = 0
    coefd = 1
elsif preset = 5
    coefa = -2
    coefb = 1
    coefc = 1
    coefd = 0
endif

soundname$ = selected$("Sound")
if soundname$ = ""
    exit please select a sound first.
endif

dur = Get total duration

Create Polynomial: "p", startx, endx, { coefa, coefb, coefc, coefd }

Erase all
Draw: 0, 0, 0, 0, "no", "yes"

selectObject: "Sound " + soundname$
Copy: soundname$ + "_shaped"
selectObject: "Sound " + soundname$ + "_shaped"

Formula... self * (coefa*((x/dur)*(endx-startx)+startx)^3 + coefb*((x/dur)*(endx-startx)+startx)^2 + coefc*((x/dur)*(endx-startx)+startx) + coefd)

Scale peak... scalepeak
Play
