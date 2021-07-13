import json
import os
from typing import Any, Union

import gkeep.globals as g
from gkeep.util import run_in_background


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

    def save_state(self, state: Any) -> None:
        run_in_background(self._save_state, state)

    def _save_state(self, state: Any) -> None:
        with open(self._state_file, "w") as ofile:
            json.dump(state, ofile)

    def load_state(self) -> Union[Any, None]:
        return run_in_background(self._load_state)

    def _load_state(self) -> Union[Any, None]:
        if not os.path.isfile(self._state_file):
            return None
        with open(self._state_file, "r") as ifile:
            return json.load(ifile)
