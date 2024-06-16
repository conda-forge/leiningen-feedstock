@echo off
setlocal EnableDelayedExpansion

:: call mamba install -y leiningen
set "_boot-prefix=%SRC_DIR%\_conda-bootstrap"
call :install_leiningen "%SRC_DIR%\leiningen-jar" "%_boot-prefix%"
set "PATH=%_boot-prefix%\Scripts;%PATH%"
call :bootstrap_leiningen %_boot-prefix%
call :prepare_licenses

call :build_uberjar

call :install_leiningen "%SRC_DIR%\leiningen-src\target" "%PREFIX%"
call :install_conda_scripts "%PREFIX%"

goto :EOF

:: --- Functions ---
:bootstrap_leiningen
set "_prefix=%~1"
cd "%SRC_DIR%"\leiningen-src\leiningen-core
  echo "Bootstrapping ..."
  set "LEIN_JAR=%_prefix%\lib\leiningen\libexec\leiningen-%PKG_VERSION%-standalone.jar"
  call lein bootstrap > nul
  if errorlevel 1 exit 1
  echo "Third party licenses ..."
  call mvn license:add-third-party -Dlicense.thirdPartyFile=THIRD-PARTY.txt > nul
  if errorlevel 1 exit 1
cd %SRC_DIR%
goto :EOF

:build_uberjar
cd "%SRC_DIR%"\leiningen-src
  echo "Uberjar ..."
  call bin\lein uberjar > nul
  if errorlevel 1 exit 1
  cd %SRC_DIR%
goto :EOF

:install_leiningen
setlocal EnableDelayedExpansion
set "_target=%~1"
set "_prefix=%~2"

mkdir %_prefix%\Scripts
mkdir %_prefix%\lib
mkdir %_prefix%\lib\leiningen
mkdir %_prefix%\lib\leiningen\libexec

copy %_target%\leiningen-%PKG_VERSION%-standalone.jar %_prefix%\lib\leiningen\libexec > nul
dir %_prefix%\lib\leiningen\libexec\leiningen-%PKG_VERSION%-standalone.jar
copy %RECIPE_DIR%\scripts\lein.bat %_prefix%\Scripts\lein.bat > nul
dir %_prefix%\Scripts\lein.bat

set "lein_file=%_prefix%\Scripts\lein.bat"
set "temp_file=%TEMP%\lein.bat"
for /f "delims=" %%i in (%lein_file%) do (
    set "line=%%i"
    if "!line:~0,13!"=="set LEIN_VERSION" (
        echo set LEIN_VERSION=%PKG_VERSION%>> "%temp_file%"
    ) else (
        echo %%i>> "%temp_file%"
    )
)
move /Y "%temp_file%" "%lein_file%"
endlocal
goto :EOF

:install_conda_scripts
setlocal
set "_prefix=%~1"
mkdir %_prefix%\etc\conda\activate.d
copy %RECIPE_DIR%\scripts\activate.bat %_prefix%\etc\conda\activate.d\lein-activate.bat > nul
if errorlevel 1 exit 1
goto :EOF

:prepare_licenses
copy %SRC_DIR%\leiningen-src\COPYING %RECIPE_DIR%\COPYING > nul
copy %SRC_DIR%\leiningen-src\leiningen-core\target\generated-sources\license\THIRD-PARTY.txt %RECIPE_DIR%\THIRD-PARTY.txt > nul
goto :EOF