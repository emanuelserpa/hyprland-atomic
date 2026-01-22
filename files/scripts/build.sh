#!/bin/bash

# Essa linha faz o script parar se der erro (segurança)
set -ouex pipefail

# --- Otimização para ZSH ---
# Como você instalou o zsh, isso garante que ele seja o padrão
# para qualquer usuário criado no sistema.
sed -i 's|/bin/bash|/bin/zsh|g' /etc/default/useradd

# --- Opcional: Habilitar serviços ---
# Se você quiser garantir que o docker/podman iniciem com o sistema
systemctl enable podman.socket
