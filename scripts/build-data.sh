#!/usr/bin/env bash
set -e

SCRIPT="$(realpath "$0")"
TOPDIR=${SCRIPT%/*/*}
DIR=$TOPDIR
SCRIPTDIR=${SCRIPT%/*}

DEFAULT_REMOTE_URL=https://raw.githubusercontent.com/nntrn/bookstand/assets/annotations.json
# DEFAULT_DATA_DIR=_data
# DEFAULT_ANNOTATIONS_FILE=annotations.json

export OUTDIR=_data
export ANNOTATIONS_FILE=annotations.json
export FETCH_REMOTE=${FETCH_REMOTE:-0}
export REMOTE_URL="${DEFAULT_REMOTE_URL}"

mkdir -p $OUTDIR

_log() { echo -e "\033[0;${2:-33}m$1\033[0m" 3>&2 2>&1 >&3 3>&-; }

create_stats() {
  mkdir -p $OUTDIR/stats
  _log "Creating stats for monthly bookmarks"

  cat $OUTDIR/activity.json |
    jq 'sort_by(.created) 
    | map(. + {groupby_label: (.created|fromdate|strftime("%b %Y"))}) 
    | group_by(.groupby_label)
    | map({key: .[0].groupby_label, value: length})
    | from_entries' >$OUTDIR/stats/bookmarks_per_month.json

  cat $OUTDIR/activity.json |
    jq 'map(.+{sort:(.created|fromdate|strftime("%Y-%m")),d:(.created|fromdate|strftime("%b %Y"))})
      | sort_by(.sort) | group_by(.d)|sort_by(.[0].sort)
      | map({(.[0].d): {
          started: (map(.assetid)|unique), 
          saved_count: length, 
          saved: (group_by(.assetid)|map({(.[0].assetid): length})|add)  
          } 
      }) | add' >$OUTDIR/stats/month.json
}

call_jq_func_annotation() {
  local func=$1
  _log "Creating $func"
  cat $ANNOTATIONS_FILE | jq -L $SCRIPTDIR "include \"annotations\"; $func"
}

get_annotations() {
  _log "Fetching remote from $REMOTE_URL"
  curl -s --create-dirs -o $ANNOTATIONS_FILE "${REMOTE_URL}"
}

while true; do
  case $1 in
  -o | --out) OUTDIR="$2" && shift ;;
  -r | --remote) FETCH_REMOTE=1 ;;
  -f | --force) FETCH_REMOTE=1 ;;
  https*.json) REMOTE_URL="$1" ;;
  *.json) ANNOTATIONS_FILE="$1" ;;
  esac
  shift || break
done

if [[ ! -f $ANNOTATIONS_FILE || ! -s $ANNOTATIONS_FILE || $FETCH_REMOTE -eq 1 ]]; then
  get_annotations &
  pid=$!
  wait $pid
fi

call_jq_func_annotation create_book_data >$OUTDIR/books.json &
call_jq_func_annotation create_genre_data >$OUTDIR/genres.json &
call_jq_func_annotation create_activity_data >$OUTDIR/activity.json &
wait %3

_log "finished" 34
create_stats
