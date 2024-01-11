# Build Container:
# - docker build -t ghcr.io/pulumi/devcontainer -f Dockerfile .
#
# Run Container:
# - docker run -it --rm -v $PWD:/workspaces ghcr.io/pulumi/devcontainer
#
# Base Image Reference:
# - https://mcr.microsoft.com/en-us/product/devcontainers/base/about

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Append rootfs directory tree into container to copy
# additional files into the container's directory tree
ADD rootfs /

# Disable timezone prompts
ENV TZ=UTC
# Disable package manager prompts
ENV DEBIAN_FRONTEND=noninteractive
# Add go and nix to path
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/nix/var/nix/profiles/default/bin"
# Set necessary nix environment variable
ENV NIX_INSTALLER_EXTRA_CONF='filter-syscalls = false'
# Default to MS FROM image builtin user
USER vscode

# Install apt packages
ARG APT_PKGS="\
gh \
git \
vim \
curl \
tmux \
gnupg \
socat \
libwrap0 \
gnupg-agent \
docker-ce-cli \
manpages-posix \
build-essential \
ca-certificates \
manpages-posix-dev \
apt-transport-https \
#docker-buildx-plugin \
software-properties-common \
"
RUN set -ex \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
    && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" \
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
    && chmod +x /tmp/pulumi/* \
    && sudo mv /tmp/pulumi/* /usr/local/bin/ \
    && which pulumi \
    && pulumi version \
    && rm -rf /tmp/* \
    && true

# Install pulumi esc
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "x64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlPulumiRelease="https://api.github.com/repos/pulumi/esc/releases/latest" \
    && export urlPulumiVersion=$(curl -s ${urlPulumiRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlPulumiBase="https://github.com/pulumi/esc/releases/download" \
    && export urlPulumiBin="esc-v${urlPulumiVersion}-linux-${arch}.tar.gz" \
    && export urlPulumi="${urlPulumiBase}/v${urlPulumiVersion}/${urlPulumiBin}" \
    && curl -L ${urlPulumi} | tar xzvf - --directory /tmp \
    && chmod +x /tmp/esc/esc \
    && sudo mv /tmp/esc/esc /usr/local/bin/esc \
    && which esc \
    && esc version \
    && rm -rf /tmp/* \
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
    && chmod +x /tmp/pulumictl \
    && sudo mv /tmp/pulumictl /usr/local/bin/ \
    && which pulumictl \
    && pulumictl version \
    && rm -rf /tmp/* \
    && true

# Install nix
# BUG: fix qemu buildx github action multi-arch arm64 nix install failure
RUN set -ex \
    && export urlNix="https://install.determinate.systems/nix" \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && curl --proto '=https' --tlsv1.2 -sSf -L ${urlNix} --output /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh install linux --init none --extra-conf "filter-syscalls = false" --no-confirm \
    && sh -c "nix --version" \
    && rm -rf /tmp/* \
    && true

# Install devbox
# BUG: depends on Nix installer qemu buildx gha arm64 bug resolution
# TODO: add devbox version test
RUN set -ex \
    && export urlDevbox="https://get.jetpack.io/devbox" \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && curl --proto '=https' --tlsv1.2 -sSf -L ${urlDevbox} --output /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh -f \
    && devbox version \
    && rm -rf /tmp/* \
    && true

# Install direnv
RUN set -ex \
    && echo 'eval "$(direnv hook $SHELL)"' | sudo tee -a /etc/skel/.bashrc | tee -a ${HOME}/.bashrc \
    && curl --output /tmp/install.sh --proto '=https' --tlsv1.2 -Sf -L "https://direnv.net/install.sh" \
    && chmod +x /tmp/install.sh \
    && sudo bash -c "/tmp/install.sh" \
    && direnv --version \
    && sudo rm -rf /tmp/* \
    && true

# Install golang
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

# Install python
# TODO: relocate install to devbox
ARG APT_PKGS="\
python3 \
python3-pip \
python3-venv \
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

# Install dotnet
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

# Install hugo
EXPOSE 1313
RUN set -ex \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export urlHugoRelease="https://api.github.com/repos/gohugoio/hugo/releases/latest" \
    && export urlHugoVersion=$(curl -s ${urlHugoRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
    && export urlHugoBase="https://github.com/gohugoio/hugo/releases/download" \
    && export urlHugoBin="hugo_${urlHugoVersion}_linux-${arch}.deb" \
    && export urlHugo="${urlHugoBase}/v${urlHugoVersion}/${urlHugoBin}" \
    && curl --output /tmp/${urlHugoBin} -L ${urlHugo} \
    && sudo dpkg -i /tmp/${urlHugoBin} \
    && which hugo \
    && hugo version \
    && rm -rf /tmp/* \
    && true

## Install kind (kubernetes-in-docker)
## TODO: relocate install to devcontainer.json
#RUN set -ex \
#    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
#    && export urlKindRelease="https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" \
#    && export urlKindVersion=$(curl -s ${urlKindRelease} | awk -F '["v,]' '/tag_name/{print $5}') \
#    && export urlKindBase="https://github.com/kubernetes-sigs/kind/releases/download" \
#    && export urlKindBin="kind-linux-${arch}" \
#    && export urlKind="${urlKindBase}/v${urlKindVersion}/${urlKindBin}" \
#    && sudo curl -L ${urlKind} --output /usr/local/bin/kind \
#    && sudo chmod +x /usr/local/bin/kind \
#    && which kind \
#    && kind version \
#    && true
#
## Install kubectl
## TODO: relocate install to devcontainer.json
#RUN set -ex \
#    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
#    && export varKubectlVersion="$(curl --silent -L https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/v//g')" \
#    && export varKubectlUrl="https://storage.googleapis.com/kubernetes-release/release/v${varKubectlVersion}/bin/linux/${arch}/kubectl" \
#    && sudo curl -L ${varKubectlUrl} --output /usr/local/bin/kubectl \
#    && sudo chmod +x /usr/local/bin/kubectl \
#    && kubectl version --client || true \
#    && true
#
## Install helm
## TODO: relocate install to devcontainer.json
#RUN set -ex \
#    && export varVerHelm="$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F '[\"v,]' '/tag_name/{print $5}')" \
#    && export varUrlHelm="https://get.helm.sh/helm-v${varVerHelm}-linux-amd64.tar.gz" \
#    && curl -L ${varUrlHelm} | tar xzvf - --directory /tmp linux-amd64/helm \
#    && chmod +x /tmp/linux-amd64/helm \
#    && sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm \
#    && helm version \
#    && rm -rf /tmp/linux-amd64 \
#    && true

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
