import gkeep.globals as g
from gkeep.util import BufUrl


class NoteView:
    def render(self, bufnr: int, url: BufUrl) -> None:
        g.vim.api.buf_set_option(bufnr, "bufhidden", "wipe")
        note = g.api.keep.get(url.id)
        if note is None:
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, [])
            return
        url.title = note.title
        g.vim.api.buf_set_name(g.vim.current.buffer, str(url))

        from gkeepapi.node import NodeType

        lines = [f"# {note.title.strip()}"]
        for label in note.labels.all():
            lines.append(f"/{label.name}")
        lines.append("")
        if note._TYPE == NodeType.Note:
            lines.extend(note.text.split("\n"))
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        elif note._TYPE == NodeType.List:
            lines.extend(note.text.split("\n"))
            g.vim.api.buf_set_lines(bufnr, 0, -1, True, lines)
        else:
            g.vim.err_write(f"Unknown note type {note._TYPE}\n")
        g.vim.api.buf_set_option(bufnr, "modified", False)
        g.vim.api.buf_set_option(bufnr, "filetype", g.config.note_filetype)

    def save_buffer(self, bufnr: int) -> None:
        url = BufUrl.parse(g.vim.api.buf_get_name(bufnr))
        if url is None:
            return
        lines = g.vim.api.buf_get_lines(bufnr, 0, -1, True)
        note = g.api.keep.get(url.id)
        if note is None:
            note = g.api.keep.createNote()
            url.id = note.id

        if lines[0].startswith("#"):
            url.title = lines.pop(0)[1:].strip()
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

        note.title = url.title
        note.text = "\n".join(lines)

        g.vim.api.buf_set_name(g.vim.current.buffer, str(url))
