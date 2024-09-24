function setTheme(theme) {
  const _theme = theme || $("select#theme").value || "monospace"
  $(`select#theme [name="${_theme}"]`).selected = true
  document.body.dataset.layout = _theme
  localStorage.setItem("theme", _theme)
}
