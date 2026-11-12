@echo off
cd /d "e:\AI Projects\First\build\web"
echo start %date% %time% > E:\dev\serve.log
python -m http.server 8090 --bind 127.0.0.1 >> E:\dev\serve.log 2>&1
