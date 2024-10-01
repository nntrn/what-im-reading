include "books";   

def stop: {
  all: ["able","about","across","after","all","almost","also","among","and","any","are","because","been","but","can","cannot","could","dear","did","does","either","else","ever","every","for","from","get","got","had","has","have","her","hers","him","his","how","however","into","its","just","least","let","like","likely","may","might","most","must","neither","nor","not","off","often","only","other","our","own","rather","said","say","says","she","should","since","some","than","that","the","their","them","then","there","these","they","this","tis","too","twas","wants","was","were","what","when","where","which","while","who","whom","why","will","with","would","yet","you","your"],

  compact: ["able","about","across","after","almost","also","among","because","been","cannot","could","dear","does","either","else","ever","every","from","have","hers","however","into","just","least","like","likely","might","most","must","neither","often","only","other","rather","said","says","should","since","some","than","that","their","them","then","there","these","they","this","twas","wants","were","what","when","where","which","while","whom","will","with","would","your"]
};

# functions using annotations.json ###########################################

def create_book_data:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) )
  | group_by(.ZASSETID)
  | map( min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE as $created | {
      assetid: .[0].ZASSETID,
      title: .[0].ZTITLE,
      author: .[0].ZAUTHOR,
      created: $created,
      modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      started: ($created|fromdate|strflocaltime("%b %Y")|ascii_upcase),
      tags: (.[0].ZGENRE|get_tags),
      slug: "\(get_author_slug(.[0].ZAUTHOR))-\(slugify(.[0].ZTITLE))",
      count: length,
      saved: length
  }) | map(. + {url: "\(.tags)/\(.slug)"});

def create_activity_data:
  map(select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10))
  | sort_by(.ZANNOTATIONCREATIONDATE)
  | map({
      id: .Z_PK,
      assetid: .ZASSETID,
      text: (.ZANNOTATIONSELECTEDTEXT|unsmart|remove_cites|format_quotes|join("\n")),
      created: .ZANNOTATIONCREATIONDATE,
      location: .ZANNOTATIONLOCATION,
      cfi: (.ZANNOTATIONLOCATION|[match("\\b[0-9]{1,4}\\b";"g").string|tonumber]|join(".")),
      chapter: (if ((.ZFUTUREPROOFING5|length)>0) then .ZFUTUREPROOFING5 else (.ZANNOTATIONLOCATION|format_location)? // .rangestart end),
      rangestart: .ZPLLOCATIONRANGESTART
  }) | sort_by(.id);

def create_word_data:
  map({
      Z_PK,
      ZASSETID,
      words: (.ZANNOTATIONSELECTEDTEXT
        | ascii_downcase
        | gsub("[.?!] (?<a>[A-Z])"; (.a|ascii_downcase);"x")
        | gsub("[[:punct:]] "; " ")
        | gsub("[^a-zA-Z]+";" ";"x")
        | split(" ")
        | map(select(length >4))
        | sort
        | group_by(.)
        | map([(.[0]|ascii_downcase),length])
        | sort_by(.[1])
        | map(join("-"))
        | reverse|join(" "))
    });

def create_genre_data: 
  create_book_data
  | group_by(.tags)
  | map({
      tag: (.[0].tags), 
      title: (.[0].tags), 
      books: (map(del(.tags))) 
    });

# functions using activity.json ###############################################

def stats_bookmarks_per_month:
  sort_by(.created) 
  | map(. + {groupby_label: (.created|fromdate|strftime("%b %Y"))}) 
  | group_by(.groupby_label)
  | map({key: .[0].groupby_label, value: length})
  | from_entries;

def stats_month: 
  map(.+{sort:(.created|fromdate|strftime("%Y-%m")),d:(.created|fromdate|strftime("%b %Y"))})
  | sort_by(.sort) | group_by(.d)|sort_by(.[0].sort)
  | map({(.[0].d): {
      started: (map(.assetid)|unique), 
      saved_count: length, 
      saved: (group_by(.assetid)|map({(.[0].assetid): length})|add)  
      } 
  }) | add;

def stats_history:
  map((.created|strptime("%Y-%m-%dT%H:%M:%SZ")|mktime) as $dt | 
    { 
      id,assetid,created,
      date: $dt, 
      ymd: ($dt|strftime("%Y-%m-%d")), 
      month: ($dt|strftime("%b %Y")) 
    })
  | group_by(.month)
  | map({ 
      month: .[0].month, 
      sortdt: (.[0].date|strftime("%Y %m")),
      month_count: length,
      activity: ( 
        group_by(.ymd)
        | reverse
        | map({
            date: .[0].ymd, 
            date_count: length,
            books: (map(.assetid)|group_by(.) | map({  assetid: .[0], book_count: length }))
        })
      )
    })
  | sort_by(.sortdt)
  | reverse;

# jq -r -L scripts --slurpfile books _data/books.json 'include "annotations"; stats_history_text' _data/history.json
def stats_history_text:
  if ($books|length) > 0 then
  ( [  
      # title
      "Reading activity", "="*16,
      "", 
      "*** denotes date when book was started",
      "",
      # create markdown file showing activity from _data/history.json
      # index $books to get date book was started
      ($books[] | map(. + {cdate: (.created|strptime("%Y-%m-%dT%H:%M:%SZ")|mktime|strftime("%Y-%m-%d"))}) |INDEX(.[];.assetid)) as $asset | map([
          .month, 
          ("-" * (.month|length)), "",
          (.activity | map( .date as $d2 | [
            "  * **\(.date)**", "", 
            (
              .books | map((if .book_count > 1 then "annotations" else "annotation" end) as $noun
                | (if $asset[.assetid].cdate == $d2 then " ***" else "" end) as $starttext
                | "     - [\($asset[.assetid].title|gsub("[\\[\\]]";""))][\(.assetid)] - \(.book_count) \($noun)\($starttext)" 
                ) 
            ),
            ""
            ])
          ), ""
      ]), 
      # create link reference from _data/books.json
      ($books[]|sort_by(.permalink)|map("[\(.assetid)]:\t\(.permalink)"))
    ] 
    | flatten | join("\n") )
  else  
    error("path to _data/books.json was not passed")
  end
;