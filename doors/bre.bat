@ECHO OFF
C:
CD \doors\BRE
DEL \bre\in_use*.*
SRDOOR -f setup.%1
BRE
EXITEMU
