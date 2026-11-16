# figcraft-server (Dokploy) — image ringan dari binary prebuilt
# Alasan: Dockerfile resmi (packaging/server/Dockerfile) build dari source pakai
# cargo --release, terlalu berat untuk host Dokploy Rendy (RAM kosong ~584 MB).
# Image ini mengunduh tarball release resmi v0.18.1 dan memverifikasi SHA256-nya,
# lalu menjalankan binary yang sama persis dengan stage runtime Dockerfile resmi
# (distroless cc-debian12:nonroot, user nonroot uid 65532, /data, port 47900).
# SHA256 diverifikasi dari SHA256SUMS.txt resmi:
# https://github.com/storytold/figcraft/releases/download/v0.18.1/SHA256SUMS.txt
# figcraft-server-0.18.1-linux-x86_64.tar.gz =
#   215b61e5b1dd5b4b4d193509b7be54010e3b929dd19b9a3a85fb1357539cdcd8

ARG FIGCRAFT_VERSION=0.18.1

FROM debian:bookworm-slim AS fetch
ARG FIGCRAFT_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates tar \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fLO "https://github.com/storytold/figcraft/releases/download/v${FIGCRAFT_VERSION}/figcraft-server-${FIGCRAFT_VERSION}-linux-x86_64.tar.gz" \
 && printf '215b61e5b1dd5b4b4d193509b7be54010e3b929dd19b9a3a85fb1357539cdcd8  figcraft-server-%s-linux-x86_64.tar.gz\n' "${FIGCRAFT_VERSION}" | sha256sum -c - \
 && mkdir -p /out/data \
 && tar -xzf "figcraft-server-${FIGCRAFT_VERSION}-linux-x86_64.tar.gz" -C /out --strip-components=1

# Sama seperti runtime stage Dockerfile resmi: glibc + libgcc saja, tanpa shell.
FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=fetch /out/figcraft-server /usr/local/bin/figcraft-server
COPY server.toml /etc/figcraft-server/server.toml
COPY --from=fetch --chown=nonroot:nonroot /out/data /data

USER nonroot
VOLUME /data
EXPOSE 47900
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/local/bin/figcraft-server", "--config", "/etc/figcraft-server/server.toml"]
