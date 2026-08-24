// Mika+FileScope — marketing site
// Progressive enhancement only: without JS the first screenshot stays visible,
// the copy button is inert, and every link still works.

(function () {
  'use strict';

  /* ── Nav: hairline appears once the page scrolls ───────────────── */
  var nav = document.getElementById('nav');
  if (nav) {
    var onScroll = function () {
      nav.classList.toggle('is-scrolled', window.scrollY > 8);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ── Screenshot tabs (WAI-ARIA tabs pattern) ───────────────────── */
  var tablist = document.querySelector('[role="tablist"]');
  if (tablist) {
    var tabs = Array.prototype.slice.call(tablist.querySelectorAll('[role="tab"]'));

    var select = function (tab) {
      tabs.forEach(function (t) {
        var selected = t === tab;
        t.setAttribute('aria-selected', String(selected));
        t.tabIndex = selected ? 0 : -1;
        var panel = document.getElementById(t.getAttribute('aria-controls'));
        if (panel) panel.hidden = !selected;
      });
    };

    tabs.forEach(function (tab) {
      tab.addEventListener('click', function () { select(tab); });
    });

    tablist.addEventListener('keydown', function (e) {
      var i = tabs.indexOf(document.activeElement);
      if (i === -1) return;
      var next = null;
      if (e.key === 'ArrowRight') next = tabs[(i + 1) % tabs.length];
      else if (e.key === 'ArrowLeft') next = tabs[(i - 1 + tabs.length) % tabs.length];
      else if (e.key === 'Home') next = tabs[0];
      else if (e.key === 'End') next = tabs[tabs.length - 1];
      if (!next) return;
      e.preventDefault();
      select(next);
      next.focus();
    });
  }

  /* ── Copy button for the build-from-source snippet ─────────────── */
  var copyBtn = document.querySelector('.code__copy');
  if (copyBtn && navigator.clipboard) {
    copyBtn.addEventListener('click', function () {
      navigator.clipboard.writeText(copyBtn.dataset.copy).then(function () {
        var original = copyBtn.textContent;
        copyBtn.textContent = 'Copied';
        copyBtn.classList.add('is-done');
        setTimeout(function () {
          copyBtn.textContent = original;
          copyBtn.classList.remove('is-done');
        }, 1800);
      });
    });
  } else if (copyBtn) {
    copyBtn.hidden = true;
  }
})();
