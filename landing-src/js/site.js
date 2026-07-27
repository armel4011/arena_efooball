// ARENA — interactions du site (sans framework).
//  1) i18n : traduit les nœuds de texte vers la langue choisie (auto = langue
//     du navigateur, repli FR). Le HTML garde le design d'origine.
//  2) sélecteur de langue.
//  3) reveal au scroll (data-reveal).
//  4) téléchargement plus rapide : détection d'appareil (build le plus léger).
//  5) vidéo d'installation : une vidéo par langue, lue DANS le site.
(function () {
  'use strict';
  var SUPPORTED = ['fr', 'en', 'es', 'pt'];
  var STORE = 'arena_lang';
  var MAP = window.I18N_MAP || { en: {}, es: {}, pt: {} };

  /* ---------- i18n : traduction des nœuds de texte ---------- */
  var nodes = []; // { node, fr, lead, trail }

  function collect() {
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: function (n) {
        var p = n.parentNode;
        while (p && p.nodeName) {
          var t = p.nodeName.toUpperCase();
          if (t === 'SCRIPT' || t === 'STYLE' || t === 'NOSCRIPT') return NodeFilter.FILTER_REJECT;
          p = p.parentNode;
        }
        return n.nodeValue && n.nodeValue.trim() ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
      }
    });
    var n;
    while ((n = walker.nextNode())) {
      var v = n.nodeValue;
      var lead = (v.match(/^\s*/) || [''])[0];
      var trail = (v.match(/\s*$/) || [''])[0];
      var fr = v.trim().replace(/\s+/g, ' ');
      nodes.push({ node: n, fr: fr, lead: lead, trail: trail });
    }
  }

  function translate(lang) {
    var dict = (lang === 'fr') ? null : (MAP[lang] || {});
    for (var i = 0; i < nodes.length; i++) {
      var e = nodes[i];
      var txt = dict ? (dict[e.fr] != null ? dict[e.fr] : e.fr) : e.fr;
      e.node.nodeValue = e.lead + txt + e.trail;
    }
    document.documentElement.setAttribute('lang', lang);
  }

  function pickLang() {
    try { var s = localStorage.getItem(STORE); if (s && SUPPORTED.indexOf(s) > -1) return s; } catch (e) {}
    var navs = (navigator.languages && navigator.languages.length) ? navigator.languages : [navigator.language || 'fr'];
    for (var i = 0; i < navs.length; i++) {
      var c = String(navs[i]).toLowerCase().split(/[-_]/)[0];
      if (SUPPORTED.indexOf(c) > -1) return c;
    }
    return 'fr';
  }

  function setLang(lang) {
    translate(lang);
    window.__arenaLang = lang;
    try { localStorage.setItem(STORE, lang); } catch (e) {}
    var cur = document.getElementById('langCur');
    var names = { fr: 'Français', en: 'English', es: 'Español', pt: 'Português' };
    if (cur) cur.textContent = names[lang] || lang.toUpperCase();
    refreshVideoLang();
  }

  /* ---------- sélecteur de langue ---------- */
  function setupLangMenu() {
    var btn = document.getElementById('langBtn');
    var menu = document.getElementById('langMenu');
    if (!btn || !menu) return;
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      menu.classList.toggle('hidden');
    });
    document.addEventListener('click', function () { menu.classList.add('hidden'); });
    menu.addEventListener('click', function (e) { e.stopPropagation(); });
    var items = menu.querySelectorAll('[data-set-lang]');
    for (var i = 0; i < items.length; i++) {
      items[i].addEventListener('click', function () { setLang(this.getAttribute('data-set-lang')); menu.classList.add('hidden'); });
    }
  }

  /* ---------- reveal au scroll ---------- */
  function setupReveal() {
    var els = document.querySelectorAll('[data-reveal]');
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
      }, { rootMargin: '0px 0px -10% 0px' });
      els.forEach(function (el) { io.observe(el); });
    } else {
      els.forEach(function (el) { el.classList.add('in'); });
    }
  }

  /* ---------- vidéo d'installation : une vidéo par langue ---------- */
  function videoIdFor(wrap, lang) {
    var id = wrap.getAttribute('data-video-' + lang) ||
      wrap.getAttribute('data-video-fr') || wrap.getAttribute('data-video-en');
    return (!id || id === 'PLACEHOLDER_VIDEO_ID') ? '' : id;
  }
  function buildVideoIframe(id, lang) {
    var src = 'https://www.youtube-nocookie.com/embed/' + encodeURIComponent(id) +
      '?rel=0&modestbranding=1&playsinline=1&hl=' + lang + '&cc_lang_pref=' + lang;
    var ifr = document.createElement('iframe');
    ifr.setAttribute('src', src);
    ifr.setAttribute('title', 'ARENA');
    ifr.setAttribute('loading', 'lazy');
    ifr.className = 'absolute inset-0 h-full w-full';
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
    if (!id) return;
    wrap.appendChild(buildVideoIframe(id, lang));
  }
  function refreshVideoLang() {
    var wrap = document.getElementById('videoWrap');
    if (!wrap) return;
    var lang = window.__arenaLang || 'fr';
    var id = videoIdFor(wrap, lang);
    if (!id) return;
    var old = wrap.querySelector('iframe');
    if (!old) { wrap.appendChild(buildVideoIframe(id, lang)); return; }
    if (old.getAttribute('data-vid') === id) return;
    wrap.replaceChild(buildVideoIframe(id, lang), old);
  }

  /* ---------- téléchargement plus rapide (détection d'appareil) ---------- */
  function setupDownload() {
    var reco = document.getElementById('dl-reco');
    if (!reco) return;
    var BASE = 'mx-auto mt-8 flex max-w-2xl flex-wrap items-center justify-between gap-3 rounded-xl border px-5 py-3.5 text-sm ';
    var ARROW = '<svg fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" class="h-4 w-4"><path d="M12 3v12"></path><path d="m7 11 5 5 5-5"></path><path d="M4 21h16"></path></svg>';
    var BUILD = {
      moderne: { href: '/downloads/arena-android-moderne.apk', size: '92 Mo' },
      ancien: { href: '/downloads/arena-android-ancien.apk', size: '72 Mo' }
    };
    // Libellés traduits selon la langue courante.
    function T(fr) {
      var l = window.__arenaLang || 'fr';
      if (l === 'fr') return fr;
      return (MAP[l] && MAP[l][fr]) || fr;
    }
    var MSG = {
      pc: 'Ouvre cette page depuis ton téléphone Android : le bon build se télécharge en un clic.',
      old: 'Détecté : appareil 32 bits. Voici le build adapté — le plus léger.',
      modern: 'Détecté : téléphone 64 bits. Build recommandé — le plus léger et rapide à installer.',
      dl: 'Télécharger'
    };
    var show = function (key, msgFr, ok) {
      reco.className = BASE + (ok ? 'border-signal/40 bg-signal/10 text-white' : 'border-white/10 bg-white/[0.03] text-silver');
      var dot = '<span class="h-2 w-2 shrink-0 rounded-full ' + (ok ? 'bg-signal' : 'bg-silver') + '"></span>';
      var btn = (ok && BUILD[key])
        ? '<a href="' + BUILD[key].href + '" download class="flex shrink-0 items-center justify-center gap-2 rounded-full bg-signal px-5 py-3 font-semibold text-void transition-transform hover:scale-105">' + ARROW + T(MSG.dl) + ' (' + BUILD[key].size + ')</a>'
        : '';
      reco.innerHTML = '<span class="flex items-center gap-2.5">' + dot + '<span>' + T(msgFr) + '</span></span>' + btn;
    };
    var decide = function (bitness) {
      if (!/Android/i.test(navigator.userAgent || '')) { show(null, MSG.pc, false); return; }
      if (bitness === '32') show('ancien', MSG.old, true);
      else show('moderne', MSG.modern, true);
    };
    if (navigator.userAgentData && navigator.userAgentData.getHighEntropyValues) {
      navigator.userAgentData.getHighEntropyValues(['bitness']).then(function (d) { decide(d.bitness); }).catch(function () { decide(''); });
    } else {
      var ua = navigator.userAgent || '';
      var is32 = /(armv7|armeabi)/i.test(ua) && !/(arm64|aarch64|x86_64|wow64|win64)/i.test(ua);
      decide(is32 ? '32' : '');
    }
  }

  /* ---------- boot ---------- */
  function boot() {
    collect();
    var lang = pickLang();
    window.__arenaLang = lang;
    setLang(lang);
    setupLangMenu();
    setupReveal();
    setupVideo();
    setupDownload();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
