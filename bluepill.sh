#!/bin/bash
# The MIT License (MIT)

# Copyright (c) 2016 Steven Arcangeli

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
command -v docker > /dev/null || return

[ -z "$BLUEPILL_ROOT_IMAGE" ] && BLUEPILL_ROOT_IMAGE="ubuntu:14.04"
BLUEPILL_BASE_IMAGE="bluepill-$USER"

###########
#  UTILS  #
###########

_confirm() {
  # $1 (optional) [str] - Prompt string
  # $2 (optional) [y|n] - The default return value if user just hits enter
  local prompt="${1-Are you sure?}"
  local default="$2"
  case $default in
    [yY])
      prompt="$prompt [Y/n] "
      ;;
    [nN])
      prompt="$prompt [y/N] "
      ;;
    *)
      prompt="$prompt [y/n] "
      ;;
  esac
  while [ 1 ]; do
    read -r -p "$prompt" response
    case $response in
      [yY][eE][sS]|[yY])
        return 0
        ;;
      [nN][oO]|[nN])
        return 1
        ;;
      *)
        if [ -z "$response" ]; then
          case $default in
            [yY])
              return 0
              ;;
            [nN])
              return 1
              ;;
          esac
        fi
        ;;
    esac
  done
}

command -v realpath > /dev/null 2>&1 || realpath() {
  if ! readlink -f "$1" 2> /dev/null; then
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
  fi
}

_bp-image-name() {
  echo "$(basename "${1?_bp-image-name missing arg}")-$(echo "$1" | md5sum | cut -f 1 -d ' ')"
}

_bp-container-name() {
  echo "C$(basename "${1?_bp-image-name missing arg}")-$(echo "$1" | md5sum | cut -f 1 -d ' ')"
}

##############
#  COMMANDS  #
##############

bluepill() {
  if [ -z "$1" ]; then
    bluepill-help
  else
    local cmd="bluepill-$1"
    if command -v $cmd > /dev/null; then
      shift
      $cmd "$@"
    else
      bluepill-help "$@"
    fi
  fi
}

bluepill-help() {
  if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "
Usage:  bluepill COMMAND [arg...]

Commands:
  build       Build a docker image for a directory
  delete      Delete the container and image for a directory
  edit        Make interactive changes to your base bluepill image
  enter       Build a container for a directory
  setup       Builds your base image that all other containers will inherit from

Run 'bluepill help COMMAND for more information on a command"
  elif command -v bluepill-$1 > /dev/null; then
    bluepill-$1 -h
  else
    echo "bluepill: '$1' is not a command."
    echo "See 'bluepill help'"
  fi
}

bluepill-setup() {
  local usage="
Usage:  bluepill setup

Builds your base image that all other containers will inherit from

  -h, --help   Print usage"
  unset OPTIND
  while getopts "h-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          help)
            echo "$usage"
            return 0
            ;;
        esac
        ;;
      h)
        echo "$usage"
        return 0
        ;;
    esac
  done
  shift $(($OPTIND-1))
  if docker inspect $BLUEPILL_BASE_IMAGE > /dev/null 2>&1; then
    _confirm "Image $BLUEPILL_BASE_IMAGE already exists. Would you like to replace it?" n || \
      return
  fi
  docker build -t $BLUEPILL_BASE_IMAGE - <<EOF
FROM $BLUEPILL_ROOT_IMAGE
RUN groupadd -g $(id -g) $USER && \
  useradd -m -u $UID -g $(id -g) -s /bin/bash $USER && \
  echo "$USER ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
EOF
  echo "Customize your base image. Type 'exit' when done"
  bluepill-edit
}

bluepill-edit() {
  local usage="
Usage:  bluepill edit

Make interactive changes to your base bluepill image

  -h, --help   Print usage"
  unset OPTIND
  while getopts "h-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          *)
            echo "$usage"
            return 1
            ;;
        esac
        ;;
      h)
        echo "$usage"
        return 0
        ;;
      \?)
        echo "$usage"
        return 1
        ;;
    esac
  done
  shift $(($OPTIND-1))
  docker inspect bluepill-setup >/dev/null 2>&1 && docker rm bluepill-setup
  docker run --name bluepill-setup -it -e USER -w $HOME -u $UID:$(id -g) \
    $BLUEPILL_BASE_IMAGE /bin/bash -l
  _confirm "Replace current image with changes?" y && \
    docker commit bluepill-setup $BLUEPILL_BASE_IMAGE
  docker rm bluepill-setup
}

bluepill-build() {
  if ! docker inspect $BLUEPILL_BASE_IMAGE > /dev/null 2>&1; then
    echo "To start using bluepill, first run 'bluepill setup'"
    return 1
  fi
  local usage="
Usage:  bluepill build [OPTIONS] [DIRECTORY]

Build a docker image for a directory

  -f <file>    Path to Dockerfile (looks for DIRECTORY/Dockerfile by default)
  -h, --help   Print usage"
  unset OPTIND
  while getopts "f:h-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          *)
            echo "$usage"
            return 1
            ;;
        esac
        ;;
      f)
        local dockerfile="$OPTARG"
        ;;
      h)
        echo "$usage"
        return 0
        ;;
      \?)
        echo "$usage"
        return 1
        ;;
    esac
  done
  shift $(($OPTIND-1))
  local dir="$(realpath ${1-.})"
  local imageName="$(_bp-image-name "$dir")"
  pushd "$dir" > /dev/null
  if [ -z "$dockerfile" ] && [ -e Dockerfile ]; then
    local dockerfile="Dockerfile"
  fi
  if docker inspect "$imageName" > /dev/null 2>&1; then
    _confirm "Image $imageName already exists. Would you like to replace it?" n || \
      return
  fi
  if [ -n "$dockerfile" ]; then
    cd "$(dirname "$dockerfile")"
    echo "FROM $BLUEPILL_BASE_IMAGE" > .Dockerfile.bp
    echo "USER root" >> .Dockerfile.bp
    cat "$(basename "$dockerfile")" | sed /^FROM/d >> .Dockerfile.bp
    echo "USER $USER" >> .Dockerfile.bp
    docker build -t "$imageName" -f .Dockerfile.bp .
    rm .Dockerfile.bp
  else
    docker tag $BLUEPILL_BASE_IMAGE $imageName
  fi
  popd > /dev/null
}

bluepill-enter() {
  if ! docker inspect $BLUEPILL_BASE_IMAGE > /dev/null 2>&1; then
    echo "To start using bluepill, first run 'bluepill setup'"
    return 1
  fi
  local usage="
Usage:  bluepill enter [OPTIONS] [DIRECTORY] [-- DOCKER ARGS]

Build a container for a directory

  You may end the command with '--' and any number of arguments to pass to
  'docker run'

  -h, --help   Print usage"
  unset OPTIND
  while getopts "h-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          help)
            echo "$usage"
            return 0
            ;;
        esac
        ;;
      h)
        echo "$usage"
        return 0
        ;;
    esac
  done
  local secondToLast=$(($OPTIND-1))
  local lastArg=${!secondToLast}
  shift $secondToLast
  if [ "$lastArg" == "--" ]; then
    local dir="$(realpath .)"
  else
    local dir="$(realpath ${1-.})"; shift
  fi
  [ "$1" == "--" ] && shift
  local imageName="$(_bp-image-name "$dir")"
  local containerName="$(_bp-container-name "$dir")"
  if ! docker inspect "$imageName" > /dev/null 2>&1; then
    echo "Must run 'bluepill build' before doing 'bluepill enter'"
    return 1
  fi
  local sshArgs=
  if [ -n "$SSH_AUTH_SOCK" ]; then
    local sshArgs="-v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
  elif [ -e $HOME/.ssh/id_rsa ]; then
    local sshArgs="-v $HOME/.ssh/id_rsa:$HOME/.ssh/id_rsa:ro"
    local sshArgs="$sshArgs -v $HOME/.ssh/id_rsa.pub:$HOME/.ssh/id_rsa.pub:ro"
  fi
  echo "Image name: $imageName"
  if docker inspect $containerName > /dev/null 2>&1; then
    docker start -i "$containerName"
  else
    docker run --name="$containerName" -it \
      -u "${UID}:$(id -g)" \
      --userns=host \
      --net=host \
      -v "$dir:$HOME/$(basename "$dir")" \
      $sshArgs \
      "$@" \
      $imageName
  fi
}

bluepill-delete() {
  local usage="
Usage:  bluepill delete [DIRECTORY]

Delete the container and image for a directory

  -h, --help   Print usage"
  unset OPTIND
  while getopts "h-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          *)
            echo "$usage"
            return 1
            ;;
        esac
        ;;
      h)
        echo "$usage"
        return 0
        ;;
      \?)
        echo "$usage"
        return 1
        ;;
    esac
  done
  shift $(($OPTIND-1))
  local dir="$(realpath ${1-.})"
  local imageName="$(_bp-image-name "$dir")"
  local containerName="$(_bp-container-name "$dir")"
  _confirm "Delete docker container $containerName?" n || return
  docker rm -f $containerName
  _confirm "Delete docker image $imageName?" n || return
  docker rmi $imageName
}
