/* ARENA — logique du site vitrine (vanilla, sans framework).
   1) i18n : langue = préférence stockée > langue du navigateur > FR.
   2) reveal au scroll.
   3) détection d'appareil → met en avant le build de téléchargement le plus
      rapide pour ce téléphone.
   4) façade vidéo YouTube : ne charge l'iframe qu'au clic (page plus légère),
      avec `hl` = langue courante → doublage audio auto (pistes fr/en). */
(function () {
  'use strict';
  var SUPPORTED = ['fr', 'en', 'es', 'pt'];
  var STORE_KEY = 'arena_lang';

  /* ---------- i18n ---------- */
  function pickLang() {
    var saved = null;
    try { saved = localStorage.getItem(STORE_KEY); } catch (e) {}
    if (saved && SUPPORTED.indexOf(saved) !== -1) return saved;
    var navs = (navigator.languages && navigator.languages.length)
      ? navigator.languages : [navigator.language || 'fr'];
    for (var i = 0; i < navs.length; i++) {
      var code = String(navs[i]).toLowerCase().split(/[-_]/)[0];
      if (SUPPORTED.indexOf(code) !== -1) return code;
    }
    return 'fr';
  }

  function applyLang(lang) {
    var dict = (window.I18N && window.I18N[lang]) || (window.I18N && window.I18N.fr) || {};
    document.documentElement.setAttribute('lang', lang);
    document.documentElement.setAttribute('data-lang', lang);
    // Texte + attribut content (balise meta description).
    var nodes = document.querySelectorAll('[data-i18n]');
    for (var i = 0; i < nodes.length; i++) {
      var key = nodes[i].getAttribute('data-i18n');
      var val = dict[key];
      if (val == null) continue;
      if (nodes[i].tagName === 'META') nodes[i].setAttribute('content', val);
      else nodes[i].textContent = val;
    }
    var cur = document.getElementById('langCur');
    if (cur) cur.textContent = dict.langName || lang.toUpperCase();
    try { localStorage.setItem(STORE_KEY, lang); } catch (e) {}
    window.__arenaLang = lang;
    // Rafraîchit le badge « Recommandé » traduit sur la carte de téléchargement.
    var recTag = document.querySelector('.dl-card.reco .tag');
    if (recTag) recTag.textContent = dict.dlRecommended || recTag.textContent;
    // Recharge la piste audio doublée de la vidéo pour la nouvelle langue.
    if (window.__arenaRefreshVideo) window.__arenaRefreshVideo();
  }

  function setupLangMenu() {
    var btn = document.getElementById('langBtn');
    var menu = document.getElementById('langMenu');
    if (!btn || !menu) return;
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = menu.classList.toggle('open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    document.addEventListener('click', function () {
      menu.classList.remove('open'); btn.setAttribute('aria-expanded', 'false');
    });
    var items = menu.querySelectorAll('[data-set-lang]');
    for (var i = 0; i < items.length; i++) {
      items[i].addEventListener('click', function () {
        applyLang(this.getAttribute('data-set-lang'));
        menu.classList.remove('open');
      });
    }
  }

  /* ---------- reveal au scroll ---------- */
  function setupReveal() {
    var els = document.querySelectorAll('.reveal');
    if (!('IntersectionObserver' in window)) {
      for (var i = 0; i < els.length; i++) els[i].classList.add('in');
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    for (var j = 0; j < els.length; j++) io.observe(els[j]);
  }

  /* ---------- détection d'appareil (téléchargement rapide) ---------- */
  function recommendedBuild() {
    var ua = navigator.userAgent || '';
    if (!/Android/i.test(ua)) return 'moderne'; // desktop/iOS : défaut moderne
    var m = ua.match(/Android\s+(\d+)/i);
    var major = m ? parseInt(m[1], 10) : 0;
    // Android 9+ (téléphones ~2018+) = arm64 → build « moderne » (léger, rapide).
    // Plus ancien → build « ancien » (arm32).
    return (major && major < 9) ? 'ancien' : 'moderne';
  }

  function setupDownload() {
    var rec = recommendedBuild();
    var recCard = document.getElementById('card-' + rec);
    if (!recCard) return;
    var dict = (window.I18N && window.I18N[window.__arenaLang]) || {};
    // Retire tout style « reco » existant (l'HTML par défaut met moderne).
    var cards = document.querySelectorAll('.dl-card');
    for (var i = 0; i < cards.length; i++) {
      cards[i].classList.remove('reco');
      var tag = cards[i].querySelector('.tag');
      if (tag) tag.remove();
      var b = cards[i].querySelector('.btn');
      if (b) { b.classList.remove('btn-primary'); b.classList.add('btn-ghost'); }
    }
    // Applique « reco » à la carte détectée, en tête, bouton primaire.
    recCard.classList.add('reco');
    var parent = recCard.parentNode;
    if (parent && parent.firstChild !== recCard) parent.insertBefore(recCard, parent.firstChild);
    var tagEl = document.createElement('span');
    tagEl.className = 'tag';
    tagEl.textContent = dict.dlRecommended || 'Recommandé';
    recCard.insertBefore(tagEl, recCard.firstChild);
    var rb = recCard.querySelector('.btn');
    if (rb) { rb.classList.remove('btn-ghost'); rb.classList.add('btn-primary'); }
  }

  /* ---------- vidéo YouTube INTÉGRÉE — UNE VIDÉO PAR LANGUE ---------- */
  // Fiable : UNE vidéo par langue (chacune a son propre audio) — YouTube ne
  // laisse pas forcer une piste audio dans une vidéo unique. Le site joue la
  // vidéo de la langue courante (data-video-<lang>), avec repli fr puis en.
  // On recharge la bonne vidéo au changement de langue.
  function videoIdFor(wrap, lang) {
    var id = wrap.getAttribute('data-video-' + lang) ||
      wrap.getAttribute('data-video-fr') || wrap.getAttribute('data-video-en');
    if (!id || id === 'PLACEHOLDER_VIDEO_ID') return '';
    return id;
  }

  function buildVideoIframe(id, lang) {
    var src = 'https://www.youtube-nocookie.com/embed/' + encodeURIComponent(id) +
      '?rel=0&modestbranding=1&playsinline=1&hl=' + lang + '&cc_lang_pref=' + lang;
    var ifr = document.createElement('iframe');
    ifr.setAttribute('src', src);
    ifr.setAttribute('title', 'ARENA');
    ifr.setAttribute('loading', 'lazy');
    ifr.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share');
    ifr.setAttribute('allowfullscreen', '');
    ifr.setAttribute('data-vid', id);
    return ifr;
  }

  function setupVideo() {
    var wrap = document.getElementById('videoWrap');
    if (!wrap) return;
    var lang = window.__arenaLang || 'fr';
    var id = videoIdFor(wrap, lang);
    if (!id) return; // en attente des vrais liens
    var facade = document.getElementById('videoFacade');
    if (facade) facade.remove();
    wrap.style.cursor = 'default';
    wrap.appendChild(buildVideoIframe(id, lang));
  }

  // Changement de langue → joue la vidéo de la langue (recharge seulement si
  // la vidéo cible change, pour ne pas couper une lecture en cours inutilement).
  function refreshVideoLang() {
    var wrap = document.getElementById('videoWrap');
    if (!wrap) return;
    var lang = window.__arenaLang || 'fr';
    var id = videoIdFor(wrap, lang);
    if (!id) return;
    var old = wrap.querySelector('iframe');
    if (!old) return;
    if (old.getAttribute('data-vid') === id) return; // même vidéo → on garde
    wrap.replaceChild(buildVideoIframe(id, lang), old);
  }
  window.__arenaRefreshVideo = refreshVideoLang;

  /* ---------- boot ---------- */
  function boot() {
    applyLang(pickLang());
    setupLangMenu();
    setupReveal();
    setupDownload();
    setupVideo();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
