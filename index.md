---
title: Home
layout: default
---
{% assign books_by_date = site.data.books | sort: 'created' |reverse | group_by_exp: "item", "item.created | date: '%b %Y'" -%}
<section class="books">
  <table style="--gap:.25rem">
  {%- for books in books_by_date %}
  {% assign count = 0 %}
  {%- assign list = books.items | sort: 'created' |reverse %}
    <tr class="header">
      <th><h2 id="{{books.name}}">{{books.name| replace: "-", " " |capitalize}}</h2></th>
      <td></td>
    </tr>
    {%- for book in list %}
    {% assign count = count | plus: book.count %}
    <tr>
      <th width="15%"><div class="flex col">
        <time>{{book.created|date: '%F'}}</time>
        <small class="fw-500" data-label="tag">{{book.tags}}</small>
      </div></th>
      <td class="flex col">
        <strong><a href="{{site.baseurl}}/{{book.tags}}/{{book.slug}}.html">{{book.title}}</a></strong>
        <label>
          <span data-label="author">{{book.author}}</span> &bull; 
          <span data-label="count">{{book.count}}</span>
        </label>
      </td>
    </tr>
    {%- endfor %}
    <tr><td colspan="2"></td></tr>
    <tr>
      <th></th>
      <td class="flex"><strong>Total:</strong>&nbsp;{{list.size}} books, {{count}} bookmarks</td>
    </tr>
    <tr><td colspan="2"></td></tr>
  {%- endfor -%}
  </table>
</section>
