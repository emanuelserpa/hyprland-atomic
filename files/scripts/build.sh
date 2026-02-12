#!/bin/bash

# 1. Segurança em primeiro lugar:
# -e: para o script se der erro
# -u: erro se usar variável não definida
# -x: mostra o comando que está sendo executado (bom para logs)
# -o pipefail: erro se algum comando no meio de um pipe falhar
set -euxo pipefail

# --- Configuração para zstd:chunked e ComposeFS ---

# 2. Garante que as pastas de configuração existam
mkdir -p /etc/containers
mkdir -p /etc/ostree

# 3. Configura o storage (TOML)
# O EOF tem que estar encostado na esquerda no final do bloco
cat <<EOF > /etc/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
additionalimagestores = [
    "/usr/lib/containers/storage"
]

[storage.options.overlay]
mountopt = "nodev,metacopy=on"

[storage.options.pull_options]
enable_partial_images = true
use_hard_links = true
ostree_repos = "/sysroot/ostree/repo"
EOF

# 4. Habilita o ComposeFS
cat <<EOF > /etc/ostree/prepare-root.conf
[composefs]
enabled = yes
EOF

# --- Otimizações Adicionais ---

# Define ZSH como shell padrão para novos usuários
if [ -f /etc/default/useradd ]; then
    sed -i 's|/bin/bash|/bin/zsh|g' /etc/default/useradd
fi

# Habilita o socket do Podman
systemctl enable podman.socket

echo "Configurações de otimização aplicadas com sucesso!"
