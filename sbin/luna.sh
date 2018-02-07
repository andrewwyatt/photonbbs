#!/bin/bash
export HOME="/opt/photonbbs"
export TERM="ansi"

cp ${HOME}/doors/tmplts/lunatix.tmplt ${HOME}/doors/luna/lunatix.$2
cp ${HOME}/doors/tmplts/linkto.tmplt ${HOME}/doors/luna/linkto.$2
sed -i "s/DORINFO1.DEF/$2\\\DORINFO1.DEF/" ${HOME}/doors/luna/linkto.$2

dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\luna.bat $2" 2>/dev/null
#dosemu -t -quiet "c:\\doors\\luna.bat $2" 2>/dev/null
reset
