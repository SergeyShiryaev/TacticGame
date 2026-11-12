@echo off
rem Раздача собранной статики Flutter. Запускается как задача планировщика,
rem поэтому не зависит от процессов агента.
python -m http.server 8080 --bind 127.0.0.1 --directory "e:\AI Projects\First\build\web" > "E:\dev\serve.log" 2>&1
