-- Keep application requests from unexpectedly maximizing tiled windows.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Use the full screen when a regular workspace contains only one tiled window.
-- Special workspaces retain their gaps and rounded corners.
for _, selector in ipairs({ "w[tv1]s[false]", "f[1]s[false]" }) do
    hl.workspace_rule({
        workspace = selector,
        gaps_out = 0,
        gaps_in = 0,
    })

    hl.window_rule({
        match = { float = false, workspace = selector },
        border_size = 0,
        rounding = 0,
    })
end

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name   = "float-1password",
    match  = { class = "^1password$" },
    float  = true,
    size   = "60% 70%",
    center = true,
})

hl.window_rule({
    name   = "float-file-pickers",
    match  = { title = "^(Open File|Save File|Open Folder|Choose Files|File Upload).*" },
    float  = true,
    size   = "50% 60%",
    center = true,
})

hl.window_rule({
    name   = "float-dialogs",
    match  = { title = "^(Confirm|Alert|Warning|Question).*" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "float-screenshare-picker",
    match  = { class = "^xdg-desktop-portal-hyprland$" },
    float  = true,
    center = true,
    pin    = true,
})

hl.window_rule({
    name  = "float-pip",
    match = { title = "Picture-in-Picture" },
    float = true,
    pin   = true,
    size  = "25% 25%",
})

hl.window_rule({
    name   = "float-satty",
    match  = { class = "^(com.gabm.satty|Satty)$" },
    float  = true,
    size   = "90% 90%",
    center = true,
})
