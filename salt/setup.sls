#!stateconf
{% set dotfiles = ('.bashrc', '.gitconfig', '.githelpers', '.pylintrc', '.tmux.conf', '.vimrc') %}
{% set dotdirs = {
  '.vim': {},
  '.gconf': {'file_mode': '0600', 'dir_mode': '0700'},
} %}
{% set scripts = ('run-command-on-git-revisions',) %}
{% set boxed_repos = ('stevearc/pyramid_duh', 'mathcamp/devbox', 'mathcamp/dql', 'mathcamp/flywheel', 'mathcamp/pypicloud') %}
{% set repos = ('mathcamp/aws-formula', 'stevearc/ozzy') %}

# Ubuntu repos
.core-pkgs:
  pkg.installed:
    - pkgs:
      - wget
      - python-software-properties

.chrome-ppa:
  cmd.run:
    - name: wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
    - unless: test -f /etc/apt/sources.list.d/google-chrome.list
  file.append:
    - name: /etc/apt/sources.list.d/google-chrome.list
    - text: deb http://dl.google.com/linux/chrome/deb/ stable main
    - makedirs: True
    - require:
      - cmd: .chrome-ppa

.talkplugin-ppa:
  file.append:
    - name: /etc/apt/sources.list.d/google-talkplugin.list
    - text: deb http://dl.google.com/linux/talkplugin/deb/ stable main

.musicmanager-ppa:
  file.append:
    - name: /etc/apt/sources.list.d/google-musicmanager.list
    - text: deb http://dl.google.com/linux/musicmanager/deb/ stable main

.dropbox-ppa:
  cmd.run:
    - name: apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
    - unless: test -f /etc/apt/sources.list.d/dropbox.list
  file.append:
    - name: /etc/apt/sources.list.d/dropbox.list
    - text: deb http://linux.dropbox.com/ubuntu/ raring main
    - makedirs: True
    - require:
      - cmd: .dropbox-ppa

.docker-ppa:
  cmd.run:
    - name: apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    - unless: test -f /etc/apt/sources.list.d/docker.list
  file.append:
    - name: /etc/apt/sources.list.d/docker.list
    - text: deb http://get.docker.io/ubuntu docker main
    - makedirs: True
    - require:
      - cmd: .docker-ppa

.pithos-ppa:
  cmd.run:
    - name: add-apt-repository -y ppa:kevin-mehall/pithos-daily
    - unless: test -f /etc/apt/sources.list.d/kevin-mehall-pithos-daily-precise.list

.apt-update:
  cmd.wait:
    - name: apt-get update
    - watch:
      - file: .chrome-ppa
      - file: .dropbox-ppa
      - cmd: .pithos-ppa

# Install packages
.pkgs:
  pkg.installed:
    - pkgs:
      # Dev tools
      - ack-grep
      - curl
      - ffmpeg
      - git-all
      - htop
      - ipython
      - openjdk-7-jdk
      - openssh-client
      - openssh-server
      - python-dev
      - python-pip
      - ruby
      - rubygems
      - tmux
      - unzip
      - vim-gnome
      - xsel
      # Desktop
      - gnome
      - gnome-do
      - gthumb
      # For numpy & scipy
      - g++
      - gfortran
      - libatlas-base-dev
      # Misc
      - desktopnova
      - flashplugin-installer
      - google-chrome-stable
      - google-talkplugin
      - google-musicmanager-beta
      - gparted
      - mplayer
      - pithos
      - vlc
      - lxc-docker
  pip.installed:
    - names:
      - virtualenv
      - autoenv
    - require:
      - pkg: .pkgs
  gem.installed:
    - name: mkrf

.purge-pkgs:
  pkg.purged:
    - pkgs:
      - overlay-scrollbar
      - liboverlay-scrollbar-0.2-0
      - liboverlay-scrollbar3-0.2-0

# Install dotfiles
{% for filename in dotfiles %}
.dotfile-{{ filename }}:
  file.managed:
    - name: {{ grains.home }}/{{ filename }}
    - source: salt://dotfiles/{{ filename }}
    - mode: '0644'
    - user: {{ grains.user }}
    - group: {{ grains.user }}
{% endfor %}
{% for filename, data in dotdirs.iteritems() %}
.dotfile-{{ filename }}:
  file.recurse:
    - name: {{ grains.home }}/{{ filename }}
    - source: salt://dotfiles/{{ filename }}
    - clean: {{ data.get('clean', False) }}
    - file_mode: {{ data.get('file_mode', '0644') }}
    - dir_mode: {{ data.get('dir_mode', '0755') }}
    - user: {{ grains.user }}
    - group: {{ grains.user }}
    - exclude_pat: "*.git"
{% endfor %}
{% for filename in scripts %}
.script-{{ filename }}:
  file.managed:
    - name: /usr/bin/{{ filename }}
    - source: salt://scripts/{{ filename }}
    - mode: '0755'
{% endfor %}

# Compile command-t
.compile-command-t:
  cmd.wait:
    - name: ruby extconf.rb && make
    - cwd: {{ grains.home }}/.vim/bundle/command-t/ruby/command-t
    - watch:
      - file: .dotfile-.vim

# Clone git repos into workspace
.workspace:
  file.directory:
    - name: {{ grains.home }}/ws
    - user: {{ grains.user }}
    - group: {{ grains.user }}
    - recurse:
      - user
      - group

.unbox-download:
  cmd.run:
    - name: 'wget https://raw.github.com/mathcamp/devbox/master/devbox/unbox.py'
    - unless: test -e unbox.py
    - cwd: {{ grains.home }}/ws
    - user: {{ grains.user }}

{% for repo in boxed_repos %}
.unbox-{{ repo }}:
  cmd.run:
    - name: python unbox.py git@github.com:{{ repo }}
    - unless: test -e {{ repo.split('/')[-1] }}
    - cwd: {{ grains.home }}/ws
    - user: {{ grains.user }}
{% endfor %}

{% for repo in repos %}
.clone-{{ repo }}:
  cmd.run:
    - name: git clone git@github.com:{{ repo }}
    - unless: test -e {{ repo.split('/')[-1] }}
    - cwd: {{ grains.home }}/ws
    - user: {{ grains.user }}
{% endfor %}
