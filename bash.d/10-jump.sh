#!/bin/bash
LOG_FILE="$HOME/.jump.log"
COMPRESSED_LOG_FILE="$HOME/.jump-compressed.log"
DEFAULT_ADAPTIVE_JUMPLOCS=20
NUM_COMPRESSED_JUMPLOCS=40

__log_pwd() {
  if [ "$PWD" != "$HOME" ]; then
    echo "$(readlink -f $PWD)" >>"$LOG_FILE"
  fi
}

if [ -z "$DISABLE_ADAPTIVE_JUMPLOCS" ]; then
  export PS1="$PS1"'$(__log_pwd)'
fi

__compress() {
  if [ ! -e "$LOG_FILE" ]; then
    return
  fi
  echo "[compressing adaptive jumplist]" >&2
  # Dump the count into the compressed file
  awk '{!seen[$0]++}END{for (i in seen) print seen[i], i}' "$LOG_FILE" \
    | sort -rn \
    | head -n "$NUM_COMPRESSED_JUMPLOCS" >>"$COMPRESSED_LOG_FILE"
  # Compress the compressed file
  local tmpfile
  tmpfile="${COMPRESSED_LOG_FILE}.tmp"
  awk '{seen[$2]+=$1}END{for (i in seen) print seen[i] * 0.9, i}' "$COMPRESSED_LOG_FILE" \
    | sort -rn \
    | head -n "$NUM_COMPRESSED_JUMPLOCS" >"$tmpfile"
  mv "$tmpfile" "$COMPRESSED_LOG_FILE"
  # Delete log file
  rm -f "$LOG_FILE"
}

__load_from_compressed() {
  if [ -e "$LOG_FILE" ]; then
    local num_new_logs
    num_new_logs=$(wc -l "$LOG_FILE" | cut -f 1 -d ' ')
    if [ $num_new_logs -gt 100 ]; then
      __compress
    fi
  fi
  head -n ${NUM_ADAPTIVE_JUMPLOCS-$DEFAULT_ADAPTIVE_JUMPLOCS} "$COMPRESSED_LOG_FILE" | cut -f 2 -d ' '
}

__load_from_uncompressed() {
  local start_time
  local stop_time
  start_time=$(date +%s.%N)
  awk '{!seen[$0]++}END{for (i in seen) print seen[i], i}' "$LOG_FILE" \
    | sort -rn \
    | head -n ${NUM_ADAPTIVE_JUMPLOCS-$DEFAULT_ADAPTIVE_JUMPLOCS} \
    | cut -f 2 -d ' '
  stop_time=$(date +%s.%N)
  if command -v bc >/dev/null; then
    local runtime
    runtime=$(echo "1000 * ($stop_time - $start_time)" | bc -l | cut -f 1 -d .)
    if [ "$runtime" -gt 500 ]; then
      __compress
    fi
  fi
}

j() {
  declare -g -A JUMP_LOCATIONS

  if command -v __load_jumplocs >/dev/null; then
    __load_jumplocs
  fi

  if [ -z "$DISABLE_ADAPTIVE_JUMPLOCS" ]; then
    local top_paths
    if [ -e "$COMPRESSED_LOG_FILE" ]; then
      top_paths=$(__load_from_compressed)
    elif [ -e "$LOG_FILE" ]; then
      top_paths=$(__load_from_uncompressed)
    fi
    for path in $top_paths; do
      local key
      key="$(basename "$path")"
      if ! test "${JUMP_LOCATIONS[$key]+isset}"; then
        JUMP_LOCATIONS[$key]="$path"
      fi
    done
  fi

  local key="$1"
  shift

  if [ "$key" == "__source" ]; then
    complete -W "${!JUMP_LOCATIONS[*]}" j
  elif [ "$key" == "__compress" ]; then
    __compress
  elif [ "$key" == "__query" ]; then
    local here
    here="$(readlink -f "$(pwd)")"
    for k in ${!JUMP_LOCATIONS[*]}; do
      if [ "$here" == "$(readlink -f "${JUMP_LOCATIONS[$k]}")" ]; then
        echo -n "$k"
        break
      fi
    done
  elif [ -z "$key" ] || [ "$key" == "-h" ]; then
    echo "j" "[${!JUMP_LOCATIONS[*]}]"
    return
  else
    if ! test "${JUMP_LOCATIONS[$key]+isset}"; then
      echo "No jump location '$key'" >&2
      return 1
    fi
    local dest="${JUMP_LOCATIONS[$key]}"
    if [ -d "$dest" ]; then
      cd "$dest" || return 1
    else
      echo "Jump location '$key' leads to nonexistent dir '$dest'" >&2
      return 1
    fi
  fi
}

export j
j "__source"
