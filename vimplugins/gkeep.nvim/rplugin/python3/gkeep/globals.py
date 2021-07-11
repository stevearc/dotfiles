from typing import TYPE_CHECKING

import pynvim

if TYPE_CHECKING:
    from gkeep.api import KeepApi
    from gkeep.config import Config
    from gkeep.menu import Menu
    from gkeep.note import NoteView
    from gkeep.notelist import NoteList

vim: pynvim.Nvim = None  # type: ignore
api: "KeepApi" = None  # type: ignore
menu: "Menu" = None  # type: ignore
noteview: "NoteView" = None  # type: ignore
notelist: "NoteList" = None  # type: ignore
config: "Config" = None  # type: ignore


def init(nvim: pynvim.Nvim):
    global vim, api, menu, noteview, notelist, config  # pylint: disable=W0603
    from gkeep.api import KeepApi
    from gkeep.config import Config
    from gkeep.menu import Menu
    from gkeep.note import NoteView
    from gkeep.notelist import NoteList

    vim = nvim
    api = KeepApi()
    menu = Menu()
    notelist = NoteList()
    noteview = NoteView()
    config = Config()
