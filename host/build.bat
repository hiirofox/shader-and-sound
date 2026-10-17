@echo off
setlocal
set "VSROOT=%ProgramFiles%\Microsoft Visual Studio\2022\Community"
if not exist "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" (
  echo Visual Studio 2022 C++ Build Tools not found.
  exit /b 1
)
call "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b 1
cl /nologo /c /O1 /Os /GS- /Gs65536 /Zl /Oi- /Gy /Gw runshd.c
if errorlevel 1 exit /b 1
link /nologo runshd.obj /out:runshd.exe /entry:entry /subsystem:windows /nodefaultlib /opt:ref /opt:icf /incremental:no /filealign:512 kernel32.lib user32.lib gdi32.lib opengl32.lib shell32.lib
if errorlevel 1 exit /b 1
del runshd.obj
for %%A in (runshd.exe) do echo Built %%~zA bytes: runshd.exe
