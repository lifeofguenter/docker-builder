FROM public.ecr.aws/docker/library/debian:trixie-slim

ARG TARGETOS
ARG TARGETARCH
ARG DEBIAN_FRONTEND="noninteractive"
ARG tfenv_version="3.0.0"
ARG tfdocs_version="0.20.0"
ARG packer_version="1.14.2"
ARG mysql_version="8.4.6"

ENV TFENV_AUTO_INSTALL="false" \
    AWS_METADATA_SERVICE_NUM_ATTEMPTS="5" \
    AWS_STS_REGIONAL_ENDPOINTS="regional" \
    PATH="/root/.local/bin:${PATH}"

# Install docker-cli
RUN set -ex && \
    apt-get -qq update && \
    apt-get -yqq install --no-install-recommends ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get -qq update && \
    apt-get -yqq install --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*


RUN set -ex && \
    apt-get -qq update && \
    apt-get -yqq install --no-install-recommends \
      amazon-ecr-credential-helper \
      ansible \
      ansible-core \
      awscli \
      bash \
      ca-certificates \
      curl \
      git \
      gpg \
      jq \
      make \
      ncurses-bin \
      nodejs \
      npm \
      openssh-client \
      pigz \
      pipx \
      pre-commit \
      python3-boto3 \
      python3-cryptography \
      python3-dnspython \
      python3-github \
      python3-gitlab \
      python3-httplib2 \
      python3-jinja2 \
      python3-netaddr \
      python3-packaging \
      python3-passlib \
      python3-paramiko \
      python3-resolvelib \
      python3-setuptools \
      python3-yaml \
      rsync \
      tree \
      unzip \
      wget \
      xz-utils \
      yamllint \
      zip && \
    mkdir -p \
      /root/.aws/ \
      /root/.ssh/ && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

# Install mysql
RUN set -ex && \
    wget --no-verbose \
      "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-community-client_${mysql_version}-1debian12_amd64.deb" \
      "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-community-client-core_${mysql_version}-1debian12_amd64.deb" \
      "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-client_${mysql_version}-1debian12_amd64.deb" \
      "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-community-client-plugins_${mysql_version}-1debian12_amd64.deb" \
      "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-common_${mysql_version}-1debian12_amd64.deb" && \
    apt-get -qq update && \
    apt-get install -yqq --no-install-recommends ./*.deb && \
    rm -f ./*.deb && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

# Install terratalk
RUN set -ex && \
    pipx install --system-site-packages b2 && \
    pipx install --system-site-packages terratalk

# Install terraform via tfenv + packer
RUN set -ex && \
    cd /opt && \
    wget --no-verbose "https://github.com/tfutils/tfenv/archive/v${tfenv_version}.tar.gz" && \
    tar xf "v${tfenv_version}.tar.gz" && \
    ln -sf "/opt/tfenv-${tfenv_version}/bin/"* /usr/local/bin && \
    tfenv list-remote | grep '^1\.11\.' | grep -v '\(alpha\|beta\|rc\)' | head -n1 | xargs -n1 tfenv install && \
    tfenv list-remote | grep '^1\.12\.' | grep -v '\(alpha\|beta\|rc\)' | head -n1 | xargs -n1 tfenv install && \
    tfenv list-remote | grep '^1\.13\.' | grep -v '\(alpha\|beta\|rc\)' | head -n2 | xargs -n1 tfenv install && \
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

# gcloud
RUN set -ex && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
      gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
      tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get -qq update && \
    apt-get -yqq install --no-install-recommends \
      google-cloud-cli \
      google-cloud-cli-app-engine-go && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*


COPY known_hosts /root/.ssh/known_hosts
