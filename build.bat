@echo off

set config=%1

set flags=-out:build/game.exe -collection:src=src -strict-style

if /i "%config%" == "" set config=debug

if /i "%config%" == "debug"   goto config_debug
if /i "%config%" == "release" goto config_release
goto end_config

:config_debug
echo --- Config: DEBUG
set flags=%flags% -o:none -debug -subsystem:console
goto end_config

:config_release
echo --- Config: RELEASE
set flags=%flags% -o:aggressive -subsystem:windows -vet -define:RELEASE_BUILD=true
rem TODO: Resource file
goto end_config

:end_config

echo --- Running pre-build scripts
script\asset_desc_gen.exe
move /y generated_asset_desc.odin src\asset\


if exist build (
	rmdir /s /q build
)

mkdir build
mkdir build\data

echo --- Building executable
odin build src %flags%

xcopy /s /q /y data build\data
