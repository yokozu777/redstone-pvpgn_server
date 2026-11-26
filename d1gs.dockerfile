FROM ubuntu:26.04 AS fetch
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tar unzip \
 && mkdir -p /opt/diablo1 /tmp/devxh \
 && curl -fL "http://cdn.pvpgn.pro/diablo1/DIABDAT.MPQ" -o /opt/diablo1/DIABDAT.MPQ \
 && curl -fL "https://github.com/lldrattles/devxh/releases/download/v1.0.2/devxh-server-v1.0.2-linux-x64.tar.gz" -o /tmp/devxh-server.tar.gz \
 && tar -xzf /tmp/devxh-server.tar.gz -C /tmp/devxh \
 && server="$(find /tmp/devxh -type f -name devilutionx-server | head -n 1)" \
 && test -n "$server" \
 && cp "$server" /usr/local/bin/devilutionx-server \
 && chmod 755 /usr/local/bin/devilutionx-server \
 && find /tmp/devxh -type f -name 'devilutionx.mpq' -exec cp {} /opt/diablo1/ \; \
 && if [ ! -f /opt/diablo1/devilutionx.mpq ]; then \
      curl -fL "https://github.com/lldrattles/devxh/releases/download/v1.0.2/devxh-client-v1.0.2-win-x64.zip" -o /tmp/devxh-client.zip \
      && unzip -l /tmp/devxh-client.zip \
      && unzip -j /tmp/devxh-client.zip '*devilutionx.mpq' -d /opt/diablo1; \
    fi \
 && test -s /opt/diablo1/DIABDAT.MPQ \
 && test -s /opt/diablo1/devilutionx.mpq \
 && rm -rf /var/lib/apt/lists/* /tmp/devxh /tmp/devxh-server.tar.gz /tmp/devxh-client.zip

FROM ubuntu:26.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends libsdl2-2.0-0 libsdl2-image-2.0-0 zlib1g \
 && rm -rf /usr/lib/*/dri /usr/lib/*/libLLVM*.so* /usr/lib/*/libgallium*.so* \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/diablo1 /var/lib/d1gs /etc/d1gs
COPY --from=fetch /usr/local/bin/devilutionx-server /usr/local/bin/devilutionx-server
COPY --from=fetch /opt/diablo1 /opt/diablo1
ENTRYPOINT ["/usr/local/bin/devilutionx-server", \
  "--game", "diablo", \
  "--data-dir", "/opt/diablo1", \
  "--save-dir", "/var/lib/d1gs", \
  "--config-dir", "/etc/d1gs", \
  "--name", "d1gs", \
  "--port", "6115", \
  "--server-tcp"]
