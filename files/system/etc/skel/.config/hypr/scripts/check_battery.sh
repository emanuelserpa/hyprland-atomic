#!/bin/bash

export LC_ALL=C

# --- CONFIGURAÇÃO PADRÃO GNOME (Adaptada para segurança) ---
# Low: Primeiro aviso (amarelo)
LEVEL_LOW=20
# Critical: Aviso urgente (vermelho) - "Conecte imediatamente"
LEVEL_CRITICAL=10
# Action: AVISO FINAL (vermelho piscante/persistente) - "Vai desligar!"
LEVEL_ACTION=6
# -----------------------------------------------------------

# Obtém dados da bateria
BAT_INFO=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0)
STATUS=$(echo "$BAT_INFO" | grep 'state:' | awk '{print $2}')
PERCENTAGE=$(echo "$BAT_INFO" | grep 'percentage:' | awk '{print $2}' | tr -d '%')

# Se não estiver descarregando, limpa travas e sai
if [[ "$STATUS" != "discharging" ]]; then
    rm -f /tmp/bat_warn_*
    exit 0
fi

# Prepara mensagem de tempo (Informativo, não gatilho)
TIME_LINE=$(echo "$BAT_INFO" | grep 'time to empty')
if [[ -n "$TIME_LINE" ]]; then
    VAL=$(echo "$TIME_LINE" | awk '{print $4}' | tr ',' '.')
    UNIT=$(echo "$TIME_LINE" | awk '{print $5}')
    TIME_MSG="Tempo estimado: ~$VAL $UNIT"
else
    TIME_MSG="Calculando tempo..."
fi

# --- LÓGICA DE 3 NÍVEIS DO GNOME ---

# 1. NÍVEL DE AÇÃO (O "Final" que você queria)
# No GNOME original é 2%, aqui usamos 5% para evitar desligamento súbito
if [[ "$PERCENTAGE" -le "$LEVEL_ACTION" ]]; then
    # -u critical faz a notificação ficar na tela até você clicar
    notify-send -u critical "AÇÃO NECESSÁRIA: $PERCENTAGE%" "O computador desligará em breve!\nConecte o carregador IMEDIATAMENTE."
    exit 0
fi

# 2. NÍVEL CRÍTICO
if [[ "$PERCENTAGE" -le "$LEVEL_CRITICAL" ]]; then
    if [[ ! -f "/tmp/bat_warn_crit" ]]; then
        notify-send -u critical "Bateria Crítica ($PERCENTAGE%)" "Você tem pouca energia restante.\n$TIME_MSG"
        touch "/tmp/bat_warn_crit"
    fi
    exit 0
fi

# 3. NÍVEL BAIXO (Aviso Comum)
if [[ "$PERCENTAGE" -le "$LEVEL_LOW" ]]; then
    if [[ ! -f "/tmp/bat_warn_low" ]]; then
        notify-send -u normal "Bateria Fraca ($PERCENTAGE%)" "$TIME_MSG"
        touch "/tmp/bat_warn_low"
    fi
    exit 0
fi
