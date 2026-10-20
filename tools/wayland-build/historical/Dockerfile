FROM ubuntu:24.04@sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG CHROMIUM_VERSION=154.0.8037.98
ARG DEPOT_TOOLS_REVISION=3e9862aec41915d8c39589f05a0380a6c12c525a
ARG UV_VERSION=0.13.3

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    DEPOT_TOOLS_UPDATE=0 \
    PATH=/opt/depot_tools:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN if [ -n "$HTTP_PROXY" ]; then \
      printf 'Acquire::http::Proxy "%s";\nAcquire::https::Proxy "%s";\n' "$HTTP_PROXY" "$HTTPS_PROXY" > /etc/apt/apt.conf.d/90-build-proxy; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl file git lsb-release procps python3 python3-venv sudo xz-utils zstd rsync libpipewire-0.3-dev libx11-xcb-dev

RUN curl --fail --location --retry 3 "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin

COPY install-build-deps.py /opt/cef-bootstrap/install-build-deps.py
RUN uv run --no-project --python /usr/bin/python3 /opt/cef-bootstrap/install-build-deps.py --no-prompt --no-arm --no-chromeos-fonts \
    && dpkg-query -W > /opt/cef-bootstrap/packages.txt \
    && rm -f /etc/apt/apt.conf.d/90-build-proxy \
    && rm -rf /var/lib/apt/lists/*

RUN git init /opt/depot_tools \
    && git -C /opt/depot_tools remote add origin https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    && git -C /opt/depot_tools fetch --depth=1 origin "$DEPOT_TOOLS_REVISION" \
    && git -C /opt/depot_tools checkout --detach FETCH_HEAD \
    && mkdir -p /build \
    && chown -R ubuntu:ubuntu /build /opt/depot_tools \
    && printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/cef-builder

USER ubuntu
WORKDIR /build
CMD ["bash"]
