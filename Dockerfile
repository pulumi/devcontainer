# Build Container:
# - docker build -t ghcr.io/pulumi/devcontainer -f Dockerfile .
#
# Run Container:
# - docker run -it --rm -v $PWD:/workspaces ghcr.io/pulumi/devcontainer
#
# Base Image Reference:
# - https://mcr.microsoft.com/en-us/product/devcontainers/base/about

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG APT_PKGS="\
gh \
git \
curl \
gnupg \
build-essential \
ca-certificates \
tmux \
vim \
"

# Append rootfs directory tree into container to copy
# additional files into the container's directory tree
ADD rootfs /

# Disable timezone prompts
ENV TZ=UTC
# Disable package manager prompts
ENV DEBIAN_FRONTEND=noninteractive
# Add go and nix to path
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/nix/var/nix/profiles/default/bin"
# Default to MS FROM image builtin user
USER vscode

# Install apt packages
RUN set -ex \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && true

# Install pulumi
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "x64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlPulumiRelease="https://api.github.com/repos/pulumi/pulumi/releases/latest" \
    && export urlPulumiVersion=$(curl -s ${urlPulumiRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlPulumiBase="https://github.com/pulumi/pulumi/releases/download" \
    && export urlPulumiBin="pulumi-v${urlPulumiVersion}-linux-${arch}.tar.gz" \
    && export urlPulumi="${urlPulumiBase}/v${urlPulumiVersion}/${urlPulumiBin}" \
    && curl -L ${urlPulumi} | tar xzvf - --directory /tmp \
    && sudo mv /tmp/pulumi/* /usr/local/bin/ \
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
    && sudo mv /tmp/esc/esc /usr/local/bin/esc \
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
    && sudo mv /tmp/pulumictl /usr/local/bin/ \
    && rm -rf /tmp/* \
    && which pulumictl \
    && pulumictl version \
    && true

# Install Nix
# BUG: fix qemu buildx github action multi-arch arm64 nix install failure
ENV PATH="${PATH}"
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && [ ${arch} = "arm64" ] || curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
       | sh -s -- install linux --extra-conf "sandbox = false" --init none --no-confirm \
    && [ ${arch} = "arm64" ] || bash -c "nix --version" \
    && true

# Install Devbox from jetpack.io
# BUG: depends on Nix installer qemu buildx gha arm64 bug resolution
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && [ ${arch} = "arm64" ] || curl -L https://get.jetpack.io/devbox --output /tmp/devbox.sh \
    && [ ${arch} = "arm64" ] || bash /tmp/devbox.sh -f \
    && [ ${arch} = "arm64" ] || rm -rf /tmp/* \
    && true

# Install golang from upstream
# TODO: relocate install to devbox
ARG GO_PKGS="\
golang.org/x/tools/gopls@latest \
github.com/josharian/impl@latest \
github.com/fatih/gomodifytags@latest \
github.com/cweill/gotests/gotests@latest \
github.com/go-delve/delve/cmd/dlv@latest \
honnef.co/go/tools/cmd/staticcheck@latest \
github.com/haya14busa/goplay/cmd/goplay@latest \
"
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export goversion="$(curl -s https://go.dev/dl/?mode=json | awk -F'[":go]' '/  "version"/{print $8}' | head -n1)" \
    && curl -L https://go.dev/dl/go${goversion}.linux-${arch}.tar.gz | sudo tar -C /usr/local/ -xzvf - \
    && which go \
    && go version \
    && for pkg in ${GO_PKGS}; do go install ${pkg}; echo "Installed: ${pkg}"; done \
    && true

# Install Python
# TODO: relocate install to devbox
ARG APT_PKGS="\
python3 \
python3-pip \
dotnet-sdk-7.0 \
dotnet-runtime-7.0 \
"
ARG PIP_PKGS="\
setuptools \
"
RUN set -ex \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo update-alternatives --install \
        /usr/bin/python python \
        /usr/bin/python3 1 \
    && sudo python3 -m pip install ${PIP_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && true

# Install .NET
# TODO: relocate install to devbox
ARG APT_PKGS="\
dotnet-sdk-7.0 \
dotnet-runtime-7.0 \
"
RUN set -ex \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && true

# Install nodejs npm yarn
# TODO: relocate install to devbox
RUN set -ex \
    && export NODE_MAJOR=20 \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
        | sudo tee /etc/apt/sources.list.d/nodesource.list \
    && sudo apt-get update \
    && sudo apt-get install nodejs \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,dpkg,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && node --version \
    && npm --version \
    && sudo npm install --global yarn \
    && yarn --version \
    && true

# Install kind (Kubernetes-in-Docker)
# TODO: relocate install to devcontainer.json
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlKindRelease="https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" \
    && export urlKindVersion=$(curl -s ${urlKindRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlKindBase="https://github.com/kubernetes-sigs/kind/releases/download" \
    && export urlKindBin="kind-linux-${arch}" \
    && export urlKind="${urlKindBase}/v${urlKindVersion}/${urlKindBin}" \
    && sudo curl -L ${urlKind} --output /usr/local/bin/kind \
    && sudo chmod +x /usr/local/bin/kind \
    && which kind \
    && kind version \
    && true

# Install kubectl
# TODO: relocate install to devcontainer.json
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export varKubectlVersion="$(curl --silent -L https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/v//g')" \
    && export varKubectlUrl="https://storage.googleapis.com/kubernetes-release/release/v${varKubectlVersion}/bin/linux/${arch}/kubectl" \
    && sudo curl -L ${varKubectlUrl} --output /usr/local/bin/kubectl \
    && sudo chmod +x /usr/local/bin/kubectl \
    && kubectl version --client || exit 1 \
    && true

# Install helm
# TODO: relocate install to devcontainer.json
RUN set -ex \
    && export varVerHelm="$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F '[\"v,]' '/tag_name/{print $5}')" \
    && export varUrlHelm="https://get.helm.sh/helm-v${varVerHelm}-linux-amd64.tar.gz" \
    && curl -L ${varUrlHelm} | tar xzvf - --directory /tmp linux-amd64/helm \
    && sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && sudo chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64 \
    && helm version \
    && true

WORKDIR /workspaces
CMD ["/usr/bin/zsh"]

# GHCR Labels
LABEL org.opencontainers.image.licenses="APACHE2"
LABEL org.opencontainers.image.source="https://github.com/pulumi/devcontainer"
LABEL org.opencontainers.image.description="A containerized environment for developing and running pulumi IaC and Provider code"

# General Labels
ARG VERSION
ARG BUILD_DATE
LABEL \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.vendor="Pulumi" \
    org.opencontainers.image.title="Pulumi Dev Container" \
    org.opencontainers.image.url="https://github.com/pulumi/devcontainer" \
    org.opencontainers.image.documentation="https://github.com/pulumi/devcontainer" \
    org.opencontainers.image.authors="https://github.com/pulumi"
