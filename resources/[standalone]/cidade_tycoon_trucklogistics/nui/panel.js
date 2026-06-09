var serverTimeOffset = 0;
var timerInterval = null;

window.addEventListener('message', function (event) {
	var item = event.data;
	if (item.showmenu){
		var config = item.dados.config;
		var contracts = item.dados.trucker_available_contracts || [];
		var users = item.dados.trucker_users || {};
		var myFrota = item.dados.trucker_trucks || [];
		var drivers = item.dados.trucker_drivers || [];
		var loans = item.dados.trucker_loans || [];

		if (item.dados.server_time) {
			serverTimeOffset = item.dados.server_time - Math.floor(Date.now() / 1000);
		}

		if(item.update != true){
			$(".pages").hide();
			$("body").css("display", "flex");
			$('.sidebar-navigation ul li').removeClass('active');
			if (item.openFuelPage) {
				$('#sidebar-fuel').addClass('active');
				openPage(10);
			} else {
				$('#sidebar-1').addClass('active');
				openPage(0);
			}
		}

		// --- PROFILE STATS ---
		$('#profile-money').text(formatCurrency(users.money || 0, config));
		$('#profile-deliveries').text(users.finished_deliveries || 0);
		$('#profile-distance-traveled').text((users.traveled_distance || 0).toFixed(1) + 'km');
		$('#profile-exp-1').text('EXP: ' + (users.exp || 0));
		
		var exp_percentage = calculateExpPercentage(users.exp || 0, config.exp_por_level);
		$('#profile-exp-2 .progress-bar').css('width', exp_percentage + '%');
		$('#bank-money').text(formatCurrency(users.money || 0, config));

		// Team Totals
		var teamProfit = 0, teamDeliveries = 0, teamDistance = 0, teamSize = 0;
		drivers.forEach(d => {
			if (d.user_id && d.user_id != 0) {
				teamProfit += (d.total_profit || 0) - (d.total_spent || 0);
				teamDeliveries += (d.finished_deliveries || 0);
				teamDistance += (d.traveled_distance || 0);
				teamSize++;
			}
		});
		$('#team-profit').text(formatCurrency(teamProfit, config));
		$('#team-deliveries').text(teamDeliveries);
		$('#team-distance').text(teamDistance.toFixed(1) + 'km');
		$('#team-size').text(teamSize);

		// --- JOBS ---
		$('#job-page-list').empty();
		$('#freight-page-list').empty();
		contracts.forEach(contract => {
			var lock = checkLock(contract, users, config);
			var jobHtml = `
				<div class="job-card ${lock.isLocked ? "locked-job" : ""}">
					${lock.isLocked ? `<span class="locked-tag">${lock.reason}</span>` : ""}
					<div class="job-info-main">
						<h6>${contract.contract_name}</h6>
						<div class="job-details-row">
							<div class="job-detail-item"><svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg><span>${contract.distance}km</span></div>
							<div class="job-detail-item"><svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.24 2 7s4.48 5 10 5 10-2.24 10-5-4.48-5-10-5zm0 13c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5zm0 5c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5z"/></svg><span>${formatCurrency(contract.reward, config)}</span></div>
						</div>
					</div>
					<div class="job-actions">
						<div class="cargo-icons-wrapper">${getCargoIcons(contract)}</div>
						<button ${lock.isLocked ? "disabled" : `onclick="startJob(${contract.contract_id}, ${contract.reward}, ${contract.distance})"`} class="btn btn-blue white">Iniciar</button>
					</div>
				</div>`;
			if(contract.contract_type == 0) $('#job-page-list').append(jobHtml);
			else $('#freight-page-list').append(jobHtml);
		});

		// --- SKILLS ---
		['product_type', 'distance', 'valuable', 'fragile', 'fast'].forEach(s => setSkill(s, users[s] || 0));

		// --- DIAGNOSTICS ---
		updateDiagnostics(myFrota.find(t => t.driver === 0 || t.driver === '0'), config);

		// --- DEALERSHIP ---
		$('#dealership-page-list').empty();
		for (const key in config.concessionaria) {
			let truck = config.concessionaria[key];
			$('#dealership-page-list').append(`
				<div class="truck-card">
					<div class="truck-card-img"><img src="${truck.img}"></div>
					<div class="truck-card-content">
						<div class="truck-card-header"><h3>${truck.name}</h3><span>${formatCurrency(truck.price, config)}</span></div>
						<div class="truck-card-specs">
							<div class="spec-item"><span class="spec-label">Motor</span><span class="spec-value">${truck.engine}</span></div>
							<div class="spec-item"><span class="spec-label">Transmissão</span><span class="spec-value">${truck.transmission}</span></div>
						</div>
						<button onclick="buyTruck('${key}', ${truck.price})" class="btn btn-blue white btn-block">Comprar</button>
					</div>
				</div>`);
		}

		// --- FLEET ---
		$('#trucks-page-list').empty();
		myFrota.forEach(truck => {
			var truckData = config.concessionaria[truck.truck_name];
			if (!truckData) return;
			var driverName = "Nenhum", statusColor = "#919aa3";
			if (truck.driver === 0 || truck.driver === '0') { driverName = "Uso Pessoal"; statusColor = "#5c6bc0"; }
			else if (truck.driver != null && truck.driver > 0) {
				var d = drivers.find(drv => drv.driver_id == truck.driver);
				if (d) { driverName = d.name; statusColor = "#63d19e"; }
			}
			$('#trucks-page-list').append(`
				<div class="job-card" style="flex-direction: column; align-items: stretch; padding: 15px;">
					<div class="d-flex justify-content-between align-items-center mb-2">
						<div class="d-flex align-items-center">
							<img src="${truckData.img}" style="width: 60px; margin-right: 12px; border-radius: 4px;">
							<div>
								<h6 class="mb-0" style="font-size:13px;">${truckData.name} <small class="text-muted">#${truck.truck_id}</small></h6>
								<span style="font-size:9px; font-weight:800; color:${statusColor}; text-transform:uppercase;">Status: ${driverName}</span>
							</div>
						</div>
						<div class="job-actions">${getMyTruckButtons(truck)}<button onclick="sellTruck(${truck.truck_id}, '${truck.truck_name}')" class="btn btn-red white">Vender</button></div>
					</div>
					<div class="driver-stats-grid" style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; background: #f8f9fa; padding: 8px; border-radius: 6px; border: 1px solid #eee;">
						<div class="d-flex flex-column text-center"><span style="font-size:7px; font-weight:800; color:#919aa3;">MOTOR</span><span style="font-size:10px; font-weight:700;">${(truck.engine/10).toFixed(0)}%</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:7px; font-weight:800; color:#919aa3;">CÂMBIO</span><span style="font-size:10px; font-weight:700;">${(truck.transmission/10).toFixed(0)}%</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:7px; font-weight:800; color:#919aa3;">CHASSI</span><span style="font-size:10px; font-weight:700;">${(truck.body/10).toFixed(0)}%</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:7px; font-weight:800; color:#919aa3;">RODAS</span><span style="font-size:10px; font-weight:700;">${(truck.wheels/10).toFixed(0)}%</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:7px; font-weight:800; color:#919aa3;">REVENDA</span><span style="font-size:10px; font-weight:700; color:#63d19e;">${formatCurrency(truckData.price * 0.6, config)}</span></div>
					</div>
				</div>`);
		});

		// --- ACTIVE DRIVERS ---
		$('#drivers-page-list').empty();
		drivers.filter(d => d.user_id && d.user_id != 0).forEach(driver => {
			const statusLabels = { 'IDLE': 'Disponível', 'PREPARING': 'Preparando', 'LOADING': 'Carregando', 'TRANSIT': 'Em Rota', 'RETURNING': 'Retornando', 'WAITING_DECISION': '🚨 AGUARDANDO DECISÃO' };
			const displayStatus = statusLabels[driver.status] || 'Operacional';
			const statusColor = driver.status == 'WAITING_DECISION' ? '#d16363' : (driver.status == 'TRANSIT' ? '#63d19e' : (driver.status == 'IDLE' ? '#919aa3' : '#5c6bc0'));

			var trainCost = config.motoristas ? Math.floor(config.motoristas.preco_min * 0.5 * (1.3 ** (driver.level || 1))) : 0;

			$('#drivers-page-list').append(`
				<div class="job-card expandable-driver-card" style="flex-direction: column; align-items: stretch; padding: 15px; ${driver.status == 'WAITING_DECISION' ? 'border: 2px solid #d16363;' : ''}">
					<div class="d-flex justify-content-between align-items-center mb-3">
						<div class="d-flex align-items-center">
							<img src="${driver.img}" style="width:45px; height:45px; border-radius:50%; margin-right: 12px; border: 2px solid #eee;">
							<div>
								<div class="d-flex align-items-center gap-2">
									<h6 class="mb-0" style="font-weight:900; color:#1a1c23;">${driver.name} <span style="background:#1a1c23; color:#63d19e; padding:2px 8px; border-radius:4px; font-size:10px; font-weight:900; margin-left:10px; border:1px solid #63d19e;">NÍVEL ${driver.level || 1}</span></h6>
									<span class="badge-timer" data-expiry="${driver.timer}" style="font-size:9px; font-weight:700; color:#919aa3; background:#f0f2f5; padding:2px 6px; border-radius:4px;">--:--</span>
								</div>
								<span style="font-size:10px; font-weight:800; color:${statusColor}; text-transform:uppercase;">${driver.active_event ? `⚠️ ${driver.active_event}` : displayStatus}</span>
							</div>
						</div>
						<div class="job-actions">
							${driver.status == 'IDLE' ? `<button onclick="trainDriver(${driver.driver_id})" class="btn btn-blue white" style="font-size:9px !important;">Treinar (${formatCurrency(trainCost, config)})</button>` : ""}
							<select class="btn btn-premium py-1" style="background:#f0f2f5; color:#313443; font-size:10px; min-width:150px;" onchange="setDriver(this.options[this.selectedIndex].getAttribute('driver_id'),this.options[this.selectedIndex].getAttribute('truck_id'));">
								${getDriverAvailableFrotaHTML(myFrota, driver, config)}
							</select>
							<button onclick="fireDriver(${driver.driver_id})" class="btn btn-red white" style="padding: 5px 10px !important;"><svg style="width:14px; fill:white;" viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg></button>
						</div>
					</div>
					
					${driver.status == 'WAITING_DECISION' ? `<div class="crisis-box mb-2" style="background:#fff5f5; border:1px dashed #d16363; padding:10px; border-radius:8px;"><h6 style="color:#d16363; font-size:10px; font-weight:900;">GESTÃO DE CRISE: ${driver.active_event}</h6><div class="d-flex gap-2">${getCrisisOptionsHTML(driver)}</div></div>` : ""}

					<div class="driver-expanded-content" style="display:none; margin-bottom:10px; background:#f0f2f5; padding:10px; border-radius:8px;">
						<h6 style="font-size:8px; font-weight:800; color:#313443; text-transform:uppercase; margin-bottom:5px;">Histórico da Viagem / Logs</h6>
						<div class="adversity-list">${getRouteEventsHTML(driver.route_events)}</div>
						<div class="d-flex justify-content-between mt-2 pt-2" style="border-top:1px solid #ddd;">
							<div class="d-flex flex-column"><span style="font-size:7px; font-weight:800; color:#919aa3;">CARGA ATUAL</span><span style="font-size:10px; font-weight:700;">${driver.current_cargo_name || '---'}</span></div>
							<div class="d-flex flex-column text-right"><span style="font-size:7px; font-weight:800; color:#919aa3;">TEMPO SERVIÇO</span><span style="font-size:10px; font-weight:700; color:#5c6bc0;">${formatTime(driver.total_work_time)}</span></div>
						</div>
					</div>

					<div class="driver-stats-grid" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; background: #f8f9fa; padding: 10px; border-radius: 8px; border: 1px solid #eee; cursor:pointer;" onclick="$(this).parent().find('.driver-expanded-content').slideToggle(200)">
						<div class="d-flex flex-column text-center"><span style="font-size:8px; font-weight:800; color:#919aa3;">ENTREGAS</span><span style="font-size:11px; font-weight:700;">${driver.finished_deliveries || 0}</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:8px; font-weight:800; color:#919aa3;">KM TOTAL</span><span style="font-size:11px; font-weight:700;">${(driver.traveled_distance || 0).toFixed(0)}km</span></div>
						<div class="d-flex flex-column text-center"><span style="font-size:8px; font-weight:800; color:#919aa3;">LUCRO LÍQUIDO</span><span style="font-size:11px; font-weight:700; color:#63d19e;">${formatCurrency((driver.total_profit || 0) - (driver.total_spent || 0), config)}</span></div>
					</div>
				</div>`);
		});

		// --- RECRUITMENT ---
		$('#recruitment-page-list').empty();
		drivers.filter(d => !d.user_id || d.user_id == 0).forEach(driver => {
			$('#recruitment-page-list').append(`
				<div class="truck-card">
					<div class="truck-card-img"><img src="${driver.img}" style="width:80px; border-radius:50%;"></div>
					<div class="truck-card-content text-center">
						<h3 class="truck-card-title">${driver.name}</h3>
						<p class="text-muted mb-2" style="font-size:11px;">Custo: ${formatCurrency(driver.price, config)} + ${formatCurrency(driver.price_per_km, config)}/km</p>
						<div class="mb-3"><div class="d-flex justify-content-center gap-1" style="transform:scale(0.7);">${getDriverLevelHTML(driver.product_type)}</div></div>
						<button ${config.motoristas && users.exp_level < config.motoristas.nivel_minimo_contratacao ? "disabled" : ""} onclick="hireDriver(${driver.driver_id})" class="btn btn-blue white btn-block">Contratar</button>
					</div>
				</div>`);
		});

		startTicking();

		// --- BANK ---
		$('#loan-options-grid').empty();
		for (var i = 1; i <= 4; i++) {
			let l = (config.emprestimos || {})[i] || (config.emprestimos || {})[String(i)];
			if(l) {
				$('#loan-options-grid').append(`<div class="loan-card" onclick="loan(${i})"><div class="loan-info"><h3 class="text-success" style="color:#63d19e !important;">${formatCurrency(l[0], config)}</h3><span>Parcela: ${formatCurrency(l[1], config)} / dia</span></div><svg style="width:30px; fill:#63d19e;" viewBox="0 0 24 24"><path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 3.98 2.53.47 3.3 1.12 3.3 2.23 0 1.49-1.32 2.12-3.04 2.12-2.1 0-2.95-.94-3.05-2.27H6.06c.1 2.12 1.49 3.39 3.44 3.82V21h3v-2.19c1.95-.42 3.5-1.44 3.5-3.61 0-2.45-1.72-3.69-4.7-4.31z"/></svg></div>`);
			}
		}
		$('#loan-list').empty();
		if(loans && loans.length > 0) {
			$('#active-loans-section').show();
			loans.forEach(loan => {
				$('#loan-list').append(`<div class="job-card" style="border-left:5px solid #d16363;"><div class="job-info-main"><h6 style="color:#d16363;">Empréstimo Ativo</h6><div class="job-details-row"><span>Saldo Devedor: ${formatCurrency(loan.remaining_amount, config)}</span></div></div><button onclick="payLoan(${loan.id})" class="btn btn-red white">Quitar Total</button></div>`);
			});
		} else $('#active-loans-section').hide();
	}
	if (item.hidemenu) { $("body").hide(); if (timerInterval) clearInterval(timerInterval); }
});

// --- HELPERS ---

function formatTime(seconds) {
    if (!seconds || seconds <= 0) return "0h";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

function getRouteEventsHTML(eventsJSON) {
	if (!eventsJSON) return "<span style='font-size:9px; color:#919aa3;'>Nenhum evento registrado.</span>";
	try {
		const events = JSON.parse(eventsJSON);
		if (!events.length) return "<span style='font-size:9px; color:#919aa3;'>Nenhum evento registrado.</span>";
		var html = "";
		events.forEach(ev => {
			html += `<div class="d-flex justify-content-between align-items-center mb-1" style="font-size:9px; color:#313443;"><span>• ${ev.name}</span><span style="font-weight:800; color:#d16363;">${ev.time > 0 ? '+' : ''}${ev.time}m</span></div>`;
		});
		return html;
	} catch(e) { return ""; }
}

function getCrisisOptionsHTML(driver) {
    if (!driver.pending_event_data) return "";
    try {
        const d = JSON.parse(driver.pending_event_data);
        if (d.type == 'PRF') return `<button onclick="resolveCrisis(${driver.driver_id}, 'cooperate')" class="btn btn-success white flex-grow-1">Cooperar</button><button onclick="resolveCrisis(${driver.driver_id}, 'bribe')" class="btn btn-warning white flex-grow-1">Subornar</button><button onclick="resolveCrisis(${driver.driver_id}, 'flee')" class="btn btn-red white flex-grow-1">Fugir</button>`;
        if (d.type == 'BREAKDOWN') return `<button onclick="resolveCrisis(${driver.driver_id}, 'official')" class="btn btn-blue white flex-grow-1">Oficial</button><button onclick="resolveCrisis(${driver.driver_id}, 'cheap')" class="btn btn-warning white flex-grow-1">Gambiarra</button>`;
        if (d.type == 'ROBBERY') return `<button onclick="resolveCrisis(${driver.driver_id}, 'surrender')" class="btn btn-red white flex-grow-1">Entregar Carga</button><button onclick="resolveCrisis(${driver.driver_id}, 'reag')" class="btn btn-warning white flex-grow-1">Acelerar</button><button onclick="resolveCrisis(${driver.driver_id}, 'police')" class="btn btn-success white flex-grow-1">Ligar Polícia</button>`;
        if (d.type == 'PROTEST') return `<button onclick="resolveCrisis(${driver.driver_id}, 'detour')" class="btn btn-warning white flex-grow-1">Pegar Desvio</button><button onclick="resolveCrisis(${driver.driver_id}, 'wait_out')" class="btn btn-success white flex-grow-1">Aguardar</button><button onclick="resolveCrisis(${driver.driver_id}, 'ram')" class="btn btn-red white flex-grow-1">Furar Bloqueio</button>`;
        if (d.type == 'CONTRABAND') return `<button onclick="resolveCrisis(${driver.driver_id}, 'decline')" class="btn btn-success white flex-grow-1">Recusar</button><button onclick="resolveCrisis(${driver.driver_id}, 'accept_smuggle')" class="btn btn-warning white flex-grow-1">Aceitar Carga</button>`;
        if (d.type == 'BLIZZARD') return `<button onclick="resolveCrisis(${driver.driver_id}, 'shelter')" class="btn btn-success white flex-grow-1">Parar Posto</button><button onclick="resolveCrisis(${driver.driver_id}, 'slow_drive')" class="btn btn-blue white flex-grow-1">Ir Devagar</button><button onclick="resolveCrisis(${driver.driver_id}, 'speed_up')" class="btn btn-red white flex-grow-1">Acelerar</button>`;
    } catch(e) { console.error(e); }
	return "";
}

function startTicking() { if (timerInterval) clearInterval(timerInterval); timerInterval = setInterval(updateTimers, 1000); updateTimers(); }
function updateTimers() {
	const now = Math.floor(Date.now() / 1000) + serverTimeOffset;
	$('.badge-timer').each(function() {
		const expiry = parseInt($(this).data('expiry'));
		if (expiry > 0) {
			const diff = expiry - now;
			if (diff > 0) { const m = Math.floor(diff / 60); const s = diff % 60; $(this).text(`${m}m ${s}s`); }
			else $(this).text('Concluindo...');
		} else $(this).hide();
	});
}

function formatCurrency(amount, config) {
	if (!config || !config.formatacao) return "$" + amount;
	return new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda, maximumFractionDigits: 0, minimumFractionDigits: 0 }).format(amount);
}

function checkLock(contract, users, config) {
	if (Number(users.product_type || 0) < Number(contract.cargo_type)) return { isLocked: true, reason: "ADR nível " + contract.cargo_type };
	if (Number(users.fragile || 0) < Number(contract.fragile)) return { isLocked: true, reason: "Carga Frágil" };
	if (Number(users.valuable || 0) < Number(contract.valuable)) return { isLocked: true, reason: "Carga Valiosa" };
	if (Number(users.fast || 0) < Number(contract.fast)) return { isLocked: true, reason: "Entrega Urgente" };
	var maxDist = 0; if (config.habilidade_distancia) maxDist = config.habilidade_distancia[users.distance] || config.habilidade_distancia[String(users.distance)] || 0;
	if (Number(contract.distance) > Number(maxDist)) return { isLocked: true, reason: "Distância (" + maxDist + "km)" };
	return { isLocked: false };
}

function getCargoIcons(contract) {
	var html = "";
	const icons = { 1: { tooltip: "Explosivos", color: "#ff5722", d: "M12 2L22 12L12 22L2 12Z" }, 2: { tooltip: "Gases Inflamáveis", color: "#f44336", d: "M12 2L22 12L12 22L2 12Z" }, 3: { tooltip: "Líquidos Inflamáveis", color: "#d32f2f", d: "M12 2L22 12L12 22L2 12Z" }, 4: { tooltip: "Sólidos Inflamáveis", color: "#ff9800", d: "M12 2L22 12L12 22L2 12Z" }, 5: { tooltip: "Substâncias Tóxicas", color: "#607d8b", d: "M12 2L22 12L12 22L2 12Z" }, 6: { tooltip: "Substâncias Corrosivas", color: "#3f51b5", d: "M12 2L22 12L12 22L2 12Z" } };
	if(icons[contract.cargo_type]) { let ic = icons[contract.cargo_type]; html += `<div data-tooltip="${ic.tooltip}"><svg class="cargo-svg" viewBox="0 0 24 24" style="width:20px; height:20px;"><path d="${ic.d}" fill="${ic.color}"/></svg></div>`; }
	if(contract.fragile == 1) html += '<div data-tooltip="Carga Frágil"><svg class="cargo-svg" viewBox="0 0 24 24" style="width:20px; height:20px;"><circle cx="12" cy="12" r="10" fill="#00bcd4"/></svg></div>';
	if(contract.valuable == 1) html += '<div data-tooltip="Carga Valiosa"><svg class="cargo-svg" viewBox="0 0 24 24" style="width:20px; height:20px;"><circle cx="12" cy="12" r="10" fill="#e91e63"/></svg></div>';
	if(contract.fast == 1) html += '<div data-tooltip="Urgente"><svg class="cargo-svg" viewBox="0 0 24 24" style="width:20px; height:20px;"><circle cx="12" cy="12" r="10" fill="#ff9800"/></svg></div>';
	return html;
}

function setSkill(id, newValue) {
	var target = $('#' + id); if (!target.length) return; target.empty();
	for (var i = 1; i <= 6; i++) {
		if(i <= newValue) { if(i > 1) target.append('<span class="line"></span>'); target.append(`<div class="steps"><span class="font-weight-bold">${i}</span></div>`); }
		else { if(i > 1) target.append('<span class="redline"></span>'); target.append(`<div class="redsteps" onclick="upgradeSkill('${id}',${i})"><span class="font-weight-bold">${i}</span></div>`); }
	}
}

function updateDiagnostics(truck, config) {
	if (!truck) { $('#truck-name-display').text('Nenhum Veículo Ativo'); $('#truck-plate-display').text('---'); $('.diagnostic-card').css('opacity', '0.5'); return; }
	var truckData = config.concessionaria[truck.truck_name];
	$('#truck-name-display').text(truckData.name); $('#truck-plate-display').text(truck.plate || 'FROTA #' + truck.truck_id); $('#diagnostic-truck-img').attr('src', truckData.img);
	const components = ['body', 'engine', 'transmission', 'wheels'];
	const statusLabels = { excellent: 'Excelente', good: 'Bom', fair: 'Regular', critical: 'Crítico' };
	components.forEach(comp => {
		var percent = Math.floor(truck[comp] / 10);
		var status = percent >= 90 ? 'excellent' : percent >= 70 ? 'good' : percent >= 40 ? 'fair' : 'critical';
		var color = percent >= 90 ? 'bg-success' : percent >= 70 ? 'bg-info' : percent >= 40 ? 'bg-warning' : 'bg-danger';
		$(`#status-${comp}`).text(statusLabels[status]).attr('class', 'diagnostic-status-badge status-' + status);
		$(`#percentage-${comp}`).text(percent + '%'); $(`#cost-${comp}`).text('Reparo: ' + formatCurrency((100 - percent) * config.valor_reparo[comp], config));
		$(`#progress-${comp}`).css('width', percent + '%').attr('class', 'diag-progress-bar ' + color); $(`#card-${comp}`).css('opacity', '1');
	});
}

function getMyTruckButtons(truck) { if(truck.driver === 0 || truck.driver === '0') return `<button onclick="spawnTruck(${truck.truck_id})" class="btn btn-blue white mr-1">Retirar</button><button onclick="setDriver(null, ${truck.truck_id})" class="btn btn-blue white">Desmarcar</button>`; return `<button onclick="setDriver('0', ${truck.truck_id})" class="btn btn-blue white">Selecionar</button>`; }
function getDriverLevelHTML(value) { var html = ""; for (var i = 1; i <= 6; i++) html += `<li class="${i <= value ? 'actived' : ''}"></li>`; return html; }
function getDriverAvailableFrotaHTML(myFrota, driver, config) {
	var html = "", has_truck = false, assignedTruckId = "";
	myFrota.forEach(truck => {
		if (truck.driver == driver.driver_id) { 
			has_truck = true; 
			assignedTruckId = truck.truck_id; 
			html += `<option selected="selected" truck_id="${truck.truck_id}" driver_id="${driver.driver_id}">${config.concessionaria[truck.truck_name].name}</option>`; 
		} else if (truck.driver === null || truck.driver === undefined || truck.driver === false) { 
			html += `<option truck_id="${truck.truck_id}" driver_id="${driver.driver_id}">${config.concessionaria[truck.truck_name].name}</option>`; 
		}
	});
	return (has_truck ? `<option driver_id="0" truck_id="${assignedTruckId}">Remover Veículo</option>` : `<option selected="selected">Designar Veículo</option>`) + html;
}

function calculateLevel(exp, expTable) { if (!expTable) return 1; var level = 0; for (let i in expTable) { if (exp >= expTable[i]) level = i; } return parseInt(level) + 1; }
function calculateExpPercentage(exp, expTable) { if (!expTable) return 0; var level = calculateLevel(exp, expTable) - 1; var currentExpLimit = expTable[level] || 0; var nextExpLimit = expTable[level + 1] || currentExpLimit + 1000; var needed = nextExpLimit - currentExpLimit; var has = exp - currentExpLimit; return Math.min(Math.max((has / needed) * 100, 0), 100); }

function trainDriver(id) { 
    $(`.expandable-driver-card`).each(function() {
        if ($(this).find(`button[onclick*="trainDriver(${id})"]`).length > 0) {
            $(this).addClass('success-trained');
            setTimeout(() => $(this).removeClass('success-trained'), 1500);
        }
    });
    post("trainDriver", id); 
}
function resolveCrisis(id, opt) { post("resolveCrisis", {driver_id: id, option: opt}); }
function openPage(pageN) { $(".pages").hide(); const p = [".main-page", ".job-page", ".freight-page", ".skills-page", ".diagnostic-page", ".dealership-page", ".trucks-page", ".recruitment-page", ".drivers-page", ".bank-page", ".fuel-page"]; $(p[pageN]).show(); if (pageN === 10) refreshFuel(); }
function closeUI() { post("close", "") }
function startJob(id, r, d) { post("startJob", {id: id, reward: r, distance: d}) }
function buyTruck(name, price) { post("buyTruck", {truck_name: name, price: price}) }
function sellTruck(id, name) { post("sellTruck", {truck_id: id, truck_name: name}) }
function spawnTruck(id) { post("spawnTruck", {truck_id: id}) }
function fireDriver(id) { post("fireDriver", {driver_id: id}) }
function hireDriver(id) { post("hireDriver", {driver_id: id}) }
function upgradeSkill(id, val) { post("upgradeSkill", {id: id, value: val}) }
function repairTruck(id) { post("repairTruck", {id: id}) }
function setDriver(d_id, t_id) { post("setDriver", {driver_id: d_id, truck_id: t_id}) }
function loan(id) { post("loan", {loan_id: id}) }
function payLoan(id) { post("payLoan", {loan_id: id}) }
function buyFuelBatch(liters, cost, deliver) { post("buyFuelBatch", {liters: liters, cost: cost, deliver: deliver, empresaId: 0}) }
function depositJerrycan() { post("depositJerrycan", {}) }
function refreshFuel() { post("refreshFuel", {}) }
function depositMoney() { var a = $('#input-deposit-money').val(); if (!a) return; $('#input-deposit-money').val(''); post("depositMoney", {amount: a}); }
function withdrawMoney() { post("withdrawMoney", {}) }
function post(name, data) { $.post("https://cidade_tycoon_trucklogistics/" + name, JSON.stringify(data)); }

document.onkeyup = function(data) { if (data.which == 27 && $("body").is(":visible")) closeUI(); };
$('.sidebar-navigation ul li').on('click', function() { $('.sidebar-navigation ul li').removeClass('active'); $(this).addClass('active'); });
$(document).on('click', '.collapsible', function() { $(this).toggleClass("active"); $(this).next(".content").slideToggle(200); });

$(document).ready(function() {
	if (window.self !== window.top) {
		$('body').addClass('iframe-mode');
		$('body').css('background-color', 'transparent');
		$('.sidebar-navigation ul li').last().hide();
	}
});
// Fuel page auto-refresh
var fuelCheckInterval = null;
window.addEventListener('message', function (event) {
    var item = event.data;
    if (item.action === 'updateStations') {
        var arr = item.stations || [];
        fuelStations = {};
        for (var i = 0; i < arr.length; i++) { var s = arr[i]; fuelStations[s.id] = s; }
        fuelPlayerX = item.playerX || 0;
        fuelPlayerY = item.playerY || 0;
        drawFuelMap();
        if ($('.fuel-page').is(':visible') && !fuelCheckInterval) {
            fuelCheckInterval = setInterval(function() {
                if (!$('.fuel-page').is(':visible')) { clearInterval(fuelCheckInterval); fuelCheckInterval = null; }
                else { refreshFuel(); requestStations(); }
            }, 20000);
        }
    }
        if (item.action === 'updateFuel') {
        var fuelStock = item.fuelStock || 0;
        $('#fuel-stock-display').text(fuelStock + ' L');
        $('#fuel-company-money').text(item.money ? '$ ' + Number(item.money).toLocaleString('pt-BR') : '---');
        if ($('.fuel-page').is(':visible') && !fuelCheckInterval) {
            fuelCheckInterval = setInterval(function() {
                if (!$('.fuel-page').is(':visible')) {
                    clearInterval(fuelCheckInterval);
                    fuelCheckInterval = null;
                } else {
                    refreshFuel();
                }
            }, 5000);
        }
    }
});



// =========================================================================
// FUEL STATION MAP SYSTEM (full-width canvas)
// =========================================================================
var fuelStations = {};
var fuelPlayerX = 0, fuelPlayerY = 0;
var selectedStationId = null;
var fuelMapReady = false;

function requestStations() {
    post("requestStations", {});
    document.getElementById("fuel-map-hint").innerHTML = "Carregando postos...";
}

function buyFromStation() {
    if (!selectedStationId) return;
    var liters = parseInt(document.getElementById("fuel-sel-liters").value) || 200;
    if (liters < 50) liters = 50;
    if (liters > 2000) liters = 2000;
    post("buyFromStation", { stationId: selectedStationId, liters: liters });
}

function setFuelWaypoint() {
    var s = fuelStations[selectedStationId];
    if (!s) return;
    post("setFuelWaypoint", { x: s.coords.x, y: s.coords.y });
}

function drawFuelMap() {
    var canvas = document.getElementById("fuel-canvas");
    if (!canvas) return;
    var ctx = canvas.getContext("2d");
    var w = canvas.clientWidth, h = canvas.clientHeight;
    canvas.width = w; canvas.height = h;
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = "#0b0c10"; ctx.fillRect(0, 0, w, h);
    var keys = Object.keys(fuelStations);
    if (keys.length === 0) return;
    var hint = document.getElementById("fuel-map-hint");
    if (hint) hint.style.display = "none";
    fuelMapReady = true;
    // Calculate bounds
    var minX = fuelPlayerX, maxX = fuelPlayerX, minY = fuelPlayerY, maxY = fuelPlayerY;
    for (var k in fuelStations) {
        var s = fuelStations[k];
        if (s.coords.x < minX) minX = s.coords.x;
        if (s.coords.x > maxX) maxX = s.coords.x;
        if (s.coords.y < minY) minY = s.coords.y;
        if (s.coords.y > maxY) maxY = s.coords.y;
    }
    var padX = (maxX - minX) * 0.2 || 400;
    var padY = (maxY - minY) * 0.2 || 400;
    minX -= padX; maxX += padX; minY -= padY; maxY += padY;
    function sx(cx) { return ((cx - minX) / (maxX - minX)) * w; }
    function sy(cy) { return h - ((cy - minY) / (maxY - minY)) * h; }
    // Grid
    ctx.strokeStyle = "#14161d"; ctx.lineWidth = 0.5;
    for (var i = 0; i < w; i += 30) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, h); ctx.stroke(); }
    for (var j = 0; j < h; j += 30) { ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(w, j); ctx.stroke(); }
    // Draw stations
    fuelStations._screenPos = {};
    for (var k in fuelStations) {
        var s = fuelStations[k];
        var x = sx(s.coords.x), y = sy(s.coords.y);
        fuelStations._screenPos[s.id] = { x: x, y: y };
        var isSel = (s.id === selectedStationId);
        // Dot
        ctx.beginPath(); ctx.arc(x, y, isSel ? 8 : 5, 0, Math.PI * 2);
        var color;
        if (s.preco < 38) color = "#63d19e";
        else if (s.preco < 42) color = "#ffcc00";
        else color = "#ff6464";
        ctx.fillStyle = color; ctx.fill();
        ctx.strokeStyle = isSel ? "#fff" : "#1a1c23";
        ctx.lineWidth = isSel ? 2.5 : 1.5; ctx.stroke();
        // Label
        ctx.fillStyle = "#fff"; ctx.font = "bold 9px Inter, sans-serif";
        ctx.textAlign = "center"; ctx.fillText("$" + s.preco, x, y - 12);
    }
    // Player marker
    var px = sx(fuelPlayerX), py = sy(fuelPlayerY);
    ctx.beginPath(); ctx.arc(px, py, 6, 0, Math.PI * 2);
    ctx.fillStyle = "#5c6bc0"; ctx.fill();
    ctx.strokeStyle = "#fff"; ctx.lineWidth = 2; ctx.stroke();
    ctx.fillStyle = "#fff"; ctx.font = "bold 7px Inter, sans-serif"; ctx.textAlign = "center";
    ctx.fillText("VC", px, py - 11);
}

// Canvas click → select station
document.addEventListener("DOMContentLoaded", function() {
    var canvas = document.getElementById("fuel-canvas");
    if (!canvas) return;
    canvas.addEventListener("click", function(e) {
        if (!fuelMapReady) return;
        var rect = canvas.getBoundingClientRect();
        var cx = e.clientX - rect.left, cy = e.clientY - rect.top;
        var best = null, bestDist = 20; // 20px tolerance
        var sp = fuelStations._screenPos || {};
        for (var id in sp) {
            var p = sp[id];
            var d = Math.sqrt((cx-p.x)*(cx-p.x) + (cy-p.y)*(cy-p.y));
            if (d < bestDist) { bestDist = d; best = id; }
        }
        if (best) selectStation(parseInt(best));
    });
});

function selectStation(id) {
    selectedStationId = parseInt(id);
    var s = fuelStations[id];
    if (!s) return;
    document.getElementById("fuel-sel-name").textContent = s.nome;
    document.getElementById("fuel-sel-info").textContent = "$" + s.preco + "/L | " + s.estoque + "L estoque | " + s.distancia.toFixed(1) + " km";
    document.getElementById("fuel-select-station").style.display = "block";
    document.getElementById("fuel-sel-liters").value = Math.min(500, s.estoque);
    drawFuelMap();
}
