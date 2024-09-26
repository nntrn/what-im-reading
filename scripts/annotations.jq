include "books";   

#   jq -L scripts 'include "annotations"; create_book_data' annotations.json
#   jq -L scripts 'include "annotations"; create_activity_data' annotations.json
#   jq -L scripts 'include "annotations"; create_word_data' annotations.json

def unsmart: . | gsub("[“”]";"\"") | gsub("[’‘]";"'");

def remove_cites:  
  gsub("\\[([0-9xiv]+)\\]";"";"m")
  | gsub("(?<q>[a-zA-Z][“”\"\\.]*)[0-9]+";.q);

def pretty_long_lines:
  gsub("\\n[\\t]+";"\n\n")
  | gsub("(?<a>[^\\n]{400,500}[[\\.\\?]]) "; .a + "\n\n");

def capturen($t;$n): "\($t) \($n|capture("c([^1-9]+)?(?<d>[0-9]+)").d)";

def create_book_data:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) )
  | group_by(.ZASSETID)
  | map( 
      min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE as $created |
      {
        assetid: .[0].ZASSETID,
        title: .[0].ZTITLE,
        author: .[0].ZAUTHOR,
        created: $created,
        modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
        started: ($created|fromdate|strflocaltime("%b %Y")|ascii_upcase),
        tags: get_tags(.[0].ZGENRE),
        slug: "\(get_author_slug(.[0].ZAUTHOR))-\(slugify(.[0].ZTITLE))",
        count: length,
        saved: length
      }
    )
  | map(. + {permalink: "\(.tags)/\(.slug)"});

def create_activity_data:
  map(select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10))
  | sort_by(.ZANNOTATIONCREATIONDATE)
  | map({
      id: .Z_PK,
      assetid: .ZASSETID,
      # raw_text:.ZANNOTATIONSELECTEDTEXT,
      text: (.ZANNOTATIONSELECTEDTEXT|remove_cites|pretty_long_lines|unsmart),
      created: .ZANNOTATIONCREATIONDATE,
      location: .ZANNOTATIONLOCATION,
      cfi:(epublocation(.ZANNOTATIONLOCATION)| map(lpad(3))|join("-")),
      chapter: (if ((.ZFUTUREPROOFING5|length)>0) then .ZFUTUREPROOFING5 else chaptername(.ZANNOTATIONLOCATION) end),
      rangestart: .ZPLLOCATIONRANGESTART
  })
  | sort_by(.id);

def create_word_data:
  map({
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
    });

def create_genre_data: 
  create_book_data
  | group_by(.tags)
  | map({
      tag: (.[0].tags), 
      title: (.[0].tags), 
      books: (map(del(.tags))) 
    })
;