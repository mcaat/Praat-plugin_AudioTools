# ============================================================
# Praat AudioTools - Chaotic Function Generator.praat
# Author: Shai Cohen
# Affiliation: Department of Music, Bar-Ilan University, Israel
# Email: shai.cohen@biu.ac.il
# Version: 0.1 (2025)
# License: MIT License
# Repository: https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
#
# Description:
#   Chaotic Function Generator
#
# Usage:
#   Select a Sound object in Praat and run this script.
#   Adjust parameters via the form dialog.
#
# Citation:
#   Cohen, S. (2025). Praat AudioTools: An Offline Analysis–Resynthesis Toolkit for Experimental Composition.
#   https://github.com/ShaiCohen-ops/Praat-plugin_AudioTools
# ============================================================
# Chaotic Function Generator 
# Allows you to choose among several chaotic formulas and visualize them.
form Chaotic Function Generator
    optionmenu function 1
        option sin(1/x)
        option sin((1/x)*(1/(1-x)))
        option (2*sin(3/x))+(3*cos(5/x))+(4*sin(6/x))+(1*cos(3/x))
        option sin(3/x)*sin(5/(1-x))
        option sin(1/x) + (2*sin(1/(1-x)))
        option tan(1/x)*cos(1/(1-x))
        option sin(1/x^2)*cos(1/(1-x)^2)
        option exp(-1/x^2)*sin(50*x)
        option sin(1/x)*cos(1/x^2)
        option (sin(1/x)+sin(1/x^3))/2
        option atan(1/x)*sin(10/x)
        option sin(1/(x*(1-x)))
        option cos(1/x^3)+sin(1/(1-x)^3)
        option sin(ln(x+0.01))*cos(ln(1.01-x))
        option (1/x)*sin(10*x)+(1/(1-x))*cos(10*(1-x))
        option sin(1/sqrt(x+0.001))*cos(1/sqrt(1.001-x))
        option exp(sin(1/x))*cos(1/(1-x))
        option sin(1/x)*sin(1/x^2)*sin(1/x^3)
        option Logistic Map: r*x*(1-x) [r=3.9]
        option Tent Map: min(2*x, 2*(1-x))
        option Custom…
    real duration_seconds 1.0
    integer sampling_rate_Hz 44100
    text custom_formula sin(1/x)
endform

# Avoid division by zero at x=0 or x=1
eps1 = 1e-4
eps2 = 1e-4

# Select formula based on option menu
if function$ = "sin(1/x)"
    formula$ = "sin(1/(x+" + string$(eps1) + "))"
elsif function$ = "sin((1/x)*(1/(1-x)))"
    formula$ = "sin((1/(x+" + string$(eps1) + "))*(1/((1-x)+" + string$(eps2) + ")))"
elsif function$ = "(2*sin(3/x))+(3*cos(5/x))+(4*sin(6/x))+(1*cos(3/x))"
    formula$ = "(2*sin(3/(x+" + string$(eps1) + ")))+(3*cos(5/(x+" + string$(eps1) + ")))+(4*sin(6/(x+" + string$(eps1) + ")))+(1*cos(3/(x+" + string$(eps1) + ")))"
elsif function$ = "sin(3/x)*sin(5/(1-x))"
    formula$ = "sin(3/(x+" + string$(eps1) + "))*sin(5/((1-x)+" + string$(eps2) + "))"
elsif function$ = "sin(1/x) + (2*sin(1/(1-x)))"
    formula$ = "sin(1/(x+" + string$(eps1) + "))+(2*sin(1/((1-x)+" + string$(eps2) + ")))"
elsif function$ = "tan(1/x)*cos(1/(1-x))"
    formula$ = "tan(1/(x+" + string$(eps1) + "))*cos(1/((1-x)+" + string$(eps2) + "))"
elsif function$ = "sin(1/x^2)*cos(1/(1-x)^2)"
    formula$ = "sin(1/((x+" + string$(eps1) + ")^2))*cos(1/(((1-x)+" + string$(eps2) + ")^2))"
elsif function$ = "exp(-1/x^2)*sin(50*x)"
    formula$ = "exp(-1/((x+" + string$(eps1) + ")^2))*sin(50*x)"
elsif function$ = "sin(1/x)*cos(1/x^2)"
    formula$ = "sin(1/(x+" + string$(eps1) + "))*cos(1/((x+" + string$(eps1) + ")^2))"
elsif function$ = "(sin(1/x)+sin(1/x^3))/2"
    formula$ = "(sin(1/(x+" + string$(eps1) + "))+sin(1/((x+" + string$(eps1) + ")^3)))/2"
elsif function$ = "atan(1/x)*sin(10/x)"
    formula$ = "arctan(1/(x+" + string$(eps1) + "))*sin(10/(x+" + string$(eps1) + "))"
elsif function$ = "sin(1/(x*(1-x)))"
    formula$ = "sin(1/((x+" + string$(eps1) + ")*((1-x)+" + string$(eps2) + ")))"
elsif function$ = "cos(1/x^3)+sin(1/(1-x)^3)"
    formula$ = "cos(1/((x+" + string$(eps1) + ")^3))+sin(1/(((1-x)+" + string$(eps2) + ")^3))"
elsif function$ = "sin(ln(x+0.01))*cos(ln(1.01-x))"
    formula$ = "sin(ln(x+0.01))*cos(ln(1.01-x))"
elsif function$ = "(1/x)*sin(10*x)+(1/(1-x))*cos(10*(1-x))"
    formula$ = "(1/(x+" + string$(eps1) + "))*sin(10*x)+(1/((1-x)+" + string$(eps2) + "))*cos(10*(1-x))"
elsif function$ = "sin(1/sqrt(x+0.001))*cos(1/sqrt(1.001-x))"
    formula$ = "sin(1/sqrt(x+0.001))*cos(1/sqrt(1.001-x))"
elsif function$ = "exp(sin(1/x))*cos(1/(1-x))"
    formula$ = "exp(sin(1/(x+" + string$(eps1) + ")))*cos(1/((1-x)+" + string$(eps2) + "))"
elsif function$ = "sin(1/x)*sin(1/x^2)*sin(1/x^3)"
    formula$ = "sin(1/(x+" + string$(eps1) + "))*sin(1/((x+" + string$(eps1) + ")^2))*sin(1/((x+" + string$(eps1) + ")^3))"
elsif function$ = "Logistic Map: r*x*(1-x) [r=3.9]"
    formula$ = "3.9*x*(1-x)"
elsif function$ = "Tent Map: min(2*x, 2*(1-x))"
    formula$ = "if x<0.5 then 2*x else 2*(1-x) endif"
elsif function$ = "Custom…"
    formula$ = custom_formula$
else
    formula$ = "sin(1/(x+" + string$(eps1) + "))"
endif

# Generate and draw the chaotic waveform
Erase all
Create Sound from formula: "chaos", 1, 0, duration_seconds, sampling_rate_Hz, formula$
Scale peak: 0.99
Play
selectObject: "Sound chaos"
Draw: 0, 0, 0, 0, "yes", "Curve"