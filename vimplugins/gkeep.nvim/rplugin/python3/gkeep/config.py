import json
import os

import gkeep.globals as g
from gkeepapi import Keep


class Config:
    def __init__(self) -> None:
        cache_dir = g.vim.funcs.stdpath("cache")
        self._email = None
        self._cache_file = os.path.join(cache_dir, "gkeep.json")
        self._state_file = os.path.join(cache_dir, "gkeep_state.json")
        self.load_cache()

    def get_icon(self, icon: str) -> str:
        if icon == "archived":
            return " "
        elif icon == "trashed":
            return " "
        elif icon == "pinned":
            return "車"
        elif icon == "label":
            return " "
        elif icon == "home":
            return " "
        else:
            return ""

    @property
    def note_filetype(self) -> str:
        return "markdown"

    def checkbox(self, checked: bool) -> str:
        if checked:
            return "☑ "
        else:
            return "☐ "

    @property
    def email(self):
        return self._email

    @email.setter
    def email(self, email):
        self._email = email
        self.save_cache()

    def load_cache(self):
        file = self._cache_file
        if not os.path.isfile(file):
            return
        with open(file, "r") as ifile:
            data = json.load(ifile)
        self._email = data.get("email")

    def save_cache(self):
        with open(self._cache_file, "w") as ofile:
            json.dump({"email": self.email}, ofile)

    async def save_state(self, keep: Keep) -> None:
        pass
