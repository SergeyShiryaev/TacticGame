# Step 2: packages for the SDK. Package names MUST be quoted: cmd splits on ';'.
$ErrorActionPreference = 'Continue'
$log = 'E:\dev\setup\setup2.log'
$sm = 'C:\Users\MAX\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat'
$sdk = 'C:\Users\MAX\AppData\Local\Android\Sdk'
$env:JAVA_HOME = 'E:\ProgrammFiles\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
function L($m) { (Get-Date -Format 'HH:mm:ss') + '  ' + $m | Add-Content -Path $log }

$yes = ('y' + [Environment]::NewLine) * 60
L 'licenses ...'
$yes | cmd /c "\"$sm\" --sdk_root=$sdk --licenses" 2>&1 | Add-Content -Path $log
L ('licenses exit = ' + $LASTEXITCODE)

L 'installed before:'
cmd /c "\"$sm\" --sdk_root=$sdk --list_installed" 2>&1 | Add-Content -Path $log

L 'install platforms:android-36 + build-tools:36.0.0 ...'
$yes | cmd /c "\"$sm\" --sdk_root=$sdk --verbose \"platforms;android-36\" \"build-tools;36.0.0\"" 2>&1 | Add-Content -Path $log
L ('install exit = ' + $LASTEXITCODE)

L 'installed after:'
cmd /c "\"$sm\" --sdk_root=$sdk --list_installed" 2>&1 | Add-Content -Path $log
'DONE' | Add-Content $log
