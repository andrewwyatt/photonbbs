#!/bin/bash
DOORBAT="ooii.bat"
export HOME="/opt/photonbbs"
export TERM="ansi"
dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\$DOORBAT $2" 2>/dev/null
reset
