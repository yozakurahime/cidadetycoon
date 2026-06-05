window.addEventListener('message', (event) => {
    const data = event.data;

    // Reprodução de áudio da claquete
    if (data.action === 'playClack') {
        const audio = document.getElementById('clack-sound');
        if (audio) {
            audio.currentTime = 0;
            // O volume pode ser alterado dinamicamente com base na distância
            if (data.volume !== undefined) {
                audio.volume = Math.max(0.0, Math.min(1.0, data.volume));
            } else {
                audio.volume = 0.8;
            }
            audio.play().catch(err => {
                console.error("Erro ao reproduzir som da claquete:", err);
            });
        }
    }

    // Controle do overlay de guias
    if (data.action === 'updateGuides') {
        const overlay = document.getElementById('guides-overlay');
        const grid = document.getElementById('rule-of-thirds');
        const letterbox = document.getElementById('letterbox');
        const rec = document.getElementById('rec-indicator');

        if (data.show) {
            overlay.classList.remove('hidden');
        } else {
            overlay.classList.add('hidden');
        }

        // Grade de terços
        if (data.grid) {
            grid.classList.remove('hidden');
        } else {
            grid.classList.add('hidden');
        }

        // REC Indicator
        if (data.rec) {
            rec.classList.remove('hidden');
        } else {
            rec.classList.add('hidden');
        }

        // Tarjas de Aspect Ratio (Letterbox)
        letterbox.className = 'letterbox'; // Reseta classes
        if (data.aspect && data.aspect !== 'none') {
            letterbox.classList.remove('hidden');
            if (data.aspect === '21-9') {
                letterbox.classList.add('ratio-21-9');
            } else if (data.aspect === '9-16') {
                letterbox.classList.add('ratio-9-16');
            } else if (data.aspect === '1-1') {
                letterbox.classList.add('ratio-1-1');
            }
        } else {
            letterbox.classList.add('hidden');
        }
    }
});
