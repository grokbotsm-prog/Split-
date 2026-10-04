"use strict";

// Money is integer cents. The tip is rounded once, half a cent up,
// then the total is split so the shares differ by at most one cent
// and add back to the total.

function stripLeadingZeros(digits) {
  return digits.replace(/^0+(?=\d)/, "");
}

function sanitizeMoney(raw) {
  let value = String(raw).replace(/[$€£¥\s]/g, "");
  const lastComma = value.lastIndexOf(",");
  const lastDot = value.lastIndexOf(".");

  if (lastComma !== -1 && lastDot !== -1) {
    if (lastComma > lastDot) value = value.replace(/\./g, "").replace(",", ".");
    else value = value.replace(/,/g, "");
  } else if (lastComma !== -1) {
    if (/^\d{1,3}(,\d{3})+$/.test(value)) value = value.replace(/,/g, "");
    else value = value.replace(",", ".");
  }

  value = value.replace(/[^\d.]/g, "");
  const dot = value.indexOf(".");
  if (dot === -1) return stripLeadingZeros(value).slice(0, 6);

  const whole = stripLeadingZeros(value.slice(0, dot).replace(/\./g, "")).slice(0, 6);
  const frac = value.slice(dot + 1).replace(/\./g, "").slice(0, 2);
  return (whole === "" ? "0" : whole) + "." + frac;
}

function sanitizePercent(raw) {
  const value = String(raw).replace(/,/g, ".").replace(/[^\d.]/g, "");
  const dot = value.indexOf(".");
  let whole;
  let frac = "";
  let hasDot = false;

  if (dot !== -1) {
    hasDot = true;
    whole = value.slice(0, dot).replace(/\./g, "");
    frac = value.slice(dot + 1).replace(/\./g, "").slice(0, 2);
  } else {
    whole = value;
  }

  whole = stripLeadingZeros(whole).slice(0, 3);
  if (whole === "" && !hasDot) return "";
  if (whole === "") whole = "0";
  if (Number(whole) >= 100) return "100";
  if (Number(whole + "." + (frac || "0")) > 100) return "100";
  return hasDot ? whole + "." + frac : whole;
}

function moneyToCents(str) {
  if (!str || str === ".") return 0;
  const parts = String(str).split(".");
  const dollars = parseInt(parts[0] || "0", 10) || 0;
  const cents = parseInt((parts[1] || "").padEnd(2, "0").slice(0, 2), 10) || 0;
  return dollars * 100 + cents;
}

// Basis points: 18% = 1800, 18.5% = 1850, 18.25% = 1825.
function percentToBps(str) {
  if (!str || str === ".") return 0;
  const parts = String(str).split(".");
  const whole = parseInt(parts[0] || "0", 10) || 0;
  const frac = parseInt((parts[1] || "").padEnd(2, "0").slice(0, 2), 10) || 0;
  return Math.min(10000, whole * 100 + frac);
}

function tipCents(billCents, bps) {
  return Math.floor((billCents * bps + 5000) / 10000);
}

function clampPeople(people) {
  const value = Math.floor(Number(people));
  if (!Number.isFinite(value) || value < 1) return 1;
  return Math.min(99, value);
}

function splitCents(totalCents, people) {
  const count = clampPeople(people);
  const base = Math.floor(totalCents / count);
  const extra = totalCents % count;
  const shares = [];
  for (let i = 0; i < count; i += 1) shares.push(i < extra ? base + 1 : base);
  return shares;
}

function formatCents(cents) {
  const negative = cents < 0;
  const abs = Math.abs(cents);
  const dollars = Math.floor(abs / 100);
  const frac = abs % 100;
  const body = String(dollars).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return (negative ? "-$" : "$") + body + "." + String(frac).padStart(2, "0");
}

function formatPercent(bps) {
  const whole = Math.floor(bps / 100);
  const frac = bps % 100;
  if (frac === 0) return whole + "%";
  if (frac % 10 === 0) return whole + "." + frac / 10 + "%";
  return whole + "." + String(frac).padStart(2, "0") + "%";
}

function calculate(billRaw, tipRaw, people) {
  const billStr = sanitizeMoney(billRaw);
  const tipStr = sanitizePercent(tipRaw);
  const count = clampPeople(people);
  const bill = moneyToCents(billStr);
  const bps = percentToBps(tipStr);
  const tip = tipCents(bill, bps);
  const total = bill + tip;
  const shares = splitCents(total, count);
  return {
    billCents: bill,
    bps: bps,
    tipCents: tip,
    totalCents: total,
    people: count,
    shares: shares
  };
}

var SplitMath = {
  sanitizeMoney: sanitizeMoney,
  sanitizePercent: sanitizePercent,
  moneyToCents: moneyToCents,
  percentToBps: percentToBps,
  tipCents: tipCents,
  splitCents: splitCents,
  formatCents: formatCents,
  formatPercent: formatPercent,
  calculate: calculate
};

if (typeof module !== "undefined" && module.exports) module.exports = SplitMath;

function initSplitPage() {
  const billInput = document.getElementById("bill");
  const tipInput = document.getElementById("tip");
  const peopleInput = document.getElementById("people");
  const fewer = document.getElementById("fewer");
  const more = document.getElementById("more");
  const sharesEl = document.getElementById("shares");
  const tipLabel = document.getElementById("tip-label");
  const tipOut = document.getElementById("tip-out");
  const totalOut = document.getElementById("total-out");
  const presets = Array.prototype.slice.call(document.querySelectorAll("[data-tip]"));
  const form = document.getElementById("check");
  let people = 2;

  function readPeople() {
    const value = parseInt(peopleInput.value, 10);
    if (!Number.isInteger(value) || value < 1) return null;
    return Math.min(99, value);
  }

  function assignIfChanged(input, next) {
    if (input.value === next) return;
    const start = input.selectionStart;
    const delta = input.value.length - next.length;
    input.value = next;
    if (start != null && typeof input.setSelectionRange === "function") {
      const pos = Math.max(0, start - Math.max(0, delta));
      input.setSelectionRange(pos, pos);
    }
  }

  function fitAmount(el) {
    el.classList.remove("mid", "long");
    if (el.scrollWidth > el.clientWidth + 1) el.classList.add("mid");
    if (el.scrollWidth > el.clientWidth + 1) {
      el.classList.remove("mid");
      el.classList.add("long");
    }
  }

  function fitAmounts() {
    const nodes = sharesEl.querySelectorAll(".hero, .amt");
    for (let i = 0; i < nodes.length; i += 1) fitAmount(nodes[i]);
  }

  function shareRow(count, cents) {
    const row = document.createElement("div");
    row.className = "share-row";
    const who = document.createElement("span");
    who.className = "who";
    who.textContent = count === 1 ? "1 person" : count + " people";
    const amt = document.createElement("span");
    amt.className = "amt";
    amt.textContent = formatCents(cents);
    row.appendChild(who);
    row.appendChild(amt);
    return row;
  }

  function render(result) {
    const shares = result.shares;
    const first = shares[0];
    const even = shares.every(function (cents) { return cents === first; });
    sharesEl.textContent = "";

    const kicker = document.createElement("p");
    kicker.className = "kicker";
    kicker.textContent = "What each person pays";
    sharesEl.appendChild(kicker);

    if (even) {
      const hero = document.createElement("p");
      hero.className = "hero";
      hero.textContent = formatCents(first);
      const note = document.createElement("p");
      note.className = "note";
      const who = shares.length === 1 ? "One person" : "All " + shares.length + " people";
      note.textContent = result.tipCents > 0 ? who + ", tip included" : who;
      sharesEl.appendChild(hero);
      sharesEl.appendChild(note);
    } else {
      const higher = shares[0];
      const lower = shares[shares.length - 1];
      let higherCount = 0;
      for (let i = 0; i < shares.length; i += 1) if (shares[i] === higher) higherCount += 1;
      sharesEl.appendChild(shareRow(higherCount, higher));
      sharesEl.appendChild(shareRow(shares.length - higherCount, lower));
      const note = document.createElement("p");
      note.className = "note";
      const sum = shares.reduce(function (total, cents) { return total + cents; }, 0);
      note.textContent = (result.tipCents > 0 ? "Tip included. " : "") +
        "Shares add up to " + formatCents(sum) + ".";
      sharesEl.appendChild(note);
    }

    tipLabel.textContent = "Tip " + formatPercent(result.bps);
    tipOut.textContent = formatCents(result.tipCents);
    totalOut.textContent = formatCents(result.totalCents);

    presets.forEach(function (button) {
      const match = tipInput.value !== "" && percentToBps(button.getAttribute("data-tip")) === result.bps;
      button.setAttribute("aria-pressed", match ? "true" : "false");
    });

    const shown = readPeople() == null ? people : readPeople();
    fewer.disabled = shown <= 1;
    more.disabled = shown >= 99;
    fitAmounts();
  }

  function update() {
    const count = readPeople();
    if (count != null) people = count;
    render(calculate(billInput.value, tipInput.value, people));
  }

  function setPeople(next) {
    people = clampPeople(next);
    peopleInput.value = String(people);
    update();
  }

  billInput.addEventListener("input", function () {
    assignIfChanged(billInput, sanitizeMoney(billInput.value));
    update();
  });

  tipInput.addEventListener("input", function () {
    assignIfChanged(tipInput, sanitizePercent(tipInput.value));
    update();
  });

  peopleInput.addEventListener("input", function () {
    let digits = peopleInput.value.replace(/\D/g, "").slice(0, 2);
    if (digits.length > 1) digits = digits.replace(/^0+/, "");
    assignIfChanged(peopleInput, digits);
    if (digits === "0") {
      setPeople(1);
      return;
    }
    update();
  });

  billInput.addEventListener("blur", function () {
    if (billInput.value === "" || billInput.value === ".") return;
    billInput.value = formatCents(moneyToCents(sanitizeMoney(billInput.value))).replace(/[$,]/g, "");
    update();
  });

  tipInput.addEventListener("blur", function () {
    let next = sanitizePercent(tipInput.value);
    if (next === "" || next === ".") next = "0";
    else if (next.charAt(next.length - 1) === ".") next = next.slice(0, -1);
    if (next.indexOf(".") !== -1) next = next.replace(/0+$/, "").replace(/\.$/, "");
    if (next === "") next = "0";
    tipInput.value = next;
    update();
  });

  peopleInput.addEventListener("blur", function () {
    peopleInput.value = String(people);
    update();
  });

  peopleInput.addEventListener("keydown", function (event) {
    if (event.key === "ArrowUp") {
      event.preventDefault();
      setPeople(people + 1);
    } else if (event.key === "ArrowDown") {
      event.preventDefault();
      setPeople(people - 1);
    }
  });

  function selectOnFocus(input) {
    input.addEventListener("focus", function () {
      setTimeout(function () { input.select(); }, 0);
    });
  }

  selectOnFocus(billInput);
  selectOnFocus(tipInput);
  selectOnFocus(peopleInput);

  presets.forEach(function (button) {
    button.addEventListener("click", function () {
      tipInput.value = button.getAttribute("data-tip");
      update();
    });
  });

  fewer.addEventListener("click", function () { setPeople(people - 1); });
  more.addEventListener("click", function () { setPeople(people + 1); });

  Array.prototype.forEach.call(document.querySelectorAll(".money, .percent"), function (wrap) {
    wrap.addEventListener("click", function () {
      const input = wrap.querySelector("input");
      if (input && document.activeElement !== input) input.focus();
    });
  });

  form.addEventListener("submit", function (event) { event.preventDefault(); });

  window.addEventListener("resize", fitAmounts);
  update();
}

if (typeof document !== "undefined") initSplitPage();
