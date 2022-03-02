# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import logging
import logging.handlers
import os
import os.path
import subprocess
import sys
from typing import List  # noqa: F401

from libqtile import bar, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

# Make sure we reload our companion file
sys.modules.pop("mpdwidget", None)
from mpdwidget import MpdWidget

mod = "mod4"
alt = "mod1"
terminal = guess_terminal("kitty")
HOME = os.getenv("HOME") or "/"
CACHE = os.path.join(HOME, ".local", "share", "qtile")
logger = logging.getLogger(__name__)

logfile = os.path.join(CACHE, "debug.log")
handler = logging.handlers.RotatingFileHandler(
    logfile, delay=True, backupCount=1, maxBytes=1024 * 1024
)
formatter = logging.Formatter("%(levelname)s %(asctime)s [%(name)s] %(message)s")
handler.setFormatter(formatter)
log = logging.getLogger()
log.setLevel(logging.DEBUG)
log.addHandler(handler)
logging.getLogger("mpd.base").setLevel(logging.WARNING)
logger.debug("Begin config.py")

try:
    keys = [
        # Switch between windows
        Key([alt], "h", lazy.layout.left(), desc="Move focus to left"),
        Key([alt], "l", lazy.layout.right(), desc="Move focus to right"),
        Key([alt], "j", lazy.layout.down(), desc="Move focus down"),
        Key([alt], "k", lazy.layout.up(), desc="Move focus up"),
        Key(
            [mod], "space", lazy.layout.next(), desc="Move window focus to other window"
        ),
        Key([alt], "Tab", lazy.layout.down(), desc="Move focus down"),
        Key([alt, "shift"], "Tab", lazy.layout.up(), desc="Move focus up"),
        # Move windows between left/right columns or move up/down in current stack.
        # Moving out of range in Columns layout will create new column.
        Key(
            [alt, "shift"],
            "h",
            lazy.layout.shuffle_left(),
            desc="Move window to the left",
        ),
        Key(
            [alt, "shift"],
            "l",
            lazy.layout.shuffle_right(),
            desc="Move window to the right",
        ),
        Key([alt, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
        Key([alt, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
        # Grow windows. If current window is on the edge of screen and direction
        # will be to screen edge - window would shrink.
        Key(
            [mod, "control"],
            "h",
            lazy.layout.grow_left(),
            desc="Grow window to the left",
        ),
        Key(
            [mod, "control"],
            "l",
            lazy.layout.grow_right(),
            desc="Grow window to the right",
        ),
        Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
        Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
        Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
        # Switch screens
        Key([alt, "control"], "h", lazy.prev_screen(), desc="Focus previous screen"),
        Key([alt, "control"], "l", lazy.next_screen(), desc="Focus next screen"),
        # Toggle between split and unsplit sides of stack.
        # Split = all windows displayed
        # Unsplit = 1 window displayed, like Max layout, but still with
        # multiple stack panes
        Key(
            [mod, "shift"],
            "Return",
            lazy.layout.toggle_split(),
            desc="Toggle between split and unsplit sides of stack",
        ),
        Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
        Key([alt, "shift"], "Return", lazy.spawn(terminal), desc="Launch terminal"),
        # Toggle between different layouts as defined below
        Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
        Key([alt], "w", lazy.window.kill(), desc="Kill focused window"),
        Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
        Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
        Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
        Key(
            [alt, "shift"],
            "r",
            lazy.spawn("rofi -show run"),
            desc="Spawn a command using a prompt widget",
        ),
        Key(
            [alt, "shift"],
            "p",
            lazy.spawn("rofi -show combi"),
            desc="Spawn a command using a prompt widget",
        ),
        Key([mod], "l", lazy.spawn("s lock"), desc="Lock screen"),
    ]

    groups = [Group(i) for i in "123456789"]

    for i in groups:
        keys.extend(
            [
                Key(
                    [alt],
                    i.name,
                    lazy.group[i.name].toscreen(toggle=False),
                    desc="Switch to group {}".format(i.name),
                ),
                Key(
                    [alt, "shift"],
                    i.name,
                    lazy.window.togroup(i.name),
                    desc="Move focused window to group {}".format(i.name),
                ),
            ]
        )

    c_border_focus = "#3d59a1"
    c_border_normal = "#1f2335.0"
    c_bar_bg = "#1a1b26.6"

    layouts = [
        layout.Columns(
            border_focus=c_border_focus,
            border_normal=c_border_normal,
            border_focus_stack=c_border_focus,
            border_normal_stack=c_border_normal,
        ),
        layout.Max(),
        # Try more layouts by unleashing below layouts.
        # layout.Stack(num_stacks=2),
        # layout.Bsp(),
        # layout.Matrix(),
        layout.MonadTall(
            border_focus=c_border_focus,
            border_normal=c_border_normal,
            single_border_width=0,
        ),
        layout.MonadWide(
            border_focus=c_border_focus,
            border_normal=c_border_normal,
            single_border_width=0,
        ),
        # layout.RatioTile(),
        # layout.Tile(),
        # layout.TreeTab(),
        # layout.VerticalTile(),
        # layout.Zoomy(),
    ]

    widget_defaults = dict(
        font="sans",
        fontsize=12,
        padding=3,
    )
    extension_defaults = widget_defaults.copy()

    num_monitors = int(
        subprocess.run(
            r"xrandr --listmonitors | head -n 1 | cut -f 2 -d :",
            shell=True,
            stdout=subprocess.PIPE,
        ).stdout
    )
    PRIMARY_MONITOR = int(
        subprocess.run(
            r'xrandr --listmonitors | awk "/\+\*/{print NR-2}"',
            shell=True,
            stdout=subprocess.PIPE,
        ).stdout
        or "0"
    )
    logger.debug("Configuring %d screens (%d primary)", num_monitors, PRIMARY_MONITOR)
    screens = [
        Screen(
            wallpaper="~/.config/backgrounds/805740.png",
            wallpaper_mode="fill",
            top=bar.Bar(
                [
                    widget.CurrentLayout(),
                    widget.GroupBox(hide_unused=True),
                    widget.Prompt(),
                    widget.WindowName(),
                    widget.Clock(format="%a %b %d  %I:%M %p"),
                    widget.Spacer(),
                    *(
                        [
                            MpdWidget(
                                status_format="{play_status} {artist}/{title} {volume}%",
                                idle_format="",
                                space="",
                                color_progress="#9ece6a",
                            ),
                            widget.Systray(background=c_bar_bg),
                            widget.Battery(
                                hide_threshold=0.9,
                                low_percentage=0.2,
                                format="B{char}{percent:2.0%}",
                            ),
                            widget.Volume(
                                mute_command="amixer -D pulse set Master Playback Switch toggle",
                                emoji=True,
                            ),
                        ]
                        if i == PRIMARY_MONITOR
                        else []
                    ),
                ],
                24,
                background=c_bar_bg,
            ),
        )
        for i in range(num_monitors)
    ]

    # Drag floating layouts.
    mouse = [
        Drag(
            [mod],
            "Button1",
            lazy.window.set_position_floating(),
            start=lazy.window.get_position(),
        ),
        Drag(
            [mod],
            "Button3",
            lazy.window.set_size_floating(),
            start=lazy.window.get_size(),
        ),
        Click([mod], "Button2", lazy.window.bring_to_front()),
    ]

    dgroups_key_binder = None
    dgroups_app_rules = []  # type: List
    follow_mouse_focus = True
    bring_front_click = False
    cursor_warp = False
    floating_layout = layout.Floating(
        float_rules=[
            # Run the utility of `xprop` to see the wm class and name of an X client.
            *layout.Floating.default_float_rules,
            Match(wm_class="confirmreset"),  # gitk
            Match(wm_class="makebranch"),  # gitk
            Match(wm_class="maketag"),  # gitk
            Match(wm_class="ssh-askpass"),  # ssh-askpass
            Match(title="branchdialog"),  # gitk
            Match(title="pinentry"),  # GPG key password entry
        ]
    )
    auto_fullscreen = True
    focus_on_window_activation = "smart"
    reconfigure_screens = True

    # If things like steam games want to auto-minimize themselves when losing
    # focus, should we respect this or not?
    auto_minimize = True

    def is_monitor_on():
        ret = subprocess.run("xset -q dpms | grep 'Monitor is Off'", shell=True)
        return ret.returncode == 1

    @hook.subscribe.screen_change
    def randrchange(ev):
        logger.debug("xrandr change event")
        if not is_monitor_on():
            logger.debug("Ignoring event because user is idle")
            return
        ret = subprocess.run(
            [os.path.join(HOME, ".config", "qtile", "setup-monitors.sh")],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if ret.stdout:
            logger.debug("  setup-monitors.sh (stdout): %s", ret.stdout)
        if ret.stderr:
            logger.debug("  setup-monitors.sh (stderr): %s", ret.stderr)
        # Only restart if the command succeeded and printed output
        # (the command only prints output when it changes the monitor layout)
        if ret.returncode == 0 and ret.stdout:
            logger.debug("restarting qtile...")
            qtile.cmd_restart()

    @hook.subscribe.startup_once
    def autostart():
        logger.debug("Running autorun.sh")
        subprocess.call([os.path.join(HOME, ".config", "qtile", "autorun.sh")])

    # XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
    # string besides java UI toolkits; you can see several discussions on the
    # mailing lists, GitHub issues, and other WM documentation that suggest setting
    # this string if your java app doesn't work correctly. We may as well just lie
    # and say that we're a working one by default.
    #
    # We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
    # java that happens to be on java's whitelist.
    wmname = "LG3D"
except Exception:
    logger.exception("Error in config")
    raise
