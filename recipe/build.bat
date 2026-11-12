@echo off
setlocal EnableDelayedExpansion

:: Bootstrap lein comes from the leiningen build requirement in BUILD_PREFIX
set "_boot-prefix=%BUILD_PREFIX%"
:: This is used when the previous conda verison cannot build from source
:: Download the upstream distribution in meta.yaml
:: call :install_leiningen "%SRC_DIR%\leiningen-jar" "%_boot-prefix%"
set "PATH=%_boot-prefix%\Scripts;%PATH%"
call :bootstrap_leiningen %_boot-prefix%
if errorlevel 1 exit 1

call :build_uberjar
if errorlevel 1 exit 1

call :install_leiningen "%SRC_DIR%\leiningen-src\target" "%PREFIX%"
if errorlevel 1 exit 1
call :install_conda_scripts "%PREFIX%"
if errorlevel 1 exit 1

goto :EOF

:: --- Functions ---
:bootstrap_leiningen
set "_prefix=%~1"
cd "%SRC_DIR%"\leiningen-src\leiningen-core
  echo "Patching SNAPSHOT version to %PKG_VERSION% ..."
  powershell -Command "(Get-Content pom.xml) -replace '[0-9.]+-SNAPSHOT', '%PKG_VERSION%' | Set-Content pom.xml"
  powershell -Command "(Get-Content project.clj) -replace '[0-9.]+-SNAPSHOT', '%PKG_VERSION%' | Set-Content project.clj"
  findstr SNAPSHOT pom.xml project.clj >nul 2>&1 && (echo ERROR: SNAPSHOT remains in leiningen-core & exit 1)
  echo "Bootstrapping ..."
  :: Bootstrap jar version is whatever the build requirement resolved to
  for %%j in ("%_prefix%\lib\leiningen\libexec\leiningen-*-standalone.jar") do set "LEIN_JAR=%%~fj"
  if not defined LEIN_JAR (echo ERROR: bootstrap leiningen jar not found in %_prefix% & exit 1)
  call lein bootstrap
  if errorlevel 1 exit 1
  echo "Third party licenses ..."
  call mvn license:add-third-party -Dlicense.thirdPartyFile=THIRD-PARTY.txt > nul
  if errorlevel 1 exit 1
cd %SRC_DIR%
goto :EOF

:build_uberjar
cd "%SRC_DIR%"\leiningen-src
  powershell -Command "(Get-Content bin\lein.bat) -replace '[0-9.]+-SNAPSHOT', '%PKG_VERSION%' | Set-Content bin\lein.bat"
  powershell -Command "(Get-Content project.clj) -replace '[0-9.]+-SNAPSHOT', '%PKG_VERSION%' | Set-Content project.clj"
  findstr SNAPSHOT bin\lein.bat project.clj >nul 2>&1
  echo "Uberjar ..."
  call bin\lein uberjar
  if errorlevel 1 exit 1
  cd %SRC_DIR%
goto :EOF

:install_leiningen
setlocal EnableDelayedExpansion
set "_target=%~1"
set "_prefix=%~2"

if not exist %_prefix%\Scripts mkdir %_prefix%\Scripts
if not exist %_prefix%\lib mkdir %_prefix%\lib
if not exist %_prefix%\lib\leiningen mkdir %_prefix%\lib\leiningen
if not exist %_prefix%\lib\leiningen\libexec mkdir %_prefix%\lib\leiningen\libexec

copy %_target%\leiningen-%PKG_VERSION%-standalone.jar %_prefix%\lib\leiningen\libexec > nul
if errorlevel 1 exit 1
dir %_prefix%\lib\leiningen\libexec\leiningen-%PKG_VERSION%-standalone.jar
if errorlevel 1 exit 1
copy %RECIPE_DIR%\scripts\lein.bat %_prefix%\Scripts\lein.bat > nul
if errorlevel 1 exit 1
dir %_prefix%\Scripts\lein.bat
if errorlevel 1 exit 1

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
if errorlevel 1 exit 1
endlocal
goto :EOF

:install_conda_scripts
setlocal
set "_prefix=%~1"
mkdir %_prefix%\etc\conda\activate.d
copy %RECIPE_DIR%\scripts\activate.bat %_prefix%\etc\conda\activate.d\lein-activate.bat > nul
if errorlevel 1 exit 1
endlocal
goto :EOF

