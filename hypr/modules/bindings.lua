local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "dolphin"
local shellIpc    = "qs ipc -p /usr/share/chillpill-shell call "

-- Applications and shell panels.
hl.bind(mainMod .. " + RETURN",   hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",        hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE",    hl.dsp.exec_cmd(shellIpc .. "launcher toggle"))
hl.bind(mainMod .. " + R",        hl.dsp.exec_cmd(shellIpc .. "launcher toggle"))
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(shellIpc .. "controlCenter toggle"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(shellIpc .. "cliphist toggle"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(shellIpc .. "miniDashboard toggle"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd(shellIpc .. "lockscreen lock"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(shellIpc .. "powerMenu toggle"))
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd(shellIpc .. "colorTemperature toggle"))

-- Window actions.
hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
))

-- Focus and workspaces.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end

hl.bind(mainMod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- Audio, brightness and media.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                 { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd(shellIpc .. "colorTemperature cooler"), { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd(shellIpc .. "colorTemperature warmer"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots.
hl.bind("Print", hl.dsp.exec_cmd(
    "grim -t ppm - | satty -f - --copy-command wl-copy --output-filename ~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"
))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
    "grim -g \"$(slurp)\" -t ppm - | satty -f - --copy-command wl-copy --output-filename ~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"
))

-- Resize mode: SUPER + CTRL + R, arrows to resize, Escape/Return to leave.
hl.bind(mainMod .. " + CTRL + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("return", hl.dsp.submap("reset"))
end)
