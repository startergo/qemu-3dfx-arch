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

all: wglgears.exe pbuffer.exe

wglgears.res: wglgears.rc
	@echo "  RC  $@"
	@$(RC) -DWINDRES -i $< -o $@ --output-format=coff
	@if [ -d ../$(OUTDIR) ]; then cp -v wglgears.res ../$(OUTDIR); fi

wglgears.exe: wglgears.c wglgears.res
	@echo "  LD  $@"
	@$(CC) $(CFLAGS) -s -o $@ wglgears.c wglgears.res $(LDFLAGS) -lgdi32 -lopengl32
	@if [ -d ../$(OUTDIR) ]; then cp -v wglgears.exe ../$(OUTDIR); fi

pbuffer.res: pbuffer.rc
	@echo "  RC  $@"
	@$(RC) -DWINDRES -i $< -o $@ --output-format=coff
	@if [ -d ../$(OUTDIR) ]; then cp -v pbuffer.res ../$(OUTDIR); fi

pbuffer.exe: pbuffer.c pbuffer.res
	@echo "  LD  $@"
	@$(CC) $(CFLAGS) -s -o $@ pbuffer.c pbuffer.res $(LDFLAGS) -lwinmm -lgdi32 -lopengl32
	@if [ -d ../$(OUTDIR) ]; then cp -v pbuffer.exe ../$(OUTDIR); fi


clean:
	@rm -f wglgears.res pbuffer.res

distclean: clean
	@rm -f wglgears.exe pbuffer.exe

