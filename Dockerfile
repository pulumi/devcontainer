# Build Container:
# - docker build -t ghcr.io/pulumi/devcontainer -f Dockerfile .
#
# Build Provider:
# - docker run -it --rm -v $PWD:/workspace ghcr.io/pulumi/devcontainer
#
# Run Container:
# - docker run -it --rm -v $PWD:/workspace --entrypoint bash ghcr.io/pulumi/devcontainer

FROM docker.io/library/ubuntu:22.04

ARG PIP_PKGS="\
setuptools \
"

ARG APT_PKGS="\
gh \
git \
vim \
curl \
tmux \
gnupg \
python3 \
python3-pip \
dotnet-sdk-7.0 \
ca-certificates \
build-essential \
dotnet-runtime-7.0 \
# golang-go \ # default go 1.18 package version is not new enough
"

ARG GO_PKGS="\
golang.org/x/tools/gopls@latest \
github.com/josharian/impl@latest \
github.com/fatih/gomodifytags@latest \
github.com/cweill/gotests/gotests@latest \
github.com/go-delve/delve/cmd/dlv@latest \
honnef.co/go/tools/cmd/staticcheck@latest \
github.com/haya14busa/goplay/cmd/goplay@latest \
"

# Append rootfs directory tree into container to copy
# additional files into the container's directory tree
ADD rootfs /

# Disable timezone prompts
ENV TZ=UTC
# Disable package manager prompts
ENV DEBIAN_FRONTEND=noninteractive
# Add go and nix to path
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/go/bin:/nix/var/nix/profiles/default/bin"

# Install apt & pip packages
RUN set -ex \
    && apt-get update \
    && apt-get install ${APT_PKGS} \
    && update-alternatives --install \
        /usr/bin/python python \
        /usr/bin/python3 1 \
    && python3 -m pip install ${PIP_PKGS} \
    && apt-get clean \
    && apt-get autoremove -y \
    && apt-get purge -y --auto-remove \
    && rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && true

# Install golang from upstream
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export goversion="$(curl -s https://go.dev/dl/?mode=json | awk -F'[":go]' '/  "version"/{print $8}' | head -n1)" \
    && curl -L https://go.dev/dl/go${goversion}.linux-${arch}.tar.gz | tar -C /usr/local/ -xzvf - \
    && which go \
    && go version \
    && for pkg in ${GO_PKGS}; do go install ${pkg}; echo "Installed: ${pkg}"; done \
    && true

# Install nodejs npm yarn
RUN set -ex \
    && export NODE_MAJOR=20 \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
        | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs \
    && apt-get clean \
    && apt-get autoremove -y \
    && apt-get purge -y --auto-remove \
    && rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && node --version \
    && npm --version \
    && npm install --global yarn \
    && yarn --version \
    && true

# TODO: debug qemu buildx cross arch build failure
## Install Nix
#ENV PATH="${PATH}"
#RUN set -ex \
#    && curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
#        | sh -s -- install linux \
#            --extra-conf "sandbox = false" \
#            --init none \
#            --no-confirm \
#    && true

# Install pulumi
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "x64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlPulumiRelease="https://api.github.com/repos/pulumi/pulumi/releases/latest" \
    && export urlPulumiVersion=$(curl -s ${urlPulumiRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlPulumiBase="https://github.com/pulumi/pulumi/releases/download" \
    && export urlPulumiBin="pulumi-v${urlPulumiVersion}-linux-${arch}.tar.gz" \
    && export urlPulumi="${urlPulumiBase}/v${urlPulumiVersion}/${urlPulumiBin}" \
    && curl -L ${urlPulumi} | tar xzvf - --directory /tmp \
    && mv /tmp/pulumi/* /usr/local/bin/ \
    && rm -rf /tmp/pulumi \
    && which pulumi \
    && pulumi version \
    && true

# Install Pulumi ESC
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "x64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlPulumiRelease="https://api.github.com/repos/pulumi/esc/releases/latest" \
    && export urlPulumiVersion=$(curl -s ${urlPulumiRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlPulumiBase="https://github.com/pulumi/esc/releases/download" \
    && export urlPulumiBin="esc-v${urlPulumiVersion}-linux-${arch}.tar.gz" \
    && export urlPulumi="${urlPulumiBase}/v${urlPulumiVersion}/${urlPulumiBin}" \
    && curl -L ${urlPulumi} | tar xzvf - --directory /tmp \
    && mv /tmp/esc/esc /usr/local/bin/esc \
    && rm -rf /tmp/esc \
    && which esc \
    && esc version \
    && true

# Install pulumictl
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlPulumiRelease="https://api.github.com/repos/pulumi/pulumictl/releases/latest" \
    && export urlPulumiVersion=$(curl -s ${urlPulumiRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlPulumiBase="https://github.com/pulumi/pulumictl/releases/download" \
    && export urlPulumiBin="pulumictl-v${urlPulumiVersion}-linux-${arch}.tar.gz" \
    && export urlPulumi="${urlPulumiBase}/v${urlPulumiVersion}/${urlPulumiBin}" \
    && curl -L ${urlPulumi} | tar xzvf - --directory /tmp \
    && mv /tmp/pulumictl /usr/local/bin/ \
    && rm -rf /tmp/* \
    && which pulumictl \
    && pulumictl version \
    && true

# Install kind (Kubernetes-in-Docker)
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlKindRelease="https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" \
    && export urlKindVersion=$(curl -s ${urlKindRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlKindBase="https://github.com/kubernetes-sigs/kind/releases/download" \
    && export urlKindBin="kind-linux-${arch}" \
    && export urlKind="${urlKindBase}/v${urlKindVersion}/${urlKindBin}" \
    && curl -L ${urlKind} --output /usr/local/bin/kind \
    && chmod +x /usr/local/bin/kind \
    && which kind \
    && kind version \
    && true

# Install kubectl
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export varKubectlVersion="$(curl --silent -L https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/v//g')" \
    && export varKubectlUrl="https://storage.googleapis.com/kubernetes-release/release/v${varKubectlVersion}/bin/linux/${arch}/kubectl" \
    && curl -L ${varKubectlUrl} --output /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client || exit 1 \
    && true

# Install helm
RUN set -ex \
    && export varVerHelm="$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F '[\"v,]' '/tag_name/{print $5}')" \
    && export varUrlHelm="https://get.helm.sh/helm-v${varVerHelm}-linux-amd64.tar.gz" \
    && curl -L ${varUrlHelm} | tar xzvf - --directory /tmp linux-amd64/helm \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && helm version \
    && rm -rf /tmp/linux-amd64 \
    && true

WORKDIR /workspaces
CMD ["make", "build"]

# GHCR Labels
LABEL org.opencontainers.image.licenses="APACHE2"
LABEL org.opencontainers.image.source="https://github.com/pulumi/devcontainer"
LABEL org.opencontainers.image.description="A containerized environment for developing and running pulumi IaC and Provider code"

# General Labels
ARG VERSION
ARG BUILD_DATE
ARG PULUMICTL
ARG PULUMI
LABEL \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.vendor="Pulumi" \
    org.opencontainers.image.title="Pulumi Dev Container" \
    org.opencontainers.image.url="https://github.com/pulumi/devcontainer" \
    org.opencontainers.image.documentation="https://github.com/pulumi/devcontainer" \
    org.opencontainers.image.authors="https://github.com/pulumi"

