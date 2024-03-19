---
title: Home
layout: default
---
{% assign books_by_date = site.data.books | sort: 'created' |reverse | group_by_exp: "item", "item.created | date: '%b %Y'" -%}
<section class="books">
  <table style="--gap:.25rem">
  {%- for books in books_by_date %}
  {%- assign list = books.items | sort: 'created' |reverse %}
    <tr class="header">
      <td colspan="2"><h2 id="{{books.name}}"><a href="{{books.name}}">{{books.name| replace: "-", " " |capitalize}}</a></h2></td>
    </tr>
    {%- for book in list %}
    <tr>
      <th width="15%">{{book.created|date: '%F'}}</th>
      <td class="flex col gap">
        <strong><a href="{{site.baseurl}}/{{book.tags}}/{{book.slug}}.html">{{book.title}}</a></strong>
        <label>
          <span data-label="author">{{book.author}}</span> &bull; 
          <span data-label="tag">{{book.tags}}</span> &bull; 
          <span data-label="count">{{book.count}}</span>
        </label>
      </td>
    </tr>
    {%- endfor %}
  {%- endfor -%}
  </table>
</section>
