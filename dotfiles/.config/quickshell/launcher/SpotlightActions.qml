import QtQuick
import Quickshell
import qs.services

// Etapa 1 do fatiamento do Spotlight: construção das ações de `:`.
// O Spotlight continua dono da janela, da consulta, da filtragem,
// da seleção, da execução e dos atalhos; este módulo só monta os itens.
QtObject {
    id: root

    required property var palette

    readonly property color cPink: palette.pink
    readonly property color cYellow: palette.yellow
    readonly property color cGreen: palette.green
    readonly property color cCyan: palette.cyan
    readonly property color cOrange: palette.orange
    readonly property color cRed: palette.red
    readonly property color cSecondary: palette.offWhite

    function configCategories() {
        const themeName = ThemeState.palette?.name ?? ThemeState.currentTheme
        const nlStatus = NightLightState.enabled ? ("Ativa (" + NightLightState.nightTemp + "K)") : "Desativada"
        const pLabel = PowerProfileState.activeLabel ?? "Equilibrado"
        const idleStatus = IdleState.inhibited ? "Cafeína ativa" : "Padrão"

        return [
            {
                kind: "config_category",
                prefix: ":tema ",
                title: "Aparência & Temas",
                subtitle: "Tema ativo: " + themeName + " · Enter para listar temas",
                icon: "󰔎",
                color: root.cPink
            },
            {
                kind: "config_category",
                prefix: ":tela ",
                title: "Tela & Energia",
                subtitle: "Luz noturna: " + nlStatus + " · " + pLabel + " · " + idleStatus,
                icon: "󰛨",
                color: root.cYellow
            },
            {
                kind: "config_category",
                prefix: ":conexoes ",
                title: "Conexões & Áudio",
                subtitle: "Wi-Fi, Bluetooth, Mixer de Som · Enter para opções",
                icon: "󰤨",
                color: root.cCyan
            },
            {
                kind: "config_category",
                prefix: ":sistema ",
                title: "Sistema & Sessão",
                subtitle: "Atualizações, bloquear, sair, reiniciar · Enter para opções",
                icon: "󰒓",
                color: root.cOrange
            }
        ]
    }

    function themeActions() {
        const wpPickItem = {
            kind: "wp_pick",
            title: "Escolher Papel de Parede...",
            subtitle: "Abrir seletor gráfico e gerar cores dinâmicas",
            icon: "󰈔",
            color: root.cPink
        }
        const wpRandomItem = {
            kind: "wp_random",
            title: "Papel de Parede Aleatório",
            subtitle: "Sortear imagem e sincronizar tema",
            icon: "",
            color: root.cGreen
        }
        const cycleItem = {
            kind: "theme_cycle",
            title: "Alternar para o Próximo Tema",
            subtitle: "Ciclar temas (atual: " + (ThemeState.palette?.name ?? ThemeState.currentTheme) + ")",
            icon: "󰔎",
            color: root.cPink
        }
        const sortedList = (ThemeState.themesList ?? []).slice().sort((a, b) => (a.name ?? "").localeCompare(b.name ?? "", undefined, { sensitivity: "base" }))
        const themeList = sortedList.map(t => {
            const isCurrent = (t.id === ThemeState.currentTheme)
            let sub = "Tema " + (t.category === "light" ? "claro" : "escuro")
            if (isCurrent) {
                const adapters = ThemeState.syncedAdapters ?? {}
                const gh = adapters.ghostty ? "Ghostty ✓" : "Ghostty –"
                const hl = adapters.hyprland ? "Hyprland ✓" : "Hyprland –"
                const lk = adapters.hyprlock ? "Hyprlock ✓" : "Hyprlock –"
                sub += " (ativo · Shell ✓ · " + gh + " · " + hl + " · " + lk + ")"
            } else {
                sub += " · Enter para aplicar globalmente"
            }
            return {
                kind: "theme_select",
                themeId: t.id,
                accent: t.accent,
                title: t.name + (isCurrent ? "  ✓" : ""),
                subtitle: sub,
                icon: "󰔎",
                color: t.accent ?? root.cPink
            }
        })
        return [wpPickItem, wpRandomItem, cycleItem].concat(themeList)
    }

    function nightlightActions() {
        return [
            {
                kind: "nightlight_toggle",
                title: NightLightState.enabled ? "Desativar Luz Noturna" : "Ativar Luz Noturna",
                subtitle: NightLightState.enabled
                    ? "Luz noturna ativa · " + (NightLightState.city.length > 0 ? NightLightState.city : "Solar") + " (" + NightLightState.nightTemp + "K)"
                    : "Luz noturna desligada · Horário solar de " + (NightLightState.city.length > 0 ? NightLightState.city : "clima") + " (Pôr: " + NightLightState.sunset + ")",
                icon: NightLightState.enabled ? "󰛨" : "󰛩",
                color: root.cYellow
            },
            {
                kind: "nightlight_set",
                val: true,
                title: "Forçar Ativação da Luz Noturna",
                subtitle: "Ligar hyprsunset/wlsunset imediatamente",
                icon: "󰛨",
                color: root.cYellow
            },
            {
                kind: "nightlight_set",
                val: false,
                title: "Desativar Luz Noturna",
                subtitle: "Desligar filtro de temperatura",
                icon: "󰛩",
                color: root.cYellow
            }
        ]
    }

    function energyActions() {
        const curProfile = PowerProfileState.activeProfile
        return [
            {
                kind: "idle_toggle",
                title: IdleState.inhibited ? "Desativar Cafeína" : "Ativar Cafeína (Inibidor de Suspensão)",
                subtitle: IdleState.inhibited
                    ? "Tela não apagará · Enter para voltar ao modo padrão"
                    : "Impedir tela de apagar ou suspender por inatividade",
                icon: IdleState.inhibited ? "󰅶" : "󰾪",
                color: IdleState.inhibited ? root.cGreen : root.cSecondary
            },
            {
                kind: "power_profile",
                profile: "performance",
                title: "Modo Desempenho (Performance)" + (curProfile === "performance" ? "  ✓" : ""),
                subtitle: "Frequências máximas, alta performance" + (curProfile === "performance" ? " (ativo)" : ""),
                icon: "󰓅",
                color: root.cGreen
            },
            {
                kind: "power_profile",
                profile: "balanced",
                title: "Modo Equilibrado (Balanceado)" + (curProfile === "balanced" ? "  ✓" : ""),
                subtitle: "Equilíbrio padrão entre economia e velocidade" + (curProfile === "balanced" ? " (ativo)" : ""),
                icon: "󰾆",
                color: root.cGreen
            },
            {
                kind: "power_profile",
                profile: "power-saver",
                title: "Modo Economia de Energia" + (curProfile === "power-saver" ? "  ✓" : ""),
                subtitle: "Reduz clock da CPU e economiza bateria" + (curProfile === "power-saver" ? " (ativo)" : ""),
                icon: "󰌪",
                color: root.cGreen
            }
        ]
    }

    function connectionActions() {
        return [
            {
                kind: "app_exec",
                command: ["nm-connection-editor"],
                title: "Configurações de Rede & Wi-Fi",
                subtitle: "Abrir gerenciador de conexões (nm-connection-editor)",
                icon: "󰤨",
                color: root.cCyan
            },
            {
                kind: "app_exec",
                command: ["blueberry"],
                title: "Dispositivos Bluetooth",
                subtitle: "Abrir painel de pareamento e conexões Bluetooth",
                icon: "󰂯",
                color: root.cCyan
            },
            {
                kind: "app_exec",
                command: ["pwvucontrol"],
                title: "Mixer de Áudio & Volume",
                subtitle: "Controle de canais, fontes e saídas PipeWire (pwvucontrol)",
                icon: "󰕾",
                color: root.cCyan
            }
        ]
    }

    function systemActionsList() {
        return [
            {
                kind: "restart_quickshell",
                title: "Reiniciar Quickshell",
                subtitle: "Recarregar barra, serviços e popups instantaneamente",
                icon: "󰑓",
                color: root.cOrange
            },
            {
                kind: "app_exec",
                command: ["kitty", "-e", "htop"],
                title: "Monitor de Recursos do Sistema",
                subtitle: "Abrir monitor de processos htop no terminal Kitty",
                icon: "󰍹",
                color: root.cOrange
            }
        ]
    }

    function sessionActions() {
        return [
            {
                kind: "system",
                title: "Bloquear Sessão",
                subtitle: "Bloquear a tela imediatamente",
                icon: "󰌾",
                color: root.cRed,
                command: [Quickshell.shellDir + "/scripts/session-action.sh", "lock"]
            },
            {
                kind: "system",
                title: "Suspender",
                subtitle: "Suspender o computador (dormir)",
                icon: "󰤄",
                color: root.cRed,
                command: [Quickshell.shellDir + "/scripts/session-action.sh", "suspend"]
            },
            {
                kind: "system",
                title: "Sair da Sessão",
                subtitle: "Fechar aplicativos e encerrar sessão gráfica",
                icon: "󰗼",
                color: root.cRed,
                command: [Quickshell.shellDir + "/scripts/session-action.sh", "logout"]
            },
            {
                kind: "system",
                title: "Reiniciar Computador",
                subtitle: "Reinicializar o sistema operacional",
                icon: "󰜉",
                color: root.cRed,
                command: [Quickshell.shellDir + "/scripts/session-action.sh", "reboot"]
            },
            {
                kind: "system",
                title: "Desligar Computador",
                subtitle: "Fechar aplicativos e desligar o computador",
                icon: "󰐥",
                color: root.cRed,
                command: [Quickshell.shellDir + "/scripts/session-action.sh", "poweroff"]
            },
            {
                kind: "system",
                title: "Gravar Tela",
                subtitle: "Tela inteira, sem áudio (wf-recorder)",
                icon: "󰕧",
                color: root.cRed,
                command: ["python3", "-B", Quickshell.shellDir + "/scripts/screen-recording.py", "start", "screen"]
            },
            {
                kind: "system",
                title: "Gravar Tela com Áudio",
                subtitle: "Tela inteira + áudio do sistema/mic (wf-recorder)",
                icon: "󰕾",
                color: root.cRed,
                command: ["python3", "-B", Quickshell.shellDir + "/scripts/screen-recording.py", "start", "screen", "--audio"]
            },
            {
                kind: "system",
                title: "Screenshot de Área",
                subtitle: "Selecionar região e copiar PNG (grim + slurp)",
                icon: "󰹑",
                color: root.cCyan,
                command: [Quickshell.shellDir + "/scripts/screenshot.sh", "area"]
            }
        ]
    }

    function allSettingsActions() {
        return [].concat(
            themeActions(),
            nightlightActions(),
            energyActions(),
            connectionActions(),
            systemActionsList(),
            sessionActions()
        )
    }

    function systemActions() {
        return allSettingsActions()
    }
}
