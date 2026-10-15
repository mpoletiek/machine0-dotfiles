-- Noctalia 4.7.7 generates this palette as .conf and runs `hyprctl reload`.
-- Read only its six RGB declarations; never execute generated content.
-- Hyprland re-runs required user modules on reload, so colors stay dynamic.
return function(path)
    local file = assert(io.open(path, "r"), "Cannot read Noctalia palette: " .. path)
    local contents = file:read("*a")
    file:close()
    local palette = {}
    for line in contents:gmatch("[^\r\n]+") do
        local name, hex = line:match("^%s*%$([%w_]+)%s*=%s*rgb%((%x%x%x%x%x%x)%)%s*$")
        if name then palette[name] = "rgb(" .. hex .. ")" end
    end
    for _, name in ipairs({"primary", "surface", "secondary", "error", "tertiary", "surface_lowest"}) do
        assert(palette[name], "Missing or invalid Noctalia RGB color: " .. name)
    end
    hl.config({
        general = { col = {
            -- Legacy Hyprlang retains the earlier gradient's 45-degree angle
            -- when Noctalia replaces its colors. Preserve even that latent state.
            active_border = { colors = {palette.primary}, angle = 45 },
            inactive_border = palette.surface,
        } },
        group = {
            col = {
                border_active = palette.secondary,
                border_inactive = palette.surface,
                border_locked_active = palette.error,
                border_locked_inactive = palette.surface,
            },
            groupbar = { col = {
                active = palette.secondary,
                inactive = palette.surface,
                locked_active = palette.error,
                locked_inactive = palette.surface,
            } },
        },
    })
end
