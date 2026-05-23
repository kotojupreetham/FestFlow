import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";
import { getFirestore, collection, getDocs, doc, updateDoc, deleteDoc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { getAuth, GoogleAuthProvider, signInWithPopup } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { gsap } from "https://esm.sh/gsap-trial@3.12.5";
import { Flip } from "https://esm.sh/gsap-trial@3.12.5/Flip";

gsap.registerPlugin(Flip);

/* ===== FIREBASE CONFIG ===== */
const firebaseConfig = {
  apiKey: "YOUR_API_KEY_HERE",
  authDomain: "YOUR_AUTH_DOMAIN_HERE",
  projectId: "YOUR_PROJECT_ID_HERE",
  storageBucket: "YOUR_STORAGE_BUCKET_HERE",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
  appId: "YOUR_APP_ID_HERE"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

/* ===== STATE ===== */
let allEvents = [];
let activeFilter = "all";

/* ===== BOOT ===== */
window.addEventListener("DOMContentLoaded", () => {
  animateLoginScreen();

  document.getElementById("google-login-btn").addEventListener("click", handleLogin);
  document.getElementById("toggle-layout").addEventListener("click", toggleLayout);
  document.getElementById("refresh-data").addEventListener("click", () => fetchAndRenderEvents());
  document.getElementById("search-input").addEventListener("input", handleSearch);

  document.querySelectorAll(".filter-pill").forEach(pill => {
    pill.addEventListener("click", () => handleFilterClick(pill));
  });
});

/* ===== LOGIN ANIMATION ===== */
function animateLoginScreen() {
  const card = document.querySelector(".login-card");
  gsap.fromTo(card,
    { y: 40, opacity: 0, scale: 0.95 },
    { y: 0, opacity: 1, scale: 1, duration: 1, ease: "power4.out", delay: 0.3 }
  );

  gsap.fromTo(".logo-icon",
    { rotation: -10, scale: 0.8 },
    { rotation: 0, scale: 1, duration: 0.8, ease: "back.out(1.7)", delay: 0.5 }
  );

  gsap.fromTo(".login-btn",
    { y: 20, opacity: 0 },
    { y: 0, opacity: 1, duration: 0.6, ease: "power3.out", delay: 0.8 }
  );
}

/* ===== AUTH ===== */
async function handleLogin() {
  const loginBtn = document.getElementById("google-login-btn");
  try {
    loginBtn.innerHTML = `<span class="spinner"></span> Authenticating...`;
    loginBtn.style.pointerEvents = "none";

    const provider = new GoogleAuthProvider();
    const result = await signInWithPopup(auth, provider);
    const user = result.user;

    document.getElementById("user-avatar").innerText = user.displayName ? user.displayName.charAt(0).toUpperCase() : "A";
    document.getElementById("admin-name").innerText = user.displayName || "Admin";

    // Transition out login
    gsap.to("#login-overlay", {
      opacity: 0,
      scale: 1.05,
      duration: 0.6,
      ease: "power3.in",
      onComplete: () => {
        document.getElementById("login-overlay").style.display = "none";
        document.getElementById("app").style.display = "block";
        animateAppEntrance();
        fetchAndRenderEvents();
      }
    });
  } catch (err) {
    const errorEl = document.getElementById("login-error");
    errorEl.style.display = "block";
    errorEl.innerText = "Auth Failed: " + err.message;
    loginBtn.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg> Try Again`;
    loginBtn.style.pointerEvents = "auto";
  }
}

/* ===== APP ENTRANCE ===== */
function animateAppEntrance() {
  const tl = gsap.timeline({ defaults: { ease: "power4.out" } });

  tl.fromTo("#topbar", { y: -60, opacity: 0 }, { y: 0, opacity: 1, duration: 0.7 })
    .fromTo(".metric-card", { y: 30, opacity: 0, scale: 0.9 }, { y: 0, opacity: 1, scale: 1, duration: 0.5, stagger: 0.1 }, "-=0.3")
    .fromTo("#controls-bar", { y: 20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.5 }, "-=0.2");
}

/* ===== FETCH & RENDER ===== */
async function fetchAndRenderEvents() {
  const container = document.getElementById("events-container");
  const emptyState = document.getElementById("empty-state");

  // Exit animation for old cards
  const existingCards = container.querySelectorAll(".event-card");
  if (existingCards.length > 0) {
    await gsap.to(existingCards, {
      scale: 0.9, opacity: 0, y: 10, duration: 0.25, stagger: 0.03, ease: "power2.in"
    });
  }
  container.innerHTML = "";
  emptyState.style.display = "none";

  // Show Skeleton loaders
  for (let i = 0; i < 3; i++) {
    container.insertAdjacentHTML("beforeend", `<div class="skeleton-card"></div>`);
  }

  try {
    const snags = await getDocs(collection(db, "events"));
    container.innerHTML = ""; // Clear skeletons

    if (snags.empty) {
      emptyState.style.display = "flex";
      updateMetrics(0, 0, 0);
      return;
    }

    allEvents = [];

    for (const docSnap of snags.docs) {
      const id = docSnap.id;
      const data = docSnap.data();
      const details = data.details || {};
      const leader = data.leader || {};
      const isApproved = data.isApproved === true;

      // createdBy is nested inside details map, fallback to leader.email
      const leaderEmail = details.createdBy || leader.email || data.createdBy || "Unknown";
      const leaderName = leader.username || details.createdBy || leaderEmail;

      // Fetch leader data from users collection
      let leaderData = null;
      if (leaderEmail !== "Unknown") {
        try {
          const usrSnap = await getDoc(doc(db, "leader", leaderEmail, "events", id));
          if (usrSnap.exists()) leaderData = usrSnap.data();
        } catch (e) { /* silent */ }
      }

      allEvents.push({ id, data, details, isApproved, leaderEmail, leaderName, leaderData });
    }

    renderCards(allEvents);
    updateMetrics(
      allEvents.length,
      allEvents.filter(e => !e.isApproved).length,
      allEvents.filter(e => e.isApproved).length
    );

  } catch (e) {
    container.innerHTML = "";
    console.error(e);
    showToast("Network Error: " + e.message, "error");
  }
}

/* ===== RENDER CARDS ===== */
function renderCards(events) {
  const container = document.getElementById("events-container");
  const emptyState = document.getElementById("empty-state");
  container.innerHTML = "";

  const filtered = events.filter(ev => {
    if (activeFilter === "pending") return !ev.isApproved;
    if (activeFilter === "approved") return ev.isApproved;
    return true;
  });

  if (filtered.length === 0) {
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  filtered.forEach(ev => {
    const { id, data, details, isApproved, leaderEmail, leaderName, leaderData } = ev;

    const title = details.title || "Untitled Event";
    const location = details.location || data.location || "—";
    const type = details.type || "—";
    const startDate = details.startingDate || details.date || "—";
    const endDate = details.endingDate || "—";
    const prize = details.prize || "—";
    const description = details.description || "—";
    const maxGuests = details.maxGuests || details.guestLimit || "—";
    const maxMembers = details.maxMembers || details.memberLimit || "—";

    // Format dates nicely
    const fmtDate = (d) => {
      if (d === "—") return d;
      if (typeof d === 'object' && d.seconds) {
        return new Date(d.seconds * 1000).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
      }
      if (typeof d === 'string') {
        const parsed = new Date(d);
        return isNaN(parsed.getTime()) ? d : parsed.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
      }
      return d;
    };

    const rawDataDump = JSON.stringify(data, null, 2);
    const leaderDump = leaderData ? JSON.stringify(leaderData, null, 2) : "No data found";

    const uid = id.replace(/[^a-zA-Z0-9-_]/g, '_');

    const html = `
      <div class="event-card" id="card-${uid}" data-id="${id}" data-approved="${isApproved}" data-title="${title.toLowerCase()}">

        <div class="card-header">
          <div>
            <div class="card-title">${title}</div>
            <span class="card-code">${id}</span>
          </div>
          <div class="status-pill ${isApproved ? 'pill-approved' : 'pill-pending'}">
            ${isApproved ? '✓ Approved' : '⏳ Pending'}
          </div>
        </div>

        <div class="card-dossier">
          <div class="dossier-item">
            <span class="dossier-icon">👤</span>
            <div>
              <div class="dossier-key">Leader</div>
              <div class="dossier-value">${leaderName}</div>
              <div class="dossier-value" style="font-size:0.7rem;opacity:0.6">${leaderEmail}</div>
            </div>
          </div>
          <div class="dossier-item">
            <span class="dossier-icon">📍</span>
            <div>
              <div class="dossier-key">Location</div>
              <div class="dossier-value">${location}</div>
            </div>
          </div>
          <div class="dossier-item">
            <span class="dossier-icon">🎯</span>
            <div>
              <div class="dossier-key">Type</div>
              <div class="dossier-value">${type}</div>
            </div>
          </div>
          <div class="dossier-item">
            <span class="dossier-icon">🏆</span>
            <div>
              <div class="dossier-key">Prize</div>
              <div class="dossier-value">${prize}</div>
            </div>
          </div>
          <div class="dossier-item">
            <span class="dossier-icon">📅</span>
            <div>
              <div class="dossier-key">Start</div>
              <div class="dossier-value">${fmtDate(startDate)}</div>
            </div>
          </div>
          <div class="dossier-item">
            <span class="dossier-icon">📅</span>
            <div>
              <div class="dossier-key">End</div>
              <div class="dossier-value">${fmtDate(endDate)}</div>
            </div>
          </div>
          ${description !== "—" ? `
          <div class="dossier-item full-span">
            <span class="dossier-icon">📝</span>
            <div>
              <div class="dossier-key">Description</div>
              <div class="dossier-value">${description}</div>
            </div>
          </div>` : ''}
        </div>

        <button class="advanced-toggle" onclick="toggleAdvanced('${uid}')">
          <span>Raw Database Payload</span>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
        </button>
        <div class="advanced-content" id="advanced-${uid}">
          <span class="json-path">events/${id}</span>${rawDataDump}
          <hr class="json-separator">
          <span class="json-path">leader/${leaderEmail}/events/${id}</span>${leaderDump}
        </div>

        <div class="card-actions">
          <button class="action-btn ${isApproved ? 'btn-revoke' : 'btn-approve'}" onclick="toggleStatus('${id}', ${isApproved})">
            ${isApproved
              ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> Revoke'
              : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Approve'}
          </button>
          <button class="action-btn btn-delete" onclick="deleteEvent('${id}')">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
        </div>

      </div>
    `;
    container.insertAdjacentHTML("beforeend", html);
  });

  // Entrance anim
  gsap.fromTo(".event-card",
    { y: 40, opacity: 0, scale: 0.96 },
    { y: 0, opacity: 1, scale: 1, duration: 0.55, stagger: 0.07, ease: "power4.out" }
  );
}

/* ===== METRICS ===== */
function updateMetrics(total, pending, approved) {
  animateCounter("count-total", total);
  animateCounter("count-pending", pending);
  animateCounter("count-approved", approved);
}

function animateCounter(id, target) {
  const el = document.getElementById(id);
  const obj = { val: parseInt(el.innerText) || 0 };
  gsap.to(obj, {
    val: target,
    duration: 1,
    ease: "power2.out",
    onUpdate: () => { el.innerText = Math.round(obj.val); }
  });
}

/* ===== TOGGLE STATUS ===== */
window.toggleStatus = async (id, currentStatus) => {
  const newStatus = !currentStatus;
  const uid = id.replace(/[^a-zA-Z0-9-_]/g, '_');
  const cardElement = document.getElementById(`card-${uid}`);
  const statusPill = cardElement.querySelector('.status-pill');
  const actionBtn = cardElement.querySelector('.card-actions .action-btn:first-child');

  gsap.to(cardElement, { scale: 0.98, duration: 0.1, yoyo: true, repeat: 1 });
  actionBtn.innerHTML = `<span>Processing...</span>`;
  actionBtn.style.opacity = "0.6";
  actionBtn.style.pointerEvents = "none";

  try {
    const docRef = doc(db, "events", id);
    await updateDoc(docRef, { isApproved: newStatus });

    const state = Flip.getState(cardElement);

    if (newStatus) {
      statusPill.className = "status-pill pill-approved";
      statusPill.innerHTML = "✓ Approved";
      actionBtn.className = "action-btn btn-revoke";
      actionBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> Revoke`;
      actionBtn.setAttribute("onclick", `toggleStatus('${id}', true)`);
      showToast("Event approved successfully", "success");
    } else {
      statusPill.className = "status-pill pill-pending";
      statusPill.innerHTML = "⏳ Pending";
      actionBtn.className = "action-btn btn-approve";
      actionBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Approve`;
      actionBtn.setAttribute("onclick", `toggleStatus('${id}', false)`);
      showToast("Event approval revoked", "warning");
    }

    actionBtn.style.opacity = "1";
    actionBtn.style.pointerEvents = "auto";
    cardElement.dataset.approved = String(newStatus);

    // Update local state & metrics
    const ev = allEvents.find(e => e.id === id);
    if (ev) ev.isApproved = newStatus;
    updateMetrics(
      allEvents.length,
      allEvents.filter(e => !e.isApproved).length,
      allEvents.filter(e => e.isApproved).length
    );

    Flip.from(state, {
      duration: 0.45,
      ease: "power2.out",
      onStart: () => {
        gsap.fromTo(cardElement,
          { borderColor: newStatus ? "#34d399" : "#fbbf24" },
          { borderColor: "rgba(255,255,255,0.06)", duration: 1.5 }
        );
      }
    });

  } catch (e) {
    console.error(e);
    showToast("Failed: " + e.message, "error");
    actionBtn.innerHTML = "Error - Retry";
    actionBtn.style.opacity = "1";
    actionBtn.style.pointerEvents = "auto";
  }
};

/* ===== DELETE EVENT ===== */
window.deleteEvent = async (id) => {
  if (!confirm(`⚠️ CRITICAL: Delete ALL data for event '${id}'? This cannot be undone.`)) return;

  const uid = id.replace(/[^a-zA-Z0-9-_]/g, '_');
  const cardElement = document.getElementById(`card-${uid}`);
  const deleteBtn = cardElement.querySelector('.btn-delete');
  deleteBtn.innerHTML = `<span>Deleting...</span>`;
  deleteBtn.style.pointerEvents = "none";

  try {
    const docRef = doc(db, "events", id);
    await deleteDoc(docRef);

    gsap.to(cardElement, {
      scale: 0.85, opacity: 0, y: -20, duration: 0.4, ease: "power3.in",
      onComplete: () => {
        cardElement.remove();
        allEvents = allEvents.filter(e => e.id !== id);
        updateMetrics(
          allEvents.length,
          allEvents.filter(e => !e.isApproved).length,
          allEvents.filter(e => e.isApproved).length
        );
        showToast("Event deleted permanently", "success");
      }
    });
  } catch (e) {
    showToast("Delete failed: " + e.message, "error");
    deleteBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>`;
    deleteBtn.style.pointerEvents = "auto";
  }
};

/* ===== ADVANCED TOGGLE ===== */
window.toggleAdvanced = (uid) => {
  const btn = document.querySelector(`#card-${uid} .advanced-toggle`);
  const content = document.getElementById(`advanced-${uid}`);
  const isOpen = content.classList.contains("open");

  if (isOpen) {
    gsap.to(content, {
      height: 0, opacity: 0, duration: 0.3, ease: "power2.in",
      onComplete: () => { content.classList.remove("open"); content.style.height = ""; }
    });
    btn.classList.remove("open");
  } else {
    content.classList.add("open");
    const fullH = content.scrollHeight;
    gsap.fromTo(content,
      { height: 0, opacity: 0 },
      { height: fullH, opacity: 1, duration: 0.35, ease: "power2.out",
        onComplete: () => { content.style.height = "auto"; }
      }
    );
    btn.classList.add("open");
  }
};

/* ===== SEARCH ===== */
function handleSearch(e) {
  const query = e.target.value.toLowerCase().trim();
  const cards = document.querySelectorAll(".event-card");

  cards.forEach(card => {
    const title = card.dataset.title || "";
    const code = card.dataset.id || "";
    const match = title.includes(query) || code.toLowerCase().includes(query);
    if (match) {
      card.classList.remove("card-hidden");
      gsap.to(card, { opacity: 1, scale: 1, duration: 0.2 });
    } else {
      gsap.to(card, { opacity: 0, scale: 0.95, duration: 0.2, onComplete: () => card.classList.add("card-hidden") });
    }
  });
}

/* ===== FILTER ===== */
function handleFilterClick(pill) {
  document.querySelectorAll(".filter-pill").forEach(p => p.classList.remove("active"));
  pill.classList.add("active");
  activeFilter = pill.dataset.filter;
  renderCards(allEvents);
}

/* ===== LAYOUT TOGGLE ===== */
function toggleLayout() {
  const container = document.getElementById("events-container");
  const cards = gsap.utils.toArray(".event-card");

  const state = Flip.getState(cards);
  container.classList.toggle("list-view");

  Flip.from(state, {
    duration: 0.55,
    ease: "power3.inOut",
    absolute: true,
    stagger: 0.04
  });
}

/* ===== TOAST SYSTEM ===== */
function showToast(message, type = "success") {
  const container = document.getElementById("toast-container");

  const icons = {
    success: `<svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
    error: `<svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`,
    warning: `<svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`
  };

  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `${icons[type] || icons.success}<span>${message}</span>`;

  container.appendChild(toast);

  gsap.fromTo(toast,
    { x: 60, opacity: 0 },
    { x: 0, opacity: 1, duration: 0.4, ease: "back.out(1.5)" }
  );

  setTimeout(() => {
    gsap.to(toast, {
      x: 60, opacity: 0, duration: 0.3, ease: "power2.in",
      onComplete: () => toast.remove()
    });
  }, 3200);
}
