#!/usr/bin/env python
import sys
import hashlib
import re
import os
import argparse
import subprocess
from typing import List, Optional

def git(*args, **kwargs) -> str:
    kwargs.setdefault('check', True)
    kwargs.setdefault('capture_output', True)
    try:
        stdout = subprocess.run(('git',) + args, **kwargs).stdout
    except subprocess.CalledProcessError as e:
        print("Error running: git", ' '.join(args))
        print(e.stdout.decode('utf-8'))
        print(e.stderr.decode('utf-8'))
        raise
    if stdout is None:
        return ''
    else:
        return stdout.decode('utf-8').strip()

def git_lines(*args, **kwargs) -> List[str]:
    ret = git(*args, **kwargs)
    if ret:
        return ret.split('\n')
    else:
        return []

def remote_main_branch() -> str:
    proc = subprocess.run(['git', 'symbolic-ref', 'refs/remotes/origin/HEAD'], capture_output=True)
    if proc.returncode == 0:
        return proc.output.decode('utf-8').split('/')[-1]
    return 'master'

MASTER = remote_main_branch()
ORIGIN_MASTER = 'origin/' + MASTER
USER = os.environ['USER']

class Stack:
    def __init__(self, name: str, children: List[str]):
        self.name = name
        self.children = children

    def add_child(self, branch: str):
        self.children.append(branch)
        self.children.sort(key=lambda x: int(STACK_RE.match(x)[2]))

    def rebase(self, target: str):
        rebase_branches(target, self.children + [self.name])

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
        i = 0
        while i < len(self.children):
            top = self.children[i]
            children = child_branches(top)
            if len(children) != len(self.children) - i:
                rebase_branches(top, self.children[i+1:] + [self.name])
            i += 1

    def __str__(self) -> str:
        return self.name + ': ' + ', '.join(self.children)

STACK_RE = re.compile(r'^(.*)\-(\d+)$')

def list_branches() -> List[str]:
    return [b.strip() for b in git_lines('branch', '--format=%(refname:short)')]

def list_merged_branches(branch: str = ORIGIN_MASTER) -> List[str]:
    return [b.strip() for b in git_lines('branch', '--format=%(refname:short)', '--merged', branch)]

def current_branch() -> str:
    return git('branch', '--show-current')

def delete_branch(branch: str, force: bool = False):
    flag = '-D' if force else '-d'
    return git('branch', flag, branch)

def current_stack() -> str:
    b = current_branch()
    match = STACK_RE.match(b)
    if match:
        return match[1]
    else:
        return b

def get_stack(name: str) -> Optional[Stack]:
    if name == '.' or name == '@':
        name = current_stack()
    for stack in list_stacks():
        if stack.name == name:
            return stack
    return None

def get_repo_url() -> str:
    url = git('remote', 'get-url', 'origin')
    if url.startswith('http'):
        if url.endswith('.git'):
            url = url[:-4]
    else:
        url = re.sub(r'^.*@', '', url)
        url = 'https://' + url.replace(':', '/')
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
    return list(reversed(git_lines('log', ref1 + "..." + ref2, '--format=%H')))

_fingerprints = {}
def fingerprint_commit(ref: str) -> str:
    if ref not in _fingerprints:
        summary = git('log', '--name-only', '--format=%an %ae %B', '-n', '1', ref)
        _fingerprints[ref] = hashlib.md5(summary.encode('utf-8')).hexdigest()
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
    return git('rev-parse', '--verify', ref)

def rebase_branches(target: str, branches: List[str]):
    branch_start = None
    for branch in branches:
        next_branch_start = rev_parse(branch)
        if branch_start is None:
            branch_start = find_branch_start(target, branch)
        git('rebase', '--onto', target, branch_start, branch)
        target = branch
        branch_start = next_branch_start

def merge_base(branch: str, ref2: str = ORIGIN_MASTER) -> str:
    return git('merge-base', branch, 'origin/' + MASTER)

def child_branches(ref: str) -> List[str]:
    return [b for b in git_lines('branch', '--contains', ref, '--format=%(refname:short)') if b != ref]

def make_stack(branch: str=None):
    cur = current_branch()
    if branch is None or branch == '.' or branch == '@':
        branch = current_stack()
    stack = get_stack(branch)
    if stack is None:
        raise ValueError(f"Could not create stack for branch {branch}")
    # Make sure we're on a tidy stack first
    stack.tidy()
    base = stack.get_next_base()
    for commit in refs_between(base, stack.name):
        child = stack.next_child()
        git('checkout', '-b', child, commit)
        stack.add_child(child)
    switch_branch(cur)

def switch_branch(branch: str):
    git('checkout', branch)

def create_branch(branch: str, start: str = MASTER):
    git('checkout', '-b', branch, start)

def touch_file(filename: str, contents: str = ""):
    with open(filename, 'w', encoding='utf-8') as ofile:
        ofile.write(contents)

def _add_cmd_stack(parser):
    subparsers = parser.add_subparsers(dest='stack_cmd')

    list_parser = subparsers.add_parser('list')
    list_parser.add_argument('-c', '--children', action='store_true', help='Show children of stack')
    subparsers.add_parser('create')
    tidy_parser = subparsers.add_parser('tidy')
    tidy_parser.add_argument('branch', nargs='?')
    subparsers.add_parser('clean')
    push_parser = subparsers.add_parser('push')
    push_parser.add_argument('branch', nargs='?')
    pr_parser = subparsers.add_parser('pr')
    pr_parser.add_argument('branch', nargs='?')
    subparsers.add_parser('prev')
    subparsers.add_parser('next')


def cmd_stack(args, parser):
    if 'stack_cmd' not in args or args.stack_cmd == 'list':
        for stack in list_stacks():
            if args.children:
                print(stack)
            else:
                print(stack.name)
    elif args.stack_cmd == 'create':
        make_stack()
    elif args.stack_cmd == 'tidy':
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
    elif args.stack_cmd == 'clean':
        print("TODO delete merged branches")
    elif args.stack_cmd == 'push':
        if args.branch is None:
            args.branch = current_stack()
        stack = get_stack(args.branch)
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        cur = current_branch()
        for branch in stack.children:
            switch_branch(branch)
            git('push', '--force-with-lease', '-u', 'origin', branch)
        switch_branch(cur)
    elif args.stack_cmd == 'pr':
        url = get_repo_url()
        if args.branch is None:
            args.branch = current_stack()
        stack = get_stack(args.branch)
        if stack is None:
            print("Could not find stack", args.branch)
            sys.exit(1)
        rel = MASTER
        for branch in stack.children:
            print(f"{url}/compare/{rel}...{branch}?expand=1")
            rel = branch
        print("TODO use gh to update title/description")
    elif args.stack_cmd == 'prev':
        print("TODO")
    elif args.stack_cmd == 'next':
        print("TODO")
    else:
        parser.print_help()

def _add_cmd_update(parser):
    parser.add_argument('-l', '--local', action='store_true', help='Rebase local branches, do not do a fetch')
    parser.add_argument('-r', '--rebase', action='store_true', help='Rebase all local branches after updating')
    parser.add_argument('target', nargs='?', help='Target branch to rebase atop (default %(default)s)', default=MASTER)

def cmd_update(args):
    if not args.local:
        git('fetch', capture_output=False)
        cur = current_branch()
        for branch in list_branches():
            # FIXME This is to catch master-passing-tests. There's probably a better way to do this.
            if branch.startswith(MASTER):
                if cur != branch:
                    git('branch', '-f', branch, 'origin/' + branch)
                else:
                    git('reset', '--hard', 'origin/' + branch)
    if args.rebase or args.local:
        stack = get_stack('stevearc-TEST')
        for stack in list_stacks():
            print("Rebasing", stack.name)
            stack.rebase(args.target)

def _add_cmd_test(parser):
    parser.add_argument('test_cmd', default='tidy_stack', choices=['tidy_stack', 'tidy_rebase', 'clean', 'old_stack', 'incomplete_stack'])

def cmd_test(args):
    test_branch_name = f"{USER}-TEST"
    if args.test_cmd == 'clean':
        switch_branch(MASTER)
        for branch in list_branches():
            if branch.startswith(test_branch_name):
                delete_branch(branch, True)
    elif args.test_cmd == 'tidy_stack':
        create_branch(test_branch_name)
        git('commit', '--allow-empty', '-m', 'Test commit 1')
        git('commit', '--allow-empty', '-m', 'Test commit 2')
        git('commit', '--allow-empty', '-m', 'Test commit 3')
        make_stack()
        switch_branch(test_branch_name + "-2")
        git('commit', '--allow-empty', '-m', 'Fix up a PR')
        switch_branch(test_branch_name)
    elif args.test_cmd == 'tidy_rebase':
        create_branch(test_branch_name, MASTER + '^')
        git('commit', '--allow-empty', '-m', 'Test commit 1')
        git('commit', '--allow-empty', '-m', 'Test commit 2')
        git('commit', '--allow-empty', '-m', 'Test commit 3')
        make_stack()
        switch_branch(test_branch_name + "-1")
        git('rebase', MASTER)
        switch_branch(test_branch_name)
    elif args.test_cmd == 'old_stack':
        create_branch(test_branch_name, MASTER + '^')
        git('commit', '--allow-empty', '-m', 'Test commit 1')
        git('commit', '--allow-empty', '-m', 'Test commit 2')
        git('commit', '--allow-empty', '-m', 'Test commit 3')
        make_stack()
    elif args.test_cmd == 'incomplete_stack':
        create_branch(test_branch_name, MASTER + '^')
        git('commit', '--allow-empty', '-m', 'Test commit 1')
        git('commit', '--allow-empty', '-m', 'Test commit 2')
        make_stack()
        git('commit', '--allow-empty', '-m', 'Test commit 3')
        git('commit', '--allow-empty', '-m', 'Test commit 4')
    else:
        print(f"Unknown test command {args.test_cmd}")

def main() -> None:
    """Main method"""
    parser = argparse.ArgumentParser(description=main.__doc__)

    subparsers = parser.add_subparsers(dest='cmd')

    stack_parser = subparsers.add_parser('stack')
    _add_cmd_stack(stack_parser)
    _add_cmd_test(subparsers.add_parser('test'))
    _add_cmd_update(subparsers.add_parser('update'))

    args = parser.parse_args()

    if args.cmd == 'stack':
        cmd_stack(args, stack_parser)
    elif args.cmd == 'update':
        cmd_update(args)
    elif args.cmd == 'test':
        cmd_test(args)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
