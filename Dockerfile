# This Dockerfile is based on the Argo CD w/ KSOPS Dockerfile found at:
# https://github.com/viaduct-ai/kustomize-sops#custom-argo-cd-w-ksops-dockerfile

ARG ARGO_CD_VERSION="v1.4.2"
ARG CUSTOMIZE_VERSION="v3.5.4"
ARG CUSTOMIZE_GO_VERSION="1.13"

#---------------------------------------------------------------#
#--------Build kustomize-kvsource-vault and Kustomize-----------#
#---------------------------------------------------------------#

FROM golang:$CUSTOMIZE_GO_VERSION as kustomize-kvsource-vault-builder

# Match Argo CD's build
ENV GOOS=linux
ENV GOARCH=amd64
ENV GO111MODULE=on

# Install kustomize via Go
RUN go get sigs.k8s.io/kustomize/kustomize/v3@${CUSTOMIZE_VERSION}

WORKDIR /go/src/github.com/noseka1/

RUN git clone https://github.com/noseka1/kustomize-kvsource-vault.git

# CD into the clone repo
WORKDIR /go/src/github.com/noseka1/kustomize-kvsource-vault

ARG PKG_NAME=SecretsFromVault

# Perform the build
RUN go build -buildmode plugin -o ${PKG_NAME}.so ${PKG_NAME}.go

#--------------------------------------------#
#--------Build Custom Argo Image-------------#
#--------------------------------------------#

FROM argoproj/argocd:$ARGO_CD_VERSION

# Set the kustomize home directory
ENV XDG_CONFIG_HOME=/home/argocd/.config
ENV KUSTOMIZE_PLUGIN_PATH=$XDG_CONFIG_HOME/kustomize/plugin

ARG PKG_NAME=SecretsFromVault

# Copy the plugin to kustomize plugin path
COPY --from=kustomize-kvsource-vault-builder \
  /go/src/github.com/noseka1/kustomize-kvsource-vault/${PKG_NAME}.so \
  $KUSTOMIZE_PLUGIN_PATH/kustomize.config.realgeeks.com/v1beta1/secretsfromvault/

# Switch to root for the ability to perform install
USER root

# Override the default kustomize executable with the Go built version
COPY --from=kustomize-kvsource-vault-builder \
  /go/bin/kustomize /usr/local/bin/kustomize

# Switch back to non-root user
USER argocd
