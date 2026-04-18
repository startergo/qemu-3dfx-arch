# syntax=docker/dockerfile:1

FROM fedora:latest

ARG OUTPUT_DIR=/output
ARG BUILD_JOBS=4
ARG QEMU_REPO=https://github.com/qemu/qemu.git
ARG QEMU_REF=master
ARG VIRGL_HELPER_REPO=https://github.com/startergo/qemu-virgl-winhost.git
ARG VIRGL_HELPER_REF=master
ARG PRIMARY_PATCH=00-qemu110x-mesa-glide.patch
ARG ENABLE_QEMU_EXP=1
ARG VIRGL_VENUS=false
ARG VIRGL_BUILDTYPE=release

ENV OUTPUT_DIR=${OUTPUT_DIR}
ENV BUILD_JOBS=${BUILD_JOBS}
ENV PATH="/usr/lib/ccache:${PATH}"
ENV CCACHE_DIR="/ccache"

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf update -y && \
    dnf install -y \
        autoconf \
        automake \
        bison \
        ccache \
        cmake \
        curl \
        diffutils \
        flex \
        git \
        libtool \
        make \
        meson \
        mingw64-SDL2 \
        mingw64-SDL2_image \
        mingw64-cmake \
        mingw64-gcc \
        mingw64-gcc-c++ \
        mingw64-glib2 \
        mingw64-gtk3 \
        mingw64-libjpeg-turbo \
        mingw64-meson \
        mingw64-openssl \
        mingw64-opus \
        mingw64-pixman \
        mingw64-vulkan-headers \
        mingw64-vulkan-loader \
        mingw64-xz \
        mingw64-zlib \
        ninja-build \
        patch \
        pkg-config \
        python \
        python3-pip \
        python3-pyparsing \
        python3-pyyaml \
        rsync \
        rust \
        cargo \
        xorg-x11-util-macros

RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --upgrade meson

RUN git clone ${VIRGL_HELPER_REPO} /virgl-helper && \
    cd /virgl-helper && \
    git checkout ${VIRGL_HELPER_REF}

COPY . /src/

RUN angle_include=/usr/x86_64-w64-mingw32/sys-root/mingw/include && \
    angle_pkgconfig=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig && \
    cp -r /virgl-helper/angle/include/* ${angle_include}/ && \
    cp /virgl-helper/angle/egl.pc ${angle_pkgconfig}/ && \
    cp /virgl-helper/angle/glesv2.pc ${angle_pkgconfig}/ && \
    cp /virgl-helper/WinHv*.h ${angle_include}/ && \
    test -f ${angle_include}/EGL/egl.h && \
    test -f ${angle_include}/GLES2/gl2.h && \
    test -f ${angle_include}/KHR/khrplatform.h && \
    test -f ${angle_include}/angle_gl.h

RUN git clone https://github.com/anholt/libepoxy.git /libepoxy && \
    cd /libepoxy && \
    mingw64-meson builddir -Dtests=false -Degl=yes -Dglx=no -Dx11=false && \
    ninja -C builddir -j${BUILD_JOBS} && \
    ninja -C builddir install

RUN mkdir -p /usr/x86_64-w64-mingw32/sys-root/mingw/include/sys && \
    printf '%s\n' \
      '#pragma once' \
      '/* Stub sys/ioccom.h for cross-compilation to Windows */' \
      '#define IOC_VOID   0x20000000UL' \
      '#define IOC_OUT    0x40000000UL' \
      '#define IOC_IN     0x80000000UL' \
      '#define IOC_INOUT  (IOC_IN|IOC_OUT)' \
      '#define _IOC(d,g,n,l) ((d)|(((unsigned long)(l)&0x1fffUL)<<16UL)|((unsigned long)(g)<<8UL)|(unsigned long)(n))' \
      '#define _IO(g,n)     _IOC(IOC_VOID,(g),(n),0)' \
      '#define _IOR(g,n,t)  _IOC(IOC_OUT,(g),(n),sizeof(t))' \
      '#define _IOW(g,n,t)  _IOC(IOC_IN,(g),(n),sizeof(t))' \
      '#define _IOWR(g,n,t) _IOC(IOC_INOUT,(g),(n),sizeof(t))' \
    > /usr/x86_64-w64-mingw32/sys-root/mingw/include/sys/ioccom.h

RUN git clone https://gitlab.freedesktop.org/slirp/libslirp.git /libslirp && \
    cd /libslirp && \
    mingw64-meson build/ && \
    ninja -C build -j${BUILD_JOBS} && \
    ninja -C build install

RUN git clone https://gitlab.freedesktop.org/spice/spice-protocol.git /spice-protocol && \
    cd /spice-protocol && \
    mingw64-meson build/ && \
    ninja -C build -j${BUILD_JOBS} && \
    ninja -C build install

RUN git clone https://gitlab.freedesktop.org/spice/spice.git /spice && \
    cd /spice && \
    mingw64-meson build/ \
        -Dgstreamer=no \
        -Dopus=disabled \
        -Dlz4=false \
        -Dsasl=false \
        -Dmanual=false \
        -Dtests=false && \
    ninja -C build -j${BUILD_JOBS} && \
    ninja -C build install

RUN git clone --depth=1 https://gitlab.freedesktop.org/virgl/virglrenderer.git /virglrenderer && \
    cd /virglrenderer && \
    patch -p2 < /virgl-helper/patches/0001-Virglrenderer-on-Windows-and-macOS.patch && \
    patch -p1 < /src/virgil3d/MINGW-packages/0002-virglrenderer-angle-gles-fixes.patch && \
    angle_include=/usr/x86_64-w64-mingw32/sys-root/mingw/include && \
    combined_pc_path=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig && \
    mingw64-meson build/ \
        --buildtype=${VIRGL_BUILDTYPE} \
        -Dc_args=-I${angle_include} \
        -Dcpp_args=-I${angle_include} \
        --pkg-config-path=${combined_pc_path} \
        -Ddrm-renderers=[] \
        -Dvenus=${VIRGL_VENUS} \
        -Dtests=false \
        -Dvideo=false \
        -Dtracing=none \
        -Dplatforms=egl \
        -Dminigbm_allocation=false && \
    ninja -C build -j${BUILD_JOBS} && \
    ninja -C build install

RUN --mount=type=cache,target=/root/.cargo/registry \
    git clone ${QEMU_REPO} /qemu && \
    cd /qemu && \
    git checkout ${QEMU_REF} && \
    if [ "${ENABLE_QEMU_EXP}" = "1" ]; then \
        (cd /src && bash scripts/apply_qemu_patches.sh --src-dir /qemu --primary-patch "/src/${PRIMARY_PATCH}" --with-qemu-exp); \
    else \
        (cd /src && bash scripts/apply_qemu_patches.sh --src-dir /qemu --primary-patch "/src/${PRIMARY_PATCH}"); \
    fi && \
    export NOCONFIGURE=1 && \
    export MESON=/usr/local/bin/meson && \
    sed -i 's/SDL_HINT_ANGLE_BACKEND/"SDL_ANGLE_BACKEND"/g; s/SDL_HINT_ANGLE_FAST_PATH/"SDL_ANGLE_FAST_PATH"/g' /qemu/ui/sdl2.c && \
    ./configure \
        --target-list=x86_64-softmmu,i386-softmmu \
        --prefix="${OUTPUT_DIR}" \
        --cross-prefix=x86_64-w64-mingw32- \
        --enable-whpx \
        --enable-virglrenderer \
        --enable-opengl \
        --enable-gtk \
        --enable-debug \
        --disable-stack-protector \
        --disable-werror \
        --disable-rust \
        --enable-sdl \
        --enable-sdl-image \
        --enable-slirp \
        --enable-spice && \
    make -j${BUILD_JOBS} && \
    make install

RUN mkdir -p ${OUTPUT_DIR}/bin && \
    cp -r ${OUTPUT_DIR}/*.exe ${OUTPUT_DIR}/bin/ || true && \
    cp -r ${OUTPUT_DIR}/x86_64-softmmu/*.exe ${OUTPUT_DIR}/bin/ || true && \
    cp /usr/x86_64-w64-mingw32/sys-root/mingw/bin/*.dll ${OUTPUT_DIR}/bin/ || true

RUN echo '#!/bin/sh' > /copy-output.sh && \
    echo 'cp -r ${OUTPUT_DIR}/* /mnt/output/' >> /copy-output.sh && \
    echo 'echo "Build artifacts copied to output directory"' >> /copy-output.sh && \
    chmod +x /copy-output.sh

CMD ["/copy-output.sh"]