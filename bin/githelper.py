#!/usr/bin/env python
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from typing import Dict, List, Optional, Tuple


def run(*args, **kwargs) -> str:
    kwargs.setdefault("check", True)
    kwargs.setdefault("capture_output", True)
    try:
        stdout = subprocess.run(args, **kwargs).stdout
    except subprocess.CalledProcessError as e:
        print("Error running: ", " ".join(args))
        if e.stdout is not None:
            print(e.stdout.decode("utf-8"))
        if e.stderr is not None:
            print(e.stderr.decode("utf-8"))
        raise
    if stdout is None:
        return ""
    else:
        return stdout.decode("utf-8").strip()


def git(*args, **kwargs) -> str:
    return run(*(("git",) + args), **kwargs)


def gh(*args, **kwargs) -> str:
    if shutil.which("gh") is None:
        print("Missing gh executable")
        sys.exit(1)
    return run(*(("gh",) + args), **kwargs)


def git_lines(*args, **kwargs) -> List[str]:
    ret = git(*args, **kwargs)
    if ret:
        return ret.split("\n")
    else:
        return []


def remote_main_branch() -> str:
    proc = subprocess.run(
        ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
        capture_output=True,
        check=False,
    )
    if proc.returncode == 0:
        return proc.stdout.decode("utf-8").split("/")[-1].strip()
    return "master"


MASTER = remote_main_branch()
ORIGIN_MASTER = "origin/" + MASTER
USER = os.environ["USER"]
STACK_RE = re.compile(r"^(.*)\-(\d+)$")


class Stack:
    def __init__(self, name: str, children: List[str]):
        self.name = name
        self.children = children
        self.pull_requests = []
        self.pr_map = {}

    def add_child(self, branch: str):
        self.children.append(branch)
        self.children.sort(key=lambda x: int(STACK_RE.match(x)[2]))

    def rebase(self, target: str):
        rebase_branches(target, self.children + [self.name])

    def load_prs(self):
        prs = json.loads(gh("pr", "status", "--json", "title,body,number,headRefName"))
        self.pr_map = {
            pr["headRefName"]: PullRequest(
                pr["number"], pr["title"], pr["body"], pr["headRefName"]
            )
            for pr in prs["createdBy"]
        }
        self.pull_requests = []
        for child in self.children:
            if child in self.pr_map:
                self.pull_requests.append(self.pr_map[child])

    def update_prs(self):
        total = len(self.pull_requests)
        for i, pr in enumerate(self.pull_requests):
            pr.set_title(i + 1, total, pr.title)
        for pr in self.pull_requests:
            pr.set_table(self.pull_requests)

    def get_next_base(self) -> str:
        if self.children:
            return self.children[-1]
        else:
            return merge_base(self.name)

    def next_child(self) -> str:
        if self.children:
            num = int(STACK_RE.match(self.children[-1])[2])
            return f"{self.name}-{num+1}"
        else:
            return self.name + "-1"

    def tidy(self):
        cur = current_branch()
        i = 0
        while i < len(self.children):
            top = self.children[i]
            children = child_branches(top)
            if len(children) != len(self.children) - i:
                rebase_branches(top, self.children[i + 1 :] + [self.name])
            i += 1
        switch_branch(cur)

    def get_stack_graph(self) -> str:
        return git(
            "log", "--format=%h %d %s", merge_base(self.name) + "..." + self.name
        )

    def __str__(self) -> str:
        return self.name + ": " + ", ".join(self.children)


PR_TITLE_RE = re.compile(r"^(WIP)?\s*(\[\d+/\d+\])?\s*(.*)$")


class PullRequest:
    def __init__(self, number: int, title: str, body: str, headRefName: str):
        match = PR_TITLE_RE.match(title)
        self.number = number
        self.raw_title = title
        self.raw_body = body
        self.table, self.body = parse_markdown_table(body)
        self.branch = headRefName
        self.wip = match[1]
        self.count = match[2]
        self.title = match[3]

    @staticmethod
    def make_title(wip: bool, index: int, total: int, title: str) -> str:
        ret = f"[{index}/{total}] {title}"
        if wip:
            ret = "WIP " + ret
        return ret

    def set_title(self, index: int, total: int, title: str):
        new_title = PullRequest.make_title(self.wip, index, total, title)
        if new_title != self.raw_title:
            gh("pr", "edit", str(self.number), "-t", new_title, capture_output=False)
            self.title = title
            self.raw_title = new_title

    def set_table(self, stack_prs: List["PullRequest"]):
        rows = []
        for i, pr in enumerate(stack_prs):
            row = {"PR": f"#{pr.number}", "Title": pr.title, "": str(i + 1)}
            if pr.number == self.number:
                row["PR"] = f">{pr.number}"
            rows.append(row)
        table = make_markdown_table(rows, ["", "PR", "Title"])
        if table != self.table:
            new_body = table + "\r\n" + self.body
            gh("pr", "edit", str(self.number), "-b", new_body, capture_output=False)
            self.raw_body = new_body
            self.table = table

    @property
    def is_wip(self) -> bool:
        return bool(self.wip)


def parse_markdown_table(body: str) -> Tuple[str, str]:
    table = []
    rest = []
    lines = body.split("\r\n")
    for i, line in enumerate(lines):
        if line.startswith("|"):
            table.append(line)
        else:
            rest = lines[i:]
            break
    return "\r\n".join(table), "\r\n".join(rest)


def make_markdown_table(data: List[Dict[str, str]], cols: List[str]) -> str:
    max_width = [len(col) for col in cols]
    for row in data:
        for i, col in enumerate(cols):
            max_width[i] = max(max_width[i], len(row[col]))

    lines = [
        "| "
        + " | ".join([col.center(max_width[i]) for i, col in enumerate(cols)])
        + " |",
        "| " + " | ".join([max_width[i] * "-" for i in range(len(cols))]) + " |",
    ]
    for row in data:
        lines.append(
            "| "
            + " | ".join([row[col].ljust(max_width[i]) for i, col in enumerate(cols)])
            + " |",
        )
    return "\n".join(lines)


def list_branches() -> List[str]:
    return [b.strip() for b in git_lines("branch", "--format=%(refname:short)")]


def list_merged_branches(branch: str = ORIGIN_MASTER) -> List[str]:
    return [
        b.strip()
        for b in git_lines("branch", "--format=%(refname:short)", "--merged", branch)
    ]


def current_branch() -> str:
    return git("branch", "--show-current")


def delete_branch(branch: str, force: bool = False):
    flag = "-D" if force else "-d"
    return git("branch", flag, branch)


def current_stack() -> str:
    b = current_branch()
    match = STACK_RE.match(b)
    if match:
        return match[1]
    else:
        return b


def get_stack(name: str) -> Optional[Stack]:
    if name == "." or name == "@":
        name = current_stack()
    for stack in list_stacks():
        if stack.name == name:
            return stack
    return None


def get_repo_url() -> str:
    url = git("remote", "get-url", "origin")
    if url.startswith("http"):
        if url.endswith(".git"):
            url = url[:-4]
    else:
        url = re.sub(r"^.*@", "", url)
        url = "https://" + url.replace(":", "/")
    return url


def list_stacks() -> List[Stack]:
    stacks = {}
    merged = list_merged_branches()
    for branch in list_branches():
        if branch in merged:
            continue
        match = STACK_RE.match(branch)
        if match:
            name, num = match[1], match[2]
            if name in stacks:
                stacks[name].add_child(branch)
            else:
                stacks[name] = Stack(name, [branch])
        elif branch not in stacks:
            stacks[branch] = Stack(branch, [])

    return list(stacks.values())


def refs_between(ref1: str, ref2: str) -> List[str]:
    """Exclusive on ref1, inclusive on ref2"""
    return list(reversed(git_lines("log", ref1 + "..." + ref2, "--format=%H")))


# FIXME this doesn't work if we want to either a) amend a commit and change a new file or b) reword the commit
# FIXME need to warn/error if there are two commits in the same history with the same fingerprint
_fingerprints = {}


def fingerprint_commit(ref: str) -> str:
    if ref not in _fingerprints:
        summary = git("log", "--name-only", "--format=%an %ae %B", "-n", "1", ref)
        _fingerprints[ref] = hashlib.md5(summary.encode("utf-8")).hexdigest()
    return _fingerprints[ref]


def find_branch_start(target: str, branch: str) -> str:
    target_mb = merge_base(target)
    branch_mb = merge_base(branch)
    target_commits = refs_between(target_mb, target)
    branch_commits = refs_between(branch_mb, branch)
    ret = branch_mb
    for (target_commit, branch_commit) in zip(target_commits, branch_commits):
        if fingerprint_commit(target_commit) != fingerprint_commit(branch_commit):
            break
        ret = branch_commit
    return ret


def rev_parse(ref: str) -> str:
    return git("rev-parse", "--verify", ref)


def rebase_branches(target: str, branches: List[str]):
    branch_start = None
    for branch in branches:
        next_branch_start = rev_parse(branch)
        if branch_start is None:
            branch_start = find_branch_start(target, branch)
        git("rebase", "--onto", target, branch_start, branch)
        target = branch
        branch_start = next_branch_start


def merge_base(branch: str, ref2: str = ORIGIN_MASTER) -> str:
    return git("merge-base", branch, "origin/" + MASTER)


def child_branches(ref: str) -> List[str]:
    return [
        b
        for b in git_lines("branch", "--contains", ref, "--format=%(refname:short)")
        if b != ref
    ]


def make_stack(branch: Optional[str] = None):
    cur = current_branch()
    if branch is None or branch == "." or branch == "@":
        branch = current_stack()
    stack = get_stack(branch)
    if stack is None:
        raise ValueError(f"Could not create stack for branch {branch}")
    # Make sure we're on a tidy stack first
    stack.tidy()
    base = stack.get_next_base()
    for commit in refs_between(base, stack.name):
        child = stack.next_child()
        git("checkout", "-b", child, commit)
        stack.add_child(child)
    switch_branch(cur)


def switch_branch(branch: str):
    git("checkout", branch)


def create_branch(branch: str, start: str = MASTER):
    git("checkout", "-b", branch, start)


def touch_file(filename: str, contents: str = ""):
    with open(filename, "w", encoding="utf-8") as ofile:
        ofile.write(contents)


def exit_if_dirty():
    output = git("status", "--porcelain")
    if output:
        sys.stderr.write("Working directory is dirty\n")
        sys.exit(1)


def _add_cmd_stack(parser):
    subparsers = parser.add_subparsers(dest="stack_cmd")

    list_parser = subparsers.add_parser("list")
    list_parser.add_argument(
        "-c", "--children", action="store_true", help="Show children of stack"
    )
    subparsers.add_parser("create")
    tidy_parser = subparsers.add_parser("tidy")
    tidy_parser.add_argument("branch", nargs="?")
    subparsers.add_parser("clean")
    push_parser = subparsers.add_parser("push")
    push_parser.add_argument("branch", nargs="?")
    push_parser.add_argument("-f", action="store_true")
    pr_parser = subparsers.add_parser("pr")
    pr_parser.add_argument("branch", nargs="?")
    prev_parser = subparsers.add_parser("prev")
    prev_parser.add_argument("count", nargs="?", type=int, default=1)
    next_parser = subparsers.add_parser("next")
    next_parser.add_argument("count", nargs="?", type=int, default=1)
    next_parser = subparsers.add_parser("tip")
    next_parser = subparsers.add_parser("first")
    del_parser = subparsers.add_parser("delete")
    del_parser.add_argument("name", nargs="?")
    rebase_parser = subparsers.add_parser("rebase")
    rebase_parser.add_argument("target")
    subparsers.add_parser("reset_remote")


def navigate_stack_relative(count: int):
    stack = get_stack(current_stack())
    if stack is None:
        sys.stderr.write("Not on a stack branch\n")
        sys.exit(1)
    cur = current_branch()
    branches = stack.children + [stack.name]
    idx = branches.index(cur)
    new_idx = max(0, min(len(branches) - 1, idx + count))
    switch_branch(branches[new_idx])
    print(stack.get_stack_graph())


def cmd_stack(args, parser):
    if "stack_cmd" not in args or args.stack_cmd == "list":
        for stack in list_stacks():
            if args.children:
                print(stack)
            else:
                print(stack.name)
    elif args.stack_cmd == "create":
        make_stack()
    elif args.stack_cmd == "tidy":
        if args.branch is None:
            stacks = list_stacks()
            for stack in stacks:
                stack.tidy()
        else:
            stack = get_stack(args.branch)
            if stack is None:
                print("Could not find stack", args.branch)
                sys.exit(1)
            stack.tidy()
    elif args.stack_cmd == "clean":
        print("TODO delete merged branches")
    elif args.stack_cmd == "push":
        if args.branch is None:
            args.branch = current_stack()
        stack = get_stack(args.branch)
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        cur = current_branch()
        for branch in stack.children:
            switch_branch(branch)
            git_args = ["push", "-u", "origin", branch]
            if args.f:
                git_args.insert(1, "--force-with-lease")
            git(*git_args, capture_output=False)
        switch_branch(cur)
    elif args.stack_cmd == "pr":
        url = get_repo_url()
        if args.branch is None:
            args.branch = current_stack()
        stack = get_stack(args.branch)
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        stack.load_prs()
        rel = MASTER
        for branch in stack.children:
            if branch not in stack.pr_map:
                print(f"{url}/compare/{rel}...{branch}?expand=1")
            rel = branch
        stack.update_prs()
    elif args.stack_cmd == "rebase":
        exit_if_dirty()
        stack = get_stack("@")
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        stack.rebase(args.target)
    elif args.stack_cmd == "prev":
        navigate_stack_relative(-1 * args.count)
    elif args.stack_cmd == "next":
        navigate_stack_relative(args.count)
    elif args.stack_cmd == "tip":
        navigate_stack_relative(10000)
    elif args.stack_cmd == "first":
        navigate_stack_relative(-10000)
    elif args.stack_cmd == "reset_remote":
        exit_if_dirty()
        cur = current_branch()
        stack = get_stack(current_stack())
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        for branch in stack.children:
            switch_branch(branch)
            git("reset", "--hard", "origin/" + branch)
        switch_branch(cur)
    elif args.stack_cmd == "delete":
        if args.name:
            stack = get_stack(args.name)
        else:
            stack = get_stack(current_stack())
        if stack is None:
            sys.stderr.write("Not a valid stack branch\n")
            sys.exit(1)
        for branch in stack.children:
            delete_branch(branch, True)
    else:
        parser.print_help()


def _add_cmd_update(parser):
    parser.add_argument(
        "-l",
        "--local",
        action="store_true",
        help="Rebase local branches, do not do a fetch",
    )
    parser.add_argument(
        "-r",
        "--rebase",
        action="store_true",
        help="Rebase all local branches after updating",
    )
    parser.add_argument(
        "target",
        nargs="?",
        help="Target branch to rebase atop (default %(default)s)",
        default=MASTER,
    )


def cmd_update(args):
    cur = current_branch()
    if not args.local:
        git("fetch", capture_output=False)
        for branch in list_branches():
            # FIXME This is to catch master-passing-tests. There's probably a better way to do this.
            if branch.startswith(MASTER):
                git("rebase", "origin/" + branch, branch)
    if args.rebase or args.local:
        # FIXME this doesn't work well if part of a stack has been merged
        stack = get_stack("stevearc-TEST")
        for stack in list_stacks():
            print("Rebasing", stack.name)
            stack.rebase(args.target)
    switch_branch(cur)


def _add_cmd_test(parser):
    parser.add_argument(
        "test_cmd",
        default="tidy_stack",
        choices=["tidy_stack", "tidy_rebase", "clean", "old_stack", "incomplete_stack"],
    )


def cmd_test(args):
    test_branch_name = f"{USER}-TEST"
    if args.test_cmd == "clean":
        switch_branch(MASTER)
        for branch in list_branches():
            if branch.startswith(test_branch_name):
                delete_branch(branch, True)
    elif args.test_cmd == "tidy_stack":
        create_branch(test_branch_name)
        git("commit", "--allow-empty", "-m", "Test commit 1")
        git("commit", "--allow-empty", "-m", "Test commit 2")
        git("commit", "--allow-empty", "-m", "Test commit 3")
        make_stack()
        switch_branch(test_branch_name + "-2")
        git("commit", "--allow-empty", "-m", "Fix up a PR")
        switch_branch(test_branch_name)
    elif args.test_cmd == "tidy_rebase":
        create_branch(test_branch_name, MASTER + "^")
        git("commit", "--allow-empty", "-m", "Test commit 1")
        git("commit", "--allow-empty", "-m", "Test commit 2")
        git("commit", "--allow-empty", "-m", "Test commit 3")
        make_stack()
        switch_branch(test_branch_name + "-1")
        git("rebase", MASTER)
        switch_branch(test_branch_name)
    elif args.test_cmd == "old_stack":
        create_branch(test_branch_name, MASTER + "^")
        git("commit", "--allow-empty", "-m", "Test commit 1")
        git("commit", "--allow-empty", "-m", "Test commit 2")
        git("commit", "--allow-empty", "-m", "Test commit 3")
        make_stack()
    elif args.test_cmd == "incomplete_stack":
        create_branch(test_branch_name, MASTER + "^")
        git("commit", "--allow-empty", "-m", "Test commit 1")
        git("commit", "--allow-empty", "-m", "Test commit 2")
        make_stack()
        git("commit", "--allow-empty", "-m", "Test commit 3")
        git("commit", "--allow-empty", "-m", "Test commit 4")
    else:
        print(f"Unknown test command {args.test_cmd}")


def main() -> None:
    """Main method"""
    parser = argparse.ArgumentParser(description=main.__doc__)

    subparsers = parser.add_subparsers(dest="cmd")

    stack_parser = subparsers.add_parser("stack")
    _add_cmd_stack(stack_parser)
    _add_cmd_test(subparsers.add_parser("test"))
    _add_cmd_update(subparsers.add_parser("update"))

    args = parser.parse_args()

    if args.cmd == "stack":
        cmd_stack(args, stack_parser)
    elif args.cmd == "update":
        cmd_update(args)
    elif args.cmd == "test":
        cmd_test(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
