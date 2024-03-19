---
title: Home
layout: default
---
{% assign books_by_genre = site.data.books | group_by: "tags" | sort: 'name' -%}
<section class="books">
  <table style="--gap:.25rem">
  {%- for books in books_by_genre %}
  {%- assign list = books.items | sort: 'created' |reverse %}
    <tr class="header">
      <td colspan="2"><h2 id="{{books.name}}"><a href="{{books.name}}">{{books.name| replace: "-", " " |capitalize}}</a></h2></td>
    </tr>
    {%- for book in list %}
    <tr>
      <th width="15%"><date>{{book.created| date: "%b %d %Y"|upcase}}</date></th>
      <td width="" class="flex col gap"><strong><a href="{{site.baseurl}}/{{book.tags}}/{{book.slug }}.html">{{book.title}}</a></strong><label><span data-label="author">{{book.author}}</span> &bull; <span data-label="count">{{book.count}}</span></label></td>
    </tr>
    {%- endfor %}
  {%- endfor -%}
  </table>
</section>
