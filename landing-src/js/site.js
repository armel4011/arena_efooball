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

  /* ---------- vidéo YouTube INTÉGRÉE + piste audio selon la langue ---------- */
  // La vidéo se lit DANS le site (lecteur embarqué). Via l'API IFrame Player,
  // on SÉLECTIONNE explicitement la piste audio doublée correspondant à la
  // langue du site : FR → piste française, EN/ES/PT → piste anglaise (les 2
  // seules pistes disponibles). On re-sélectionne au changement de langue.
  var ytPlayer = null;

  // Langue du site → code de piste audio à cibler (seules FR et EN existent).
  function audioLangFor(lang) { return lang === 'fr' ? 'fr' : 'en'; }

  // Sélectionne la piste audio du lecteur pour la langue voulue. Les méthodes
  // getAvailableAudioTracks / setAudioTrack ne sont pas documentées mais sont
  // celles utilisées par le lecteur pour le multi-audio → tout est en try/catch.
  function selectAudioTrack(player, lang) {
    try {
      if (!player || !player.getAvailableAudioTracks) return;
      var tracks = player.getAvailableAudioTracks();
      if (!tracks || !tracks.length) return;
      var want = audioLangFor(lang);
      var chosen = null;
      for (var i = 0; i < tracks.length; i++) {
        var t = tracks[i] || {};
        var code = String(t.id || t.languageCode || t.name || '').toLowerCase();
        if (code === want || code.indexOf(want + '.') === 0 ||
            code.indexOf(want + '-') === 0 || code.indexOf(want) === 0) {
          chosen = t; break;
        }
      }
      if (chosen && player.setAudioTrack) player.setAudioTrack(chosen);
    } catch (e) {/* API interne indisponible : on garde la piste par défaut */}
  }

  function createPlayer(wrap, id) {
    var host = document.createElement('div');
    wrap.appendChild(host);
    var lang = window.__arenaLang || 'fr';
    ytPlayer = new YT.Player(host, {
      width: '100%', height: '100%', videoId: id,
      host: 'https://www.youtube-nocookie.com',
      playerVars: { rel: 0, modestbranding: 1, playsinline: 1, hl: lang, cc_lang_pref: lang },
      events: {
        onReady: function (e) { selectAudioTrack(e.target, window.__arenaLang || 'fr'); },
        onStateChange: function (e) {
          // À la 1re lecture, les pistes sont sûrement chargées → on (re)cible.
          if (e.data === 1) selectAudioTrack(e.target, window.__arenaLang || 'fr');
        }
      }
    });
  }

  function setupVideo() {
    var wrap = document.getElementById('videoWrap');
    if (!wrap) return;
    var id = wrap.getAttribute('data-video-id');
    if (!id || id === 'PLACEHOLDER_VIDEO_ID') return; // en attente du vrai lien
    var facade = document.getElementById('videoFacade');
    if (facade) facade.remove();
    wrap.style.cursor = 'default';
    if (window.YT && window.YT.Player) { createPlayer(wrap, id); return; }
    // Charge l'API IFrame une seule fois puis crée le lecteur.
    var prev = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = function () {
      if (typeof prev === 'function') { try { prev(); } catch (e) {} }
      createPlayer(wrap, id);
    };
    if (!document.getElementById('yt-iframe-api')) {
      var s = document.createElement('script');
      s.id = 'yt-iframe-api';
      s.src = 'https://www.youtube.com/iframe_api';
      document.head.appendChild(s);
    }
  }

  // Changement de langue du site → bascule la piste audio du lecteur.
  function refreshVideoLang() {
    if (ytPlayer) selectAudioTrack(ytPlayer, window.__arenaLang || 'fr');
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
