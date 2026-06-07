console.log('[TycoonOS] finance.js loaded');
window.renderFinance = function(payload) {
  renderBalances(payload.money || { bank: 0, cash: 0 });
  renderTransactions(payload.history || []);
};

function renderBalances(money) {
  const bankVal = document.getElementById('finance-bank-value');
  const cashVal = document.getElementById('finance-cash-value');
  const eyeBtn = document.getElementById('toggle-streamer-mode');

  if (!bankVal || !cashVal) return;

  const formatMoney = (val) => {
    return val !== undefined ? `$ ${val.toLocaleString('pt-BR')}` : '$ --';
  };

  if (window.OSState.streamerMode) {
    bankVal.textContent = '$ ••••••';
    cashVal.textContent = '$ ••••••';
    updateEyeIcon(true);
  } else {
    bankVal.textContent = formatMoney(money.bank);
    cashVal.textContent = formatMoney(money.cash);
    updateEyeIcon(false);
  }

  if (eyeBtn) {
    const newBtn = eyeBtn.cloneNode(true);
    eyeBtn.parentNode.replaceChild(newBtn, eyeBtn);
    newBtn.addEventListener('click', () => {
      window.OSState.streamerMode = !window.OSState.streamerMode;
      localStorage.setItem('tycoon_settings_streamer', window.OSState.streamerMode);
      window.playClickSound();
      renderBalances(money);
    });
  }
}

function updateEyeIcon(isStreamer) {
  const icon = document.getElementById('eye-icon');
  if (!icon) return;

  if (isStreamer) {
    icon.innerHTML = `
      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
      <line x1="1" y1="1" x2="23" y2="23"/>
    `;
  } else {
    icon.innerHTML = `
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
      <circle cx="12" cy="12" r="3"/>
    `;
  }
}

function renderTransactions(history) {
  const container = document.getElementById('finance-history-list');
  if (!container) return;

  if (history && !Array.isArray(history)) {
    history = Object.values(history);
  }

  if (!history || history.length === 0) {
    container.innerHTML = `
      <div class="empty-state" style="padding: 16px;">
        <p>Nenhuma transação financeira registrada recentemente na sua planilha.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = history.map(item => {
    const reward = Number(item.reward) || 0;
    const xp = Number(item.xp) || 0;
    const modeLabel = {
      freelance_general: 'Frete: Carga Geral',
      freelance_special: 'Frete: Carga Especial',
      freelance_premium: 'Frete: Carga Premium'
    }[item.mode] || 'Entrega Logística';

    const desc = `${escapeHTML(modeLabel)} (Hub: ${escapeHTML(item.hub_name || 'Geral')})`;
    const amountStr = window.OSState.streamerMode ? '+ $ ••••••' : `+ $ ${reward.toLocaleString('pt-BR')}`;
    const dateStr = item.completed_at ? formatDate(item.completed_at) : 'Concluído';

    return `
      <div class="history-item">
        <div class="history-info">
          <h5>${desc}</h5>
          <span>${escapeHTML(dateStr)} • +${xp} XP</span>
        </div>
        <div class="history-amount amount-positive">${amountStr}</div>
      </div>
    `;
  }).join('');
}

function formatDate(dateVal) {
  if (!dateVal) return '';
  if (typeof dateVal === 'number') {
    const d = new Date(dateVal * 1000);
    return d.toLocaleDateString('pt-BR') + ' ' + d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  }
  return String(dateVal).substring(0, 16);
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
