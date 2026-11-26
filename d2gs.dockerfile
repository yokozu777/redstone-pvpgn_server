FROM ubuntu:26.04 AS wine-builder
ARG WINE_MAIN=11.x
ARG WINE=11.22
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates make wget flex bison xz-utils \
      gcc-multilib g++-multilib \
      lib32z1 zlib1g-dev:i386 libncurses-dev:i386 \
 && rm -rf /var/lib/apt/lists/* \
 && wget --tries=5 --timeout=30 --retry-connrefused \
      "http://dl.winehq.org/wine/source/${WINE_MAIN}/wine-${WINE}.tar.xz" \
 && tar xf "wine-${WINE}.tar.xz" \
 && cd "wine-${WINE}" \
 && CC="gcc -m32" CXX="g++ -m32" CFLAGS="-m32" CXXFLAGS="-m32" LDFLAGS="-m32" \
    ./configure \
    --without-alsa \
    --without-capi \
    --without-coreaudio \
    --without-cups \
    --without-dbus \
    --without-ffmpeg \
    --without-fontconfig \
    --without-freetype \
    --without-gettext \
    --without-gphoto \
    --without-gnutls \
    --without-gssapi \
    --without-gstreamer \
    --without-inotify \
    --without-krb5 \
    --without-mingw \
    --without-netapi \
    --without-opencl \
    --without-opengl \
    --without-oss \
    --without-pcap \
    --without-pcsclite \
    --without-pthread \
    --without-pulse \
    --without-sane \
    --without-sdl \
    --without-udev \
    --without-usb \
    --without-v4l2 \
    --without-vulkan \
    --without-wayland \
    --without-x \
    --without-xcomposite \
    --without-xcursor \
    --without-xfixes \
    --without-xinerama \
    --without-xinput \
    --without-xinput2 \
    --without-xrandr \
    --without-xrender \
    --without-xshape \
    --without-xshm \
    --without-xxf86vm \
    --disable-win16 \
    --disable-tests \
 && make -j "$(nproc)" \
 && make install \
 && mkdir -p /root/.wine/drive_c/d2gs \
 && test -x /usr/local/bin/wine \
 && test -d /usr/local/lib/wine/i386-unix \
 && test -d /usr/local/share/wine \
 && rm -rf /opt/*
RUN find /usr/local/bin /usr/local/lib/wine/i386-unix -type f \
      -exec strip --strip-unneeded {} + ; \
    rm -rf /usr/local/include /usr/local/share/man /usr/local/share/applications \
 && find /usr/local -type f -name '*.a' -delete

FROM alpine:latest AS downloader
ARG D2URL="http://cdn.pvpgn.pro/diablo2"
RUN apk add --no-cache wget xz ; mkdir -p /opt/d2gs ;  wget $D2URL/1.13d/D2Client.dll $D2URL/1.13d/D2CMP.dll $D2URL/1.13d/D2Common.dll \
$D2URL/1.13d/D2Game.dll $D2URL/1.13d/D2gfx.dll $D2URL/1.13d/D2Lang.dll $D2URL/1.13d/D2MCPClient.dll $D2URL/1.13d/D2Net.dll $D2URL/1.13d/D2sound.dll \
$D2URL/1.13d/D2Win.dll $D2URL/1.13d/Fog.dll $D2URL/1.13d/Storm.dll $D2URL/1.14d/Patch_D2.mpq $D2URL/1.14d/ijl11.dll $D2URL/d2speech.mpq \
http://cdn.pvpgn.pro/diablo2/d2data.mpq http://cdn.pvpgn.pro/diablo2/d2sfx.mpq http://cdn.pvpgn.pro/diablo2/d2exp.mpq -P /opt/d2gs ; \
wget https://github.com/pvpgn/pvpgn-magic-builder/archive/v2.31.tar.gz ; tar xf v2.31.tar.gz ; mv pvpgn-magic-builder-2.31/module/include/d2gs/1.13d/* /opt/d2gs

FROM ubuntu:26.04
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends libc6:i386 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=wine-builder /usr/local/bin /usr/local/bin
COPY --from=wine-builder /usr/local/lib/wine /usr/local/lib/wine
COPY --from=wine-builder /usr/local/share/wine /usr/local/share/wine
WORKDIR /root/.wine/drive_c/d2gs
COPY --from=downloader /opt/d2gs .
COPY --chmod=777 conf/* .
ENTRYPOINT ["./start.sh"]
