-- Ayu Mirage, shared with kitty/kitty.conf.
local ayu = {
    background = "212733",
    surface    = "191e2a",
    selection  = "343f4c",
    foreground = "d9d7ce",
    muted      = "686868",
    blue       = "6dcbfa",
    yellow     = "ffcc66",
    green      = "90e1c6",
}

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = {
            top    = 0,
            right  = 14,
            bottom = 14,
            left   = 14,
        },
        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(" .. ayu.blue .. "ee)",
                    "rgba(" .. ayu.green .. "dd)",
                    "rgba(" .. ayu.yellow .. "dd)",
                },
                angle = 45,
            },
            inactive_border = "rgba(" .. ayu.selection .. "bb)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.96,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(" .. ayu.surface .. "99)",
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,
            vibrancy = 0.12,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

return ayu
