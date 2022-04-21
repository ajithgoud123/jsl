#!/usr/bin/env bash
set -euo pipefail
if [[ -f /etc/redhat-release ]]; then
      if [[ $(cat /etc/redhat-release) =~ ^Red  ]]; then
            systemctl stop nm-cloud-setup.service nm-cloud-setup.timer
            systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
            sed -i '/^#/! s/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
      fi
fi
export INSTALL_K3S_VERSION=v1.22.4+k3s1
export INSTALL_K3S_BIN_DIR=/usr/local/bin
if [[ $PATH != *"/usr/local/bin"* ]]; then
    export INSTALL_K3S_BIN_DIR=/usr/bin
fi
if [[ ! $(grep -q '^nameserver 127.0.0.53$' /etc/resolv.conf ) ]]; then
    if [[ -f /run/systemd/resolve/resolv.conf ]]; then
        export K3S_RESOLV_CONF=/run/systemd/resolve/resolv.conf
    fi
fi
curl -sfL https://get.k3s.io | sh
echo -e "\033[1mKubernetes\033[0m:"
kubectl version
HELM_VER=v3.3.1
curl -s -L https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz -o- | tar -C "${INSTALL_K3S_BIN_DIR}" -x linux-amd64/helm -zf- --strip-components=1
echo -en "\033[1mHelm\033[0m: "
helm version

if [[ -f /etc/redhat-release ]]; then
      if [[ $(cat /etc/redhat-release) =~ ^Red  ]]; then
          reboot
      fi
fi
