@ECHO OFF
C:
CD \DOORS\SIMP
COPY c:\NODEINFO\%1\DORINFO%1.DEF .
SIMPSONS %1
EXITEMU
