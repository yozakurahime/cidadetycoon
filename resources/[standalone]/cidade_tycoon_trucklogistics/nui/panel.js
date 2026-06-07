window.addEventListener('message', function (event) {
	var item = event.data;
	var list_item = '';
	if (item.showmenu){
		var config = item.dados.config;
		var contracts = item.dados.trucker_available_contracts;
		var users = item.dados.trucker_users;
		var myFrota = item.dados.trucker_trucks;
		var drivers = item.dados.trucker_drivers;
		var loans = item.dados.trucker_loans;
		if(item.update != true){
			$(".pages").css("display", "none");
			$("body").css("display", "");
			$(".main-page").css("display", "block");
			$('.sidebar-navigation ul li').removeClass('active');
			$('#sidebar-1').addClass('active');
			openPage(0);
		}

		$('#new-contracts-1').empty();
		$('#new-contracts-1').append('New contracts each ' + (config.cooldown*2) + ' min');
		$('#new-contracts-2').empty();
		$('#new-contracts-2').append('New contracts each ' + (config.cooldown*2) + ' min');
		
		$('#profile-money').empty();
		$('#profile-money').append(new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda, maximumFractionDigits: 0, minimumFractionDigits: 0 }).format(users.money));
		$('#bank-money').empty();
		$('#bank-money').append(new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda, maximumFractionDigits: 0, minimumFractionDigits: 0 }).format(users.money));
		
		$('#profile-money-earned').empty();
		$('#profile-money-earned').append(new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda, maximumFractionDigits: 0, minimumFractionDigits: 0 }).format(users.total_earned));
		$('#profile-deliveries').empty();
		$('#profile-deliveries').append(users.finished_deliveries);
		$('#profile-exp-1').empty();
		$('#profile-exp-1').append(users.exp);
		$('#profile-exp-2').empty();
		var expTable = [];
		if (Array.isArray(config.exp_por_level)) {
			expTable = config.exp_por_level;
		} else {
			for (var k = 1; k <= 30; k++) {
				expTable.push(config.exp_por_level[k] || config.exp_por_level[String(k)] || (k * 1000));
			}
		}
		var exp_r = 0;
		if (users.exp >= expTable[expTable.length - 1]){
			exp_r = 100;
		} else if (config.player_level == 0) {
			var max = expTable[0];
			var exp = users.exp;
			exp_r = Math.round((exp * 100) / max);
		} else {
			for (var i = 0; i < expTable.length; i++) {
				if (users.exp < expTable[i]) {
					var prevExp = i > 0 ? expTable[i - 1] : 0;
					var max = expTable[i] - prevExp;
					var exp = users.exp - prevExp;
					exp_r = Math.round((exp * 100) / max);
					if (exp_r >= 0) {
						break;
					}
				}
			}
		}
		$('#profile-exp-2').append('<div class="progress-bar bg-amber accent-4" role="progressbar" style="width: ' + exp_r + '%" aria-valuenow="' + exp_r + '" aria-valuemin="0" aria-valuemax="100"></div>');
		$('#profile-distance-traveled').empty();
		$('#profile-distance-traveled').append(users.traveled_distance.toFixed(2) + 'km');
		$('#profile-skill-points').empty();
		$('#profile-skill-points').append(users.skill_points);
		$('#profile-trucks').empty();
		$('#profile-trucks').append(myFrota.length);
		$('#profile-drivers').empty();
		var drivers_count = 0;
		for (const driver of drivers) {
			if(driver.user_id != null && driver.user_id != undefined){
				drivers_count++;
			}
		}
		$('#profile-drivers').append(drivers_count);
		
		

		$('#job-page-list').empty();
		$('#freight-page-list').empty();
		for (const contract of contracts) {
			list_item = `
			<ul class="list list-inline">
				<li class="d-flex justify-content-between">
					<div class="d-flex flex-row align-items-center"><svg class="checkicon" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
						<div class="ml-2">
							<h6 class="mb-0">` + contract.contract_name + `</h6>
							<div class="d-flex flex-row mt-1 text-black-50 date-time">
								<div><svg class="route-svg" viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg><span class="ml-2">Distance: ` + contract.distance + `km</span></div>
								<div class="ml-3"><svg class="coins-svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.24 2 7s4.48 5 10 5 10-2.24 10-5-4.48-5-10-5zm0 13c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5zm0 5c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5z"/></svg><span class="ml-2">Reward: ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(contract.reward) + `</span></div>
							</div>
						</div>
					</div>
					<div class="d-flex flex-row align-items-center">
						<div class="d-flex flex-column mr-2">
							<div class="profile-image">
							`;
			if(contract.cargo_type == 1) {
				list_item += '<div data-tooltip="Explosives"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#ff5722"/><path d="M12 7l1 2.5L15.5 10l-2.5 1-1 2.5-1-2.5-2.5-1L11 9.5zM8.5 13.5l.3.8.8.3-.8.3-.3.8-.3-.8-.8-.3.8-.3zm7 0l.3.8.8.3-.8.3-.3.8-.3-.8-.8-.3.8-.3z" fill="white"/></svg></div>';
			}else if(contract.cargo_type == 2) {
				list_item += '<div data-tooltip="Flammable Gases"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#f44336"/><path d="M12 7.5S8.5 11 8.5 13.5c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5c0-2.5-3.5-6-3.5-6zm0 8c-.83 0-1.5-.67-1.5-1.5 0-1.12 1.5-3.22 1.5-3.22s1.5 2.1 1.5 3.22c0 .83-.67 1.5-1.5 1.5z" fill="white"/></svg></div>';
			}else if(contract.cargo_type == 3) {
				list_item += '<div data-tooltip="Flammable liquids"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#d32f2f"/><path d="M12 6.5S8 10.5 8 13.5c0 2.2 1.8 4 4 4s4-1.8 4-4c0-3-4-7-4-7zm0 9c-1.1 0-2-.9-2-2 0-1.5 2-4 2-4s2 2.5 2 4c0 1.1-.9 2-2 2z" fill="white"/><path d="M7 19h10v1.5H7z" fill="white"/></svg></div>';
			}else if(contract.cargo_type == 4) {
				list_item += '<div data-tooltip="Flammable solids"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#ff9800"/><path d="M12 6.5c-3.04 0-5.5 2.46-5.5 5.5s2.46 5.5 5.5 5.5 5.5-2.46 5.5-5.5-2.46-5.5-5.5-5.5zm0 9c-1.93 0-3.5-1.57-3.5-3.5S10.07 8.5 12 8.5s3.5 1.57 3.5 3.5-1.57 3.5-3.5 3.5z" fill="white"/><path d="M10.5 11h3v2h-3z" fill="white"/></svg></div>';
			}else if(contract.cargo_type == 5) {
				list_item += '<div data-tooltip="Toxic Substances"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#ffffff" stroke="#000000" stroke-width="1.5"/><path d="M12 6c-2.21 0-4 1.79-4 4 0 1.88 1.3 3.44 3 3.87V15.5h-1v1.5h1v1h2v-1h1v-1.5h-1v-1.63c1.7-.43 3-1.99 3-3.87 0-2.21-1.79-4-4-4zm-1.5 3.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm3 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z" fill="black"/></svg></div>';
			}else if(contract.cargo_type == 6) {
				list_item += '<div data-tooltip="Corrosive substances"><svg class="cargo-svg" viewBox="0 0 24 24"><path d="M12 2L22 12L12 22L2 12Z" fill="#3f51b5"/><path d="M12 7c-1.66 0-3 1.34-3 3v2H7v1.5h8V12h-2v-2c0-.55-.45-1-1-1zm3.85 4.85l-1.3-1.3a.996.996 0 0 0-1.41 0l-3 3a.996.996 0 0 0 0 1.41l1.3 1.3c.39.39 1.02.39 1.41 0l3-3c.39-.39.39-1.03 0-1.41z" fill="white"/></svg></div>';
			}
			if(contract.fragile == 1) {
				list_item += '<div data-tooltip="Fragile cargo"><svg class="cargo-svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#00bcd4"/><path d="M16 6H8v2c0 2.21 1.79 4 4 4v3h-2v2h4v-2h-2v-3c2.21 0 4-1.79 4-4V6zM12 10c-1.1 0-2-.9-2-2V7h4v1c0 1.1-.9 2-2 2z" fill="white"/></svg></div>';
			}
			if(contract.valuable == 1) {
				list_item += '<div data-tooltip="Valuable cargo"><svg class="cargo-svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#e91e63"/><path d="M12 6L4.5 10l7.5 9 7.5-9L12 6zm0 10.55L7.22 11h9.56L12 16.55zM8.38 9.5l1.62-2h4l1.62 2H8.38z" fill="white"/></svg></div>';
			}
			if(contract.fast == 1) {
				list_item += '<div data-tooltip="Urgent cargo"><svg class="cargo-svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#ff9800"/><path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" fill="white"/></svg></div>';
			}
			list_item += `
							</div>
						</div>
						<button onclick="startJob(` + contract.contract_id + `,` + contract.reward + `,` + contract.distance + `)" class="btn btn-blue btn-darken-2 white">Start Job</button>
					</div>
				</li>
			</ul>
			`;
			if(contract.contract_type == 0) {
				$('#job-page-list').append(list_item);
			}else{
				$('#freight-page-list').append(list_item);
			}
		}
		
		$('#skills-desc').empty();
		$('#skills-desc').append("Upgrade your skills to get better jobs (Skill points avaliable: " + users.skill_points + ")");
		setSkill('distance',users.distance);
		setSkill('product_type',users.product_type);
		setSkill('valuable',users.valuable);
		setSkill('fragile',users.fragile);
		setSkill('fast',users.fast);

		$('#dealership-page-list').empty();
		list_item = `
			<div class="col-12 mt-3 mb-1">
				<h4 class="text-uppercase">Dealership</h4>
				<p>Buy more trucks to you and your drivers</p>
			</div>`;

		for (const key in config.concessionaria) {
			truck = config.concessionaria[key];
			list_item += `
				<div class="card"> <img src="` + truck.img + `" class="card-img-top" width="100%">
					<div class="card-body pt-0 px-0">
						<div class="d-flex flex-row justify-content-between mb-0 mt-3 px-3"> <span class="text-muted">Truck</span>
							<h6>` + truck.name + `</h6>
						</div>
						<hr class="mt-2 mx-3">
						<div class="d-flex flex-row justify-content-between px-3 pb-4">
							<div class="d-flex flex-column"><span class="text-muted">Price</span></div>
							<div class="d-flex flex-column">
								<h5 class="mb-0">` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(truck.price) + `</h5>
							</div>
						</div>
						<div class="d-flex flex-row justify-content-between p-3 mid">
							<div class="d-flex flex-column"><small class="text-muted mb-1">ENGINE</small>
								<div class="d-flex flex-row"><svg class="dealership-icon-svg" viewBox="0 0 24 24" style="fill: #5c6bc0;"><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03-.7-1.62-.94l-.36-2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
									<div class="d-flex flex-column ml-1"><small class="ghj">` + truck.engine + `</small><small class="ghj">` + truck.transmission + `</small></div>
								</div>
							</div>
							<div class="d-flex flex-column"><small class="text-muted mb-2">HORSEPOWER</small>
								<div class="d-flex flex-row"><svg class="dealership-icon-svg" viewBox="0 0 24 24" style="fill: #ff9800;"><path d="M11.5 2L3 13h7v9l8.5-11h-7z"/></svg>
									<h6 class="ml-1">` + truck.hp + ` hp</h6>
								</div>
							</div>
						</div>
						<div class="mx-3 mt-3 mb-2"><button onclick="buyTruck('` + key + `','` + truck.price + `')" type="button" class="btn btn-blue btn-darken-2 white btn-block"><small>BUY</small></button></div> <small class="d-flex justify-content-center text-muted">*Legal Disclaimer</small>
					</div>
				</div>
				`;
		}
		$('#dealership-page-list').append(list_item);

		$('#trucks-page-list').empty();
		$('#truck-name').empty();
		$('#diagnostic-truck-img').attr('src', 'img/truck.png');
		
		// Reset diagnostic bars if no active truck
		$('#diagnostic-body').empty().append('<div class="media d-flex"><div class="media-body text-left"><h3 class="danger">0 %</h3><span>Nenhum Veículo Selecionado</span></div></div>');
		$('#diagnostic-engine').empty().append('<div class="media d-flex"><div class="media-body text-left"><h3 class="danger">0 %</h3><span>Nenhum Veículo Selecionado</span></div></div>');
		$('#diagnostic-transmission').empty().append('<div class="media d-flex"><div class="media-body text-left"><h3 class="danger">0 %</h3><span>Nenhum Veículo Selecionado</span></div></div>');
		$('#diagnostic-wheels').empty().append('<div class="media d-flex"><div class="media-body text-left"><h3 class="danger">0 %</h3><span>Nenhum Veículo Selecionado</span></div></div>');

		list_item = "";
		for (const truck of myFrota) {
			truck.body = truck.body/10;
			truck.engine = truck.engine/10;
			truck.transmission = truck.transmission/10;
			truck.wheels = truck.wheels/10;
			if(truck.driver == 0){
				$('#truck-name').append('('+config.concessionaria[truck.truck_name].name+')');
				$('#diagnostic-truck-img').attr('src', config.concessionaria[truck.truck_name].img);
				var color = "";
				
				if (truck.body > 80) {
					color = "success";
				}else if(truck.body > 40){
					color = "warning";
				}else{
					color = "danger";
				}
				$('#diagnostic-body').empty();
				$('#diagnostic-body').append(`
					<div class="media d-flex">
						<div class="media-body text-left">
							<h3 class="` + color + `">` + truck.body + ` %</h3><span>Fix Body (` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format((100-truck.body)*config.valor_reparo.body) + `)</span>
						</div>
						<div class="align-self-center">
							<svg class="card-icon-svg ` + color + ` float-right" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg>
						</div>
					</div>
					<div class="progress mt-1 mb-0" style="height: 7px;">
						<div class="progress-bar bg-` + color + `" role="progressbar" style="width: ` + truck.body + `%" aria-valuenow="` + truck.body + `" aria-valuemin="0" aria-valuemax="100"></div>
					</div>
				`);
				
				if (truck.engine > 80) {
					color = "success";
				}else if(truck.engine > 40){
					color = "warning";
				}else{
					color = "danger";
				}
				$('#diagnostic-engine').empty();
				$('#diagnostic-engine').append(`
					<div class="media d-flex">
						<div class="media-body text-left">
							<h3 class="` + color + `">` + truck.engine + ` %</h3><span>Fix Engine (` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format((100-truck.engine)*config.valor_reparo.engine) + `)</span>
						</div>
						<div class="align-self-center">
							<svg class="card-icon-svg ` + color + ` float-right" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg>
						</div>
					</div>
					<div class="progress mt-1 mb-0" style="height: 7px;">
						<div class="progress-bar bg-` + color + `" role="progressbar" style="width: ` + truck.engine + `%" aria-valuenow="` + truck.engine + `" aria-valuemin="0" aria-valuemax="100"></div>
					</div>
				`);
				
				if (truck.transmission > 80) {
					color = "success";
				}else if(truck.transmission > 40){
					color = "warning";
				}else{
					color = "danger";
				}
				$('#diagnostic-transmission').empty();
				$('#diagnostic-transmission').append(`
					<div class="media d-flex">
						<div class="media-body text-left">
							<h3 class="` + color + `">` + truck.transmission + ` %</h3><span>Fix Transmission (` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format((100-truck.transmission)*config.valor_reparo.transmission) + `)</span>
						</div>
						<div class="align-self-center">
							<svg class="card-icon-svg ` + color + ` float-right" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg>
						</div>
					</div>
					<div class="progress mt-1 mb-0" style="height: 7px;">
						<div class="progress-bar bg-` + color + `" role="progressbar" style="width: ` + truck.transmission + `%" aria-valuenow="` + truck.transmission + `" aria-valuemin="0" aria-valuemax="100"></div>
					</div>
				`);
				
				if (truck.wheels > 80) {
					color = "success";
				}else if(truck.wheels > 40){
					color = "warning";
				}else{
					color = "danger";
				}
				$('#diagnostic-wheels').empty();
				$('#diagnostic-wheels').append(`
					<div class="media d-flex">
						<div class="media-body text-left">
							<h3 class="` + color + `">` + truck.wheels + ` %</h3><span>Fix Wheels (` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format((100-truck.wheels)*config.valor_reparo.wheels) + `)</span>
						</div>
						<div class="align-self-center">
							<svg class="card-icon-svg ` + color + ` float-right" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg>
						</div>
					</div>
					<div class="progress mt-1 mb-0" style="height: 7px;">
						<div class="progress-bar bg-` + color + `" role="progressbar" style="width: ` + truck.wheels + `%" aria-valuenow="` + truck.wheels + `" aria-valuemin="0" aria-valuemax="100"></div>
					</div>
				`);
			}
			list_item += `
				<li class="d-flex justify-content-between">
					<div class="d-flex flex-row align-items-center"><img src="` + config.concessionaria[truck.truck_name].img + `" class="truck-thumbnail" alt="Truck-Thumbnail">
						<div class="ml-2">
							<h6 class="mb-0">` + config.concessionaria[truck.truck_name].name + `</h6>
							<div class="d-flex flex-row mt-1 text-black-50 date-time">
								<div>
									<svg class="tools-svg" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg><span class="ml-2">Body: ` + truck.body + `%</span>
								</div>
								<div class="ml-3">
									<svg class="tools-svg" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg><span class="ml-2">Engine: ` + truck.engine + `%</span>
								</div>
								<div class="ml-3">
									<svg class="tools-svg" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg><span class="ml-2">Transmission: ` + truck.transmission + `%</span>
								</div>
								<div class="ml-3">
									<svg class="tools-svg" viewBox="0 0 24 24"><path d="M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4z"/></svg><span class="ml-2">Wheels: ` + truck.wheels + `%</span>
								</div>
							</div>
						</div>
					</div>
					<div class="d-flex flex-row align-items-center">
						` + getMyTruckHTML(truck) + `
						<button onclick="sellTruck('` + truck.truck_id + `','` + truck.truck_name + `')" class="btn btn-red btn-accent-4 white">Sell Truck</button>
					</div>
				</li>
				`;
		}
		$('#trucks-page-list').append(list_item);

		$('#recruitment-page-list').empty();
		$('#drivers-page-list').empty();
		list_item = `
			<div class="col-12 mt-3 mb-1">
				<h4 class="text-uppercase">Recruitment Agency</h4>
				<p>Recruit new drivers to work for your company</p>
			</div>
			`;
		for (const driver of drivers) {
			if (driver.user_id == null || driver.user_id == undefined){
				list_item += `
					<div class="card user-card">
						<div class="card-block">
							<div class="user-image">
								<img src="` + driver.img + `" class="img-radius" alt="User-Profile-Image">
							</div>
							<h6 class="m-t-25 m-b-10">` + driver.name + `</h6>
							<p class="text-muted">Price: ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(driver.price) + ` + ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(driver.price_per_km) + `/km</p>
							<hr>
							<p class="text-muted">Product Type</p>
							<ul class="list-unstyled activity-leval">
								` + getDriverLevelHTML(driver.product_type) + `
							</ul>
							<p class="text-muted">Distance</p>
							<ul class="list-unstyled activity-leval">
								` + getDriverLevelHTML(driver.distance) + `
							</ul>
							<p class="text-muted">Valuable Cargo</p>
							<ul class="list-unstyled activity-leval">
								` + getDriverLevelHTML(driver.valuable) + `
							</ul>
							<p class="text-muted">Fragile Cargo</p>
							<ul class="list-unstyled activity-leval">
								` + getDriverLevelHTML(driver.fragile) + `
							</ul>
							<p class="text-muted">On-time delivery</p>
							<ul class="list-unstyled activity-leval">
								` + getDriverLevelHTML(driver.fast) + `
							</ul>
							<div class="mx-3 mt-3 mb-2"><button onclick="hireDriver('` + driver.driver_id + `')" type="button" class="btn btn-blue btn-darken-2 white btn-block"><small>HIRE</small></button></div>
						</div>
					</div>
					`;
			}else{
				$('#drivers-page-list').append(`
					<li class="d-flex justify-content-between">
						<div class="d-flex flex-row align-items-center">
							<img src="` + driver.img + `" class="img-radius img-width" alt="User-Profile-Image">
							<div class="ml-2">
								<h6 class="mb-0">` + driver.name + `</h6>
								<div class="d-flex flex-row mt-1 text-black-50 date-time">
									<div>
										<svg class="coins-svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.24 2 7s4.48 5 10 5 10-2.24 10-5-4.48-5-10-5zm0 13c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5zm0 5c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5z"/></svg><span class="ml-2">Price: ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(driver.price) + ` + ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(driver.price_per_km) + `/km</span>
									</div>
									<div class="ml-3">
										<svg class="medal-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg><span class="ml-2">Driver skills: Product Type (` + driver.product_type + `) Distance (` + driver.distance + `) Valuable Cargo (` + driver.valuable + `) Fragile Cargo (` + driver.fragile + `) On-time Delivery (` + driver.fast + `)</span>
									</div>
								</div>
							</div>
						</div>
						<div class="d-flex flex-row align-items-center">
							<div class="d-flex flex-column mr-2">
								<select id="select-truck" class="selectpicker form-control" onchange="setDriver(this.options[this.selectedIndex].getAttribute('driver_id'),this.options[this.selectedIndex].getAttribute('truck_id'));">
									` + getDriverAvailableFrotaHTML(myFrota,driver,config) + `
								</select>
							</div> 
							<button onclick="fireDriver('` + driver.driver_id + `')" class="btn btn-red btn-accent-4 white">Fire Driver</button>
						</div>
					</li>
				`);
			}
		}
		$('#recruitment-page-list').append(list_item);

		$('#loan-title').empty();
		$('#loan-title').append('Get loans to invest in your company (Maximum active loans: ' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(config.max_emprestimo) + ')');
		
		var getLoanData = function(idx) {
			var val = config.emprestimos[idx] || config.emprestimos[idx + 1] || config.emprestimos[String(idx + 1)];
			if (!val) {
				var fallbacks = [
					[20000, 400, 200],
					[50000, 950, 500],
					[100000, 1800, 1000],
					[400000, 7000, 4000]
				];
				return fallbacks[idx] || [20000, 400, 200];
			}
			return val;
		};
		var l1 = getLoanData(0);
		var l2 = getLoanData(1);
		var l3 = getLoanData(2);
		var l4 = getLoanData(3);

		$('#loan-1').empty();
		list_item = '<h3 class="success darken-1">' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l1[0]) + '</h3><span>pay ' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l1[1]) + ' at day</span>';
		$('#loan-1').append(list_item);
		$('#loan-2').empty();
		list_item = '<h3 class="success darken-1">' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l2[0]) + '</h3><span>pay ' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l2[1]) + ' at day</span>';
		$('#loan-2').append(list_item);
		$('#loan-3').empty();
		list_item = '<h3 class="success darken-1">' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l3[0]) + '</h3><span>pay ' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l3[1]) + ' at day</span>';
		$('#loan-3').append(list_item);
		$('#loan-4').empty();
		list_item = '<h3 class="success darken-1">' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l4[0]) + '</h3><span>pay ' + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(l4[1]) + ' at day</span>';
		$('#loan-4').append(list_item);

		$('#loan-list').empty();
		for (const loan of loans) {
			list_item = `
				<li class="d-flex justify-content-between">
					<div class="d-flex flex-row align-items-center"><svg class="checkicon" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
						<div class="ml-2">
							<h6 class="mb-0">` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(loan.loan) + `</h6>
							<div class="d-flex flex-row mt-1 text-black-50 date-time">
								<div><svg class="coins-svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.24 2 7s4.48 5 10 5 10-2.24 10-5-4.48-5-10-5zm0 13c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5zm0 5c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5z"/></svg><span class="ml-2">Remaining: ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(loan.remaining_amount) + `</span></div>
								<div class="ml-3"><svg class="coins-svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.24 2 7s4.48 5 10 5 10-2.24 10-5-4.48-5-10-5zm0 13c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5zm0 5c-5.52 0-10-2.24-10-5v3c0 2.76 4.48 5 10 5s10-2.24 10-5v-3c0 2.76-4.48 5-10 5z"/></svg><span class="ml-2">Daily cost: ` + new Intl.NumberFormat(config.formatacao.location, { style: 'currency', currency: config.formatacao.moeda }).format(loan.day_cost) + `</span></div>
							</div>
						</div>
					</div>
					<div class="d-flex flex-row align-items-center">
						<button onclick="payLoan('` + loan.id + `')" class="btn btn-red btn-accent-4 white">Pay Loan</button>
					</div>
				</li>
			`;
			$('#loan-list').append(list_item);
		}
	}
	if (item.hidemenu){
		$("body").css("display", "none");
	}
});

function log(d){
	console.log(JSON.stringify(d));
}

function getDriverLevelHTML(value){
	var html = "";
	for (var i = 1; i <= 6; i++) {
		if(i <= value){
			html += '<li class="actived"></li>';
		}else{
			html += '<li></li>';
		}
	}
	return html;
}

function getDriverAvailableFrotaHTML(myFrota,driver,config){
	var html = "";
	var i = 1;
	var has_truck = null;
	for (const truck of myFrota) {
		if (truck.driver == driver.driver_id) {
			has_truck = truck.truck_id;
			html += '<option selected="selected">' + config.concessionaria[truck.truck_name].name +'</option>';
		}else{
			if (truck.driver == null){
				html += '<option truck_id="' + truck.truck_id + '" driver_id="' + driver.driver_id + '">' + config.concessionaria[truck.truck_name].name +'</option>';
			}
		}
	}
	if (has_truck == null) {
		html = '<option selected="selected">Select a Truck</option>' + html;
	}else{
		html = '<option driver_id="0" truck_id="' + has_truck + '">Select a Truck</option>' + html;
	}
	return html;
}

function getMyTruckHTML(truck){
	return truck.driver==0 ? `<button onclick="spawnTruck(` + truck.truck_id + `)" class="btn btn-blue btn-darken-2 white white mr-2">Spawn Truck</button> <button onclick="setDriver(null,` + truck.truck_id + `)" class="btn btn-blue btn-darken-2 white white mr-2">Deselect</button>` : `<button onclick="setDriver('0',` + truck.truck_id + `)" class="btn btn-blue btn-darken-2 white white mr-2">Select Truck</button>`
}

function setSkill(id,newValue){
	$('#'+id).empty();
	for (var i = 1; i <= 6; i++) {
		if(i <= newValue){
			if(i == 1){
				$('#'+id).append('<div class="steps"> <span><svg class="check-svg" style="fill: white;" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg></span> </div>');
			}else{
				$('#'+id).append('<span class="line"></span><div class="steps"> <span><svg class="check-svg" style="fill: white;" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg></span> </div>');
			}
		}else{
			if(i == 1){
				$('#'+id).append('<div class="redsteps" onclick="upgradeSkill(\''+id+'\','+i+')"> <span class="font-weight-bold">'+i+'</span> </div>');
			}else{
				$('#'+id).append('</div> <span class="redline"></span><div class="redsteps" onclick="upgradeSkill(\''+id+'\','+i+')"> <span class="font-weight-bold">'+i+'</span>');
			}
		}
	}
}

function openPage(pageN){
	if(pageN == 0){
		$(".pages").css("display", "none");
		$(".main-page").css("display", "block");
	}
	if(pageN == 1){
		$(".pages").css("display", "none");
		$(".job-page").css("display", "block");
	}
	if(pageN == 2){
		$(".pages").css("display", "none");
		$(".freight-page").css("display", "block");
	}
	if(pageN == 3){
		$(".pages").css("display", "none");
		$(".skills-page").css("display", "block");
	}
	if(pageN == 4){
		$(".pages").css("display", "none");
		$(".diagnostic-page").css("display", "block");
	}
	if(pageN == 5){
		$(".pages").css("display", "none");
		$(".dealership-page").css("display", "block");
	}
	if(pageN == 6){
		$(".pages").css("display", "none");
		$(".trucks-page").css("display", "block");
	}
	if(pageN == 7){
		$(".pages").css("display", "none");
		$(".recruitment-page").css("display", "block");
	}
	if(pageN == 8){
		$(".pages").css("display", "none");
		$(".drivers-page").css("display", "block");
	}
	if(pageN == 9){
		$(".pages").css("display", "none");
		$(".bank-page").css("display", "block");
	}
}

function closeUI(){
	post("close","")
}
function startJob(contract_id,reward,distance){
	post("startJob",{id:contract_id,reward:reward,distance:distance})
}
function sellTruck(truck_id,truck_name){
	post("sellTruck",{truck_id:truck_id,truck_name:truck_name})
}
function buyTruck(truck_name,price){
	post("buyTruck",{truck_name:truck_name,price:price})
}
function spawnTruck(truck_id){
	post("spawnTruck",{truck_id:truck_id})
}
function fireDriver(driver_id){
	post("fireDriver",{driver_id:driver_id})
}
function hireDriver(driver_id){
	post("hireDriver",{driver_id:driver_id})
}
function upgradeSkill(id,i){
	post("upgradeSkill",{id:id,value:i})
}
function repairTruck(id){
	post("repairTruck",{id:id})
}
function setDriver(driver_id,truck_id){
	post("setDriver",{driver_id:driver_id,truck_id:truck_id})
}
function loan(loan_id){
	post("loan",{loan_id:loan_id})
}
function payLoan(loan_id){
	post("payLoan",{loan_id:loan_id})
}
function depositMoney(){
	var amount = document.getElementById('input-deposit-money').value;
	document.getElementById('input-deposit-money').value = null;
	post("depositMoney",{amount:amount})
}
function withdrawMoney(){
	post("withdrawMoney",{})
}

document.onkeyup = function(data){
	if (data.which == 27){
		if ($("body").is(":visible")){
			post("close","")
		}
	}
};

$('.sidebar-navigation ul li').on('click', function() {
	$('li').removeClass('active');
	$(this).addClass('active');
});

var coll = document.getElementsByClassName("collapsible");
var i;
for (i = 0; i < coll.length; i++) {
	coll[i].addEventListener("click", function() {
		this.classList.toggle("active");
		var content = this.nextElementSibling;
		if (content.style.display === "block") {
			content.style.display = "none";
		} else {
			content.style.display = "block";
		}
	});
}

function post(name,data){
	$.post("https://cidade_tycoon_trucklogistics/"+name,JSON.stringify(data),function(datab){
		if (datab != "ok"){
			console.log(datab);
		}
	});
}