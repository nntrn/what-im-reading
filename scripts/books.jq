def cleannbsp: gsub("[\u202F\u00A0]";" ";"x");

def getinsidecfi: 
  [ match("\\[([a-zA-Z0-9][^\\]]+)\\]+";"g").captures[].string
    | gsub("[-_]+";" ";"x")
    | gsub("(text|item|epub|EPUB|xhtml|html|x[0-9]{3,}[ ]?)";"";"x")
    | gsub("^[ ]+|[ ]$";"";"x")
    # | gsub("(epub|EPUB|[[:punct:]]?xhtml|html|ji[0-9]+|sup[0-9]+|nav_|div[0-9]+)"; "")
  ] 
  | unique 
  ; 

def squo: [39]|implode;
def lpad(n): tostring | if (n > length) then ((n - length) * "0") + . else . end;
def squote($text): [squo,$text,squo]|join("");
def dquote($text): "\"\($text)\"";

def unsmart: . | gsub("[“”]";"\"") | gsub("[’‘]";"'");

def unsmart($text): $text | unsmart;

def get_tags($tag): ($tag|split("[\\s]?([^\\w\\s]|for)[\\s]";"x")?|max_by(split(" ")|length)|ascii_downcase|gsub("[\\s]";"-";"x"));

def get_tags: get_tags(.);

def get_author($a):
  (($a|split("(\\s)?[;&,]+";"x")|.[0]|gsub("[':]";"")|gsub("[\\.\\s]+";"-")|ascii_downcase)?);

def get_author: get_author(.);

def epublocation($cfi):
  $cfi
  | gsub("[^0-9]";"-") | gsub("^[-]+";"") | gsub("[-]+$";"";"x") | gsub("[-]{1,}";"-")
  | split("-")|.[1:]
  | map(select(length < 5)|tonumber);

def split_long_title($text):
  $text
  | split("\\s?[(:)]\\s?";"x")
  | (map(select(length > 0))| [.[0],(.[1:]|map(select(contains("Volume"))))]|flatten|join(" "));

def slugify($text):
  ([39]|implode) as $squo
  | (if ($text|length)>40 then split_long_title($text) else $text end)
  | ascii_downcase
  | gsub($squo;"";"x")
  | gsub("[\\*\"]";"";"x")
  | gsub("[^a-zA-Z0-9]+";"-";"x")
  | gsub("-$";"";"x");

def get_author_slug($s):
  $s
  | (if test("&";"x") then split("[,&][\\s]?";"x") else split("; ") end )[0]
  | gsub("[.,]";"")
  | gsub("[^\\w\\d]+";"-";"x")
  | gsub("-$";"";"x")
  | ascii_downcase
  ;

def remove_cites:  
  gsub("\\[([0-9xiv]+)\\]";"";"m") | gsub("(?<q>[a-zA-Z][“”\"\\.]*)[0-9]+";.q);

def format_quotes:
  gsub("^[\\n ]+|[ \\n]+$";"")
  | split("\n")
  | map(
      select(test("[a-zA-Z0-9]{3,}";"x"))
      | gsub("[\\t]+"; "\t")
      # | if length > 400 then  gsub("(?<=[\\S\\s]{300,500}\\.) "; "\n\n") else . end
    ) 
  | join("\n")
  ;

def identify_subsection:
  . as $string |
    if test("[cC][onclusi]{2,}") then "Conclusion"
    elif test("([iI][ntroduci]{1,}|[iI]tr)";"x") then "Introduction"
    elif test("[pP][reface]{2,}") then "Preface"
    elif test("[dD][edicaton]{2,}") then "Dedication"
    elif test("[fF][orewrd]{2,}") then "Foreword"
    elif test("[eE][pilogue]{2,}") then "Epilogue"
    elif test("[Pp][rologue]{2,}") then "Prologue"
    elif test("[gG][losary]{2,}") then "Glossary"
    elif test("[aA][fterword]{3,}") then "Afterword"
    elif test("[aA][pendix]{3,}";"i") then "Appendix"
    elif test("[fF][ront]{2,}") then "Front"
    elif test("^[A-Z0-9 ]+$") then ($string |gsub("[^0-9]";"")|tonumber|tostring)
    else  null
    end
  ;

def getnum($str): $str
  | gsub("(?<w>[^0-9])(?<n>[0-9]+)";.w + " " + .n)
  | [match("(\\b[0-9]+)";"g").string|tonumber]|first|tostring;

def getchapternum($str): $str
  | [$str]|flatten|join(" ")
  | gsub(".*(?<c>[cC][\\w\\D]+?)(?<d>[0-9]+).*";.d;"x")
  | tonumber|tostring
  ;

def chapter_abbr: 
  . as $cfi |
  ascii_downcase | 
  if test("nts") then "Notes" 
  elif  test("ack") then "Acknowledgements" 
  else $cfi
  end 
;

def format_chapter:
  ([.]|flatten|unique) as $input
  | ($input | join(" ")
  | gsub("x?[0-9 ]{8,}"; ""; "x")) as $str
  | $str | 
  # if test("[cC][chapter]{1,}";"i") then  "Chapter " + getnum($input|map(select("^[cChapter]{2,}"))|first)
  if test("[chapter]{3,}|^[cC]";"i") then  "Chapter " + getchapternum($input|map(select("[chapter]{3,}|^[cC]")))
  elif test("toc_marker") then getnum($str)
  else 
    $str 
    | gsub("(epub|EPUB|[[:punct:]]?xhtml|html|ji[0-9]+|sup[0-9]+|nav_|div[0-9]+)"; "")
    | gsub("^[^a-zA-Z0-9]+";"") 
    # | chapter_abbr
    # | if ($input[0]| test("^[cC][chapter]{1,}")) then  "Chapter " + getnum($str) 
  end
  ;

def format_location:
  [match("\\[([^\\]]+)\\]+";"g").captures[].string] as $raw 
  | ($raw|join(" ")|identify_subsection) as $sec
  | (if $sec then $sec  else ($raw|first|format_chapter) end)
  ;
