@echo off
setlocal
rem Install the NDK version FlutterExtension.kt declares as default (28.2.13676358).
set "JAVA_HOME=E:\ProgrammFiles\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "SDK=C:\Users\MAX\AppData\Local\Android\Sdk"
set "SM=%SDK%\cmdline-tools\latest\bin\sdkmanager.bat"
set "YES=E:\dev\setup\yes.txt"
set "LOG=E:\dev\setup\sdk_ndk.log"

echo === install ndk 28.2.13676358 === > "%LOG%"
call "%SM%" --sdk_root="%SDK%" --verbose "ndk;28.2.13676358" < "%YES%" >> "%LOG%" 2>&1
echo ndk exit %ERRORLEVEL% >> "%LOG%"

echo === cmake (for build scripts, harmless if absent) === >> "%LOG%"
dir "%SDK%\ndk" >> "%LOG%" 2>&1
echo ALLDONE >> "%LOG%"
