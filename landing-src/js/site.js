// Site Arena — interactions sans framework.
(function () {
  // 1) Reveal au scroll (éléments marqués data-reveal).
  var els = document.querySelectorAll('[data-reveal]');
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { rootMargin: '0px 0px -10% 0px' });
    els.forEach(function (el) { io.observe(el); });
  } else {
    els.forEach(function (el) { el.classList.add('in'); });
  }

  // 2) Boutons "Lire la vidéo" : lance la vidéo et masque l'overlay.
  document.querySelectorAll('button[aria-label="Lire la vidéo"]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var v = btn.parentElement.querySelector('video');
      if (!v) return;
      v.setAttribute('controls', '');
      v.play();
      btn.style.display = 'none';
    });
  });
})();
