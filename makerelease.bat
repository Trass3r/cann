@del .deps
@del *.moduleDeps /Q
@del .objs /Q
@del *.rsp /Q

xfbuild main.d +v +obin\main +xcore +xstd -release -O -inline -Isfml2\bindings\d\import -IDerelict2\DerelictGL -IDerelict2\DerelictUtil

cv2pdb -D2 bin\main.exe