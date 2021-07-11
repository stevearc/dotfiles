import inspect
from functools import wraps
from typing import Any, List

import gkeep.globals as g
import pynvim
from gkeep.menu import Position
from gkeep.util import BufUrl

Args = List[Any]


def unwrap_args(f):
    @wraps(f)
    def d(self, args: Args):
        return f(self, *args)

    return d


@pynvim.plugin
class GkeepPlugin:
    def __init__(self, vim: pynvim.Nvim) -> None:
        g.init(vim)
        g.vim.funcs.timer_start(10000, "_gkeep_sync", {"repeat": -1})

    def is_keep_buffer(self, bufnr: int) -> bool:
        return BufUrl.parse(g.vim.api.buf_get_name(bufnr)) is not None

    @pynvim.command(
        "Gkeep", nargs="*", complete="customlist,_gkeep_command_complete", sync=True
    )
    @unwrap_args
    def keep_command(self, cmd: str = "login", *args: Any) -> None:
        meth = f"cmd_{cmd}"
        if hasattr(self, meth):
            getattr(self, meth)(*args)
        else:
            g.vim.err_write(f"Unknown Gkeep command '{cmd}'\n")

    @pynvim.function("_gkeep_command_complete", sync=True)
    @unwrap_args
    def keep_command_complete(self, arg_lead, _line, _cursor_pos):
        ret = []
        for name, _ in inspect.getmembers(self, predicate=inspect.ismethod):
            if name.startswith("cmd_"):
                cmd = name[4:]
                if cmd.startswith(arg_lead):
                    ret.append(cmd)
        return ret

    @pynvim.function("_gkeep_preload")
    @unwrap_args
    def preload(self, email: str = None) -> None:
        if email is None:
            last_email = g.config.email
            if last_email is not None:
                email = last_email
        if email is None:
            g.vim.err_write("Gkeep cannot preload, missing email. Call :Gkeep login\n")
        else:
            token = g.api.keyring.get_password("google-keep-token", email)
            if token:
                g.api.keep.resume(email, token)

    @pynvim.function("_gkeep_sync")
    @unwrap_args
    def sync(self, *args) -> None:
        labels_updated = any((i.dirty for i in g.api.keep._labels.values()))
        dirty = labels_updated or bool(g.api.keep._findDirtyNodes())
        if dirty:
            g.api.keep.sync()
            g.menu.refresh()

    @pynvim.function("_gkeep_list_action", sync=True)
    @unwrap_args
    def list_action(self, action: str, *args) -> None:
        g.notelist.action(action, *args)

    @pynvim.function("_gkeep_menu_action", sync=True)
    @unwrap_args
    def menu_action(self, action: str, *args) -> None:
        g.menu.action(action, *args)

    @pynvim.autocmd("BufReadCmd", "gkeep://*", eval='expand("<amatch>")', sync=True)
    def _load_note(self, address: str):
        url = BufUrl.parse(address)
        if not url:
            g.vim.err_write(f"Malformed Gkeep url {address}\n")
            return
        g.vim.command(f"silent doau BufReadPre {url}")
        g.noteview.render(g.vim.current.buffer, url)
        g.vim.command(f"silent doau BufReadPost {url}")

    @pynvim.autocmd("BufWriteCmd", "gkeep://*", eval='expand("<abuf>")', sync=True)
    def _save_note(self, bufnrstr: str) -> None:
        bufnr = int(bufnrstr)
        url = BufUrl.parse(g.vim.api.buf_get_name(bufnr))
        if not url:
            g.vim.err_write(f"Buffer {bufnrstr} has malformed Gkeep bufname\n")
            return
        g.noteview.save_buffer(bufnr)
        g.vim.command(f"silent doau BufWritePre {url}")
        g.vim.api.buf_set_option(bufnr, "modified", False)
        g.vim.command(f"silent doau BufWritePost {url}")
        g.vim.funcs._gkeep_sync()
        g.api.keep.sync()
        g.menu.refresh()

    def cmd_login(self, email: str = None, password: str = None) -> None:
        if email is None:
            last_email = g.config.email
            if last_email is not None:
                email = last_email
        if email is None:
            email = g.vim.funcs.input("Email:")
        token = g.api.keyring.get_password("google-keep-token", email)
        if token and password is None:
            g.api.keep.resume(email, token)
        else:
            if password is None:
                password = g.vim.funcs.input("Password:")
            g.api.keep.login(email, password)
            token = g.api.keep.getMasterToken()
            g.api.keyring.set_password("google-keep-token", email, token)
        g.config.email = email
        g.vim.out_write(f"Gkeep logged in {email}\n")

    def cmd_open(self, position: Position = Position.LEFT) -> None:
        g.menu.open(True, position)

    def cmd_toggle(self, position: Position = Position.LEFT) -> None:
        g.menu.toggle(True, position)

    def cmd_close(self) -> None:
        g.menu.close()

    def cmd_sync(self) -> None:
        g.api.keep.sync()
        g.menu.refresh()
