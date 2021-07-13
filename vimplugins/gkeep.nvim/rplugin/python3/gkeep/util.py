from threading import Thread
from typing import TYPE_CHECKING, Union

import gkeep.globals as g
import greenlet

if TYPE_CHECKING:
    from gkeepapi.node import Note


class BufUrl:
    id: str
    title: Union[str, None]

    def __init__(self, id_or_note: Union[str, "Note"], title: str = None):
        if isinstance(id_or_note, str):
            self.id = id_or_note
            self.title = title
        else:
            self.id = id_or_note.id
            self.title = id_or_note.title
        if self.title == "":
            self.title = None

    @classmethod
    def parse(cls, address: str):
        if not address.startswith("gkeep://"):
            return
        return cls(*address[len("gkeep://") :].split(":", 1))

    def __str__(self):
        ret = f"gkeep://{self.id or ''}"
        if self.title:
            ret += f":{self.title}"
        return ret


_vim_running = True


def _wrap_greenlet(func):
    glet = greenlet.getcurrent()

    def f(*args, **kwargs):
        try:
            ret = func(*args, **kwargs)
        except Exception as e:
            if _vim_running:
                g.vim.async_call(glet.throw, e)
        else:
            if _vim_running:
                g.vim.async_call(glet.switch, ret)

    return f


def run_in_background(func, *args, **kwargs):
    current = greenlet.getcurrent()
    if current.parent is None:
        return g.vim.async_call(run_in_background, func, *args, **kwargs)
    thread = Thread(target=_wrap_greenlet(func), args=args, kwargs=kwargs, daemon=True)
    thread.start()
    return current.parent.switch()


def shutdown():
    global _vim_running  # pylint: disable=W0603
    _vim_running = False
