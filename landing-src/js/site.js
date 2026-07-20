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

  // 3) Téléchargement plus rapide — détecte l'appareil et pousse d'un clic le
  //    plus PETIT build compatible (évite le .apk universel de 255 Mo pris par
  //    défaut « au cas où »). Amélioration progressive : sans JS, le bandeau
  //    statique et la carte « Recommandé » guident déjà correctement.
  var reco = document.getElementById('dl-reco');
  if (reco) {
    var BASE = 'mx-auto mt-8 flex max-w-2xl flex-wrap items-center justify-between gap-3 rounded-xl border px-5 py-3.5 text-sm ';
    var ARROW = '<svg fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" class="h-4 w-4"><path d="M12 3v12"></path><path d="m7 11 5 5 5-5"></path><path d="M4 21h16"></path></svg>';
    var BUILD = {
      moderne: { href: '/downloads/arena-android-moderne.apk', size: '92 Mo' },
      ancien: { href: '/downloads/arena-android-ancien.apk', size: '72 Mo' }
    };
    var show = function (key, msg, ok) {
      reco.className = BASE + (ok
        ? 'border-signal/40 bg-signal/10 text-white'
        : 'border-white/10 bg-white/[0.03] text-silver');
      var dot = '<span class="h-2 w-2 shrink-0 rounded-full ' + (ok ? 'bg-signal' : 'bg-silver') + '"></span>';
      var btn = (ok && BUILD[key])
        ? '<a href="' + BUILD[key].href + '" download class="flex shrink-0 items-center justify-center gap-2 rounded-full bg-signal px-5 py-3 font-semibold text-void transition-transform hover:scale-105">' + ARROW + 'Télécharger (' + BUILD[key].size + ')</a>'
        : '';
      reco.innerHTML = '<span class="flex items-center gap-2.5">' + dot + '<span>' + msg + '</span></span>' + btn;
    };
    var decide = function (bitness) {
      if (!/Android/i.test(navigator.userAgent || '')) {
        show(null, 'Ouvre cette page depuis ton téléphone Android : le bon build se télécharge en un clic.', false);
        return;
      }
      if (bitness === '32') {
        show('ancien', 'Détecté : appareil 32 bits. Voici le build adapté — le plus léger.', true);
      } else {
        show('moderne', 'Détecté : téléphone 64 bits. Build recommandé — le plus léger et rapide à installer.', true);
      }
    };
    // API moderne (Chrome/Android) : bitness fiable "32" / "64".
    if (navigator.userAgentData && navigator.userAgentData.getHighEntropyValues) {
      navigator.userAgentData.getHighEntropyValues(['bitness'])
        .then(function (d) { decide(d.bitness); })
        .catch(function () { decide(''); });
    } else {
      // Repli : indices d'ABI 32 bits dans l'user-agent, sinon on suppose 64 bits.
      var ua = navigator.userAgent || '';
      var is32 = /(armv7|armeabi)/i.test(ua) && !/(arm64|aarch64|x86_64|wow64|win64)/i.test(ua);
      decide(is32 ? '32' : '');
    }
  }
})();
