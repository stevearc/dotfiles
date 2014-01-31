#!stateconf

# Repos
.core-pkgs:
  pkg.installed:
    - pkgs:
      - wget
      - python-software-properties

.chrome-ppa:
  cmd.run:
    - name: wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
    - unless: test -f /etc/apt/sources.list.d/google.list
  file.append:
    - name: /etc/apt/sources.list.d/google.list
    - text: deb http://dl.google.com/linux/chrome/deb/ stable main
    - makedirs: True
    - require:
      - cmd: .chrome-ppa

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
      - gparted
      - mplayer
      - pithos
      - vlc
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
{% for filename in ('.bashrc', '.gitconfig', '.githelpers', '.pylintrc', '.tmux.conf', '.vimrc') %}
.dotfile-{{ filename }}:
  file.managed:
    - name: {{ grains.home }}/{{ filename }}
    - source: salt://dotfiles/{{ filename }}
    - mode: '0644'
    - user: {{ grains.user }}
    - group: {{ grains.user }}
{% endfor %}
{%- set dirs = {'.vim': {},
                '.gconf': {'file_mode': '0600', 'dir_mode': '0700'},
               }
-%}
{% for filename, data in dirs.iteritems() %}
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
{% for filename in ('run-command-on-git-revisions',) %}
.dotfile-{{ filename }}:
  file.managed:
    - name: /usr/bin/{{ filename }}
    - source: salt://dotfiles/{{ filename }}
    - mode: '0755'
{% endfor %}

# Compile command-t
.compile-command-t:
  cmd.wait:
    - name: ruby extconf.rb && make
    - cwd: {{ grains.home }}/.vim/bundle/command-t/ruby/command-t
    - watch:
      - file: .dotfile-.vim
