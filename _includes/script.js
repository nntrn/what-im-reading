function highlightAnnotation() {
  Array.from(document.querySelectorAll('.mark')).forEach(e => e.classList.remove('mark'))
  if (Number(location.hash.substr(1,))) {
    document.querySelector(`.bookmark a[href="${location.hash}"]`).parentElement.parentElement.classList.add('mark')
  }
}
highlightAnnotation()
window.onhashchange = highlightAnnotation;