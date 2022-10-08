setlocal

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

REM cd pupnp && mkdir build && cd build
REM cmake .. -A Win32 -DDOWNLOAD_AND_BUILD_DEPS=1
REM cd ..

ren pupnp\upnp\inc\upnpconfig.h *.bak
msbuild libpupnp.sln /property:Configuration=Debug %1
msbuild libpupnp.sln /property:Configuration=Release %1
ren pupnp\upnp\inc\upnpconfig.bak *.h

set target=targets\win32\x86

if exist %target% (
	del %target%\*.lib
)

robocopy pupnp\build\upnp\Release %target% libupnps.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\ixml\Release %target% ixmls.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\upnp\Debug %target% libupnpsd.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\ixml\Debug %target% ixmlsd.* /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\upnp\inc %target%\include\upnp *.h /NDL /NJH /NJS /nc /ns /np
robocopy pupnp\build\upnp\inc %target%\include\upnp *.h /NDL /NJH /NJS /nc /ns /np /IS
robocopy pupnp\ixml\inc %target%\include\ixml *.h /NDL /NJH /NJS /nc /ns /np

lib.exe /OUT:%target%/libpupnp.lib %target%/libupnps.lib %target%/ixmls.lib
lib.exe /OUT:%target%/libpupnpd.lib %target%/libupnpsd.lib %target%/ixmlsd.lib

endlocal

