#!/bin/bash
set -e
B=/c/Users/ivelin/Downloads/qemu-3dfx-arch/virgil3d/MINGW-packages
cd /tmp/vpt/virglrenderer-1.3.0
mkdir -p src/gallium/include/sys
touch src/gallium/include/sys/ioccom.h

echo "0001:"; patch -p2 --dry-run -i $B/0001-Virglrenderer-on-Windows-and-macOS.patch 2>&1 | tail -1
echo "0002:"; patch -p1 --dry-run -i $B/0002-virglrenderer-angle-gles-fixes.patch 2>&1 | tail -1
echo "0003:"; patch -p1 --dry-run -i $B/0003-virglrenderer-angle-caps-gating.patch 2>&1 | tail -1
echo "0004:"; patch -p1 --dry-run -i $B/0004-virglrenderer-gles-copy-image-fallback.patch 2>&1 | tail -1
echo "0005:"; patch -p1 --dry-run -i $B/0005-virglrenderer-global-log-level-filter.patch 2>&1 | tail -1
echo "0006:"; patch -p1 --dry-run -i $B/0006-virglrenderer-experimental-gl46-caps.patch 2>&1 | tail -1
echo "0010:"; patch -p1 --dry-run -i $B/0010-virglrenderer-shader-texture-diagnostics.patch 2>&1 | tail -1
echo "ALL_DONE"
