setlocal

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

if /I [%1] == [rebuild] (
	rd /q /s pupnp\build
)

if not exist pupnp\build (
	mkdir pupnp\build
	cd pupnp\build
	cmake .. -A Win32 -DDOWNLOAD_AND_BUILD_DEPS=1
	cd ..\..
)	

if /I [%1] == [rebuild] (
	set option=":Rebuild"
)

set target=targets\win32\x86

msbuild libpupnp.sln /property:Configuration=Debug -t:_last%option%
msbuild libpupnp.sln /property:Configuration=Release -t:_last%option%
	
if exist %target% (
	del %target%\*.lib
)

robocopy pupnp\build\upnp\Release %target% libupnps.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\ixml\Release %target% ixmls.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\upnp\Debug %target% libupnpsd.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\ixml\Debug %target% ixmlsd.* /NDL /NJH /NJS /nc /ns /np
robocopy addons\build %target% *.lib /NDL /NJH /NJS /nc /ns /np

robocopy pupnp\upnp\inc %target%\include\upnp *.h /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\upnp\inc %target%\include\upnp *.h /NDL /NJH /NJS /nc /ns /np /IS
robocopy pupnp\ixml\inc %target%\include\ixml *.h /NDL /NJH /NJS /nc /ns /np
robocopy addons targets\include\addons ixmlextra.h /NDL /NJH /NJS /nc /ns /np

lib.exe /OUT:%target%/libpupnp.lib %target%/libupnps.lib %target%/ixmls.lib %target%/libaddons.lib
lib.exe /OUT:%target%/libpupnpd.lib %target%/libupnpsd.lib %target%/ixmlsd.lib %target%/libaddons.lib

endlocal

