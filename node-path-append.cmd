@ECHO OFF
SETLOCAL
REM %1: Registry Key to Environment to modify

ECHO.Modifying Registry key %~1
REG QUERY "%~1" /v Path 1> NUL 2> NUL || (
    ECHO.Creating missing registry key %~1 and setting Path value to empty
    REG ADD "%~1" /v Path /t REG_EXPAND_SZ /d "" 1> NUL
) || GOTO ERRORMESSAGE

SET NODE_PATH_APPEND=;%%APPDATA%%\npm;%%LOCALAPPDATA%%\Yarn\bin;C:\Tools\node-v%NODEVERSION%-x64
FOR /F "tokens=1,2,* delims= " %%X IN ('REG QUERY "%~1" /v Path') DO (
    IF /I "%%~X"=="Path" (
        ECHO.Appending "%NODE_PATH_APPEND%" to Path value "%%~Z"
        REG ADD "%~1" /v "%%~X" /t REG_EXPAND_SZ /d "%%~Z%NODE_PATH_APPEND%" /f || GOTO ERRORMESSAGE
    )
)

:ERRORMESSAGE
ECHO.Unable to modify registry key
