# ============================================================
# Praat AudioTools - Stereo Channel Similarity Meter.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Stereo Channel Similarity Meter
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================


#Stereo Channel Similarity Meter

sound = selected("Sound")
soundName$ = selected$("Sound")
numberOfChannels = Get number of channels
if numberOfChannels != 2
    exitScript "This is not a stereo file. It has 'numberOfChannels' channels."
endif

select sound
channel1 = Extract one channel: 1
select sound
channel2 = Extract one channel: 2

select sound
totalSamples = Get number of samples
samplingRate = Get sampling frequency
step = max(1, totalSamples / 1000)
similarSamples = 0
comparedSamples = 0

i = 1
while i <= totalSamples
    time = (i - 1) / samplingRate
    select channel1
    value1 = Get value at time: time, "Nearest"
    select channel2
    value2 = Get value at time: time, "Nearest"
    difference = abs(value1 - value2)
    if difference < 0.0001
        similarSamples = similarSamples + 1
    endif
    comparedSamples = comparedSamples + 1
    i = i + step
endwhile

similarity = (similarSamples / comparedSamples) * 100

echo "Similarity: 'similarity:1'%"

select channel1
plus channel2
Remove