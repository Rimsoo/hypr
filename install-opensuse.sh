#!/usr/bin/env bash
# Installe Hyprland + les outils utilisés par cette config sur openSUSE Tumbleweed.
# Usage (le dépôt doit déjà être cloné dans ~/.config/hypr) :
#   git clone --recursive https://github.com/Rimsoo/hypr.git ~/.config/hypr
#   bash ~/.config/hypr/install-opensuse.sh
# Relançable sans risque : ce qui est déjà installé est ignoré.

set -u
HYPR_DIR="$HOME/.config/hypr"
missing=()

# Installe chaque paquet séparément : un nom introuvable ne bloque pas le reste
install() {
	for pkg in "$@"; do
		if rpm -q --whatprovides "$pkg" &>/dev/null; then continue; fi
		sudo zypper --non-interactive install --no-recommends "$pkg" || missing+=("$pkg")
	done
}

echo "==> Mise à jour du système"
sudo zypper --non-interactive refresh
sudo zypper --non-interactive dup

echo "==> Hyprland et écosystème"
install hyprland hyprland-devel xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
	hyprpolkitagent hyprsunset hyprpicker hyprpaper qt6-wayland

echo "==> Barre, lanceur, terminal, outils"
install waybar wofi kitty yazi btop neovim \
	grim slurp wl-clipboard libnotify-tools \
	udiskie pavucontrol playerctl brightnessctl \
	python3-gobject typelib-1_0-Playerctl-2_0 \
	fcitx5 fcitx5-configtool \
	fontawesome-fonts google-noto-coloremoji-fonts \
	waypaper awww thunderbird git flatpak opi

echo "==> Codecs (dépôt Packman)"
opi -n codecs || missing+=("codecs (lancer 'opi codecs' à la main)")

echo "==> Applis Flatpak"
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for app in app.zen_browser.zen im.riot.Riot com.discordapp.Discord dev.lizardbyte.app.Sunshine; do
	flatpak install --user -y flathub "$app" || missing+=("flatpak:$app")
done

# hyprland.lua lance zen-browser, discord, element-desktop et sunshine par leur nom :
# petits lanceurs dans ~/.local/bin vers les versions Flatpak
mkdir -p "$HOME/.local/bin"
for pair in zen-browser=app.zen_browser.zen discord=com.discordapp.Discord \
	element-desktop=im.riot.Riot sunshine=dev.lizardbyte.app.Sunshine; do
	cmd="${pair%%=*}" app="${pair#*=}"
	command -v "$cmd" &>/dev/null && continue
	printf '#!/bin/sh\nexec flatpak run %s "$@"\n' "$app" >"$HOME/.local/bin/$cmd"
	chmod +x "$HOME/.local/bin/$cmd"
done

echo "==> Steam (dépôt non-oss)"
install steam

if lspci | grep -qi nvidia; then
	echo "==> GPU NVIDIA détecté : pilote propriétaire"
	install openSUSE-repos-Tumbleweed-NVIDIA
	sudo zypper --non-interactive install-new-recommends --repo NVIDIA || missing+=("pilote NVIDIA")
else
	echo "==> Pas de NVIDIA : pense à commenter les hl.env(...nvidia...) dans hyprland.lua"
fi

echo "==> Plugin hyprsplit (sous-module git)"
git -C "$HYPR_DIR" submodule update --init

echo "==> Services systemd utilisateur"
mkdir -p "$HOME/.config/systemd/user"
cp "$HYPR_DIR"/systemd/* "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable waypaper.timer

echo
if ((${#missing[@]})); then
	echo "!! Non installé (nom différent sur openSUSE ? chercher avec 'zypper se' ou 'opi') :"
	printf '   - %s\n' "${missing[@]}"
else
	echo "Tout est installé."
fi
echo "Redémarre, connecte-toi dans le terminal (TTY) puis lance : Hyprland"
