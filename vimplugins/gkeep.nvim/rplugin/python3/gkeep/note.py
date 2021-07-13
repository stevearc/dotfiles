import re
import typing as t

import gkeep.globals as g
from gkeep.util import BufUrl

SPACE_RE = re.compile(r"^\s*$")

if t.TYPE_CHECKING:
    from gkeepapi.node import List, ListItem, TopLevelNode


class NoteView:
    def render(self, bufnr: int, url: BufUrl) -> None:
        from gkeepapi.node import List as KeepList
        from gkeepapi.node import Note

        g.vim.api.buf_set_option(bufnr, "bufhidden", "wipe")
        note = g.api.keep.get(url.id)
        if note is None:
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, [])
            return
        url.title = note.title
        g.vim.api.buf_set_name(g.vim.current.buffer, str(url))

        lines: t.List[str] = []
        gen_header(lines, note)
        if isinstance(note, Note):
            lines.extend(note.text.split("\n"))
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        elif isinstance(note, KeepList):
            gen_list_body(lines, note)
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        else:
            g.vim.err_write(f"Unknown note type {type(note)}\n")
        g.vim.api.buf_set_option(bufnr, "modified", False)
        g.vim.api.buf_set_option(bufnr, "filetype", g.config.note_filetype)

    def save_buffer(self, bufnr: int) -> None:
        from gkeepapi.node import List as KeepList
        from gkeepapi.node import Note

        url = BufUrl.parse(g.vim.api.buf_get_name(bufnr))
        if url is None:
            return
        lines = g.vim.api.buf_get_lines(bufnr, 0, -1, True)
        note = g.api.keep.get(url.id)
        if note is None:
            g.vim.err_write(f"Note {url.id} not found\n")
            return

        parse_header(lines, note)
        url.title = note.title

        if isinstance(note, Note):
            note.text = "\n".join(lines)
        elif isinstance(note, KeepList):
            parse_list_body(lines, note)
            self.render(bufnr, url)
        else:
            g.vim.err_write(f"Unknown note type {type(note)}\n")

        g.vim.api.buf_set_name(g.vim.current.buffer, str(url))


def gen_header(lines: t.List[str], note: "TopLevelNode"):
    lines.append(f"# {note.title.strip()}")
    for label in note.labels.all():
        lines.append(f"/{label.name}")
    lines.append("")


def parse_header(lines: t.List[str], note: "TopLevelNode"):
    if lines[0].startswith("#"):
        note.title = lines.pop(0)[1:].strip()
    labels = []
    while lines[0].startswith("/"):
        label = lines.pop(0)[1:].strip()
        labels.append(g.api.keep.findLabel(label))
    for label in labels:
        if label not in note.labels.all():
            note.labels.add(label)
    for label in note.labels.all():
        if label not in labels:
            note.labels.remove(label)

    if lines and lines[0] == "":
        lines.pop(0)


def gen_list_body(lines: t.List[str], note: "List") -> None:
    for item in note.items:
        prefix = "  " if item.indented else ""
        lines.append(f"{prefix}{g.config.checkbox(item.checked)}{item.text}")


def _make_item_key(item: "ListItem"):
    return (getattr(item.parent_item, "id", None), item.checked, item.text)


def parse_list_body(lines: t.List[str], note: "List"):
    checked_str = g.config.checkbox(True)
    unchecked_str = g.config.checkbox(False)
    checkbox = "(" + re.escape(checked_str) + "|" + re.escape(unchecked_str) + ")"
    line_re = re.compile(r"^(\s*)" + checkbox + "(.*)$")

    items = {}
    for item in note.items:
        items[_make_item_key(item)] = item
        # g.vim.out_write(f"init: {_make_item_key(item)}\n")

    parent = None
    sort = 0
    for line in lines:
        match = line_re.match(line)
        if match:
            indented = bool(match[1])
            checked = match[2] == checked_str
            text = match[3]
        elif SPACE_RE.match(line):
            continue
        else:
            indented = line.startswith(" ")
            checked = False
            text = line.strip()

        if indented:
            # If the first element is indented, silently dedent it
            if parent is None:
                indented = False
        parent_id = None
        if indented and parent is not None:
            parent_id = parent.id
        key = (parent_id, checked, text)
        item = items.pop(key, None)
        if item is None:
            item = note.add(text, checked, sort)

        if indented:
            assert parent is not None
            checked = checked or parent.checked

        # g.vim.out_write(f"{key}\n")
        if item.sort != sort:
            item.sort = sort
        if item.text != text:
            item.text = text
        if item.checked != checked:
            item.checked = checked
        if item.indented != indented:
            if indented:
                assert parent is not None
                parent.indent(item)
            else:
                assert item.parent_item is not None
                item.parent_item.dedent(item)

        if not indented:
            parent = item

        sort -= 1000000

    for key, missing in items.items():
        assert missing.parent is not None
        # note.remove(missing)
        missing.delete()
