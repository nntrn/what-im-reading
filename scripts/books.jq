# def stopwords: {
#   all: ["able","about","across","after","all","almost","also","among","and","any","are","because","been","but","can","cannot","could","dear","did","does","either","else","ever","every","for","from","get","got","had","has","have","her","hers","him","his","how","however","into","its","just","least","let","like","likely","may","might","most","must","neither","nor","not","off","often","only","other","our","own","rather","said","say","says","she","should","since","some","than","that","the","their","them","then","there","these","they","this","tis","too","twas","wants","was","were","what","when","where","which","while","who","whom","why","will","with","would","yet","you","your"],
#   compact: ["able","about","across","after","almost","also","among","because","been","cannot","could","dear","does","either","else","ever","every","from","have","hers","however","into","just","least","like","likely","might","most","must","neither","often","only","other","rather","said","says","should","since","some","than","that","their","them","then","there","these","they","this","twas","wants","were","what","when","where","which","while","whom","will","with","would","your"]
# }

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
      select(test("[a-zA-Z0-9]"))
      | gsub("[\\t]+"; "\t")
      | if length > 400 then  gsub("(?<=[\\S\\s]{300,500}\\.) "; "\n\n") else . end
    ) 
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
  | [match("(\\b[0-9]+)";"g").string|tonumber]|last|tostring;

def format_chapter:
  ([.]|flatten|unique) as $input
  | ($input | join(" ")
  | gsub("x?[0-9]{8,}"; .n; "x")) as $str
  | $str | 
  if test("[cC][chapter]{1,}") or test("^[cC].*([0-9]+)") then  "Chapter " + getnum($str) 
  elif test("toc_marker") then getnum($str)
  else 
    $str 
    | gsub("(epub|EPUB|[[:punct:]]?xhtml|html|ji[0-9]+|sup[0-9]+|nav_|div[0-9]+)"; "")
    | gsub("^[^a-zA-Z0-9]+";"")
  end
  ;

def format_location:
  [match("\\[([^\\]]+)\\]+";"g").captures[].string] as $raw 
  | ($raw|join(" ")|identify_subsection) as $sec
  | (if $sec then $sec  else ($raw|format_chapter) end)
  ;
