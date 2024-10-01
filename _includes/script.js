const $ = query => document.querySelector(query)
const $$ = query => Array.from(document.querySelectorAll(query))

{% include scripts/theme.js %}
{% include scripts/book.js %}

window.addEventListener("load", function () {
  if (localStorage.getItem('theme')) {
    setTheme(localStorage.getItem('theme'))
  }
})