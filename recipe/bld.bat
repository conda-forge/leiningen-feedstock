@echo off
setlocal EnableDelayedExpansion

:: call mamba install -y leiningen
call :install_leiningen "%SRC_DIR%\leiningen-jar" "%BUILD_PREFIX%"
if errorlevel 1 exit 1
set "PATH=%BUILD_PREFIX%\Scripts;%BUILD_PREFIX%\bin;%PATH%"
call :bootstrap_leiningen
call :prepare_licenses

call :build_uberjar

call :install_leiningen "%SRC_DIR%\leiningen-src\target" "%PREFIX%"
call :install_conda_scripts

goto :EOF

:: --- Functions ---
:bootstrap_leiningen
cd "%SRC_DIR%"\leiningen-src
  echo "Bootstrapping ..."
  set "LEIN_JAR=%BUILD_PREFIX%\lib\leiningen\libexec\leiningen-%PKG_VERSION%-standalone.jar"
  %RECIPE_DIR%\scripts\lein bootstrap > nul
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
set "_TARGET=%~1"
set "_PREFIX=%~2"

mkdir %_PREFIX%\lib
mkdir %_PREFIX%\Scripts

set "LIBEXEC_DIR=%_PREFIX%\lib\leiningen\libexec"
mkdir %LIBEXEC_DIR%

copy %RECIPE_DIR%\scripts\lein.bat %PREFIX%\Scripts\lein.bat > nul
if errorlevel 1 exit 1

set "lein_file=%_PREFIX%\Scripts\lein.bat"
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

install -m644 %_TARGET%\leiningen-%PKG_VERSION%-standalone.jar %LIBEXEC_DIR%
goto :EOF

:install_conda_scripts
mkdir %PREFIX%\etc\conda\activate.d
copy %RECIPE_DIR%\scripts\activate.bat %ACTIVATE_DIR%\lein-activate.bat > nul
if errorlevel 1 exit 1
goto :EOF

:prepare_licenses
copy %SRC_DIR%\leiningen-src\COPYING %RECIPE_DIR%\COPYING > nul
copy %SRC_DIR%\leiningen-src\leiningen-core\target\generated-sources\license\THIRD-PARTY.txt %RECIPE_DIR%\THIRD-PARTY.txt > nul
goto :EOF