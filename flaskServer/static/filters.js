// Submits the results filter form whenever a control changes, so filtering
// feels instant. Without JavaScript the form shows an Apply button instead.
(function () {
  "use strict";

  var form = document.querySelector("form[data-autosubmit]");
  if (!form) {
    return;
  }
  form.addEventListener("change", function () {
    if (form.requestSubmit) {
      form.requestSubmit();
    } else {
      form.submit();
    }
  });
})();
