FROM debian:stable-slim

# Build Variables
ARG USER_HOME=/home/piper
ARG MTA_PLUGIN_VERSION=2.5.0
ARG MTA_PLUGIN_URL=https://github.com/cloudfoundry-incubator/multiapps-cli-plugin/releases/download/v${MTA_PLUGIN_VERSION}/mta_plugin_linux_amd64

# Issue https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required dependecies
RUN apt-get update && apt-get install -y --no-install-recommends curl tar jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*
# Install yq processing tool
RUN curl -LJO https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod a+rx yq_linux_amd64 && \
    mv yq_linux_amd64 /opt/yq && \
    ln -sf /opt/yq /bin/yq
# Add group & user
RUN addgroup -gid 1001 piper && \
    useradd piper --uid 1001 --gid 1001 --shell /bin/bash --home-dir "${USER_HOME}" --create-home && \
    curl --location --silent "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -zx -C /usr/local/bin && \
    cf --version

# Switch to user
USER piper
WORKDIR ${USER_HOME}

# Install CF cli plugins
RUN cf add-plugin-repo CF-Community https://plugins.cloudfoundry.org && \
    cf install-plugin blue-green-deploy -f -r CF-Community && \
    cf install-plugin ${MTA_PLUGIN_URL} -f && \
    cf install-plugin Create-Service-Push -f -r CF-Community && \
    cf plugins

# Allow anybody to read/write/exec at HOME
RUN chmod -R o+rwx "${USER_HOME}"
ENV HOME=${USER_HOME}
