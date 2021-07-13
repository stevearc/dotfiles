import inspect
from functools import wraps
from threading import Lock
from typing import Any, List, Union

import gkeep.globals as g
import pynvim
from gkeep.menu import Position
from gkeep.status import get_status, status
from gkeep.util import BufUrl, run_in_background, shutdown

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
        vim.funcs.timer_start(10000, "_gkeep_sync", {"repeat": -1})
        self._sync_lock = Lock()

    def is_keep_buffer(self, bufnr: int) -> bool:
        return BufUrl.parse(g.vim.api.buf_get_name(bufnr)) is not None

    @pynvim.shutdown_hook
    def on_shutdown(self):
        shutdown()

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
    @status("Loading notes")
    def preload(self) -> None:
        run_in_background(self._preload)

    def _preload(self) -> None:
        email = g.config.email
        if email is not None:
            token = g.api.keyring.get_password("google-keep-token", email)
            if token:
                state = g.config.load_state()
                g.api.keep.resume(email, token, state=state)
                g.vim.async_call(g.menu.refresh)

    @pynvim.function("_gkeep_sync")
    @unwrap_args
    def sync_func(self, *args) -> None:
        if len(args) > 0:
            g.vim.err_write(f"Got unexpected args in sync: {args}\n")
        labels_updated = any((i.dirty for i in g.api.keep._labels.values()))
        dirty = labels_updated or bool(g.api.keep._findDirtyNodes())
        if dirty:
            self.sync()

    @status("Syncing changes")
    def sync(self) -> None:
        run_in_background(self._sync)

    def _sync(self) -> None:
        with self._sync_lock:
            g.api.keep.sync()
            g.vim.async_call(g.menu.refresh)
            g.config.save_state(g.api.keep.dump())

    @pynvim.function("_gkeep_list_action", sync=True)
    @unwrap_args
    def list_action(self, action: str, *args) -> None:
        g.notelist.action(action, *args)

    @pynvim.function("_gkeep_menu_action", sync=True)
    @unwrap_args
    def menu_action(self, action: str, *args) -> None:
        g.menu.action(action, *args)

    @pynvim.function("_gkeep_status", sync=True)
    @unwrap_args
    def get_status(self) -> Union[str, None]:
        s = get_status()
        if s is None:
            s = ""
        return s

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
        g.menu.refresh()
        self.sync()

    def cmd_logout(self) -> None:
        email = g.config.email
        if email is not None:
            g.api.keyring.delete_password("google-keep-token", email)
        g.api.logout()

    def cmd_login(self, email: str = None) -> None:
        if email is None:
            last_email = g.config.email
            if last_email is not None:
                email = last_email
        if email is None:
            email = g.vim.funcs.input("Email:")
        token = g.api.keyring.get_password("google-keep-token", email)
        if token:
            with status("Loading notes"):
                g.api.keep.resume(email, token, state=g.config.load_state())
        else:
            password = g.vim.funcs.input("Password:")
            with status("Loading notes"):
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
