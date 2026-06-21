# ---- stage 1: build libucontext ----
FROM node:22-slim AS libucontext-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/kaniini/libucontext.git /tmp/libucontext \
    && make -C /tmp/libucontext ARCH=$(uname -m) \
    && make -C /tmp/libucontext ARCH=$(uname -m) DESTDIR=/tmp/install install

# ---- stage 2: build azure-cli venv ----
FROM node:22-slim AS az-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/az \
    && /opt/az/bin/pip install --no-cache-dir azure-cli \
    && rm -rf /opt/az/lib/python3.*/site-packages/azure/mgmt \
    && find /opt/az/lib/python3.*/site-packages/azure/cli/command_modules \
         -mindepth 1 -maxdepth 1 -type d \
         ! -name profile ! -name cloud ! -name configure ! -name config ! -name extension \
         -exec rm -rf {} + \
    && rm -rf /opt/az/lib/python3.*/site-packages/pip \
              /opt/az/lib/python3.*/site-packages/setuptools \
              /opt/az/lib/python3.*/site-packages/pygments \
    && find /opt/az -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true \
    && find /opt/az -type d -name tests -exec rm -rf {} + 2>/dev/null; true \
    && find /opt/az -name '*.pyc' -delete 2>/dev/null; true

# ---- stage 3: final ----
FROM node:22-slim

COPY --from=libucontext-builder /tmp/install/usr/lib/libucontext.so.1 /usr/lib/libucontext.so.1
COPY --from=az-builder /opt/az /opt/az

# Single RUN layer so all cleanup is real (not hidden in prior layers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap ca-certificates curl git jq make postgresql-client \
    python3 ripgrep socat unzip \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale/* \
    && ln -s /opt/az/bin/az /usr/local/bin/az \
    && curl -fsSL --retry 3 --http1.1 \
       "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl" \
       -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL --retry 3 --http1.1 \
       "https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-$(dpkg --print-architecture).zip" \
       -o /tmp/kubelogin.zip \
    && unzip -j /tmp/kubelogin.zip "bin/linux_$(dpkg --print-architecture)/kubelogin" -d /usr/local/bin \
    && rm /tmp/kubelogin.zip \
    && curl -fsSL --retry 3 --http1.1 \
       "https://releases.crossplane.io/stable/current/bin/linux_$(dpkg --print-architecture)/crank" \
       -o /usr/local/bin/crossplane \
    && chmod +x /usr/local/bin/crossplane \
    && npm install -g --no-optional @anthropic-ai/claude-code@latest opencode-ai \
    && npm cache clean --force \
    && rm -rf /tmp/* /root/.npm /root/.cache \
    && groupmod -n skip node \
    && usermod -l skip -d /home/skip -m node \
    && chmod -R a+rwX /home/skip \
    && echo "alias g='git'" >> /home/skip/.bashrc \
    && echo "alias clawde='claude --dangerously-skip-permissions'" >> /home/skip/.bashrc \
    && echo "alias ocode='opencode'" >> /home/skip/.bashrc \
    && echo "export LD_PRELOAD=/usr/lib/libucontext.so.1" >> /home/skip/.bashrc \
    && chown skip:skip /home/skip/.bashrc

USER skip
WORKDIR /home/skip/project
ENTRYPOINT ["bash"]
