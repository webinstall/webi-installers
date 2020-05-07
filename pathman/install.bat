pushd "%userprofile%" || goto :error
  IF NOT EXIST .local (
    mkdir .local || goto :error
  )
  IF NOT EXIST .local\bin (
    mkdir .local\bin || goto :error
  )

  pushd .local\bin || goto :error
    rem TODO %PROCESSOR_ARCH%
    powershell $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest "https://rootprojects.org/pathman/dist/windows/amd64/pathman.exe" -OutFile pathman.exe || goto :error
  popd || goto :error
popd

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
