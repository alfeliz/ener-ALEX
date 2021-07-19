# ener-ALEX
Octave code to extract energy from ALEX channels data, actualized from last elec code.

## To work with it

Just execute the file "elec.m" in Octave, in the folder witht he ALEX electricity data. they can be within folders, ordered by voltage or other magnitude.
The program looks for the shot folders, extreact directly the current and voltage traces and operate with them to abtain energy and power. 
At the end, save average energy of the last moments, when the shot has finished to pass current, and the voltage really absorved by the wire for each shot and the average of the folders.

## Necessary files

Just the *elec.m* and *display_rounded_matrix.m* files.
