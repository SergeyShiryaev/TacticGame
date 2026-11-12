@echo off
setlocal
rem Step 2: install the SDK packages Flutter 3.47.9 asks for.
rem Package names must stay quoted: cmd splits unquoted ';' into two args.
set "JAVA_HOME=E:\ProgrammFiles\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "SDK=C:\Users\MAX\AppData\Local\Android\Sdk"
set "SM=%SDK%\cmdline-tools\latest\bin\sdkmanager.bat"
set "YES=E:\dev\setup\yes.txt"
set "LOG=E:\dev\setup\sdk_lic.log"

echo === licenses === > "%LOG%"
call "%SM%" --sdk_root="%SDK%" --licenses < "%YES%" >> "%LOG%" 2>&1
echo licenses exit %ERRORLEVEL% >> "%LOG%"

echo === installed before === >> "%LOG%"
call "%SM%" --sdk_root="%SDK%" --list_installed >> "%LOG%" 2>&1

echo === install android-36 + build-tools 36.0.0 === >> "%LOG%"
call "%SM%" --sdk_root="%SDK%" --verbose "platforms;android-36" "build-tools;36.0.0" < "%YES%" >> "%LOG%" 2>&1
echo install exit %ERRORLEVEL% >> "%LOG%"

echo === installed after === >> "%LOG%"
call "%SM%" --sdk_root="%SDK%" --list_installed >> "%LOG%" 2>&1
echo ALLDONE >> "%LOG%"
