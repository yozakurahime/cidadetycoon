// Estado global do OS (disponibilizado globalmente)
window.OSState = {
  currentApp: 'home',
  soundEnabled: true,
  soundVolume: 0.5,
  activeWallpaper: '1',
  streamerMode: false,
  payload: null,
};

// ==========================================================================
// Web Audio API Synthesizer (Sons do Touch)
// ==========================================================================
window.playClickSound = function() {
  if (!window.OSState.soundEnabled) return;
  
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    
    oscillator.type = 'sine';
    // Clique capacitivo curto (decay rápido)
    oscillator.frequency.setValueAtTime(950, audioCtx.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(150, audioCtx.currentTime + 0.04);
    
    gainNode.gain.setValueAtTime(window.OSState.soundVolume * 0.08, audioCtx.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.04);
    
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + 0.04);
  } catch (err) {
    console.log('Erro de reprodução de áudio CEF:', err);
  }
};

// ==========================================================================
// Comunicação com o Cliente FiveM (NUI)
// ==========================================================================
window.postNUI = function(action, data = {}) {
  const resourceName = (typeof GetParentResourceName !== 'undefined') ? GetParentResourceName() : 'cidade_tycoon_tablet';
  return fetch(`https://${resourceName}/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: JSON.stringify(data)
  }).then(resp => resp.json()).catch(err => {
    console.warn(`NUI Callback ${action} falhou (Offline-mode):`, err);
    return { ok: false, message: 'Serviço temporariamente indisponível.' };
  });
};

// ==========================================================================
// OS Toasts & Push Notifications
// ==========================================================================
let toastTimeout = null;
window.showToast = function(title, message, duration = 3500) {
  const toast = document.getElementById('os-toast');
  if (!toast) return;

  toast.querySelector('.toast-title').textContent = title;
  toast.querySelector('.toast-message').textContent = message;
  
  toast.classList.add('show');
  window.playClickSound();

  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toast.classList.remove('show');
  }, duration);
};

// ==========================================================================
// OS Confirmation Modal
// ==========================================================================
window.showConfirmationModal = function(title, message, onConfirm, onCancel = null) {
  const wrapper = document.getElementById('os-modal-wrapper');
  const modalTitle = document.getElementById('modal-title');
  const modalMessage = document.getElementById('modal-message');
  const confirmBtn = document.getElementById('modal-confirm-btn');
  const cancelBtn = document.getElementById('modal-cancel-btn');

  if (!wrapper || !confirmBtn || !cancelBtn) return;

  modalTitle.textContent = title;
  modalMessage.textContent = message;
  wrapper.classList.remove('hidden');
  window.playClickSound();

  // Reset listeners
  const newConfirm = confirmBtn.cloneNode(true);
  const newCancel = cancelBtn.cloneNode(true);
  confirmBtn.parentNode.replaceChild(newConfirm, confirmBtn);
  cancelBtn.parentNode.replaceChild(newCancel, cancelBtn);

  newConfirm.addEventListener('click', () => {
    window.playClickSound();
    wrapper.classList.add('hidden');
    if (onConfirm) onConfirm();
  });

  newCancel.addEventListener('click', () => {
    window.playClickSound();
    wrapper.classList.add('hidden');
    if (onCancel) onCancel();
  });
};

// ==========================================================================
// Navegação do Sistema Operacional
// ==========================================================================
window.openApp = function(appId) {
  if (window.OSState.currentApp === appId) return;
  window.playClickSound();

  // Ocultar app anterior
  if (window.OSState.currentApp === 'home') {
    document.getElementById('home-view').classList.add('hidden');
  } else {
    const prevView = document.getElementById(`app-${window.OSState.currentApp}`);
    if (prevView) prevView.classList.add('hidden');
    
    // Remover ativação do dock correspondente
    const prevDock = document.querySelector(`#dock .dock-item[data-target="${window.OSState.currentApp}"]`);
    if (prevDock) prevDock.classList.remove('active');
  }

  // Mostrar novo app
  if (appId === 'home') {
    document.getElementById('home-view').classList.remove('hidden');
    document.querySelector('#dock .dock-item[data-target="home"]').classList.add('active');
    window.renderHome(window.OSState.payload);
  } else {
    const newView = document.getElementById(`app-${appId}`);
    if (newView) newView.classList.remove('hidden');
    
    // Ativar dock
    const newDock = document.querySelector(`#dock .dock-item[data-target="${appId}"]`);
    if (newDock) newDock.classList.add('active');
    
    document.querySelector('#dock .dock-item[data-target="home"]').classList.remove('active');
    
    // Gatilho de renderização específica
    triggerAppRender(appId);
  }

  window.OSState.currentApp = appId;
};

window.refreshOS = function() {
    window.postNUI('refreshDashboard').then(resp => {
        if (resp && resp.ok && resp.payload) {
            window.OSState.payload = resp.payload;
            window.renderHome(resp.payload);
            if (window.OSState.currentApp !== 'home') {
                triggerAppRender(window.OSState.currentApp);
            }
        }
    });
};

function triggerAppRender(appId) {
  if (!window.OSState.payload) return;
  
  if (appId === 'cityhall' && window.renderCityHall) {
    window.renderCityHall(window.OSState.payload);
  } else if (appId === 'fleet' && window.renderFleet) {
    window.renderFleet(window.OSState.payload);
  } else if (appId === 'operations' && window.renderOperations) {
    window.renderOperations(window.OSState.payload);
  } else if (appId === 'finance' && window.renderFinance) {
    window.renderFinance(window.OSState.payload);
  } else if (appId === 'business' && window.renderBusiness) {
    window.renderBusiness(window.OSState.payload);
  } else if (appId === 'jobs' && window.renderJobs) {
    window.renderJobs(window.OSState.payload);
  }
}

// ==========================================================================
// Sincronização e Relógio
// ==========================================================================
function startClock() {
  const updateOSClocks = () => {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const timeString = `${hours}:${minutes}`;

    document.getElementById('status-clock').textContent = timeString;
    const homeClock = document.getElementById('home-clock');
    if (homeClock) homeClock.textContent = timeString;

    // Data por extenso
    const options = { weekday: 'long', day: 'numeric', month: 'long' };
    const dateString = now.toLocaleDateString('pt-BR', options);
    const homeDate = document.getElementById('home-date');
    if (homeDate) homeDate.textContent = dateString.charAt(0).toUpperCase() + dateString.slice(1);
  };

  updateOSClocks();
  setInterval(updateOSClocks, 30000);
}

// ==========================================================================
// Inicialização do OS & Event Listeners
// ==========================================================================
document.addEventListener('DOMContentLoaded', () => {
  // Carregar configurações locais
  window.OSState.soundEnabled = localStorage.getItem('tycoon_settings_sound') !== 'false';
  window.OSState.soundVolume = parseFloat(localStorage.getItem('tycoon_settings_volume') || '0.5');
  window.OSState.activeWallpaper = localStorage.getItem('tycoon_settings_wallpaper') || '1';
  window.OSState.streamerMode = localStorage.getItem('tycoon_settings_streamer') === 'true';

  // Aplicar Wallpaper
  const screen = document.getElementById('tablet-screen');
  if (screen) {
    screen.className = `wallpaper-gradient-${window.OSState.activeWallpaper}`;
  }

  startClock();
  if (window.initSettings) {
    window.initSettings();
  }

  // Listeners para os ícones da Home Screen
  document.querySelectorAll('.app-icon-wrapper').forEach(el => {
    el.addEventListener('click', () => {
      const app = el.getAttribute('data-app');
      window.openApp(app);
    });
  });

  // Listeners para os itens do Dock
  document.querySelectorAll('#dock .dock-item[data-target]').forEach(el => {
    el.addEventListener('click', () => {
      const target = el.getAttribute('data-target');
      window.openApp(target);
    });
  });

  // Listeners para botões "Voltar" (Back) de cabeçalho
  document.querySelectorAll('.back-home-btn').forEach(el => {
    el.addEventListener('click', () => {
      window.openApp('home');
    });
  });

  // Listener genérico de abas (tabs) internas dos apps (ex: Prefeitura)
  document.addEventListener('click', (e) => {
    const tabBtn = e.target.closest('.app-tab');
    if (!tabBtn) return;

    window.playClickSound();
    const targetId = tabBtn.getAttribute('data-tab-target');
    if (!targetId) return;

    const tabsContainer = tabBtn.closest('.app-tabs');
    if (tabsContainer) {
      tabsContainer.querySelectorAll('.app-tab').forEach(btn => btn.classList.remove('active'));
    }
    tabBtn.classList.add('active');

    const appPanel = tabBtn.closest('.app-view');
    if (appPanel) {
      appPanel.querySelectorAll('.tab-pane').forEach(pane => {
        if (pane.id === `tab-${targetId}`) {
          pane.classList.add('active');
        } else {
          pane.classList.remove('active');
        }
      });
    }
  });

  // Listener global de fechar tablet pelo botão ou ESC
  const closeTablet = () => {
    window.playClickSound();
    document.getElementById('app').classList.add('hidden');
    window.postNUI('closeTablet');
  };

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeTablet();
    }
  });
});

// ==========================================================================
// Entrada de Mensagens NUI (FiveM -> CEF)
// ==========================================================================
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data) return;

  if (data.action === 'openTablet') {
    window.OSState.payload = data.payload || {};
    document.getElementById('app').classList.remove('hidden');
    
    window.renderHome(window.OSState.payload);
    if (window.OSState.currentApp !== 'home') {
      triggerAppRender(window.OSState.currentApp);
    }
    
    if (window.OSState.payload.tutorial && window.OSState.payload.tutorial.active && window.OSState.payload.tutorial.currentStep === 'welcome') {
      window.showToast('Bem-vindo', 'Seu guia inicial da Cidade Tycoon está ativo!');
    }
  } else if (data.action === 'closeTablet') {
    document.getElementById('app').classList.add('hidden');
  } else if (data.action === 'updateTime') {
    if (data.time) {
      document.getElementById('status-clock').textContent = data.time;
      const homeClock = document.getElementById('home-clock');
      if (homeClock) homeClock.textContent = data.time;
    }
  }
});

// ==========================================================================
// CONSOLIDATED APPS MODULES
// ==========================================================================

// Global Helpers
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

// --------------------------------------------------------------------------
// APP: PREFEITURA (CITY HALL)
// --------------------------------------------------------------------------
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
    container.innerHTML = `<p class="empty-state">Nenhum aviso oficial recente.</p>`;
    return;
  }

  container.innerHTML = announcements.map(item => `
    <div class="announcement-item">
      <div class="announcement-title">${escapeHTML(item.title || 'Aviso da Prefeitura')}</div>
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

  container.innerHTML = richest.slice(0, 10).map((player, idx) => {
    const name = player.name || player.company_name || 'Tycoon Anônimo';
    const score = player.score || player.hybrid_score || 0;
    return `
      <div class="leaderboard-row">
        <span>${idx + 1}</span>
        <span>${escapeHTML(name)}</span>
        <span>${score.toLocaleString('pt-BR')} PTS</span>
      </div>
    `;
  }).join('');
}

function renderLicenses(licenses) {
  const container = document.getElementById('cityhall-licenses-list');
  if (!container) return;

  const licenseCatalog = [
    { key: 'driver', label: 'Habilitação Classe A/B', icon: '🚗' },
    { key: 'truck', label: 'Habilitação Categoria C (Caminhões)', icon: '🚛' },
    { key: 'heli', label: 'Licença de Piloto de Helicóptero', icon: '🚁' },
    { key: 'pilot', label: 'Licença de Piloto Comercial', icon: '✈️' },
  ];

  container.innerHTML = licenseCatalog.map(lic => {
    const hasLicense = licenses[lic.key] === true;
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

// --------------------------------------------------------------------------
// APP: MINHA FROTA (FLEET)
// --------------------------------------------------------------------------
let selectedVehicleId = null;
let isSpawning = false;
let isPaying = false;

window.renderFleet = function(payload) {
  let vehicles = (payload && payload.garage && payload.garage.vehicles) || [];
  if (vehicles && !Array.isArray(vehicles)) vehicles = Object.values(vehicles);
  
  renderVehicleList(vehicles);
  
  if (selectedVehicleId) {
    const selectedVeh = vehicles.find(v => Number(v.id) === Number(selectedVehicleId));
    if (selectedVeh) {
      renderVehicleDetails(selectedVeh);
      return;
    }
  }
  showEmptyState();
};

function renderVehicleList(vehicles) {
  const container = document.getElementById('fleet-vehicle-list');
  if (!container) return;

  if (vehicles.length === 0) {
    container.innerHTML = `<p class="empty-state">Nenhum veículo registrado.</p>`;
    return;
  }

  container.innerHTML = vehicles.map(veh => {
    const isActive = Number(veh.id) === Number(selectedVehicleId);
    return `
      <div class="fleet-vehicle-item ${isActive ? 'active' : ''}" data-veh-id="${veh.id}">
        <div class="vehicle-item-header">
          <span>${escapeHTML(veh.label || veh.vehicle)}</span>
          <span class="vehicle-item-plate">${escapeHTML(veh.plate)}</span>
        </div>
        <div class="vehicle-item-odometer">Tier ${veh.tier || 0} | ${veh.capacity || 0} Caixas</div>
      </div>
    `;
  }).join('');

  container.querySelectorAll('.fleet-vehicle-item').forEach(el => {
    el.addEventListener('click', () => {
      selectedVehicleId = el.getAttribute('data-veh-id');
      window.refreshOS();
    });
  });
}

function showEmptyState() {
  const container = document.getElementById('fleet-vehicle-detail');
  if (container) container.innerHTML = `<p class="empty-state">Selecione um veículo.</p>`;
}

function renderVehicleDetails(veh) {
  const container = document.getElementById('fleet-vehicle-detail');
  if (!container) return;

  const main = veh.maintenance || {};
  const overall = Math.floor(main.overall_condition || 100);

  container.innerHTML = `
    <div class="os-card">
      <div class="card-header">
        <h3>${escapeHTML(veh.label || veh.vehicle)}</h3>
        <span class="tutorial-badge">${overall}%</span>
      </div>
      <div class="progress-bar-container">
        <div class="progress-bar" style="width: ${overall}%"></div>
      </div>
      <p>Placa: ${escapeHTML(veh.plate)}</p>
      <p>Local: ${escapeHTML(veh.garage || 'Desconhecido')}</p>
      <button id="btn-spawn-veh" class="os-btn os-btn-primary" style="width:100%;" ${Number(veh.state) !== 1 ? 'disabled' : ''}>Retirar Veículo</button>
    </div>
  `;

  document.getElementById('btn-spawn-veh')?.addEventListener('click', () => {
      window.postNUI('tablet_spawn_vehicle', { vehicleId: veh.id }).then(resp => {
          if (resp.ok) window.showToast('Sucesso', 'Veículo no GPS!');
          window.refreshOS();
      });
  });
}

// --------------------------------------------------------------------------
// APP: OPERAÇÕES (OPERATIONS)
// --------------------------------------------------------------------------
let isCancelling = false;

window.renderOperations = function(payload) {
  renderActiveJob(payload.hasActiveMission, payload.activeMission);
  renderTutorial(payload.tutorial || {});
  renderHubs(payload.hubs || []);
};

function renderHubs(hubs) {
  const container = document.getElementById('operations-hubs-list');
  if (!container) return;

  container.innerHTML = hubs.map(hub => `
    <div class="hub-item">
      <span>${escapeHTML(hub.name)}</span>
      <button class="os-btn os-btn-secondary btn-hub-gps" data-hub-id="${hub.id}">GPS</button>
    </div>
  `).join('');

  container.querySelectorAll('.btn-hub-gps').forEach(btn => {
    btn.addEventListener('click', () => {
      window.postNUI('tablet_mark_hub', { hubId: Number(btn.getAttribute('data-hub-id')) }).then(resp => {
        if (resp.ok) window.showToast('GPS', 'Rota definida.');
      });
    });
  });
}

function renderActiveJob(hasJob, job) {
  const container = document.getElementById('operations-active-job');
  if (!container) return;

  if (!hasJob || !job) {
    container.innerHTML = `<p class="empty-state">Nenhum contrato ativo.</p>`;
    return;
  }

  const progress = (job.totalDelivered / job.totalRequired) * 100;

  container.innerHTML = `
    <div class="card-header"><h3>Contrato Ativo</h3></div>
    <div class="job-details">
      <p>Carga: ${job.inTrunk} / ${job.capacity}</p>
      <p>Progresso: ${job.totalDelivered} / ${job.totalRequired}</p>
      <div class="progress-bar-container"><div class="progress-bar" style="width: ${progress}%"></div></div>
      <button id="btn-cancel-job" class="os-btn os-btn-danger" style="width: 100%;">Cancelar Missão</button>
    </div>
  `;

  document.getElementById('btn-cancel-job')?.addEventListener('click', () => {
    window.showConfirmationModal('Cancelar', 'Deseja realmente cancelar?', () => {
      window.postNUI('cancelActiveJob').then(() => window.refreshOS());
    });
  });
}

function renderTutorial(tutorial) {
  const container = document.getElementById('operations-tutorial-step');
  if (!container || !tutorial.active) return;
  container.innerHTML = `<div class="tutorial-step-header">${escapeHTML(tutorial.currentStep)}</div>`;
}

// --------------------------------------------------------------------------
// APP: FINANÇAS (FINANCE)
// --------------------------------------------------------------------------
window.renderFinance = function(payload) {
  const money = payload.money || { bank: 0, cash: 0 };
  document.getElementById('finance-bank-value').textContent = `$ ${money.bank.toLocaleString('pt-BR')}`;
  document.getElementById('finance-cash-value').textContent = `$ ${money.cash.toLocaleString('pt-BR')}`;
  
  const history = payload.history || [];
  const container = document.getElementById('finance-history-list');
  if (container) {
      container.innerHTML = history.map(item => `
        <div class="history-item">
            <span>${escapeHTML(item.description)}</span>
            <strong style="color: ${item.type === 'income' ? 'var(--color-success)' : 'var(--color-danger)'}">${item.type === 'income' ? '+' : '-'} $${item.amount.toLocaleString()}</strong>
        </div>
      `).join('');
  }

  // Render active financings
  const financings = payload.financings || [];
  const financingsContainer = document.getElementById('finance-financings-list');
  if (financingsContainer) {
      if (financings.length === 0) {
          financingsContainer.innerHTML = `
            <div class="empty-state" style="padding: 16px;">
              <p>Nenhum financiamento de veículo ativo.</p>
            </div>
          `;
      } else {
          financingsContainer.innerHTML = financings.map(f => {
              const paid = f.amount_paid || 0;
              const total = f.total_price || 0;
              const progress = (paid / total) * 100;
              return `
                <div class="history-item" style="flex-direction: column; align-items: stretch; gap: 8px; padding: 12px;">
                  <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                      <h5 style="margin: 0; font-size: 14px;">${escapeHTML(f.vehicle_model.toUpperCase())}</h5>
                      <span style="font-size: 11px; color: var(--color-text-muted);">${escapeHTML(f.plate)} • Parcela ${f.installments_paid}/${f.total_installments}</span>
                    </div>
                    <div style="text-align: right;">
                      <strong style="display: block; font-size: 14px; color: var(--color-primary);">$ ${f.installment_amount.toLocaleString('pt-BR')}</strong>
                      <span style="font-size: 10px; color: var(--color-text-muted);">Última: ${formatDate(f.last_payment)}</span>
                    </div>
                  </div>
                  <div class="progress-bar-container" style="height: 6px; margin: 4px 0;">
                    <div class="progress-bar" style="width: ${progress}%"></div>
                  </div>
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 11px; color: var(--color-text-muted);">
                    <span>Pago: $ ${paid.toLocaleString('pt-BR')} / $ ${total.toLocaleString('pt-BR')}</span>
                    <button class="os-btn os-btn-primary btn-pay-financing" data-id="${f.id}" style="padding: 4px 10px; font-size: 11px;">Pagar Parcela</button>
                  </div>
                </div>
              `;
          }).join('');

          financingsContainer.querySelectorAll('.btn-pay-financing').forEach(btn => {
              btn.addEventListener('click', () => {
                  const financingId = Number(btn.getAttribute('data-id'));
                  window.postNUI('tablet_pay_financing', { financingId: financingId }).then(resp => {
                      if (resp && resp.message) window.showToast('Financiamento', resp.message);
                      window.refreshOS();
                  });
              });
          });
      }
  }
};

function formatDate(dateVal) {
  if (!dateVal) return 'Nunca';
  if (typeof dateVal === 'number') {
    const d = new Date(dateVal * 1000);
    return d.toLocaleDateString('pt-BR') + ' ' + d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  }
  return String(dateVal).substring(0, 16).replace('T', ' ');
}

// --------------------------------------------------------------------------
// APP: EMPRESA (BUSINESS)
// --------------------------------------------------------------------------
window.renderBusiness = function(payload) {
  const setupView = document.getElementById('business-setup-view');
  const mainView = document.getElementById('business-main-view');

  if (!payload.hasCompany) {
    setupView.classList.remove('hidden');
    mainView.classList.add('hidden');
    renderWarehouseList(payload.warehouses || []);
  } else {
    setupView.classList.add('hidden');
    mainView.classList.remove('hidden');
    document.getElementById('business-vault-value').textContent = `$ ${(payload.company.vaultBalance || 0).toLocaleString('pt-BR')}`;
    renderBizFleet(payload.fleet || []);
  }
};

function renderWarehouseList(warehouses) {
  const container = document.getElementById('business-warehouse-list');
  if (!container) return;
  container.innerHTML = warehouses.map(w => `
    <div class="os-card">
      <h4>${escapeHTML(w.name)}</h4>
      <p>$ ${w.price.toLocaleString()}</p>
      <button class="os-btn os-btn-primary btn-buy-warehouse" data-id="${w.id}">Adquirir</button>
    </div>
  `).join('');

  container.querySelectorAll('.btn-buy-warehouse').forEach(btn => {
    btn.addEventListener('click', () => {
      const warehouseId = Number(btn.getAttribute('data-id'));
      window.postNUI('purchaseCompany', { warehouseId: warehouseId }).then(resp => {
        if (resp && resp.message) window.showToast('Empresa', resp.message);
        window.refreshOS();
      });
    });
  });
}

function renderBizFleet(fleet) {
  const container = document.getElementById('business-fleet-list');
  if (!container) return;
  container.innerHTML = fleet.map(f => `<div>Placa: ${f.plate} | Status: ${f.status}</div>`).join('');
}

// --------------------------------------------------------------------------
// APP: EMPREGOS (JOBS)
// --------------------------------------------------------------------------
window.renderJobs = function(payload) {
  const container = document.getElementById('jobs-board-list');
  if (!container) return;
  container.innerHTML = (payload.availableJobs || []).map(j => `
    <div class="os-card">
      <h4>${escapeHTML(j.title)}</h4>
      <p>$ ${j.reward.toLocaleString()}</p>
      <button class="os-btn os-btn-primary btn-take-job" data-id="${j.id}">Aceitar</button>
    </div>
  `).join('');

  container.querySelectorAll('.btn-take-job').forEach(btn => {
    btn.addEventListener('click', () => {
      const jobId = Number(btn.getAttribute('data-id'));
      window.postNUI('tablet_accept_job', { jobId: jobId }).then(resp => {
        if (resp && resp.message) window.showToast('Emprego', resp.message);
        window.refreshOS();
      });
    });
  });
};

window.renderHome = function(payload) {
  document.getElementById('home-company-name').textContent = payload.name || "Tycoon";
  document.getElementById('home-level-tag').textContent = `NÍVEL ${payload.level || 1}`;
  
  const xpPercent = ((payload.experience || 0) / (payload.maxExperience || 2000)) * 100;
  document.getElementById('home-xp-fill').style.width = `${xpPercent}%`;
  document.getElementById('home-xp-text').textContent = `${(payload.experience || 0).toLocaleString()} / ${(payload.maxExperience || 2000).toLocaleString()} XP`;
};
