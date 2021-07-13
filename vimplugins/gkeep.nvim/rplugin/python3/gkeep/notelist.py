import random
from functools import cmp_to_key
from typing import TYPE_CHECKING, Any, Dict, List, Union

import gkeep.globals as g
from gkeep.util import BufUrl
from gkeep.view import View

if TYPE_CHECKING:
    from gkeepapi.node import Note


def cmp(a: "Note", b: "Note") -> int:
    if a.pinned != b.pinned:
        return -1 if a.pinned else 1
    return int(b.sort) - int(a.sort)


class NoteList(View):
    def __init__(self) -> None:
        super().__init__()
        self._query = ""
        self._query_args: Dict[str, Any] = {}
        self._notes: List["Note"] = []

    @property
    def query(self) -> str:
        return self._query

    @query.setter
    def query(self, query: str):
        if self._query == query:
            return
        self._query = query
        self._query_args = g.api.parse_query(query)
        self.rerun_query()
        winid = self.get_win()
        if winid:
            g.vim.api.win_set_cursor(winid, [1, 0])

    def rerun_query(self, save_place: bool = False):
        note = self._get_note_under_cursor()
        self._notes = list(g.api.keep.find(**self._query_args))
        self._notes.sort(key=cmp_to_key(cmp))
        self.render()
        if note is not None and save_place:
            self._select_note(note)

    def _select_note(self, note: "Note"):
        try:
            idx = self.notes.index(note)
        except ValueError:
            pass
        else:
            g.vim.api.win_set_cursor(0, [idx + 1, 0])

    @property
    def notes(self) -> List["Note"]:
        return self._notes

    def open(self) -> None:
        winid = self.get_win()
        if winid is not None:
            return
        g.vim.command("noau rightbelow split")
        g.vim.api.win_set_option(0, "winfixwidth", True)
        g.vim.api.win_set_option(0, "number", False)
        g.vim.api.win_set_option(0, "relativenumber", False)
        g.vim.api.win_set_option(0, "signcolumn", "no")
        g.vim.api.win_set_option(0, "foldcolumn", "0")
        g.vim.api.win_set_option(0, "wrap", False)

        self._bufnr = g.vim.api.create_buf(False, True)
        g.vim.current.buffer = self.bufnr
        g.vim.api.buf_set_option(0, "buftype", "nofile")
        g.vim.api.buf_set_option(0, "bufhidden", "wipe")
        g.vim.api.buf_set_option(0, "swapfile", False)
        g.vim.api.buf_set_option(0, "filetype", "GoogleKeepList")
        g.vim.api.buf_set_option(0, "modifiable", False)

        self.keymap("<CR>", "<cmd>call _gkeep_list_action('select', v:true)<CR>")
        self.keymap("p", "<cmd>call _gkeep_list_action('pin')<CR>")
        self.keymap("a", "<cmd>call _gkeep_list_action('archive')<CR>")
        self.keymap("dd", "<cmd>call _gkeep_list_action('delete')<CR>")
        self.keymap("c", "<cmd>call _gkeep_list_action('new')<CR>")
        self.keymap("J", "<cmd>call _gkeep_list_action('move', 1)<CR>")
        self.keymap("K", "<cmd>call _gkeep_list_action('move', -1)<CR>")
        self.keymap("q", "<cmd>Gkeep close<CR>")
        self.keymap("<c-r>", "<cmd>Gkeep sync<CR>")
        g.vim.command("au CursorMoved <buffer> call _gkeep_list_action('select')")
        self.render()

    def render(self) -> None:
        bufnr = self.bufnr
        if bufnr is None:
            return
        g.vim.api.buf_set_option(bufnr, "modifiable", True)
        lines = []
        for note in self.notes:
            entry = note.title.strip()
            if not entry:
                entry = "<No title>"
            if note.pinned:
                entry = g.config.get_icon("pinned") + entry
            if note.trashed and not self._query_args.get("trashed"):
                entry = g.config.get_icon("trashed") + entry
            if note.archived and not self._query_args.get("archived"):
                entry = g.config.get_icon("archived") + entry

            lines.append(entry)
        if not lines:
            lines.append("   <No results>")
        g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        g.vim.api.buf_set_option(bufnr, "modifiable", False)

    def _get_note_under_cursor(self) -> Union["Note", None]:
        mywin = self.get_win()
        if mywin is None:
            return None
        line = g.vim.api.win_get_cursor(mywin)[0]
        idx = line - 1
        if idx >= len(self.notes):
            return None
        return self.notes[idx]

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

    def cmd_select(self, enter: bool = False) -> None:
        startwin = g.vim.current.window
        note = self._get_note_under_cursor()
        if note is None:
            return
        self._edit_note(note)
        if not enter:
            g.vim.current.window = startwin

    def _edit_note(self, note: "Note") -> None:
        url = BufUrl(note)
        winid = self.get_normal_win()
        g.vim.current.window = winid
        g.vim.command(f"edit {url}")
        # If we're inside an autocmd (e.g. CursorMoved), we won't automatically fire the BufReadCmd properly
        if (
            g.vim.api.buf_line_count(0) == 1
            and g.vim.api.buf_get_lines(0, 0, 1, True)[0] == ""
        ):
            g.vim.command(f"doau BufReadCmd {url}")

    def cmd_pin(self) -> None:
        note = self._get_note_under_cursor()
        if note is None:
            return
        note.pinned = not note.pinned
        self.rerun_query(True)

    def cmd_archive(self) -> None:
        note = self._get_note_under_cursor()
        if note is None:
            return
        note.archived = not note.archived
        self.rerun_query()

    def cmd_delete(self) -> None:
        note = self._get_note_under_cursor()
        if note is None:
            return
        if note.trashed:
            note.untrash()
            g.vim.err_write("\nWarning: undeleting notes seems to not work right now\n")
        else:
            note.trash()
        self.rerun_query()

    def cmd_new(self) -> None:
        note = g.api.keep.createNote("New note")
        note.pinned = self._query_args.get("pinned")
        labels = self._query_args.get("labels")
        if labels:
            for label in labels:
                note.labels.add(label)

        colors = self._query_args.get("colors")
        if colors and len(colors) == 1:
            note.color = colors[0]
        self.rerun_query()
        self._select_note(note)

    def cmd_move(self, steps: Union[int, str]) -> None:
        steps = int(steps)
        note = self._get_note_under_cursor()
        if note is None:
            return
        idx = self.notes.index(note)
        newidx = idx + steps
        if newidx < 0 or newidx >= len(self.notes):
            return
        if newidx == 0:
            low = int(self.notes[newidx].sort)
            hi = max(9999999999, low + 1000000)
        elif newidx == len(self.notes) - 1:
            hi = int(self.notes[newidx - 1].sort)
            low = min(0, hi - 1000000)
        else:
            offset = 0 if steps < 0 else 1
            n_hi = self.notes[newidx - 1 + offset]
            n_low = self.notes[newidx + offset]
            hi = int(n_hi.sort)
            low = int(n_low.sort)
            if note.pinned and not n_hi.pinned:
                return
            elif not note.pinned and n_low.pinned:
                return
            elif n_hi.pinned != n_low.pinned:
                if note.pinned:
                    low = min(0, hi - 1000000)
                else:
                    hi = max(9999999999, low + 1000000)
        note.sort = random.randint(low, hi)
        self.notes.pop(idx)
        self.notes.insert(newidx, note)
        self.render()
        g.vim.api.win_set_cursor(0, [newidx + 1, 0])

    def get_normal_win(self) -> int:
        for winid in g.vim.api.tabpage_list_wins(0):
            if self.is_normal_win(winid):
                return winid
        g.vim.command("noau vsplit")
        return g.vim.current.window
