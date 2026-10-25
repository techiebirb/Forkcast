// Swaps the page content for a loading view while a slow form (an AI search
// or menu check) submits. A form opts in with data-loading="<kind>", which
// names a <template id="fw-loading-<kind>"> on the page.
(function () {
  "use strict";

  var timer = null;

  function startSteps(root) {
    var steps = root.querySelectorAll(".fa-steps li");
    if (steps.length < 2) {
      return;
    }
    var current = 0;
    function render() {
      steps.forEach(function (li, index) {
        var mark = li.querySelector(".fa-steps__mark");
        li.classList.toggle("is-done", index < current);
        li.classList.toggle("is-current", index === current);
        if (!mark) {
          return;
        }
        if (index < current) {
          mark.innerHTML = '<i class="ph ph-check" aria-hidden="true"></i>';
        } else if (index === current) {
          mark.innerHTML = '<span class="fc-spinner" aria-hidden="true"></span>';
        } else {
          mark.innerHTML = '<span class="fa-steps__dot"></span>';
        }
      });
    }
    render();
    // The steps name what the AI is doing as time passes; there is no
    // progress signal from the server, so no counts are shown.
    timer = window.setInterval(function () {
      if (current < steps.length - 1) {
        current += 1;
        render();
      }
    }, 4000);
  }

  function show(kind) {
    var template = document.getElementById("fw-loading-" + kind);
    var target = document.querySelector("[data-loading-target]");
    if (!template || !target) {
      return;
    }
    target.innerHTML = "";
    target.appendChild(template.content.cloneNode(true));
    target.setAttribute("aria-busy", "true");
    window.scrollTo(0, 0);
    startSteps(target);
  }

  window.fwShowLoading = show;

  document.addEventListener("submit", function (event) {
    var form = event.target;
    if (event.defaultPrevented || !form || !form.dataset) {
      return;
    }
    if (!form.dataset.loading && !(event.submitter && event.submitter.dataset.loading)) {
      return;
    }
    // A submit button can ask for its own loading view (data-loading).
    var submitter = event.submitter;
    var kind = (submitter && submitter.dataset && submitter.dataset.loading) || form.dataset.loading;
    // Let the browser start the submit first: a form that is removed from the
    // page during its own submit event never gets sent.
    window.setTimeout(function () {
      show(kind);
    }, 0);
  });

  window.addEventListener("pageshow", function (event) {
    // Back/forward cache restores the loading view; reload to get real content.
    if (event.persisted && document.querySelector("[aria-busy='true']")) {
      window.location.reload();
    }
  });
})();
