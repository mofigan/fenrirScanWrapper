@echo off
rem fenrirScanWrapper.bat - Path splitter for the offline devices.
rem   Install. copy fenrirScanWrapper.bat c:\fenrirDir
rem   Example. fenrirScanWrapper --scan --restart
rem            fenrirScanWrapper --fenrir-scan --restart --backup --large
setlocal
set DriveLetters=c d e f g h i j k x y z
set DriveLettersFixed=c d
set Expire=32
set FenrirDir=.
set EnableScan=no
set EnableFenrirScan=no
set EnableRestartFenrir=no
set EnablePause=no
set EnableLargeMode=no
set EnableBackup=no
set EnableExpire=no
set MyVersion=0.2.1

:sub_main
  set MyName=%0
  call :sub_check
  if NOT %errorlevel%==0 goto end
  call :sub_getopt %*
  call :sub_scan
  call :sub_build_path
  call :sub_restart
  :end
  call :sub_pause
exit /b 0

:sub_check
  pushd "%FenrirDir%"
    if NOT "%errorlevel%"=="0" call :usage "Bad FenrirDir." && exit /b 1
    if NOT exist "fenrir.exe" call :usage "Bad fenrir.exe" && exit /b 1
    if NOT exist "data" call :usage "Bad data dir." && exit /b 1
  popd
exit /b 0

:usage
  echo FAILED: %1
  echo usage: %MyName% [--scan|--fenrir-scan] [--restart] [--pause] [--large]
exit /b 0

:sub_getopt
  if NOT "%*"=="" echo %time% options: %*
  for %%P in (%*) do (
    echo getopt: %%P
    if "%%P"=="--scan" set EnableScan=yes
    if "%%P"=="--fenrir-scan" set EnableFenrirScan=yes
    if "%%P"=="--restart" set EnableRestartFenrir=yes
    if "%%P"=="--pause" set EnablePause=yes
    if "%%P"=="--large" set EnableLargeMode=yes
    if "%%P"=="--backup" set EnableBackup=yes
    if "%%P"=="--expire" set EnableExpire=yes
  )
exit /b 0

:sub_scan
  if "%EnableBackup%"=="yes" call :sub_backup "%FenrirDir%\data" path
  if exist "%FenrirDir%" pushd "%FenrirDir%
    if "%EnableScan%"=="yes" (
      echo %time% Scan.
      fenrir.exe /t /key=/s
    ) else (
      if "%EnableFenrirScan%"=="yes" (
        echo %time% Scan by fenrirScan.exe
        if exist fenrirScan.exe fenrirScan.exe
      )
    )
    echo %time% fenrir terminated.
    fenrir.exe /t /key=/x
  popd
exit /b 0

:sub_build_path
  set nowymd=%date:/=%
  if exist "%FenrirDir%" pushd "%FenrirDir%\data"
  if NOT exist "%FenrirDir%" pushd data
    set Pre=%COMPUTERNAME%_path_
    echo %time% Split path.
    for %%D in (%DriveLetters%) do (
      findstr /B /I "%%D:" path > %Pre%%%D.find
      for %%X in (%DriveLettersFixed%) do (
        if %%X==%%D move /y %Pre%%%D.find %Pre%%%D.txt
      )
      for %%F in (%Pre%%%D.find) do (
        if NOT %%~zF==0 if NOT exist %Pre%%%D.txt move /y %%F %Pre%%%D.txt
        for %%T in (%Pre%%%D.txt) do (
          if "%EnableLargeMode%"=="yes" (
            if %%~zF GTR %%~zT move /y %%F %%T
          ) else (
            if exist "%%F" move /y %%F %%T
          )
          if "%EnableExpire%"=="yes" if exist "%%D:\" if exist "%%F" (
            call :sub_get_tsymd %%T
            if NOT "%%~zF"=="%%~zT" if NOT "%nowymd%"=="%tsymd%" move /y %%F %%T
          )
          if "%%~zT"=="0" del /f "%%T"
          if NOT "%%~zT"=="" echo %time% %%T: %%~tT, %%~zT bytes.
        )
      )
      del /f "%Pre%%%D.find" 2>nul
    )
    echo %time% Merge path.
    set PATHTMP=path%random%.tmp
    del /f %PATHTMP% 2>nul
    for %%F in (%Pre%*.txt) do type "%%F" >> %PATHTMP%
    move /y %PATHTMP% path
    for %%P in (path) do echo %time% path: %%~zP bytes.
  popd
exit /b 0

:sub_get_tsymd
  rem {filename}
  set FileTs=%~t1
  set tsymd=%FileTs:/=%
  set tsymd=%tsymd:~0,8%
exit /b 0

:sub_restart
  if "%EnableRestartFenrir%"=="yes" (
    echo %time% fenrir restart.
    start %FenrirDir%\fenrir.exe
  )
exit /b 0

:sub_pause
  if "%EnablePause%"=="yes" (
    echo [Hit any key to exit]
    pause >nul
    rem ping localhost -n 16 >nul
  )
exit /b 0

:sub_backup
  rem {work-dir} {target-file} [number-of-expire]
  set Rar=C:\Program Files\WinRAR\rar.exe
  if NOT exist "%Rar%" exit /b 1
  if NOT exist "%1" exit /b 1
  if "%2"=="" exit /b 1
  pushd "%1"
    set Target=%2
    set NExpire=8
    if NOT "%3"=="" set NExpire=%3
    set NowDate=%date:/=-%-%time::=-%
    set NowDate=%NowDate:~0,16%
    set NowDate=%NowDate: =0%
    echo %time% Backup %Target% to %Target%-%NowDate%.rar
    set TmpRar=%Target%-%Random%.tmp
    "%Rar%" a -u -as -dh -inul -m1 -os -ow -o+ -r -s- -y %TmpRar% %Target%
    move /y %TmpRar% %Target%-%NowDate%.rar
    for /f "skip=%NExpire%" %%F in ('dir /b /o-n %Target%-*') do del /f %%F
  popd
exit /b 0
