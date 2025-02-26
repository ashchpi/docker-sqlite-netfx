@ECHO OFF

::
:: test_net_6.bat --
::
:: .NET 6 Multiplexing Wrapper Tool for Unit Tests
::
:: Written by Joe Mistachkin.
:: Released to the public domain, use at your own risk!
::

SETLOCAL

REM SET __ECHO=ECHO
REM SET __ECHO2=ECHO
REM SET __ECHO3=ECHO
IF NOT DEFINED _AECHO (SET _AECHO=REM)
IF NOT DEFINED _CECHO (SET _CECHO=REM)
IF NOT DEFINED _CECHO2 (SET _CECHO2=REM)
IF NOT DEFINED _CECHO3 (SET _CECHO3=REM)
IF NOT DEFINED _VECHO (SET _VECHO=REM)

%_AECHO% Running %0 %*

SET DUMMY2=%1

IF DEFINED DUMMY2 (
  GOTO usage
)

REM SET DFLAGS=/L

%_VECHO% DFlags = '%DFLAGS%'

SET FFLAGS=/V /F /G /H /I /R /Y /Z

%_VECHO% FFlags = '%FFLAGS%'

SET ROOT=%~dp0\..
SET ROOT=%ROOT:\\=\%

%_VECHO% Root = '%ROOT%'

SET TOOLS=%~dp0
SET TOOLS=%TOOLS:~0,-1%

%_VECHO% Tools = '%TOOLS%'

CALL :fn_ResetErrorLevel

SET NONETSTANDARD20=1

%_CECHO3% CALL "%TOOLS%\set_common.bat"
%__ECHO3% CALL "%TOOLS%\set_common.bat"

IF ERRORLEVEL 1 (
  ECHO Could not set common variables.
  GOTO errors
)

IF NOT DEFINED DOTNET (
  SET DOTNET=dotnet.exe
)

%_VECHO% DotNet = '%DOTNET%'

IF NOT DEFINED SUBCOMMANDS (
  SET SUBCOMMANDS=exec
)

%_VECHO% SubCommands = '%SUBCOMMANDS%'

IF NOT DEFINED TEST_NATIVE_CONFIGURATIONS (
  SET TEST_NATIVE_CONFIGURATIONS=ReleaseNativeOnly
)

%_VECHO% TestNativeConfigurations = '%TEST_NATIVE_CONFIGURATIONS%'

IF DEFINED PLATFORM (
  %_AECHO% Skipping platform detection, already set...
  GOTO skip_detectPlatform
)

IF /I "%PROCESSOR_ARCHITECTURE%" == "x86" (
  SET PLATFORM=Win32
)

IF /I "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  SET PLATFORM=x64
)

:skip_detectPlatform

IF NOT DEFINED PLATFORM (
  ECHO Unsupported platform.
  GOTO errors
)

%_VECHO% Platform = '%PLATFORM%'

IF NOT DEFINED YEARS (
  SET YEARS=NetStandard21
)

%_VECHO% Years = '%YEARS%'

IF NOT DEFINED NATIVE_YEARS (
  SET NATIVE_YEARS=2019 2017 2015
)

%_VECHO% NativeYears = '%NATIVE_YEARS%'

IF NOT DEFINED TEST_FILE (
  SET TEST_FILE=Tests\all.eagle
)

%_VECHO% TestFile = '%TEST_FILE%'
%_VECHO% PreArgs = '%PREARGS%'
%_VECHO% MidArgs = '%MIDARGS%'
%_VECHO% PostArgs = '%POSTARGS%'

IF NOT DEFINED EAGLESHELL (
  SET EAGLESHELL=EagleShell.dll
)

%_VECHO% EagleShell = '%EAGLESHELL%'

CALL :fn_VerifyDotNetCore
IF ERRORLEVEL 1 GOTO errors

%_CECHO2% PUSHD "%ROOT%"
%__ECHO2% PUSHD "%ROOT%"

IF ERRORLEVEL 1 (
  ECHO Could not change directory to "%ROOT%".
  GOTO errors
)

REM ****************************************************************************
REM *********************** Disable Microsoft Telemetry ************************
REM ****************************************************************************

SET VSCMD_SKIP_SENDTELEMETRY=1
SET VCPKG_KEEP_ENV_VARS=VSCMD_SKIP_SENDTELEMETRY
SET DOTNET_CLI_TELEMETRY_OPTOUT=1

REM ****************************************************************************
REM **************************** Run the Test Suite ****************************
REM ****************************************************************************

SET TEST_ALL=1

FOR %%C IN (%TEST_NATIVE_CONFIGURATIONS%) DO (
  FOR %%Y IN (%YEARS%) DO (
    FOR %%N IN (%NATIVE_YEARS%) DO (
      CALL :fn_RunDotNetCoreTestSuite %%C %%Y %%N
      IF ERRORLEVEL 1 GOTO errors
    )
  )
)

%_CECHO2% POPD
%__ECHO2% POPD

IF ERRORLEVEL 1 (
  ECHO Could not restore directory.
  GOTO errors
)

GOTO no_errors

:fn_VerifyDotNetCore
  FOR %%T IN (%DOTNET%) DO (
    SET %%T_PATH=%%~dp$PATH:T
  )
  IF NOT DEFINED %DOTNET%_PATH (
    ECHO The .NET Core executable "%DOTNET%" is required to be in the PATH.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  GOTO :EOF

:fn_RunDotNetCoreTestSuite
  SET NATIVE_CONFIGURATION=%1
  IF NOT DEFINED NATIVE_CONFIGURATION (
    ECHO Cannot run .NET Core test suite, missing native configuration.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  SET YEAR=%2
  IF NOT DEFINED YEAR (
    ECHO Cannot run .NET Core test suite, missing year.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  SET NATIVE_YEAR=%3
  IF NOT DEFINED NATIVE_YEAR (
    ECHO Cannot run .NET Core test suite, missing native year.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  SET CONFIGURATION=%NATIVE_CONFIGURATION%
  SET CONFIGURATION=%CONFIGURATION:NativeOnly=%
  IF EXIST "bin\%YEAR%\%CONFIGURATION%NetStandard21\bin" (
    IF EXIST "bin\%NATIVE_YEAR%\%PLATFORM%\%NATIVE_CONFIGURATION%" (
      %_CECHO% "%DOTNET%" %SUBCOMMANDS% "Externals\Eagle\bin\net6\%EAGLESHELL%" %PREARGS% -anyInitialize "set test_year {%YEAR%}; set test_native_year {%NATIVE_YEAR%}; set test_configuration {%CONFIGURATION%}; set test_configuration_suffix NetStandard21; set test_extra netstandard2.1" -initialize -postInitialize "unset -nocomplain no(deleteSqliteImplicitNativeFiles)" %MIDARGS% -file "%TEST_FILE%" %POSTARGS%
      %__ECHO% "%DOTNET%" %SUBCOMMANDS% "Externals\Eagle\bin\net6\%EAGLESHELL%" %PREARGS% -anyInitialize "set test_year {%YEAR%}; set test_native_year {%NATIVE_YEAR%}; set test_configuration {%CONFIGURATION%}; set test_configuration_suffix NetStandard21; set test_extra netstandard2.1" -initialize -postInitialize "unset -nocomplain no(deleteSqliteImplicitNativeFiles)" %MIDARGS% -file "%TEST_FILE%" %POSTARGS%
      CALL :fn_FixErrorLevel
      IF ERRORLEVEL 1 (
        ECHO Testing of "%YEAR%/%NATIVE_YEAR%/%CONFIGURATION%" .NET Standard 2.1 assembly via .NET 6 failed.
        CALL :fn_SetErrorLevel
        GOTO :EOF
      )
    ) ELSE (
      %_AECHO% Native directory "bin\%NATIVE_YEAR%\%PLATFORM%\%NATIVE_CONFIGURATION%" not found, skipped.
    )
  ) ELSE (
    %_AECHO% Managed directory "bin\%YEAR%\%CONFIGURATION%NetStandard21\bin" not found, skipped.
  )
  GOTO :EOF

:fn_SetVariable
  SETLOCAL
  SET __ECHO_CMD=ECHO %%%2%%
  FOR /F "delims=" %%V IN ('%__ECHO_CMD%') DO (
    SET VALUE=%%V
  )
  ENDLOCAL && (
    SET %1=%VALUE%
  )
  GOTO :EOF

:fn_ResetErrorLevel
  VERIFY > NUL
  GOTO :EOF

:fn_SetErrorLevel
  VERIFY MAYBE 2> NUL
  GOTO :EOF

:fn_FixErrorLevel
  IF %ERRORLEVEL% NEQ 0 (
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  GOTO :EOF

:usage
  ECHO.
  ECHO Usage: %~nx0
  GOTO errors

:errors
  CALL :fn_SetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Test failure, errors were encountered.
  GOTO end_of_file

:no_errors
  CALL :fn_ResetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Test success, no errors were encountered.
  GOTO end_of_file

:end_of_file
%__ECHO% EXIT /B %ERRORLEVEL%
