ifeq ($(CC),cc)
CC=$(lastword $(subst /, ,$(shell readlink -f `which cc`)))
endif

ifeq ($(findstring gcc,$(CC)),gcc)
CFLAGS  += -Wno-stringop-truncation -Wno-stringop-overflow -Wno-format-truncation
endif

PLATFORM ?= $(firstword $(subst -, ,$(CC)))
HOST ?= $(word 2, $(subst -, ,$(CC)))

LIB = build/libaddons.a

DEFINES  = -DNDEBUG -D_GNU_SOURCE -DUPNP_STATIC_LIB
CFLAGS  += -Wall -Wno-multichar -fPIC -ggdb -O2 $(DEFINES) -fdata-sections -ffunction-sections 

PUPNP		= ../targets

#vpath %.c $(TOOLS):$(SRC)
#vpath %.cpp $(TOOLS):$(SRC)

INCLUDE = -I$(PUPNP)/$(HOST)/$(PLATFORM)/include/ixml \
	  -I$(PUPNP)/$(HOST)/$(PLATFORM)/include/upnp
		  
SOURCES = ixmlextra.c

OBJECTS = $(patsubst %.c,build/%.o,$(filter %.c,$(SOURCES)))
OBJECTS += $(patsubst %.cpp,build/%.o,$(filter %.cpp,$(SOURCES)))

all: directory $(OBJECTS) $(LIB)
directory:
	@mkdir -p build
	
$(LIB): $(OBJECTS)
	$(AR) rcs $@ $^

build/%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< -c -o $@
	
build/%.o : %.cpp
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< -c -o $@

clean: 
	rm -f $(OBJECTS) $(LIB)

