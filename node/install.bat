@echo off
setlocal
pushd "%userprofile%" || goto :error
  pushd "%userprofile%\.local\opt" || goto :error
    powershell $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://nodejs.org/dist/v12.16.2/node-v12.16.2-win-x64.zip -OutFile node-v12.16.2-win-x64.zip || goto :error
    rem Windows BSD-tar handles zip. Imagine that.
    tar xf node-v12.16.2-win-x64.zip || goto :error
    dir
    rename node-v12.16.2-win-x64 node-v12.16.2 || goto :error
    rmdir node-v12.16.2-win-x64
    del node-v12.16.2-win-x64.zip || goto :error
  popd || goto :error

  rem make npm not act stupid about which node to use... ugh (this should be the default)
  .\.local\opt\node-v12.16.2\npm.cmd" --scripts-prepend-node-path=true config set scripts-prepend-node-path true || goto :error
  pathman add .local\opt\node-v12.16.2 || goto :error
popd || goto :error

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
