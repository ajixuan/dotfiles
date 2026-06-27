# ---- stage 1: build libucontext ----
FROM node:22-trixie-slim AS libucontext-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/kaniini/libucontext.git /tmp/libucontext \
    && make -C /tmp/libucontext ARCH=$(uname -m) \
    && make -C /tmp/libucontext ARCH=$(uname -m) DESTDIR=/tmp/install install

# ---- stage 2: final ----
FROM node:22-trixie-slim

COPY --from=libucontext-builder /tmp/install/usr/lib/libucontext.so.1 /usr/lib/libucontext.so.1

# Single RUN layer so all cleanup is real
RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap ca-certificates curl git jq make postgresql-client \
    python3 ripgrep socat unzip \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale/* \
    && curl -fsSL --retry 3 --http1.1 \
       "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl" \
       -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL --retry 3 --http1.1 \
       "https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-$(dpkg --print-architecture).zip" \
       -o /tmp/kubelogin.zip \
    && unzip -j /tmp/kubelogin.zip "bin/linux_$(dpkg --print-architecture)/kubelogin" -d /usr/local/bin \
    && rm /tmp/kubelogin.zip \
    && npm cache clean --force \
    && rm -rf /tmp/* /root/.npm /root/.cache \
    && groupmod -n skip node \
    && usermod -l skip -d /home/skip -m node \
    && chmod -R a+rwX /home/skip \
    && echo "alias g='git'" >> /home/skip/.bashrc \
    && echo "alias clawde='claude --dangerously-skip-permissions'" >> /home/skip/.bashrc \
    && echo "alias ocode='opencode serve --port 4096'" >> /home/skip/.bashrc \
    && echo "export LD_PRELOAD=/usr/lib/libucontext.so.1" >> /home/skip/.bashrc \
    && chown skip:skip /home/skip/.bashrc

USER skip
WORKDIR /home/skip/project
ENTRYPOINT ["bash"]
