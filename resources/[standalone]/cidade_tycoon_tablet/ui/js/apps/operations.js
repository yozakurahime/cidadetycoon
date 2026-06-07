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
        <h3>Serviço Ativo</h3>
        <span class="tutorial-badge" style="background: rgba(255,255,255,0.05); color: var(--text-muted);">Inativo</span>
      </div>
      <div class="empty-state" style="padding: 20px;">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width: 36px; height: 36px;">
          <rect x="2" y="7" width="20" height="14" rx="2" ry="2"/>
          <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
        </svg>
        <p>Nenhum contrato logístico ativo no momento. Vá até um dos Hubs Logísticos no mapa para iniciar um frete.</p>
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
      <h3>Serviço Logístico Ativo</h3>
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
        Abortar Serviço (Multa de Cancelamento)
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

      window.showToast('Logística', 'Cancelando frete...');

      window.postNUI('cancelActiveJob').then(resp => {
        isCancelling = false;
        
        if (resp && resp.ok) {
          window.showToast('Sucesso', 'Serviço cancelado com sucesso. Multa aplicada.', 4000);
          if (resp.payload) {
            window.OSState.payload = resp.payload;
            renderOperations(resp.payload);
          }
        } else {
          window.showToast('Erro', resp.message || 'Não foi possível cancelar o serviço.', 5000);
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
        <p>Você já concluiu o Onboarding inicial. O guia está desativado.</p>
      </div>
    `;
    return;
  }

  const stepMap = {
    welcome: {
      title: 'Boas-vindas a Cidade Tycoon',
      desc: 'Abra seu tablet e confira suas opções para iniciar. Seu guia de operações começará agora.'
    },
    go_to_garage: {
      title: 'Vá até sua Garagem',
      desc: `Siga a rota marcada em seu GPS até a garagem designada (${escapeHTML(tutorial.assignedGarage || 'Garagem')}) para retirar seu primeiro veículo.`
    },
    retrieve_bike: {
      title: 'Retire sua Faggio',
      desc: 'Abra a garagem e retire seu veículo inicial (Faggio) para poder fazer suas entregas de onboarding.'
    },
    go_to_hub: {
      title: 'Dirija-se ao Hub Logístico',
      desc: `Siga a rota no mapa até o Hub Logístico designado (${escapeHTML(tutorial.assignedHubName || 'Hub Inicial')}) para coletar sua carga.`
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
    title: 'Objetivo de Operação',
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
