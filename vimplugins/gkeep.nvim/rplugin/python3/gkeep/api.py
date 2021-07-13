import re
import subprocess
import sys
from typing import TYPE_CHECKING, Any, Dict, Optional

if TYPE_CHECKING:
    from gkeepapi import Keep


FLAG_RE = re.compile(r"[+\-][pta]{1,3}", re.I)
COLOR_RE = re.compile(r"\b(?:c|color):([\w,]+)\b", re.I)
LABEL_RE = re.compile(r'\b(?:l|label):(?:"([^"]+)"|([\w,]+)\b)', re.I)
FLAG_MAP = {
    "p": "pinned",
    "a": "archived",
    "t": "trashed",
}


class KeepApi:
    def __init__(self):
        self._keep = None
        self._keyring = None

    def load(self):
        try:
            # pylint: disable=W0611
            import gkeepapi
            import keyring
        except ImportError:
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", "-q", "gkeepapi", "keyring"]
            )

    def parse_query(self, query: str = "") -> Dict[str, Any]:
        flags = {}
        for flag_match in FLAG_RE.finditer(query):
            flag_str = flag_match[0]
            for key in flag_str[1:]:
                flags[FLAG_MAP[key]] = flag_str[0] == "+"

        colors = None
        for color_match in COLOR_RE.finditer(query):
            if colors is None:
                colors = []
            colors.extend(color_match[1].upper().split(","))

        labels = None
        for label_match in LABEL_RE.finditer(query):
            if labels is None:
                labels = []
            if label_match[1]:
                label_objs = [self.keep.findLabel(s) for s in label_match[1].split(",")]
                labels.extend(label_objs)
            else:
                labels.append(self.keep.findLabel(label_match[2]))

        query = re.sub(FLAG_RE, "", query)
        query = re.sub(COLOR_RE, "", query)
        query = re.sub(LABEL_RE, "", query)
        findstr: Optional[str] = query.strip()
        if not findstr:
            findstr = None
        return {
            "labels": labels,
            "colors": colors,
            "query": findstr,
            **flags,
        }

    def logout(self):
        self._keep = None

    @property
    def keep(self) -> "Keep":
        if self._keep is None:
            self.load()
            import gkeepapi

            self._keep = gkeepapi.Keep()
        return self._keep

    @property
    def keyring(self):
        if self._keyring is None:
            self.load()
            import keyring

            self._keyring = keyring
        return self._keyring
