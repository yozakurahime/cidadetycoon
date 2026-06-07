const panel = document.getElementById("panel");
const frames = document.getElementById("frames");
const count = document.getElementById("frame-count");
const replaySeek = document.getElementById("replay-seek");
const replayInfo = document.getElementById("replay-info");
const replayCurrent = document.getElementById("replay-current");
const replayDuration = document.getElementById("replay-duration");
const replayEvents = document.getElementById("replay-events");
const replayIn = document.getElementById("replay-in");
const replayOut = document.getElementById("replay-out");
const playbackRate = document.getElementById("playback-rate");
const replayLoop = document.getElementById("replay-loop");
const subjectSelect = document.getElementById("subject-select");
const targetLabel = document.getElementById("target-label");
const controls = ["fov", "speed", "duration", "easing", "letterbox", "dof", "dofNear", "dofFar", "dofStrength"];

const post = (action, data = {}) => fetch(`https://${GetParentResourceName()}/${action}`, {
	method: "POST",
	headers: { "Content-Type": "application/json" },
	body: JSON.stringify(data)
});

function displayValue(key, value) {
	const target = document.getElementById(`${key}-value`);
	if (!target) return;
	target.textContent = key === "duration" ? `${value} ms` : Number(value).toFixed(key.startsWith("dof") ? 1 : 1).replace(".0", "");
}

function updateState(state) {
	controls.forEach((key) => {
		const element = document.getElementById(key);
		if (!element || state[key] === undefined) return;
		if (element.type === "checkbox") element.checked = state[key];
		else element.value = state[key];
		displayValue(key, state[key]);
	});
	subjectSelect.value = state.targetKey || "";
	targetLabel.textContent = state.targetLabel || "Livre";

	const items = state.keyframes || [];
	count.textContent = `${items.length} keyframe${items.length === 1 ? "" : "s"}`;
	if (!items.length) {
		frames.className = "frames empty";
		frames.textContent = "Posicione a camera e adicione o primeiro keyframe.";
		return;
	}

	frames.className = "frames";
	frames.innerHTML = items.map((frame, index) => `
		<div class="frame">
			<span class="index">${String(index + 1).padStart(2, "0")}</span>
			<span class="detail">${frame.duration || 3000} ms | FOV ${Math.round(frame.fov || 50)} | ${frame.easing === "cut" ? "corte" : (frame.easing === "linear" ? "linear" : "suave")} ${frame.targetLabel ? `| ${frame.targetLabel}` : ""}</span>
			<button data-go="${index + 1}">Ir</button>
			<button class="danger" data-delete="${index + 1}">X</button>
		</div>
	`).join("");
}

function formatTime(milliseconds) {
	const seconds = Math.max(0, Number(milliseconds || 0)) / 1000;
	const minutes = Math.floor(seconds / 60);
	const rest = (seconds % 60).toFixed(1).padStart(4, "0");
	return `${String(minutes).padStart(2, "0")}:${rest}`;
}

function updateReplay(data) {
	replaySeek.max = data.duration || 0;
	replaySeek.value = data.time || 0;
	replayCurrent.textContent = formatTime(data.time);
	replayDuration.textContent = formatTime(data.duration);
	replayIn.textContent = formatTime(data.editIn);
	replayOut.textContent = formatTime(data.editOut);
	playbackRate.value = String(data.playbackRate || 1);
	replayLoop.checked = data.loop === true;
	const previousSubject = subjectSelect.value;
	subjectSelect.replaceChildren(new Option("Camera livre", ""));
	(data.subjects || []).forEach((subject) => {
		subjectSelect.add(new Option(`${subject.kind}: ${subject.label}`, subject.key));
	});
	if (Array.from(subjectSelect.options).some((option) => option.value === previousSubject)) {
		subjectSelect.value = previousSubject;
	}
	if (!data.duration) {
		replayInfo.textContent = "Nenhuma cena gravada";
		replayEvents.className = "event-list empty";
		replayEvents.textContent = "Nenhum evento marcado na cena.";
		return;
	}
	const state = data.recording ? "GRAVANDO" : data.playing ? "PLAY" : "PAUSADO";
	replayInfo.textContent = `${state} | ${data.actorCount} atores | ${data.vehicleCount} veiculos | ${data.propCount || 0} objetos | ${data.eventCount || 0} eventos`;
	const events = data.events || [];
	if (!events.length) {
		replayEvents.className = "event-list empty";
		replayEvents.textContent = "Nenhum evento marcado na cena.";
		return;
	}
	replayEvents.className = "event-list";
	replayEvents.innerHTML = events.map((item) => `
		<div class="event">
			<span>${formatTime(item.t)} | ${item.label}</span>
			<button class="danger" data-delete-event="${item.index}">X</button>
		</div>
	`).join("");
}

window.addEventListener("message", (event) => {
	const data = event.data;
	if (data.action === "visible") panel.classList.toggle("hidden", !data.visible);
	if (data.action === "state") updateState(data);
	if (data.action === "replayState") updateReplay(data);
});

document.querySelectorAll("[data-action]").forEach((button) => {
	button.addEventListener("click", () => post(button.dataset.action));
});

controls.forEach((key) => {
	const element = document.getElementById(key);
	element.addEventListener("input", () => {
		const value = element.type === "checkbox" ? element.checked : element.value;
		displayValue(key, value);
		post("setting", { key, value });
	});
});

replaySeek.addEventListener("input", () => {
	replayCurrent.textContent = formatTime(replaySeek.value);
	post("replaySeek", { time: Number(replaySeek.value) });
});

function updatePlayback() {
	post("replayPlayback", { rate: Number(playbackRate.value), loop: replayLoop.checked });
}

playbackRate.addEventListener("change", updatePlayback);
replayLoop.addEventListener("change", updatePlayback);

subjectSelect.addEventListener("change", () => {
	if (subjectSelect.value) post("focusSubject", { key: subjectSelect.value });
	else post("clearSubject");
});

document.querySelectorAll("[data-preset]").forEach((button) => {
	button.addEventListener("click", () => post("cameraPreset", { preset: button.dataset.preset }));
});

replayEvents.addEventListener("click", (event) => {
	const remove = event.target.dataset.deleteEvent;
	if (remove) post("replayDeleteEvent", { index: Number(remove) });
});

frames.addEventListener("click", (event) => {
	const go = event.target.dataset.go;
	const remove = event.target.dataset.delete;
	if (go) post("goFrame", { index: go });
	if (remove) post("deleteFrame", { index: remove });
});

document.addEventListener("keydown", (event) => {
	if (event.key === "Escape") post("closePanel");
	if (event.key === "F6") post("closePanel");
});
