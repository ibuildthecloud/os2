FROM opensuse/leap:15.3 as tools
RUN zypper in -y curl docker squashfs xorriso
RUN curl https://get.mocaccino.org/luet/get_luet_root.sh | sh
RUN luet install -y extension/makeiso
COPY tools /

FROM opensuse/leap:15.3
ARG ARCH=amd64
ENV ARCH=${ARCH}
RUN zypper in -y \
    bash-completion \
    conntrack-tools \
    coreutils \
    curl \
    device-mapper \
    dosfstools \
    dracut \
    e2fsprogs \
    findutils \
    gawk \
    grub2-i386-pc \
    grub2-x86_64-efi \
    haveged \
    iproute2 \
    iptables \
    jq \
    kernel-default \
    kernel-firmware-bnx2 \
    kernel-firmware-i915 \
    kernel-firmware-intel \
    kernel-firmware-iwlwifi \
    kernel-firmware-mellanox \
    kernel-firmware-network \
    kernel-firmware-platform \
    kernel-firmware-realtek \
    less \
    lsscsi \
    lvm2 \
    mdadm \
    multipath-tools \
    nano \
    nfs-utils \
    open-iscsi \
    open-vm-tools \
    parted \
    python-azure-agent \
    qemu-guest-agent \
    rng-tools \
    rsync \
    squashfs \
    strace \
    systemd \
    systemd-sysvinit \
    tar \
    timezone \
    vim \
    which

RUN curl -L https://github.com/containerd/nerdctl/releases/download/v0.8.3/nerdctl-0.8.3-linux-${ARCH}.tar.gz | tar xvzf - -C /usr/bin nerdctl
RUN if [ "$ARCH" = "amd64" ]; then ARCH=x86_64; fi && \
    curl -L https://github.com/derailed/k9s/releases/download/v0.24.10/k9s_v0.24.10_Linux_${ARCH}.tar.gz | tar xvzf - -C /usr/bin k9s

RUN zypper ar https://download.opensuse.org/repositories/security:/SELinux/openSUSE_Leap_15.3/security:SELinux.repo
#RUN zypper --gpg-auto-import-keys in -y --allow-vendor-change --allow-downgrade selinux-policy audit selinux-tools python3-policycoreutils policycoreutils-python-utils container-selinux -libsemanage1
RUN zypper --gpg-auto-import-keys in -y --allow-vendor-change --allow-downgrade container-selinux -libsemanage1
#RUN rm /.autorelabel

RUN mkdir /tmp/rpm && \
    cd /tmp/rpm && \
    curl -L -O https://github.com/k3s-io/k3s-selinux/releases/download/v0.3.testing.0/k3s-selinux-0.3-0.el7.noarch.rpm && \
    curl -L -O  https://github.com/rancher/rancher-selinux/releases/download/v0.2-rc1.testing.1/rancher-selinux-0.2.rc1-1.el7.noarch.rpm && \
    mv /var/lib/selinux/targeted/active /var/lib/selinux/targeted/bkp && \
    mv /var/lib/selinux/targeted/bkp /var/lib/selinux/targeted/active && \
    rpm -ivh --nodeps *.rpm && \
    cd / && \
    rm -rf /tmp/rpm


COPY files/etc/luet/luet.yaml /etc/luet/luet.yaml
COPY files/usr/bin/luet /usr/bin/luet

#ENV LUET_VERSION 0.16.5
#RUN curl -sfL -o /usr/bin/luet https://github.com/mudler/luet/releases/download/${LUET_VERSION}/luet-${LUET_VERSION}-linux-${ARCH} && \
    #chmod +x /usr/bin/luet
#COPY luet /usr/bin/luet
#COPY luet.yaml /etc/luet/
RUN luet install -y \
    toolchain/yip \
    utils/installer \
    system/cos-setup \
    system/grub-config

COPY files/ /
RUN mkinitrd

RUN zypper in -y upx && \
    upx -d /usr/bin/yip

ARG OS_NAME=RancherOS
ARG OS_VERSION=999
ARG OS_GIT=dirty
ARG FINALIZE=false
RUN if [ "${FINALIZE}" = "true" ]; then OS_NAME=${OS_NAME} OS_VERSION=${OS_VERSION} OS_GIT=${OS_GIT} /usr/bin/finalize; fi
