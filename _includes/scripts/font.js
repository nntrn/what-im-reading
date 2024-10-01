function setFont(font) {
  const selectEl = $(`#fontselect [name=${font}]`)
  const sitefont = selectEl.value
  selectEl.selected = true
  $("body").style.setProperty("--body-font", sitefont)
  $("html").style.fontSize = selectEl.getAttribute("size")
}

function changeBodyFont(ev) {
  const fontname = $("#fontselect").selectedOptions[0].getAttribute("name")
  setFont(fontname)
  localStorage.setItem("font", fontname)
}
