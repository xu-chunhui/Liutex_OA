@ECHO OFF
TITLE Finding Liutex Core Lines
gfortran -c .\liutex_mod.f08
gfortran -c .\coreline_v3.f08
gfortran .\coreline_v3.o .\liutex_mod.o -o find_core_lines.exe
START /WAIT /B "Finding Liutex Core Lines" ".\find_core_lines.exe"
PAUSE