@ECHO OFF
:: Description: Video to AVIF converter
:: By: Pathduck
:: Version: 1.0
:: Url: https://github.com/Pathduck/vid2avif/
:: License: GNU General Public License v3.0 (GPLv3)

:: Enable delayed variable expension
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define ANSI Colors
SET "OFF=[0m"
SET "RED=[91m"
SET "GREEN=[32m"
SET "YELLOW=[33m"
SET "BLUE=[94m"
SET "CYAN=[96m"

:: Check for blank input or help commands
IF "%~1"=="" GOTO :help_message
IF "%~1"=="-?" GOTO :help_message
IF "%~1"=="/?" GOTO :help_message
IF "%~1"=="--help" GOTO :help_message

:: Check if FFmpeg exists on PATH, if not exit
WHERE /q ffmpeg.exe || ( ECHO %RED%FFmpeg not found in PATH, please install it first%OFF% & GOTO :EOF )

:: Assign input and output
SET "input=%~1"
SET "output=%~n1"

:: Validate input file
IF NOT EXIST "%input%" (
	ECHO %RED%Input file not found: !input! %OFF%
	GOTO :EOF
)

:: Clearing input vars and setting defaults
SET "fps=15"
SET "scale=-1"
SET "filetype=avif"
SET "loglevel=error"
SET "start_time="
SET "end_time="
SET "crop="
SET "picswitch="
SET "playswitch="

:varin
:: Parse Arguments, first shift input one left
SHIFT
:parse_loop
IF NOT "%~1"=="" (
	IF "%~1"=="-o" SET "output=%~dpn2" & SHIFT
	IF "%~1"=="-r" SET "scale=%~2" & SHIFT
	IF "%~1"=="-f" SET "fps=%~2" & SHIFT
	IF "%~1"=="-s" SET "start_time=%~2" & SHIFT
	IF "%~1"=="-e" SET "end_time=%~2" & SHIFT
	IF "%~1"=="-v" SET "loglevel=%~2" & SHIFT
	IF "%~1"=="-x" SET "crop=%~2" & SHIFT
	IF "%~1"=="-p" SET "picswitch=1"
	IF "%~1"=="-y" SET "playswitch=1"
	SHIFT & GOTO :parse_loop
)

:safchek
:: Validate if output file is set
FOR %%f IN ("%output%") DO SET "out_base=%%~nf"
IF "%output%"=="" ( ECHO %RED%Missing value for -o%OFF% & GOTO :EOF )
IF DEFINED out_base (
	IF "!out_base:~0,1!"=="-" ( ECHO %RED%Missing value for -o%OFF% & GOTO :EOF )
)

:: Validate if output is a directory; strip trailing slash and use input filename
IF EXIST "%output%\*" (
	IF "%output:~-1%"=="\" SET "output=%output:~0,-1%"
	FOR %%f IN ("!input!") DO SET "filename=%%~nf"
	SET "output=!output!\!filename!"
)

:: Set output file extension
SET "output=%output%.%filetype%"

:: Validate Clipping
IF DEFINED start_time (
	IF DEFINED end_time SET "trim=-ss !start_time! -to !end_time!"
	IF NOT DEFINED end_time (
		ECHO %RED%End time ^(-e^) is required when Start time ^(-s^) is specified.%OFF%
		GOTO :EOF
	)
)
IF DEFINED end_time (
	IF NOT DEFINED start_time (
		ECHO %RED%Start time ^(-s^) is required when End time ^(-e^) is specified.%OFF%
		GOTO :EOF
	)
)

:: Validate Framerate
IF DEFINED fps (
	IF !fps! LSS 0 (
		ECHO  %RED%Framerate ^(-f^) must be greater than 0.%OFF%
		GOTO :EOF
	)
)

:script_start
:: Putting together filters
SET "filters=fps=%fps%"
IF DEFINED crop ( SET "filters=%filters%,crop=%crop%" )
SET "filters=%filters%,scale=%scale%:-1:flags=lanczos+accurate_rnd+full_chroma_int"

:: FFplay preview
IF DEFINED playswitch (
:: Check if ffplay exists on PATH, if not exit
	WHERE /q ffplay.exe || ( ECHO %RED%FFplay not found in PATH, please install it first%OFF% & GOTO :EOF )

	FOR /F "delims=" %%a in ('ffplay -version') DO (
		IF NOT DEFINED ffplay_version ( SET "ffplay_version=%%a" 
		 ) ELSE IF NOT DEFINED ffplay_build ( SET "ffplay_build=%%a" )
	)
	ECHO %YELLOW%!ffplay_version!%OFF%
	ECHO %YELLOW%!ffplay_build!%OFF%

	IF NOT DEFINED start_time SET "start_time=0"
	IF NOT DEFINED end_time SET "end_time=3"
	ffplay -v %loglevel% -i "%input%" -vf "%filters%" -an -loop 0 -ss !start_time! -t !end_time!
	GOTO :EOF
)

:: Storing FFmpeg version string
FOR /F "delims=" %%a in ('ffmpeg -version') DO (
	IF NOT DEFINED ffmpeg_version ( SET "ffmpeg_version=%%a"
	) ELSE IF NOT DEFINED ffmpeg_build ( SET "ffmpeg_build=%%a" )
)

:: Displaying FFmpeg version string and output file
ECHO %YELLOW%!ffmpeg_version!%OFF%
ECHO %YELLOW%!ffmpeg_build!%OFF%
ECHO %GREEN%Output file:%OFF% !output!

:: Setting variables to put the encode command together
SET "type_opts=-crf 30 -cpu-used 4 -row-mt 1 -tiles 2x2 -pix_fmt yuv420p"

:: Executing the encoding command
ECHO %GREEN%Encoding animation...%OFF%
ffmpeg -v %loglevel% %trim% -i "%input%" ^
-vf "%filters%" -an ^
-f %filetype% %type_opts% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
IF NOT EXIST "%output%" (
	ECHO ECHO %RED%Failed to generate animation: !output! not found.%OFF%
	GOTO :cleanup
)

:: Open output file if picswitch is set
IF DEFINED picswitch START "" "%output%"

:cleanup
:: Cleaning up
ECHO %GREEN%Done.%OFF%
ENDLOCAL
GOTO :EOF

:help_message
:: Print usage message
ECHO %GREEN%Video to AVIF converter v1.0%OFF%
ECHO %BLUE%By Pathduck%OFF%
ECHO:
ECHO %GREEN%Usage:%OFF%
ECHO %~n0 [input_file] [arguments]
ECHO:
ECHO %GREEN%Arguments:%OFF%
ECHO  -o  Output file. Default is the same as input file, sans extension
ECHO  -r  Resize output width in pixels. Default is original input size
ECHO  -f  Framerate in frames per seconds (default 15)
ECHO  -s  Start time of the animation (HH:MM:SS.MS)
ECHO  -e  End time of the animation (HH:MM:SS.MS)
ECHO  -x  Crop the input video (out_w:out_h:x:y)
ECHO  -y  Preview animation using FFplay (part of FFmpeg)
ECHO      Useful for testing cropping, but will not use exact start/end time
ECHO  -p  Opens the resulting animation in the default image viewer
ECHO  -v  Set FFmpeg log level (default: error)
ECHO:
GOTO :EOF
