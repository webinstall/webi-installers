rem TODO
@echo off
rem get OS version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "6.3" set currentOS=win8.1
if "%version%" == "6.2" set currentOS=win8
if "%version%" == "6.1" set currentOS=win7
if "%version%" == "6.0" set currentOS=winVista
if "%version%" == "10.0" set currentOS=win10

rem get this Computer Architecture
set currentArch=%processor_architecture%


echo This PC OS = %currentOS%
echo This PC arch = %currentArch%

set pkg=node
set ver=12


rem invoke PowerShell to fetch CSV from the page on URL
for /f "tokens=*" %%i in ('powershell.exe -command "(Invoke-WebRequest -URI 'https://webinstall.dev/api/releases/%pkg%@%ver%.csv?os=%currentOS%&arch=%currentArch%&channel=stable&ext=zip&limit=1').Content"') do set return=%%i

rem Break apart the CSV returned by the webpage on URL
for /F "tokens=1-9 delims=," %%a in ("%return%") do (
set version=%%a
set pkg_url=%%i
set os=%%e
set arch=%%f
)

rem Break apart parts of pkg_url to file name & directory
for /F "tokens=1-5 delims=/" %%a in ("%pkg_url%") do (
set pkg_file=%%e
set pkg_dir=%%c
)



rem Final variable names as below.
echo Reurned CSV = %return% & echo.
echo Version = %version%
echo Url = %pkg_url%
echo pkg_file = %pkg_file%
echo pkg_dir = %pkg_dir%
echo os in CSV = %os%
echo arch in CSV = %arch%
echo this PC OS = %currentOS%
echo this PC arch = %currentArch%
