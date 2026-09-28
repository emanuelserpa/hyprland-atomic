import QtQuick

// Stable search contract. Legacy domain fields remain available to activate().
QtObject {
    function normalize(item, provider, catalog) {
        const source = item ?? {}
        const kind = String(source.kind ?? "hint")
        const actions = catalog.actionsFor(source)
        const primary = catalog.primaryAction(source)
        const ids = actions.map(action => String(action.id))
        const key = kind === "app" ? String(source.entry?.id ?? source.entry?.name ?? source.title ?? "")
                  : kind === "window" ? String(source.address ?? source.handle ?? source.title ?? "")
                  : kind === "file" ? String(source.path ?? "")
                  : kind === "clipboard" ? String(source.clipId ?? "")
                  : kind === "command" ? String(source.command ?? "")
                  : String(source.value ?? source.emoji ?? source.title ?? "")
        const result = {}
        for (const field in source)
            result[field] = source[field]
        result.id = String(source.id ?? (kind + ":" + key))
        result.kind = kind
        result.provider = String(provider ?? source.provider ?? kind)
        result.title = String(source.title ?? "")
        result.subtitle = String(source.subtitle ?? "")
        result.icon = source.icon ?? ""
        result.score = Number(source.score ?? 0)
        const sections = { app: "Aplicativos", window: "Janelas", close_window: "Janelas",
                           kill: "Janelas", command: "Comandos", file: "Arquivos",
                           clipboard: "Clipboard", emoji: "Emoji", calc: "Cálculo" }
        result.section = String(source.section ?? sections[kind] ?? "Ações")
        let payload = source.payload
        if (payload === undefined) {
            payload = {}
            for (const field of ["path", "address", "handle", "workspaceId", "clipId",
                                 "command", "value", "emoji", "themeId", "profile", "pid"])
                if (source[field] !== undefined)
                    payload[field] = source[field]
        }
        result.payload = payload
        result.primaryAction = String(source.primaryAction ?? primary?.id ?? "")
        result.actions = source.actions ?? ids
        return result
    }

    function normalizeAll(items, provider, catalog) {
        return (items ?? []).map(item => normalize(item, provider, catalog))
    }
}
