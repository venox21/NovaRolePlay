const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'standalone_admin';

const PERMISSION_CATALOG = [
    {
        category: '⚡ Selbst-Optionen',
        items: [
            { key: 'self.noclip', label: 'NoClip (Flugmodus) nutzen' },
            { key: 'self.godmode', label: 'Godmode (Unverwundbarkeit)' },
            { key: 'self.invisible', label: 'Unsichtbarkeit aktivieren' },
            { key: 'self.esp', label: 'Spielernamen (ESP) & Blips sehen' },
            { key: 'self.infinite_ammo', label: 'Unendlich Munition aktivieren' },
            { key: 'self.heal_revive', label: 'Sich selbst heilen, wiederbeleben & Rüstung' },
            { key: 'self.tpm', label: 'Teleport zum Wegpunkt (TPM)' },
            { key: 'self.skin', label: 'Eigenes Skin-/Kleidungsmenü öffnen' }
        ]
    },
    {
        category: '👥 Spieler-Support & Kontrolle',
        items: [
            { key: 'player.teleport', label: 'Teleport (Goto, Bring, Würfelpark, Ins Auto)' },
            { key: 'player.spectate', label: 'Spieler beobachten (Spectate)' },
            { key: 'player.freeze', label: 'Spieler einfrieren (Freeze / Unfreeze)' },
            { key: 'player.heal_revive', label: 'Spieler heilen, wiederbeleben & Rüstung' },
            { key: 'player.skin', label: 'Skin-Menü bei anderen Spielern öffnen' },
            { key: 'player.kill', label: 'Spieler töten (Kill)' }
        ]
    },
    {
        category: '🔨 Moderation & Bans',
        items: [
            { key: 'mod.warn', label: 'Spieler verwarnen (Warn-Overlay)' },
            { key: 'mod.kick', label: 'Spieler vom Server kicken' },
            { key: 'mod.ban', label: 'Spieler bannen (Zeit & Permanent)' },
            { key: 'mod.unban', label: 'Bans aufheben (Unban in Bann-Liste)' }
        ]
    },
    {
        category: '💰 Wirtschaft, Jobs & Inventar',
        items: [
            { key: 'eco.money', label: 'Geld geben, abziehen & setzen' },
            { key: 'eco.setjob', label: 'Beruf & Rang eines Spielers ändern' },
            { key: 'eco.giveitem', label: 'Items an Spieler vergeben' },
            { key: 'eco.inventory', label: 'Spieler-Inventar öffnen & leeren' },
            { key: 'eco.licenses', label: 'Führerscheine & Lizenzen vergeben / entziehen' },
            { key: 'eco.weapons', label: 'Waffen & Munition vergeben / abnehmen' }
        ]
    },
    {
        category: '🚗 Fahrzeug-Tools',
        items: [
            { key: 'veh.spawn', label: 'Fahrzeuge spawnen (Spawner)' },
            { key: 'veh.repair_clean', label: 'Reparieren, Waschen, Flip, Tank & Löschen (DV)' },
            { key: 'veh.tune_custom', label: 'Full-Tune, Kennzeichen & Farbe ändern' }
        ]
    },
    {
        category: '🌍 Server, Welt & Leitung',
        items: [
            { key: 'srv.announce', label: 'Server-Ankündigungen (Banner) senden' },
            { key: 'srv.cleanup', label: 'Welt-Cleanup (Fahrzeuge, Peds, Props löschen)' },
            { key: 'srv.env', label: 'Wetter & Server-Uhrzeit global steuern' },
            { key: 'srv.manage_admins', label: 'Admin-Team verwalten (Rollen zuweisen)' },
            { key: 'srv.manage_roles', label: 'Admin-Rollen erstellen, bearbeiten & löschen' },
            { key: 'srv.char_db', label: 'Spieler-Datenbank & Offline-Charaktere verwalten' },
            { key: 'srv.view_logs', label: 'Live Admin-Logs einsehen & Discord-Webhook testen' }
        ]
    }
];

let state = {
    self: { permissions: {}, rankLevel: 0 },
    roles: [],
    players: [],
    dbChars: [],
    logs: [],
    admins: [],
    bans: [],
    jobs: [],
    items: [],
    world: { weather: 'EXTRASUNNY', hour: 12, minute: 0, maxClients: 48 }
};

let selfStates = {};
let currentCoords = { vec3: 'vec3(0, 0, 0)', vec4: 'vec4(0, 0, 0, 0)', h: 0 };
let selectedPlayerId = null;
let selectedDbCharId = null;
let wipeConfirmCharId = null;
let selectedRoleKey = 'rank_10';
let isCreatingNewRole = false;
let draftRolePerms = {};
let bannerTimeout = null;

const app = document.getElementById('app');

async function postNUI(endpoint, data = {}) {
    try {
        const res = await fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await res.json();
    } catch {
        return null;
    }
}

function escapeHtml(str) {
    return String(str ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function formatMoney(num) {
    return '$' + Number(num || 0).toLocaleString('de-DE');
}

function showToastUI(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = message;
    container.appendChild(el);
    setTimeout(() => el.remove(), 3500);
}

function showBannerUI(bannerType, title, message) {
    const banner = document.getElementById('top-banner');
    banner.className = `top-banner ${bannerType === 'warn' ? 'warn' : ''}`;
    document.getElementById('banner-title').textContent = title;
    document.getElementById('banner-message').textContent = message;
    banner.classList.remove('hidden');

    if (bannerTimeout) clearTimeout(bannerTimeout);
    bannerTimeout = setTimeout(() => {
        banner.classList.add('hidden');
    }, 8500);
}

// ============================================================================
// RENDER FUNCTIONS
// ============================================================================

function renderSelfToggles() {
    const keys = ['noclip', 'godmode', 'invisible', 'nametags', 'blips', 'infiniteAmmo', 'vehicleEsp'];
    keys.forEach(k => {
        const el = document.getElementById(`toggle-${k}`);
        if (el) {
            el.classList.toggle('active', Boolean(selfStates[k]));
        }
    });

    if (currentCoords && currentCoords.vec4) {
        document.getElementById('coords-vec4').textContent = currentCoords.vec4;
    }
}

function renderPlayersList() {
    const query = (document.getElementById('player-search').value || '').trim().toLowerCase();
    const listEl = document.getElementById('players-list');

    document.getElementById('nav-player-count').textContent = state.players.length;
    document.getElementById('stat-players').textContent =
        `${state.players.length} / ${state.world.maxClients || 48}`;

    if (!selectedPlayerId && state.players.length > 0) {
        selectedPlayerId = state.players[0].id;
    }

    const filtered = state.players.filter(p =>
        String(p.id).includes(query) ||
        String(p.charId || '').includes(query) ||
        (p.name || '').toLowerCase().includes(query) ||
        (p.rpName || '').toLowerCase().includes(query) ||
        (p.job || '').toLowerCase().includes(query) ||
        (p.rankLabel || '').toLowerCase().includes(query) ||
        (p.identifier || '').toLowerCase().includes(query)
    );

    listEl.innerHTML = filtered.map(p => {
        const badgeStyle = p.rankLevel > 0 && p.rankColor
            ? `style="background:${escapeHtml(p.rankColor)}28;color:${escapeHtml(p.rankColor)};border:1px solid ${escapeHtml(p.rankColor)}66;"`
            : '';
        const badgeText = p.rankLevel > 0 ? (p.rankLabel || p.rank) : 'Spieler';
        const displayId = p.charId || p.id;

        return `
            <div class="player-item ${p.id === selectedPlayerId ? 'selected' : ''}" onclick="selectPlayer(${p.id})">
                <div class="player-item-left">
                    <strong>ID: #${displayId} · ${escapeHtml(p.rpName || p.name)}</strong>
                    <small>${escapeHtml(p.job || 'Arbeitslos')} · ${p.ping}ms (Server-ID: ${p.id})</small>
                </div>
                <span class="badge" ${badgeStyle}>${escapeHtml(badgeText)}</span>
            </div>
        `;
    }).join('');

    renderSelectedPlayer();
}

function renderSelectedPlayer() {
    const p = state.players.find(x => x.id === selectedPlayerId);
    if (!p) {
        document.getElementById('insp-name').textContent = 'Kein Spieler ausgewählt';
        document.getElementById('insp-meta').textContent = 'Wähle links einen Spieler aus';
        return;
    }

    const displayId = p.charId || p.id;
    document.getElementById('insp-name').textContent = `[Bürger-ID: #${displayId}] ${p.rpName || p.name} (${p.name})`;
    document.getElementById('insp-meta').textContent = `${p.identifier} · Server-ID: #${p.id}`;
    const rankEl = document.getElementById('insp-rank');
    rankEl.textContent = p.rankLevel > 0 ? (p.rankLabel || p.rank) : 'SPIELER';
    rankEl.style.background = p.rankLevel > 0 ? `${p.rankColor || '#a855f7'}28` : '';
    rankEl.style.color = p.rankLevel > 0 ? (p.rankColor || '#e9d5ff') : '';
    rankEl.style.border = p.rankLevel > 0 ? `1px solid ${p.rankColor || '#a855f7'}66` : '';

    document.getElementById('insp-job').textContent = p.job || 'Arbeitslos';
    document.getElementById('insp-cash').textContent = formatMoney(p.cash);
    document.getElementById('insp-bank').textContent = formatMoney(p.bank);
    document.getElementById('insp-ping').textContent = `${p.ping} ms`;

    const quickIdInput = document.getElementById('quick-target-id');
    if (quickIdInput) {
        quickIdInput.value = displayId;
    }

    const jobSelect = document.getElementById('job-select');
    const gradeSelect = document.getElementById('grade-select');
    if (jobSelect && gradeSelect) {
        updateGradesFor(jobSelect, gradeSelect);
    }
}

function updateGradesFor(jSel, gSel) {
    if (!jSel || !gSel) return;
    const selectedJob = state.jobs.find(j => j.name === jSel.value) || state.jobs[0];
    if (!selectedJob) return;

    const isSelf = (jSel.id === 'job-select' && state.self && selectedPlayerId === state.self.id);
    const setBtn = document.getElementById('btn-set-job');

    if (isSelf) {
        if (selectedJob.name === 'unemployed') {
            gSel.innerHTML = `<option value="0">0 - Arbeitslos (Fraktion verlassen)</option>`;
            if (setBtn) {
                setBtn.textContent = 'Arbeitslos melden';
                setBtn.className = 'btn secondary';
            }
        } else {
            let maxGrade = { grade: 0, label: 'Leader' };
            if (selectedJob.grades && selectedJob.grades.length > 0) {
                maxGrade = selectedJob.grades.reduce((prev, curr) => (Number(curr.grade) > Number(prev.grade) ? curr : prev), selectedJob.grades[0]);
            }
            gSel.innerHTML = `<option value="${maxGrade.grade}">👑 Temp Leader (${escapeHtml(maxGrade.label)} - Rang ${maxGrade.grade})</option>`;
            if (setBtn) {
                setBtn.innerHTML = '👑 Als Temp-Leader setzen';
                setBtn.className = 'btn primary';
            }
        }
    } else {
        gSel.innerHTML = (selectedJob.grades || [{ grade: 0, label: 'Rang 0' }]).map(g =>
            `<option value="${g.grade}">${g.grade} - ${escapeHtml(g.label)}</option>`
        ).join('');
        if (setBtn && jSel.id === 'job-select') {
            setBtn.textContent = 'Beruf setzen';
            setBtn.className = 'btn primary';
        }
    }
}

function renderJobsAndItems() {
    const jobSelect = document.getElementById('job-select');
    const gradeSelect = document.getElementById('grade-select');
    const dbJobSelect = document.getElementById('db-job-select');
    const dbGradeSelect = document.getElementById('db-grade-select');

    if (state.jobs.length > 0 && jobSelect.options.length !== state.jobs.length) {
        const optionsHtml = state.jobs.map(j =>
            `<option value="${escapeHtml(j.name)}">${escapeHtml(j.label)} (${escapeHtml(j.name)})</option>`
        ).join('');

        jobSelect.innerHTML = optionsHtml;
        if (dbJobSelect) dbJobSelect.innerHTML = optionsHtml;

        jobSelect.onchange = () => updateGradesFor(jobSelect, gradeSelect);
        updateGradesFor(jobSelect, gradeSelect);

        if (dbJobSelect && dbGradeSelect) {
            dbJobSelect.onchange = () => updateGradesFor(dbJobSelect, dbGradeSelect);
            updateGradesFor(dbJobSelect, dbGradeSelect);
        }
    }

    const datalist = document.getElementById('items-datalist');
    if (state.items.length > 0 && datalist.children.length !== state.items.length) {
        datalist.innerHTML = state.items.map(it =>
            `<option value="${escapeHtml(it.name)}">${escapeHtml(it.label)}</option>`
        ).join('');
    }
}

function renderBans() {
    document.getElementById('nav-ban-count').textContent = state.bans.length;
    const tbody = document.getElementById('bans-tbody');

    if (state.bans.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;color:#9ca3af;">Keine aktiven Bans vorhanden.</td></tr>`;
        return;
    }

    tbody.innerHTML = state.bans.map(b => `
        <tr>
            <td>#${b.id}</td>
            <td><strong>${escapeHtml(b.playerName)}</strong></td>
            <td class="mono">${escapeHtml(b.identifier)}</td>
            <td>${escapeHtml(b.reason)}</td>
            <td>${escapeHtml(b.bannedBy)}</td>
            <td>${escapeHtml(b.expiresText)}</td>
            <td>
                <button class="btn primary" onclick="unbanPlayer(${b.id})">Entbannen</button>
            </td>
        </tr>
    `).join('');
}

function renderAdmins() {
    document.getElementById('nav-admin-count').textContent = state.admins.length;
    const tbody = document.getElementById('admins-tbody');
    const newRankSelect = document.getElementById('new-admin-rank');

    // Dropdown für neue Admin-Zuweisung mit allen vorhandenen Rollen füllen
    if (state.roles.length > 0) {
        const currentVal = newRankSelect.value;
        newRankSelect.innerHTML = state.roles.map(r =>
            `<option value="${escapeHtml(r.role_key)}">${escapeHtml(r.label)}</option>`
        ).join('');
        if (currentVal && state.roles.some(r => r.role_key === currentVal)) {
            newRankSelect.value = currentVal;
        }
    }

    tbody.innerHTML = state.admins.map(a => {
        const options = state.roles.map(r =>
            `<option value="${escapeHtml(r.role_key)}" ${a.rank === r.role_key ? 'selected' : ''}>${escapeHtml(r.label)}</option>`
        ).join('');

        const badgeStyle = `style="background:${escapeHtml(a.color)}28;color:${escapeHtml(a.color)};border:1px solid ${escapeHtml(a.color)}66;"`;

        return `
            <tr>
                <td><strong>${escapeHtml(a.name)}</strong></td>
                <td class="mono">${escapeHtml(a.identifier)}</td>
                <td><span class="badge" ${badgeStyle}>${escapeHtml(a.rankLabel || a.rank)}</span></td>
                <td>
                    <div class="actions-group">
                        <select onchange="updateAdminRank('${escapeHtml(a.identifier)}', this.value)">
                            ${options}
                        </select>
                        <button class="btn danger" onclick="updateAdminRank('${escapeHtml(a.identifier)}', 'user')">
                            Entfernen
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

// ============================================================================
// ADMIN-ROLLEN & BERECHTIGUNGEN EDITOR (TAB 7)
// ============================================================================

function renderRoles() {
    document.getElementById('nav-role-count').textContent = state.roles.length;
    const listEl = document.getElementById('roles-list');

    if (!isCreatingNewRole && (!selectedRoleKey || !state.roles.some(r => r.role_key === selectedRoleKey))) {
        selectedRoleKey = state.roles[0]?.role_key || 'rank_10';
    }

    listEl.innerHTML = state.roles.map(r => {
        const activeClass = (!isCreatingNewRole && r.role_key === selectedRoleKey) ? 'selected' : '';
        const badgeStyle = `style="background:${escapeHtml(r.color)}28;color:${escapeHtml(r.color)};border:1px solid ${escapeHtml(r.color)}66;"`;
        const permCount = Object.values(r.permissions || {}).filter(Boolean).length;

        return `
            <div class="player-item ${activeClass}" onclick="selectRole('${escapeHtml(r.role_key)}')">
                <div class="player-item-left">
                    <strong>${escapeHtml(r.label)}</strong>
                    <small>Stufe ${r.level} · ${permCount} Berechtigungen aktiv</small>
                </div>
                <span class="badge" ${badgeStyle}>Rang ${r.level}</span>
            </div>
        `;
    }).join('');

    renderRoleEditor();
}

function renderRoleEditor() {
    let role = state.roles.find(r => r.role_key === selectedRoleKey);

    if (isCreatingNewRole) {
        role = {
            role_key: '',
            label: '[Rang 1] Neue Admin-Rolle',
            level: 1,
            color: '#3b82f6',
            permissions: draftRolePerms
        };
        document.getElementById('role-editor-title').textContent = '➕ Neue Admin-Rolle erstellen';
        document.getElementById('role-editor-key').textContent = 'Neue Rolle (wird beim Speichern angelegt)';
        document.getElementById('btn-delete-role').classList.add('hidden');
    } else if (role) {
        draftRolePerms = { ...(role.permissions || {}) };
        document.getElementById('role-editor-title').textContent = role.label;
        document.getElementById('role-editor-key').textContent = `Schlüssel: ${role.role_key} · Rang-Stufe: ${role.level}`;
        document.getElementById('role-label-input').value = role.label;
        document.getElementById('role-level-input').value = role.level;
        document.getElementById('role-color-input').value = role.color || '#a855f7';

        const isProtected = role.role_key === 'rank_10' || role.role_key === 'rank_1';
        document.getElementById('btn-delete-role').classList.toggle('hidden', isProtected);
    } else {
        return;
    }

    renderPermissionCheckboxes();
}

function renderPermissionCheckboxes() {
    const container = document.getElementById('role-perms-container');
    container.innerHTML = PERMISSION_CATALOG.map(cat => {
        const checks = cat.items.map(item => {
            const checked = draftRolePerms[item.key] === true ? 'checked' : '';
            return `
                <label class="perm-check">
                    <input type="checkbox" data-perm="${item.key}" ${checked} onchange="onPermCheckChange('${item.key}', this.checked)" />
                    <span>${escapeHtml(item.label)}</span>
                </label>
            `;
        }).join('');

        return `
            <div class="perm-group-card">
                <h4>${escapeHtml(cat.category)}</h4>
                ${checks}
            </div>
        `;
    }).join('');
}

window.selectRole = function(roleKey) {
    isCreatingNewRole = false;
    selectedRoleKey = roleKey;
    renderRoles();
};

window.createNewRoleDraft = function() {
    isCreatingNewRole = true;
    draftRolePerms = {
        'self.noclip': true,
        'self.esp': true,
        'self.heal_revive': true,
        'self.tpm': true,
        'player.teleport': true,
        'player.spectate': true
    };
    document.getElementById('role-label-input').value = '[Rang 1] Neue Admin-Rolle';
    document.getElementById('role-level-input').value = 1;
    document.getElementById('role-color-input').value = '#3b82f6';
    renderRoles();
};

window.onPermCheckChange = function(permKey, isChecked) {
    if (isChecked) {
        draftRolePerms[permKey] = true;
    } else {
        delete draftRolePerms[permKey];
    }
};

window.toggleAllRolePerms = function(enableAll) {
    draftRolePerms = {};
    if (enableAll) {
        PERMISSION_CATALOG.forEach(cat => {
            cat.items.forEach(it => {
                draftRolePerms[it.key] = true;
            });
        });
    }
    renderPermissionCheckboxes();
};

window.saveSelectedRole = function() {
    const label = document.getElementById('role-label-input').value.trim();
    const level = Number(document.getElementById('role-level-input').value) || 1;
    const color = document.getElementById('role-color-input').value || '#a855f7';

    if (!label) {
        showToastUI('Bitte gib einen Namen für die Rolle ein!', 'error');
        return;
    }

    postNUI('saveRole', {
        isNew: isCreatingNewRole,
        role_key: isCreatingNewRole ? '' : selectedRoleKey,
        label,
        level,
        color,
        permissions: draftRolePerms
    });
    isCreatingNewRole = false;
};

window.deleteSelectedRole = function() {
    if (isCreatingNewRole || !selectedRoleKey) return;
    postNUI('deleteRole', { role_key: selectedRoleKey });
    selectedRoleKey = 'rank_10';
};

// ============================================================================
// SPIELER-DATENBANK (OFFLINE & ONLINE CHARAKTERE) & LIVE LOGS
// ============================================================================

function renderDbCharsList() {
    const countEl = document.getElementById('nav-db-count');
    if (countEl) countEl.textContent = state.dbChars.length;

    const dbRankSelect = document.getElementById('db-rank-select');
    if (dbRankSelect && state.roles.length > 0 && dbRankSelect.options.length !== state.roles.length) {
        dbRankSelect.innerHTML = state.roles.map(r =>
            `<option value="${escapeHtml(r.role_key)}">${escapeHtml(r.label)}</option>`
        ).join('');
    }

    const query = (document.getElementById('db-search')?.value || '').trim().toLowerCase();
    const statusFilter = document.getElementById('db-filter-status')?.value || 'all';
    const listEl = document.getElementById('db-chars-list');
    if (!listEl) return;

    if (!selectedDbCharId && state.dbChars.length > 0) {
        selectedDbCharId = state.dbChars[0].identifier;
    }

    const filtered = state.dbChars.filter(c => {
        if (statusFilter === 'online' && !c.online) return false;
        if (statusFilter === 'offline' && c.online) return false;
        if (!query) return true;
        return (
            String(c.dbId || '').includes(query) ||
            (c.fullName || '').toLowerCase().includes(query) ||
            (c.identifier || '').toLowerCase().includes(query) ||
            (c.license || '').toLowerCase().includes(query) ||
            (c.jobName || '').toLowerCase().includes(query) ||
            (c.rankLabel || '').toLowerCase().includes(query)
        );
    });

    listEl.innerHTML = filtered.map(c => {
        const statusDot = c.online
            ? `<span style="color:#10b981;font-weight:700;">🟢 Online (#${c.onlineId})</span>`
            : `<span style="color:#9ca3af;">⚫ Offline</span>`;
        const badgeStyle = c.rankLevel > 0 && c.rankColor
            ? `style="background:${escapeHtml(c.rankColor)}28;color:${escapeHtml(c.rankColor)};border:1px solid ${escapeHtml(c.rankColor)}66;"`
            : '';
        const badgeText = c.rankLevel > 0 ? (c.rankLabel || c.rank) : 'Spieler';
        const displayDbId = c.dbId || 1;

        return `
            <div class="player-item ${c.identifier === selectedDbCharId ? 'selected' : ''}" onclick="selectDbChar('${escapeHtml(c.identifier)}')">
                <div class="player-item-left">
                    <strong>ID: #${displayDbId} · ${escapeHtml(c.fullName)}</strong>
                    <small>${statusDot} · ${escapeHtml(c.jobName)} (${c.jobGrade}) · Bank: ${formatMoney(c.bank)}</small>
                </div>
                <span class="badge" ${badgeStyle}>${escapeHtml(badgeText)}</span>
            </div>
        `;
    }).join('');

    renderSelectedDbChar();
}

function renderSelectedDbChar() {
    const c = state.dbChars.find(x => x.identifier === selectedDbCharId);
    const wipeBtn = document.getElementById('btn-db-wipe');
    if (wipeBtn && wipeConfirmCharId !== selectedDbCharId) {
        wipeConfirmCharId = null;
        wipeBtn.textContent = '💀 Charakter-Wipe (CK) — Komplett löschen';
    }

    if (!c) {
        document.getElementById('db-insp-name').textContent = 'Kein Charakter ausgewählt';
        document.getElementById('db-insp-meta').textContent = 'Wähle links einen Charakter aus der Datenbank';
        return;
    }

    document.getElementById('db-insp-name').textContent = `[Bürger-ID: #${c.dbId || 1}] ${c.fullName}`;
    document.getElementById('db-insp-meta').textContent = `${c.identifier} · ${c.license}`;

    const statusEl = document.getElementById('db-insp-status');
    if (c.online) {
        statusEl.textContent = `🟢 ONLINE (#${c.onlineId})`;
        statusEl.style.background = 'rgba(16, 185, 129, 0.2)';
        statusEl.style.color = '#10b981';
        statusEl.style.border = '1px solid rgba(16, 185, 129, 0.5)';
    } else {
        statusEl.textContent = '⚫ OFFLINE';
        statusEl.style.background = 'rgba(107, 114, 128, 0.2)';
        statusEl.style.color = '#9ca3af';
        statusEl.style.border = '1px solid rgba(107, 114, 128, 0.4)';
    }

    const rankEl = document.getElementById('db-insp-rank');
    rankEl.textContent = c.rankLevel > 0 ? (c.rankLabel || c.rank) : 'SPIELER';
    rankEl.style.background = c.rankLevel > 0 ? `${c.rankColor || '#a855f7'}28` : '';
    rankEl.style.color = c.rankLevel > 0 ? (c.rankColor || '#e9d5ff') : '';
    rankEl.style.border = c.rankLevel > 0 ? `1px solid ${c.rankColor || '#a855f7'}66` : '';

    document.getElementById('db-insp-cash').textContent = formatMoney(c.cash);
    document.getElementById('db-insp-bank').textContent = formatMoney(c.bank);
    document.getElementById('db-insp-black').textContent = formatMoney(c.blackMoney);
    document.getElementById('db-insp-job').textContent = `${c.jobName} (Rang ${c.jobGrade})`;
    document.getElementById('db-insp-dob').textContent = `${c.dob} · ${c.sex}`;
    document.getElementById('db-insp-vehs').textContent = `${c.vehiclesCount} Fahrzeug(e)`;

    document.getElementById('db-firstname').value = c.firstname || '';
    document.getElementById('db-lastname').value = c.lastname || '';

    const dbRankSelect = document.getElementById('db-rank-select');
    if (dbRankSelect && c.rank && c.rank !== 'user') {
        dbRankSelect.value = c.rank;
    }
}

function renderLogs() {
    const countEl = document.getElementById('nav-log-count');
    if (countEl) countEl.textContent = state.logs.length;

    const tbody = document.getElementById('logs-tbody');
    if (!tbody) return;

    const query = (document.getElementById('log-search')?.value || '').trim().toLowerCase();
    const catFilter = document.getElementById('log-category-filter')?.value || 'all';

    const catBadges = {
        moderation: { label: '🔨 Moderation', color: '#ef4444' },
        warn:       { label: '⚠️ Warn / Freeze', color: '#f59e0b' },
        economy:    { label: '💰 Wirtschaft', color: '#10b981' },
        database:   { label: '🗄️ Datenbank', color: '#6366f1' },
        roles:      { label: '👑 Rollen / Team', color: '#a855f7' },
        support:    { label: '🩺 Support', color: '#06b6d4' },
        server:     { label: '🌍 Server', color: '#3b82f6' }
    };

    const filtered = state.logs.filter(l => {
        if (catFilter !== 'all' && l.category !== catFilter) return false;
        if (!query) return true;
        return (
            (l.action || '').toLowerCase().includes(query) ||
            (l.admin_name || '').toLowerCase().includes(query) ||
            (l.target_name || '').toLowerCase().includes(query) ||
            (l.details || '').toLowerCase().includes(query) ||
            (l.admin_role || '').toLowerCase().includes(query)
        );
    });

    if (filtered.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;color:#9ca3af;">Noch keine passenden Admin-Logs vorhanden.</td></tr>`;
        return;
    }

    tbody.innerHTML = filtered.map(l => {
        const badgeInfo = catBadges[l.category] || { label: l.category || 'Allgemein', color: '#9ca3af' };
        const badgeStyle = `style="background:${badgeInfo.color}24;color:${badgeInfo.color};border:1px solid ${badgeInfo.color}55;"`;

        return `
            <tr>
                <td class="mono">#${l.id || '-'}</td>
                <td class="mono" style="white-space:nowrap;">${escapeHtml(l.time_text || '-')}</td>
                <td><span class="badge" ${badgeStyle}>${escapeHtml(badgeInfo.label)}</span></td>
                <td><strong>${escapeHtml(l.action)}</strong></td>
                <td>
                    <strong>${escapeHtml(l.admin_name)}</strong><br/>
                    <small style="color:#9ca3af;">${escapeHtml(l.admin_role || '')}</small>
                </td>
                <td>
                    <strong>${escapeHtml(l.target_name)}</strong><br/>
                    <small class="mono" style="color:#9ca3af;">${escapeHtml(l.target_identifier || '')}</small>
                </td>
                <td>${escapeHtml(l.details)}</td>
            </tr>
        `;
    }).join('');
}

window.selectDbChar = function(identifier) {
    selectedDbCharId = identifier;
    wipeConfirmCharId = null;
    renderDbCharsList();
};

window.dbRenameChar = function() {
    if (!selectedDbCharId) return;
    const firstname = document.getElementById('db-firstname').value.trim();
    const lastname = document.getElementById('db-lastname').value.trim();
    if (!firstname || !lastname) {
        showToastUI('Bitte gib Vorname und Nachname ein!', 'error');
        return;
    }
    postNUI('dbCharAction', {
        action: 'rename',
        identifier: selectedDbCharId,
        firstname,
        lastname
    });
};

window.dbMoneyAct = function(mode) {
    if (!selectedDbCharId) return;
    postNUI('dbCharAction', {
        action: 'money',
        identifier: selectedDbCharId,
        account: document.getElementById('db-money-account').value,
        amount: Number(document.getElementById('db-money-amount').value) || 0,
        mode
    });
};

window.dbSetCharJob = function() {
    if (!selectedDbCharId) return;
    postNUI('dbCharAction', {
        action: 'setjob',
        identifier: selectedDbCharId,
        jobName: document.getElementById('db-job-select').value,
        jobGrade: Number(document.getElementById('db-grade-select').value) || 0
    });
};

window.dbSetCharRank = function(overrideRank) {
    if (!selectedDbCharId) return;
    const rank = overrideRank || document.getElementById('db-rank-select').value;
    postNUI('dbCharAction', {
        action: 'setrank',
        identifier: selectedDbCharId,
        rank
    });
};

window.dbBanChar = function() {
    if (!selectedDbCharId) return;
    const reason = document.getElementById('db-ban-reason').value.trim() || 'Offline-Ban durch Admin';
    const durationHours = Number(document.getElementById('db-ban-duration').value) || 0;
    postNUI('dbCharAction', {
        action: 'ban',
        identifier: selectedDbCharId,
        reason,
        durationHours
    });
};

window.dbClearCharInv = function() {
    if (!selectedDbCharId) return;
    postNUI('dbCharAction', {
        action: 'clearinv',
        identifier: selectedDbCharId
    });
};

window.dbWipeChar = function() {
    if (!selectedDbCharId) return;
    const wipeBtn = document.getElementById('btn-db-wipe');
    if (wipeConfirmCharId !== selectedDbCharId) {
        wipeConfirmCharId = selectedDbCharId;
        if (wipeBtn) {
            wipeBtn.textContent = '⚠️ NOCHMAL KLICKEN ZUM ENDGÜLTIGEN LÖSCHEN (CK)!';
        }
        showToastUI('Klicke zur Sicherheit noch einmal auf den Button, um den Charakter endgültig zu löschen!', 'error');
        return;
    }
    const idToDelete = selectedDbCharId;
    wipeConfirmCharId = null;
    selectedDbCharId = null;
    if (wipeBtn) {
        wipeBtn.textContent = '💀 Charakter-Wipe (CK) — Komplett löschen';
    }
    postNUI('dbCharAction', {
        action: 'wipe',
        identifier: idToDelete
    });
};

window.triggerLogAction = function(action) {
    postNUI('logAction', { action });
};

// ============================================================================
// APPLY SERVER DATA
// ============================================================================

function applyData(data) {
    if (!data) return;
    state.self = data.self || { permissions: {}, rankLevel: 0 };
    state.roles = data.roles || [];
    state.players = data.players || [];
    state.dbChars = data.dbChars || [];
    state.logs = data.logs || [];
    state.admins = data.admins || [];
    state.bans = data.bans || [];
    state.jobs = data.jobs || [];
    state.items = data.items || [];
    state.world = data.world || state.world;

    document.getElementById('self-info').textContent =
        `Eingeloggt als: ${state.self.name || 'Admin'} (#${state.self.id || '?'}) · Rolle: ${state.self.rankLabel || state.self.rank || 'Owner'}`;

    const hh = String(state.world.hour ?? 12).padStart(2, '0');
    const mm = String(state.world.minute ?? 0).padStart(2, '0');
    document.getElementById('stat-env').textContent = `${state.world.weather || 'EXTRASUNNY'} · ${hh}:${mm}`;

    renderSelfToggles();
    renderPlayersList();
    renderJobsAndItems();
    renderDbCharsList();
    renderBans();
    renderAdmins();
    renderRoles();
    renderLogs();
}

// ============================================================================
// INTERACTION HANDLERS
// ============================================================================

window.selectPlayer = function(id) {
    selectedPlayerId = id;
    renderPlayersList();
};

window.triggerSelf = async function(action) {
    const res = await postNUI('selfAction', { action });
    if (res && res.states) {
        selfStates = res.states;
        currentCoords = res.coords || currentCoords;
        renderSelfToggles();
    }
};

window.copyCoord = function(type) {
    let text = currentCoords.vec3;
    if (type === 'vec4') text = currentCoords.vec4;
    if (type === 'heading') text = String(currentCoords.h ?? 0);

    const el = document.createElement('textarea');
    el.value = text;
    document.body.appendChild(el);
    el.select();
    document.execCommand('copy');
    el.remove();
    showToastUI(`Kopiert: ${text}`, 'success');
};

window.playerAct = function(action) {
    if (!selectedPlayerId) return;
    postNUI('playerAction', {
        action,
        targetId: selectedPlayerId,
        reason: document.getElementById('mod-reason').value.trim() || 'Kein Grund angegeben',
        durationHours: Number(document.getElementById('mod-duration').value) || 0
    });
};

window.moneyAct = function(mode) {
    if (!selectedPlayerId) return;
    postNUI('playerAction', {
        action: 'money',
        targetId: selectedPlayerId,
        account: document.getElementById('money-account').value,
        amount: Number(document.getElementById('money-amount').value) || 0,
        mode
    });
};

window.setPlayerJob = function() {
    if (!selectedPlayerId) return;
    const isSelf = (state.self && selectedPlayerId === state.self.id);
    postNUI('playerAction', {
        action: 'setjob',
        targetId: selectedPlayerId,
        jobName: document.getElementById('job-select').value,
        jobGrade: Number(document.getElementById('grade-select').value) || 0,
        isTempLeader: isSelf
    });
};

window.givePlayerItem = function() {
    if (!selectedPlayerId) return;
    const itemName = document.getElementById('item-name').value.trim();
    const count = Number(document.getElementById('item-count').value) || 1;
    if (!itemName) return;
    postNUI('playerAction', {
        action: 'giveitem',
        targetId: selectedPlayerId,
        itemName,
        count
    });
};

// ============================================================================
// FÜHRERSCHEINE, LIZENZEN & WAFFEN (SELBST & PER ID-EINGABE)
// ============================================================================

window.quickSelfLicenses = function(licenseType = 'all') {
    postNUI('playerAction', {
        action: 'give_licenses',
        targetId: null, // Auf dem Server automatisch der Admin selbst
        licenseType
    });
};

window.quickSelfWeapons = function(weaponType = 'all') {
    postNUI('playerAction', {
        action: 'give_weapons',
        targetId: null, // Auf dem Server automatisch der Admin selbst
        weaponType
    });
};

window.giveLicensesQuick = function(licenseType = 'all') {
    const rawId = document.getElementById('quick-target-id')?.value.trim();
    const targetId = rawId ? Number(rawId) : selectedPlayerId;
    postNUI('playerAction', {
        action: 'give_licenses',
        targetId: targetId || null,
        licenseType
    });
};

window.giveWeaponsQuick = function(weaponType = 'all') {
    const rawId = document.getElementById('quick-target-id')?.value.trim();
    const targetId = rawId ? Number(rawId) : selectedPlayerId;
    postNUI('playerAction', {
        action: 'give_weapons',
        targetId: targetId || null,
        weaponType
    });
};

window.playerLicenseAct = function(licenseType) {
    const rawId = document.getElementById('quick-target-id')?.value.trim();
    const targetId = rawId ? Number(rawId) : selectedPlayerId;
    postNUI('playerAction', {
        action: 'give_licenses',
        targetId: targetId || null,
        licenseType
    });
};

window.playerWeaponAct = function(weaponType) {
    const rawId = document.getElementById('quick-target-id')?.value.trim();
    const targetId = rawId ? Number(rawId) : selectedPlayerId;
    postNUI('playerAction', {
        action: 'give_weapons',
        targetId: targetId || null,
        weaponType
    });
};

window.giveSelectedWeapon = function() {
    const rawId = document.getElementById('quick-target-id')?.value.trim();
    const targetId = rawId ? Number(rawId) : selectedPlayerId;
    const weapon = document.getElementById('admin-weapon-select')?.value;
    const ammo = Number(document.getElementById('admin-weapon-ammo')?.value) || 250;
    if (!weapon) return;
    postNUI('playerAction', {
        action: 'give_weapons',
        targetId: targetId || null,
        weaponType: 'single',
        weapon,
        ammo
    });
};

window.spawnVehicle = function() {
    const model = document.getElementById('veh-model').value.trim();
    if (!model) return;
    postNUI('vehicleAction', {
        action: 'spawn',
        model,
        warp: document.getElementById('veh-warp').checked,
        deleteCurrent: document.getElementById('veh-del').checked,
        maxTune: document.getElementById('veh-max').checked
    });
};

window.quickSpawn = function(model) {
    postNUI('vehicleAction', {
        action: 'spawn',
        model,
        warp: document.getElementById('veh-warp').checked,
        deleteCurrent: document.getElementById('veh-del').checked,
        maxTune: document.getElementById('veh-max').checked
    });
};

window.vehAct = function(action) {
    postNUI('vehicleAction', { action });
};

window.setVehiclePlate = function() {
    const plate = document.getElementById('veh-plate').value.trim();
    if (!plate) return;
    postNUI('vehicleAction', { action: 'plate', plate });
};

window.setVehColor = function(primary, secondary) {
    postNUI('vehicleAction', { action: 'color', primary, secondary });
};

window.sendAnnouncement = function() {
    const msg = document.getElementById('announce-msg').value.trim();
    if (!msg) return;
    postNUI('worldAction', { action: 'announce', message: msg });
    document.getElementById('announce-msg').value = '';
};

window.worldAct = function(action) {
    postNUI('worldAction', { action });
};

window.setWeather = function(weather) {
    postNUI('worldAction', { action: 'weather', weather });
};

window.setTime = function(hour, minute) {
    postNUI('worldAction', { action: 'time', hour, minute });
};

window.setCustomTime = function() {
    const hour = Number(document.getElementById('custom-hour').value) || 12;
    const minute = Number(document.getElementById('custom-min').value) || 0;
    postNUI('worldAction', { action: 'time', hour, minute });
};

window.unbanPlayer = function(id) {
    postNUI('unban', { id });
};

window.updateAdminRank = function(identifier, rank) {
    postNUI('setAdminRank', { identifier, rank });
};

document.getElementById('btn-add-admin').addEventListener('click', () => {
    const raw = document.getElementById('new-admin-id').value.trim();
    const rank = document.getElementById('new-admin-rank').value;
    if (!raw) return;

    const asNumber = Number(raw);
    if (!Number.isNaN(asNumber) && asNumber > 0) {
        postNUI('setAdminRank', { targetId: asNumber, rank });
    } else {
        postNUI('setAdminRank', { identifier: raw, rank });
    }
    document.getElementById('new-admin-id').value = '';
});

document.getElementById('player-search').addEventListener('input', renderPlayersList);
document.getElementById('db-search').addEventListener('input', renderDbCharsList);
document.getElementById('db-filter-status').addEventListener('change', renderDbCharsList);
document.getElementById('log-search').addEventListener('input', renderLogs);
document.getElementById('log-category-filter').addEventListener('change', renderLogs);
document.getElementById('btn-refresh').addEventListener('click', () => postNUI('refresh'));
document.getElementById('btn-close').addEventListener('click', () => postNUI('close'));

document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.nav-btn, .tab-pane').forEach(el => el.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
    });
});

window.addEventListener('message', (event) => {
    const { action, data, states, coords, message, toastType, bannerType, title } = event.data || {};
    if (states) selfStates = states;
    if (coords) currentCoords = coords;

    if (action === 'open') {
        applyData(data);
        app.classList.remove('hidden');
    } else if (action === 'update') {
        applyData(data);
    } else if (action === 'syncStates') {
        renderSelfToggles();
    } else if (action === 'close') {
        app.classList.add('hidden');
    } else if (action === 'toast') {
        showToastUI(message, toastType);
    } else if (action === 'banner') {
        showBannerUI(bannerType, title, message);
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        postNUI('close');
    }
});
