console.log('[TycoonOS] cityhall.js loaded');
// App Prefeitura (City Hall)
window.renderCityHall = function(payload) {
  var city = payload && payload.city;
  renderAnnouncements((city && city.announcements) || []);
  renderLeaderboard((city && city.richest) || (city && city.tycoonTop) || []);
  renderLicenses((payload && payload.licenses) || {});
};

function renderAnnouncements(announcements) {
  const container = document.getElementById('cityhall-announcements-list');
  if (!container) return;

  if (announcements && !Array.isArray(announcements)) {
    announcements = Object.values(announcements);
  }

  if (!announcements || announcements.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <p>Nenhum aviso oficial da prefeitura publicado recentemente.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = announcements.map(item => `
    <div class="announcement-item">
      <div class="announcement-title">${escapeHTML(item.title || 'Aviso da Prefeitura')}</div>
      <div class="announcement-meta">${escapeHTML(item.sender || 'Gabinete do Prefeito')} • ${escapeHTML(item.date || 'Hoje')}</div>
      <div class="announcement-body">${escapeHTML(item.message || item.content || '')}</div>
    </div>
  `).join('');
}

function renderLeaderboard(richest) {
  const container = document.getElementById('cityhall-leaderboard-richest');
  if (!container) return;

  if (richest && !Array.isArray(richest)) {
    richest = Object.values(richest);
  }

  if (!richest || richest.length === 0) {
    container.innerHTML = `<p class="empty-state">O ranking de Tycoons está temporariamente indisponível.</p>`;
    return;
  }

  container.innerHTML = richest.map((player, idx) => {
    const name = player.name || player.playername || 'Motorista Anônimo';
    const score = typeof player.score === 'number' 
      ? `$ ${player.score.toLocaleString('pt-BR')}` 
      : (typeof player.money === 'number' ? `$ ${player.money.toLocaleString('pt-BR')}` : '--');
    return `
      <div class="leaderboard-row">
        <span>${idx + 1}</span>
        <span>${escapeHTML(name)}</span>
        <span>${score}</span>
      </div>
    `;
  }).join('');
}

function renderLicenses(licenses) {
  const container = document.getElementById('cityhall-licenses-list');
  if (!container) return;

  // Lista padronizada de licenças da cidade
  const licenseCatalog = [
    { key: 'driver', label: 'Habilitação Classe A/B', icon: '🚗' },
    { key: 'truck', label: 'Habilitação Categoria C (Caminhões)', icon: '🚛' },
    { key: 'heli', label: 'Licença de Piloto de Helicóptero', icon: '🚁' },
    { key: 'pilot', label: 'Licença de Piloto Comercial', icon: '✈️' },
    { key: 'weapon', label: 'Porte de Arma de Fogo', icon: '🔫' },
  ];

  container.innerHTML = licenseCatalog.map(lic => {
    // Verifica se o jogador possui a licença
    const hasLicense = licenses[lic.key] === true || licenses[lic.key] === 1 || licenses[lic.key] === 'true';
    const statusClass = hasLicense ? 'active' : 'inactive';
    const statusLabel = hasLicense ? 'ATIVA' : 'NÃO POSSUI';

    return `
      <div class="license-card">
        <div class="license-icon">${lic.icon}</div>
        <div class="license-info">
          <h4>${lic.label}</h4>
          <span class="license-status ${statusClass}">${statusLabel}</span>
        </div>
      </div>
    `;
  }).join('');
}

function escapeHTML(str) {
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>'"]/g, 
    tag => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      "'": '&#39;',
      '"': '&quot;'
    }[tag] || tag)
  );
}
