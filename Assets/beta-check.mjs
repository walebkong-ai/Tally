import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import * as firestore from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";
import { runBetaChecks } from "./beta-checks.mjs?v=1";
const app = initializeApp({
  projectId: "solvry-walebkong",
  appId: "1:32814860247:web:c6734f8601d709d64e6d92",
  storageBucket: "solvry-walebkong.firebasestorage.app",
  apiKey: "AIzaSyCGUfK1w-l-AK-r-zlqMUpNTNEn6Ae4nzU",
  authDomain: "solvry-walebkong.firebaseapp.com",
  messagingSenderId: "32814860247",
  projectNumber: "32814860247",
  version: "2",
});
const auth = getAuth(app),
  db = firestore.getFirestore(app);
let report = null,
  generation = 0;
const fields = document.querySelector("#fields"),
  identity = document.querySelector("#identity"),
  status = document.querySelector("#status"),
  results = document.querySelector("#results");
const prefill = new URLSearchParams(location.search);
const peer = prefill.get('peer') || '';
if (/^@?[a-z0-9-]{1,256}$/i.test(peer)) document.querySelector('#peer').value = peer;
if (/^\d{4}-\d{2}-\d{2}$/.test(prefill.get('date') || '')) document.querySelector('#date').value = prefill.get('date');
if (['unconnected','hidden','revealed','removed'].includes(prefill.get('phase'))) document.querySelector('#phase').value = prefill.get('phase');
if ((prefill.get('score') || '').length <= 256) document.querySelector('#expectedScore').value = prefill.get('score') || '';
onAuthStateChanged(auth, (user) => {
  generation++;
  report = null;
  fields.disabled = !user;
  identity.textContent = user
    ? "Signed in: " + user.email
    : "No Solvry Google account is signed in in this browser.";
  results.replaceChildren();
  document.querySelector("#report").textContent = "";
  document.querySelector("#download").hidden = true;
  document.querySelector("#copy").hidden = true;
});
document.querySelector("#checks").addEventListener("submit", async (event) => {
  event.preventDefault();
  const user = auth.currentUser,
    currentGeneration = generation;
  if (!user) return;
  fields.disabled = true;
  report = null;
  results.replaceChildren();
  status.textContent = "Reading live permissions…";
  document.querySelector("#download").hidden = true;
  document.querySelector("#copy").hidden = true;
  document.querySelector("#report").textContent = "";
  const isCurrent = () =>
    generation === currentGeneration && auth.currentUser?.uid === user.uid;
  try {
    report = await runBetaChecks({
      firestore,
      db,
      user,
      peerHandle: document.querySelector("#peer").value,
      date: document.querySelector("#date").value,
      phase: document.querySelector("#phase").value,
      expectedScore: document.querySelector("#expectedScore").value.trim(),
      isCurrent,
      onResult: (item) => {
        if (!isCurrent()) return;
        const row = document.createElement("div");
        row.className = "result " + (item.status === "PASS" ? "pass" : "fail");
        row.textContent =
          item.status +
          " · " +
          item.name +
          (item.detail ? " · " + item.detail : "");
        results.append(row);
      },
    });
    if (!isCurrent()) {
      report = null;
      return;
    }
    status.textContent =
      report.passed + " passed · " + report.failed + " failed";
    document.querySelector("#report").textContent = JSON.stringify(
      report,
      null,
      2,
    );
    document.querySelector("#download").hidden = false;
    document.querySelector("#copy").hidden = false;
  } catch (error) {
    if (isCurrent())
      status.textContent =
        error.code || error.message || "Could not complete the check.";
  } finally {
    if (isCurrent()) fields.disabled = false;
  }
});
document.querySelector("#download").addEventListener("click", () => {
  if (!report) return;
  const url = URL.createObjectURL(
    new Blob([JSON.stringify(report, null, 2)], { type: "application/json" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download =
    "solvry-beta-" +
    report.phase +
    "-" +
    report.checkedAt.slice(0, 10) +
    ".json";
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 60000);
});
document.querySelector("#copy").addEventListener("click", async () => {
  if (!report) return;
  try {
    await navigator.clipboard.writeText(JSON.stringify(report, null, 2));
    document.querySelector("#copyStatus").textContent =
      "Sanitized report copied.";
  } catch {
    document.querySelector("#copyStatus").textContent =
      "Copy was blocked. Use the visible report or Download instead.";
  }
});
