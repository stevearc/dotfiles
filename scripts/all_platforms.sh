#!/bin/bash
set -e

fetch-nerd-font() {
  if [ ! -e UbuntuMono.zip ]; then
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/UbuntuMono.zip
    unzip UbuntuMono.zip
  fi
  rm -f UbuntuMono.zip
}

post-install-neovim() {
  [ -d ~/.envs ] || mkdir ~/.envs
  [ -d ~/.envs/py3 ] || python3 -m venv ~/.envs/py3
  ~/.envs/py3/bin/pip install -q wheel
  ~/.envs/py3/bin/pip install -q pynvim || ~/.envs/py3/bin/pip install -i https://pypi.org/simple -q pynvim

  # nvim --headless +UpdateRemotePlugins +qall >/dev/null
}

configure-git() {
  git config --global user.email >/dev/null || git config --global user.email stevearc@stevearc.com
  git config --global color.ui auto
  git config --global user.name 'Steven Arcangeli'
  git config --global merge.tool vimdiff
  git config --global diff.algorithm patience
  git config --global fetch.prune true
  git config --global diff.colorMoved zebra
  git config --global push.autoSetupRemote true
  # This was causing massive lag
  # git config --global core.fsmonitor true

  git config --global alias.st 'status'
  git config --global alias.ci 'commit'
  git config --global alias.co 'checkout'
  git config --global alias.cob 'checkout -b'
  git config --global alias.com '!git checkout $(git main)'
  git config --global alias.cp 'cherry-pick'
  git config --global alias.des 'describe --tags'
  git config --global alias.di 'diff --ignore-all-space'
  git config --global alias.dc 'diff --cached --ignore-all-space'
  git config --global alias.dm '!git diff --ignore-all-space $(git merge-base HEAD origin/$(git main)) HEAD'
  git config --global alias.dms '!git diff --name-status $(git merge-base HEAD origin/$(git main)) HEAD'
  git config --global alias.ab 'rebase --abort'
  git config --global alias.abort 'rebase --abort'
  git config --global alias.rco 'rebase --continue'
  git config --global alias.mb 'merge-base'
  git config --global alias.ri '!git rebase -i $(git merge-base HEAD origin/$(git main))'
  git config --global alias.amend 'commit --amend'
  git config --global alias.am 'commit --amend --no-edit'
  git config --global alias.ama 'commit --amend -a --no-edit'
  git config --global alias.amn 'commit --amend --no-edit'
  git config --global alias.aa 'add --all'
  git config --global alias.head '!git l -1'
  git config --global alias.h '!git head'
  git config --global alias.hist 'log --'
  git config --global alias.ff 'merge --ff-only'
  git config --global alias.pullff 'pull --ff-only'
  git config --global alias.pr 'pull --rebase'
  git config --global alias.noff 'merge --no-ff'
  git config --global alias.div 'divergence'
  git config --global alias.f 'fetch'
  git config --global alias.fa 'fetch --all'
  git config --global alias.b 'branch'
  git config --global alias.ba 'branch -a'
  git config --global alias.ds 'diff --stat=160,120'
  git config --global alias.dh1 'diff HEAD~1'
  git config --global alias.sh 'show -w'
  git config --global alias.s 'submodule'
  git config --global alias.su 'submodule update --init --recursive'
  git config --global alias.sclean '!git submodule update --init --recursive && git submodule foreach --recursive "git reset --hard" && git submodule foreach --recursive "git clean -fd"'
  git config --global alias.rp 'rev-parse --verify'
  git config --global alias.delm '!bash ~/.githelpers delete_merged'
  git config --global alias.pod 'push origin --delete'
  git config --global alias.rom '!git rebase "origin/$(git main)"'
  git config --global alias.rum '!git rebase "upstream/$(git main)"'
  git config --global alias.main '!(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo "///master") | cut -f 4 -d / | tr -d "[:space:]"'
  git config --global alias.ss 'show --stat'
  git config --global alias.res '!nvim $(git status --porcelain | grep "^UU " | cut -d " " -f 2)'
  git config --global alias.wip 'commit --no-verify -m WIP'
  git config --global alias.undo 'reset HEAD^'
  git config --global alias.po '!bash ~/.githelpers push_current_branch'
  git config --global alias.pof '!bash ~/.githelpers push_current_branch --force-with-lease'
  git config --global alias.dopr '!bash ~/.githelpers create_pull_request'
  git config --global alias.popr '!git po && sleep 1 && git dopr'
  git config --global alias.findpr '!bash ~/.githelpers find_pull_request'
  git config --global alias.fix '!bash ~/.githelpers commit_fix'
  git config --global alias.uu '!bash ~/.githelpers update_master'
  git config --global alias.l '!bash ~/.githelpers pretty_git_log_paged'
  git config --global alias.la '!git l --all'
  git config --global alias.ra '!git la -30'
  git config --global alias.rs '!git la -30 --simplify-by-decoration --first-parent'
  git config --global alias.r '!git rcp -30'
  git config --global alias.rc '!bash ~/.githelpers contextual_git_log'
  git config --global alias.rcp '!bash ~/.githelpers contextual_git_log_paged'
  git config --global alias.patch 'format-patch --stdout'
  git config --global alias.root 'rev-parse --show-toplevel'
  git config --global alias.sm '!bash ~/.githelpers show_modified_files'
  git config --global alias.prev 'checkout @^'
  git config --global alias.next '!git checkout $(git rev-list --children --all | grep ^$(git rev-parse HEAD) | cut -f 2 -d " ")'
  git config --global alias.hookdir 'rev-parse --git-path hooks'
  git config --global alias.installhooks '!bash ~/.githelpers install-hooks'
  git config --global alias.stack '!python ~/.local/share/gitstack.py'
  git config --global alias.sk '!python ~/.local/share/gitstack.py'
  git config --global alias.ls '!python ~/.local/share/gitstack.py list'
  git config --global alias.srom '!python ~/.local/share/gitstack.py rebase origin/$(git main)'
  git config --global alias.skd '!python ~/.local/share/gitstack.py --log-level debug'
  git config --global alias.skt '!python ~/dotfiles/gitstack/test_scenarios.py'
  git config --global alias.up '!bash ~/.githelpers update'
  git config --global alias.mine '!git log --author=$(git config --get user.email) --pretty=medium --compact-summary'
  git config --global alias.touch 'commit --amend --reset-author --no-edit'

  git config --global color.decorate.HEAD 'bold red'
  git config --global color.decorate.branch green
  git config --global color.decorate.remoteBranch cyan
  git config --global color.decorate.tag 'bold yellow'
  git config --global color.decorate.stash green
  git config --global core.excludesFile '~/.config/global-git-ignore'
  mkdir -p ~/.config
  touch ~/.config/global-git-ignore
  grep tags ~/.config/global-git-ignore >/dev/null 2>&1 || echo tags >>~/.config/global-git-ignore
  grep .DS_Store ~/.config/global-git-ignore >/dev/null 2>&1 || echo .DS_Store >>~/.config/global-git-ignore
  grep .nvim.lua ~/.config/global-git-ignore >/dev/null 2>&1 || echo .nvim.lua >>~/.config/global-git-ignore
  grep __pycache__ ~/.config/global-git-ignore >/dev/null 2>&1 || echo __pycache__ >>~/.config/global-git-ignore

  if hascmd fzf; then
    git config --global alias.fb '!git sk list | fzf | xargs git checkout'
  fi
}
