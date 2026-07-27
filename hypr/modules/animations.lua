-- Short, low-travel transitions: motion remains visible without feeling bouncy.

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("ayuEaseOut", {
    type = "bezier",
    points = { { 0.22, 1 }, { 0.36, 1 } },
})

hl.curve("ayuEaseInOut", {
    type = "bezier",
    points = { { 0.65, 0 }, { 0.35, 1 } },
})

hl.animation({ leaf = "global",        enabled = true, speed = 6,   bezier = "ayuEaseOut" })
hl.animation({ leaf = "border",        enabled = true, speed = 7,   bezier = "ayuEaseOut" })
hl.animation({ leaf = "windows",       enabled = true, speed = 5,   bezier = "ayuEaseOut" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   bezier = "ayuEaseOut", style = "popin 98%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 4,   bezier = "ayuEaseInOut", style = "popin 98%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 5,   bezier = "ayuEaseOut" })
hl.animation({ leaf = "layers",        enabled = true, speed = 5,   bezier = "ayuEaseOut", style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4.5, bezier = "ayuEaseInOut", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "ayuEaseOut", style = "fade" })
