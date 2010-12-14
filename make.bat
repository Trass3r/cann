@del .deps
@del *.moduleDeps /Q
@del .objs /Q
@del *.rsp /Q

xfbuild main.d +v +obin\main +xcore +xstd -unittest -debug -g

cv2pdb -D2 bin\main.exe