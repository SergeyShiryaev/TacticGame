@echo off
rem Build script for the release APK. Run detached, log goes to E:\dev\setup\apk.log.
setlocal

set "JAVA_HOME=E:\ProgrammFiles\Android\Android Studio\jbr"
set "ANDROID_SDK_ROOT=C:\Users\MAX\AppData\Local\Android\Sdk"
set "ANDROID_HOME=C:\Users\MAX\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"

set "LOG=E:\dev\setup\apk.log"

echo === build start %DATE% %TIME% === > "%LOG%"
"%JAVA_HOME%\bin\java.exe" -version >> "%LOG%" 2>&1
echo === flutter --version === >> "%LOG%" 2>&1
"E:\dev\flutter\bin\flutter.bat" --version >> "%LOG%" 2>&1

cd /d "E:\AI Projects\First"
echo === flutter build apk --release === >> "%LOG%" 2>&1
"E:\dev\flutter\bin\flutter.bat" build apk --release >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
echo FLUTTER_EXIT=%RC% >> "%LOG%" 2>&1

echo === apk artifacts === >> "%LOG%" 2>&1
dir /s /b "E:\AI Projects\First\build\app\outputs\flutter-apk\*.apk" >> "%LOG%" 2>&1
echo ALLDONE >> "%LOG%" 2>&1
endlocal
