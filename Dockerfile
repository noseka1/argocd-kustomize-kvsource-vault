# This Dockerfile is based on the Argo CD w/ KSOPS Dockerfile found at:
# https://github.com/viaduct-ai/kustomize-sops#custom-argo-cd-w-ksops-dockerfile

ARG ARGO_CD_VERSION="v1.3.6"
# Always match Argo CD Dockerfile's Go version!
# https://github.com/argoproj/argo-cd/blob/master/Dockerfile
ARG GO_VERSION="1.12.6"

ARG CUSTOMIZE_VERSION="v3.5.1"

#---------------------------------------------------------------#
#--------Build kustomize-kvsource-vault and Kustomize-----------#
#---------------------------------------------------------------#

FROM golang:$GO_VERSION as kustomize-kvsource-vault-builder

# Match Argo CD's build
ENV GOOS=linux
ENV GOARCH=amd64
ENV GO111MODULE=on

ARG PKG_NAME=SecretsFromVault

WORKDIR /go/src/github.com/RealGeeks/

RUN git clone https://github.com/RealGeeks/kustomize-kvsource-vault.git

# CD into the clone repo
WORKDIR /go/src/github.com/RealGeeks/kustomize-kvsource-vault

# Perform the build
#RUN go install
RUN go build -buildmode plugin -o ${PKG_NAME}.so ${PKG_NAME}.go

# Install kustomize via Go
RUN go get sigs.k8s.io/kustomize/kustomize/v3@kustomize/${CUSTOMIZE_VERSION}

#--------------------------------------------#
#--------Build Custom Argo Image-------------#
#--------------------------------------------#

FROM argoproj/argocd:$ARGO_CD_VERSION

# Switch to root for the ability to perform install
USER root

# Set the kustomize home directory
ENV XDG_CONFIG_HOME=$HOME/.config
ENV KUSTOMIZE_PLUGIN_PATH=$XDG_CONFIG_HOME/kustomize/plugin/

ARG PKG_NAME=secretsfromvault

# Override the default kustomize executable with the Go built version
COPY --from=kustomize-kvsource-vault-builder \
  /go/bin/kustomize /usr/local/bin/kustomize

# Copy the plugin to kustomize plugin path
COPY --from=kustomize-kvsource-vault-builder \
  /go/src/github.com/RealGeeks/kustomize-kvsource-vault/* $KUSTOMIZE_PLUGIN_PATH/kustomize.config.realgeeks.com/v1beta1/${PKG_NAME}/

# Switch back to non-root user
USER argocd
