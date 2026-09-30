@echo off
rem Install the PsychoPy version of ALM on Windows. Double-click this file once.
rem Creates the Python environment, an "alm" command, and an ALM launcher on the desktop.
cd /d "%~dp0"

rem uv provides Python 3.10 (which PsychoPy needs) and installs the packages
where uv >nul 2>nul
if not errorlevel 1 goto have_uv
echo Installing uv (https://docs.astral.sh/uv/)...
powershell -NoProfile -ExecutionPolicy ByPass -Command "irm https://astral.sh/uv/install.ps1 | iex"
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
:have_uv
uv venv --allow-existing --python 3.10 .venv || goto failed
uv pip install --python .venv -r requirements.txt || goto failed

rem "alm" command
if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
> "%USERPROFILE%\.local\bin\alm.bat" echo @"%~dp0.venv\Scripts\python.exe" "%~dp0alm.py" %%*

rem desktop shortcut, only if wanted (the window stays open at the end so any error can be read)
set "SHORTCUT="
choice /c yn /n /m "Create a desktop shortcut? [y/n] "
if errorlevel 2 goto no_shortcut
for /f "usebackq delims=" %%d in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%d"
> "%DESKTOP%\ALM.bat" echo @"%~dp0.venv\Scripts\python.exe" "%~dp0alm.py"
>> "%DESKTOP%\ALM.bat" echo @pause
set "SHORTCUT=1"
:no_shortcut

echo.
echo Installed. To run ALM:
if defined SHORTCUT echo   - double-click ALM.bat on the desktop
echo   - or type: alm   (in a new Command Prompt)
pause
exit /b 0

:failed
echo.
echo Installation failed; see the messages above.
pause
exit /b 1
