ARG ALPINE_VERSION="3.15"
ARG TRIVY_VERSION="0.21.1"

FROM alpine:$ALPINE_VERSION AS download-base
WORKDIR /downloads
RUN echo "$(apk --print-arch)" > /arch.txt 
RUN ARCH2= && alpineArch="$(apk --print-arch)" \
    && case "${alpineArch##*-}" in \
    x86_64) ARCH2='amd64' ;; \
    aarch64) ARCH2='arm64' ;; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    echo $ARCH2 > /arch2.txt 

FROM download-base
ARG CRICTL_VERSION="v1.24.1"
RUN wget -O crictl.tar.gz "https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$(cat /arch2.txt).tar.gz" && \
    tar zxvf crictl.tar.gz -C /usr/local/bin
    
WORKDIR /
