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
span[started]:after{content:"*";color:red}
main{font-size:12px;line-height:1.15}
main>ul{padding-left:0;list-style:none;display:flex;flex-direction:column;gap:1rem}
li ul strong{font-weight:500}
strong a{text-decoration:none;font-weight:700;color:inherit}
li p strong{color:#000;font-weight:700;font-size:.95rem}
li p{margin:0 0;padding-bottom:.25rem}
ul{list-style-type:disc}
li,ul{color:#666}
h2{font-size:1.4rem;text-align:right;margin-right:10%;border-bottom:2px dotted gray;margin:2rem 0;padding:0 .5rem}
</style>

# Reading Activity 

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
     (.books | map("  - [" + $asset[.assetid].title + "][\(.assetid)] - \(.count) annotation\(if .count > 1 then "s" else "" end)" 
      + (if $asset[.assetid].cdate == $d2 then "  \n  - **Started [\($asset[.assetid].title)][\(.assetid)]**" else "" end)  )),""][] )|flatten|join("\n"))  
  ])
  | flatten(2)
  | join("\n\n") +"\n"' $HISTORYDATAPATH

jq -r 'sort_by(.permalink)|map("[\(.assetid)]:\t\(.permalink)")|join("\n")' $DATADIR/books.json
