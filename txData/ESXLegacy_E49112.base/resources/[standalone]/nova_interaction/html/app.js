/*
 * NOVA Roleplay - G-Interaktionsmenü Frontend Controller
 */

(() => {
  const overlay = document.getElementById('g-overlay');
  const badgeEl = document.getElementById('g-badge');
  const titleEl = document.getElementById('g-title');
  const subtitleEl = document.getElementById('g-subtitle');
  const gridEl = document.getElementById('g-grid');
  const closeBtn = document.getElementById('g-btn-close');

  let isOpen = false;

  function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data)
    }).catch(() => {});
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function closeMenu() {
    if (!isOpen) return;
    isOpen = false;
    overlay.classList.remove('active');
    post('close');
  }

  function renderMenu(data) {
    badgeEl.textContent = data.badge || 'INTERAKTION';
    titleEl.textContent = data.title || 'G-Menü';
    subtitleEl.textContent = data.subtitle || 'Wähle eine Option';

    gridEl.innerHTML = '';
    const items = data.items || [];

    items.forEach((item, index) => {
      const card = document.createElement('div');
      card.className = 'g-card';

      let badgeHtml = '';
      if (item.badge) {
        const badgeColor = item.badgeColor || 'gray';
        badgeHtml = `<span class="g-card-badge ${badgeColor}">${escapeHtml(item.badge)}</span>`;
      }

      card.innerHTML = `
        <div class="g-card-left">
          <div class="g-card-icon" style="${item.iconColor ? `color:${item.iconColor}; border-color:${item.iconColor}44; background:${item.iconColor}22;` : ''}">
            ${item.icon || '⚡'}
          </div>
          <div class="g-card-info">
            <span class="g-card-title">${escapeHtml(item.title)}</span>
            <span class="g-card-desc">${escapeHtml(item.desc || '')}</span>
          </div>
        </div>
        ${badgeHtml}
      `;

      card.addEventListener('click', () => {
        post('selectAction', { action: item.action, id: item.id, extra: item.extra || null });
        if (item.closeOnClick !== false) {
          closeMenu();
        }
      });

      gridEl.appendChild(card);
    });

    isOpen = true;
    overlay.classList.add('active');
  }

  // NUI Message Listener
  window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d) return;

    if (d.action === 'openMenu') {
      renderMenu(d.data || {});
    } else if (d.action === 'closeMenu') {
      isOpen = false;
      overlay.classList.remove('active');
    }
  });

  // Tasten-Events (ESC & G zum Schließen)
  window.addEventListener('keydown', (e) => {
    if (!isOpen) return;
    if (e.key === 'Escape' || e.code === 'Escape' || e.key === 'g' || e.key === 'G' || e.code === 'KeyG') {
      e.preventDefault();
      closeMenu();
    }
  });

  closeBtn.addEventListener('click', closeMenu);

  // Klick auf Overlay schließt das Menü
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      closeMenu();
    }
  });
})();

