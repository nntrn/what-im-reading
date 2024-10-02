#!/usr/bin/env bash

set -e

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*/*}
_scriptdir=${SCRIPT%/*}

DEFAULT_REMOTE_URL="https://nntrn.github.io/store/annotations.json"
DEFAULT_ANNOTATIONS_FILE=annotations.json

export OUTDIR=$DIR
export ANNOTATIONS_FILE=$DEFAULT_ANNOTATIONS_FILE
export FETCH_REMOTE=0
export REMOTE_URL="$DEFAULT_REMOTE_URL"
export RUN_ONLY=

_log() { echo -e "\033[0;${2:-33}m$1\033[0m" 3>&2 2>&1 >&3 3>&-; }

set_remote() {
  FETCH_REMOTE=1
  if [[ $1 == "https://"* ]]; then
    REMOTE_URL="$1"
  elif [[ -n $1 ]]; then
    _log "Did not set $1"
  fi
}

jq_from_annotations() {
  local func=$1
  _log "* Running $func" 36
  jq -L $_scriptdir "include \"annotations\"; $func" $ANNOTATIONS_FILE
}

jq_from_activity() {
  local func=$1
  _log "* Running $func" 35
  jq -L $_scriptdir "include \"annotations\"; $func" $DATADIR/activity.json
}

get_annotations() {

  if [[ ! $REMOTE_URL == "https://"* ]]; then
    REMOTE_URL=$DEFAULT_REMOTE_URL
  fi

  _log "Fetching annotations from $REMOTE_URL" 37
  curl -s -o $ANNOTATIONS_FILE "${REMOTE_URL}"

  return $?
}

while true; do
  case $1 in
  -o | --out) OUTDIR="$2" && shift ;;
  -R | --run-only) RUN_ONLY="$2" && shift ;;
  -u | --url) set_remote "$2" && shift ;;
  -r | --remote) set_remote ;;
  https*.json) set_remote "$1" ;;
  *.json) ANNOTATIONS_FILE="$1" ;;
  esac
  shift || break
done

export DATADIR=$OUTDIR/_data

if [[ ! -f $ANNOTATIONS_FILE ]] ||
  [[ ! -s $ANNOTATIONS_FILE ]] ||
  [[ $FETCH_REMOTE -eq 1 ]]; then

  get_annotations &
  wait %1
fi

if [[ -n $RUN_ONLY ]]; then
  if [[ $RUN_ONLY == "stat_"* ]]; then
    jq_from_activity $RUN_ONLY
  else
    jq_from_annotations $RUN_ONLY
  fi
else

  mkdir -p $OUTDIR/{_data/stats,_pages}

  jq_from_annotations create_book_data >$DATADIR/books.json &
  jq_from_annotations create_genre_data >$DATADIR/genres.json &
  jq_from_annotations create_activity_data >$DATADIR/activity.json &
  # jq_from_annotations create_word_data >$DATADIR/words.json &
  wait %3

  jq_from_activity stats_bookmarks_per_month >$DATADIR/stats/bookmarks_per_month.json &
  jq_from_activity stats_month >$DATADIR/stats/month.json &
  jq_from_activity stats_history >$DATADIR/history.json &
  wait %3

  # _log "* Creating _includes/activity.txt"

#   jq -r -L $_scriptdir --slurpfile books $DATADIR/books.json 'include "annotations"; stats_history_text' \
#     $DATADIR/history.json >$OUTDIR/_pages/activity.txt
#
#   cat $OUTDIR/_pages/activity.txt >$OUTDIR/_includes/activity.txt

fi
