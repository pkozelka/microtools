#!/bin/bash
# Simple tool simulating the functionality of Jenkins' stash/unstash commands in local build.
# State: DRAFT

STASH_DIR=$HOME/.cache/stash

#X="cpp/build/libdaimojo_static.a cpp/build/BUILD_INFO.txt build/cpp/libpytorch_scorer_c.so build/cpp/*.pb.h build/cpp/test/*.pb.h build/cpp/src/c/*.pb.h build/py/daimojo/*.pb.h"
X="cpp/build/libdaimojo_static.a cpp/build/BUILD_INFO.txt build/cpp/libpytorch_scorer_c.so build/cpp/*.pb.h build/cpp/CMakeFiles/mojo_obj.dir/src/*/*.o build/cpp/CMakeFiles/mojo_obj.dir/src/*.o"


function fileset() {
  local id="${1?}"
  case "$id" in
  x) echo $X;;
  *) echo "ERROR: Invalid stash id: '$id'. Use one of these: ">&2; ls -1 "$STASH_DIR" >&2; return 1;;
  esac
}

function stash() {
  local id="${1?}"
  echo "STASH: storing '$id'" >&2
  [ -d "$STASH_DIR/$id" ] && echo "WARNING: stash '$id' already exists, and has these files: $(find "$STASH_DIR/$id" -type f -printf '%f ')" >&2
  mkdir -p "$STASH_DIR/$id"
  local fileset
  fileset=$(fileset "$id" || return 1)
  local d
  for p in $fileset; do
    for f in $p; do
      d=${f%/*}
      mkdir -p "$STASH_DIR/$id/$d" || return 1
      cp -av "$f" "$STASH_DIR/$id/$d/" # ignore errors - in case of no match
    done
  done
  true
}

function unstash() {
  local id="${1?}"
  echo "STASH: restoring '$id'" >&2
  rsync -azi "$STASH_DIR/$id/" "."
}

function remove() {
  local id="${1?}"
  echo "STASH: removing '$id'">&2
  rm -rfv "${STASH_DIR:?}/${id}" || true
}

function list() {
  local id="${1?}"
  echo "STASH: listing '$id'">&2
  find "$STASH_DIR/$id" -type f -printf '%P\n'
}

function list_tree() {
  local id="${1?}"
  echo "STASH: tree '$id'">&2
  tree --filesfirst -h "$STASH_DIR/$id" -T 'Stash'
}

function clean() {
  for d in "${STASH_DIR}"/*; do
    [ -d "$d" ] || continue
    echo "STASH: removing '$d'">&2
    rm -rf "$d"
  done
}

function help() {
	cat <<EOF
Options:
-s <id> stash
-u <id> unstash
-l [<id>] list
--clean remove everything stashed
EOF
}

function main() {
  local action="help"
  case "$1" in
  "-h") action="help";;
  "-s") action="stash";;
  "-u") action="unstash";;
  "-r") action="remove";;
  "-l") action="list";;
  "-t") action="list_tree";;
  "--clean") action="clean";;
  *) echo "ERROR: Unknown option: $1"; return 1;;
  esac
  shift
  $action "$@"
}

main "$@"
