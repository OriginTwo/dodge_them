@echo off

rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rem                     Build Options
rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set config=release

set out_name=game.exe

set cflags=/std:c11 /nologo /W3 /wd4244 /D_CRT_SECURE_NO_WARNINGS /I..\lib
set lflags=/entry:mainCRTStartup /incremental:no /nodefaultlib:LIBCMT
set libs=..\lib\glfw\glfw3_%config%.lib opengl32.lib gdi32.lib user32.lib shell32.lib msvcrt.lib

if %config% == debug (
	set cflags=%cflags% /Zi /Od /DBUILD_DEBUG /DDEBUG_PRINT_FPS
	set lflags=%lflags% /nodefaultlib:LIBCMTD
)
if %config% == release (

	set cflags=%cflags% /O2 /DBUILD_RELEASE
	set lflags=%lflags% /subsystem:windows
)

echo --- Build configuration: '%config%'


rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rem                 Creating Directories
rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if not exist build (
	mkdir build
	mkdir build\res
) else (
	rmdir build /s /q
	mkdir build
	mkdir build\res
)


rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rem                   Build Executable
rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pushd build
cl %cflags% /TC ..\src\main.c /link %lflags% %libs% /out:%out_name%
popd


rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rem                      Copy Files
rem ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

xcopy res build\res /s /q