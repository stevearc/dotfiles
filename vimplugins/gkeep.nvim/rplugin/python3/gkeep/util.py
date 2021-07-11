from typing import TYPE_CHECKING, Union

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
