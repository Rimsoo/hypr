# hypr

Config Hyprland (>= 0.55, config Lua) + Waybar.

## Installation sur openSUSE Tumbleweed

```sh
sudo zypper in git
git clone --recursive https://github.com/Rimsoo/hypr.git ~/.config/hypr
bash ~/.config/hypr/install-opensuse.sh
```

Le script installe Hyprland et les outils utilisés par la config, les applis
Flatpak (Zen, Discord, Element, Sunshine), le pilote NVIDIA si besoin, et copie
les services systemd utilisateur de `systemd/`.

À la fin, il liste ce qui n'a pas pu être installé.

## Après

- Fonds d'écran : à copier dans `~/Pictures/WP` (dossier utilisé par waypaper).
- Sans GPU NVIDIA : commenter les `hl.env(...nvidia...)` dans `hyprland.lua`.
- Moniteurs : adapter les lignes `hl.monitor(...)` en haut de `hyprland.lua`.
- Mise à jour du système : `sudo zypper ref && sudo zypper dup`.
