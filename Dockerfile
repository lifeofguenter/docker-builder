FROM public.ecr.aws/docker/library/docker:27

ARG TARGETOS
ARG TARGETARCH
ARG tfenv_version="3.0.0"
ARG tfdocs_version="0.19.0"
ARG packer_version="1.11.2"

ENV TFENV_AUTO_INSTALL="false" \
    AWS_METADATA_SERVICE_NUM_ATTEMPTS="5" \
    AWS_STS_REGIONAL_ENDPOINTS="regional" \
    PATH="/root/.local/bin:${PATH}"

RUN set -ex && \
    apk add --no-progress --no-cache \
      ansible \
      ansible-lint \
      aws-cli \
      bash \
      ca-certificates \
      curl \
      docker-credential-ecr-login \
      git \
      jq \
      make \
      mysql-client \
      ncurses \
      nodejs \
      npm \
      openssh-client \
      pipx \
      python3-dev \
      py3-dnspython \
      rsync \
      tree \
      wget \
      yamllint \
      zip && \
    mkdir -p \
      /root/.aws/ \
      /root/.ssh/

RUN set -ex && \
    pipx install pre-commit && \
    pipx install --preinstall python-gitlab terratalk

# terraform via tfenv
RUN set -ex && \
    cd /opt && \
    wget --no-verbose "https://github.com/tfutils/tfenv/archive/v${tfenv_version}.tar.gz" && \
    tar xf "v${tfenv_version}.tar.gz" && \
    ln -sf "/opt/tfenv-${tfenv_version}/bin/"* /usr/local/bin && \
    tfenv list-remote | grep '^1\.10\.' | grep -v '\(alpha\|beta\|rc\)' | head -n2 | xargs -n1 tfenv install && \
    tfenv list-remote | grep '^1\.9\.' | grep -v '\(alpha\|beta\|rc\)' | head -n1 | xargs -n1 tfenv install && \
    wget --no-verbose "https://github.com/terraform-docs/terraform-docs/releases/download/v${tfdocs_version}/terraform-docs-v${tfdocs_version}-${TARGETOS}-${TARGETARCH}.tar.gz" && \
    wget --no-verbose "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_${TARGETOS}_${TARGETARCH}.zip" && \
    tar xf terraform-docs-*.tar.gz && \
    unzip "packer_${packer_version}_${TARGETOS}_${TARGETARCH}.zip" && \
    chmod +x terraform-docs packer && \
    mv terraform-docs /usr/local/bin/terraform-docs && \
    mv packer /usr/local/bin/packer && \
    rm \
      "v${tfenv_version}.tar.gz" \
      packer_*.zip \
      terraform-docs-*.tar.gz

COPY known_hosts /root/.ssh/known_hosts
