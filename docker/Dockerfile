# Build Container:
# - docker build -t ghcr.io/pulumi/devcontainer -f Dockerfile .
#
# Run Container:
# - docker run -it --rm -v $PWD:/workspaces ghcr.io/pulumi/devcontainer
#
# Base Image Reference:
# - https://mcr.microsoft.com/en-us/product/devcontainers/base/about

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04
SHELL ["/bin/bash", "-c", "-e"]

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
bc \
mc \
vim \
git \
tar \
mosh \
file \
wget \
tree \
pigz \
fish \
curl \
tmux \
tmate \
socat \
gnupg \
pipenv \
netcat \
psmisc \
procps \
passwd \
ripgrep \
tcpdump \
python3 \
pciutils \
libwrap0 \
xz-utils \
fontconfig \
glibc-tools \
python3-pip \
build-essential \
ca-certificates \
libarchive-tools \
neofetch \
"
RUN echo \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && echo

# Install docker packages for codespaces docker-in-docker
ARG APT_PKGS="\
docker-buildx-plugin \
docker-ce-cli \
libffi-dev \
iptables \
"
RUN echo \
    && sudo apt-get update \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo sudo rm -rf \
        /var/lib/{apt,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && echo

# Install Kind Kubernetes-in-Docker
RUN echo \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export varVerKind=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | awk -F '["v,]' '/tag_name/{print $5}') \
    && export varUrlKind="https://github.com/kubernetes-sigs/kind/releases/download/v${varVerKind}/kind-linux-${arch}" \
    && sudo curl --output /usr/bin/kind -L ${varUrlKind} \
    && sudo chmod +x /usr/bin/kind \
    && /usr/bin/kind version \
    && echo

# Install Kubectl
RUN echo \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export varVerKubectl="$(curl --silent -L https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/v//g')" \
    && export varUrlKubectl="https://storage.googleapis.com/kubernetes-release/release/v${varVerKubectl}/bin/linux/${arch}/kubectl" \
    && sudo curl -L ${varUrlKubectl} --output /bin/kubectl \
    && sudo chmod +x /bin/kubectl \
    && kubectl version --client \
    && echo

# Install pulumi
RUN echo \
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
    && echo

# Install pulumi esc
RUN echo \
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
    && echo

# Install pulumictl
RUN echo \
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
    && echo

# Install nix
# BUG: fix qemu buildx github action multi-arch arm64 nix install failure
RUN echo \
    && export urlNix="https://install.determinate.systems/nix" \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && curl --proto '=https' --tlsv1.2 -sSf -L ${urlNix} --output /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh install linux --init none --extra-conf "filter-syscalls = false" --no-confirm \
    && sh -c "nix --version" \
    && sudo rm -rf /tmp/* \
    && echo

# Install devbox
# BUG: depends on Nix installer qemu buildx gha arm64 bug resolution
# TODO: add devbox version test
RUN echo \
    && export urlDevbox="https://get.jetpack.io/devbox" \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && curl --proto '=https' --tlsv1.2 -sSf -L ${urlDevbox} --output /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh -f \
    && devbox version \
    && rm -rf /tmp/* \
    && echo

# Install direnv
RUN echo \
    && echo 'eval "$(direnv hook $SHELL)"' | sudo tee -a /etc/skel/.bashrc | tee -a ${HOME}/.bashrc \
    && curl --output /tmp/install.sh --proto '=https' --tlsv1.2 -Sf -L "https://direnv.net/install.sh" \
    && chmod +x /tmp/install.sh \
    && sudo bash -c "/tmp/install.sh" \
    && direnv --version \
    && sudo rm -rf /tmp/* \
    && echo

# Install golang
ARG GO_PKGS="\
golang.org/x/tools/gopls@latest \
github.com/josharian/impl@latest \
github.com/fatih/gomodifytags@latest \
github.com/cweill/gotests/gotests@latest \
github.com/go-delve/delve/cmd/dlv@latest \
honnef.co/go/tools/cmd/staticcheck@latest \
github.com/haya14busa/goplay/cmd/goplay@latest \
"
RUN echo \
    && export arch=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
    && export goversion="$(curl -s https://go.dev/dl/?mode=json | awk -F'[":go]' '/  "version"/{print $8}' | head -n1)" \
    && curl -L https://go.dev/dl/go${goversion}.linux-${arch}.tar.gz | sudo tar -C /usr/local/ -xzvf - \
    && which go \
    && go version \
    && for pkg in ${GO_PKGS}; do go install ${pkg}; echo "Installed: ${pkg}"; done \
    && echo

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
RUN echo \
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
        /var/lib/{apt,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && echo

# Install dotnet
ARG APT_PKGS="\
dotnet-sdk-7.0 \
dotnet-runtime-7.0 \
"
RUN echo \
    && sudo apt-get update \
    && sudo apt-get install ${APT_PKGS} \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && echo

# Install nodejs npm yarn
RUN echo \
    && export NODE_MAJOR=20 \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | sudo gpg --batch --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
        | sudo tee /etc/apt/sources.list.d/nodesource.list \
    && sudo apt-get update \
    && sudo apt-get install nodejs \
    && sudo apt-get clean \
    && sudo apt-get autoremove -y \
    && sudo apt-get purge -y --auto-remove \
    && sudo rm -rf \
        /var/lib/{apt,cache,log} \
        /usr/share/{doc,man,locale} \
        /var/cache/apt \
        /root/.cache \
        /var/tmp/* \
        /tmp/* \
    && node --version \
    && npm --version \
    && sudo npm install --global yarn \
    && yarn --version \
    && echo

# Install hugo
EXPOSE 1313
RUN echo \
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
    && echo

# Install helm
# TODO: relocate install to devcontainer.json
RUN echo \
    && export varVerHelm="$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F '[\"v,]' '/tag_name/{print $5}')" \
    && export varUrlHelm="https://get.helm.sh/helm-v${varVerHelm}-linux-amd64.tar.gz" \
    && curl -L ${varUrlHelm} | tar xzvf - --directory /tmp linux-amd64/helm \
    && chmod +x /tmp/linux-amd64/helm \
    && sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && helm version \
    && rm -rf /tmp/linux-amd64 \
    && echo

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

##################################################################################
# Common Functions
ARG curl="/usr/bin/curl --silent --show-error --tlsv1.2 --location"
ARG INSTALL="install -m 755 -o root -g root"
ARG BIN="/usr/local/bin"
ARG dir_clean="\
sudo rm -rf \
/var/lib/{apt,cache,log} \
/usr/share/{doc,man,locale} \
/var/cache/apt \
/home/*/.cache \
/root/.cache \
/var/tmp/* \
/tmp/* \
"

# jq
RUN set -ex; echo \
&& export NAME="jq" \
&& export TEST="${NAME} --version" \
&& export REPOSITORY="jqlang/jq" \
&& export ARCH="$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }')" \
&& export VERSION="$(${curl} https://api.github.com/repos/${REPOSITORY}/releases/latest | awk -F '[\"v\",-]' '/tag_name/{print $5}')" \
&& export PKG="${NAME}-linux-${ARCH}" \
&& export URL="https://github.com/${REPOSITORY}/releases/download/${NAME}-${VERSION}/${NAME}-linux-${ARCH}" \
&& echo "INFO[${NAME}] Installed:" \
&& echo "INFO[${NAME}]   Command:        ${NAME}" \
&& echo "INFO[${NAME}]   Package:        ${PKG}" \
&& echo "INFO[${NAME}]   Latest Release: ${VERSION}" \
&& echo "INFO[${NAME}]   Architecture:   ${ARCH}" \
&& echo "INFO[${NAME}]   Source:         ${URL}" \
&& ${curl} ${URL} --output /tmp/${NAME} \
&& file /tmp/${NAME} \
&& sudo ${INSTALL} /tmp/${NAME} ${BIN}/${NAME} \
&& ${dir_clean} \
&& ${TEST} \
&& echo

# Insall Github Actions Local Testing CLI
# - https://nektosact.com
# - https://github.com/nektos/gh-act
RUN echo \
&& export NAME=act \
&& export TEST="${NAME} --version" \
&& export REPOSITORY="nektos/gh-act" \
&& export VERSION="$(${curl} https://api.github.com/repos/${REPOSITORY}/releases/latest | jq --raw-output .tag_name)" \
&& export ARCH=$(uname -m | awk '{ if ($1 == "x86_64") print "amd64"; else if ($1 == "aarch64" || $1 == "arm64") print "arm64"; else print "unknown" }') \
&& export PKG="linux-${ARCH}" \
&& export URL="https://github.com/${REPOSITORY}/releases/download/${VERSION}/${PKG}" \
&& echo "---------------------------------------------------------"\
&& echo "INFO[${NAME}] Installed:" \
&& echo "INFO[${NAME}]   Command:        ${NAME}" \
&& echo "INFO[${NAME}]   Package:        ${PKG}" \
&& echo "INFO[${NAME}]   Latest Release: ${VERSION}" \
&& echo "INFO[${NAME}]   Architecture:   ${ARCH}" \
&& echo "INFO[${NAME}]   Source:         ${URL}" \
&& echo "---------------------------------------------------------"\
&& ${curl} ${URL} --output /tmp/${NAME} \
&& sudo ${INSTALL} /tmp/${NAME} ${BIN}/${NAME} \
&& ${dir_clean} \
&& ${TEST} \
&& echo