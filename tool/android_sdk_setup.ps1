# Setup Android SDK command-line tools + packages needed by Flutter 3.47.9.
# Run detached: powershell -NoProfile -ExecutionPolicy Bypass -File tool\android_sdk_setup.ps1
$ErrorActionPreference = 'Continue'
$log = 'E:\dev\setup\setup.log'
New-Item -ItemType Directory -Force -Path 'E:\dev\setup' | Out-Null
function L($m) { (Get-Date -Format 'HH:mm:ss') + '  ' + $m | Add-Content -Path $log }

$env:JAVA_HOME = 'E:\ProgrammFiles\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$sdk = 'C:\Users\MAX\AppData\Local\Android\Sdk'
$zip = 'E:\dev\setup\ct.zip'
$url = 'https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip'

L 'JAVA_HOME = ' + $env:JAVA_HOME
& java -version 2>&1 | ForEach-Object { L ('java: ' + $_) }

L 'download cmdline-tools ...'
& curl.exe -sSL --fail --retry 5 -C - -o $zip $url
L ('curl exit = ' + $LASTEXITCODE + '  size = ' + (Get-Item $zip -EA SilentlyContinue).Length)
if ($LASTEXITCODE -ne 0) { L 'DOWNLOAD FAILED, abort'; 'FAILED' | Add-Content $log; exit 1 }

L 'unzip ...'
Remove-Item 'E:\dev\setup\ct' -Recurse -Force -EA SilentlyContinue
Expand-Archive -Path $zip -DestinationPath 'E:\dev\setup\ct' -Force
L ('unzipped root: ' + ((Get-ChildItem 'E:\dev\setup\ct').Name -join ', '))

$dst = Join-Path $sdk 'cmdline-tools\latest'
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item 'E:\dev\setup\ct\cmdline-tools\*' -Destination $dst -Recurse -Force
$sm = Join-Path $dst 'bin\sdkmanager.bat'
L ('sdkmanager exists = ' + (Test-Path $sm))
if (-not (Test-Path $sm)) { L 'NO SDKMANAGER, abort'; 'FAILED' | Add-Content $log; exit 1 }

$yes = ('y' + [Environment]::NewLine) * 40
L 'licenses ...'
$yes | & $sm --sdk_root=$sdk --licenses 2>&1 | Select-Object -Last 3 | ForEach-Object { L ('lic: ' + $_) }
L ('licenses exit = ' + $LASTEXITCODE)

L 'install packages ...'
$pkgs = @('platform-tools', 'platforms;android-36', 'build-tools;36.0.0')
$yes | & $sm --sdk_root=$sdk --verbose @pkgs 2>&1 | Add-Content -Path $log
L ('packages exit = ' + $LASTEXITCODE)

L 'platforms after: ' + ((Get-ChildItem (Join-Path $sdk 'platforms') -EA SilentlyContinue).Name -join ', ')
L 'build-tools after: ' + ((Get-ChildItem (Join-Path $sdk 'build-tools') -EA SilentlyContinue).Name -join ', ')
'DONE' | Add-Content $log
