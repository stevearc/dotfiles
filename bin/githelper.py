#!/usr/bin/env python
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from typing import Any, Dict, List, Literal, Optional, Tuple, overload

DEBUG = False

# TODO
# - Extend a stack that has already been merged by passing in a PR


def run(*args, **kwargs) -> str:
    kwargs.setdefault("check", True)
    kwargs.setdefault("capture_output", True)
    silence = kwargs.pop("silence", False)
    if DEBUG:
        print("RUN:", args)
    try:
        stdout = subprocess.run(args, **kwargs).stdout
    except subprocess.CalledProcessError as e:
        if not silence:
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
        sys.stderr.write("Missing gh executable\n")
        sys.exit(1)

    return run("gh", *args, **kwargs)


def has_gh() -> bool:
    proc = subprocess.run(
        ["gh", "auth", "status"],
        capture_output=True,
        check=False,
    )
    return proc.returncode == 0


def git_lines(*args, **kwargs) -> List[str]:
    ret = git(*args, **kwargs)
    if ret:
        return ret.splitlines()
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
    def __init__(self, name: str):
        self.name = name
        self._children: List["Child"] = []

    def finalize(self):
        """Record all children that must have been merged"""
        if not self._children:
            return
        for i in range(1, self._children[0].index):
            self._children.append(
                Child(self.name, i, is_merged=True, local_exists=False)
            )
        self._children.sort(key=lambda x: x.index)

    def add_child(self, child: "Child"):
        self._children.append(child)
        self._children.sort(key=lambda x: x.index)

    def unmerged_children(self, before_branch: Optional[str] = None) -> List["Child"]:
        children = [child for child in self._children if not child.is_merged]
        if before_branch:
            ret = []
            for child in children:
                ret.append(child)
                if child.branch == before_branch:
                    break
            children = ret
        return children

    def all_children(self) -> List["Child"]:
        return [child for child in self._children]

    def load_prs(self):
        if not self._children:
            return
        try:
            prs = json.loads(
                gh(
                    "pr",
                    "status",
                    "--json",
                    "title,body,number,headRefName,url,isDraft",
                    silence=True,
                )
            )
        except subprocess.CalledProcessError:
            # This can happen if gh isn't installed, authed, or set up for the current repo
            return
        pr_map: Dict[str, "PullRequest"] = {
            pr["headRefName"]: PullRequest.from_json(pr) for pr in prs["createdBy"]
        }
        for child in self._children:
            pr = pr_map.get(child.branch)
            if pr:
                child.pull_request = pr

        # gh pr status doesn't show closed PRs, so we need to fetch them separately
        any_new_prs = True
        while any_new_prs and pr_map and not self._children[0].pull_request:
            any_new_prs = False
            prs = [child.pull_request for child in self._children if child.pull_request]
            if not prs:
                return
            first_pr = prs[0]
            pr_table = first_pr.parse_pr_table()
            for child_idx, pr_num in pr_table.items():
                child = self._children[child_idx - 1]
                if child.pull_request:
                    continue
                pr = PullRequest.from_ref(str(pr_num))
                child.pull_request = pr
                any_new_prs = True

    def __len__(self) -> int:
        return len(self._children)

    def create_prs(self, before_branch: Optional[str] = None) -> List["Child"]:
        total = len(self)
        created = []
        rel = MASTER
        body_file = os.path.join(
            git("rev-parse", "--show-toplevel"), ".github", "PULL_REQUEST_TEMPLATE.md"
        )
        for i, child in enumerate(self.unmerged_children(before_branch)):
            pr = child.pull_request
            if not pr:
                commit_line = git_lines("log", "-n", "1", "--format=%B", child.branch)[
                    0
                ].strip()
                title = PullRequest.get_title(i + 1, total, commit_line, True)
                gh(
                    "pr",
                    "create",
                    "--head",
                    child.branch,
                    "-B",
                    rel,
                    "-d",
                    "-t",
                    title,
                    "-F",
                    body_file,
                    capture_output=False,
                )
                child.pull_request = PullRequest.from_ref(child.branch)
                created.append(child)
            rel = child.branch
        return created

    def update_prs(self) -> List["Child"]:
        total = len(self)
        updated = set()

        for i, child in enumerate(self._children):
            pr = child.pull_request
            if pr is not None and pr.set_title(i + 1, total, pr.title):
                updated.add(child)
        pull_requests = [
            child.pull_request
            for child in self._children
            if child.pull_request is not None
        ]
        for child in self._children:
            pr = child.pull_request
            if pr is not None and pr.set_table(pull_requests):
                updated.add(child)
        return list(updated)

    def get_next_base(self) -> str:
        if self._children:
            return self._children[-1].branch
        else:
            return merge_base(self.name)

    def create_next_child(self) -> "Child":
        idx = 1
        if self._children:
            idx = self._children[-1].index + 1
        return Child(self.name, idx, is_merged=False, local_exists=False)

    def unmerged_branches(self, before_branch: Optional[str] = None) -> List[str]:
        children = [child.branch for child in self.unmerged_children(before_branch)]
        if before_branch is None or before_branch == self.name:
            children += [self.name]
        return children

    def needs_restack(self) -> bool:
        unmerged_children = self.unmerged_children()
        if not unmerged_children:
            return False
        for i, top in enumerate(unmerged_children):
            contains = set(child_branches(top.branch))
            for child in unmerged_children[i + 1 :]:
                if child.branch not in contains:
                    return True
            if self.name not in contains:
                return True
        return False

    def is_incomplete(self) -> bool:
        unmerged_children = self.unmerged_children()
        if not unmerged_children:
            return False
        return rev_parse(unmerged_children[-1].branch) != rev_parse(self.name)

    def rebase(self, target: Optional[str] = None):
        cur = current_branch()
        unmerged_children = self.unmerged_children()
        if not unmerged_children:
            if target is not None:
                git("rebase", target, self.name)
                switch_branch(cur)
            return
        first_child_branch = unmerged_children[0].branch
        last_child_branch = unmerged_children[-1].branch
        last_child_rev = rev_parse(last_child_branch)
        tip_rev = rev_parse(self.name)

        if target is not None:
            base = merge_base(first_child_branch, target)
            parent = find_branch_parent(base, first_child_branch)
            git("rebase", "--onto", target, parent, first_child_branch)

        root = merge_base(first_child_branch)
        for i, top in enumerate(unmerged_children[:-1]):
            next_branch = unmerged_children[i + 1].branch
            tag_commits(top.branch, f"{root}..{top.branch}")
            if next_branch not in child_branches(top.branch):
                first_rev = find_branch_parent(top.branch, next_branch)
                git("rebase", "--onto", top.branch, first_rev, next_branch)
            root = top.branch

        if last_child_rev == tip_rev:
            switch_branch(self.name)
            git("reset", "--hard", last_child_branch)
        elif self.name not in child_branches(last_child_branch):
            git("rebase", "--onto", last_child_branch, last_child_rev, self.name)

        switch_branch(cur)

    def get_stack_graph(self) -> str:
        return git(
            "log", "--format=%h %d %s", merge_base(self.name) + "..." + self.name
        )


PR_TITLE_RE = re.compile(r"^(\[\d+/\d+\])?\s*(WIP:)?\s*(.*)$")
PR_TABLE_LINE_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*[#>](\d+)")


class PullRequest:
    def __init__(self, number: int, title: str, body: str, url: str, is_draft: bool):
        match = PR_TITLE_RE.match(title)
        assert match
        self.number = number
        self.raw_title = title
        self.title = match[3]
        self.raw_body = body
        self.table, self.body = parse_markdown_table(body)
        self.url = url
        self.is_draft = is_draft

    def __hash__(self) -> int:
        return self.number

    def __eq__(self, other) -> bool:
        if not isinstance(other, PullRequest):
            return False
        return self.number == other.number

    @classmethod
    def from_ref(cls, num_or_branch) -> "PullRequest":
        return cls.from_json(
            json.loads(
                gh(
                    "pr",
                    "view",
                    num_or_branch,
                    "--json",
                    "title,body,number,url,isDraft",
                )
            )
        )

    @classmethod
    def from_json(cls, json: Dict[str, Any]) -> "PullRequest":
        return cls(
            json["number"],
            json["title"],
            json["body"],
            json["url"],
            json["isDraft"],
        )

    def parse_pr_table(self) -> Dict[int, int]:
        """Return a mapping of child index to PR number"""
        ret = {}
        for line in self.table.splitlines():
            match = PR_TABLE_LINE_RE.match(line)
            if match:
                ret[int(match[1])] = int(match[2])
        return ret

    @staticmethod
    def get_title(index: int, total: int, title: str, is_draft: bool) -> str:
        wip = "WIP: " if is_draft else ""
        return f"[{index}/{total}] {wip}{title}"

    def set_title(self, index: int, total: int, title: str) -> bool:
        new_title = self.get_title(index, total, title, self.is_draft)
        if new_title != self.raw_title:
            gh("pr", "edit", str(self.number), "-t", new_title, capture_output=False)
            self.title = title
            self.raw_title = new_title
            return True
        else:
            return False

    def set_draft(self, is_draft: bool) -> bool:
        if is_draft == self.is_draft:
            return False
        args = ["pr", "ready", str(self.number)]
        if is_draft:
            args.append("--undo")
        gh(*args, capture_output=False)
        self.is_draft = is_draft
        return True

    def set_table(self, stack_prs: List["PullRequest"]) -> bool:
        rows = []
        for i, pr in enumerate(stack_prs):
            title = pr.title
            if pr.is_draft:
                title = "WIP: " + title
            row = {"PR": f"#{pr.number}", "Title": title, "": str(i + 1)}
            if pr.number == self.number:
                row["PR"] = f">{pr.number}"
            rows.append(row)
        table = make_markdown_table(rows, ["", "PR", "Title"])
        if table != self.table:
            new_body = table + "\n" + self.body
            gh("pr", "edit", str(self.number), "-b", new_body, capture_output=False)
            self.raw_body = new_body
            self.table = table
            return True
        else:
            return False


class Child:
    stack_name: str
    index: int
    is_merged: bool
    local_exists: bool
    pull_request: Optional[PullRequest] = None

    def __init__(
        self, stack_name: str, index: int, *, is_merged: bool, local_exists: bool
    ):
        self.stack_name = stack_name
        self.index = index
        self.is_merged = is_merged
        self.local_exists = local_exists

    @property
    def branch(self):
        return self.stack_name + "-" + str(self.index)

    def __hash__(self) -> int:
        return hash(self.branch)

    def __eq__(self, other) -> bool:
        if not isinstance(other, Child):
            return False
        return self.branch == other.branch


def parse_markdown_table(body: str) -> Tuple[str, str]:
    table = []
    rest = []
    lines = body.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("|"):
            table.append(line)
        else:
            rest = lines[i:]
            break
    return "\n".join(table), "\n".join(rest)


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


@overload
def get_stack(name: str, required: Literal[True]) -> Stack:
    ...


@overload
def get_stack(name: str, required: bool = False) -> Optional[Stack]:
    ...


def get_stack(name: str, required: bool = False) -> Optional[Stack]:
    if name == "." or name == "@":
        name = current_stack()
    for stack in list_stacks():
        if stack.name == name:
            return stack
    if required:
        sys.stderr.write(f"Could not find stack '{name}'\n")
        sys.exit(1)
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
    stacks: Dict[str, Stack] = {}
    merged = list_merged_branches()
    for branch in list_branches():
        is_merged = branch in merged
        match = STACK_RE.match(branch)
        if match:
            name, num = match[1], int(match[2])
            if name not in stacks:
                stacks[name] = Stack(name)
            stacks[name].add_child(
                Child(name, num, is_merged=is_merged, local_exists=True)
            )
        elif branch not in stacks:
            stacks[branch] = Stack(branch)

    ret = list(stacks.values())
    for stack in ret:
        stack.finalize()
    return ret


def refs_between(ref1: str, ref2: str) -> List[str]:
    """Exclusive on ref1, inclusive on ref2"""
    return list(reversed(git_lines("log", ref1 + "..." + ref2, "--format=%H")))


def get_tag(ref: str) -> Optional[str]:
    lines = git_lines("log", "-n", "1", "--format=%B", ref)
    for line in lines:
        if line.startswith("branch: "):
            return line[8:].strip()


def find_branch_parent(target: str, branch: str) -> str:
    branch_mb = merge_base(target, branch)

    commits = refs_between(branch_mb, branch)
    prev = branch_mb
    for commit in commits:
        if get_tag(commit) == branch:
            return prev
        prev = commit

    raise ValueError(f"Could not find branch start for {branch}")


def rev_parse(ref: str) -> str:
    return git("rev-parse", "--verify", ref)


def tag_commits(tag: str, refs: str):
    filter = (
        r"""awk '/^branch:/ {found=1} END {if(!found) print "\nbranch: """
        + tag
        + """"} 1'"""
    )
    proc = subprocess.run(
        [
            "git",
            "filter-branch",
            "-f",
            "--msg-filter",
            filter,
            refs,
        ],
        env={"FILTER_BRANCH_SQUELCH_WARNING": "1"},
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        stderr = proc.stderr.decode("utf-8").strip()
        if stderr != "Found nothing to rewrite":
            raise subprocess.CalledProcessError(
                proc.returncode, proc.args, proc.stdout, proc.stderr
            )


def merge_base(branch: str, ref2: str = ORIGIN_MASTER) -> str:
    return git("merge-base", branch, ref2)


def child_branches(ref: str) -> List[str]:
    return [
        b
        for b in git_lines("branch", "--contains", ref, "--format=%(refname:short)")
        if b != ref
    ]


def make_stack(branch: Optional[str] = None):
    exit_if_dirty()
    cur = current_branch()
    if branch is None or branch == "." or branch == "@":
        branch = current_stack()
    stack = get_stack(branch)
    if stack is None:
        raise ValueError(f"Could not create stack for branch {branch}")
    # Make sure we're on a tidy stack first
    stack.rebase()
    base = stack.get_next_base()
    for commit in refs_between(base, stack.name):
        child = stack.create_next_child()
        git("checkout", "-b", child.branch, commit)
        child.local_exists = True
        tag_commits(child.branch, f"{child.branch}^..{child.branch}")
        stack.add_child(child)

    # The tip should be the same as the last child branch
    switch_branch(stack.name)
    git("reset", "--hard", stack.unmerged_children()[-1].branch)
    stack.rebase()
    switch_branch(cur)


def switch_branch(branch: str):
    git("checkout", branch)


def create_branch(branch: str, start: str = MASTER):
    git("checkout", "-b", branch, start)


def touch_file(filename: str, contents: str = ""):
    with open(filename, "w", encoding="utf-8") as ofile:
        ofile.write(contents)


def exit_if_no_gh():
    if not has_gh():
        sys.stderr.write("gh cli missing or not authenticated\n")
        sys.exit(1)


def exit_if_dirty():
    output = git("status", "--porcelain")
    if output:
        sys.stderr.write("Working directory is dirty\n")
        sys.exit(1)


def _add_cmd_stack(parser: argparse.ArgumentParser):
    subparsers = parser.add_subparsers(dest="stack_cmd")

    list_parser = subparsers.add_parser(
        "list", help="List all branches, filtering out stack children"
    )
    list_parser.add_argument(
        "-c",
        "--children",
        action="store_true",
        help="Print the number of children each stack has",
    )
    subparsers.add_parser(
        "create",
        help="Create a new stack on the current branch",
        description="Each commit on the current branch will be turned into a new branch.",
    )
    restack_parser = subparsers.add_parser(
        "restack",
        aliases=["tidy"],
        help="Restack all child branches",
        description="Rebases child branches to form a linear history",
    )
    restack_parser.add_argument(
        "name", nargs="?", default=".", help="Name of the branch to restack"
    )
    clean_parser = subparsers.add_parser(
        "clean", help="Delete the merged branches of a stack"
    )
    clean_parser.add_argument(
        "name", nargs="?", default=".", help="Name of the stack to clean"
    )
    push_parser = subparsers.add_parser("push", help="push branches of a stack")
    push_parser.add_argument(
        "-a", action="store_true", help="Push all branches, not just the earlier ones"
    )
    push_parser.add_argument(
        "-f", action="store_true", help="push with force-with-lease"
    )
    pr_parser = subparsers.add_parser("pr", help="Create or update PRs for a stack")
    pr_parser.add_argument(
        "-a",
        action="store_true",
        help="Create PRs for all branches, not just the earlier ones",
    )
    pr_parser.add_argument("name", nargs="?", default=".", help="Name of the stack")
    publish_parser = subparsers.add_parser(
        "publish", help="Publish stack PRs from draft mode"
    )
    publish_parser.add_argument(
        "-a",
        action="store_true",
        help="Publish PRs for all branches, not just the earlier ones",
    )
    publish_parser.add_argument(
        "-u",
        "--undo",
        action="store_true",
        help="Convert PR back to draft mode (current branch only)",
    )
    publish_parser.add_argument(
        "name", nargs="?", default=".", help="Name of the stack"
    )
    prev_parser = subparsers.add_parser(
        "prev", help="Check out previous branch in stack"
    )
    prev_parser.add_argument(
        "count",
        nargs="?",
        type=int,
        default=1,
        help="Jump backwards this many branches",
    )
    next_parser = subparsers.add_parser("next", help="Check out next branch in stack")
    next_parser.add_argument(
        "count", nargs="?", type=int, default=1, help="Jump forwards this many branches"
    )
    next_parser = subparsers.add_parser(
        "tip", help="Check out the tip branch in the stack"
    )
    next_parser = subparsers.add_parser(
        "first", help="Check out the first branch in the stack"
    )
    del_parser = subparsers.add_parser(
        "delete",
        help="Delete the branches of a stack",
        description="Note that this will not delete the tip branch of the stack",
    )
    del_parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Force delete the branches",
    )
    del_parser.add_argument(
        "name",
        nargs="?",
        default=".",
        help="Name of the stack to delete",
    )
    rebase_parser = subparsers.add_parser(
        "rebase", help="rebase a stack on top of a rev"
    )
    rebase_parser.add_argument("target", help="Target revision to rebase onto")
    subparsers.add_parser(
        "reset_remote",
        help="Reset stack branches to origin refs",
        description="This is useful if you've edited and pushed a stack from another machine",
    )
    status_parser = subparsers.add_parser("status", help="Display status of the stack")
    status_parser.add_argument(
        "name", nargs="?", default=".", help="Name of the stack to show the status of"
    )


def navigate_stack_relative(count: int):
    stack = get_stack(current_stack())
    if stack is None:
        sys.stderr.write("Not on a stack branch\n")
        sys.exit(1)
    cur = current_branch()
    branches = stack.unmerged_branches()
    idx = branches.index(cur)
    new_idx = max(0, min(len(branches) - 1, idx + count))
    switch_branch(branches[new_idx])
    print(stack.get_stack_graph())


def cmd_stack(args, parser):
    if "stack_cmd" not in args or args.stack_cmd == "list":
        for stack in list_stacks():
            if args.children:
                line = stack.name
                num_children = len(stack.all_children())
                line = f"{num_children}".ljust(3) + line
                print(line)
            else:
                print(stack.name)
    elif args.stack_cmd == "create":
        make_stack()
    elif args.stack_cmd == "restack":
        exit_if_dirty()
        stack = get_stack(args.name, required=True)
        stack.rebase()
    elif args.stack_cmd == "clean":
        stack = get_stack(args.name, required=True)
        for child in stack.all_children():
            if child.is_merged and child.local_exists:
                print("delete", child.branch)
                delete_branch(child.branch)
    elif args.stack_cmd == "push":
        stack = get_stack(".", required=True)
        cur = current_branch()
        before_branch = None if args.a else cur
        for branch in stack.unmerged_branches(before_branch):
            switch_branch(branch)
            git_args = ["push", "-u", "origin", branch]
            if args.f:
                git_args.insert(1, "--force-with-lease")
            git(*git_args, capture_output=False)
        switch_branch(cur)
    elif args.stack_cmd == "pr":
        exit_if_no_gh()
        stack = get_stack(args.name, required=True)
        stack.load_prs()
        before_branch = None if args.a else current_branch()
        created = stack.create_prs(before_branch)
        updated = stack.update_prs()
        for child in stack._children:
            pr = child.pull_request
            if pr is not None:
                if child in created:
                    print("Created  ", pr.url)
                elif child in updated:
                    print("Updated  ", pr.url)
                else:
                    print("Unchanged", pr.url)
    elif args.stack_cmd == "publish":
        exit_if_no_gh()
        stack = get_stack(args.name, required=True)
        stack.load_prs()
        unpublished = set()
        published = set()
        updated = set()
        if args.undo:
            cur = current_branch()
            child = next(
                (child for child in stack.unmerged_children() if child.branch == cur)
            )
            pr = child.pull_request
            assert pr
            if pr.set_draft(True):
                unpublished.add(child)
            updated = stack.update_prs()
        else:
            before_branch = None if args.a else current_branch()
            for child in stack.unmerged_children(before_branch):
                pr = child.pull_request
                if pr:
                    if pr.set_draft(False):
                        published.add(child)
            updated = stack.update_prs()
        for child in stack.all_children():
            pr = child.pull_request
            if pr:
                if child in published:
                    print("Published  ", pr.url)
                elif child in unpublished:
                    print("Unpublished", pr.url)
                elif child in updated:
                    print("Updated    ", pr.url)
                else:
                    print("Unchanged  ", pr.url)
    elif args.stack_cmd == "rebase":
        exit_if_dirty()
        stack = get_stack(".", required=True)
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
        stack = get_stack(current_stack(), required=True)
        unmerged = [
            child.branch for child in stack.unmerged_children() if child.local_exists
        ] + [stack.name]
        for branch in unmerged:
            switch_branch(branch)
            git("reset", "--hard", "origin/" + branch, check=False)
        switch_branch(cur)
    elif args.stack_cmd == "delete":
        stack = get_stack(args.name, required=True)
        for child in stack.all_children():
            if child.local_exists:
                delete_branch(child.branch, args.force)
    elif args.stack_cmd == "status":
        stack = get_stack(args.name, required=True)
        stack.load_prs()
        header = [stack.name]
        if stack.needs_restack():
            header.append("(needs restack)")
        if stack.is_incomplete():
            header.append("(has unstacked commits)")
        print(" ".join(header))
        for child in reversed(stack.all_children()):
            line = [child.branch]
            # TODO display origin status
            if child.pull_request:
                line.append(f"#{child.pull_request.number}")
            if child.is_merged:
                line.append(f"(merged)")
            print(" ".join(line))
    else:
        parser.print_help()


def _add_cmd_update(parser):
    parser.add_argument(
        "-l",
        "--local",
        action="store_true",
        help="Rebase local branches, do not do a fetch",
    )


def cmd_update(args):
    exit_if_dirty()
    cur = current_branch()
    if not args.local:
        git("fetch", capture_output=False)
    for branch in list_branches():
        # FIXME This is to catch master-passing-tests. There's probably a better way to do this.
        if branch.startswith(MASTER):
            git("rebase", "origin/" + branch, branch)
    switch_branch(cur)


def _add_cmd_test(parser):
    parser.add_argument(
        "test_cmd",
        default="tidy_stack",
        choices=[
            "create",
            "tidy_stack",
            "tidy_rebase",
            "reset",
            "old_stack",
            "incomplete_stack",
        ],
    )


def cmd_test(args):
    test_branch_name = f"{USER}-TEST"
    if args.test_cmd == "reset":
        switch_branch(MASTER)
        for branch in list_branches():
            if branch.startswith(test_branch_name):
                delete_branch(branch, True)
    elif args.test_cmd == "create":
        create_branch(test_branch_name)
        git("commit", "--allow-empty", "-m", "Test commit 1")
        git("commit", "--allow-empty", "-m", "Test commit 2")
        git("commit", "--allow-empty", "-m", "Test commit 3")
        make_stack()
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
