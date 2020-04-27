mkdir %userprofile%\.local
mkdir %userprofile%\.local\opt

pushd %userprofile%\.local\opt
  powershell $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://nodejs.org/dist/v12.16.2/node-v12.16.2-win-x64.zip -OutFile node-v12.16.2-win-x64.zip
  tar xf node-v12.16.2-win-x64.zip
  move node-v12.16.2-win-x64 node-v12.16.2
popd

pathman add %userprofile%\.local\opt\node-v12.16.2\bin
