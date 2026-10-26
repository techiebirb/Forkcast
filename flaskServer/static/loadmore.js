// Shows results ten at a time. Without JavaScript every card stays visible and
// the Load more button stays hidden.
(function () {
  "use strict";

  var list = document.querySelector("[data-load-more]");
  var wrap = document.querySelector("[data-load-more-button]");
  if (!list || !wrap) {
    return;
  }
  var size = parseInt(list.getAttribute("data-page-size"), 10) || 10;
  var cards = Array.prototype.slice.call(list.children);
  var shown = size;
  var button = wrap.querySelector("button");

  function render() {
    cards.forEach(function (card, index) {
      card.hidden = index >= shown;
    });
    wrap.hidden = shown >= cards.length;
  }

  button.addEventListener("click", function () {
    var first = shown;
    shown += size;
    render();
    var next = cards[first];
    if (next) {
      var target = next.querySelector("button, a");
      if (target) {
        target.focus({ preventScroll: true });
      }
      next.scrollIntoView({ block: "nearest", behavior: "smooth" });
    }
  });

  render();
})();
