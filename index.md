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
      <th data-level="1"><h2 id="{{books.name}}">{{books.name| replace: "-", " " |capitalize}}</h2></th>
      <td></td>
    </tr>
    <tr class="total">
      <td class="padded align-right">started <strong>{{list.size}} books</strong></td>
      <td></td>
    </tr>
    {%- for book in list %}
    {%- assign statcount = site.data.stats.bookmarks_per_month[books.name]  %}
    <tr>
      <th data-level="2" class="padded"><div class="flex col">
        <time data-label="created">{{book.created|date: '%F'}}</time>
        <small data-label="genre" class="fw-500"><a href="{{book.tags}}">{{book.tags}}</a></small>
      </div></th>
      <td class="flex col padded gap">
        <strong><a href="{{site.baseurl}}/{{book.tags}}/{{book.slug}}.html">{{book.title}}</a></strong>
        <label>
          <span data-label="author">{{book.author}}</span> &bull; 
          <span data-label="count">{{book.count}}</span>
        </label>
      </td>
    </tr>
    {%- endfor %}
    <tr class="blank"><td colspan="2"></td></tr>
    <tr class="total">
      <th data-level="2" class="padded"><strong>Summary:</strong></th>
      <td class="padded">... and created <strong>{{statcount}} bookmarks</strong></td>
    </tr>
    <tr><td colspan="2"><br></td></tr>
  {%- endfor -%}
  </table>
</section>
