// Home page behavior: allergy chips, the summary line, the search button's
// enabled state, and getting the user's location before a search.
(function () {
  "use strict";

  var form = document.getElementById("preferences-form");
  if (!form) {
    return;
  }

  var hidden = document.getElementById("allergies");
  var chips = document.getElementById("allergy-chips");
  var addInput = document.getElementById("allergy-input");
  var addButton = document.getElementById("allergy-add");
  var summary = document.getElementById("summary");
  var searchButton = document.getElementById("search-restaurants-btn");
  var checkButton = document.getElementById("check-restaurant-btn");
  var locationError = document.getElementById("location-error");
  var macros = Array.prototype.slice.call(form.querySelectorAll("[data-macro]"));
  var halal = form.elements.halal;
  var kosher = form.elements.kosher;

  function capitalize(text) {
    return text.charAt(0).toUpperCase() + text.slice(1);
  }

  function selectedAllergies() {
    return Array.prototype.slice
      .call(chips.querySelectorAll("input[data-allergy]:checked"))
      .map(function (input) { return input.dataset.allergy; });
  }

  function number(input) {
    var value = parseFloat(input.value);
    return isNaN(value) ? null : value;
  }

  function format(value) {
    return Math.abs(value - Math.round(value)) < 0.05 ? String(Math.round(value)) : value.toFixed(1);
  }

  function update() {
    var allergies = selectedAllergies();
    hidden.value = allergies.join(", ");

    var values = {};
    macros.forEach(function (input) { values[input.dataset.macro] = number(input); });
    var otherCount = ["carbs", "fat", "fiber", "sugar"].filter(function (name) {
      return values[name] !== null;
    }).length;
    var any = macros.some(function (input) { return number(input) !== null; }) ||
      halal.checked || kosher.checked || allergies.length > 0;

    var parts = [];
    if (values.calories !== null) { parts.push(format(values.calories) + " cal"); }
    if (values.proteins !== null) { parts.push(format(values.proteins) + " g protein"); }
    if (otherCount > 0) { parts.push("+" + otherCount + (otherCount === 1 ? " target" : " targets")); }
    if (halal.checked) { parts.push("Halal"); }
    if (kosher.checked) { parts.push("Kosher"); }
    if (allergies.length > 0) { parts.push(allergies.length + (allergies.length === 1 ? " allergy" : " allergies")); }

    summary.textContent = any ? parts.join(" · ") : "Add a target or a dietary filter to search.";
    searchButton.disabled = !any;
  }

  function addAllergy(key) {
    key = key.trim().toLowerCase();
    if (!key) {
      return;
    }
    var existing = chips.querySelector('input[data-allergy="' + key.replace(/"/g, "") + '"]');
    if (existing) {
      existing.checked = true;
      return;
    }
    var label = document.createElement("label");
    label.className = "fc-chip";
    var input = document.createElement("input");
    input.type = "checkbox";
    input.checked = true;
    input.dataset.allergy = key;
    var text = document.createElement("span");
    text.textContent = capitalize(key);
    label.appendChild(input);
    label.appendChild(text);
    chips.appendChild(label);
  }

  function addFromInput() {
    addInput.value.split(",").forEach(addAllergy);
    addInput.value = "";
    update();
  }

  addButton.addEventListener("click", addFromInput);
  addInput.addEventListener("keydown", function (event) {
    if (event.key === "Enter") {
      event.preventDefault();
      addFromInput();
    }
  });
  form.addEventListener("change", update);
  form.addEventListener("input", update);

  // Picking a past result fills the name box, so the server gets one name.
  var choice = document.getElementById("restaurant-choice");
  var nameInput = document.getElementById("restaurant-name");
  if (choice && nameInput) {
    choice.addEventListener("change", function () {
      if (choice.value) {
        nameInput.value = choice.value;
      }
    });
  }

  // Location is needed for a search. Ask early so the answer is ready.
  var userLocation = null;

  function requestLocation() {
    return new Promise(function (resolve, reject) {
      if (!navigator.geolocation) {
        reject(new Error("Geolocation is not supported by this browser."));
        return;
      }
      navigator.geolocation.getCurrentPosition(
        function (position) {
          userLocation = { latitude: position.coords.latitude, longitude: position.coords.longitude };
          resolve(userLocation);
        },
        reject,
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
      );
    });
  }

  requestLocation().catch(function () {});

  function fillLocation() {
    if (userLocation) {
      document.getElementById("latitude").value = userLocation.latitude;
      document.getElementById("longitude").value = userLocation.longitude;
    }
  }

  form.addEventListener("submit", function (event) {
    var submitter = event.submitter;
    if (submitter === checkButton) {
      var hasName = (nameInput && nameInput.value.trim()) || (choice && choice.value);
      if (!hasName) {
        event.preventDefault();
        nameInput.focus();
        nameInput.scrollIntoView({ block: "center", behavior: "smooth" });
        return;
      }
      fillLocation();
      return;
    }

    if (userLocation) {
      fillLocation();
      return;
    }

    // No location yet: ask now, then submit by hand.
    event.preventDefault();
    locationError.hidden = true;
    requestLocation().then(function () {
      fillLocation();
      form.action = searchButton.getAttribute("formaction");
      if (window.fwShowLoading) {
        window.fwShowLoading("search");
      }
      form.submit();
    }).catch(function () {
      locationError.hidden = false;
      locationError.scrollIntoView({ block: "center", behavior: "smooth" });
    });
  });

  update();
})();
