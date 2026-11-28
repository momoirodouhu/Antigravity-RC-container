FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 1. Base OS utilities, diagnostics, Python3, and core CLI tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    dnsutils \
    fd-find \
    file \
    findutils \
    gawk \
    git \
    gnupg \
    grep \
    gzip \
    iproute2 \
    iputils-ping \
    jq \
    less \
    lsof \
    mtr-tiny \
    netcat-openbsd \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    sed \
    socat \
    strace \
    tar \
    tree \
    unzip \
    wget \
    xz-utils \
    zip \
    && ln -sfn /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# 2. GitHub CLI (gh) & Node.js LTS (22.x)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. yq & Kubernetes tools (kubectl, kubelogin OIDC, helm, kustomize)
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && KUBECTL_VER="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl" \
       -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL https://github.com/int128/kubelogin/releases/latest/download/kubelogin_linux_amd64.zip \
       -o /tmp/kubelogin.zip \
    && unzip -q /tmp/kubelogin.zip -d /tmp/kubelogin \
    && install -m 0755 /tmp/kubelogin/kubelogin /usr/local/bin/kubelogin \
    && ln -sfn /usr/local/bin/kubelogin /usr/local/bin/kubectl-oidc_login \
    && rm -rf /tmp/kubelogin /tmp/kubelogin.zip \
    && curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -fsSL https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh \
       | bash -s -- /usr/local/bin

# 4. User-space package managers (mise, uv), Coder CLI, and Antigravity CLI (agy)
# Installed into /usr/local/bin so PVC mount on /home/dev does not shadow them
RUN curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && curl -fsSL https://coder.com/install.sh | sh

# renovate: datasource=github-releases depName=google-antigravity/antigravity-cli
ARG AGY_VERSION=1.5.18
RUN curl -fsSL "https://github.com/google-antigravity/antigravity-cli/releases/download/${AGY_VERSION}/agy_cli_linux_x64.tar.gz" \
       -o /tmp/agy.tar.gz \
    && tar -xzf /tmp/agy.tar.gz -C /tmp antigravity \
    && install -m 0755 /tmp/antigravity /usr/local/bin/agy \
    && rm -f /tmp/agy.tar.gz /tmp/antigravity \
    && command -v agy

# 5. Non-root user (UID/GID 1000) & system-level environment profile + entrypoint
RUN groupadd -g 1000 dev \
    && useradd -m -u 1000 -g 1000 -d /home/dev -s /bin/bash dev \
    && mkdir -p /opt/antigravity

COPY ENV_PROFILE.md /opt/antigravity/ENV_PROFILE.md
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0644 /opt/antigravity/ENV_PROFILE.md \
    && chmod 0755 /usr/local/bin/entrypoint.sh

USER 1000:1000
WORKDIR /home/dev

ENV HOME=/home/dev \
    PATH="/home/dev/.local/share/mise/shims:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
