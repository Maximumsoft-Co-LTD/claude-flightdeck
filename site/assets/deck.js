/* claude-flightdeck — interaction layer (vanilla, dependency-free)
   - scroll-reveal (IntersectionObserver)
   - count-up gauges
   - telemetry typing effect
   - mobile nav toggle
   All effects are progressive enhancement; the site is fully readable
   with JS disabled (reveal elements just render statically via CSS fallback
   when this script adds .in, and prefers-reduced-motion short-circuits). */
(function () {
  "use strict";
  var reduce = window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---- nav: solidify on scroll (Tesla-style transparent → frosted) ---- */
  var bar = document.querySelector(".topbar");
  if (bar) {
    var onScroll = function () {
      if (window.scrollY > 24) bar.classList.add("scrolled");
      else bar.classList.remove("scrolled");
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  /* ---- mobile nav ---- */
  var toggle = document.querySelector(".navtoggle");
  var nav = document.querySelector(".nav");
  if (toggle && nav) {
    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    nav.addEventListener("click", function (e) {
      if (e.target.tagName === "A") nav.classList.remove("open");
    });
  }

  /* ---- count-up ---- */
  function countUp(el) {
    var target = parseInt(el.getAttribute("data-count"), 10) || 0;
    if (reduce || target === 0) { el.textContent = String(target); return; }
    var start = null, dur = 1100;
    function step(t) {
      if (start === null) start = t;
      var p = Math.min((t - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = String(Math.round(target * eased));
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  /* ---- reveal on scroll ---- */
  var revealEls = [].slice.call(document.querySelectorAll(".reveal"));
  if (!("IntersectionObserver" in window) || reduce) {
    revealEls.forEach(function (el) { el.classList.add("in"); });
    document.querySelectorAll("[data-count]").forEach(function (el) {
      el.textContent = el.getAttribute("data-count");
    });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        el.classList.add("in");
        el.querySelectorAll("[data-count]").forEach(countUp);
        if (el.hasAttribute("data-count")) countUp(el);
        io.unobserve(el);
      });
    }, { threshold: 0.18, rootMargin: "0px 0px -8% 0px" });
    revealEls.forEach(function (el) { io.observe(el); });
    // count-up gauges sit inside .reveal wrappers; also observe any stray ones
    document.querySelectorAll(".gauge").forEach(function (el) { io.observe(el); });
  }

  /* ---- telemetry typing ---- */
  var tEl = document.querySelector("[data-type]");
  if (tEl) {
    var txt = tEl.getAttribute("data-type");
    if (reduce) { tEl.textContent = txt; }
    else {
      var i = 0;
      (function type() {
        tEl.textContent = txt.slice(0, i);
        if (i++ <= txt.length) setTimeout(type, 26);
      })();
    }
  }
})();
