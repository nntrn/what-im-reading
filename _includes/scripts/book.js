function highlightAnnotation() {
  if (Number(location.hash.substr(1,))) {
    Array.from(document.querySelectorAll('.mark')).forEach(e => e.classList.remove('mark'))
    document.querySelector(`[id="${location.hash.slice(1,)}"]`).classList.add('mark')
  }
}
highlightAnnotation()
window.onhashchange = highlightAnnotation;