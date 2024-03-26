---
title: what i'm reading
layout: default
---
{% assign books_by_date = site.data.books | sort: 'created' |reverse | group_by_exp: "item", "item.created | date: '%b %Y'" -%}
<section class="books">
<table style="--gap:.25rem">
{%- for books in books_by_date %}
{%- assign list = books.items | sort: 'created' |reverse %}
<tr class="header">
  <th data-level="1"><h2 id="{{books.name| slugify: 'latin'}}">{{books.name| replace: "-", " " |capitalize}}</h2></th>
  <td></td>
</tr>
{%- for book in list %}
{%- assign statcount = site.data.stats.bookmarks_per_month[books.name]  %}
<tr data-genre="{{book.tags}}" data-created="{{book.created}}" data-author="{{book.author}}" data-count="{{book.count}}">
  <th scope="col" data-level="2" class="padded">
    <div><time>{{book.created|date: '%F'}}</time></div><div class="small normal"><a href="{{book.tags}}"></a></div>
  </th>
  <td class="padded">
    <a href="./{{book.tags}}/{{book.slug}}.html"><strong>{{book.title}}</strong></a><br><label>{{book.author}} &bull; {{book.count}}</label>
  </td>
</tr>
{%- endfor %}
<tr>
  <td></td>
  <td>
    <div class="flex muted gap" style="--gap:.5rem">
      <span>started <mark><strong>{{list.size}}</strong>&nbsp;book{% if list.size > 1 %}s{%- endif -%}</mark></span>
      <span>&sol;</span>
      <span>created <mark><strong>{{statcount}}</strong>&nbsp;bookmark{% if statcount > 1 %}s{%- endif -%}</mark></span>
    </div>
  </td>
</tr>
<tr><td colspan="2"><br></td></tr>
{%- endfor -%}
</table>
</section>
