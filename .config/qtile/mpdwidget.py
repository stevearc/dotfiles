# Modified from https://github.com/qtile/qtile/blob/master/libqtile/widget/mpd2widget.py

# Copyright (c) 2008, Aldo Cortesi. All rights reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""We have made the following changes:
1. Different default mouse buttons
2. Remove mpd command pipelining to eliminate race condition crashes
3. Fix crash in color_progress rendering
"""
import re
from collections import defaultdict
from html import escape
from socket import error as socket_error

from libqtile import utils
from libqtile.log_utils import logger
from libqtile.widget import base
from mpd import CommandError, ConnectionError, MPDClient

# Mouse Interaction
mouse_buttons = {
    # Left click toggles play/pause
    1: "toggle",
    # Right click skips song
    3: "next",
    # Scroll up/down to change volume
    4: "volume_up",
    5: "volume_down",
}

# To display mpd state
play_states = {"play": "\u25b6", "pause": "\u23F8", "stop": "\u25a0"}


def option(char):
    """
    old status mapping method.

    Deprecated.
    """

    def _convert(elements, key, space):
        if key in elements and elements[key] != "0":
            elements[key] = char
        else:
            elements[key] = space

    return _convert


# Changes to formatter will still use this dicitionary as a fallback
prepare_status = {
    "repeat": option("r"),
    "random": option("z"),
    "single": option("1"),
    "consume": option("c"),
    "updating_db": option("U"),
}

# dictionary for new formatting method.  This is now default.
status_dict = {
    "repeat": "r",
    "random": "z",
    "single": "1",
    "consume": "c",
    "updating_db": "U",
}

default_idle_message = "MPD IDLE"

default_idle_format = (
    "{play_status} {idle_message}" + "[{repeat}{random}{single}{consume}{updating_db}]"
)

default_format = (
    "{play_status} {artist}/{title} "
    + "[{repeat}{random}{single}{consume}{updating_db}]"
)


def default_cmd():
    return None


format_fns = {
    "all": escape,
}


class MpdWidget(base.ThreadPoolText):
    r"""Mpd2 Object.

    Parameters
    ==========
    status_format:
        format string to display status

        For a full list of values, see:
            MPDClient.status() and MPDClient.currentsong()

        https://musicpd.org/doc/protocol/command_reference.html#command_status
        https://musicpd.org/doc/protocol/tags.html

        Default::

            '{play_status} {artist}/{title} \
                [{repeat}{random}{single}{consume}{updating_db}]'

            ``play_status`` is a string from ``play_states`` dict

            Note that the ``time`` property of the song renamed to ``fulltime``
            to prevent conflicts with status information during formating.

    idle_format:
        format string to display status when no song is in queue.

        Default::

            '{play_status} {idle_message} \
                [{repeat}{random}{single}{consume}{updating_db}]'

    idle_message:
        text to display instead of song information when MPD is idle.
        (i.e. no song in queue)

        Default:: "MPD IDLE"

    prepare_status:
        dict of functions to replace values in status with custom characters.

        ``f(status, key, space_element) => str``

        New functionality allows use of a dictionary of plain strings.

        Default::

            status_dict = {
                'repeat': 'r',
                'random': 'z',
                'single': '1',
                'consume': 'c',
                'updating_db': 'U'
            }

    format_fns:
        A dict of functions to format the various elements.

        'Tag': f(str) => str

        Default:: { 'all': lambda s: cgi.escape(s) }

        N.B. if 'all' is present, it is processed on every element of song_info
            before any other formatting is done.

    mouse_buttons:
        A dict of mouse button numbers to actions

    Widget requirements: python-mpd2_.

    .. _python-mpd2: https://pypi.org/project/python-mpd2/
    """

    orientations = base.ORIENTATION_HORIZONTAL
    defaults = [
        ("update_interval", 1, "Interval of update widget"),
        ("host", "localhost", "Host of mpd server"),
        ("port", 6600, "Port of mpd server"),
        ("password", None, "Password for auth on mpd server"),
        ("mouse_buttons", mouse_buttons, "b_num -> action."),
        ("play_states", play_states, "Play state mapping"),
        ("format_fns", format_fns, "Dictionary of format methods"),
        ("command", default_cmd, "command to be executed by mapped mouse button."),
        ("prepare_status", status_dict, "characters to show the status of MPD"),
        ("status_format", default_format, "format for displayed song info."),
        (
            "idle_format",
            default_idle_format,
            "format for status when mpd has no playlist.",
        ),
        ("idle_message", default_idle_message, "text to display when mpd is idle."),
        ("timeout", 30, "MPDClient timeout"),
        ("idletimeout", 5, "MPDClient idle command timeout"),
        ("no_connection", "No connection", "Text when mpd is disconnected"),
        ("color_progress", None, "Text color to indicate track progress."),
        ("space", "-", "Space keeper"),
        ("volume_delta", 2, "Amount to change volume on button scroll"),
    ]

    def __init__(self, **config):
        """Constructor."""
        super().__init__("", **config)

        self.add_defaults(MpdWidget.defaults)
        self.client = MPDClient()
        self.client.timeout = self.timeout
        self.client.idletimeout = self.idletimeout
        if self.color_progress:
            self.color_progress = utils.hex(self.color_progress)

    @property
    def connected(self):
        """Attempt connection to mpd server."""
        try:
            self.client.ping()  # pylint: disable=E1101
        except (socket_error, ConnectionError):
            try:
                self.client.connect(self.host, self.port)
                if self.password:
                    self.client.password(self.password)  # pylint: disable=E1101
            except (socket_error, ConnectionError, CommandError):
                return False
        return True

    def poll(self):
        """
        Called by qtile manager.

        poll the mpd server and update widget.
        """
        if self.connected:
            return self.update_status()
        else:
            return self.no_connection

    def update_status(self):
        """get updated info from mpd server and call format."""
        # We removed the command_list because there were race conditions with the mouse
        # click commands and it was crashing the widget
        status = self.client.status()
        current_song = self.client.currentsong()
        return self.formatter(status, current_song)

    def button_press(self, x, y, button):
        """handle click event on widget."""
        base.ThreadPoolText.button_press(self, x, y, button)
        m_name = self.mouse_buttons[button]

        if self.connected:
            if hasattr(self, m_name):
                self.__try_call(m_name)
            elif hasattr(self.client, m_name):
                self.__try_call(m_name, self.client)

    def __try_call(self, attr_name, obj=None):
        err1 = "Class {Class} has no attribute {attr}."
        err2 = 'attribute "{Class}.{attr}" is not callable.'
        context = obj or self
        try:
            getattr(context, attr_name)()
        except (AttributeError, TypeError) as e:
            if isinstance(e, AttributeError):
                err = err1.format(Class=type(context).__name__, attr=attr_name)
            else:
                err = err2.format(Class=type(context).__name__, attr=attr_name)
            logger.exception(err + " {}".format(e.args[0]))

    def volume_up(self):
        self.client.volume(self.volume_delta)

    def volume_down(self):
        self.client.volume(-self.volume_delta)

    def next(self):
        self.client.next()

    def toggle(self):
        """toggle play/pause."""
        status = self.client.status()  # pylint: disable=E1101
        play_status = status["state"]

        if play_status == "play":
            self.client.pause()  # pylint: disable=E1101
        else:
            self.client.play()  # pylint: disable=E1101

    def formatter(self, status, current_song):
        """format song info."""
        default = "Undefined"
        song_info = defaultdict(lambda: default)
        song_info["play_status"] = self.play_states[status["state"]]

        if status["state"] == "stop" and current_song == {}:
            song_info["idle_message"] = self.idle_message
            fmt = self.idle_format
        else:
            fmt = self.status_format

        for k in current_song:
            song_info[k] = current_song[k]
        song_info["fulltime"] = song_info["time"]
        del song_info["time"]

        song_info.update(status)
        if song_info["updating_db"] == default:
            song_info["updating_db"] = "0"
        if not callable(self.prepare_status["repeat"]):
            for k in self.prepare_status:
                if k in status and status[k] != "0":
                    # Much more direct.
                    song_info[k] = self.prepare_status[k]
                else:
                    song_info[k] = self.space
        else:
            self.prepare_formatting(song_info)

        # 'remaining' isn't actually in the information provided by mpd
        # so we construct it from 'fulltime' and 'elapsed'.
        # 'elapsed' is always less than or equal to 'fulltime', if it exists.
        # Remaining should default to '00:00' if either or both are missing.
        # These values are also used for coloring text by progress, if wanted.
        if "remaining" in self.status_format or self.color_progress:
            total = (
                float(song_info["fulltime"])
                if song_info["fulltime"] != default
                else 0.0
            )
            elapsed = (
                float(song_info["elapsed"]) if song_info["elapsed"] != default else 0.0
            )
            song_info["remaining"] = "{:.2f}".format(float(total - elapsed))

        # mpd serializes tags containing commas as lists.
        for key in song_info:
            if isinstance(song_info[key], list):
                song_info[key] = ", ".join(song_info[key])

        # Now we apply the user formatting to selected elements in song_info.
        # if 'all' is defined, it is applied first.
        # the reason for this is that, if the format functions do pango markup.
        # we don't want to do anything that would mess it up, e.g. `escape`ing.
        if "all" in self.format_fns:
            for key in song_info:
                song_info[key] = self.format_fns["all"](song_info[key])
        for fmt_fn in self.format_fns:
            if fmt_fn in song_info and fmt_fn != "all":
                song_info[fmt_fn] = self.format_fns[fmt_fn](song_info[fmt_fn])

        # fmt = self.status_format
        if not isinstance(fmt, str):
            fmt = str(fmt)

        formatted = fmt.format_map(song_info)

        if self.color_progress and status["state"] != "stop":
            formatted = highlight_progress(
                formatted, elapsed, total, self.color_progress
            )

        return formatted

    def prepare_formatting(self, status):
        """old way of preparing status formatting."""
        for key in self.prepare_status:
            self.prepare_status[key](status, key, self.space)

    def finalize(self):
        """finalize."""
        super().finalize()

        try:
            self.client.close()  # pylint: disable=E1101
            self.client.disconnect()
        except ConnectionError:
            pass


def highlight_progress(status, elapsed, total, color):
    if total <= 0 or elapsed <= 0:
        return status
    matches = {}
    offset = 0

    def replace(m):
        nonlocal offset
        span = m.span()
        delta = span[1] - span[0] - 1
        matches[offset + span[0]] = delta
        offset -= delta
        return "~"

    # Create an intermediate form where we replace html escape sequences (e.g. &amp;) with a single char
    display_str = re.sub("&.*?;", replace, status)
    # Calculate the progress based on the length of the intermediate string
    progress = int(len(display_str) * elapsed / total)
    color_start = '<span color="{0}">'.format(color)
    color_end = "</span>"
    # Adjust progress based on the matches that we replaced
    progress += sum([v for i, v in matches.items() if progress > i])
    return color_start + status[:progress] + color_end + status[progress:]
