from typing import Optional

import gkeep.globals as g


class View:
    def __init__(self):
        self._bufnr = None

    @property
    def bufnr(self) -> Optional[int]:
        if self._bufnr is not None and g.vim.api.buf_is_valid(self._bufnr):
            return self._bufnr
        return None

    @property
    def is_visible(self):
        return self.get_win() is not None

    def get_win(self) -> Optional[int]:
        bufnr = self.bufnr
        if bufnr is None:
            return None
        for winid in g.vim.api.tabpage_list_wins(0):
            if bufnr == g.vim.api.win_get_buf(winid):
                return winid
        return None

    @property
    def is_inside(self):
        return g.vim.current.buffer == self.bufnr

    def close(self) -> None:
        winid = self.get_win()
        if winid is not None:
            g.vim.api.win_close(winid, True)

    def is_normal_win(self, winid) -> bool:
        if g.vim.api.win_get_config(winid)["relative"] != "":
            return False
        if g.vim.funcs.win_gettype(winid) != "":
            return False
        bufnr = g.vim.api.win_get_buf(winid)
        if g.vim.api.buf_get_option(bufnr, "buftype") != "":
            return False
        return True

    def keymap(self, lhs: str, rhs: str) -> None:
        g.vim.api.buf_set_keymap(0, "n", lhs, rhs, {"silent": True, "noremap": True})
