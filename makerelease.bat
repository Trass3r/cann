rdmd --build-only -release -O -inline -Isfml2\bindings\d\import -IDerelict2\DerelictGL -IDerelict2\DerelictUtil main.d

cv2pdb -D2 bin\main.exe
