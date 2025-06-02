QEMU_SRC_DIR=../../../qemu-1
FXLIB=../../fxlib
CROSS?=
VER?=
CC=$(CROSS)gcc$(VER)
RC=$(CROSS)windres
STRIP=strip
CFLAGS=-march=x86-64-v2 -mtune=generic -mfpmath=sse -msse2 -O3 -mcrc32
CFLAGS+=-pipe -I$(QEMU_SRC_DIR)/hw/mesa -I$(FXLIB) -Wall -Werror -flto=auto -fomit-frame-pointer
LDFLAGS=-static-libgcc
LDFLAGS+=-Wl,--disable-auto-image-base,--no-seh,--dynamicbase,--nxcompat
OUTDIR?=build
TARGET2=wgltest.res
TARGET3=wgltest.exe

all: wgltest.exe wgltest.res

wgltest.res: wgltest.rc
	@echo "  RC  $@"
	@$(RC) -DWINDRES -i $< -o $@ --output-format=coff
	@if [ -d ../$(OUTDIR) ]; then cp -v wgltest.res ../$(OUTDIR); fi

wgltest.exe: wgltest.c wgltest.res
	@echo "  LD  $@"
	@$(CC) $(CFLAGS) -s -o $@ wgltest.c wgltest.res $(LDFLAGS) -lgdi32 -lopengl32
	@if [ -d ../$(OUTDIR) ]; then cp -v wgltest.exe ../$(OUTDIR); fi

clean:
	@rm -f wgltest.res

distclean: clean
	@rm -f wgltest.exe

