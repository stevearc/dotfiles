import enum
from typing import List, Optional, Union

import gkeep.globals as g
from gkeep.view import View


class Position(enum.Enum):
    LEFT = "left"
    RIGHT = "right"


class MenuItem:
    def __init__(self, icon: str, name: str, query: str):
        self.icon = icon
        self.name = name
        self.query = query

    @property
    def title(self):
        return g.config.get_icon(self.icon) + self.name

    def __hash__(self) -> int:
        return hash(self.query)

    def __eq__(self, other) -> bool:
        return self.query == other.query

    def __ne__(self, other) -> bool:
        return not self.__eq__(other)


class Menu(View):
    def __init__(self) -> None:
        super().__init__()
        self._items: Optional[List[MenuItem]] = None

    def _get_item_under_cursor(self) -> Union[MenuItem, None]:
        mywin = self.get_win()
        line = g.vim.api.win_get_cursor(mywin)[0]
        idx = line - 1
        if idx >= len(self.items):
            return None
        return self.items[idx]

    def refresh(self):
        current_item = self._get_item_under_cursor()
        self._items = self._create_items()
        self.render()
        if current_item != self._get_item_under_cursor():
            self.cmd_select(False)

    def _create_items(self) -> List[MenuItem]:
        items = [MenuItem("home", "Home", "-at")]
        for label in g.api.keep.labels():
            items.append(MenuItem("label", label.name, f'l:"{label.name}" -at'))
        items.append(MenuItem("archived", "Archive", "+a"))
        items.append(MenuItem("trashed", "Trash", "+t"))
        return items

    @property
    def items(self) -> List[MenuItem]:
        if not self._items:
            self._items = self._create_items()
        return self._items

    def close(self):
        super().close()
        g.notelist.close()

    def open(self, enter: bool = True, position: Position = Position.LEFT) -> None:
        winid = self.get_win()
        if winid is not None:
            if enter:
                g.vim.api.set_current_win(winid)
            return
        startwin = g.vim.current.window
        if position == Position.LEFT:
            g.vim.command("noau vertical leftabove split")
        elif position == Position.RIGHT:
            g.vim.command("noau vertical rightbelow split")

        g.vim.api.win_set_option(0, "winfixwidth", True)
        g.vim.api.win_set_option(0, "winfixheight", True)
        g.vim.api.win_set_option(0, "number", False)
        g.vim.api.win_set_option(0, "relativenumber", False)
        g.vim.api.win_set_option(0, "signcolumn", "no")
        g.vim.api.win_set_option(0, "foldcolumn", "0")
        g.vim.api.win_set_option(0, "wrap", False)
        g.vim.api.win_set_width(0, 40)

        if self.bufnr is None:
            self._create_buffer()

        mywin = g.vim.current.window
        self.render()
        self.action("select")
        g.notelist.open()
        g.vim.api.win_set_height(mywin, 10)
        if enter:
            g.vim.current.window = mywin
        else:
            g.vim.current.window = startwin

    def _create_buffer(self) -> None:
        self._bufnr = g.vim.api.create_buf(False, True)
        g.vim.current.buffer = self.bufnr
        g.vim.api.buf_set_option(0, "buftype", "nofile")
        g.vim.api.buf_set_option(0, "bufhidden", "wipe")
        g.vim.api.buf_set_option(0, "swapfile", False)
        g.vim.api.buf_set_option(0, "filetype", "GoogleKeepMenu")
        g.vim.api.buf_set_option(0, "modifiable", False)

        self.keymap("<CR>", "<cmd>call _gkeep_menu_action('select', v:true)<CR>")
        self.keymap("q", "<cmd>Gkeep close<CR>")
        self.keymap("<c-r>", "<cmd>Gkeep sync<CR>")
        g.vim.command("au CursorMoved <buffer> call _gkeep_menu_action('select')")

    def toggle(self, enter: bool = True, position: Position = Position.LEFT) -> None:
        if self.is_visible:
            self.close()
        else:
            self.open(enter, position)

    def render(self):
        bufnr = self.bufnr
        if bufnr is None:
            return
        g.vim.api.buf_set_option(bufnr, "modifiable", True)
        lines = [item.title for item in self.items]
        g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        g.vim.api.buf_set_option(bufnr, "modifiable", False)

    def action(self, action: str, *args) -> None:
        kwargs = {}
        meth = f"cmd_{action}"
        if hasattr(self, meth):
            if len(args) == 1 and isinstance(args[0], dict):
                kwargs = args[0]
                args = ()
            getattr(self, meth)(*args, **kwargs)
        else:
            g.vim.err_write(f"Unknown Gkeep action '{action}'\n")

    def cmd_select(self, enter: Union[int, bool] = False) -> None:
        startwin = g.vim.current.window
        item = self._get_item_under_cursor()
        if item is None:
            return
        g.notelist.query = item.query

        winid = g.notelist.get_win()
        if winid:
            g.vim.current.window = winid
            g.notelist.cmd_select(False)
        if not enter:
            g.vim.current.window = startwin
