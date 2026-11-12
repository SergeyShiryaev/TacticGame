@echo off
rem Раздача собранной статики Flutter из build\web на http://127.0.0.1:8080
cd /d "e:\AI Projects\First"
start "flutter-web-static" /min cmd /c "python -m http.server 8080 --bind 127.0.0.1 --directory ""e:\AI Projects\First\build\web"" > ""E:\dev\serve.log"" 2>&1"
