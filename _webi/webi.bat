@echo off
pushd "%userprofile%" || goto :error
  IF NOT EXIST .local (
    mkdir .local || goto :error
  )
  IF NOT EXIST .local\bin (
    mkdir .local\bin || goto :error
  )
  IF NOT EXIST .local\opt (
    mkdir .local\opt || goto :error
  )

  echo Downloading and installing %1
  powershell $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://webinstall.dev/packages/%1/install.ps1 -OutFile %1-webinstall.bat || goto :error

  rem TODO only add if it's not in there already
  PATH .local\bin;%PATH%

  call %1-webinstall.bat || goto :error
  del %1-webinstall.bat || goto :error
popd

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
