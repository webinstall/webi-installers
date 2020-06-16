setlocal
@echo off
pushd "%userprofile%" || goto :error
  IF NOT EXIST .local (
    mkdir .local || goto :error
  )
  IF NOT EXIST .local\bin (
    mkdir .local\bin || goto :error
  )

  rem {{ baseurl }}
  rem {{ version }}
  pushd .local\bin || goto :error
    if NOT EXIST webi.bat (
      rem without SilentlyContinue this is SLOOOOOOOOOOOOOOOW!
      powershell $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://webinstall.dev/packages/_webi/webi.bat -OutFile webi.bat || goto :error
    )
    call .\webi {{ exename }} || goto :error
    rem pathman add "%userprofile%\.local\bin" >nul 2>&1 || goto :error
    pathman add "%userprofile%\.local\bin" || goto :error
  popd || goto :error
popd

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
