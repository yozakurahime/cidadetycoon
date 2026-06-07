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
      <div class="announcement-meta">${escapeHTML(item.sender || 'Gabinete do Prefeito')} â€¢ ${escapeHTML(item.date || 'Hoje')}</div>
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
    container.innerHTML = `<p class="empty-state">O ranking de Tycoons estÃ¡ temporariamente indisponÃ­vel.</p>`;
    return;
  }

  container.innerHTML = richest.map((player, idx) => {
    const name = player.name || player.playername || 'Motorista AnÃ´nimo';
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

  // Lista padronizada de licenÃ§as da cidade
  const licenseCatalog = [
    { key: 'driver', label: 'HabilitaÃ§Ã£o Classe A/B', icon: 'ðŸš—' },
    { key: 'truck', label: 'HabilitaÃ§Ã£o Categoria C (CaminhÃµes)', icon: 'ðŸš›' },
    { key: 'heli', label: 'LicenÃ§a de Piloto de HelicÃ³ptero', icon: 'ðŸš' },
    { key: 'pilot', label: 'LicenÃ§a de Piloto Comercial', icon: 'âœˆï¸' },
    { key: 'weapon', label: 'Porte de Arma de Fogo', icon: 'ðŸ”«' },
  ];

  container.innerHTML = licenseCatalog.map(lic => {
    // Verifica se o jogador possui a licenÃ§a
    const hasLicense = licenses[lic.key] === true || licenses[lic.key] === 1 || licenses[lic.key] === 'true';
    const statusClass = hasLicense ? 'active' : 'inactive';
    const statusLabel = hasLicense ? 'ATIVA' : 'NÃƒO POSSUI';

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
console.log('[TycoonOS] fleet.js loaded');
let selectedVehicleId = null;
let isSpawning = false;
let isPaying = false;

window.renderFleet = function(payload) {
  console.log('[TycoonOS] renderFleet triggered. Payload:', JSON.stringify(payload));
  let vehicles = (payload && payload.garage && payload.garage.vehicles) || [];
  console.log('[TycoonOS] vehicles extracted:', JSON.stringify(vehicles));
  if (vehicles && !Array.isArray(vehicles)) {
    vehicles = Object.values(vehicles);
    console.log('[TycoonOS] vehicles converted to array:', JSON.stringify(vehicles));
  }
  
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
  console.log('[TycoonOS] renderVehicleList container:', !!container, 'length:', vehicles.length);
  if (!container) return;

  if (vehicles.length === 0) {
    console.log('[TycoonOS] renderVehicleList: empty vehicles');
    container.innerHTML = `<p class="empty-state">VocÃª nÃ£o possui veÃ­culos registrados na cidade.</p>`;
    return;
  }

  container.innerHTML = vehicles.map(veh => {
    const isActive = Number(veh.id) === Number(selectedVehicleId);
    const activeClass = isActive ? 'active' : '';
    const plate = veh.plate || 'SEMPLACA';
    const odometer = (veh.maintenance && veh.maintenance.odometer_km) ? `${Math.floor(veh.maintenance.odometer_km).toLocaleString()} km` : '0 km';
    
    const stateVal = Number(veh.state);
    const defaultLabel = stateVal === 1 ? 'Na garagem' : (stateVal === 0 ? 'Fora' : 'Apreendido');
    const stateLabel = veh.stateLabel || defaultLabel;
    
    return `
      <div class="fleet-vehicle-item ${activeClass}" data-veh-id="${veh.id}">
        <div class="vehicle-item-header">
          <span>${escapeHTML(veh.vehicle || 'VeÃ­culo')}</span>
          <span class="vehicle-item-plate">${escapeHTML(plate)}</span>
        </div>
        <div class="vehicle-item-odometer">OdÃ´metro: ${odometer}</div>
        <div class="vehicle-item-odometer">Status: ${escapeHTML(stateLabel)}</div>
      </div>
    `;
  }).join('');

  // Adicionar click listeners
  container.querySelectorAll('.fleet-vehicle-item').forEach(el => {
    el.addEventListener('click', () => {
      const id = el.getAttribute('data-veh-id');
      selectedVehicleId = id;
      
      container.querySelectorAll('.fleet-vehicle-item').forEach(item => item.classList.remove('active'));
      el.classList.add('active');

      const targetVeh = vehicles.find(v => Number(v.id) === Number(id));
      if (targetVeh) {
        renderVehicleDetails(targetVeh);
      }
    });
  });
}

function showEmptyState() {
  const container = document.getElementById('fleet-vehicle-detail');
  if (container) {
    container.innerHTML = `
      <div class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 1 12v4c0 .6.4 1 1 1h2"/>
          <circle cx="7" cy="17" r="2"/>
          <circle cx="15" cy="17" r="2"/>
        </svg>
        <p>Selecione um veÃ­culo da sua frota para ver o diagnÃ³stico completo.</p>
      </div>
    `;
  }
}

function renderVehicleDetails(veh) {
  const container = document.getElementById('fleet-vehicle-detail');
  if (!container) return;

  const main = veh.maintenance || {};
  const overallCondition = main.overall_condition !== undefined ? Math.floor(main.overall_condition) : 100;
  const odometer = main.odometer_km ? `${Math.floor(main.odometer_km).toLocaleString()} km` : '0 km';
  const lastService = main.last_service_odometer_km ? `${Math.floor(main.last_service_odometer_km).toLocaleString()} km` : '0 km';
  const nextService = main.next_service_due_km ? `${Math.floor(main.next_service_due_km).toLocaleString()} km` : '2.500 km';
  const outstandingBalance = main.outstanding_balance ? Math.floor(main.outstanding_balance) : 0;
  const recommendation = main.next_service_recommendation || 'RevisÃ£o em dia';
  
  let healthClass = 'progress-success';
  if (overallCondition <= 40) {
    healthClass = 'progress-danger';
  } else if (overallCondition <= 70) {
    healthClass = 'progress-warning';
  }

  const subsystems = main.subsystems || [];
  const subsystemsArray = Array.isArray(subsystems) ? subsystems : Object.values(subsystems);
  const subsystemsHtml = subsystemsArray.length > 0 
    ? subsystemsArray.map(sub => {
        const condition = sub.condition !== undefined ? Math.floor(sub.condition) : 100;
        let subHealth = 'progress-success';
        if (condition <= 40) subHealth = 'progress-danger';
        else if (condition <= 70) subHealth = 'progress-warning';
        return `
          <div class="subsystem-item">
            <div class="subsystem-name">
              <span>${escapeHTML(sub.label || sub.subsystem)}</span>
              <span>${condition}%</span>
            </div>
            <div class="progress-bar-container">
              <div class="progress-bar ${subHealth}" style="width: ${condition}%"></div>
            </div>
          </div>
        `;
      }).join('')
    : '<p class="job-value" style="grid-column: 1/-1; text-align: center; color: var(--text-muted);">Perfil de peÃ§as deste veÃ­culo indisponÃ­vel.</p>';

  const canSpawn = Number(veh.state) === 1;

  container.innerHTML = `
    <div class="vehicle-detail-grid">
      <div class="vehicle-image-card">
        <svg viewBox="0 0 24 24" width="80" height="80" fill="none" stroke="rgba(255,255,255,0.15)" stroke-width="1">
          <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 1 12v4c0 .6.4 1 1 1h2"/>
          <circle cx="7" cy="17" r="2"/>
          <circle cx="15" cy="17" r="2"/>
        </svg>
        <div class="vehicle-profile-name">
          <h2>${escapeHTML(veh.vehicle || 'VeÃ­culo')}</h2>
          <span>Placa: ${escapeHTML(veh.plate || 'SEMPLACA')} | Local: ${escapeHTML(veh.garage || 'Desconhecido')}</span>
        </div>
      </div>

      <div class="os-card">
        <div class="card-header">
          <h3>Integridade Geral</h3>
          <span class="tutorial-badge">${overallCondition}%</span>
        </div>
        <div class="progress-bar-container" style="height: 10px; margin-bottom: 16px;">
          <div class="progress-bar ${healthClass}" style="width: ${overallCondition}%"></div>
        </div>
        <div class="job-row">
          <span class="job-label">RecomendaÃ§Ã£o:</span>
          <span class="job-value" style="color: ${overallCondition <= 40 ? 'var(--color-danger)' : (overallCondition <= 70 ? 'var(--color-accent)' : 'var(--color-success)')}">${escapeHTML(recommendation)}</span>
        </div>
        <div class="job-row">
          <span class="job-label">OdÃ´metro:</span>
          <span class="job-value">${odometer}</span>
        </div>
      </div>

      <div class="os-card">
        <div class="card-header">
          <h3>Agenda de RevisÃ£o</h3>
        </div>
        <div class="job-row">
          <span class="job-label">Ãšltima RevisÃ£o:</span>
          <span class="job-value">${lastService}</span>
        </div>
        <div class="job-row">
          <span class="job-label">PrÃ³xima RevisÃ£o:</span>
          <span class="job-value">${nextService}</span>
        </div>
        <div class="job-row">
          <span class="job-label">DÃ©bito Operacional:</span>
          <span class="job-value" style="color: ${outstandingBalance > 0 ? 'var(--color-danger)' : 'var(--color-success)'}">
            $ ${outstandingBalance.toLocaleString('pt-BR')}
          </span>
        </div>
      </div>

      <div class="os-card diag-subsystems">
        <div class="card-header">
          <h3>Status das PeÃ§as / Subsistemas</h3>
        </div>
        <div class="subsystems-list">
          ${subsystemsHtml}
        </div>
      </div>

      <div class="diag-subsystems stack" style="margin-top: 10px;">
        <div class="btn-row">
          <button id="btn-spawn-veh" class="os-btn os-btn-secondary" ${!canSpawn || isSpawning ? 'disabled' : ''}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M15 3h6v6M10 14L21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
            </svg>
            ${isSpawning ? 'Retirando...' : 'Retirar na Garagem PrÃ³xima'}
          </button>
          
          <button id="btn-pay-debt" class="os-btn os-btn-primary" ${outstandingBalance <= 0 || isPaying ? 'disabled' : ''}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="4" width="20" height="16" rx="2" ry="2"/>
              <line x1="12" y1="4" x2="12" y2="20"/>
            </svg>
            Quitar DÃ©bito Operacional
          </button>
        </div>
      </div>
    </div>
  `;

  const spawnBtn = document.getElementById('btn-spawn-veh');
  if (spawnBtn) {
    spawnBtn.addEventListener('click', () => {
      handleSpawnVehicle(veh);
    });
  }

  const payBtn = document.getElementById('btn-pay-debt');
  if (payBtn) {
    payBtn.addEventListener('click', () => {
      handlePayDebt(veh, outstandingBalance);
    });
  }
}

function handleSpawnVehicle(veh) {
  if (isSpawning) return;
  isSpawning = true;
  
  const spawnBtn = document.getElementById('btn-spawn-veh');
  if (spawnBtn) spawnBtn.disabled = true;

  window.showToast('Garagem', 'Solicitando retirada do veÃ­culo...');

  window.postNUI('tablet_spawn_vehicle', { vehicleId: veh.id }).then(resp => {
    isSpawning = false;
    if (spawnBtn) spawnBtn.disabled = !(Number(veh.state) === 1);

    if (resp && resp.ok) {
      window.showToast('Sucesso', 'VeÃ­culo retirado com sucesso! Siga o GPS.', 5000);
      
      // Recarrega o payload em background
      window.postNUI('refreshDashboard').then(refreshResp => {
        if (refreshResp && refreshResp.ok && refreshResp.payload) {
          window.OSState.payload = refreshResp.payload;
          const updatedVeh = (refreshResp.payload.garage && refreshResp.payload.garage.vehicles) ? refreshResp.payload.garage.vehicles.find(v => Number(v.id) === Number(veh.id)) : null;
          if (updatedVeh) {
            renderVehicleList(refreshResp.payload.garage.vehicles);
            renderVehicleDetails(updatedVeh);
          }
        }
      });
    } else {
      window.showToast('Erro de Spawn', resp.message || 'Garagem muito distante ou indisponÃ­vel.', 5000);
    }
  });
}

function handlePayDebt(veh, amount) {
  if (isPaying) return;

  window.showConfirmationModal(
    'Quitar DÃ©bito Operacional',
    `Deseja realmente pagar a taxa de manutenÃ§Ã£o de $ ${amount.toLocaleString('pt-BR')} para o veÃ­culo ${veh.vehicle}?`,
    () => {
      isPaying = true;
      const payBtn = document.getElementById('btn-pay-debt');
      if (payBtn) payBtn.disabled = true;

      window.showToast('Banco', 'Processando pagamento...');

      window.postNUI('tablet_pay_operational_debt', { vehicleId: veh.id }).then(resp => {
        isPaying = false;
        
        if (resp && resp.ok) {
          window.showToast('Sucesso', 'DÃ©bito quitado com sucesso!', 4000);
          if (resp.payload) {
            window.OSState.payload = resp.payload;
            const updatedVeh = (resp.payload.garage && resp.payload.garage.vehicles) ? resp.payload.garage.vehicles.find(v => Number(v.id) === Number(veh.id)) : null;
            if (updatedVeh) {
              renderVehicleDetails(updatedVeh);
            }
          }
        } else {
          window.showToast('Falha no Pagamento', resp.message || 'Saldo insuficiente ou falha bancÃ¡ria.', 5000);
          if (payBtn) payBtn.disabled = false;
        }
      });
    }
  );
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
console.log('[TycoonOS] operations.js loaded');
let isCancelling = false;

window.renderOperations = function(payload) {
  renderActiveJob(payload.hasActiveMission, payload.activeMission);
  renderTutorial(payload.tutorial || {});
};

function renderActiveJob(hasJob, job) {
  const container = document.getElementById('operations-active-job');
  if (!container) return;

  if (!hasJob || !job) {
    container.innerHTML = `
      <div class="card-header">
        <h3>ServiÃ§o Ativo</h3>
        <span class="tutorial-badge" style="background: rgba(255,255,255,0.05); color: var(--text-muted);">Inativo</span>
      </div>
      <div class="empty-state" style="padding: 20px;">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width: 36px; height: 36px;">
          <rect x="2" y="7" width="20" height="14" rx="2" ry="2"/>
          <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
        </svg>
        <p>Nenhum contrato logÃ­stico ativo no momento. VÃ¡ atÃ© um dos Hubs LogÃ­sticos no mapa para iniciar um frete.</p>
      </div>
    `;
    return;
  }

  const modeLabel = {
    freelance_general: 'Carga Geral',
    freelance_special: 'Carga Especial',
    freelance_premium: 'Carga Premium (Valiosa)'
  }[job.mode] || 'Frete';

  container.innerHTML = `
    <div class="card-header">
      <h3>ServiÃ§o LogÃ­stico Ativo</h3>
      <span class="tutorial-badge" style="background: rgba(76, 175, 80, 0.2); color: var(--color-success);">EM ANDAMENTO</span>
    </div>
    <div class="job-details">
      <div class="job-row">
        <span class="job-label">Tipo de Carga:</span>
        <span class="job-value">${escapeHTML(modeLabel)}</span>
      </div>
      <div class="job-row">
        <span class="job-label">Modelo Recomendado:</span>
        <span class="job-value">${escapeHTML(job.vehicleModel || 'Qualquer')}</span>
      </div>
      <div class="job-row">
        <span class="job-label">Pagamento Estimado:</span>
        <span class="job-value" style="color: var(--color-success)">$ ${job.reward ? job.reward.toLocaleString('pt-BR') : '0'}</span>
      </div>
      <div class="job-row" style="border: none; margin-bottom: 12px;">
        <span class="job-label">Integridade da Carga:</span>
        <span class="job-value" style="color: var(--color-info)">Monitorada via Telemetria</span>
      </div>
      
      <button id="btn-cancel-job" class="os-btn os-btn-danger" style="width: 100%;" ${isCancelling ? 'disabled' : ''}>
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
        </svg>
        Abortar ServiÃ§o (Multa de Cancelamento)
      </button>
    </div>
  `;

  const cancelBtn = document.getElementById('btn-cancel-job');
  if (cancelBtn) {
    cancelBtn.addEventListener('click', handleCancelJob);
  }
}

function handleCancelJob() {
  if (isCancelling) return;

  window.showConfirmationModal(
    'Abortar Contrato Ativo',
    'Tem certeza que deseja cancelar seu frete em andamento? O cancelamento acarreta multa operacional de cancelamento contratual.',
    () => {
      isCancelling = true;
      const cancelBtn = document.getElementById('btn-cancel-job');
      if (cancelBtn) cancelBtn.disabled = true;

      window.showToast('LogÃ­stica', 'Cancelando frete...');

      window.postNUI('cancelActiveJob').then(resp => {
        isCancelling = false;
        
        if (resp && resp.ok) {
          window.showToast('Sucesso', 'ServiÃ§o cancelado com sucesso. Multa aplicada.', 4000);
          if (resp.payload) {
            window.OSState.payload = resp.payload;
            renderOperations(resp.payload);
          }
        } else {
          window.showToast('Erro', resp.message || 'NÃ£o foi possÃ­vel cancelar o serviÃ§o.', 5000);
          if (cancelBtn) cancelBtn.disabled = false;
        }
      });
    }
  );
}

function renderTutorial(tutorial) {
  const container = document.getElementById('operations-tutorial-step');
  if (!container) return;

  if (!tutorial || !tutorial.active) {
    container.innerHTML = `
      <div class="empty-state" style="padding: 16px; min-height: 100px;">
        <p>VocÃª jÃ¡ concluiu o Onboarding inicial. O guia estÃ¡ desativado.</p>
      </div>
    `;
    return;
  }

  const stepMap = {
    welcome: {
      title: 'Boas-vindas a Cidade Tycoon',
      desc: 'Abra seu tablet e confira suas opÃ§Ãµes para iniciar. Seu guia de operaÃ§Ãµes comeÃ§arÃ¡ agora.'
    },
    go_to_garage: {
      title: 'VÃ¡ atÃ© sua Garagem',
      desc: `Siga a rota marcada em seu GPS atÃ© a garagem designada (${escapeHTML(tutorial.assignedGarage || 'Garagem')}) para retirar seu primeiro veÃ­culo.`
    },
    retrieve_bike: {
      title: 'Retire sua Faggio',
      desc: 'Abra a garagem e retire seu veÃ­culo inicial (Faggio) para poder fazer suas entregas de onboarding.'
    },
    go_to_hub: {
      title: 'Dirija-se ao Hub LogÃ­stico',
      desc: `Siga a rota no mapa atÃ© o Hub LogÃ­stico designado (${escapeHTML(tutorial.assignedHubName || 'Hub Inicial')}) para coletar sua carga.`
    },
    accept_tutorial_contract: {
      title: 'Aceite o Contrato Geral',
      desc: 'Chegando ao Hub, abra o painel de contratos e aceite a Carga Geral do Tutorial.'
    },
    complete_first_delivery: {
      title: 'Entregue a Primeira Carga',
      desc: 'Dirija com cuidado! Siga as rotas do mapa e conclua sua entrega sem danificar a carga.'
    }
  };

  const step = stepMap[tutorial.currentStep] || {
    title: 'Objetivo de OperaÃ§Ã£o',
    desc: 'Siga as diretrizes do mapa e do painel para continuar.'
  };

  container.innerHTML = `
    <div class="tutorial-step-header">${escapeHTML(step.title)}</div>
    <p class="tutorial-step-desc">${escapeHTML(step.desc)}</p>
    
    <button id="btn-tutorial-gps" class="os-btn os-btn-secondary" style="width: 100%; margin-top: 16px;">
      <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2">
        <polygon points="3 11 22 2 13 21 11 13 3 11"/>
      </svg>
      Marcar Rota no GPS
    </button>
  `;

  const gpsBtn = document.getElementById('btn-tutorial-gps');
  if (gpsBtn) {
    gpsBtn.addEventListener('click', () => {
      window.showToast('GPS', 'Rota do tutorial atualizada no GPS.');
      window.postNUI('tablet_tutorial_waypoint');
    });
  }
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
    bankVal.textContent = '$ â€¢â€¢â€¢â€¢â€¢â€¢';
    cashVal.textContent = '$ â€¢â€¢â€¢â€¢â€¢â€¢';
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
        <p>Nenhuma transaÃ§Ã£o financeira registrada recentemente na sua planilha.</p>
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
    }[item.mode] || 'Entrega LogÃ­stica';

    const desc = `${escapeHTML(modeLabel)} (Hub: ${escapeHTML(item.hub_name || 'Geral')})`;
    const amountStr = window.OSState.streamerMode ? '+ $ â€¢â€¢â€¢â€¢â€¢â€¢' : `+ $ ${reward.toLocaleString('pt-BR')}`;
    const dateStr = item.completed_at ? formatDate(item.completed_at) : 'ConcluÃ­do';

    return `
      <div class="history-item">
        <div class="history-info">
          <h5>${desc}</h5>
          <span>${escapeHTML(dateStr)} â€¢ +${xp} XP</span>
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
console.log('[TycoonOS] settings.js loaded');
window.initSettings = function() {
  const audioToggle = document.getElementById('settings-audio-toggle');
  const volumeSlider = document.getElementById('settings-audio-volume');
  const wallpaperOptions = document.querySelectorAll('.wallpaper-option');
  const screen = document.getElementById('tablet-screen');

  if (audioToggle) {
    audioToggle.checked = window.OSState.soundEnabled;
    audioToggle.addEventListener('change', (e) => {
      window.OSState.soundEnabled = e.target.checked;
      localStorage.setItem('tycoon_settings_sound', window.OSState.soundEnabled);
      window.playClickSound();
    });
  }

  if (volumeSlider) {
    volumeSlider.value = window.OSState.soundVolume * 100;
    volumeSlider.addEventListener('input', (e) => {
      window.OSState.soundVolume = parseFloat(e.target.value) / 100;
      localStorage.setItem('tycoon_settings_volume', window.OSState.soundVolume);
    });
    volumeSlider.addEventListener('change', () => {
      window.playClickSound();
    });
  }

  wallpaperOptions.forEach(opt => {
    const wpNum = opt.getAttribute('data-wallpaper');
    if (wpNum === window.OSState.activeWallpaper) {
      wallpaperOptions.forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
    }

    opt.addEventListener('click', () => {
      wallpaperOptions.forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
      
      window.OSState.activeWallpaper = wpNum;
      localStorage.setItem('tycoon_settings_wallpaper', wpNum);
      
      if (screen) {
        screen.className = `wallpaper-gradient-${wpNum}`;
      }
      window.playClickSound();
    });
  });
};

// InicializaÃ§Ã£o automÃ¡tica caso a DOM jÃ¡ esteja carregada
if (document.readyState !== 'loading') {
  window.initSettings();
}

