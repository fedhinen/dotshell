-- Services started once with the Hyprland session.

hl.on("hyprland.start", function()
    hl.exec_cmd("chillpill-shell")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("dbus-update-activation-environment --system WAYLAND_DISPLAY_XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
end)
