# argocd-kustomize-kvsource-vault
An Argo CD image with a Kustomize secret generator plugin for Vault. 

This repo provides a Dockerfile that builds a custom [Argo CD](https://github.com/argoproj/argo-cd) image. This image includes a custom version of [Kustomize](https://github.com/kubernetes-sigs/kustomize) tool along with the [Kustomize Secret Generator Plugin for Vault](https://github.com/RealGeeks/kustomize-kvsource-vault).


The [custom Argo CD w/ KSOPS Dockerfile](https://github.com/viaduct-ai/kustomize-sops#custom-argo-cd-w-ksops-dockerfile) was used as a base to create the Dockerfile in this repository.
