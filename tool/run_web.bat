@echo off
set "PATH=E:\dev\flutter\bin;%PATH%"
set "PUB_CACHE=E:\dev\pubcache"
cd /d "e:\AI Projects\First"
echo START %TIME%> "E:\dev\run.log"
start "flutter-run" /min cmd /c "flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1 >> ""E:\dev\run.log"" 2>&1"
echo STOPPED %TIME%>> "E:\dev\run.log"
