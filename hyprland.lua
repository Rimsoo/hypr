-- #######################################################################################
-- ~/.config/hypr/hyprland.lua
-- Converti depuis hyprland.conf pour Hyprland >= 0.55 (config Lua)
--
-- Autocomplétion LSP : ajoute /usr/share/hypr/stubs à ta workspace.library
-- (voir .luarc.json en bas de mes notes)
-- #######################################################################################

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
hl.monitor({ output = "DP-1", mode = "1920x1080@240", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@70", position = "1920x0", scale = 1 })
-- règle de repli pour tout moniteur non listé ci-dessus
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------

-- Les `$variables` de hyprlang deviennent de simples variables Lua locales.
local terminal = "kitty"
local fileManager = "kitty -e yazi"
-- local fileManager = "dolphin"
local menu = "killall wofi; wofi --show drun"
local sysMonitor = "kitty -e btop"
local browser = "zen-browser"
local editor = "kitty -e nvim"
local bar = "waybar -c ~/.config/hypr/waybar/config.jsonc -s ~/.config/hypr/waybar/style.css"
local reloadBar = "killall waybar; " .. bar
-- [[ ... ]] = chaîne littérale Lua : pas besoin d'échapper les guillemets
local screenshot = [[grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot copied to clipboard" -a "grim" -t 3000]]
local colorpicker = "hyprpicker -a"
local mail = "thunderbird"
local game = "steam steam://rungameid/1264970"
local sunshine = "sunshine"
local discord = "discord"
local matrix = "element-desktop"
-- local ddnet    = "steam steam://rungameid/412220"

-------------------
---- HYPRSPLIT ----
-------------------

-- IMPORTANT : depuis Hyprland 0.55, hyprsplit n'est PLUS un plugin C++ hyprpm.
-- C'est une bibliothèque Lua. Installation :
--     hyprpm remove hyprsplit          # retire l'ancien plugin cassé
--     git clone https://github.com/shezdy/hyprsplit ~/.config/hypr/hyprsplit
--
-- Le pcall() évite qu'un clone manquant ou cassé ne tue toute la config :
-- require() sur un module inexistant lève une vraie erreur qui stopperait
-- l'exécution de ce fichier.

local NUM_WORKSPACES = 5

local hs_ok, hs_or_err = pcall(require, "hyprsplit")
local hs = hs_ok and hs_or_err or nil

if hs then
	hs.config({ num_workspaces = NUM_WORKSPACES })
	-- hs.config({ persistent_workspaces = true })
	-- Réserve 1-5 à DP-1 et 6-10 à HDMI-A-1 (sinon : ordre des IDs moniteur)
	-- hs.monitor_priority({ "DP-1", "HDMI-A-1" })
else
	hl.notification.create({
		text = "hyprsplit non chargé : " .. tostring(hs_or_err),
		timeout = 10000,
		icon = "error",
	})
end

-- Dispatchers d'espaces de travail : versions par-moniteur de hyprsplit si
-- disponibles, sinon repli sur celles de Hyprland.
local ws_focus = hs and hs.dsp.focus or hl.dsp.focus
local ws_move = hs and hs.dsp.window.move or hl.dsp.window.move

-------------------
---- AUTOSTART ----
-------------------

-- `exec-once` devient l'événement "hyprland.start".
-- hl.exec_cmd() est déjà asynchrone : plus besoin de `&` ni de `& disown`.
hl.on("hyprland.start", function()
	hl.exec_cmd(bar)
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("udiskie")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("systemctl --user start hyprland-session.target")
	hl.exec_cmd(sunshine) -- streaming dispo dès le boot (WOL)
	-- `hyprpm reload -n` SUPPRIMÉ : plus aucun plugin C++ à charger.
end)

-- hl.on("hyprland.shutdown", function() ... end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_SIZE", "16")
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,

		border_size = 2,

		-- `col.active_border = rgba(..) rgba(..) 5deg` devient une table
		col = {
			active_border = { colors = { "rgba(83a598ff)", "rgba(b8bb26ff)" }, angle = 5 },
			inactive_border = "rgba(595959aa)",
		},

		resize_on_border = true,

		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 7,
		rounding_power = 3,

		active_opacity = 0.95,
		inactive_opacity = 0.85,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a, -- = rgba(1a1a1aee), en ARGB
		},

		blur = {
			enabled = true,
			size = 1,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	-- `enabled = yes, please :)` -> un vrai booléen
	animations = {
		enabled = true,
	},
})

-- Les `bezier = nom,x1,y1,x2,y2` deviennent hl.curve() avec 2 points de contrôle.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- `animation = leaf, on/off, speed, curve[, style]`
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- "Smart gaps" / "No gaps when only" — décommente si tu veux
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })

hl.config({
	-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/
	dwindle = {
		-- pseudotile = true,
		preserve_split = true,
	},

	-- See https://wiki.hypr.land/configuring/layouts/master-layout/
	master = {
		new_status = "master",
	},

	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = false,
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us,us",
		kb_variant = "basic,intl",
		kb_options = "grp:win_space_toggle",

		numlock_by_default = true,
		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 = aucune modification

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- Le bloc `gestures { }` n'existe plus : les gestes se déclarent un par un.
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Config par périphérique
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + KP_Enter", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("XF86Mail", hl.dsp.exec_cmd(mail))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(mail))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(sysMonitor))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(game))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(sunshine))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(matrix))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + I",     hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- hl.bind("F11",                 hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(colorpicker))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))

-- Tu avais DEUX lignes `bind = $mainMod SHIFT, R` : fusionnées en un callback.
-- (`hyprctl reload` depuis Lua = hl.dsp.reload_config())
hl.bind(mainMod .. " + SHIFT + R", function()
	hl.exec_cmd("hyprctl reload")
	hl.exec_cmd(reloadBar)
end)

-- Déplacer le focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Redimensionner la fenêtre active (`binde` -> { repeating = true })
hl.bind(mainMod .. " + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Déplacer la fenêtre
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- `movewindow, mon:+1` -> { monitor = "+1" }
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + ALT + H", hl.dsp.window.move({ monitor = "-1" }))

---- Espaces de travail hyprsplit (enfin réactivés !) ----

-- Pavé numérique : index = numéro d'espace de travail (KP_1..KP_9, KP_0)
local kpCodes = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }

for i = 1, NUM_WORKSPACES do
	local key = i % 10 -- 10 -> touche 0

	-- SUPER + <n>        : aller à l'espace n du moniteur courant
	hl.bind(mainMod .. " + " .. key, ws_focus({ workspace = i }))
	-- SUPER + ALT + <n>  : y déplacer la fenêtre
	hl.bind(mainMod .. " + ALT + " .. key, ws_move({ workspace = i }))

	local code = kpCodes[i]
	if code then
		hl.bind(mainMod .. " + code:" .. code, ws_focus({ workspace = i }))
		hl.bind(mainMod .. " + ALT + code:" .. code, ws_move({ workspace = i }))
	end
end

if hs then
	-- Récupère les fenêtres coincées sur un espace invalide (débranchement d'écran)
	hl.bind(mainMod .. " + SHIFT + G", hs.dsp.grab_rogue_windows())
	-- Échange les espaces actifs entre les deux moniteurs
	hl.bind(mainMod .. " + ALT + S", hs.dsp.workspace.swap_monitors({ monitor1 = "current", monitor2 = "+1" }))
end

-- Espace spécial (scratchpad)
hl.bind(mainMod .. " + Tab", hl.dsp.workspace.toggle_special("magic"))

-- Tu avais DEUX lignes `bind = $mainMod ALT, Tab` : fusionnées en un callback.
hl.bind(mainMod .. " + ALT + Tab", function()
	hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
	hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
end)

hl.bind(mainMod .. " + ALT + right", ws_move({ workspace = "e+1" }))
hl.bind(mainMod .. " + ALT + left", ws_move({ workspace = "e-1" }))

-- Défiler les espaces à la molette
hl.bind(mainMod .. " + mouse_down", ws_focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", ws_focus({ workspace = "e-1" }))

-- Déplacer / redimensionner à la souris (`bindm` -> { mouse = true })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Touches multimédia
-- `bindel` -> { repeating = true, locked = true }
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd('pactl set-sink-volume @DEFAULT_SINK@ "+5%"'),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd('pactl set-sink-volume @DEFAULT_SINK@ "-5%"'),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),
	{ repeating = true, locked = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { repeating = true, locked = true })

-- `bindl` -> { locked = true }
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- ATTENTION : ta ligne `windowrule = match:initial_title Godot` n'avait AUCUN
-- effet, donc elle ne faisait rien. Je la laisse commentée — décommente si tu
-- voulais bien `tile on` comme pour les autres.
-- hl.window_rule({ match = { initial_title = "Godot" }, tile = true })

hl.window_rule({ match = { initial_title = "Steam" }, tile = true })
hl.window_rule({ match = { initial_title = "RSI Launcher" }, tile = true })
hl.window_rule({ match = { initial_class = "steam" }, tile = true })

-- Ignorer les demandes de maximisation (tu l'avais commenté)
-- hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- Corrige des problèmes de drag sous XWayland (tu l'avais commenté)
-- hl.window_rule({
--     name  = "fix-xwayland-drags",
--     match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
--     no_focus = true,
-- })

-- >>> simpleautoframer: managed block — do not edit by hand <<<
-- Generated by SimpleAutoFramer. Re-generated every time the app
-- registers its global shortcuts with the portal. Maps each key
-- combination to the portal's empty-app_id:<id> entry.
hl.bind("CTRL + SHIFT + at", hl.dsp.global(":ctrl_shift_at"))
hl.bind("CTRL + SHIFT + exclam", hl.dsp.global(":ctrl_shift_exclam"))
hl.bind("CTRL + SHIFT + asciitilde", hl.dsp.global(":ctrl_shift_asciitilde"))
-- <<< simpleautoframer: end managed block >>>
