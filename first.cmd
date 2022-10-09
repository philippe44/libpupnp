@echo set cmake mode
if exist pupnp\upnp\inc\upnpconfig.h (
	ren pupnp\upnp\inc\upnpconfig.h upnpconfig.h.autotools
)	
