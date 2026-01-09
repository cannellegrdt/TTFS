@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: lankley, 01-09-2026
:: TreeToFS, Windows version
:: ============================================================================

if "%~1"=="" (
    echo Usage: %~nx0 ^<file^> [destination_path]
    exit /b 1
)

set "INPUT_FILE=%~1"
set "DEST=%~2"
if "%DEST%"=="" set "DEST=."

if not exist "%DEST%" mkdir "%DEST%"

chcp 65001 >nul

set "INDENT_SIZE=0"

for /f "usebackq delims=" %%L in ("%INPUT_FILE%") do (
    set "line=%%L"
    
    echo !line! | findstr /R /C:"^[[:space:]]*$" >nul && goto :next_line
    echo !line! | findstr /C:"directories" /C:"files" >nul && goto :next_line

    :: 1. Determine depth by counting leading tree/space characters
    set "prefix_part="
    set "temp_line=!line!"
    set "prefix_len=0"
    
    call :get_prefix_len "!temp_line!" prefix_len
    
    if !INDENT_SIZE! equ 0 if !prefix_len! gtr 0 (
        set "INDENT_SIZE=!prefix_len!"
    )

    if !INDENT_SIZE! gtr 0 (
        set /a "DEPTH=!prefix_len! / !INDENT_SIZE!"
    ) else (
        set "DEPTH=0"
    )

    :: 2. Extract and clean Name
    set "raw_name=!line:~%prefix_len%!"
    
    for /f "tokens=1" %%N in ("!raw_name!") do set "clean_name=%%N"
    set "clean_name=!clean_name:/=!"
    set "clean_name=!clean_name:*=!"
    set "clean_name=!clean_name:@=!"

    set "is_dir=false"
    echo !raw_name! | findstr /C:"/" >nul && set "is_dir=true"

    :: 3. Update iherarchy array
    set "path_!DEPTH!=!clean_name!"

    :: 4. Build full path
    set "full_path=%DEST%"
    for /L %%i in (0,1,!DEPTH!) do (
        set "full_path=!full_path!\!path_%%i!"
    )

    :: 5. Creation logic
    if "!is_dir!"=="true" (
        if not exist "!full_path!" mkdir "!full_path!"
    ) else (
        for %%F in ("!full_path!") do if not exist "%%~dpF" mkdir "%%~dpF"
        if not exist "!full_path!" type nul > "!full_path!"
    )

    :next_line
    rem
)

echo.
echo File system structure created successfully in: %DEST%
goto :eof

:get_prefix_len
set "str=%~1"
set "count=0"
:loop
set "char=!str:~%count%,1!"
if "%char%"==" " (set /a count+=1 & goto loop)
if "%char%"=="│" (set /a count+=1 & goto loop)
if "%char%"=="├" (set /a count+=1 & goto loop)
if "%char%"=="└" (set /a count+=1 & goto loop)
if "%char%"=="─" (set /a count+=1 & goto loop)
set "%~2=%count%"
goto :eof
