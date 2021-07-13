from functools import wraps
from typing import Optional

_status_stack = []


class Status:
    def __init__(self, msg: str):
        self.msg = msg

    def __enter__(self):
        _status_stack.append(self.msg)

    def __exit__(self, _type, _value, _traceback):
        _status_stack.pop()

    def __call__(self, f):
        @wraps(f)
        def d(*args, **kwargs):
            _status_stack.append(self.msg)
            try:
                return f(*args, **kwargs)
            finally:
                _status_stack.pop()

        return d


status = Status


def get_status() -> Optional[str]:
    if _status_stack:
        return _status_stack[-1]
    else:
        return None
