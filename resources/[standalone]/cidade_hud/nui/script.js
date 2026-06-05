(function () {
	"use strict";

	const $ = (id) => document.getElementById(id);
	const overlay = $("overlay");
	const vehicle = $("vehicle");
	const radio = $("radio");
	const voice = $("voice");
	const progress = $("progress");
	const progressFill = $("progress-fill");
	let progressFrame = null;

	function clamp(value) {
		return Math.max(0, Math.min(100, Number(value) || 0));
	}

	function text(id, value) {
		$(id).textContent = String(value);
	}

	function meter(id, value) {
		const normalized = clamp(value);
		$(id).style.width = `${normalized}%`;
		text(`${id}-value`, Math.round(normalized));
	}

	function markReady() {
		overlay.classList.add("ready");
	}

	function updateCommon(item) {
		meter("health", item.health);
		meter("armour", item.armour);
		meter("stamina", item.stamina);
		meter("hunger", item.hunger);
		meter("thirst", item.thirst);
		meter("stress", item.stress);
		$("armour-card").classList.toggle("hidden", clamp(item.armour) === 0);
		text("time", `${item.hour || "--"}:${item.minute || "--"}`);
		text("date", `${item.day || "--"} ${item.month || ""}`.trim());
		text("street", item.street || "LOS SANTOS");
		markReady();
	}

	function paddedSpeed(value) {
		return String(Math.max(0, Math.round(Number(value) || 0))).padStart(3, "0");
	}

	function updateVehicle(item) {
		const speed = Math.max(0, Number(item.speed) || 0);
		const fuel = clamp(item.fuel);
		text("speed", paddedSpeed(speed));
		text("gear", item.gear === undefined ? "N" : item.gear);
		text("fuel-value", `${Math.round(fuel)}%`);
		
		const speedFill = $("speed-fill");
		if (speedFill) {
			speedFill.style.width = `${Math.min(100, speed / 2.4)}%`;
		}
		
		$("fuel").style.width = `${fuel}%`;
		$("belt").classList.toggle("active", item.cinto === true);
		$("lock").classList.toggle("active", Number(item.locked) >= 2 || item.locked === true);
	}

	function runProgress(item) {
		if (progressFrame) cancelAnimationFrame(progressFrame);
		if (item.display !== true) {
			progress.classList.add("hidden");
			return;
		}
		const duration = Math.max(1, Number(item.time) || 1);
		const started = performance.now();
		text("progress-label", item.text || "PROCESSANDO");
		progress.classList.remove("hidden");

		function draw(now) {
			const percent = Math.min(100, ((now - started) / duration) * 100);
			progressFill.style.width = `${percent}%`;
			if (percent < 100) {
				progressFrame = requestAnimationFrame(draw);
			} else {
				progress.classList.add("hidden");
				progressFrame = null;
			}
		}
		progressFrame = requestAnimationFrame(draw);
	}

	function updateTycoon(item) {
		const tycoonPanel = $("tycoon");
		if (!item.level) {
			tycoonPanel.classList.add("hidden");
			return;
		}
		tycoonPanel.classList.remove("hidden");
		text("player-name", item.playerName || "Personagem");
		text("passport", item.passport || "--");
		text("tycoon-level", item.level);
		
		const xpPercent = clamp((item.experience / item.maxExperience) * 100);
		$("xp-fill").style.width = `${xpPercent}%`;
	}

	function updateMission(item) {
		const missionPanel = $("active-mission");
		if (!item.active) {
			missionPanel.classList.add("hidden");
			return;
		}
		missionPanel.classList.remove("hidden");
		text("cargo-integrity", Math.floor(item.cargoHealth || 100));
		text("mission-progress", `${item.totalDelivered || 0}/${item.totalRequired || 1}`);
		
		const integrityEl = $("cargo-integrity");
		const health = item.cargoHealth || 100;
		if (health <= 40) integrityEl.style.color = "var(--health)";
		else if (health <= 75) integrityEl.style.color = "var(--hunger)";
		else integrityEl.style.color = "var(--green)";
	}

	window.addEventListener("message", (event) => {
		const item = event.data || {};
		if (item.type === "ui") runProgress(item);
		if (item.action === "updateTycoon") updateTycoon(item);
		if (item.action === "updateMission") updateMission(item);
		if (item.hudoff !== undefined) {
			overlay.classList.toggle("off", item.hudoff === true);
		}
		if (item.fomeSede !== undefined) {
			const hideFomeSede = item.fomeSede === false;
			document.querySelector(".vital.hunger").classList.toggle("hidden", hideFomeSede);
			document.querySelector(".vital.thirst").classList.toggle("hidden", hideFomeSede);
		}
		if (item.exibCombustivel !== undefined) {
			const hideFuel = item.exibCombustivel === false;
			document.querySelector(".fuel").classList.toggle("hidden", hideFuel);
		}

		switch (item.action) {
			case "update":
				updateCommon(item);
				vehicle.classList.add("hidden");
				break;
			case "inCar":
				updateCommon(item);
				vehicle.classList.remove("hidden");
				break;
			case "proximity":
				voice.classList.remove("level-1", "level-2", "level-3");
				voice.classList.add(`level-${Math.max(1, Math.min(3, Number(item.number) || 1))}`);
				break;
			case "talking":
				voice.classList.toggle("talking", item.falando === true);
				break;
			case "voice":
				voice.classList.remove("level-1", "level-2", "level-3");
				voice.classList.add(`level-${Math.max(1, Math.min(3, Number(item.number) || 1))}`);
				voice.classList.toggle("talking", item.falando === true);
				break;
			case "connect-radio":
				if (item.freq && Number(item.freq) > 0) {
					text("radio-frequency", `${item.freq} MHz`);
					radio.classList.remove("hidden");
				} else {
					radio.classList.add("hidden");
				}
				break;
			case "talking-radio":
				radio.classList.toggle("transmitting", item.radio === true);
				voice.classList.toggle("talking", item.radio === true);
				break;
		}

		if (item.only === "updateSpeed") {
			updateVehicle(item);
			vehicle.classList.remove("hidden");
			markReady();
		}
	});

	if (new URLSearchParams(window.location.search).has("preview")) {
		document.body.classList.add("preview");
		window.postMessage({
			action: "inCar",
			health: 86,
			armour: 42,
			hunger: 82,
			thirst: 69,
			stress: 24,
			hour: "21",
			minute: "47",
			day: "26",
			month: "Maio",
			street: "Boulevard Del Perro",
			fomeSede: true
		}, "*");
		window.postMessage({ action: "proximity", number: 2 }, "*");
		window.postMessage({ action: "connect-radio", freq: "101.3" }, "*");
		window.postMessage({
			action: "updateTycoon",
			playerName: "Ana Souza",
			passport: "CT48291",
			level: 12,
			experience: 15500,
			maxExperience: 24000
		}, "*");
		window.postMessage({
			only: "updateSpeed",
			speed: 112,
			fuel: 63,
			gear: 4,
			locked: 2,
			cinto: true
		}, "*");
	}
}());
