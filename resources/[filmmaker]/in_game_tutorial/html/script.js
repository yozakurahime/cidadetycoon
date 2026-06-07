document.addEventListener('DOMContentLoaded', () => {
    const overlay = document.getElementById('tutorial-overlay');
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabPanels = document.querySelectorAll('.tab-panel');
    const btnCloseHeader = document.getElementById('btn-close-header');
    const btnCloseFooter = document.getElementById('btn-close-footer');

    // Escuta mensagens enviadas do Lua Client
    window.addEventListener('message', (event) => {
        const item = event.data;
        if (item.action === "open") {
            overlay.style.display = 'flex';
            // Abre por padrão na primeira aba (Cinematics)
            switchTab('cinematics');
        } else if (item.action === "close") {
            overlay.style.display = 'none';
        }
    });

    // Função de Troca de Abas
    function switchTab(tabId) {
        tabBtns.forEach(btn => {
            if (btn.getAttribute('data-tab') === tabId) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });

        tabPanels.forEach(panel => {
            if (panel.id === `panel-${tabId}`) {
                panel.classList.add('active');
            } else {
                panel.classList.remove('active');
            }
        });
    }

    // Vincula cliques nas abas da sidebar
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const tabId = btn.getAttribute('data-tab');
            switchTab(tabId);
        });
    });

    // Função para notificar o jogo que o painel deve ser fechado
    function triggerClose() {
        fetch(`https://in_game_tutorial/closeTutorial`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({})
        }).catch(err => console.log('Erro ao enviar callback de fechamento:', err));
    }

    // === CONTROLE DE CLIMA ===
    const weatherBtns = document.querySelectorAll('.weather-btn');
    weatherBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const weather = btn.getAttribute('data-weather');
            
            // Visual active feedback
            weatherBtns.forEach(b => b.classList.remove('active-btn'));
            btn.classList.add('active-btn');

            fetch(`https://in_game_tutorial/changeWeather`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8'
                },
                body: JSON.stringify({ weather: weather })
            }).catch(err => console.log('Erro ao alterar clima:', err));
        });
    });

    // === CONTROLE DE HORÁRIO ===
    const timeSlider = document.getElementById('time-slider');
    const timeDisplay = document.getElementById('time-display');
    const timePresetBtns = document.querySelectorAll('.time-preset-btn');
    const freezeTimeCheckbox = document.getElementById('freeze-time-checkbox');

    function updateTime(hours, freezeState) {
        const formattedTime = `${hours.toString().padStart(2, '0')}:00`;
        timeDisplay.textContent = formattedTime;
        timeSlider.value = hours;

        fetch(`https://in_game_tutorial/changeTime`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({
                hours: hours,
                minutes: 0,
                freeze: freezeState
            })
        }).catch(err => console.log('Erro ao alterar tempo:', err));
    }

    // Slider input change
    timeSlider.addEventListener('input', () => {
        const hours = parseInt(timeSlider.value);
        updateTime(hours, freezeTimeCheckbox.checked);
    });

    // Preset buttons click
    timePresetBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const hour = parseInt(btn.getAttribute('data-hour'));
            updateTime(hour, freezeTimeCheckbox.checked);
        });
    });

    // Freeze checkbox change
    freezeTimeCheckbox.addEventListener('change', () => {
        const hours = parseInt(timeSlider.value);
        updateTime(hours, freezeTimeCheckbox.checked);
    });

    // Fechar pelo botão do cabeçalho
    btnCloseHeader.addEventListener('click', triggerClose);

    // Fechar pelo botão do rodapé
    btnCloseFooter.addEventListener('click', triggerClose);

    // Escutar as teclas ESC e Backspace para fechar o menu
    window.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' || event.key === 'Backspace') {
            triggerClose();
        }
    });
});
