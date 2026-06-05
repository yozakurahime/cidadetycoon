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
    container.innerHTML = `<p class="empty-state">Você não possui veículos registrados na cidade.</p>`;
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
          <span>${escapeHTML(veh.vehicle || 'Veículo')}</span>
          <span class="vehicle-item-plate">${escapeHTML(plate)}</span>
        </div>
        <div class="vehicle-item-odometer">Odômetro: ${odometer}</div>
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
        <p>Selecione um veículo da sua frota para ver o diagnóstico completo.</p>
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
  const recommendation = main.next_service_recommendation || 'Revisão em dia';
  
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
    : '<p class="job-value" style="grid-column: 1/-1; text-align: center; color: var(--text-muted);">Perfil de peças deste veículo indisponível.</p>';

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
          <h2>${escapeHTML(veh.vehicle || 'Veículo')}</h2>
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
          <span class="job-label">Recomendação:</span>
          <span class="job-value" style="color: ${overallCondition <= 40 ? 'var(--color-danger)' : (overallCondition <= 70 ? 'var(--color-accent)' : 'var(--color-success)')}">${escapeHTML(recommendation)}</span>
        </div>
        <div class="job-row">
          <span class="job-label">Odômetro:</span>
          <span class="job-value">${odometer}</span>
        </div>
      </div>

      <div class="os-card">
        <div class="card-header">
          <h3>Agenda de Revisão</h3>
        </div>
        <div class="job-row">
          <span class="job-label">Última Revisão:</span>
          <span class="job-value">${lastService}</span>
        </div>
        <div class="job-row">
          <span class="job-label">Próxima Revisão:</span>
          <span class="job-value">${nextService}</span>
        </div>
        <div class="job-row">
          <span class="job-label">Débito Operacional:</span>
          <span class="job-value" style="color: ${outstandingBalance > 0 ? 'var(--color-danger)' : 'var(--color-success)'}">
            $ ${outstandingBalance.toLocaleString('pt-BR')}
          </span>
        </div>
      </div>

      <div class="os-card diag-subsystems">
        <div class="card-header">
          <h3>Status das Peças / Subsistemas</h3>
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
            ${isSpawning ? 'Retirando...' : 'Retirar na Garagem Próxima'}
          </button>
          
          <button id="btn-pay-debt" class="os-btn os-btn-primary" ${outstandingBalance <= 0 || isPaying ? 'disabled' : ''}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="4" width="20" height="16" rx="2" ry="2"/>
              <line x1="12" y1="4" x2="12" y2="20"/>
            </svg>
            Quitar Débito Operacional
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

  window.showToast('Garagem', 'Solicitando retirada do veículo...');

  window.postNUI('tablet_spawn_vehicle', { vehicleId: veh.id }).then(resp => {
    isSpawning = false;
    if (spawnBtn) spawnBtn.disabled = !(Number(veh.state) === 1);

    if (resp && resp.ok) {
      window.showToast('Sucesso', 'Veículo retirado com sucesso! Siga o GPS.', 5000);
      
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
      window.showToast('Erro de Spawn', resp.message || 'Garagem muito distante ou indisponível.', 5000);
    }
  });
}

function handlePayDebt(veh, amount) {
  if (isPaying) return;

  window.showConfirmationModal(
    'Quitar Débito Operacional',
    `Deseja realmente pagar a taxa de manutenção de $ ${amount.toLocaleString('pt-BR')} para o veículo ${veh.vehicle}?`,
    () => {
      isPaying = true;
      const payBtn = document.getElementById('btn-pay-debt');
      if (payBtn) payBtn.disabled = true;

      window.showToast('Banco', 'Processando pagamento...');

      window.postNUI('tablet_pay_operational_debt', { vehicleId: veh.id }).then(resp => {
        isPaying = false;
        
        if (resp && resp.ok) {
          window.showToast('Sucesso', 'Débito quitado com sucesso!', 4000);
          if (resp.payload) {
            window.OSState.payload = resp.payload;
            const updatedVeh = (resp.payload.garage && resp.payload.garage.vehicles) ? resp.payload.garage.vehicles.find(v => Number(v.id) === Number(veh.id)) : null;
            if (updatedVeh) {
              renderVehicleDetails(updatedVeh);
            }
          }
        } else {
          window.showToast('Falha no Pagamento', resp.message || 'Saldo insuficiente ou falha bancária.', 5000);
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
