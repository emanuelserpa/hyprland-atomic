-- hyprland.lua
-- Migração curada de hyprlang -> Lua para Hyprland >= 0.55.
-- Base: ~/.config/hypr/hyprland.conf fornecido em 2026-08-19.
--
-- Princípios desta migração:
--   * usa APIs Lua nativas (hl.config, hl.monitor, hl.device, hl.window_rule,
--     hl.bind, hl.define_submap, hl.on);
--   * elimina repetições com loops;
--   * mantém a ordem das window rules;
--   * deixa variáveis de ambiente para UWSM (~/.config/uwsm/env);
--   * usa apenas um fallback via hyprctl para o combo "exact 90% 90%",
--     pois ele não tem uma equivalência Lua percentual claramente documentada.

local HOME = assert(os.getenv("HOME"), "HOME is required")

------------------
---- MONITOR -----
------------------

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60.05",
    position = "0x0",
    scale = 1.2,
})

--------------------
---- PROGRAMAS -----
--------------------

local browser = "flatpak run app.zen_browser.zen"
local terminal = "ghostty"
local fileManager = "nemo"
local copyq = "copyq toggle"
local menu = "wofi --show drun"

---------------------
---- CONFIG BASE ----
---------------------

hl.config({
    input = {
        kb_layout = "br",
        kb_variant = "thinkpad",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,

        touchpad = {
            tap_to_click = true,
            tap_and_drag = true,

            -- 1 dedo = esquerdo
            -- 2 dedos = direito
            -- 3 dedos = meio
            tap_button_map = "lrm",

            -- Se você clicar fisicamente sem querer,
            -- o botão depende da quantidade de dedos,
            -- não da região inferior do touchpad.
            clickfinger_behavior = true,

            -- Mantém o arrasto por um curto tempo se você levantar o dedo.
            -- Isso facilita drag sem precisar afundar o clickpad.
            drag_lock = 1,

            disable_while_typing = true,
            natural_scroll = false,

            scroll_factor = 1.0,
        }
    },

    general = {
        gaps_in = 3,

        -- O antigo "3/sw" não é um valor css_gaps válido na API Lua atual.
        -- Normalizado para 3; veja as notas de migração.
        gaps_out = 3,

        border_size = 1,

        col = {
            active_border = {
                colors = { "rgba(ff80bfaa)" },
                angle = 45,
            },
            inactive_border = "rgba(282a36aa)",
        },

        layout = "dwindle",
        allow_tearing = false,
    },

    decoration = {
        rounding = 10,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            new_optimizations = true,
            ignore_opacity = true,
        },

        screen_shader = HOME .. "/.config/hypr/shaders/vibrance2.glsl",
    },

    group = {
        groupbar = {
            height = 16,
            font_size = 11,
            text_color = 0xffffffff,

            col = {
                active = "rgba(68479daa)",
                inactive = "rgba(282a36ee)",
            },

            gradients = true,
            gaps_in = 1,
            gaps_out = 0,
            keep_upper_gap = false,

            gradient_rounding = 0,
            gradient_round_only_edges = false,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper = -1,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-------------------
---- DISPOSITIVOS --
-------------------

hl.device({
    name = "tpps/2-elan-trackpoint",
    sensitivity = 0.2,
    accel_profile = "adaptive",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-------------------
---- ANIMAÇÕES ----
-------------------

hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 },
    },
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 7,
    bezier = "default",
    style = "popin 80%",
})

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "default",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 8,
    bezier = "default",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 7,
    bezier = "default",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 6,
    bezier = "default",
})

-- O hyprlang antigo usava "slidefade top/bottom".
-- A API/documentação atual expõe slidefadevert para special workspaces.
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 3,
    bezier = "default",
    style = "slidefadevert",
})

hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 3,
    bezier = "default",
    style = "slidefadevert",
})

----------------------
---- WINDOW RULES ----
----------------------

-- ============================================================
-- FLOATS ESPECIAIS
-- ============================================================

-- CopyQ: janela utilitária, sempre floating.
hl.window_rule({
    name = "copyq-float",
    match = {
        class = [[^(com\.github\.hluk\.copyq)$]],
    },
    float = true,
    size = { 675, 710 },
    group = "deny",
    stay_focused = true,
    dim_around = true,
})


-- File picker GTK / portal.
hl.window_rule({
    name = "gtk-file-picker",
    match = {
        class = [[^(xdg-desktop-portal-gtk)$]],
    },
    float = true,
    center = true,
    size = { 900, 600 },
})


-- Ghostty quake / scratchpad.
hl.window_rule({
    name = "quake-terminal",
    match = {
        title = [[^(ghostty-quake)$]],
    },
    workspace = "special:scratchpad silent",
    float = true,
    no_blur = true,
    center = true,
    size = { 1000, 500 },
    rounding = 0,
    border_size = 1,
})


-- Loupe: visualizador de imagens funciona melhor como janela.
hl.window_rule({
    name = "loupe-float",
    match = {
        class = [[^(org\.gnome\.Loupe)$]],
    },
    float = true,
    center = true,
    size = { 1000, 750 },
})


-- ============================================================
-- PEQUENOS UTILITÁRIOS
-- ============================================================

-- Controle de áudio PipeWire.
hl.window_rule({
    name = "pwvucontrol-float",
    match = {
        class = [[^(com\.saivert\.pwvucontrol|pwvucontrol)$]],
    },
    float = true,
    center = true,
    size = { 850, 600 },
})


-- Editor de conexões do NetworkManager.
hl.window_rule({
    name = "nm-connection-editor-float",
    match = {
        class = [[^(nm-connection-editor)$]],
    },
    float = true,
    center = true,
    size = { 900, 650 },
})


-- Blueberry.
hl.window_rule({
    name = "blueberry-float",
    match = {
        class = [[(?i)^(blueberry|blueberry\.py)$]],
    },
    float = true,
    center = true,
    size = { 800, 600 },
})


-- Configuração GTK.
hl.window_rule({
    name = "nwg-look-float",
    match = {
        class = [[^(nwg-look)$]],
    },
    float = true,
    center = true,
    size = { 800, 600 },
})


-- Configuração Qt.
hl.window_rule({
    name = "qt6ct-float",
    match = {
        class = [[^(qt6ct)$]],
    },
    float = true,
    center = true,
    size = { 850, 650 },
})


-- Fcitx.
hl.window_rule({
    name = "fcitx-config-float",
    match = {
        class = [[(?i).*(fcitx5-config|fcitx5-config-qt).*]],
    },
    float = true,
    center = true,
    size = { 850, 650 },
})


-- Gerenciador de arquivos compactados GNOME.
hl.window_rule({
    name = "file-roller-float",
    match = {
        class = [[^(org\.gnome\.FileRoller|file-roller)$]],
    },
    float = true,
    center = true,
    size = { 900, 650 },
})


-- Waypaper.
hl.window_rule({
    name = "waypaper-float",
    match = {
        class = [[(?i)^(waypaper)$]],
    },
    float = true,
    center = true,
    size = { 1000, 700 },
})


-- Configuração de monitores.
hl.window_rule({
    name = "nwg-displays-float",
    match = {
        class = [[^(nwg-displays)$]],
    },
    float = true,
    center = true,
    size = { 1000, 700 },
})


-- ============================================================
-- NEMO
-- ============================================================

-- A janela normal continua tiled.
-- Apenas Properties/Propriedades vira floating.
hl.window_rule({
    name = "nemo-properties-float",
    match = {
        class = [[^(nemo)$]],
        title = [[(?i).*(properties|propriedades).*]],
    },
    float = true,
    center = true,
    size = { 800, 600 },
})


-- ============================================================
-- ZEN
-- ============================================================

-- Picture-in-Picture não deve entrar no tiling.
hl.window_rule({
    name = "zen-pip-float",
    match = {
        class = [[^(zen)$]],
        title = [[(?i)^(picture-in-picture|picture in picture|imagem em imagem)$]],
    },
    float = true,
    size = { 640, 360 },
})


-- ============================================================
-- STEAM
-- ============================================================

-- A Steam principal fica tiled.
-- Janelas secundárias ficam floating.
hl.window_rule({
    name = "steam-popups-and-chats",
    match = {
        class = [[^(steam)$]],
        title = [[(?i).*(friends list|lista de amigos|news|novidades|chat|conversa|settings|configurações|uploader|capturas|properties|propriedades).*]],
    },
    float = true,
    center = true,
})


-- ============================================================
-- IDLE INHIBIT
-- ============================================================

hl.window_rule({
    name = "idle-inhibit-fullscreen",
    match = {
        class = [[.*]],
    },
    idle_inhibit = "fullscreen",
})


-- ============================================================
-- WORKSPACES
-- ============================================================

-- Browser.
hl.window_rule({
    name = "zen-workspace",
    match = {
        class = [[^(zen)$]],
    },
    workspace = "1 silent",
})


-- Terminal normal.
-- O quake-terminal já é capturado anteriormente.
hl.window_rule({
    name = "ghostty-workspace",
    match = {
        class = [[^(com\.mitchellh\.ghostty)$]],
        initial_title = [[^(Ghostty)$]],
    },
    workspace = "2 silent",
})

-- Telegram.
hl.window_rule({
    name = "telegram-workspace",
    match = {
        class = [[^(org\.telegram\.desktop)$]],
    },
    workspace = "3 silent",
})


-- Discord Flatpak.
hl.window_rule({
    name = "discord-workspace",
    match = {
        class = [[^(discord)$]],
    },
    workspace = "3 silent",
})


-- WhatsApp / ElecWhat.
hl.window_rule({
    name = "elecwhat-workspace",
    match = {
        class = [[^(elecwhat)$]],
    },
    workspace = "3 silent",
})


-- Firefox PWA que você já usava.
hl.window_rule({
    name = "ffpwa-workspace",
    match = {
        initial_class = [[^(FFPWA-01KT27Z97VTPNPNTXCDY7EZZ9A)$]],
    },
    workspace = "3 silent",
})


-- Spotify.
hl.window_rule({
    name = "spotify-workspace",
    match = {
        class = [[^(spotify)$]],
    },
    workspace = "4 silent",
})

-- Qalculate!
hl.window_rule({
    name = "qalculate-float",
    match = {
        class = [[^(qalculate-gtk)$]],
    },
    float = true,
    center = true,
    size = { 560, 460 },
})

-- Stremio.
hl.window_rule({
    name = "stremio-workspace",
    match = {
        class = [[(?i).*stremio.*]],
    },
    workspace = "4 silent",
})


-- Nemo.
hl.window_rule({
    name = "nemo-workspace",
    match = {
        class = [[^(nemo)$]],
    },
    workspace = "5 silent",
})


-- Steam.
hl.window_rule({
    name = "steam-workspace",
    match = {
        class = [[^(steam)$]],
    },
    workspace = "8 silent",
})


-- Jogos iniciados pela Steam.
hl.window_rule({
    name = "steam-games-workspace",
    match = {
        class = [[^(steam_app_\d+)$]],
    },
    workspace = "8",
})


-- VS Code.
hl.window_rule({
    name = "vscode-workspace",
    match = {
        class = [[^(code|Code)$]],
    },
    workspace = "9 silent",
})


-- ============================================================
-- APP-SPECIFIC WORKAROUNDS
-- ============================================================

-- Telegram às vezes tenta manipular maximize/fullscreen sozinho.
hl.window_rule({
    name = "telegram-suppress-events",
    match = {
        class = [[^(org\.telegram\.desktop)$]],
    },
    suppress_event = "maximize fullscreen",
})

----------------
---- BINDS -----
----------------

local mainMod = "SUPER"

-- Aplicativos / ações básicas
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(copyq))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("rofimoji --selector wofi"))

-- Com UWSM, encerra a sessão de forma ordenada.
hl.bind(mainMod .. " + SHIFT + BackSpace", hl.dsp.exec_cmd("uwsm stop"))

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Toggle floating inteligente.
-- Ao sair do tiling:
--   1. torna a janela floating;
--   2. redimensiona para 90% do monitor ativo;
--   3. centraliza.
-- Ao voltar para tiled, não força resize/center, deixando o layout
-- reorganizar a janela normalmente.
local function toggleFloat90()
    local client = hl.get_active_window()
    if client == nil then
        return
    end

    local monitor = hl.get_active_monitor()
    local wasTiled = not client.floating

    hl.dispatch(hl.dsp.window.float({
        action = "toggle",
        window = client,
    }))

    if wasTiled and monitor ~= nil then
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(monitor.width * 0.70),
            y = math.floor(monitor.height * 0.70),
            relative = false,
            window = client,
        }))

        hl.dispatch(hl.dsp.window.center({
            window = client,
        }))
    end
end

-- Mantém o atalho que existia no seu hyprland.conf:
-- SUPER + SHIFT + SPACE
hl.bind(
    mainMod .. " + SHIFT + Space",
    toggleFloat90,
    { description = "Toggle floating 90% centered" }
)

-- E adiciona o atalho que você chamou de CTRL + MOD + SPACE:
-- CTRL + SUPER + SPACE
hl.bind(
    mainMod .. " + CTRL + Space",
    toggleFloat90,
    { description = "Toggle floating 90% centered" }
)

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())

-- hyprtabs v0.4.1
-- Porta nativa em Lua de:
-- https://github.com/thiagokokada/hyprland-go/blob/v0.4.1/examples/hyprtabs/main.go
--
-- Group all windows in the current workspace, or ungroup, como um
-- container "tabbed" do i3/sway.
local function hyprtabs()
    local activeWindow = hl.get_active_window()
    if activeWindow == nil then
        return
    end

    -- Usa o workspace especial quando houver um ativo; caso contrário,
    -- usa o workspace normal. "tiled_layout" informa o layout corrente.
    local activeWorkspace =
        hl.get_active_special_workspace() or hl.get_active_workspace()

    if activeWorkspace == nil then
        return
    end

    local isMaster = activeWorkspace.tiled_layout == "master"

    -- O hyprland-go antigo recebia um array "Grouped".
    -- Na API Lua atual, Window.group é nil quando a janela não está agrupada.
    if activeWindow.group ~= nil then
        -- Se já estamos em um grupo, desfaz o grupo.
        hl.dispatch(hl.dsp.group.toggle({ window = activeWindow }))

        -- O fonte Go original só precisava disto para o layout master.
        -- Em dwindle, "swapwithmaster" não existe e gera Runtime error.
        if isMaster then
            hl.dispatch(hl.dsp.layout("swapwithmaster master"))
        end

        return
    end

    -- Equivalente ao Clients() + filtro por Workspace.Id do programa Go.
    -- A API Lua já faz o filtro dentro do compositor.
    local windows = hl.get_workspace_windows(activeWorkspace)
    if windows == nil then
        return
    end

    -- Start by creating a new group.
    hl.dispatch(hl.dsp.group.toggle({ window = activeWindow }))

    local directions = { "left", "right", "up", "down" }

    for _, window in ipairs(windows) do
        -- O fonte original repete TODO o bloco duas vezes. Isso é proposital:
        -- uma tentativa pode não bastar em layouts dwindle muito profundos.
        for _ = 1, 2 do
            -- Equivalente a: focuswindow address:<w>
            hl.dispatch(hl.dsp.focus({ window = window }))

            -- O Go original fazia isto sempre, mas o comentário dele deixa
            -- claro que é uma ajuda específica para o layout master.
            -- Em dwindle isso só produz "Unknown dwindle layoutmsg".
            if isMaster then
                hl.dispatch(hl.dsp.layout("swapwithmaster auto"))
            end

            -- Equivalente às quatro chamadas moveintogroup do original.
            for _, direction in ipairs(directions) do
                hl.dispatch(hl.dsp.window.move({
                    into_group = direction,
                    window = window,
                }))
            end
        end
    end

    -- Focus in the active window at the end.
    hl.dispatch(hl.dsp.focus({ window = activeWindow }))
end

hl.bind(
    mainMod .. " + W",
    hyprtabs,
    { description = "Agrupar/desagrupar workspace em tabs" }
)

-- Evita empilhar uma segunda instância do hyprlock.
hl.bind(
    mainMod .. " + SHIFT + L",
    hl.dsp.exec_cmd("playerctl -a pause; pidof hyprlock >/dev/null || hyprlock")
)

hl.bind( mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Toggle inteligente do terminal Quake / Scratchpad.
-- Se o ghostty-quake não estiver em execução, inicia uma nova instância.
-- Se já estiver rodando, apenas alterna a visibilidade sem criar processos duplicados.
local function toggleQuake()
    local windows = hl.get_windows()
    local exists = false

    if windows ~= nil then
        for _, window in ipairs(windows) do
            if window.title == "ghostty-quake" then
                exists = true
                break
            end
        end
    end

    if not exists then
        hl.exec_cmd([[ghostty --title="ghostty-quake"]])
    end

    hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
end

hl.bind(mainMod .. " + Escape", toggleQuake, { description = "Toggle Quake terminal" })
hl.bind(mainMod .. " + code:49", toggleQuake, { description = "Toggle Quake terminal" })
-- Kill App integrado ao Lua.
--
-- Consulta o Hyprland nativamente com hl.get_windows(). Wofi e a busca de
-- ícones rodam fora do callback via hl.exec_cmd(), para não bloquear o
-- event loop do compositor.
local function shellQuote(value)
    local text = tostring(value or "")
    return "'" .. text:gsub("'", "'\"'\"'") .. "'"
end

local function sanitizeMenuText(value)
    return tostring(value or "")
        :gsub("[\r\n\t]", " ")
        :gsub("%s%s+", " ")
end

local function killApp()
    local windows = hl.get_windows()

    if windows == nil or #windows == 0 then
        return
    end

    local pids = {}
    local classes = {}
    local titles = {}

    for _, window in ipairs(windows) do
        local pid = tonumber(window.pid)

        if pid ~= nil and pid > 0 then
            pids[#pids + 1] = shellQuote(math.floor(pid))
            classes[#classes + 1] = shellQuote(
                sanitizeMenuText(window.class or "unknown")
            )
            titles[#titles + 1] = shellQuote(
                sanitizeMenuText(window.title or "")
            )
        end
    end

    if #pids == 0 then
        return
    end

    local script =
        "pids=(" .. table.concat(pids, " ") .. ")\n" ..
        "classes=(" .. table.concat(classes, " ") .. ")\n" ..
        "titles=(" .. table.concat(titles, " ") .. ")\n" ..
        [=[
set -u

CURRENT_THEME="hicolor"
settings="$HOME/.config/gtk-3.0/settings.ini"

if [[ -r "$settings" ]]; then
    while IFS='=' read -r key value; do
        key="${key//[[:space:]]/}"

        if [[ "$key" == "gtk-icon-theme-name" ]]; then
            value="${value//[[:space:]]/}"
            [[ -n "$value" ]] && CURRENT_THEME="$value"
            break
        fi
    done < "$settings"
fi

declare -A MAN_FIXES=(
    ["smartcode-stremio"]="com.stremio.Stremio"
    ["com.stremio.stremio"]="com.stremio.Stremio"
    ["Stremio"]="com.stremio.Stremio"
    ["com.github.rafostar.Clapper"]="com.github.rafostar.Clapper"
)

declare -A ICON_CACHE=()

find_icon() {
    local class="$1"

    if [[ -n "${ICON_CACHE[$class]+present}" ]]; then
        printf '%s' "${ICON_CACHE[$class]}"
        return
    fi

    local names=("$class" "${class,,}")

    if [[ -n "${MAN_FIXES[$class]+present}" ]]; then
        names+=("${MAN_FIXES[$class]}")
    fi

    if [[ "$class" == *.* ]]; then
        local dotted="${class##*.}"
        names+=("${dotted,,}")
    fi

    if [[ "$class" == *-* ]]; then
        local dashed="${class##*-}"
        names+=("${dashed,,}")
    fi

    local paths=(
        "$HOME/.local/share/icons/$CURRENT_THEME"
        "/usr/share/icons/$CURRENT_THEME"
        "$HOME/.local/share/icons/hicolor"
        "/usr/share/icons/hicolor"
        "$HOME/.local/share/flatpak/exports/share/icons/hicolor"
        "/var/lib/flatpak/exports/share/icons/hicolor"
        "/usr/share/pixmaps"
    )

    local sizes=(
        "48x48/apps"
        "scalable/apps"
        "apps"
        "256x256/apps"
        "128x128/apps"
    )

    local path name size candidate found

    for path in "${paths[@]}"; do
        [[ -d "$path" ]] || continue

        for name in "${names[@]}"; do
            for size in "${sizes[@]}"; do
                candidate="$path/$size/$name.svg"
                if [[ -f "$candidate" ]]; then
                    ICON_CACHE[$class]="$candidate"
                    printf '%s' "$candidate"
                    return
                fi

                candidate="$path/$size/$name.png"
                if [[ -f "$candidate" ]]; then
                    ICON_CACHE[$class]="$candidate"
                    printf '%s' "$candidate"
                    return
                fi
            done
        done
    done

    for path in "${paths[@]}"; do
        [[ -d "$path" ]] || continue

        for name in "${names[@]}"; do
            found="$(
                find "$path" -maxdepth 4 \
                    \( -iname "$name.svg" -o -iname "$name.png" \) \
                    -print -quit 2>/dev/null
            )"

            if [[ -n "$found" ]]; then
                ICON_CACHE[$class]="$found"
                printf '%s' "$found"
                return
            fi
        done
    done

    ICON_CACHE[$class]=""
}

window_list=""

for ((i = 0; i < ${#pids[@]}; i++)); do
    pid="${pids[$i]}"
    class="${classes[$i]}"
    title="${titles[$i]}"
    icon_path="$(find_icon "$class")"

    if [[ -n "$icon_path" ]]; then
        line="img:${icon_path}:text:${pid} ${class} - ${title}"
    else
        line="text:${pid} ${class} - ${title}"
    fi

    if [[ -z "$window_list" ]]; then
        window_list="$line"
    else
        window_list+=$'\n'"$line"
    fi
done

[[ -n "$window_list" ]] || exit 0

selected="$(
    printf '%s\n' "$window_list" |
        wofi --dmenu --allow-images -p "Kill App" -i
)"

[[ -n "$selected" ]] || exit 0

case "$selected" in
    img:*:text:*)
        selected="${selected#*:text:}"
        ;;
    text:*)
        selected="${selected#text:}"
        ;;
esac

pid="${selected%% *}"

case "$pid" in
    ''|*[!0-9]*)
        exit 0
        ;;
esac

kill -9 -- "$pid"
]=]

    hl.exec_cmd("bash -c " .. shellQuote(script))
end

hl.bind(
    mainMod .. " + K",
    killApp,
    { description = "Kill app via Wofi" }
)
-----------------------
---- FOCO / JANELAS ---
-----------------------

-- No .conf original, esquerda/direita tinham changegroupactive + movefocus,
-- enquanto cima/baixo tinham somente movefocus. Mantemos essa diferença
-- explicitamente em vez de ativar movefocus_cycles_groupfirst globalmente.
local function focusLeft()
    local window = hl.get_active_window()

    if window ~= nil and window.group ~= nil then
        hl.dispatch(hl.dsp.group.prev({ window = window }))
        return
    end

    hl.dispatch(hl.dsp.focus({ direction = "left" }))
end

local function focusRight()
    local window = hl.get_active_window()

    if window ~= nil and window.group ~= nil then
        hl.dispatch(hl.dsp.group.next({ window = window }))
        return
    end

    hl.dispatch(hl.dsp.focus({ direction = "right" }))
end

hl.bind(mainMod .. " + left", focusLeft)
hl.bind(mainMod .. " + right", focusRight)
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Nas horizontais, group_aware cobre a intenção do antigo
-- movewindow + movegroupwindow. Nas verticais, o .conf original
-- não executava movegroupwindow.
hl.bind(
    mainMod .. " + SHIFT + left",
    hl.dsp.window.move({
        direction = "left",
        group_aware = true,
    })
)

hl.bind(
    mainMod .. " + SHIFT + right",
    hl.dsp.window.move({
        direction = "right",
        group_aware = true,
    })
)

hl.bind(
    mainMod .. " + SHIFT + up",
    hl.dsp.window.move({ direction = "up" })
)

hl.bind(
    mainMod .. " + SHIFT + down",
    hl.dsp.window.move({ direction = "down" })
)

-------------------
---- SUBMAP RESIZE -
-------------------

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind(
        "right",
        hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "left",
        hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "up",
        hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "down",
        hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
        { repeating = true }
    )

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-----------------
---- SUBMAP MOVE -
-----------------

hl.bind(mainMod .. " + M", hl.dsp.submap("move"))

hl.define_submap("move", function()
    hl.bind(
        "right",
        hl.dsp.window.move({ x = 30, y = 0, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "left",
        hl.dsp.window.move({ x = -30, y = 0, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "up",
        hl.dsp.window.move({ x = 0, y = -30, relative = true }),
        { repeating = true }
    )
    hl.bind(
        "down",
        hl.dsp.window.move({ x = 0, y = 30, relative = true }),
        { repeating = true }
    )

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

--------------------
---- WORKSPACES ----
--------------------

for i = 1, 10 do
    local workspace = i
    local key = i % 10 -- workspace 10 -> tecla 0

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = workspace })
    )

    hl.bind(mainMod .. " + SHIFT + " .. key, function()
        -- Preserva o comportamento original: sai do grupo antes de mover.
        hl.dispatch(hl.dsp.window.move({ out_of_group = true }))
        hl.dispatch(hl.dsp.window.move({ workspace = workspace }))
    end)
end

-- Scroll/PageUp/PageDown
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))

-- Mouse drag / resize
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

--------------------
---- SCREENSHOTS ----
--------------------

hl.bind("Print", hl.dsp.exec_cmd(HOME .. "/.local/bin/hypr-screenshot output"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(HOME .. "/.local/bin/hypr-screenshot area"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("wl-paste | swappy -f -"))

------------------------
---- MEDIA / BRILHO ----
------------------------

hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("playerctl next"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("playerctl prev"))
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd("playerctl play-pause"))

local volumeUp = [[
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ &&
wpctl get-volume @DEFAULT_AUDIO_SINK@ |
awk '{print int($2*100)}' > "$XDG_RUNTIME_DIR/wob.sock"
]]

local volumeDown = [[
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- &&
wpctl get-volume @DEFAULT_AUDIO_SINK@ |
awk '{print int($2*100)}' > "$XDG_RUNTIME_DIR/wob.sock"
]]

local volumeMute = [[
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle &&
(
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" &&
    echo 0 ||
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'
) > "$XDG_RUNTIME_DIR/wob.sock"
]]

local brightnessUp = [[
brightnessctl set 5%+ &&
brightnessctl -m | cut -d, -f4 | tr -d '%' > "$XDG_RUNTIME_DIR/wob.sock"
]]

local brightnessDown = [[
brightnessctl set 5%- &&
brightnessctl -m | cut -d, -f4 | tr -d '%' > "$XDG_RUNTIME_DIR/wob.sock"
]]

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(volumeUp),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(volumeDown),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd(volumeMute),
    { locked = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true }
)

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd(brightnessUp),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd(brightnessDown),
    { locked = true, repeating = true }
)

hl.bind("XF86NotificationCenter", hl.dsp.exec_cmd("swaync-client -t -sw"))

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")

    hl.exec_cmd("systemctl --user start gvfs-daemon")
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("uwsm app -- easyeffects --gapplication-service")
    hl.exec_cmd("uwsm app -- copyq --start-server && sleep 0.5 && copyq hide")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd([[ghostty --title="ghostty-quake"]])

    -- Separados: hl.exec_cmd já é assíncrono; não precisamos usar "&".
    hl.exec_cmd("uwsm app -- nm-applet --indicator")

    hl.exec_cmd([[
rm -f "$XDG_RUNTIME_DIR/wob.sock" &&
mkfifo "$XDG_RUNTIME_DIR/wob.sock" &&
tail -f "$XDG_RUNTIME_DIR/wob.sock" | wob
]])
end)
