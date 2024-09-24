#!/usr/bin/env bash
set -e

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*/*}

DATADIR=$DIR/_data
ASSETSDIR=$DIR/assets/data
HISTORYDATAPATH=$ASSETSDIR/history.json

mkdir -p $ASSETSDIR

jq 'map(
  (.created|strptime("%Y-%m-%dT%H:%M:%SZ")|mktime) as $dt 
  | { 
      id,assetid,created,
      date:$dt, 
      ymd: ($dt|strftime("%Y-%m-%d")), month: ($dt|strftime("%b %Y")) 
    }
  )
  | group_by(.month)
  | map({ 
      month: .[0].month, 
      sortdt: (.[0].date|strftime("%Y %m")),
      count: length,
      dates: (
        map({assetid, date, ymd}) 
        | group_by(.ymd)
        | map({
            date: .[0].ymd, 
            books: (map(.assetid)|group_by(.)|map({ assetid: .[0], count: length }))
          }) 
      )
  })
  | sort_by(.sortdt)|reverse' $DATADIR/activity.json >$HISTORYDATAPATH

jq -n --unbuffered env &>/dev/null

echo '---
title: Reading Activity
layout: default
permalink: /activity
---

<style>
li p{margin: 0 0;}
span[started]:after{content:"*";color:red}
</style>

# Reading Activity 

<span started="1"></span> = started book 
'

jq -r --slurpfile books $DATADIR/books.json '($books[] | 
    map(. + {cdate: (.created|strptime("%Y-%m-%dT%H:%M:%SZ")|mktime|strftime("%Y-%m-%d"))}) | 
    INDEX(.[];.assetid)
  ) as $asset 
  | map([
    "## " +.month,
    (.dates
    | map(.date as $d2 | [
      "* **\(.date)**" ,
      "", 
     (.books | map("  - \(.count) annotation\(if .count > 1 then "s" else "" end) for [" + $asset[.assetid].title + "][\(.assetid)]" 
      + (if $asset[.assetid].cdate == $d2 then " <span started=1></span>" else "" end)  )),""][] )|flatten|join("\n"))  
  ])
  | flatten(2)
  | join("\n\n") +"\n"' $HISTORYDATAPATH

jq -r 'sort_by(.permalink)|map("[\(.assetid)]:\t\(.permalink)")|join("\n")' $DATADIR/books.json
