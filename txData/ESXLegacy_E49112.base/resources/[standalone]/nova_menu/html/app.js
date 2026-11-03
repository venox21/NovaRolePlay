let isSubVisible = true;
let currentData = {
  name: 'Spieler',
  id: 1,
  job: 'Arbeitslos',
  grade: '-',
  cash: 0,
  bank: 0,
  coins: 0,
  online: 1,
  isAdmin: false
};

let ticketsList = [];
let selectedTicketId = null;
let creatingNewTicket = false;

function renderCoins() {
  const topCoins = document.getElementById('top-coins');
  if (topCoins) {
    topCoins.textContent = Number(currentData.coins || 0).toLocaleString('de-DE');
  }
  document.querySelectorAll('.shop-banner-coins .coin-num').forEach(el => {
    el.textContent = `🔴 ${Number(currentData.coins || 0).toLocaleString('de-DE')} Coins`;
  });
}

function renderShopTransactions(txList) {
  const container = document.getElementById('shop-transactions-box');
  if (!container) return;
  container.innerHTML = '';
  if (!txList || txList.length === 0) {
    container.innerHTML = '<div style="color:#6b7280; font-size:13px; text-align:center; padding:12px;">Noch keine Transaktionen vorhanden.</div>';
    return;
  }
  txList.forEach(tx => {
    const row = document.createElement('div');
    row.className = 'stats-row';
    const isPlus = tx.type === 'plus';
    const sign = isPlus ? '+' : '-';
    const color = isPlus ? '#10b981' : '#a855f7';
    row.innerHTML = `
      <span>${escapeHtml(tx.date || 'Heute')}</span>
      <span>${escapeHtml(tx.title)} (${sign}${Number(tx.amount || 0).toLocaleString('de-DE')} Coins)</span>
      <strong style="color:${color};">${escapeHtml(tx.details || (isPlus ? 'Gutschrift' : 'Kauf'))}</strong>
    `;
    container.appendChild(row);
  });
}

function getResName() {
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'nova_menu';
}

function nuiPost(endpoint, payload = {}) {
  return fetch(`https://${getResName()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  }).catch(() => {});
}

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatMoney(n) {
  return '$' + Math.round(Number(n) || 0).toLocaleString('de-DE').replace(/\./g, ' ');
}

// 1. EMOTE KATALOG
const EMOTE_LIST = [
  { label: 'Winken', cat: 'emotes', icon: '👋', type: 'anim', dict: 'gestures@m@standing@casual', anim: 'gesture_hello' },
  { label: 'Daumen Hoch', cat: 'emotes', icon: '👍', type: 'anim', dict: 'anim@mp_player_intupperthumbs_up', anim: 'idle_a' },
  { label: 'Klatschen', cat: 'emotes', icon: '👏', type: 'anim', dict: 'anim@mp_player_intcelebrationmale@slow_clap', anim: 'slow_clap' },
  { label: 'Salutieren', cat: 'emotes', icon: '🫡', type: 'anim', dict: 'anim@mp_player_intuppersalute', anim: 'idle_a' },
  { label: 'Mittelfinger', cat: 'emotes', icon: '🖕', type: 'anim', dict: 'anim@mp_player_intupperfinger', anim: 'idle_a' },
  { label: 'Facepalm', cat: 'emotes', icon: '🤦', type: 'anim', dict: 'anim@mp_player_intupperface_palm', anim: 'idle_a' },
  { label: 'Friedenszeichen', cat: 'emotes', icon: '✌️', type: 'anim', dict: 'anim@mp_player_intupperpeace', anim: 'idle_a' },
  { label: 'Schulterzucken', cat: 'emotes', icon: '🤷', type: 'anim', dict: 'gestures@m@standing@casual', anim: 'gesture_shrug_hard' },

  { label: 'Club Dance', cat: 'dances', icon: '💃', type: 'anim', dict: 'anim@amb@nightclub@dancers@podium_dancers@', anim: 'hi_dance_facedown_17_v2_female^1' },
  { label: 'Hip Hop Dance', cat: 'dances', icon: '🕺', type: 'anim', dict: 'missfbi3_sniping', anim: 'dance_m_default' },
  { label: 'DJ feiern', cat: 'dances', icon: '🎧', type: 'anim', dict: 'anim@mp_player_intcelebrationmale@dj', anim: 'dj' },
  { label: 'Air Guitar', cat: 'dances', icon: '🎸', type: 'anim', dict: 'anim@mp_player_intcelebrationmale@air_guitar', anim: 'air_guitar' },

  { label: 'Rauchen', cat: 'lifestyle', icon: '🚬', type: 'scenario', anim: 'WORLD_HUMAN_SMOKING' },
  { label: 'Kaffee trinken', cat: 'lifestyle', icon: '☕', type: 'scenario', anim: 'WORLD_HUMAN_DRINKING' },
  { label: 'Bier trinken', cat: 'lifestyle', icon: '🍺', type: 'scenario', anim: 'WORLD_HUMAN_PARTYING' },
  { label: 'Liegestütze', cat: 'lifestyle', icon: '💪', type: 'scenario', anim: 'WORLD_HUMAN_PUSH_UPS' },
  { label: 'Sit-ups', cat: 'lifestyle', icon: '🏋️', type: 'scenario', anim: 'WORLD_HUMAN_SIT_UPS' },
  { label: 'Fotografieren', cat: 'lifestyle', icon: '📸', type: 'scenario', anim: 'WORLD_HUMAN_PAPARAZZI' },

  { label: 'Auf Stuhl sitzen', cat: 'poses', icon: '🪑', type: 'scenario', anim: 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER' },
  { label: 'Auf Boden sitzen', cat: 'poses', icon: '🧘', type: 'scenario', anim: 'WORLD_HUMAN_PICNIC' },
  { label: 'An Wand lehnen', cat: 'poses', icon: '🧍', type: 'scenario', anim: 'WORLD_HUMAN_LEANING' },
  { label: 'Sonnen / Liegen', cat: 'poses', icon: '🏖️', type: 'scenario', anim: 'WORLD_HUMAN_SUNBATHE' }
];

// 2. TICKETS RENDERN (LINKE LISTE)
function renderTicketHistory() {
  const container = document.getElementById('ticket-cards-container');
  if (!container) return;
  container.innerHTML = '';

  if (!ticketsList || ticketsList.length === 0) {
    selectedTicketId = null;
    const empty = document.createElement('div');
    empty.style.color = '#6b7280';
    empty.style.fontSize = '12px';
    empty.style.padding = '16px';
    empty.style.textAlign = 'center';
    empty.textContent = currentData.isAdmin
      ? 'Keine Tickets vorhanden.'
      : 'Noch keine Tickets vorhanden. Schreibe rechts eine Nachricht, um ein Ticket zu erstellen.';
    container.appendChild(empty);
    return;
  }

  // Falls nicht explizit "Neues Ticket" gewaehlt wurde und keine gueltige Auswahl existiert:
  // erstes offenes Ticket waehlen; wenn alle geschlossen sind -> leeres neues Ticket (null)
  if (!creatingNewTicket && (!selectedTicketId || !ticketsList.some(t => String(t.id) === String(selectedTicketId)))) {
    const firstOpen = ticketsList.find(t => t.status === 'Offen');
    selectedTicketId = firstOpen ? firstOpen.id : null;
  }

  // Oben immer "+ Neues Ticket erstellen" anbieten
  const newCard = document.createElement('div');
  const isNewActive = selectedTicketId === null;
  newCard.className = `ticket-card ${isNewActive ? 'active' : ''}`;
  newCard.style.borderColor = isNewActive ? '#a855f7' : '#282a36';
  newCard.style.background = isNewActive ? '#1e202b' : '#14151b';
  newCard.innerHTML = `
    <div class="card-top">
      <span class="ticket-num" style="color:#a855f7;">✚ Neues Ticket erstellen</span>
      <span class="card-status-badge" style="color:#06b6d4; background:#1b2430;">Neu</span>
    </div>
    <div class="card-msg" style="color:#9ca3af;">Schreibe rechts eine Nachricht, um ein neues Ticket zu öffnen.</div>
  `;
  newCard.addEventListener('click', () => {
    selectedTicketId = null;
    creatingNewTicket = true;
    renderTicketHistory();
    renderChatMessages();
    document.getElementById('chat-msg-input')?.focus();
  });
  container.appendChild(newCard);

  ticketsList.forEach((t) => {
    const card = document.createElement('div');
    const isAct = String(t.id) === String(selectedTicketId);
    card.className = `ticket-card ${isAct ? 'active' : ''}`;

    let lastMsg = 'Keine Nachrichten';
    if (Array.isArray(t.messages) && t.messages.length > 0) {
      const last = t.messages[t.messages.length - 1];
      lastMsg = last.text || last.alert || 'Keine Nachrichten';
    }
    const isClosed = t.status === 'Geschlossen';

    card.innerHTML = `
      <div class="card-top">
        <span class="ticket-num">Ticket ${escapeHtml(t.id)} - ${escapeHtml(t.playerName)} <span class="card-status-badge" style="${isClosed ? 'color:#ef4444' : 'color:#10b981'}">${escapeHtml(t.status)}</span></span>
        <span class="ticket-date">${escapeHtml(t.date || '')}</span>
      </div>
      <div class="card-msg">${escapeHtml(lastMsg)}</div>
    `;

    card.addEventListener('click', () => {
      selectedTicketId = t.id;
      creatingNewTicket = false;
      renderTicketHistory();
      renderChatMessages();
    });

    container.appendChild(card);
  });
}

// 3. TICKET CHAT RENDERN (RECHTE SPALTE)
function renderChatMessages() {
  const container = document.getElementById('ticket-chat-bubbles');
  const titleEl = document.getElementById('chat-header-title');
  const actionsEl = document.getElementById('chat-header-actions');
  const inputEl = document.getElementById('chat-msg-input');
  if (!container) return;
  container.innerHTML = '';

  const activeTicket = ticketsList.find(t => String(t.id) === String(selectedTicketId));

  if (!activeTicket) {
    if (titleEl) titleEl.textContent = 'TICKET ERSTELLEN';
    if (actionsEl) actionsEl.style.display = 'none';
    if (inputEl) inputEl.placeholder = 'Schreiben Sie eine Nachricht, um ein Ticket zu erstellen...';

    const empty = document.createElement('div');
    empty.style.color = '#6b7280';
    empty.style.fontSize = '13px';
    empty.style.padding = '24px';
    empty.style.textAlign = 'center';
    empty.style.marginTop = 'auto';
    empty.style.marginBottom = 'auto';
    empty.textContent = 'Schreibe unten eine Nachricht, um ein neues Support-Ticket zu eröffnen.';
    container.appendChild(empty);
    return;
  }

  if (titleEl) {
    titleEl.textContent = `TICKET #${activeTicket.id} - ${activeTicket.playerName} (${activeTicket.status.toUpperCase()})`;
  }

  if (inputEl) {
    inputEl.placeholder = activeTicket.status === 'Geschlossen'
      ? 'Ticket geschlossen — Nachricht erstellt automatisch ein neues Ticket...'
      : 'Schreiben Sie eine Nachricht...';
  }

  if (actionsEl) {
    actionsEl.style.display = 'flex';
    const tpBtn = document.getElementById('btn-goto-player');
    if (tpBtn) {
      tpBtn.style.display = currentData.isAdmin ? 'flex' : 'none';
    }
    const closeBtn = document.getElementById('btn-close-ticket');
    if (closeBtn) {
      closeBtn.style.display = activeTicket.status === 'Geschlossen' ? 'none' : 'flex';
    }
  }

  const msgs = activeTicket.messages || [];
  msgs.forEach(m => {
    if (m.alert) {
      const alert = document.createElement('div');
      alert.className = 'chat-badge-alert';
      alert.textContent = m.alert;
      container.appendChild(alert);
    } else {
      const bubble = document.createElement('div');
      bubble.className = `chat-bubble ${m.type === 'staff' ? 'staff' : 'player'}`;
      const timePart = m.time ? ` <span style="color:#6b7280; font-weight:500; margin-left:6px;">${escapeHtml(m.time)}</span>` : '';
      bubble.innerHTML = `
        <div class="bubble-sender">${escapeHtml(m.sender)}${timePart}</div>
        <div class="bubble-text">${escapeHtml(m.text)}</div>
      `;
      container.appendChild(bubble);
    }
  });

  container.scrollTop = container.scrollHeight;
}

// TICKET SCHLIESSEN BUTTON
document.getElementById('btn-close-ticket')?.addEventListener('click', () => {
  if (!selectedTicketId) return;
  const closedId = selectedTicketId;
  // Direkt auf leeres neues Ticket umschalten
  selectedTicketId = null;
  creatingNewTicket = true;
  renderTicketHistory();
  renderChatMessages();
  nuiPost('closeTicket', { ticketId: closedId });
});

// TELEPORT BUTTON (ADMIN)
document.getElementById('btn-goto-player')?.addEventListener('click', () => {
  if (!selectedTicketId) return;
  nuiPost('gotoPlayer', { ticketId: selectedTicketId });
});

// NACHRICHT ABSENDEN
function submitTicketChat() {
  const input = document.getElementById('chat-msg-input');
  if (!input) return;
  const txt = input.value.trim();
  if (!txt) return;

  const targetTicketId = creatingNewTicket ? null : selectedTicketId;
  creatingNewTicket = false;

  nuiPost('sendTicketMsg', {
    message: txt,
    ticketId: targetTicketId
  });

  input.value = '';
}

document.getElementById('btn-submit-chat')?.addEventListener('click', submitTicketChat);
document.getElementById('chat-msg-input')?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    submitTicketChat();
  }
});

// 4. EMOTE KATALOG
function renderEmotes(catFilter = 'all', query = '') {
  const grid = document.getElementById('anim-grid');
  if (!grid) return;
  grid.innerHTML = '';

  const q = query.toLowerCase().trim();
  const filtered = EMOTE_LIST.filter(e => {
    const matchCat = catFilter === 'all' || e.cat === catFilter;
    const matchQ = !q || e.label.toLowerCase().includes(q);
    return matchCat && matchQ;
  });

  filtered.forEach(e => {
    const card = document.createElement('div');
    card.className = 'emote-card';
    card.innerHTML = `
      <span>${escapeHtml(e.label)}</span>
      <span class="emote-icon">${e.icon}</span>
    `;
    card.addEventListener('click', () => {
      nuiPost('playEmote', e);
    });
    grid.appendChild(card);
  });
}

document.getElementById('btn-stop-anim')?.addEventListener('click', () => {
  nuiPost('playEmote', { action: 'cancel' });
});

let currentAnimCat = 'all';
document.querySelectorAll('.cat-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('.cat-chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    currentAnimCat = chip.dataset.cat || 'all';
    renderEmotes(currentAnimCat, document.getElementById('anim-search')?.value || '');
  });
});

document.getElementById('anim-search')?.addEventListener('input', (e) => {
  renderEmotes(currentAnimCat, e.target.value);
});

// 5. SUB-TREE KLICK-HANDLER (CHARAKTER & GESCHÄFT)
document.querySelectorAll('#group-charakter .sub-tree-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.stopPropagation();
    const subtab = item.dataset.subtab;
    document.querySelectorAll('#group-charakter .sub-tree-item').forEach(i => i.classList.remove('active'));
    item.classList.add('active');

    document.querySelectorAll('.char-subview').forEach(v => v.classList.remove('active'));
    const target = document.getElementById(`subview-${subtab}`);
    if (target) target.classList.add('active');

    document.querySelectorAll('.menu-nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelector('.menu-nav-btn[data-tab="charakter"]')?.classList.add('active');

    document.querySelectorAll('.main-tab-view').forEach(v => v.classList.remove('active'));
    document.getElementById('view-charakter')?.classList.add('active');

    const titleEl = document.getElementById('page-main-title');
    if (titleEl) titleEl.textContent = `CHARAKTER // ${item.textContent.trim().toUpperCase()}`;
  });
});

document.querySelectorAll('#group-geschaeft .sub-tree-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.stopPropagation();
    const shopsub = item.dataset.shopsub;
    document.querySelectorAll('#group-geschaeft .sub-tree-item').forEach(i => i.classList.remove('active'));
    item.classList.add('active');

    document.querySelectorAll('.shop-subview').forEach(v => v.classList.remove('active'));
    const target = document.getElementById(`subview-${shopsub}`);
    if (target) target.classList.add('active');

    document.querySelectorAll('.menu-nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelector('.menu-nav-btn[data-tab="geschaeft"]')?.classList.add('active');

    document.querySelectorAll('.main-tab-view').forEach(v => v.classList.remove('active'));
    document.getElementById('view-geschaeft')?.classList.add('active');

    const cleanTitle = item.querySelector('.sub-title')?.textContent || item.textContent.replace('🔒', '').trim();
    const titleEl = document.getElementById('page-main-title');
    if (titleEl) titleEl.textContent = `GESCHÄFT // ${cleanTitle.toUpperCase()}`;
  });
});

// 6. MAIN NAVIGATION TABS (INKL. ACCORDION FUER CHARAKTER & GESCHÄFT)
document.querySelectorAll('.menu-nav-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const tabName = btn.dataset.tab;
    const wasActive = btn.classList.contains('active');

    document.querySelectorAll('.menu-nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.main-tab-view').forEach(v => v.classList.remove('active'));

    btn.classList.add('active');
    const view = document.getElementById(`view-${tabName}`);
    if (view) view.classList.add('active');
    if (tabName === 'aufgaben') updateDailyStatus();

    // Accordion Steuerung Charakter
    const charSubTree = document.querySelector('#group-charakter .sub-tree-list');
    const charChevron = document.querySelector('#group-charakter .chevron');
    if (tabName === 'charakter') {
      if (charSubTree) {
        const isHidden = charSubTree.style.display === 'none';
        if (wasActive) {
          charSubTree.style.display = isHidden ? 'flex' : 'none';
        } else {
          charSubTree.style.display = 'flex';
        }
        if (charChevron) charChevron.textContent = charSubTree.style.display === 'none' ? '›' : '⌄';
      }
      const activeSub = document.querySelector('#group-charakter .sub-tree-item.active');
      const titleEl = document.getElementById('page-main-title');
      if (titleEl) {
        titleEl.textContent = activeSub
          ? `CHARAKTER // ${activeSub.textContent.trim().toUpperCase()}`
          : 'CHARAKTER';
      }
      return;
    }

    // Accordion Steuerung Geschäft
    const shopSubTree = document.querySelector('#group-geschaeft .sub-tree-list');
    const shopChevron = document.querySelector('#group-geschaeft .chevron');
    if (tabName === 'geschaeft') {
      if (shopSubTree) {
        const isHidden = shopSubTree.style.display === 'none';
        if (wasActive) {
          shopSubTree.style.display = isHidden ? 'flex' : 'none';
        } else {
          shopSubTree.style.display = 'flex';
        }
        if (shopChevron) shopChevron.textContent = shopSubTree.style.display === 'none' ? '›' : '⌄';
      }
      const activeSub = document.querySelector('#group-geschaeft .sub-tree-item.active');
      const titleEl = document.getElementById('page-main-title');
      if (titleEl) {
        const cleanTitle = activeSub ? (activeSub.querySelector('.sub-title')?.textContent || activeSub.textContent.replace('🔒', '').trim()) : 'STARTSEITE';
        titleEl.textContent = `GESCHÄFT // ${cleanTitle.toUpperCase()}`;
      }
      return;
    }

    const titleEl = document.getElementById('page-main-title');
    const itemTitle = btn.querySelector('.item-title')?.textContent?.trim() || tabName;
    if (titleEl) titleEl.textContent = itemTitle.toUpperCase();
  });
});

// Top-Bar Button "Aufladen" springt direkt in den Store -> Aufladen
document.getElementById('btn-recharge')?.addEventListener('click', () => {
  const shopBtn = document.querySelector('.menu-nav-btn[data-tab="geschaeft"]');
  if (shopBtn) shopBtn.click();
  const aufladenSub = document.querySelector('[data-shopsub="shop-aufladen"]');
  if (aufladenSub) aufladenSub.click();
});

// Shop Kauf-Buttons Interaktion
document.querySelectorAll('.shop-buy-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const card = btn.closest('.shop-card');
    if (!card) return;

    const title = card.querySelector('.shop-card-title')?.textContent?.trim() || 'Artikel';
    const priceText = card.querySelector('.shop-card-price')?.textContent || '';
    const subview = card.closest('.shop-subview');
    const cat = subview ? subview.id.replace('subview-shop-', '') : '';

    let price = 0;
    let coinsToAdd = 0;

    if (cat === 'aufladen') {
      const match = title.match(/(\d+[\s\d]*)/);
      if (match) {
        coinsToAdd = Number(match[1].replace(/\s/g, '')) || 500;
      }
    } else {
      const cleanNum = priceText.replace(/[^\d]/g, '');
      price = Number(cleanNum) || 0;
    }

    let isVehicle = false;
    let model = '';
    let cashAmount = 0;

    const lowerTitle = title.toLowerCase();

    if (lowerTitle.includes('bugatti')) {
      isVehicle = true;
      model = 'nero2';
    } else if (lowerTitle.includes('neulings-paket') || lowerTitle.includes('neuling')) {
      isVehicle = true;
      model = 'rhinehart';
      cashAmount = 250000;
    } else if (lowerTitle.includes('porsche')) {
      isVehicle = true;
      model = 'comet6';
    } else if (lowerTitle.includes('mercedes') || lowerTitle.includes('g63')) {
      isVehicle = true;
      model = 'dubsta';
    } else if (lowerTitle.includes('bmw') || lowerTitle.includes('m5')) {
      isVehicle = true;
      model = 'tailgater2';
    } else if (lowerTitle.includes('audi') || lowerTitle.includes('rs6')) {
      isVehicle = true;
      model = 'rhinehart';
    } else if (lowerTitle.includes('supervolito')) {
      isVehicle = true;
      model = 'supervolito2';
    } else if (lowerTitle.includes('street racer')) {
      isVehicle = true;
      model = 'sultanrs';
      cashAmount = 50000;
    } else if (cat === 'fahrzeug') {
      isVehicle = true;
      model = 'comet2';
    }

    if (cat === 'geld') {
      const matchGeld = title.match(/\$([\d.]+)/);
      if (matchGeld) {
        cashAmount = Number(matchGeld[1].replace(/\./g, '')) || 50000;
      }
    }

    let itemId = '';
    if (title.includes('Schönheits-OP')) itemId = 'char-skin';
    else if (title.includes('Namensänderung')) itemId = 'char-name';
    else if (title.includes('Charakterslot')) itemId = 'char-slot';

    const origText = btn.textContent;
    btn.textContent = '...';
    btn.disabled = true;

    nuiPost('buyShopItem', {
      title,
      price,
      cat,
      isCrate: (cat === 'kisten'),
      coins: coinsToAdd,
      cash: cashAmount,
      isVehicle,
      model,
      item: itemId
    });

    setTimeout(() => {
      btn.textContent = '✓ Ausgewählt';
      btn.style.background = '#10b981';
      setTimeout(() => {
        btn.textContent = origText;
        btn.style.background = '#a855f7';
        btn.disabled = false;
      }, 1500);
    }, 400);
  });
});

// 7. EINSTELLUNGEN INTERAKTIVITAET (ALLE KATEGORIEN)
const SELECTOR_OPTIONS = {
  // Schnittstelle
  'Sprache': ['🇩🇪 Deutsch', '🇬🇧 English'],
  'Schnittstelle zum Territoriumskampf': ['Standard', 'Kompakt', 'Aus'],
  'Tooltip-Anzeige': ['Steuerung', 'Minimal', 'Aus'],
  'Tacho': ['Minimalistisch (2)', 'Sport (1)', 'Klassisch', 'Aus'],
  'Aktualisierungsrate des Tachos': ['Normal', 'Hoch', 'Niedrig'],
  'Interface Thema': ['Dunkel', 'Kontrast'],
  'Schriftart der Spielernamen über dem Kopf': ['ProximaNova SemiB...', 'Inter SemiBold', 'Rajdhani Bold'],

  // Zusätzlich
  'FPS-Begrenzung': ['Unbegrenzt', '144 FPS', '120 FPS', '60 FPS', '30 FPS'],
  'Schatten-Distanz': ['Hoch', 'Sehr Hoch', 'Normal'],
  'Distanz-Skalierung': ['100%', '75%', '50%'],
  'HDR-Helligkeitsbereich': ['Standard', 'Kräftig', 'Sanft'],
  'Straßenglanz & Reflexionen': ['Hoch', 'Ultra', 'Normal'],

  // Sound-Anpassung
  'Gesamtlautstärke': ['100%', '80%', '60%', '40%', '20%', '0%'],
  'Sprachchat (Voice-Lautstärke)': ['100%', '80%', '60%', '40%', '20%'],
  'Funkgerät-Lautstärke': ['80%', '100%', '60%', '40%', '20%'],
  'Soundeffekte & Motoren': ['100%', '80%', '60%', '40%'],
  'Hintergrundmusik': ['Aus', '20%', '50%', '100%'],
  'Mikrofon-Empfindlichkeit': ['Normal', 'Hoch', 'Niedrig'],

  // Spiel Chat
  'Schriftgröße im Chat': ['Normal', 'Klein', 'Groß'],
  'Hintergrund-Deckkraft': ['80%', '100%', '50%', '0% Unsichtbar'],
  'Automatisch ausblenden': ['Nach 10 Sekunden', 'Nach 5 Sekunden', 'Nie'],

  // Makros
  'Schnellslot 1 (Waffe / Item)': ['Taste 1', 'Ziffernblock 1'],
  'Schnellslot 2 (Waffe / Item)': ['Taste 2', 'Ziffernblock 2'],
  'Schnellslot 3 (Waffe / Item)': ['Taste 3', 'Ziffernblock 3'],
  'Schnellslot 4 (Waffe / Item)': ['Taste 4', 'Ziffernblock 4'],
  'Schnellslot 5 (Waffe / Item)': ['Taste 5', 'Ziffernblock 5'],
  'Schnell-Animation 1': ['Winken (/e wave)', 'Salutieren (/e salute)', 'Hände hoch'],
  'Schnell-Animation 2': ['Daumen Hoch (/e thumbup)', 'Klatschen', 'Facepalm'],
  'Schnell-Animation 3': ['Sitzen (/e sit)', 'An Wand lehnen', 'Rauchen'],
  'Schnell-Animation 4': ['Kaffee trinken', 'Bier trinken', 'Liegestütze'],

  // Fadenkreuz
  'Fadenkreuz-Stil': ['Punkt', 'Kreis', 'Klassisch (+)', 'Dynamisch'],
  'Fadenkreuz-Farbe': ['Rot', 'Weiß', 'Grün', 'Cyan', 'Violett', 'Gelb'],
  'Punktgröße': ['Mittel (4px)', 'Klein (2px)', 'Groß (6px)'],

  // Sicherheit
  'Zwei-Faktor-Authentifizierung (2FA)': ['Aktiviert', 'Deaktiviert'],
  'Discord-Konto Verknüpfung': ['Verbunden (FabianLuca)', 'Trennen'],
  'Automatische Abmeldung bei Inaktivität': ['Nach 30 Min', 'Nach 15 Min', 'Nach 60 Min', 'Nie']
};

function updateCrosshairPreview() {
  const el = document.getElementById('crosshair-preview-element');
  const toggle = document.getElementById('crosshair-toggle');
  const styleEl = document.getElementById('crosshair-style-val');
  const colorEl = document.getElementById('crosshair-color-val');
  const sizeEl = document.getElementById('crosshair-size-val');
  const outline = document.getElementById('crosshair-outline');
  if (!el) return;

  if (toggle && !toggle.checked) {
    el.style.display = 'none';
    return;
  }
  el.style.display = 'block';

  const style = styleEl?.textContent?.trim() || 'Punkt';
  const colorName = colorEl?.textContent?.trim() || 'Rot';
  const sizeText = sizeEl?.textContent?.trim() || 'Mittel (4px)';

  const colorMap = {
    'Rot': '#ef4444',
    'Weiß': '#ffffff',
    'Grün': '#10b981',
    'Cyan': '#06b6d4',
    'Violett': '#a855f7',
    'Gelb': '#facc15'
  };
  const colorHex = colorMap[colorName] || '#ef4444';

  el.className = 'crosshair-element';
  if (style === 'Kreis') {
    el.classList.add('circle');
    el.style.background = 'transparent';
    el.style.borderColor = colorHex;
  } else if (style === 'Klassisch (+)') {
    el.classList.add('cross');
    el.style.background = 'transparent';
  } else if (style === 'Dynamisch') {
    el.classList.add('dynamic');
    el.style.borderColor = colorHex;
  } else {
    el.classList.add('dot');
    el.style.background = colorHex;
  }

  const hasOutline = outline ? outline.checked : true;
  el.style.boxShadow = hasOutline ? '0 0 0 1px #000' : 'none';

  let px = 6;
  if (sizeText.includes('Klein')) px = 4;
  else if (sizeText.includes('Groß')) px = 9;

  if (style === 'Punkt') {
    el.style.width = px + 'px';
    el.style.height = px + 'px';
  }
}

document.querySelectorAll('.setting-card').forEach(card => {
  const label = card.querySelector('.setting-label')?.textContent?.trim();
  const valEl = card.querySelector('.selector-val');
  const arrows = card.querySelectorAll('.selector-arrow');
  if (label && valEl && arrows.length === 2 && SELECTOR_OPTIONS[label]) {
    const opts = SELECTOR_OPTIONS[label];
    arrows[0].addEventListener('click', () => {
      const idx = Math.max(0, opts.indexOf(valEl.textContent.trim()));
      valEl.textContent = opts[(idx - 1 + opts.length) % opts.length];
      if (label.startsWith('Fadenkreuz') || label === 'Punktgröße') {
        updateCrosshairPreview();
      }
    });
    arrows[1].addEventListener('click', () => {
      const idx = Math.max(0, opts.indexOf(valEl.textContent.trim()));
      valEl.textContent = opts[(idx + 1) % opts.length];
      if (label.startsWith('Fadenkreuz') || label === 'Punktgröße') {
        updateCrosshairPreview();
      }
    });
  }
});

document.getElementById('crosshair-toggle')?.addEventListener('change', updateCrosshairPreview);
document.getElementById('crosshair-outline')?.addEventListener('change', updateCrosshairPreview);

document.getElementById('set-toggle-map')?.addEventListener('change', (e) => {
  nuiPost('updateSetting', { key: 'map', value: Boolean(e.target.checked) });
});

function switchSettingsTab(targetId) {
  if (!targetId) return;

  // Sidebar Buttons aktualisieren
  document.querySelectorAll('.set-sub-item').forEach(s => {
    s.classList.toggle('active', s.dataset.target === targetId);
  });

  document.querySelectorAll('.set-cat-btn').forEach(b => {
    if (targetId === 'schnittstelle' || targetId === 'zusatzlich') {
      b.classList.toggle('active', b.dataset.target === 'schnittstelle');
    } else {
      b.classList.toggle('active', b.dataset.target === targetId);
    }
  });

  // Subview wechseln
  document.querySelectorAll('.settings-subview').forEach(view => {
    view.classList.remove('active');
  });

  const activeView = document.getElementById(`setview-${targetId}`);
  if (activeView) {
    activeView.classList.add('active');
  }

  if (targetId === 'fadenkreuz') {
    updateCrosshairPreview();
  }
}

document.querySelectorAll('.set-sub-item').forEach(sub => {
  sub.addEventListener('click', (e) => {
    e.stopPropagation();
    switchSettingsTab(sub.dataset.target);
  });
});

document.querySelectorAll('.set-cat-btn').forEach(catBtn => {
  catBtn.addEventListener('click', () => {
    switchSettingsTab(catBtn.dataset.target);
  });
});

// 8. ID TOGGLE
document.getElementById('id-toggle-btn')?.addEventListener('click', () => {
  isSubVisible = !isSubVisible;
  const idEl = document.getElementById('menu-user-id');
  if (idEl) idEl.textContent = isSubVisible ? `ID: #${currentData.id}` : 'ID: #***';
});

// 9. EXIT / CLOSE
function closeMenu() {
  const overlay = document.getElementById('menu-overlay');
  if (overlay) {
    overlay.classList.add('hidden');
    overlay.style.display = 'none';
  }
  nuiPost('close', {});
}

document.getElementById('btn-exit')?.addEventListener('click', closeMenu);

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' || e.key === 'F2' || e.code === 'F2') {
    e.preventDefault();
    closeMenu();
  }
});

// 10. NUI RECEIVER
window.addEventListener('message', (event) => {
  const d = event.data;
  if (!d) return;

  if (d.action === 'openMenu') {
    const overlay = document.getElementById('menu-overlay');
    if (overlay) {
      overlay.classList.remove('hidden');
      overlay.style.display = 'flex';
    }
    renderTicketHistory();
    renderChatMessages();
    renderEmotes(currentAnimCat, document.getElementById('anim-search')?.value || '');
    updateDailyStatus();
  } else if (d.action === 'crateReward' && d.data) {
    const modal = document.getElementById('crate-modal');
    if (modal) {
      document.getElementById('crate-modal-title').textContent = d.data.crate || 'KISTE GEÖFFNET!';
      document.getElementById('crate-modal-reward').textContent = d.data.reward || '';
      document.getElementById('crate-modal-desc').textContent = d.data.desc || '';
      modal.style.display = 'flex';
    }
  } else if (d.action === 'dailyClaimed') {
    updateDailyStatus();
  } else if (d.action === 'closeMenu') {
    const overlay = document.getElementById('menu-overlay');
    if (overlay) {
      overlay.classList.add('hidden');
      overlay.style.display = 'none';
    }
  } else if (d.action === 'updateCoins') {
    currentData.coins = Number(d.coins) || 0;
    renderCoins();
    if (d.transactions) {
      renderShopTransactions(d.transactions);
    }
  } else if (d.action === 'updateTickets') {
    ticketsList = d.tickets || [];
    if (d.closedId) {
      if (!selectedTicketId || String(selectedTicketId) === String(d.closedId)) {
        selectedTicketId = null;
        creatingNewTicket = true;
      }
    } else if (d.activeId) {
      selectedTicketId = d.activeId;
      creatingNewTicket = false;
    }
    renderTicketHistory();
    renderChatMessages();
  } else if (d.action === 'updateData' && d.data) {
    currentData = { ...currentData, ...d.data };
    if (Array.isArray(d.data.tickets)) {
      ticketsList = d.data.tickets;
    }
    if (typeof d.data.coins !== 'undefined') {
      currentData.coins = Number(d.data.coins) || 0;
    }
    renderCoins();
    if (d.data.transactions) {
      renderShopTransactions(d.data.transactions);
    }

    const nameEl = document.getElementById('menu-user-name');
    const idEl = document.getElementById('menu-user-id');
    if (nameEl) nameEl.textContent = currentData.name;
    if (idEl) idEl.textContent = isSubVisible ? `ID: #${currentData.id}` : 'ID: #***';

    const setSafe = (id, val) => {
      const el = document.getElementById(id);
      if (el) el.textContent = val;
    };

    setSafe('c-name', currentData.name);
    setSafe('c-id', currentData.id);
    setSafe('c-job', currentData.job);
    setSafe('c-job2', currentData.job);
    setSafe('c-grade', currentData.grade);
    setSafe('c-cash', formatMoney(currentData.cash));
    setSafe('c-bank', formatMoney(currentData.bank));
    setSafe('c-online', currentData.online);

    // Westen & Rüstung
    const armourVal = Math.min(100, Math.max(0, Number(currentData.armour) || 0));
    setSafe('vest-current-status', `${armourVal}% Rüstung`);
    const armourBar = document.getElementById('vest-armour-bar');
    if (armourBar) armourBar.style.width = `${armourVal}%`;

    setSafe('vest-count-50', `${currentData.vests50 || 0}x`);
    setSafe('vest-count-100', `${currentData.vests100 || 0}x`);

    renderTicketHistory();
    renderChatMessages();
  }
});

// Westen Schnell-Ausrüstung im F2-Menü
document.querySelectorAll('.vest-equip-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const vestType = btn.dataset.type;
    if (!vestType) return;
    nuiPost('equipVest', { type: vestType });
  });
});

document.getElementById('btn-unequip-vest')?.addEventListener('click', (e) => {
  e.stopPropagation();
  nuiPost('unequipVest', {});
});

// NOVA: Tagesbelohnungen & Kisten Popup Handlers
function updateDailyStatus() {
  nuiPost('getDailyStatus', {}).then(res => {
    const textEl = document.getElementById('daily-cooldown-text');
    const btn = document.getElementById('claim-daily-btn');
    if (!textEl || !btn) return;

    if (res && res.canClaim) {
      textEl.textContent = 'Status: Bereit zum Abholen!';
      textEl.style.color = '#22c55e';
      btn.disabled = false;
      btn.style.opacity = '1';
      btn.style.cursor = 'pointer';
      btn.textContent = 'Belohnung abholen';
    } else {
      const remaining = res ? res.remaining : 86400;
      const hours = Math.floor(remaining / 3600);
      const mins = Math.floor((remaining % 3600) / 60);
      textEl.textContent = `Nächste Belohnung in: ${hours}h ${mins}m`;
      textEl.style.color = '#9ca3af';
      btn.disabled = true;
      btn.style.opacity = '0.5';
      btn.style.cursor = 'not-allowed';
      btn.textContent = 'Bereits abgeholt';
    }
  }).catch(() => {});
}

document.getElementById('claim-daily-btn')?.addEventListener('click', (e) => {
  e.stopPropagation();
  nuiPost('claimDaily', {});
});

document.getElementById('crate-modal-close')?.addEventListener('click', (e) => {
  e.stopPropagation();
  const modal = document.getElementById('crate-modal');
  if (modal) modal.style.display = 'none';
});

// Initial render damit Grid & Ansichten sofort bereitstehen
renderCoins();
renderEmotes();
renderTicketHistory();
renderChatMessages();
updateCrosshairPreview();
updateDailyStatus();
