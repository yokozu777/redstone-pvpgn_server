FROM ubuntu:26.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates wget git build-essential clang cmake pkg-config \
    zlib1g-dev libcurl4-openssl-dev liblua5.1-0-dev \
    libmariadb-dev libmariadb-dev-compat \
 && rm -rf /var/lib/apt/lists/* \
 && wget https://github.com/pvpgn/pvpgn-server/archive/1.99.8.0.0-rc1-PRO.tar.gz \
 && tar xf 1.99.8.0.0-rc1-PRO.tar.gz \
 && mkdir pvpgn-server-1.99.8.0.0-rc1-PRO/build
WORKDIR "/pvpgn-server-1.99.8.0.0-rc1-PRO/build"
RUN cmake -D CMAKE_INSTALL_PREFIX=/pvpgn -D WITH_MYSQL=true -D WITH_LUA=true -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ../ && make -j $(nproc) && make install

FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /pvpgn/sbin \
 && apt-get update \
 && apt-get install -y --no-install-recommends libstdc++6 liblua5.1-0 libmariadb3 libcurl4t64 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /pvpgn/sbin /pvpgn/sbin
COPY --from=builder /pvpgn/var /pvpgn/var
COPY --from=builder /pvpgn/etc /pvpgn/etc
RUN apt-get update \
 && apt-get install -y --no-install-recommends binutils \
 && find /pvpgn/sbin -type f ! -name '*.mod' -exec strip --strip-unneeded {} + \
 && apt-get purge -y binutils \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /pvpgn/etc/pvpgn /opt/pvpgn-defaults/etc
COPY --from=builder /pvpgn/var/pvpgn /opt/pvpgn-defaults/var
