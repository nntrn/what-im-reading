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

def remove_citations($text):
  $text 
    | gsub("(?<a>[^0-9\\$,]{3})[0-9]{1,2}(?<b>[^0-9%\\.,]{2})"; .a +.b; "x")
    | gsub("(?<a>[^0-9]{3})[0-9]{1,2}([\\s]+)?$"; .a +.b; "xs");

def remove_citations: remove_citations(.);

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
  | ascii_downcase;

 def epubchapname($cfi):
  $cfi
  | [match("(\\[[^\\]]+\\])+";"g")]
  | map(
    .string
    | gsub("[\\]\\[]+";"";"x")
    | gsub("(?<a>[a-zA-Z])[0]+(?<d>[0-9])";.a + " " + .d;"x")
    | gsub("[xX][0-9]{2,}[^a-zA-Z0-9]+";" ";"x")
    | gsub("([x\\.]+)?html";"";"x")
    | gsub("[_-]";" ";"x")
    | gsub("(?<a>[a-zA-Z])(?<n>[0-9])";.a + " " + .n;"x")
    | gsub("(?<a>[a-zA-Z])[0]{1,}(?<n>[1-9])";.a + " " +.n;"x")
    | gsub("^[pP][\\s]+";"Part ";"x")
    | gsub("^[Ccx]([hapter]+)? ";"Chapter";"xi")
    | gsub("^[Ss]([ection ]+)";"Section";"xi")
    | gsub("^[iI]([ntroduction]{1,}).*";"Introduction";"x")

    |select(length>0)
  )  | unique[0]
  ;

def chaptername($location):
  $location
  | capture("\\[(?<chapter>[^\\]]+)\\]").chapter
  | gsub("[0-9]{4,}|margins|\\.?xhtml|epub|ebook|\\.html";"";"xi")
  | gsub("[_-]+";" ")
  | gsub("[\\s ]$";"";"x")
  | gsub("(?<w>[a-zA-Z])(?<d>[0-9])"; .w + " " + .d)
  | gsub("(?:.{0,6})?[cC]hapter?(?:[\\s0]+)?";"Chapter ";"x")
  | gsub("^[Ccx]([hapter ]+)([^0-9]+|[0-9]{4,})?(?<c>[0-9])";"Chapter "+ .c;"xi")
  | gsub("^[Ss]([ection ]+)? ";"Section ";"xi")
  | gsub("^[iI][nt][cdinortu]+(?<s>[\\s])?";"Introduction" + .s;"xi")
  | gsub(" [0]+(?<n>[1-9])";" " +.n)
  | gsub("(?<![0-9]+)[a-z\\s]+ ch";"Chapter";"x")
  ;

def format_text:
  split("[\\n]+";"x")
  # | map(select(test("[a-zA-Z]")) | gsub("^[\\t\\s]+";"";"x"))
  | map(select(test("[a-zA-Z]")))
  | join("\n")
  | gsub("[ ]{2,}";" ";"x")
  # | gsub("\\s\\n(?<x>[a-xA-Z])"; " "+ .x)
  | gsub("[\\n]{2,}";"\n\n";"x")
  # | gsub("(?<f>[a-z])\\n(?<s>[a-z])";.f + " " + .s;"x")
  ;


def format_paragraph:
  # unsmart| 
  gsub("[ ]{2,}"; " ";"x")
  | gsub("[\\n]+","  \\n";"x")
  | gsub("(?<a>[^\\n]{60,72}) "; .a + "\n")
;

def format_paragraph($txt): $txt| format_paragraph;



def wrap_text($text;$id):
  $text
  | gsub("[\\s\\t]{2,}"; " ";"x")
  | unsmart
  | split("[\\n]+";"x")
  | map("\(.)  ")
  | join("\n")
  | gsub("(?<a>[^\\n]{60,72})[\\s](?<b>[a-zA-Z])"; "" + .a + "\n" + .b; "x")
  | split("[\\n]+";"x")
  | (.[0]|tostring) as $first 
  | (.[1:]|map(select(test("[^\\s\\t\\n]"))|"   \(.)")) as $last
  | [ "","*  \($first)", $last, "   [](#\($id))", "" ]
  | flatten(2)
  | join("\n");


def markdown_tmpl:
  [
    "---",
    "title: \(if (.title|test(":")) then dquote(.title) else (.title) end)",
    "author: \(.author)",
    "asset_id: \(.assetid)",
    "date: \(.creationDate)",
    "modified: \(.modifiedDate)",
    "category: \(.tags)",
    "tags: [\(.tags)]",
    "count: \(.count)",
    "---",
    "",
    "# \(.title)",
    "",
    "by \(.author)",
    "",
    ([.text]|flatten|join("\n")),
    ""
  ]
  | join ("\n")
  ;

def get_chapter:
  . | (
  if ((.ZFUTUREPROOFING5|length)>0)
  then .ZFUTUREPROOFING5
  else chaptername(.ZANNOTATIONLOCATION)
  end);

def get_chapter($o): $o|get_chapter;

def rechapter:
  ( if ((.ZFUTUREPROOFING5|length)>0) then "\(.ZFUTUREPROOFING5)"
    elif (.ZANNOTATIONLOCATION|test("[Cc][ hapter]+";"x")) then
    "\(get_chapter)"
    else ""
    end
  );

def rechapter($s): $s|rechapter;

def group_by_chapter:
   sort_by(.booklocation)
  | group_by(.ZPLLOCATIONRANGESTART)
  | map([
    (group_by(.chapter)
      | to_entries
      | map(
        .key as $k |
        .value | (
          [.[0].chapter,"",(map(wrap_text(.ZANNOTATIONSELECTEDTEXT;.Z_PK))|join("\n\n")),""]
          | map(select(length>0))
          | join("\n")
        )
      )
    )
  ])
  | flatten(2)
  | join("\n")
  ;

def bookcontent:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10)  | . +
    {
      booklocation: epublocation(.ZANNOTATIONLOCATION),
      chapter: rechapter(.)
    }
  )
  | group_by(.ZASSETID)
  | map({
      assetid: .[0].ZASSETID,
      title: (.[0].ZTITLE|gsub("\"";"") | gsub("\\([^0-9]+\\)"; "";"x")),
      author: .[0].ZAUTHOR,
      creationDate: min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      modifiedDate: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      tags: get_tags(.[0].ZGENRE),
      slug: "\(get_author_slug(.[0].ZSORTAUTHOR))-\(slugify((.[0].ZTITLE|gsub("[^\\w\\s\\d]+";"";"x"))))",
      text: group_by_chapter|split("\n"),
      count: length
    });

def booksplit: bookcontent;

def build:
  bookcontent
  | map(
    @sh "echo \( markdown_tmpl )" + " | cat -s > \(env.OUTDIR//"__test__")/\(.slug).md"
  )
  | join("\n\n");

def build_eval:
  bookcontent
  | map(
    @sh "echo \( markdown_tmpl )" + " | cat -s > \(env.OUTDIR//"__test__")/\(.slug).md"
  )
  | join("\n\n");

def create_tag_markdown:
  map({
    title: .,
    content: ([
      "---",
      "title: \"#\(.)\"",
      "tags: \(.)",
      "layout: tag",
      "---"
    ] | join("\n"))
  })
  | map(@sh "echo -e \(.content) >"+ "_tags/\(.title).md")
  | join("\n\n");
  
# def group_by_date