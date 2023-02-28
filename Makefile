CFLAGS  := -Wall -O2 -D_REENTRANT
LIBS    := -lpthread -lm
GIT     := git
TARGET  := $(shell uname -s | tr '[A-Z]' '[a-z]' 2>/dev/null || echo unknown)

ifeq ($(TARGET), sunos)
	CFLAGS += -D_PTHREADS -D_POSIX_C_SOURCE=200112L
	LIBS   += -lsocket
else ifeq ($(TARGET), darwin)
	# Per https://luajit.org/install.html: If MACOSX_DEPLOYMENT_TARGET
	# is not set then it's forced to 10.4, which breaks compile on Mojave.
	MACOSX_DEPLOYMENT_TARGET ?= $(shell sw_vers -productVersion)
	export MACOSX_DEPLOYMENT_TARGET

	CFLAGS += -I/usr/local/include

	# Per macOS, the below options are deprecated and going to be removed.
        # They cause host/minilua build process to fail, so please remove.
	# LDFLAGS += -pagezero_size 10000 -image_base 100000000

else ifeq ($(TARGET), linux)
        CFLAGS  += -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE
	LIBS    += -ldl
	LDFLAGS += -Wl,-E
else ifeq ($(TARGET), freebsd)
	CFLAGS  += -D_DECLARE_C99_LDBL_MATH
	LDFLAGS += -Wl,-E
endif

SRC  := wrk.c \
	net.c \
	ssl.c \
	aprintf.c \
	stats.c \
	script.c \
	units.c \
	ae.c \
	zmalloc.c \
	http_parser.c \
	tinymt64.c \
	hdr_histogram.c
BIN  := wrk2

ODIR := obj
OBJ  := $(patsubst %.c,$(ODIR)/%.o,$(SRC)) $(ODIR)/bytecode.o

LDIR     = deps/luajit/src
SDIR     = deps/openssl

LDIRFLAGS= BUILDMODE=static
SDIRFLAGS= 

# Please do not enable static linking because
# OpenSSL seems to cause issues. This should probably
# get built and tested with MUSL for Linux.
#
# We localize these flags so that they are
# not passed into dependent projects.

ifeq ($(DEBUG), true)
	LOCCFLAGS  += -O0 -g3
	LOCLDFLAGS += -g3
endif

LOCLIBS := $(LDIR)/libluajit.a $(SDIR)/libssl.a $(SDIR)/libcrypto.a
CFLAGS  += -I$(LDIR) -I$(SDIR)/include/
LDFLAGS += -L$(LDIR) -L$(SDIR)

all: depends $(BIN)

depends:
	$(GIT) submodule update --init --recursive --force

clean:
	$(RM) $(BIN) obj/*
	@$(MAKE) -C deps/luajit clean
	@$(MAKE) -C deps/openssl clean

$(BIN): $(OBJ) $(LOCLIBS)
	@echo LINK $(BIN)
	@$(CC) $(LOCLDFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

$(OBJ): config.h Makefile | $(ODIR)

$(ODIR):
	@mkdir -p $@

$(ODIR)/bytecode.o: src/wrk.lua $(LDIR)/luajit
	@echo LUAJIT $<
	@$(SHELL) -c 'cd $(LDIR) && ./luajit -b $(CURDIR)/$< $(CURDIR)/$@'

$(ODIR)/%.o : %.c | $(LOCLIBS)
	@echo CC $<
	@$(CC) $(LOCCFLAGS) $(CFLAGS) -c -o $@ $<

$(LDIR) $(SDIR): depends

$(LDIR)/libluajit.a: $(LDIR)
	@echo Building LuaJIT...
	@[ -f "$@" ] || $(MAKE) -C $(LDIR) $(LDIRFLAGS)

$(LDIR)/luajit: $(LDIR)/libluajit.a

$(SDIR)/libcrypto.a: $(SDIR)
	@echo Building OpenSSL...
	@[ -f "$@" ] || { cd $(SDIR) && ./config $(SDIRFLAGS) && $(MAKE) ; }

$(SDIR)/libssl.a: $(SDIR)/libcrypto.a

.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .c .o .lua

vpath %.c   src
vpath %.h   src
vpath %.lua scripts
