#!/usr/bin/env bash
set -e

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
export OUTDIR=_data
export ANNOTATIONS_FILE=annotations.json

_log() { echo -e "\033[0;${2:-33}m$1\033[0m" 3>&2 2>&1 >&3 3>&-; }

create_book_data() {
  _log "Creating books.json..."
  cat $ANNOTATIONS_FILE | jq -L $DIR 'include "books";   
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) |
    . + { booklocation: epublocation(.ZANNOTATIONLOCATION), ZTITLE: (.ZTITLE|gsub("\"";"") | gsub("\\([^0-9]+\\)"; "";"x"))})
  | group_by(.ZASSETID)
  | map({
      assetid: .[0].ZASSETID,
      title: .[0].ZTITLE,
      author: .[0].ZAUTHOR,
      created: min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      tags: get_tags(.[0].ZGENRE),
      slug: "\(get_author_slug(.[0].ZAUTHOR))-\(slugify(.[0].ZTITLE))",
      count: length
    })| map(. + {permalink: "\(.tags)/\(.slug)"})'
}

create_genre_data() {
  _log "Creating genre.json..."
  cat $OUTDIR/books.json |
    jq 'group_by(.tags)|map({tag: (.[0].tags), title: (.[0].tags), books: (map(del(.tags))) })'
}

create_activity_data() {
  _log "Creating activity.json..."
  cat $ANNOTATIONS_FILE | jq -L $DIR 'include "books"; 
    map(select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10))
    | sort_by(.ZANNOTATIONCREATIONDATE)
    | map({
      id: .Z_PK,
      assetid: .ZASSETID,
      text: (.ZANNOTATIONSELECTEDTEXT|remove_citations|format_text),
      created: .ZANNOTATIONCREATIONDATE,
      location: .ZANNOTATIONLOCATION,
      cfi:(epublocation(.ZANNOTATIONLOCATION)| map(lpad(3))|join("-")),
      chapter: (if ((.ZFUTUREPROOFING5|length)>0) then .ZFUTUREPROOFING5 else chaptername(.ZANNOTATIONLOCATION) end),
      rangestart: .ZPLLOCATIONRANGESTART
    })
    | sort_by(.id)'
}

create_word_data() {
  cat $ANNOTATIONS_FILE | jq 'map({
    Z_PK,
    ZASSETID,
    words: (.ZANNOTATIONSELECTEDTEXT
      | gsub("[.?!] (?<a>[A-Z])"; (.a|ascii_downcase);"x")
      | gsub("\([39]|implode)"; "")
      | gsub("[^a-zA-Z]+";" ";"x")|split(" ")
      | map(select(length >4))|sort|group_by(.)
      | map([.[0],length])
      | sort_by(.[1])
      | map(join("-"))
      | reverse)
  })'
}

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

while true; do
  case $1 in
  -o | --out) OUTDIR="$2" && shift ;;
  -r | --remote) FETCH_REMOTE=1 && shift ;;
  *.json) ANNOTATIONS_FILE="$1" && shift ;;
  esac
  shift || break
done

if [[ ! -f $ANNOTATIONS_FILE || $FETCH_REMOTE -eq 1 ]]; then
  _log "Fetching remote"
  ANNOTATIONS_FILE=/tmp/annotations.json
  curl --create-dirs -o $ANNOTATIONS_FILE https://raw.githubusercontent.com/nntrn/bookstand/assets/annotations.json
fi

if [[ -s $ANNOTATIONS_FILE ]]; then
  _log "===> Files will be saved to $OUTDIR <===" 36
  mkdir -p $OUTDIR
  create_book_data >$OUTDIR/books.json
  create_genre_data >$OUTDIR/genres.json
  create_activity_data >$OUTDIR/activity.json
  create_stats
else
  _log "annotations is empty"
fi
