/* ============================================================
   NOVA ROLEPLAY · APPLE IPAD PRO TABLET LOGIC
   ============================================================ */

(function() {
  const $ = (id) => document.getElementById(id);

  function escapeHtml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
  const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'nova_tablet';

  let tabletData = {
    playerName: 'Fabian',
    job: 'Unemployed',
    grade: '-',
    accounts: { bank: 0, money: 0 },
    onlineCount: 0,
    players: [],
    faction: { inFaction: false, name: 'unemployed', label: 'Keine Fraktion', grade: '-' },
    family: { inFamily: false, name: 'none', label: 'Keine Familie', grade: '-' },
    properties: []
  };

  let currentOpenApp = null;
  let currentFactionMode = 'faction';
  let activeFactionData = null;
  let currentActivePanel = null;

  // ---------- NUI HELPER ----------
  function post(endpoint, payload = {}, cb = null) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload)
    })
    .then(async resp => {
      let data = null;
      try {
        const text = await resp.text();
        try {
          data = JSON.parse(text);
        } catch (_) {
          data = text;
        }
      } catch (_) {}
      if (typeof cb === 'function') cb(data);
      return data;
    })
    .catch((err) => {
      console.warn(`[nova_tablet] POST error on ${endpoint}:`, err);
    });
  }

  // ---------- LIVE GERMAN CLOCK & DATE ----------
  const DAYS = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const MONTHS = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  function updateClock() {
    const d = new Date();
    const dayName = DAYS[d.getDay()];
    const dayNum = String(d.getDate()).padStart(2, '0');
    const monthName = MONTHS[d.getMonth()];
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');

    const str = `${hours}:${minutes}, ${dayName}, ${dayNum}. ${monthName}`;
    const clockEl = $('status-clock');
    if (clockEl) clockEl.textContent = str;
  }
  updateClock();
  setInterval(updateClock, 1000);

  // Initial reset
  closeApp();
  closeFactionDashboard();
  closeAlert();

  // ---------- IOS ALERT MODAL ----------
  function showAlert(title, message) {
    $('alert-title').textContent = title || 'Hinweis';
    $('alert-message').textContent = message || '';
    $('ios-alert').classList.remove('hidden');
  }

  function closeAlert() {
    $('ios-alert').classList.add('hidden');
  }

  $('alert-btn-ok').addEventListener('click', closeAlert);

  // ---------- WINDOW / STANDARD APP CONTROLLER ----------
  function openApp(appId, title) {
    closeFactionDashboard();
    const contents = document.querySelectorAll('.win-content');
    contents.forEach(c => c.classList.add('hidden'));

    $('win-title').textContent = title || 'App';

    const targetContent = $(`content-${appId}`);
    if (targetContent) {
      targetContent.classList.remove('hidden');
    }

    $('window-layer').classList.remove('hidden');
    currentOpenApp = appId;

    if (appId === '2048') {
      Game2048.init();
    } else if (appId === 'apply') {
      loadApplyPortal();
    }
  }

  function closeApp() {
    $('window-layer').classList.add('hidden');
    currentOpenApp = null;
  }

  $('win-btn-back').addEventListener('click', closeApp);
  $('win-btn-close').addEventListener('click', closeApp);

  // Home bar
  $('home-bar').addEventListener('click', () => {
    const fDash = $('faction-dashboard');
    if (fDash && !fDash.classList.contains('hidden')) {
      if (currentActivePanel) {
        $('f-subview-wrapper').classList.add('hidden');
        $('f-dash-grid').classList.remove('hidden');
        currentActivePanel = null;
      } else {
        closeFactionDashboard();
      }
    } else if (currentOpenApp) {
      closeApp();
    } else {
      closeTablet();
    }
  });

  $('btn-power').addEventListener('click', closeTablet);

  function closeTablet() {
    closeAlert();
    closeApp();
    closeFactionDashboard();
    $('tablet-frame').classList.add('hidden');
    post('close');
  }

  // ============================================================
  // MEDIA 1793642487766 · FRAKTIONS- & FAMILIEN DASHBOARD
  // ============================================================

  function openFactionDashboard(mode) {
    currentFactionMode = mode;
    closeApp();
    closeAlert();

    const isFam = (mode === 'family');
    const fData = isFam ? tabletData.family : tabletData.faction;

    $('f-dash-org-name').textContent = fData.label || (isFam ? 'Familie' : 'Fraktion');
    $('f-dash-user-name').textContent = tabletData.playerName || 'Mitglied';
    $('f-dash-user-rank').textContent = (fData.grade || 'Mitglied') + '|';

    $('home-view').classList.add('hidden');
    $('faction-dashboard').classList.remove('hidden');
    $('f-dash-grid').classList.remove('hidden');
    $('f-subview-wrapper').classList.add('hidden');
    currentActivePanel = null;

    post('getFactionDetails', { mode: mode });
  }

  function closeFactionDashboard() {
    const fDash = $('faction-dashboard');
    if (fDash) fDash.classList.add('hidden');
    $('home-view').classList.remove('hidden');
    activeFactionData = null;
    currentActivePanel = null;
  }

  $('f-dash-close-btn').addEventListener('click', closeFactionDashboard);

  $('f-btn-back').addEventListener('click', () => {
    $('f-subview-wrapper').classList.add('hidden');
    $('f-dash-grid').classList.remove('hidden');
    currentActivePanel = null;
  });

  const PANEL_TITLES = {
    notice: 'Wichtiger Hinweis & Ankündigung',
    roster: 'Kollegen & Mitgliederverwaltung',
    ranks: 'Rang-Übersicht & Berechtigungen',
    settings: 'Einstellungen der Organisation',
    logs: 'Protokolle & Verlauf',
    vault: 'Guthaben & Fraktionskasse',
    bonus: 'Prämierung & Bonuszahlung',
    contracts: 'Verträge & Aufträge',
    blacklist: 'Organisations-Blacklist',
    upgrades: 'Fraktions-Verbesserungen',
    territories: 'Territoriale Kontrolle',
    influence: 'Einfluss & Reputation',
    'state-mdc': 'Polizeidatenbank & Strafregister (MDC)',
    'state-justice': 'Justiz, Sanktionen & Lizenzen',
    'state-logistics': 'Fuhrpark, Logistik & Einsatzmittel',
    'state-comms': 'GNews & Departmentfunk',
    vehicles: 'Fraktionsfuhrpark (Autos & Motorräder)'
  };

  document.querySelectorAll('.f-tile').forEach(tile => {
    tile.addEventListener('click', () => {
      const panelId = tile.getAttribute('data-panel');
      openFactionPanel(panelId);
    });
  });

  function openFactionPanel(panelId) {
    currentActivePanel = panelId;
    $('f-dash-grid').classList.add('hidden');
    $('f-subview-wrapper').classList.remove('hidden');
    $('f-subview-title').textContent = PANEL_TITLES[panelId] || 'Details';

    document.querySelectorAll('.f-panel').forEach(p => p.classList.add('hidden'));
    const targetPanel = $(`panel-${panelId}`);
    if (targetPanel) {
      targetPanel.classList.remove('hidden');
    }

    if (activeFactionData) {
      renderFactionPanel(panelId);
    } else {
      post('getFactionDetails', { mode: currentFactionMode });
    }
  }

  function updateFactionDetails(data) {
    if (!data.success) {
      showAlert('Organisation', data.message || 'Konnte nicht geladen werden.');
      closeFactionDashboard();
      return;
    }

    activeFactionData = data;
    const isState = (data.faction && data.faction.type === 'state');
    $('f-dash-org-name').textContent = data.faction.label;
    $('f-dash-user-name').textContent = tabletData.playerName;
    $('f-dash-user-rank').textContent = (data.currentGrade || 'Mitglied') + '|';
    adaptFactionTiles(isState);

    if (currentActivePanel) {
      renderFactionPanel(currentActivePanel);
    }
  }


  // ============================================================
  // 36 STATE-BERECHTIGUNGEN KATALOG
  // ============================================================
  const STATE_PERMISSIONS = [
    // 1. MITGLIEDERVERWALTUNG & DISZIPLIN
    { key: 'invite', label: 'Personen in die Fraktion einladen', cat: 'members' },
    { key: 'kick', label: 'Personen aus der Fraktion entlassen', cat: 'members' },
    { key: 'ranks_manage', label: 'Ränge ändern', cat: 'members' },
    { key: 'warns_manage', label: 'Verwarnungen verwalten', cat: 'members' },
    { key: 'members_suspend', label: 'Spieler aus Fraktionen suspendieren', cat: 'members' },
    { key: 'members_expel', label: 'Spieler aus Fraktionen verweisen', cat: 'members' },
    { key: 'blacklist_manage', label: 'Blacklist verwalten', cat: 'members' },

    // 2. ORGANISATION, RÄNGE & ABTEILUNGEN
    { key: 'rank_system_edit', label: 'Rangsystem ändern', cat: 'org' },
    { key: 'departments_edit', label: 'Abteilungen bearbeiten', cat: 'org' },
    { key: 'departments_assign', label: 'Abteilungen zuweisen', cat: 'org' },
    { key: 'outfits_edit', label: 'Kleidungssets bearbeiten', cat: 'org' },
    { key: 'private_outfits_edit', label: 'Private Kleidungssets bearbeiten', cat: 'org' },
    { key: 'doors_control', label: 'Gebäudetüren öffnen/schließen', cat: 'org' },

    // 3. FINANZEN & KASSE
    { key: 'vault_deposit', label: 'Guthaben aufladen', cat: 'finance' },
    { key: 'vault_withdraw', label: 'Guthaben abheben', cat: 'finance' },
    { key: 'bonus_distribute', label: 'Bonusauszahlungen verteilen', cat: 'finance' },
    { key: 'mass_payout', label: 'Massenauszahlungen durchführen', cat: 'finance' },
    { key: 'funding_execute', label: 'Finanzierungen durchführen', cat: 'finance' },

    // 4. LAGER, LOGISTIK & FAHRZEUGE
    { key: 'vehicles_spawn', label: 'Autos & Motorräder ausparken', cat: 'logistics' },
    { key: 'storage_use', label: 'Fraktionslager nutzen', cat: 'logistics' },
    { key: 'storage_manage', label: 'Lager verwalten', cat: 'logistics' },
    { key: 'crafting_use', label: 'Crafting nutzen', cat: 'logistics' },
    { key: 'materials_order', label: 'Materialien bestellen', cat: 'logistics' },
    { key: 'vehicles_respawn', label: 'Fraktionsfahrzeuge respawnen', cat: 'logistics' },
    { key: 'vehicles_impound', label: 'Fahrzeuge abschleppen', cat: 'logistics' },
    { key: 'airdrops_open', label: 'Airdrops öffnen', cat: 'logistics' },

    // 5. JUSTIZ, LIZENZEN & STRAFVERFOLGUNG
    { key: 'database_use', label: 'Datenbank nutzen', cat: 'police' },
    { key: 'records_create', label: 'Strafregister erstellen', cat: 'police' },
    { key: 'records_delete', label: 'Strafregister löschen', cat: 'police' },
    { key: 'fines_issue', label: 'Geldstrafen ausstellen', cat: 'police' },
    { key: 'jail_player', label: 'Personen inhaftieren', cat: 'police' },
    { key: 'jail_long', label: 'Inhaftierungen über 50 Minuten durchführen', cat: 'police' },
    { key: 'licenses_give', label: 'Lizenzen ausstellen', cat: 'police' },
    { key: 'licenses_revoke', label: 'Lizenzen entziehen', cat: 'police' },
    { key: 'vehicle_search_report', label: 'Fahrzeugdurchsuchungen erstellen', cat: 'police' },

    // 6. KOMMUNIKATION & NEWS
    { key: 'department_radio', label: 'Departmentfunk nutzen', cat: 'comms' },
    { key: 'gnews_access', label: 'Zugriff auf GNews', cat: 'comms' }
  ];

  const PERM_CATEGORIES = {
    members: '👥 Mitgliederverwaltung & Disziplin',
    org: '🏢 Organisation, Ränge & Abteilungen',
    finance: '💰 Finanzen & Staatskasse',
    logistics: '📦 Lager, Logistik & Fuhrpark',
    police: '⚖️ Justiz, Lizenzen & Strafverfolgung',
    comms: '📡 Kommunikation & News'
  };

  function adaptFactionTiles(isState) {
    const tDyn1 = $('f-tile-dyn-1');
    const tDyn2 = $('f-tile-dyn-2');
    const tDyn3 = $('f-tile-dyn-3');
    const tDyn4 = $('f-tile-dyn-4');
    const tDyn5 = $('f-tile-dyn-5');
    if (!tDyn1 || !tDyn2 || !tDyn3 || !tDyn4 || !tDyn5) return;

    if (isState) {
      tDyn1.setAttribute('data-panel', 'state-mdc');
      tDyn1.querySelector('.f-tile-label').textContent = 'MDC & Akten';
      tDyn1.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><circle cx="12" cy="14" r="3"></circle><line x1="14" y1="16" x2="18" y2="20"></line></svg>`;

      tDyn2.setAttribute('data-panel', 'state-justice');
      tDyn2.querySelector('.f-tile-label').textContent = 'Justiz & Lizenzen';
      tDyn2.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><path d="M12 6v6l4 2"></path><path d="M9 18l6-6"></path></svg>`;

      tDyn3.setAttribute('data-panel', 'state-logistics');
      tDyn3.querySelector('.f-tile-label').textContent = 'Logistik & Mittel';
      tDyn3.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"></rect><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon><circle cx="5.5" cy="18.5" r="2.5"></circle><circle cx="18.5" cy="18.5" r="2.5"></circle></svg>`;

      tDyn4.setAttribute('data-panel', 'state-comms');
      tDyn4.querySelector('.f-tile-label').textContent = 'GNews & Funk';
      tDyn4.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"></path><path d="M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"></path><circle cx="12" cy="12" r="2"></circle><path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5"></path><path d="M19.1 4.9C23 8.8 23 15.2 19.1 19.1"></path></svg>`;

      tDyn5.setAttribute('data-panel', 'blacklist');
      tDyn5.querySelector('.f-tile-label').textContent = 'Blacklist';
    } else {
      tDyn1.setAttribute('data-panel', 'contracts');
      tDyn1.querySelector('.f-tile-label').textContent = 'Verträge';
      tDyn1.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 64 64" width="56" height="56" fill="currentColor"><path d="M14 8h24l12 12v32a4 4 0 0 1-4 4H14a4 4 0 0 1-4-4V12a4 4 0 0 1 4-4z"/><circle cx="44" cy="44" r="11" fill="#ffffff"/><circle cx="44" cy="44" r="9" fill="currentColor"/><text x="44" y="49" font-size="13" font-weight="900" text-anchor="middle" fill="#ffffff" font-family="sans-serif">$</text></svg>`;

      tDyn2.setAttribute('data-panel', 'blacklist');
      tDyn2.querySelector('.f-tile-label').textContent = 'Blacklist';
      tDyn2.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 64 64" width="56" height="56" fill="currentColor"><circle cx="32" cy="22" r="9"/><path d="M18 52c0-7.7 6.3-14 14-14s14 6.3 14 14v2H18v-2z"/><circle cx="32" cy="32" r="23" fill="none" stroke="currentColor" stroke-width="5"/><line x1="16" y1="16" x2="48" y2="48" stroke="currentColor" stroke-width="5"/></svg>`;

      tDyn3.setAttribute('data-panel', 'upgrades');
      tDyn3.querySelector('.f-tile-label').textContent = 'Verbesserungen';
      tDyn3.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 64 64" width="56" height="56" fill="currentColor"><rect x="10" y="10" width="44" height="44" rx="10"/><circle cx="24" cy="32" r="5" fill="#ffffff"/><circle cx="40" cy="22" r="4" fill="#ffffff"/><circle cx="40" cy="42" r="4" fill="#ffffff"/></svg>`;

      tDyn4.setAttribute('data-panel', 'territories');
      tDyn4.querySelector('.f-tile-label').textContent = 'Territoriale Kontrolle';
      tDyn4.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 64 64" width="56" height="56" fill="currentColor"><path d="M52 12l-7 1-6 6 8 8 6-6 1-7-2-2zM45 25l-21 21-3-3 21-21 3 3zM16 48l-4 4-2-2 4-4 2 2zM12 12l7 1 6 6-8 8-6-6-1-7 2-2zM19 25l21 21 3-3-21-21-3 3z"/></svg>`;

      tDyn5.setAttribute('data-panel', 'influence');
      tDyn5.querySelector('.f-tile-label').textContent = 'Einfluss';
      tDyn5.querySelector('.f-tile-icon').innerHTML = `<svg viewBox="0 0 64 64" width="56" height="56" fill="currentColor"><circle cx="32" cy="32" r="28"/><polygon points="32,15 33.8,20.5 39.5,20.5 34.8,24 36.6,29.5 32,26 27.4,29.5 29.2,24 24.5,20.5 30.2,20.5" fill="#ffffff"/></svg>`;
    }
  }

  function renderFactionPanel(panelId) {
    if (!activeFactionData) return;
    const isLeader = activeFactionData.isLeader;
    const f = activeFactionData.faction;

    // 1. HINWEIS
    if (panelId === 'notice') {
      $('notice-display-text').textContent = f.notice || 'Keine Bekanntmachung hinterlegt.';
      $('notice-meta-author').textContent = 'Verfasst von: ' + (f.leaderName || 'Fraktionsleitung');
      const leaderBox = $('notice-leader-box');
      if (leaderBox) leaderBox.style.display = isLeader ? 'flex' : 'none';
      const inputEl = $('notice-input');
      if (inputEl) inputEl.value = f.notice || '';

    // 2. KOLLEGEN
    } else if (panelId === 'roster') {
      const members = activeFactionData.members || [];
      const onlineCount = members.filter(m => m.isOnline).length;
      $('roster-count-total').textContent = members.length;
      $('roster-count-online').textContent = onlineCount;

      const inviteBox = $('roster-invite-box');
      if (inviteBox) inviteBox.style.display = isLeader ? 'flex' : 'none';

      renderRosterList(members);
      renderFactionApplications();

    // 2.5 RÄNGE & BERECHTIGUNGEN
    } else if (panelId === 'ranks') {
      renderFactionRanksOverview();

    // 3. EINSTELLUNGEN
    } else if (panelId === 'settings') {
      $('set-info-name').textContent = f.label + ` (${f.name})`;
      $('set-info-id').textContent = '#' + f.id;
      $('set-info-type').textContent = (f.type === 'gang' ? 'Gang / Familie' : 'Staatliche Behörde');
      $('set-info-leader').textContent = f.leaderName || 'Kein Leader ernannt';
      $('set-input-radio').value = f.radioFreq || '100.0';
      $('set-select-recruit').value = f.recruitOpen ? 'open' : 'closed';

      $('set-input-radio').disabled = !isLeader;
      $('set-select-recruit').disabled = !isLeader;
      $('btn-save-settings').style.display = isLeader ? 'inline-block' : 'none';
      renderFactionRanks(activeFactionData.grades || [], isLeader);

    // 4. PROTOKOLLE
    } else if (panelId === 'logs') {
      const logs = activeFactionData.logs || [];
      const listEl = $('f-logs-list');
      listEl.innerHTML = '';
      if (logs.length === 0) {
        listEl.innerHTML = '<p style="color:#94a3b8; padding:1rem;">Keine Protokolleinträge vorhanden.</p>';
      } else {
        logs.forEach(l => {
          const item = document.createElement('div');
          item.className = 'log-item';
          const typeClass = 'tag-' + (l.type || 'info');
          item.innerHTML = `
            <div class="log-left">
              <span class="log-tag ${typeClass}">${l.type || 'INFO'}</span>
              <span class="log-text">${l.text}</span>
            </div>
            <span class="log-meta">${l.date || ''} · ${l.author || 'System'}</span>
          `;
          listEl.appendChild(item);
        });
      }

    // 5. GUTHABEN VERWALTEN
    } else if (panelId === 'vault') {
      $('vault-display-val').textContent = '$' + Number(activeFactionData.vault || 0).toLocaleString('de-DE');
      const withdrawBox = $('vault-withdraw-box');
      if (withdrawBox) withdrawBox.style.display = isLeader ? 'flex' : 'none';

    // 6. PRÄMIERUNG
    } else if (panelId === 'bonus') {
      const selectEl = $('bonus-select-target');
      selectEl.innerHTML = '<option value="">-- Mitglied auswählen --</option>';
      (activeFactionData.members || []).forEach(m => {
        const opt = document.createElement('option');
        opt.value = m.identifier;
        opt.textContent = `${m.name} (${m.gradeLabel}) - ID #${m.charId}`;
        selectEl.appendChild(opt);
      });

    // 7. VERTRÄGE
    } else if (panelId === 'contracts') {
      const grid = $('contracts-grid');
      grid.innerHTML = '';
      const contracts = activeFactionData.contracts || [];
      contracts.forEach(c => {
        const card = document.createElement('div');
        card.className = 'contract-card';
        card.innerHTML = `
          <div>
            <div class="contract-header">
              <span class="contract-title">${c.title}</span>
              <span class="contract-reward">+$${Number(c.reward).toLocaleString('de-DE')}</span>
            </div>
            <p class="contract-desc">${c.desc}</p>
          </div>
          <button class="f-btn-primary btn-complete-contract" data-cid="${c.id}">Auftrag ausführen & Prämie erhalten</button>
        `;
        grid.appendChild(card);
      });

      grid.querySelectorAll('.btn-complete-contract').forEach(btn => {
        btn.addEventListener('click', () => {
          const cid = btn.getAttribute('data-cid');
          post('completeContract', { factionId: f.id, contractId: cid });
          showAlert('Vertrag erfüllt', 'Auftrag abgeschlossen! Belohnung wurde der Kasse und dir gutgeschrieben.');
          setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
        });
      });

    // 8. BLACKLIST
    } else if (panelId === 'blacklist') {
      const listEl = $('blacklist-items');
      listEl.innerHTML = '';
      const bl = activeFactionData.blacklist || [];
      const addBox = $('blacklist-add-box');
      if (addBox) addBox.style.display = isLeader ? 'flex' : 'none';

      if (bl.length === 0) {
        listEl.innerHTML = '<p style="color:#94a3b8; padding:0.5rem;">Keine Personen auf der Blacklist eingetragen.</p>';
      } else {
        bl.forEach((b, idx) => {
          const item = document.createElement('div');
          item.className = 'log-item';
          item.innerHTML = `
            <div class="log-left">
              <span class="log-tag" style="background:#fee2e2; color:#b91c1c;">GESPERRT</span>
              <div>
                <strong>${b.name}</strong>
                <div style="font-size:0.8rem; color:#64748b;">${b.reason}</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:0.6rem;">
              <span class="log-meta">${b.date} · ${b.author}</span>
              ${isLeader ? `<button class="btn-table-action action-kick btn-del-bl" data-idx="${idx + 1}">✕</button>` : ''}
            </div>
          `;
          listEl.appendChild(item);
        });

        listEl.querySelectorAll('.btn-del-bl').forEach(btn => {
          btn.addEventListener('click', () => {
            const index = btn.getAttribute('data-idx');
            post('manageBlacklist', { factionId: f.id, action: 'remove', index: index });
            showAlert('Blacklist', 'Eintrag entfernt.');
            setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
          });
        });
      }

    // 9. VERBESSERUNGEN
    } else if (panelId === 'upgrades') {
      const grid = $('upgrades-grid');
      grid.innerHTML = '';
      const upgrades = activeFactionData.upgrades || [];
      upgrades.forEach(u => {
        const card = document.createElement('div');
        card.className = 'upgrade-card';
        card.innerHTML = `
          <div>
            <div class="upgrade-header">
              <span class="upgrade-title">${u.name}</span>
              <span class="upgrade-cost">${u.unlocked ? '✓ Aktiv' : '$' + Number(u.cost).toLocaleString('de-DE')}</span>
            </div>
            <p class="upgrade-desc">${u.desc}</p>
          </div>
          ${u.unlocked 
            ? '<span class="badge-kpi badge-online" style="text-align:center;">Freigeschaltet & Aktiv</span>'
            : `<button class="f-btn-primary btn-unlock-upgrade" data-uid="${u.id}" ${!isLeader ? 'disabled style="opacity:0.5;"' : ''}>Freischalten ($${Number(u.cost).toLocaleString('de-DE')})</button>`
          }
        `;
        grid.appendChild(card);
      });

      grid.querySelectorAll('.btn-unlock-upgrade').forEach(btn => {
        btn.addEventListener('click', () => {
          const uid = btn.getAttribute('data-uid');
          post('buyUpgrade', { factionId: f.id, upgradeId: uid });
          showAlert('Verbesserung', 'Kaufauftrag übermittelt.');
          setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
        });
      });

    // 10. TERRITORIALE KONTROLLE
    } else if (panelId === 'territories') {
      const grid = $('territories-grid');
      grid.innerHTML = '';
      const territories = activeFactionData.territories || [];
      territories.forEach(t => {
        const isOwner = (t.owner === f.label);
        const card = document.createElement('div');
        card.className = 'territory-card';
        card.innerHTML = `
          <div>
            <div class="territory-header">
              <span class="territory-title">${t.name}</span>
              <span class="badge-kpi ${isOwner ? 'badge-online' : ''}">${t.owner} (${t.control}%)</span>
            </div>
            <div class="territory-bar-wrap">
              <div class="territory-bar-fill" style="width:${t.control}%; background:${isOwner ? '#22c55e' : '#3b82f6'};"></div>
            </div>
            <p class="territory-meta">Stündlicher Fraktionsbonus: +$${Number(t.revenue).toLocaleString('de-DE')}</p>
          </div>
          <button class="f-btn-primary btn-patrol-terr" data-tid="${t.id}">Patrouillieren (+5% Kontrolle)</button>
        `;
        grid.appendChild(card);
      });

      grid.querySelectorAll('.btn-patrol-terr').forEach(btn => {
        btn.addEventListener('click', () => {
          const tid = btn.getAttribute('data-tid');
          post('claimTerritory', { factionId: f.id, territoryId: tid });
          showAlert('Patrouille', 'Gebietskontrolle verstärkt.');
          setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
        });
      });

    // 12. AUTOS & FUHRPARK
    } else if (panelId === 'vehicles') {
      renderFactionVehiclesTab('cars');

    // 11. EINFLUSS
    } else if (panelId === 'influence') {
      $('influence-display-num').textContent = f.influence || 85;
      const countTerr = (activeFactionData.territories || []).filter(t => t.owner === f.label).length;
      $('inf-val-territories').textContent = `${countTerr || 1} Gebiete gesichert`;
      $('inf-val-vault').textContent = '$' + Number(activeFactionData.vault || 0).toLocaleString('de-DE');

    // 12. STATE: MDC & STRAFREGISTER
    } else if (panelId === 'state-mdc') {
      renderMdcRecords();

    // 13. STATE: JUSTIZ & LIZENZEN
    } else if (panelId === 'state-justice') {
      renderJusticePanel();

    // 14. STATE: FUHRPARK & LOGISTIK
    } else if (panelId === 'state-logistics') {
      // Logistik-Tools aktiv

    // 15. STATE: GNEWS & FUNK
    } else if (panelId === 'state-comms') {
      // GNews & Funk aktiv
    }
  }

  function renderRosterList(members) {
    const tbody = $('roster-table-body');
    tbody.innerHTML = '';
    const isLeader = activeFactionData.isLeader;
    const filter = ($('roster-search').value || '').toLowerCase();

    const filtered = members.filter(m => {
      return m.name.toLowerCase().includes(filter) || String(m.charId).includes(filter) || m.gradeLabel.toLowerCase().includes(filter);
    });

    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:1.2rem; color:#94a3b8;">Keine Mitglieder gefunden.</td></tr>';
      return;
    }

    filtered.forEach(m => {
      const tr = document.createElement('tr');
      const warnsHtml = m.suspended 
        ? '<span class="badge-suspended">SUSPENDIERT</span>' 
        : (m.warns > 0 ? `<span class="badge-warn">${m.warns}/3 Verwarnung</span>` : '<span style="color:#94a3b8; font-size:0.75rem;">0/3</span>');

      tr.innerHTML = `
        <td>
          <span class="status-pill">
            <span class="status-dot ${m.isOnline ? 'online' : ''}"></span>
            ${m.isOnline ? `Online (${m.serverId})` : 'Offline'}
          </span>
        </td>
        <td><strong>#${m.charId}</strong></td>
        <td>${escapeHtml(m.name)}</td>
        <td><span class="badge-kpi">${escapeHtml(m.gradeLabel)}</span></td>
        <td><span class="badge-dept">${escapeHtml(m.department || 'Streifendienst')}</span></td>
        <td>${warnsHtml}</td>
        <td style="text-align: right;">
          ${isLeader ? `
            <div class="roster-actions" style="justify-content: flex-end;">
              <button class="btn-table-action btn-m-act" data-act="promote" data-ident="${m.identifier}" title="Befördern">▲</button>
              <button class="btn-table-action btn-m-act" data-act="demote" data-ident="${m.identifier}" title="Degradieren">▼</button>
              <button class="btn-rank-edit btn-m-extra" data-act="set_dept" data-ident="${m.identifier}" title="Abteilung zuweisen">🏢</button>
              <button class="btn-rank-edit btn-m-extra" data-act="warn" data-ident="${m.identifier}" title="Verwarnung erteilen">⚠️</button>
              <button class="btn-rank-edit btn-m-extra" data-act="suspend" data-ident="${m.identifier}" title="Suspendieren">⏸️</button>
              <button class="btn-table-action action-kick btn-m-extra" data-act="expel" data-ident="${m.identifier}" title="Verweisen">⛔</button>
              <button class="btn-table-action action-kick btn-m-act" data-act="fire" data-ident="${m.identifier}" title="Kündigen">✕</button>
            </div>
          ` : '<span style="color:#94a3b8; font-size:0.75rem;">-</span>'}
        </td>
      `;
      tbody.appendChild(tr);
    });

    tbody.querySelectorAll('.btn-m-extra').forEach(btn => {
      btn.addEventListener('click', () => {
        const action = btn.getAttribute('data-act');
        const ident = btn.getAttribute('data-ident');

        if (action === 'set_dept') {
          const dept = prompt('Abteilung für diesen Beamten eingeben (z.B. Streifendienst, SWAT / SEK, K9 Hundestaffel, Ermittlung):', 'Streifendienst');
          if (!dept) return;
          post('stateManageMemberExtra', { factionId: activeFactionData.faction.id, targetIdentifier: ident, action: 'set_dept', department: dept, mode: currentFactionMode });
        } else if (action === 'warn') {
          post('stateManageMemberExtra', { factionId: activeFactionData.faction.id, targetIdentifier: ident, action: 'warn', mode: currentFactionMode });
        } else if (action === 'suspend') {
          post('stateManageMemberExtra', { factionId: activeFactionData.faction.id, targetIdentifier: ident, action: 'suspend', mode: currentFactionMode });
        } else if (action === 'expel') {
          post('stateManageMemberExtra', { factionId: activeFactionData.faction.id, targetIdentifier: ident, action: 'expel', mode: currentFactionMode });
        }
        showAlert('Mitgliederverwaltung', 'Aktion ausgeführt.');
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });

    tbody.querySelectorAll('.btn-m-act').forEach(btn => {
      btn.addEventListener('click', () => {
        const action = btn.getAttribute('data-act');
        const ident = btn.getAttribute('data-ident');
        post('memberAction', {
          factionName: activeFactionData.faction.name,
          targetIdentifier: ident,
          action: action
        });
        showAlert('Mitgliederverwaltung', 'Aktion ausgeführt.');
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  $('roster-search').addEventListener('input', () => {
    if (activeFactionData && activeFactionData.members) {
      renderRosterList(activeFactionData.members);
    }
  });

  // SUBVIEW ACTIONS EVENT LISTENERS

  // Hinweis speichern
  $('btn-save-notice').addEventListener('click', () => {
    if (!activeFactionData) return;
    const txt = $('notice-input').value;
    post('saveNotice', { factionId: activeFactionData.faction.id, notice: txt, mode: currentFactionMode });
    showAlert('Hinweis', 'Fraktionsankündigung gespeichert.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // Neues Mitglied einstellen
  $('btn-invite-member').addEventListener('click', () => {
    if (!activeFactionData) return;
    const val = $('invite-player-id').value;
    if (!val) { showAlert('Rekrutierung', 'Bitte gib eine gültige Spieler- oder Bürger-ID ein.'); return; }
    post('inviteMember', { factionName: activeFactionData.faction.name, targetId: val });
    $('invite-player-id').value = '';
    showAlert('Rekrutierung', 'Einstellungsauftrag übermittelt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // Einstellungen speichern
  $('btn-save-settings').addEventListener('click', () => {
    if (!activeFactionData) return;
    const radio = $('set-input-radio').value;
    const isOpen = ($('set-select-recruit').value === 'open');
    post('saveSettings', { factionId: activeFactionData.faction.id, radioFreq: radio, recruitOpen: isOpen });
    showAlert('Einstellungen', 'Einstellungen gespeichert.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // ---------- FRAKTIONS-RÄNGE VERWALTEN ----------
  function renderFactionRanks(grades, isLeader) {
    const tbody = $('ranks-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';

    const createBox = $('create-rank-box');
    if (createBox) createBox.style.display = isLeader ? 'flex' : 'none';

    if (!grades || grades.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; color:#94a3b8; padding:1.2rem;">Keine Ränge geladen.</td></tr>';
      return;
    }

    const sorted = [...grades].sort((a, b) => a.grade - b.grade);
    const maxGrade = Math.max(...sorted.map(g => g.grade));

    sorted.forEach(g => {
      const tr = document.createElement('tr');
      const isBoss = (g.grade === maxGrade);
      const isBase = (g.grade === 0);

      let gradeBadge = `<span class="badge-grade-num">Stufe ${g.grade}</span>`;
      if (isBoss) {
        gradeBadge = `<span class="badge-grade-num badge-grade-boss">👑 Rang ${g.grade} (Leitung)</span>`;
      } else if (isBase) {
        gradeBadge = `<span class="badge-grade-num badge-grade-base">Rang ${g.grade} (Basis)</span>`;
      }

      let actionsHtml = '';
      if (isLeader) {
        actionsHtml += `<button class="btn-rank-perms" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}">🛡️ Rechte (36)</button> `;
        actionsHtml += `<button class="btn-rank-edit" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}" data-salary="${g.salary}">✏️ Bearbeiten</button>`;
        if (!isBoss && !isBase) {
          actionsHtml += ` <button class="btn-rank-del" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}">🗑️</button>`;
        } else {
          actionsHtml += ` <span class="rank-badge-protected">Geschützt</span>`;
        }
      } else {
        actionsHtml = `<span class="rank-badge-protected">Nur Ansicht</span>`;
      }

      tr.innerHTML = `
        <td>${gradeBadge}</td>
        <td><strong>${escapeHtml(g.label)}</strong></td>
        <td><span class="rank-code-sub">${escapeHtml(g.name)}</span></td>
        <td><span class="rank-salary-pill">$${Number(g.salary).toLocaleString('de-DE')}</span></td>
        <td style="text-align: right;"><div class="rank-actions-flex">${actionsHtml}</div></td>
      `;
      tbody.appendChild(tr);
    });

    // Positions-Optionen für Erstellung aktualisieren
    const posSelect = $('rank-select-position');
    if (posSelect) {
      posSelect.innerHTML = `<option value="before_boss">Vor Leitungsrang (Stufe ${maxGrade}) [Empfohlen]</option>`;
      sorted.forEach(g => {
        if (g.grade > 0 && g.grade < maxGrade) {
          const opt = document.createElement('option');
          opt.value = g.grade;
          opt.textContent = `An Stufe ${g.grade} einfügen (nach "${g.label}")`;
          posSelect.appendChild(opt);
        }
      });
    }

    // Event Listener für Editieren & Löschen
    tbody.querySelectorAll('.btn-rank-perms').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = Number(btn.getAttribute('data-grade'));
        const label = btn.getAttribute('data-label');
        openRankPermissionsModal(grade, label);
      });
    });

    tbody.querySelectorAll('.btn-rank-edit').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = btn.getAttribute('data-grade');
        const label = btn.getAttribute('data-label');
        const salary = btn.getAttribute('data-salary');
        openEditRankModal(grade, label, salary);
      });
    });

    tbody.querySelectorAll('.btn-rank-del').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = Number(btn.getAttribute('data-grade'));
        const label = btn.getAttribute('data-label');
        post('deleteFactionRank', {
          factionId: activeFactionData.faction.id,
          grade: grade,
          mode: currentFactionMode
        });
        showAlert('Rang gelöscht', `Der Rang "${label}" (Stufe ${grade}) wurde gelöscht.`);
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  function openEditRankModal(grade, label, salary) {
    $('edit-rank-grade').value = grade;
    $('edit-rank-label').value = label;
    $('edit-rank-salary').value = salary;
    $('edit-rank-modal-title').textContent = `Rang bearbeiten (Stufe ${grade})`;
    $('modal-edit-rank').classList.remove('hidden');
  }

  function closeEditRankModal() {
    $('modal-edit-rank').classList.add('hidden');
  }

  $('btn-close-edit-rank').addEventListener('click', closeEditRankModal);
  $('btn-cancel-edit-rank').addEventListener('click', closeEditRankModal);

  $('btn-save-edit-rank').addEventListener('click', () => {
    if (!activeFactionData) return;
    const grade = $('edit-rank-grade').value;
    const label = $('edit-rank-label').value.trim();
    const salary = Number($('edit-rank-salary').value) || 0;

    if (!label) {
      showAlert('Fehler', 'Bitte gib eine Rang-Bezeichnung ein.');
      return;
    }

    post('updateFactionRank', {
      factionId: activeFactionData.faction.id,
      grade: grade,
      label: label,
      salary: salary,
      mode: currentFactionMode
    });

    closeEditRankModal();
    showAlert('Rang aktualisiert', `Rang ${grade} ("${label}") wurde gespeichert.`);
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  $('btn-create-rank').addEventListener('click', () => {
    if (!activeFactionData) return;
    const label = $('rank-input-label').value.trim();
    const salary = Number($('rank-input-salary').value) || 0;
    const pos = $('rank-select-position').value;

    if (!label) {
      showAlert('Fehler', 'Bitte gib eine Rang-Bezeichnung für den neuen Rang ein.');
      return;
    }

    post('createFactionRank', {
      factionId: activeFactionData.faction.id,
      label: label,
      salary: salary,
      position: pos,
      mode: currentFactionMode
    });

    $('rank-input-label').value = '';
    $('rank-input-salary').value = '350';
    showAlert('Rang angelegt', `Neuer Rang "${label}" wird angelegt...`);
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 500);
  });

  // Kasse Einzahlung Quick Chips
  document.querySelectorAll('.chip-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      $('vault-input-deposit').value = btn.getAttribute('data-amt');
    });
  });

  // Kasse einzahlen
  $('btn-vault-deposit').addEventListener('click', () => {
    if (!activeFactionData) return;
    const amt = $('vault-input-deposit').value;
    if (!amt || Number(amt) <= 0) { showAlert('Fraktionskasse', 'Bitte gib einen gültigen Einzahlungsbetrag ein.'); return; }
    post('depositVault', { factionName: activeFactionData.faction.name, amount: amt });
    $('vault-input-deposit').value = '';
    showAlert('Fraktionskasse', 'Einzahlung übermittelt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // Kasse abheben (Leader)
  $('btn-vault-withdraw').addEventListener('click', () => {
    if (!activeFactionData) return;
    const amt = $('vault-input-withdraw').value;
    if (!amt || Number(amt) <= 0) { showAlert('Fraktionskasse', 'Bitte gib einen gültigen Auszahlungsbetrag ein.'); return; }
    post('withdrawVault', { factionName: activeFactionData.faction.name, amount: amt });
    $('vault-input-withdraw').value = '';
    showAlert('Fraktionskasse', 'Auszahlung übermittelt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // Prämie überweisen
  $('btn-submit-bonus').addEventListener('click', () => {
    if (!activeFactionData) return;
    const target = $('bonus-select-target').value;
    const amt = $('bonus-input-amt').value;
    const reason = $('bonus-input-reason').value || 'Leistungsprämie';

    if (!target) { showAlert('Prämierung', 'Bitte wähle ein Mitglied aus.'); return; }
    if (!amt || Number(amt) <= 0) { showAlert('Prämierung', 'Bitte gib eine gültige Prämienhöhe ein.'); return; }

    post('giveBonus', {
      factionName: activeFactionData.faction.name,
      targetIdentifier: target,
      amount: amt,
      reason: reason
    });
    $('bonus-input-amt').value = '';
    $('bonus-input-reason').value = '';
    showAlert('Prämierung', 'Prämie erfolgreich überwiesen.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // Blacklist hinzufügen
  $('btn-add-blacklist').addEventListener('click', () => {
    if (!activeFactionData) return;
    const name = $('blacklist-name').value;
    const reason = $('blacklist-reason').value;
    if (!name) { showAlert('Blacklist', 'Bitte gib einen Namen oder Bürger-ID ein.'); return; }
    post('manageBlacklist', {
      factionId: activeFactionData.faction.id,
      action: 'add',
      name: name,
      reason: reason || 'Hausverbot'
    });
    $('blacklist-name').value = '';
    $('blacklist-reason').value = '';
    showAlert('Blacklist', 'Person zur Blacklist hinzugefügt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // ============================================================
  // APP CLICK HANDLERS
  // ============================================================

  // 1. FRAKTION
  $('app-faction').addEventListener('click', () => {
    if (!tabletData.faction || !tabletData.faction.inFaction) {
      showAlert('Fraktion', 'Du bist in keiner Fraktion.');
      return;
    }
    openFactionDashboard('faction');
  });

  // 2. FAMILIE
  $('app-family').addEventListener('click', () => {
    if (!tabletData.family || !tabletData.family.inFamily) {
      showAlert('Familie', 'Du bist in keiner Familie.');
      return;
    }
    openFactionDashboard('family');
  });

  // 3. MEIN HAUS
  $('app-house').addEventListener('click', () => {
    openApp('house', 'Mein Haus');
  });

  // 4. MEIN GESCHÄFT
  $('app-business').addEventListener('click', () => {
    openApp('business', 'Mein Geschäft');
  });

  // 5. MARKTPLATZ
  $('app-market').addEventListener('click', () => {
    openApp('market', 'Marktplatz');
  });

  // 6. 2048
  $('app-2048').addEventListener('click', () => {
    openApp('2048', '2048 Game');
  });

  // 7. ADMIN APP
  const appAdmin = $('app-admin');
  if (appAdmin) {
    appAdmin.addEventListener('click', () => {
      if (!tabletData.isAdmin) {
        showAlert('Admin', 'Keine Administrator-Berechtigung.');
        return;
      }
      openApp('admin', 'Administration');
      renderAdminPanel();
    });
  }

  // 8. BEWERBUNGEN APP
  const appApply = $('app-apply');
  if (appApply) {
    appApply.addEventListener('click', () => {
      openApp('apply', 'Bewerbungen');
    });
  }

  // Dock items delegation
  document.querySelectorAll('.dock-item').forEach(item => {
    item.addEventListener('click', () => {
      const target = item.getAttribute('data-launch');
      if (target === 'app-business') openApp('business', 'Mein Geschäft');
      else if (target === 'app-house') openApp('house', 'Mein Haus');
      else if (target === 'app-market') openApp('market', 'Marktplatz');
    });
  });

  // ---------- MONEY TRANSFER ----------
  $('btn-transfer').addEventListener('click', () => {
    const target = $('transfer-target').value;
    const amount = $('transfer-amount').value;
    if (!target || !amount || Number(amount) <= 0) {
      showAlert('Überweisung', 'Bitte gib eine gültige Spieler-ID und einen Betrag ein.');
      return;
    }
    post('dispatchAction', { action: 'transferMoney', target, amount });
    $('transfer-target').value = '';
    $('transfer-amount').value = '';
    showAlert('Überweisung', 'Transaktion gesendet.');
  });

  // ---------- DATA RENDERING ----------
  function renderData(data) {
    tabletData = data;

    // Admin App Visibility
    const adminApp = $('app-admin');
    if (adminApp) {
      if (data.isAdmin) {
        adminApp.classList.remove('hidden');
        adminApp.style.display = 'flex';
      } else {
        adminApp.classList.add('hidden');
        adminApp.style.display = 'none';
      }
    }

    // Faction label update on Desktop
    const factionLabel = $('label-faction');
    if (factionLabel) {
      if (data.faction && data.faction.inFaction) {
        factionLabel.textContent = data.faction.label;
      } else {
        factionLabel.textContent = 'Fraktion';
      }
    }

    // Family label update on Desktop
    const familyLabel = $('label-family');
    if (familyLabel) {
      if (data.family && data.family.inFamily) {
        familyLabel.textContent = data.family.label;
      } else {
        familyLabel.textContent = 'Familie';
      }
    }

    // Business App Details
    $('biz-bank').textContent = '$' + Number(data.accounts?.bank || 0).toLocaleString('de-DE');
    $('biz-cash').textContent = '$' + Number(data.accounts?.money || 0).toLocaleString('de-DE');

    const bizPlayerList = $('biz-player-list');
    if (bizPlayerList) {
      bizPlayerList.innerHTML = '';
      if (data.players && data.players.length > 0) {
        data.players.forEach(p => {
          const card = document.createElement('div');
          card.className = 'roster-card';
          card.innerHTML = `
            <div>
              <div class="name">${p.name} (ID: ${p.id})</div>
              <div class="job">${p.job}</div>
            </div>
            <button class="btn-subtle" onclick="document.getElementById('transfer-target').value = '${p.id}'">Wählen</button>
          `;
          bizPlayerList.appendChild(card);
        });
      }
    }

    // House App Details
    const houseList = $('house-list');
    if (houseList) {
      houseList.innerHTML = '';
      if (data.properties && data.properties.length > 0) {
        data.properties.forEach(h => {
          const card = document.createElement('div');
          card.className = 'house-card';
          card.innerHTML = `
            <h4>${h.label}</h4>
            <p>Status: ${h.rented ? 'Gemietet' : 'Gekauft'}</p>
            <div class="house-price">$${Number(h.price).toLocaleString('de-DE')}</div>
          `;
          houseList.appendChild(card);
        });
      } else {
        houseList.innerHTML = '<p style="color:#94a3b8; font-size:0.95rem; grid-column:span 2;">Keine registrierten Immobilien im Grundbuch gefunden.</p>';
      }
    }
  }

  // ---------- ADMIN PANEL LOGIC ----------
  function renderAdminPanel() {
    if ($('admin-panel-role')) {
      $('admin-panel-role').textContent = tabletData.adminRole || 'NOVA Administration';
    }

    const list = $('admin-players-list');
    if (list) {
      list.innerHTML = '';
      const players = tabletData.players || [];
      if (players.length === 0) {
        list.innerHTML = '<p style="color:#94a3b8; font-size:0.9rem; padding:0.5rem;">Keine weiteren Bürger online.</p>';
      } else {
        players.forEach(p => {
          const card = document.createElement('div');
          card.className = 'roster-card';
          card.innerHTML = `
            <div>
              <div class="name">${p.name} (ID: ${p.id})</div>
              <div class="job">${p.job}</div>
            </div>
            <div class="admin-player-btns">
              <button class="btn-admin-act btn-adm-goto" data-pid="${p.id}">Zu Spieler</button>
              <button class="btn-admin-act btn-adm-bring" data-pid="${p.id}">Zu mir</button>
              <button class="btn-admin-act act-kick btn-adm-kick" data-pid="${p.id}">Kicken</button>
            </div>
          `;
          list.appendChild(card);
        });

        list.querySelectorAll('.btn-adm-goto').forEach(btn => {
          btn.addEventListener('click', () => {
            const pid = btn.getAttribute('data-pid');
            post('adminQuickAction', { action: 'goto', targetId: pid });
          });
        });

        list.querySelectorAll('.btn-adm-bring').forEach(btn => {
          btn.addEventListener('click', () => {
            const pid = btn.getAttribute('data-pid');
            post('adminQuickAction', { action: 'bring', targetId: pid });
          });
        });

        list.querySelectorAll('.btn-adm-kick').forEach(btn => {
          btn.addEventListener('click', () => {
            const pid = btn.getAttribute('data-pid');
            post('adminQuickAction', { action: 'kick', targetId: pid, reason: 'Vom Tablet gekickt' });
          });
        });
      }
    }
  }

  const btnLaunchFullAdmin = $('btn-launch-full-admin');
  if (btnLaunchFullAdmin) {
    btnLaunchFullAdmin.addEventListener('click', () => {
      post('openFullAdmin');
    });
  }

  const btnAdminHeal = $('btn-admin-heal');
  if (btnAdminHeal) {
    btnAdminHeal.addEventListener('click', () => {
      post('adminQuickAction', { action: 'heal' });
      showAlert('Admin', 'Gesundheit, Hunger & Durst aufgefüllt.');
    });
  }

  const btnAdminRevive = $('btn-admin-revive');
  if (btnAdminRevive) {
    btnAdminRevive.addEventListener('click', () => {
      post('adminQuickAction', { action: 'revive' });
      showAlert('Admin', 'Wiederbelebung ausgeführt.');
    });
  }

  const btnAdminNoclip = $('btn-admin-noclip');
  if (btnAdminNoclip) {
    btnAdminNoclip.addEventListener('click', () => {
      post('adminQuickAction', { action: 'noclip' });
    });
  }

  const btnAdminWeather = $('btn-admin-weather');
  if (btnAdminWeather) {
    btnAdminWeather.addEventListener('click', () => {
      post('adminQuickAction', { action: 'weather' });
      showAlert('Admin', 'Berlin-Wetter & deutsche Zeit synchronisiert.');
    });
  }

  const btnAdminAnnounce = $('btn-admin-announce');
  if (btnAdminAnnounce) {
    btnAdminAnnounce.addEventListener('click', () => {
      const msg = $('admin-announce-input').value;
      if (!msg) {
        showAlert('Admin', 'Bitte gib eine Nachricht ein.');
        return;
      }
      post('adminQuickAction', { action: 'announce', message: msg });
      $('admin-announce-input').value = '';
      showAlert('Admin', 'Server-Ankündigung erfolgreich gesendet.');
    });
  }

  // ---------- WINDOW MESSAGE LISTENER ----------
  window.addEventListener('message', (event) => {
    const item = event.data;
    if (!item) return;

    if (item.action === 'openTablet') {
      closeApp();
      closeFactionDashboard();
      closeAlert();
      $('tablet-frame').classList.remove('hidden');
    } else if (item.action === 'closeTablet') {
      $('tablet-frame').classList.add('hidden');
      closeApp();
      closeFactionDashboard();
      closeAlert();
    } else if (item.action === 'updateData') {
      renderData(item.data || {});
    } else if (item.action === 'updateFactionDetails') {
      updateFactionDetails(item.data || {});
    }
  });

  // ============================================================
  // PLAYABLE 2048 GAME LOGIC
  // ============================================================
  const Game2048 = {
    grid: [],
    score: 0,
    best: 0,
    size: 4,
    eventsBound: false,

    init() {
      this.bindEvents();
      this.restart();
    },

    restart() {
      this.grid = Array(this.size).fill(null).map(() => Array(this.size).fill(0));
      this.score = 0;
      this.updateScore();
      this.addRandomTile();
      this.addRandomTile();
      this.draw();
    },

    addRandomTile() {
      const emptyCells = [];
      for (let r = 0; r < this.size; r++) {
        for (let c = 0; c < this.size; c++) {
          if (this.grid[r][c] === 0) emptyCells.push({ r, c });
        }
      }
      if (emptyCells.length === 0) return;
      const cell = emptyCells[Math.floor(Math.random() * emptyCells.length)];
      this.grid[cell.r][cell.c] = Math.random() < 0.9 ? 2 : 4;
    },

    updateScore() {
      $('score-val').textContent = this.score;
      if (this.score > this.best) {
        this.best = this.score;
        $('best-val').textContent = this.best;
      }
    },

    draw() {
      const container = $('grid-2048');
      container.innerHTML = '';
      for (let r = 0; r < this.size; r++) {
        for (let c = 0; c < this.size; c++) {
          const val = this.grid[r][c];
          const tile = document.createElement('div');
          tile.className = 'grid-cell';
          if (val > 0) {
            tile.classList.add(`tile-${val}`);
            tile.textContent = val;
          }
          container.appendChild(tile);
        }
      }
    },

    slide(row) {
      let arr = row.filter(val => val !== 0);
      for (let i = 0; i < arr.length - 1; i++) {
        if (arr[i] === arr[i + 1]) {
          arr[i] *= 2;
          this.score += arr[i];
          arr[i + 1] = 0;
        }
      }
      arr = arr.filter(val => val !== 0);
      while (arr.length < this.size) arr.push(0);
      return arr;
    },

    moveLeft() {
      let changed = false;
      for (let r = 0; r < this.size; r++) {
        const newRow = this.slide(this.grid[r]);
        if (newRow.some((val, idx) => val !== this.grid[r][idx])) changed = true;
        this.grid[r] = newRow;
      }
      if (changed) {
        this.addRandomTile();
        this.draw();
        this.updateScore();
      }
    },

    moveRight() {
      let changed = false;
      for (let r = 0; r < this.size; r++) {
        const reversed = [...this.grid[r]].reverse();
        const newRow = this.slide(reversed).reverse();
        if (newRow.some((val, idx) => val !== this.grid[r][idx])) changed = true;
        this.grid[r] = newRow;
      }
      if (changed) {
        this.addRandomTile();
        this.draw();
        this.updateScore();
      }
    },

    moveUp() {
      let changed = false;
      for (let c = 0; c < this.size; c++) {
        const col = [this.grid[0][c], this.grid[1][c], this.grid[2][c], this.grid[3][c]];
        const newCol = this.slide(col);
        for (let r = 0; r < this.size; r++) {
          if (this.grid[r][c] !== newCol[r]) changed = true;
          this.grid[r][c] = newCol[r];
        }
      }
      if (changed) {
        this.addRandomTile();
        this.draw();
        this.updateScore();
      }
    },

    moveDown() {
      let changed = false;
      for (let c = 0; c < this.size; c++) {
        const col = [this.grid[3][c], this.grid[2][c], this.grid[1][c], this.grid[0][c]];
        const newCol = this.slide(col);
        for (let r = 0; r < this.size; r++) {
          if (this.grid[3 - r][c] !== newCol[r]) changed = true;
          this.grid[3 - r][c] = newCol[r];
        }
      }
      if (changed) {
        this.addRandomTile();
        this.draw();
        this.updateScore();
      }
    },

    bindEvents() {
      if (this.eventsBound) return;
      this.eventsBound = true;

      $('restart-2048').addEventListener('click', () => this.restart());

      window.addEventListener('keydown', (e) => {
        if (currentOpenApp !== '2048') return;
        if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
          e.preventDefault();
          this.moveLeft();
        } else if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
          e.preventDefault();
          this.moveRight();
        } else if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') {
          e.preventDefault();
          this.moveUp();
        } else if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') {
          e.preventDefault();
          this.moveDown();
        }
      });
    }
  };

})();


  // ============================================================
  // RANG-ÜBERSICHT & BERECHTIGUNGEN PANEL
  // ============================================================
  function renderFactionRanksOverview() {
    const list = $('ranks-overview-list');
    if (!list) return;
    if (!activeFactionData) {
      list.innerHTML = '<p style="color:#94a3b8; padding:2rem; text-align:center;">Lade Dienstgrade...</p>';
      post('getFactionDetails', { mode: currentFactionMode });
      return;
    }
    const grades = activeFactionData.grades || [];
    const isLeader = activeFactionData.isLeader;

    list.innerHTML = '';

    const sorted = [...grades].sort((a, b) => a.grade - b.grade);
    const maxGradeNum = sorted.length > 0 ? Math.max(...sorted.map(g => g.grade)) : 4;
    const minGradeNum = sorted.length > 0 ? Math.min(...sorted.map(g => g.grade)) : 0;
    const bossRank = sorted.find(g => g.grade === maxGradeNum);
    const baseRank = sorted.find(g => g.grade === minGradeNum);

    // Stats aktualisieren
    if ($('ranks-stat-total')) $('ranks-stat-total').textContent = sorted.length;
    if ($('ranks-stat-boss')) $('ranks-stat-boss').textContent = bossRank ? `${bossRank.label} (Stufe ${maxGradeNum})` : '-';
    if ($('ranks-stat-base')) $('ranks-stat-base').textContent = baseRank ? `${baseRank.label} (Stufe ${minGradeNum})` : '-';

    // Position Select in Erstellungs-Box aktualisieren
    const posSelect = $('ranks-new-position');
    if (posSelect) {
      posSelect.innerHTML = `<option value="before_boss">Vor Leitungsrang (Stufe ${maxGradeNum}) [Empfohlen]</option>`;
      sorted.forEach(g => {
        if (g.grade > 0 && g.grade < maxGradeNum) {
          const opt = document.createElement('option');
          opt.value = g.grade;
          opt.textContent = `An Stufe ${g.grade} einfügen (nach "${g.label}")`;
          posSelect.appendChild(opt);
        }
      });
    }

    // Button Neuer Rang anzeigen/verstecken
    const toggleBtn = $('btn-toggle-create-rank');
    if (toggleBtn) toggleBtn.style.display = isLeader ? 'flex' : 'none';

    if (sorted.length === 0) {
      list.innerHTML = '<p style="color:#94a3b8; padding:2rem; text-align:center;">Keine Ränge in dieser Organisation gefunden.</p>';
      return;
    }

    const totalPermsCount = STATE_PERMISSIONS.length;

    sorted.forEach(g => {
      const isBoss = (g.grade === maxGradeNum);
      const isBase = (g.grade === minGradeNum);

      // Aktive Berechtigungen für diesen Rang berechnen
      let activePerms = [];
      if (activeFactionData.rankPermissions && activeFactionData.rankPermissions[String(g.grade)]) {
        activePerms = activeFactionData.rankPermissions[String(g.grade)];
      } else if (isBoss) {
        activePerms = STATE_PERMISSIONS.map(p => p.key);
      } else if (g.grade === 0) {
        activePerms = ['vehicles_spawn', 'storage_use', 'crafting_use', 'department_radio', 'doors_control', 'vehicles_respawn'];
      } else {
        activePerms = ['vehicles_spawn', 'storage_use', 'crafting_use', 'department_radio', 'doors_control', 'vehicles_respawn',
                       'database_use', 'fines_issue', 'jail_player', 'records_create', 'vehicles_impound',
                       'vehicle_search_report', 'vault_deposit', 'materials_order', 'airdrops_open'];
        if (g.grade >= 2) {
          activePerms.push('licenses_give', 'gnews_access', 'storage_manage', 'warns_manage', 'departments_assign', 'outfits_edit', 'private_outfits_edit');
        }
        if (g.grade >= 3) {
          activePerms.push('invite', 'kick', 'ranks_manage', 'jail_long', 'licenses_revoke');
        }
      }

      const activePermCount = isBoss ? totalPermsCount : activePerms.length;

      // Vorschau-Chips für Kernfunktionen
      const previewChips = [];
      if (isBoss || activePerms.includes('vehicles_spawn') || activePerms.includes('vehicles_respawn')) {
        previewChips.push('<span class="chip-badge chip-veh">🚗 Fuhrpark</span>');
      }
      if (isBoss || activePerms.includes('storage_use') || activePerms.includes('storage_manage')) {
        previewChips.push('<span class="chip-badge chip-storage">📦 Waffenlager</span>');
      }
      if (isBoss || activePerms.includes('vault_deposit') || activePerms.includes('vault_withdraw')) {
        previewChips.push('<span class="chip-badge chip-vault">💰 Fraktionskasse</span>');
      }
      if (isBoss || activePerms.includes('invite') || activePerms.includes('kick')) {
        previewChips.push('<span class="chip-badge chip-recruit">👥 Personal &amp; Einladen</span>');
      }
      if (isBoss || activePerms.includes('ranks_manage')) {
        previewChips.push('<span class="chip-badge chip-ranks">👑 Ränge verwalten</span>');
      }
      if (isBoss || activePerms.includes('airdrops_open')) {
        previewChips.push('<span class="chip-badge chip-airdrop">📦 Schmuggel-Airdrop</span>');
      }
      if (isBoss || activePerms.includes('database_use') || activePerms.includes('records_create')) {
        previewChips.push('<span class="chip-badge chip-police">⚖️ MDC &amp; Akten</span>');
      }

      const card = document.createElement('div');
      card.className = `rank-overview-card ${isBoss ? 'rank-card-boss' : ''}`;

      card.innerHTML = `
        <div class="rank-card-header">
          <div class="rank-badge-wrap">
            ${isBoss ? '<span class="badge-crown">👑 Leitungsrang (Boss)</span>' : `<span class="badge-grade-level">Stufe ${g.grade}</span>`}
            <span class="rank-sysname">System: <code>${escapeHtml(g.name)}</code></span>
          </div>
          <div class="rank-salary-tag">
            💰 $${Number(g.salary).toLocaleString('de-DE')} <span style="font-size:0.75rem; opacity:0.75; font-weight:500;">/ Payday</span>
          </div>
        </div>

        <div class="rank-card-body">
          <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap;">
            <div>
              <h4 class="rank-card-title">${escapeHtml(g.label)}</h4>
              <div class="rank-perms-summary">
                <span class="perms-count-chip ${isBoss ? 'perms-all' : ''}">
                  🛡️ ${isBoss ? `Alle ${totalPermsCount} Berechtigungen aktiv` : `${activePermCount} / ${totalPermsCount} Berechtigungen aktiv`}
                </span>
              </div>
            </div>
          </div>

          <div class="perms-chips-preview" style="margin-top:0.75rem; display:flex; flex-wrap:wrap; gap:0.4rem;">
            ${previewChips.join('')}
          </div>
        </div>

        <div class="rank-card-actions">
          <button class="f-btn-primary btn-rank-perms-action" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}">
            🛡️ Berechtigungen anpassen (${activePermCount})
          </button>
          ${isLeader ? `
            <button class="f-btn-secondary btn-rank-edit-action" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}" data-salary="${g.salary}">
              ✏️ Bearbeiten
            </button>
            ${(!isBoss && !isBase) ? `
              <button class="f-btn-danger btn-rank-del-action" data-grade="${g.grade}" data-label="${escapeHtml(g.label)}" style="background:#dc2626; color:#fff; border:none; padding:0.5rem 0.8rem; border-radius:0.55rem; cursor:pointer; font-weight:600;">
                🗑️ Löschen
              </button>
            ` : '<span class="rank-badge-protected">Geschützt</span>'}
          ` : '<span class="rank-badge-protected">Nur Ansicht</span>'}
        </div>
      `;

      list.appendChild(card);
    });

    // Event Listener für Berechtigungen Modal
    list.querySelectorAll('.btn-rank-perms-action').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = Number(btn.getAttribute('data-grade'));
        const label = btn.getAttribute('data-label');
        openRankPermissionsModal(grade, label);
      });
    });

    // Event Listener für Bearbeiten
    list.querySelectorAll('.btn-rank-edit-action').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = btn.getAttribute('data-grade');
        const label = btn.getAttribute('data-label');
        const salary = btn.getAttribute('data-salary');
        openEditRankModal(grade, label, salary);
      });
    });

    // Event Listener für Löschen
    list.querySelectorAll('.btn-rank-del-action').forEach(btn => {
      btn.addEventListener('click', () => {
        const grade = Number(btn.getAttribute('data-grade'));
        const label = btn.getAttribute('data-label');
        post('deleteFactionRank', {
          factionId: activeFactionData.faction.id,
          grade: grade,
          mode: currentFactionMode
        });
        showAlert('Rang gelöscht', `Rang "${label}" (Stufe ${grade}) wurde gelöscht.`);
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  // Neuer Rang Erstellungs-Box Umschalter
  const toggleRankCreateBtn = $('btn-toggle-create-rank');
  if (toggleRankCreateBtn) {
    toggleRankCreateBtn.addEventListener('click', () => {
      const box = $('ranks-create-box');
      if (box) box.classList.toggle('hidden');
    });
  }

  const cancelRankCreateBtn = $('btn-cancel-ranks-create');
  if (cancelRankCreateBtn) {
    cancelRankCreateBtn.addEventListener('click', () => {
      const box = $('ranks-create-box');
      if (box) box.classList.add('hidden');
    });
  }

  const submitRankCreateBtn = $('btn-submit-ranks-create');
  if (submitRankCreateBtn) {
    submitRankCreateBtn.addEventListener('click', () => {
      if (!activeFactionData) {
        showAlert('Fehler', 'Fraktionsdaten werden noch geladen. Bitte kurz warten.');
        post('getFactionDetails', { mode: currentFactionMode });
        return;
      }
      const label = ($('ranks-new-label').value || '').trim();
      const salary = Number($('ranks-new-salary').value || 350);
      const pos = $('ranks-new-position').value;

      if (!label || label.length < 2) {
        showAlert('Fehler', 'Bitte eine gültige Rangbezeichnung eingeben.');
        return;
      }

      post('createFactionRank', {
        factionId: activeFactionData.faction.id,
        label: label,
        salary: salary,
        position: pos,
        mode: currentFactionMode
      });

      $('ranks-new-label').value = '';
      const box = $('ranks-create-box');
      if (box) box.classList.add('hidden');
      showAlert('Rang erstellt', `Neuer Rang "${label}" wurde erfolgreich angelegt.`);
      setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
    });
  }

  // ============================================================
  // BERECHTIGUNGS-MODAL (36 STATE RECHTE)
  // ============================================================
  let currentPermsGrade = null;

  function openRankPermissionsModal(grade, label) {
    if (!activeFactionData) return;
    currentPermsGrade = grade;
    $('perm-modal-title').textContent = `🛡️ Berechtigungen: ${label} (Stufe ${grade})`;

    const sorted = [...(activeFactionData.grades || [])].sort((a, b) => a.grade - b.grade);
    const maxGrade = Math.max(...sorted.map(g => g.grade));
    const isBoss = (grade === maxGrade);

    if (isBoss) {
      $('perm-modal-subtitle').textContent = '👑 Leitungsrang: Besitzt dauerhaft alle 36 Berechtigungen.';
    } else {
      $('perm-modal-subtitle').textContent = 'Wähle die erlaubten Befugnisse und Berechtigungen für diesen Rang.';
    }

    // Aktive Rechte ermitteln
    let activeList = [];
    if (activeFactionData.rankPermissions && activeFactionData.rankPermissions[String(grade)]) {
      activeList = activeFactionData.rankPermissions[String(grade)];
    } else if (isBoss) {
      activeList = STATE_PERMISSIONS.map(p => p.key);
    } else if (grade === 0) {
      activeList = ['storage_use', 'crafting_use', 'department_radio', 'doors_control', 'vehicles_respawn'];
    } else if (grade >= 1) {
      activeList = ['storage_use', 'crafting_use', 'department_radio', 'doors_control', 'vehicles_respawn',
                    'database_use', 'fines_issue', 'jail_player', 'records_create', 'vehicles_impound',
                    'vehicle_search_report', 'vault_deposit', 'materials_order', 'airdrops_open'];
      if (grade >= 2) {
        activeList.push('licenses_give', 'gnews_access', 'storage_manage', 'warns_manage', 'departments_assign', 'outfits_edit', 'private_outfits_edit');
      }
    }

    renderPermissionsCheckboxes(activeList, isBoss);
    $('modal-rank-permissions').classList.remove('hidden');
  }

  function renderPermissionsCheckboxes(activeList, isBoss) {
    const container = $('perm-checkboxes-container');
    container.innerHTML = '';
    const filterText = ($('perm-search-input').value || '').toLowerCase();

    // Nach 6 Kategorien gruppieren
    const groups = {};
    STATE_PERMISSIONS.forEach(p => {
      if (!groups[p.cat]) groups[p.cat] = [];
      groups[p.cat].push(p);
    });

    let totalChecked = 0;

    Object.keys(PERM_CATEGORIES).forEach(catKey => {
      const perms = groups[catKey] || [];
      const filtered = perms.filter(p => p.label.toLowerCase().includes(filterText) || p.key.includes(filterText));
      if (filtered.length === 0) return;

      const card = document.createElement('div');
      card.className = 'perm-category-card';
      let html = `<div class="perm-category-title">${PERM_CATEGORIES[catKey]}</div><div class="perm-grid">`;

      filtered.forEach(p => {
        const isChecked = isBoss || activeList.includes(p.key);
        if (isChecked) totalChecked++;
        html += `
          <label class="perm-item">
            <input type="checkbox" class="perm-checkbox" data-key="${p.key}" ${isChecked ? 'checked' : ''} ${isBoss ? 'disabled' : ''}>
            <span>${escapeHtml(p.label)}</span>
          </label>
        `;
      });

      html += '</div>';
      card.innerHTML = html;
      container.appendChild(card);
    });

    $('perm-active-count').textContent = `${totalChecked} / ${STATE_PERMISSIONS.length} aktiv`;

    // Checkbox change listener
    container.querySelectorAll('.perm-checkbox').forEach(cb => {
      cb.addEventListener('change', updatePermsCount);
    });
  }

  function updatePermsCount() {
    const checked = document.querySelectorAll('.perm-checkbox:checked').length;
    $('perm-active-count').textContent = `${checked} / ${STATE_PERMISSIONS.length} aktiv`;
  }

  $('perm-search-input').addEventListener('input', () => {
    const checkedKeys = Array.from(document.querySelectorAll('.perm-checkbox:checked')).map(cb => cb.getAttribute('data-key'));
    const isBoss = (currentPermsGrade !== null && activeFactionData && currentPermsGrade >= Math.max(...activeFactionData.grades.map(g => g.grade)));
    renderPermissionsCheckboxes(checkedKeys, isBoss);
  });

  $('btn-perm-select-all').addEventListener('click', () => {
    document.querySelectorAll('.perm-checkbox:not(:disabled)').forEach(cb => cb.checked = true);
    updatePermsCount();
  });

  $('btn-perm-deselect-all').addEventListener('click', () => {
    document.querySelectorAll('.perm-checkbox:not(:disabled)').forEach(cb => cb.checked = false);
    updatePermsCount();
  });

  function closeRankPermissionsModal() {
    $('modal-rank-permissions').classList.add('hidden');
    currentPermsGrade = null;
  }

  $('btn-close-perm-modal').addEventListener('click', closeRankPermissionsModal);
  $('btn-cancel-perm-modal').addEventListener('click', closeRankPermissionsModal);

  $('btn-save-perm-modal').addEventListener('click', () => {
    if (currentPermsGrade === null || !activeFactionData) return;
    const selectedKeys = Array.from(document.querySelectorAll('.perm-checkbox:checked')).map(cb => cb.getAttribute('data-key'));

    post('saveRankPermissions', {
      factionId: activeFactionData.faction.id,
      grade: currentPermsGrade,
      permissions: selectedKeys,
      mode: currentFactionMode
    });

    closeRankPermissionsModal();
    showAlert('Berechtigungen gespeichert', `Berechtigungen für Stufe ${currentPermsGrade} wurden aktualisiert.`);
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  // ============================================================
  // STATE PANELS RENDERING & EVENTS
  // ============================================================

  // MDC & STRAFREGISTER
  function renderMdcRecords() {
    const tbody = $('mdc-records-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';
    const records = activeFactionData.records || [];
    const filter = ($('mdc-search-input').value || '').toLowerCase();

    const filtered = records.filter(r => {
      return (r.citizen_name || '').toLowerCase().includes(filter) ||
             String(r.char_id || '').includes(filter) ||
             (r.reason || '').toLowerCase().includes(filter);
    });

    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:1.2rem; color:#94a3b8;">Keine Einträge im Strafregister gefunden.</td></tr>';
      return;
    }

    filtered.forEach(r => {
      const tr = document.createElement('tr');
      const dateStr = r.created_at ? new Date(r.created_at).toLocaleDateString('de-DE', { hour: '2-digit', minute: '2-digit' }) : 'Kürzlich';
      tr.innerHTML = `
        <td style="font-size:0.8rem; color:#64748b;">${dateStr}</td>
        <td><strong>#${r.char_id || '?'}</strong> ${escapeHtml(r.citizen_name || 'Bürger')}</td>
        <td>${escapeHtml(r.reason || '-')}</td>
        <td><span class="rank-salary-pill" style="color:#b91c1c; background:#fee2e2;">$${Number(r.fine || 0).toLocaleString('de-DE')}</span></td>
        <td><span class="badge-grade-num">${r.jail_time || 0} Min.</span></td>
        <td style="font-size:0.82rem; color:#475569;">${escapeHtml(r.officer_name || 'System')}</td>
        <td style="text-align:right;">
          <button class="btn-rank-del btn-del-record" data-rid="${r.id}">🗑️</button>
        </td>
      `;
      tbody.appendChild(tr);
    });

    tbody.querySelectorAll('.btn-del-record').forEach(btn => {
      btn.addEventListener('click', () => {
        const rid = btn.getAttribute('data-rid');
        post('stateManageRecord', { action: 'delete', factionId: activeFactionData.faction.id, recordId: rid, mode: currentFactionMode });
        showAlert('Strafregister', 'Eintrag gelöscht.');
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  $('btn-mdc-new-record').addEventListener('click', () => {
    $('mdc-create-form-box').classList.toggle('hidden');
  });

  $('btn-cancel-mdc').addEventListener('click', () => {
    $('mdc-create-form-box').classList.add('hidden');
  });

  $('btn-submit-mdc-record').addEventListener('click', () => {
    const charId = $('mdc-input-charid').value;
    const fine = $('mdc-input-fine').value || 0;
    const jail = $('mdc-input-jail').value || 0;
    const reason = $('mdc-input-reason').value.trim();

    if (!charId || !reason) {
      showAlert('Fehler', 'Bitte gib eine Bürger-ID und den Tatbestand an.');
      return;
    }

    post('stateManageRecord', {
      action: 'create',
      factionId: activeFactionData.faction.id,
      targetCharId: charId,
      fine: fine,
      jailTime: jail,
      reason: reason,
      mode: currentFactionMode
    });

    $('mdc-input-charid').value = '';
    $('mdc-input-reason').value = '';
    $('mdc-create-form-box').classList.add('hidden');
    showAlert('Strafregister', 'Akte wird angelegt...');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  $('mdc-search-input').addEventListener('input', renderMdcRecords);

  // JUSTIZ & LIZENZEN
  function renderJusticePanel() {
    const selectEl = $('lic-select-target');
    if (selectEl) {
      selectEl.innerHTML = '<option value="">-- Bürger auswählen --</option>';
      (activeFactionData.members || []).forEach(m => {
        const opt = document.createElement('option');
        opt.value = m.identifier;
        opt.textContent = `${m.name} (#${m.charId})`;
        selectEl.appendChild(opt);
      });
    }
  }

  $('btn-issue-fine').addEventListener('click', () => {
    const charId = $('fine-input-charid').value;
    const amt = $('fine-input-amt').value;
    const reason = $('fine-input-reason').value.trim();

    if (!charId || !amt || !reason) {
      showAlert('Fehler', 'Bitte Bürger-ID, Betrag und Grund angeben.');
      return;
    }

    post('stateIssueFine', {
      factionId: activeFactionData.faction.id,
      targetCharId: charId,
      amount: amt,
      reason: reason,
      mode: currentFactionMode
    });

    $('fine-input-charid').value = '';
    $('fine-input-amt').value = '';
    $('fine-input-reason').value = '';
    showAlert('Geldstrafe', 'Geldstrafe ausgestellt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  $('btn-issue-jail').addEventListener('click', () => {
    const charId = $('jail-input-charid').value;
    const minutes = $('jail-input-minutes').value;
    const reason = $('jail-input-reason').value.trim();

    if (!charId || !minutes || !reason) {
      showAlert('Fehler', 'Bitte Bürger-ID, Haftzeit und Grund angeben.');
      return;
    }

    post('stateJailPlayer', {
      factionId: activeFactionData.faction.id,
      targetCharId: charId,
      minutes: minutes,
      reason: reason,
      mode: currentFactionMode
    });

    $('jail-input-charid').value = '';
    $('jail-input-minutes').value = '';
    $('jail-input-reason').value = '';
    showAlert('Inhaftierung', 'Inhaftierungsbefehl übermittelt.');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  $('btn-give-license').addEventListener('click', () => {
    const target = $('lic-select-target').value;
    const licType = $('lic-select-type').value;
    if (!target) { showAlert('Fehler', 'Bitte einen Bürger auswählen.'); return; }

    post('stateManageLicense', {
      action: 'give',
      factionId: activeFactionData.faction.id,
      targetIdentifier: target,
      licenseType: licType,
      mode: currentFactionMode
    });
    showAlert('Lizenz', `Lizenz "${licType}" erteilt.`);
  });

  $('btn-revoke-license').addEventListener('click', () => {
    const target = $('lic-select-target').value;
    const licType = $('lic-select-type').value;
    if (!target) { showAlert('Fehler', 'Bitte einen Bürger auswählen.'); return; }

    post('stateManageLicense', {
      action: 'revoke',
      factionId: activeFactionData.faction.id,
      targetIdentifier: target,
      licenseType: licType,
      mode: currentFactionMode
    });
    showAlert('Lizenz', `Lizenz "${licType}" entzogen.`);
  });

  // FUHRPARK & LOGISTIK
  $('btn-respawn-vehicles').addEventListener('click', () => {
    post('stateRespawnVehicles', { factionId: activeFactionData.faction.id, mode: currentFactionMode });
    showAlert('Fuhrpark', 'Befehl zum Fuhrpark-Respawn übermittelt.');
  });

  document.querySelectorAll('.btn-order-mat').forEach(btn => {
    btn.addEventListener('click', () => {
      const type = btn.getAttribute('data-type');
      const cost = btn.getAttribute('data-cost');
      showAlert('Materialbestellung', `Bestellung für ${type.toUpperCase()} ($${Number(cost).toLocaleString('de-DE')}) übermittelt.`);
    });
  });

  $('btn-open-state-storage').addEventListener('click', () => {
    showAlert('Fraktionslager', 'Fraktionslager wird über ox_inventory geöffnet...');
  });

  $('btn-open-state-crafting').addEventListener('click', () => {
    showAlert('Crafting', 'Dienstwerkbank & Crafting geöffnet.');
  });

  // GNEWS & FUNK
  $('btn-broadcast-gnews').addEventListener('click', () => {
    const text = $('gnews-input-text').value.trim();
    if (!text) { showAlert('Fehler', 'Bitte gib eine Meldung ein.'); return; }

    post('stateBroadcastGNews', {
      factionId: activeFactionData.faction.id,
      message: text,
      mode: currentFactionMode
    });

    $('gnews-input-text').value = '';
    showAlert('GNews', 'Eilmeldung landesweit ausgestrahlt!');
  });

  $('btn-connect-dept-radio').addEventListener('click', () => {
    showAlert('Departmentfunk', 'Funkgerät auf Departmentfunk (100.0 MHz) eingestellt.');
  });

  // Massenauszahlung
  $('btn-vault-mass-payout').addEventListener('click', () => {
    if (!activeFactionData) return;
    const amt = Number($('vault-input-mass-amt').value) || 0;
    if (amt <= 0) { showAlert('Massenauszahlung', 'Bitte einen gültigen Betrag angeben.'); return; }
    post('stateMassPayout', { factionId: activeFactionData.faction.id, amountPerMember: amt, mode: currentFactionMode });
    showAlert('Massenauszahlung', `Massenauszahlung von $${amt.toLocaleString('de-DE')} pro Kopf übermittelt.`);
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });


  // ============================================================
  // BEWERBUNGSPORTAL APP LOGIK
  // ============================================================
  let applyPortalData = null;
  let selectedApplyFaction = null;

  function loadApplyPortal() {
    post('getApplicationData', {}, (res) => {
      applyPortalData = res || { factions: [], myApplications: [] };
      renderApplyFactions();
      renderMyApplications();
    });
  }

  function renderApplyFactions() {
    const list = $('apply-factions-list');
    if (!list) return;
    list.innerHTML = '';
    const factions = (applyPortalData && applyPortalData.factions) || [];

    if (factions.length === 0) {
      list.innerHTML = '<p style="color:#94a3b8; padding:1rem;">Keine Fraktionen oder Behörden gefunden.</p>';
      return;
    }

    factions.forEach(f => {
      const card = document.createElement('div');
      const isOpen = (f.recruit_open == 1 || f.recruit_open === true || f.recruit_open === '1');
      card.className = `apply-faction-card ${selectedApplyFaction === f.job_name ? 'selected' : ''}`;
      const typeBadge = (f.type === 'state')
        ? '<span class="badge-dept" style="margin-left:0.5rem; background:#0284c7; color:#fff;">Staat</span>'
        : '<span class="badge-dept" style="margin-left:0.5rem; background:#7c3aed; color:#fff;">Organisation</span>';

      card.innerHTML = `
        <div>
          <div class="apply-faction-title">${escapeHtml(f.label)} ${typeBadge}</div>
          <span class="apply-faction-status ${isOpen ? 'apply-status-open' : 'apply-status-closed'}">
            ${isOpen ? '🟢 Bewerbungen geöffnet' : '🔴 Bewerbungen geschlossen'}
          </span>
        </div>
        <button class="f-btn-primary" style="margin-top:0.8rem; font-size:0.8rem; padding:0.4rem 0.6rem;">${isOpen ? 'Bewerben' : 'Auswählen'}</button>
      `;

      card.addEventListener('click', () => {
        selectedApplyFaction = f.job_name;
        document.querySelectorAll('.apply-faction-card').forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');

        $('apply-selected-title').textContent = `Bewerbung einreichen bei: ${f.label} (${isOpen ? '🟢 Offen' : '🔴 Geschlossen'})`;
        $('apply-selected-faction').value = f.job_name;
        $('apply-form-box').style.display = 'block';
      });

      list.appendChild(card);
    });
  }

  function renderMyApplications() {
    const tbody = $('my-applications-tbody');
    tbody.innerHTML = '';
    const myApps = (applyPortalData && applyPortalData.myApplications) || [];

    if (myApps.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:1.2rem; color:#94a3b8;">Du hast bisher keine Bewerbungen eingereicht.</td></tr>';
      return;
    }

    myApps.forEach(a => {
      const tr = document.createElement('tr');
      const dateStr = a.created_at ? new Date(a.created_at).toLocaleDateString('de-DE') : 'Kürzlich';
      let statusBadge = '<span class="badge-status-pending">⏳ In Prüfung</span>';
      if (a.status === 'invited') {
        statusBadge = '<span class="badge-status-invited">✅ Zum Vorstellungsgespräch eingeladen</span>';
      } else if (a.status === 'rejected') {
        statusBadge = '<span class="badge-status-rejected">❌ Abgelehnt</span>';
      }

      tr.innerHTML = `
        <td>${dateStr}</td>
        <td><strong>${escapeHtml(a.target_faction.toUpperCase())}</strong></td>
        <td>${escapeHtml(a.phone_number || '-')}</td>
        <td>${statusBadge}</td>
        <td style="color:#64748b; font-size:0.82rem;">${escapeHtml(a.reviewer_name || 'Ausstehend')}</td>
      `;
      tbody.appendChild(tr);
    });
  }

  $('btn-submit-application').addEventListener('click', () => {
    const targetFaction = $('apply-selected-faction').value;
    const phone = $('apply-phone').value.trim();
    const drive = $('apply-drive-lic').value === '1';
    const weapon = $('apply-weapon-lic').value === '1';
    const letter = $('apply-letter').value.trim();
    const exp = $('apply-exp').value.trim();

    if (!targetFaction) { showAlert('Fehler', 'Bitte wähle zuerst eine Behörde aus.'); return; }
    if (!letter) { showAlert('Fehler', 'Bitte verfasse ein Anschreiben.'); return; }

    post('submitApplication', {
      targetFaction: targetFaction,
      phone: phone,
      hasDrive: drive,
      hasWeapon: weapon,
      letter: letter,
      experience: exp
    });

    $('apply-letter').value = '';
    $('apply-exp').value = '';
    $('apply-form-box').style.display = 'none';
    showAlert('Bewerbung übermittelt', 'Deine Bewerbung wurde erfolgreich bei der Behörde eingereicht!');
    setTimeout(loadApplyPortal, 500);
  });

  const btnRefreshApply = $('btn-refresh-apply');
  if (btnRefreshApply) {
    btnRefreshApply.addEventListener('click', () => {
      loadApplyPortal();
    });
  }


  // ============================================================
  // FAHNDUNGEN & WANTEDS (ALPR) IM MDC
  // ============================================================
  $('tab-btn-records').addEventListener('click', () => {
    $('tab-btn-records').classList.add('active');
    $('tab-btn-wanteds').classList.remove('active');
    $('mdc-view-records').classList.remove('hidden');
    $('mdc-view-wanteds').classList.add('hidden');
  });

  $('tab-btn-wanteds').addEventListener('click', () => {
    $('tab-btn-wanteds').classList.add('active');
    $('tab-btn-records').classList.remove('active');
    $('mdc-view-wanteds').classList.remove('hidden');
    $('mdc-view-records').classList.add('hidden');
    renderWanteds();
  });

  function renderWanteds() {
    const tbody = $('wanteds-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';
    const wanteds = activeFactionData.wanteds || [];
    const filter = ($('wanteds-search-input').value || '').toLowerCase();

    const filtered = wanteds.filter(w => {
      return (w.citizen_name || '').toLowerCase().includes(filter) ||
             (w.plate || '').toLowerCase().includes(filter) ||
             String(w.char_id || '').includes(filter) ||
             (w.reason || '').toLowerCase().includes(filter);
    });

    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:1.2rem; color:#94a3b8;">Keine aktiven Fahndungen im System.</td></tr>';
      return;
    }

    filtered.forEach(w => {
      const tr = document.createElement('tr');
      const starsDisplay = '★'.repeat(w.stars || 1);
      const isHighDanger = (w.danger_level && w.danger_level.includes('Schwer'));

      tr.innerHTML = `
        <td><span class="badge-stars">${starsDisplay}</span></td>
        <td><strong>#${w.char_id || '?'}</strong> ${escapeHtml(w.citizen_name || 'Unbekannt')}</td>
        <td><span class="rank-code-sub" style="font-weight:700;">${escapeHtml(w.plate || 'OHNE KFZ')}</span></td>
        <td>${escapeHtml(w.reason || 'Gesucht')}</td>
        <td><span class="${isHighDanger ? 'badge-danger-high' : 'badge-dept'}">${escapeHtml(w.danger_level || 'Normal')}</span></td>
        <td style="color:#64748b; font-size:0.82rem;">${escapeHtml(w.officer_name || 'System')}</td>
        <td style="text-align:right;">
          <button class="btn-rank-del btn-del-wanted" data-wid="${w.id}" title="Fahndung aufheben">🗑️</button>
        </td>
      `;
      tbody.appendChild(tr);
    });

    tbody.querySelectorAll('.btn-del-wanted').forEach(btn => {
      btn.addEventListener('click', () => {
        const wid = btn.getAttribute('data-wid');
        post('deleteWanted', { wantedId: wid, factionId: activeFactionData.faction.id, mode: currentFactionMode });
        showAlert('Fahndung', 'Fahndung wurde aufgehoben.');
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  $('btn-new-wanted-toggle').addEventListener('click', () => {
    $('wanted-create-form-box').classList.toggle('hidden');
  });

  $('btn-cancel-wanted').addEventListener('click', () => {
    $('wanted-create-form-box').classList.add('hidden');
  });

  $('btn-submit-wanted').addEventListener('click', () => {
    const charId = $('wanted-input-charid').value;
    const plate = $('wanted-input-plate').value.trim();
    const stars = $('wanted-input-stars').value;
    const reason = $('wanted-input-reason').value.trim();
    const danger = $('wanted-input-danger').value;

    if (!reason) { showAlert('Fehler', 'Bitte gib einen Fahndungsgrund an.'); return; }

    post('createWanted', {
      factionId: activeFactionData.faction.id,
      charId: charId,
      plate: plate,
      stars: stars,
      reason: reason,
      dangerLevel: danger,
      mode: currentFactionMode
    });

    $('wanted-input-charid').value = '';
    $('wanted-input-plate').value = '';
    $('wanted-input-reason').value = '';
    $('wanted-create-form-box').classList.add('hidden');
    showAlert('Fahndung', 'Fahndung wurde im ALPR-System erfasst!');
    setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
  });

  $('wanteds-search-input').addEventListener('input', renderWanteds);


  // ============================================================
  // TURF & TERRITORIEN (GANGWARS)
  // ============================================================
  function renderTurfsGrid() {
    const grid = $('territories-grid');
    if (!grid) return;
    grid.innerHTML = '';
    const turfs = activeFactionData.turfs || [];
    const myJob = activeFactionData.faction.name;

    if (turfs.length === 0) {
      grid.innerHTML = '<p style="color:#94a3b8; padding:1rem;">Keine Zonen registriert.</p>';
      return;
    }

    turfs.forEach(t => {
      const isOwner = (t.owner_job === myJob);
      const isWar = (t.is_war == 1);
      const card = document.createElement('div');
      card.className = 'territory-card';
      card.innerHTML = `
        <div>
          <div class="territory-header">
            <span class="territory-title">${escapeHtml(t.name)}</span>
            <span class="badge-kpi ${isOwner ? 'badge-online' : ''}">${escapeHtml(t.owner_label)}</span>
          </div>
          <div class="territory-bar-wrap">
            <div class="territory-bar-fill" style="width:100%; background:${isWar ? '#ef4444' : (isOwner ? '#22c55e' : '#3b82f6')};"></div>
          </div>
          <p class="territory-meta">Stündlicher Kassen-Ertrag: <strong>+$${Number(t.hourly_reward || 2500).toLocaleString('de-DE')}</strong></p>
          ${isWar ? '<p style="color:#ef4444; font-weight:700; margin-top:0.3rem;">🚨 GANGWAR IM GANGE!</p>' : ''}
        </div>
        ${!isOwner 
          ? `<button class="f-btn-danger btn-attack-turf" data-tid="${t.id}" style="background:#dc2626; color:#fff; border:none; border-radius:0.55rem; padding:0.6rem; font-weight:700; cursor:pointer;" ${isWar ? 'disabled style="opacity:0.5;"' : ''}>⚔️ Angriff starten (Gangwar)</button>`
          : '<button class="f-btn-primary" disabled style="opacity:0.6;">✓ Eigene Zone</button>'
        }
      `;
      grid.appendChild(card);
    });

    grid.querySelectorAll('.btn-attack-turf').forEach(btn => {
      btn.addEventListener('click', () => {
        const tid = btn.getAttribute('data-tid');
        post('startGangwar', { turfId: tid, factionId: activeFactionData.faction.id, mode: currentFactionMode });
        showAlert('Gangwar', 'Angriff gestartet! Begebt euch in die Zone und haltet das Territorium!');
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }

  // Hook into panel-territories render
  const origRenderFactionPanel = renderFactionPanel;
  renderFactionPanel = function(panelId) {
    origRenderFactionPanel(panelId);
    if (panelId === 'territories') {
      renderTurfsGrid();
    }
  };

  // SCHMUGGEL-AIRDROP ANFORDERN
  function requestAirdropAction() {
    if (!activeFactionData) return;
    post('requestAirdrop', { factionId: activeFactionData.faction.id, mode: currentFactionMode });
    showAlert('Schmuggel-Airdrop', 'Airdrop angefordert ($20.000)! Koordinaten wurden an alle Gang-Mitglieder gesendet.');
  }

  // Airdrop Button Listener
  const airdropBtn = $('btn-request-airdrop');
  if (airdropBtn) {
    airdropBtn.addEventListener('click', requestAirdropAction);
  }

  function renderFactionApplications() {
    const box = $('roster-applications-box');
    const tbody = $('faction-applications-tbody');
    if (!box || !tbody || !activeFactionData) return;

    const apps = activeFactionData.applications || [];
    const isLeader = activeFactionData.isLeader;

    if (!isLeader || apps.length === 0) {
      box.style.display = 'none';
      return;
    }

    box.style.display = 'block';
    tbody.innerHTML = '';

    apps.forEach(a => {
      const tr = document.createElement('tr');
      const isPending = (a.status === 'pending');
      tr.innerHTML = `
        <td><strong>#${a.char_id}</strong> ${escapeHtml(a.applicant_name)}</td>
        <td>${escapeHtml(a.phone_number || '-')}</td>
        <td>
          ${a.has_drive_lic ? '<span class="badge-dept">Führerschein</span> ' : ''}
          ${a.has_weapon_lic ? '<span class="badge-stars">Waffenschein</span>' : ''}
        </td>
        <td style="max-width:240px; font-size:0.8rem; color:#475569;">"${escapeHtml(a.letter || '')}"</td>
        <td style="text-align: right;">
          ${isPending ? `
            <button class="f-btn-primary btn-review-app" data-aid="${a.id}" data-status="invited" style="padding:0.3rem 0.55rem; font-size:0.78rem;">✅ Einladen</button>
            <button class="btn-rank-del btn-review-app" data-aid="${a.id}" data-status="rejected" style="padding:0.3rem 0.55rem; font-size:0.78rem;">❌</button>
          ` : `<span class="badge-status-${a.status}">${a.status === 'invited' ? 'Eingeladen' : 'Abgelehnt'}</span>`}
        </td>
      `;
      tbody.appendChild(tr);
    });

    tbody.querySelectorAll('.btn-review-app').forEach(btn => {
      btn.addEventListener('click', () => {
        const aid = btn.getAttribute('data-aid');
        const st = btn.getAttribute('data-status');
        post('reviewApplication', { appId: aid, status: st, mode: currentFactionMode });
        showAlert('Bewerbung', `Bewerbung ${st === 'invited' ? 'angenommen (Einladung gesendet)' : 'abgelehnt'}.`);
        setTimeout(() => post('getFactionDetails', { mode: currentFactionMode }), 400);
      });
    });
  }


  // ============================================================
  // FRAKTIONSFUHRPARK (AUTOS & MOTORRÄDER) LOGIK
  // ============================================================
  let currentVehicleCat = 'cars';

  const FACTION_VEHICLES_CATALOG = {
    police: {
      cars: [
        { model: 'police', label: 'Vapid Stanier Police Cruiser', desc: 'Standard Streifenfahrzeug der Schutzpolizei' },
        { model: 'police2', label: 'Bravado Buffalo STX Interceptor', desc: 'High-Speed Verfolgungsfahrzeug' },
        { model: 'police3', label: 'Vapid Torrence Interceptor', desc: 'Moderner Streifenwagen' },
        { model: 'police4', label: 'Ziviler Unmarked Cruiser', desc: 'Zivilstreife für verdeckte Ermittlungen' },
        { model: 'fbi', label: 'Tactical Buffalo Interceptor', desc: 'Schwerer Einsatzwagen' }
      ],
      bikes: [
        { model: 'policeb', label: 'Police Sovereign Streifen-Bike', desc: 'Wendiges Einsatzmotorrad' }
      ]
    },
    ambulance: {
      cars: [
        { model: 'ambulance', label: 'Rettungstransportwagen (RTW)', desc: 'Voll ausgestatteter Rettungswagen' },
        { model: 'firetruk', label: 'Feuerwehrlöschfahrzeug', desc: 'Schwerer Löschwagen' }
      ],
      bikes: [
        { model: 'enduro', label: 'First Responder Sanitäts-Enduro', desc: 'Schnelle Erstversorgung im Gelände' }
      ]
    },
    sheriff: {
      cars: [
        { model: 'sheriff', label: 'Sheriff Stanier Cruiser', desc: 'Landkreis-Streifenfahrzeug' },
        { model: 'sheriff2', label: 'Sheriff SUV Granger', desc: 'Allrad-Geländewagen für Blaine County' },
        { model: 'pranger', label: 'Park Ranger 4x4 SUV', desc: 'Offroad-Streife für Berge und Parks' }
      ],
      bikes: [
        { model: 'sanchez', label: 'Sheriff Offroad Sanchez Bike', desc: 'Geländemaschine für Sand und Wüste' }
      ]
    },
    sang: {
      cars: [
        { model: 'crusader', label: 'Canis Crusader Militär-Jeep', desc: 'Standard 4x4 Patrouillenfahrzeug' },
        { model: 'insurgent', label: 'HVY Insurgent Transporter', desc: 'Beschussfester Truppentransporter' },
        { model: 'barracks', label: 'HVY Barracks Militär-LKW', desc: 'Schwerer Logistik-Transporter' }
      ],
      bikes: [
        { model: 'manchez', label: 'Maibatsu Manchez Melder-Krad', desc: 'Militärisches Aufklärungsmotorrad' }
      ]
    },
    government: {
      cars: [
        { model: 'cognoscenti', label: 'Enus Cognoscenti Staatskarosse', desc: 'Repräsentative Luxus-Limousine' },
        { model: 'schafter3', label: 'Benefactor Schafter V12 Eskorte', desc: 'Gepanzerte Staatslimousine' },
        { model: 'baller5', label: 'Gallivanter Baller LE Eskort-SUV', desc: 'Gepanzertes Begleitfahrzeug' },
        { model: 'stretch', label: 'Dundreary Stretch Limousine', desc: 'Staatsstreckwagen' }
      ],
      bikes: [
        { model: 'sovereign', label: 'Western Sovereign Eskort-Bike', desc: 'Offizielles Eskort-Motorrad' }
      ]
    },
    weazel: {
      cars: [
        { model: 'rumpo', label: 'Bravado Rumpo News Van', desc: 'Satelliten-Übertragungswagen' },
        { model: 'burrito', label: 'Declasse Burrito Presse-Transporter', desc: 'Kamera- und Toncrew Transporter' }
      ],
      bikes: [
        { model: 'faggio', label: 'Pegassi Faggio Presse-Roller', desc: 'Schneller Stadtroller für Eilmeldungen' }
      ]
    },
    fib: {
      cars: [
        { model: 'fbi', label: 'FIB Tactical Buffalo Cruiser', desc: 'Hochleistungs-Einsatzfahrzeug des Bureau' },
        { model: 'fbi2', label: 'FIB Special Agent SUV Granger', desc: 'Gepanzerter Ermittler-SUV' }
      ],
      bikes: [
        { model: 'bati', label: 'Pegassi Bati 801 Abfang-Bike', desc: 'Extrem schnelles Abfang-Motorrad' }
      ]
    },
    ballas: {
      cars: [
        { model: 'buccaneer', label: 'Albany Buccaneer Lowrider', desc: 'Klassischer Ballas Muscle-Lowrider' },
        { model: 'voodoo', label: 'Declasse Voodoo Classic', desc: 'Tiefergelegter Davis-Klassiker' },
        { model: 'primo2', label: 'Albany Primo Custom', desc: 'Street-Tuner Sedan' }
      ],
      bikes: [
        { model: 'daemon', label: 'Western Daemon Gang-Chopper', desc: 'Klassischer V-Twin Chopper' },
        { model: 'double', label: 'Dinka Double-T Street Bike', desc: 'Agiles Fluchtmotorrad' }
      ]
    },
    vagos: {
      cars: [
        { model: 'manana', label: 'Albany Manana Custom', desc: 'Rancho Gold Lowrider Cabrio' },
        { model: 'tornado', label: 'Declasse Tornado Custom', desc: 'Klassischer 50s Gang-Cruiser' },
        { model: 'peyote', label: 'Vapid Peyote Classic', desc: 'Gelber Muscle-Klassiker' }
      ],
      bikes: [
        { model: 'avarus', label: 'LCC Avarus Custom Chopper', desc: 'Extravaganter Street-Chopper' },
        { model: 'sanchez2', label: 'Maibatsu Sanchez Stunt Bike', desc: 'Gelbe Crossmaschine für Los Santos' }
      ]
    },
    families: {
      cars: [
        { model: 'chino', label: 'Vapid Chino Lowrider', desc: 'Grüner Forum Drive Lowrider' },
        { model: 'buccaneer2', label: 'Albany Buccaneer Custom Rider', desc: 'Chamberlain Hills Muscle-Car' },
        { model: 'faction', label: 'Willard Faction Custom', desc: 'Kultiger 80er Turbo-Cruiser' }
      ],
      bikes: [
        { model: 'zombiea', label: 'Western Zombie Bobber', desc: 'Robuster Bobber für die Gang' },
        { model: 'ruffian', label: 'Pegassi Ruffian Street Bike', desc: 'Schnelles Streetfighter-Motorrad' }
      ]
    },
    bloods: {
      cars: [
        { model: 'virgo', label: 'Albany Virgo Custom', desc: 'Rotes Luxus-Coupe der Bloods' },
        { model: 'sabregt', label: 'Declasse Sabre Turbo', desc: 'Kraftvoller V8-Renner' },
        { model: 'dominator', label: 'Vapid Dominator Street Muscle', desc: 'Moderner Muscle-Car' }
      ],
      bikes: [
        { model: 'nightblade', label: 'Western Nightblade', desc: 'Tiefer dunkler Muscle-Chopper' },
        { model: 'akuma', label: 'Dinka Akuma Street Racer', desc: 'Explosive Beschleunigung' }
      ]
    },
    marabunta: {
      cars: [
        { model: 'glendale', label: 'Benefactor Glendale Custom', desc: 'Blauer Kartell-Sedan' },
        { model: 'slamvan', label: 'Vapid Slamvan Custom', desc: 'Tiefergelegter Pick-up Truck' },
        { model: 'surfer', label: 'BF Surfer Schmuggel-Van', desc: 'Unauffälliger Transporter' }
      ],
      bikes: [
        { model: 'wolfsbane', label: 'Western Wolfsbane Chopper', desc: 'Schwerer Biker-Chopper' },
        { model: 'bf400', label: 'Nagasaki BF400 Rally Bike', desc: 'Extrem wendiges Gelände-Bike' }
      ]
    }
  };

  function renderFactionVehiclesTab(category) {
    currentVehicleCat = category || 'cars';
    const grid = $('f-vehicles-grid');
    if (!grid) return;
    if (!activeFactionData) {
      grid.innerHTML = '<p style="color:#94a3b8; padding:1.5rem; text-align:center;">Lade Fuhrpark...</p>';
      post('getFactionDetails', { mode: currentFactionMode });
      return;
    }

    // Tabs umschalten
    const tabCars = $('tab-veh-cars');
    const tabBikes = $('tab-veh-bikes');
    if (tabCars && tabBikes) {
      if (currentVehicleCat === 'cars') {
        tabCars.classList.add('active');
        tabBikes.classList.remove('active');
      } else {
        tabBikes.classList.add('active');
        tabCars.classList.remove('active');
      }
    }

    grid.innerHTML = '';
    const jobKey = ((activeFactionData.faction && activeFactionData.faction.name) || (tabletData && tabletData.job) || 'police').toLowerCase();
    const catalog = FACTION_VEHICLES_CATALOG[jobKey] || FACTION_VEHICLES_CATALOG['police'];
    const list = catalog[currentVehicleCat] || [];

    if (list.length === 0) {
      grid.innerHTML = '<p style="color:#94a3b8; padding:1.5rem; text-align:center;">Keine Fahrzeuge in dieser Kategorie hinterlegt.</p>';
      return;
    }

    list.forEach(veh => {
      const card = document.createElement('div');
      card.className = 'veh-card';
      const isCar = (currentVehicleCat === 'cars');

      card.innerHTML = `
        <div class="veh-card-header">
          <div class="veh-card-icon">
            ${isCar ? '🚗' : '🏍️'}
          </div>
          <div>
            <div class="veh-card-title">${escapeHtml(veh.label)}</div>
            <div class="veh-card-model">CODE: ${escapeHtml(veh.model.toUpperCase())}</div>
          </div>
        </div>
        <div class="veh-card-desc">${escapeHtml(veh.desc || '')}</div>
        <button class="f-btn-primary veh-card-action btn-spawn-veh" data-model="${veh.model}" data-label="${escapeHtml(veh.label)}">
          🔑 Ausparken
        </button>
      `;

      grid.appendChild(card);
    });

    grid.querySelectorAll('.btn-spawn-veh').forEach(btn => {
      btn.addEventListener('click', () => {
        const m = btn.getAttribute('data-model');
        const l = btn.getAttribute('data-label');
        post('spawnFactionVehicle', { model: m, label: l, job: jobKey, mode: currentFactionMode });
        showAlert('Fuhrpark', `${l} wird bereitgestellt...`);
        setTimeout(closeTablet, 400);
      });
    });
  }

  // Tab-Wechsel Listener
  const tabCarsBtn = $('tab-veh-cars');
  if (tabCarsBtn) {
    tabCarsBtn.addEventListener('click', () => {
      renderFactionVehiclesTab('cars');
    });
  }

  const tabBikesBtn = $('tab-veh-bikes');
  if (tabBikesBtn) {
    tabBikesBtn.addEventListener('click', () => {
      renderFactionVehiclesTab('bikes');
    });
  }

  // Fahrzeug einparken
  const btnParkIn = $('btn-tablet-park-in');
  if (btnParkIn) {
    btnParkIn.addEventListener('click', () => {
      post('parkInFactionVehicle');
    });
  }
