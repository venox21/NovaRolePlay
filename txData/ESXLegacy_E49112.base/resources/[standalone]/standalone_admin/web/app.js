const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'standalone_admin';

let state = {
    self: {},
    players: [],
    admins: []
};

const app = document.getElementById('app');
const playersTbody = document.getElementById('players-tbody');
const adminsTbody = document.getElementById('admins-tbody');
const searchInput = document.getElementById('player-search');
const reasonInput = document.getElementById('action-reason');
const durationInput = document.getElementById('ban-duration');

async function postNUI(endpoint, data = {}) {
    try {
        const res = await fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await res.json();
    } catch (err) {
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

function renderPlayers() {
    const query = searchInput.value.trim().toLowerCase();
    const filtered = state.players.filter(p =>
        String(p.id).includes(query) ||
        p.name.toLowerCase().includes(query) ||
        p.identifier.toLowerCase().includes(query)
    );

    document.getElementById('player-count').textContent = state.players.length;

    playersTbody.innerHTML = filtered.map(p => `
        <tr>
            <td>#${p.id}</td>
            <td><strong>${escapeHtml(p.name)}</strong></td>
            <td class="mono">${escapeHtml(p.identifier)}</td>
            <td><span class="badge ${escapeHtml(p.rank)}">${escapeHtml(p.rank)}</span></td>
            <td>${p.ping} ms</td>
            <td>
                <div class="actions-group">
                    <button class="btn" onclick="triggerPlayerAction('goto', ${p.id})">Goto</button>
                    <button class="btn" onclick="triggerPlayerAction('bring', ${p.id})">Bring</button>
                    <button class="btn" onclick="triggerPlayerAction('spectate', ${p.id})">Spectate</button>
                    <button class="btn danger" onclick="triggerPlayerAction('kick', ${p.id})">Kick</button>
                    <button class="btn danger" onclick="triggerPlayerAction('ban', ${p.id})">Ban</button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderAdmins() {
    document.getElementById('admin-count').textContent = state.admins.length;

    const ranks = ['supporter', 'moderator', 'admin', 'superadmin', 'owner'];

    adminsTbody.innerHTML = state.admins.map(a => {
        const options = ranks.map(r =>
            `<option value="${r}" ${a.rank === r ? 'selected' : ''}>${r.toUpperCase()}</option>`
        ).join('');

        return `
            <tr>
                <td><strong>${escapeHtml(a.name)}</strong></td>
                <td class="mono">${escapeHtml(a.identifier)}</td>
                <td><span class="badge ${escapeHtml(a.rank)}">${escapeHtml(a.rank)}</span></td>
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

function applyData(data) {
    if (!data) return;
    state.self = data.self || {};
    state.players = data.players || [];
    state.admins = data.admins || [];

    document.getElementById('self-info').textContent =
        `Eingeloggt als: ${state.self.name || 'Admin'} (#${state.self.id || '?'}) | Rang: ${(state.self.rank || 'admin').toUpperCase()}`;

    renderPlayers();
    renderAdmins();
}

window.triggerPlayerAction = function(action, targetId) {
    postNUI('playerAction', {
        action,
        targetId,
        reason: reasonInput.value.trim() || 'Kein Grund angegeben',
        durationHours: Number(durationInput.value) || 0
    });
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

searchInput.addEventListener('input', renderPlayers);

document.getElementById('btn-refresh').addEventListener('click', () => postNUI('refresh'));
document.getElementById('btn-close').addEventListener('click', () => postNUI('close'));

document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab, .tab-content').forEach(el => el.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
    });
});

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    if (action === 'open') {
        applyData(data);
        app.classList.remove('hidden');
    } else if (action === 'update') {
        applyData(data);
    } else if (action === 'close') {
        app.classList.add('hidden');
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        postNUI('close');
    }
});

