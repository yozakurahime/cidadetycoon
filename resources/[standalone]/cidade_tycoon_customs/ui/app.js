// ui/app.js

let originalProps = {};
let currentProps = {};
let pricing = {};
let shoppingCart = {};
let plate = "";
let model = "";
let isMechanic = false;
let mechanicName = "Mecânico";
let wheelCount = 0;
let wheelCategories = [];
let visualMods = [];
let visualExtras = [];

// Open UI Event
window.addEventListener('message', function (event) {
    const data = event.data;
    if (data.action === 'open') {
        originalProps = JSON.parse(JSON.stringify(data.props));
        currentProps = JSON.parse(JSON.stringify(data.props));
        if (originalProps.wheels !== undefined) {
            originalProps.wheelType = originalProps.wheels;
            currentProps.wheelType = originalProps.wheels;
        }
        pricing = data.prices;
        plate = data.plate;
        model = data.model;
        isMechanic = data.isMechanic;
        mechanicName = data.mechanicName;
        wheelCount = data.wheelCount;
        wheelCategories = data.wheelCategories || [];
        visualMods = data.visualMods || [];
        visualExtras = data.extras || [];

        // Initialize values
        document.getElementById('veh-model').innerText = model;
        document.getElementById('veh-plate').innerText = plate;
        document.getElementById('os-mechanic-input').value = mechanicName;

        // Job specific visibility
        const mechanicFields = document.querySelectorAll('.select-only-mechanic');
        mechanicFields.forEach(el => {
            el.style.display = isMechanic ? 'flex' : 'none';
        });

        // Reset Cart
        shoppingCart = {};
        updateCart();

        // Populate Controls with current values
        setupPaintSubmenu();
        setupWheelsSubmenu();
        setupVisualModsSubmenu();
        setupNeonSubmenu();
        setupXenonSubmenu();
        setupWindowsSubmenu();

        // Show UI container
        document.getElementById('customs-container').style.display = 'flex';
        document.getElementById('ordem-servico-panel').style.display = 'flex';
    } else if (data.action === 'close') {
        document.getElementById('customs-container').style.display = 'none';
        document.getElementById('ordem-servico-panel').style.display = 'none';
    }
});

// Category switching
const categoryBtns = document.querySelectorAll('.category-btn');
categoryBtns.forEach(btn => {
    btn.addEventListener('click', function () {
        categoryBtns.forEach(b => b.classList.remove('active'));
        this.classList.add('active');

        const cat = this.getAttribute('data-category');
        
        // Hide all submenus
        document.querySelectorAll('.submenu-content').forEach(sub => {
            sub.classList.remove('active');
        });

        // Show clicked submenu
        document.getElementById(`submenu-${cat}`).classList.add('active');

        // Update titles
        const titles = {
            paint: { title: 'Pintura', desc: 'Escolha as cores primárias, secundárias e acabamentos perolados.' },
            wheels: { title: 'Rodas e Pneus', desc: 'Configure as rodas do veículo, selecionando a categoria e o modelo.' },
            visual: { title: 'Pecas Visuais', desc: 'Instale spoilers, para-choques, escapamentos, capos e acabamentos suportados pelo veiculo.' },
            neon: { title: 'Iluminação Neon', desc: 'Instale luzes neon subaquáticas e ajuste suas cores RGB.' },
            xenon: { title: 'Faróis Xenon', desc: 'Ative faróis Xenon de alta potência e selecione a cor desejada.' },
            windows: { title: 'Vidros e Película', desc: 'Instale películas de proteção solar (insulfilm) nos vidros.' },
            services: { title: 'Serviços Especiais', desc: 'Realize limpezas ou outros serviços mecânicos de estética.' }
        };

        document.getElementById('category-title').innerText = titles[cat].title;
        document.getElementById('category-desc').innerText = titles[cat].desc;
        
        playFrontendSound("SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET");
    });
});

// Sound helpers
function playFrontendSound(sound, set) {
    // Standard FiveM sound endpoint or NUI local audio
}

// Debounce utility to prevent excessive NUI calls
function debounce(fn, delay) {
    let timer;
    return function(...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
}

// Post helper
function sendPost(endpoint, data = {}, callback) {
    return fetch(`https://cidade_tycoon_customs/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(async response => {
        const text = await response.text();
        let payload = text;
        try {
            payload = text ? JSON.parse(text) : {};
        } catch (_err) {}
        if (typeof callback === 'function') callback(payload);
        return payload;
    });
}

// -------------------------------------------------------------
// Paint Section
// -------------------------------------------------------------
function setupPaintSubmenu() {
    const primarySlider = document.getElementById('primary-color-slider');
    const primaryVal = document.getElementById('primary-color-val');
    const secondarySlider = document.getElementById('secondary-color-slider');
    const secondaryVal = document.getElementById('secondary-color-val');
    const pearlescentSlider = document.getElementById('pearlescent-slider');
    const pearlescentVal = document.getElementById('pearlescent-val');
    const wheelColorSlider = document.getElementById('wheel-color-slider');
    const wheelColorVal = document.getElementById('wheel-color-val');

    primarySlider.value = currentProps.color1 !== undefined ? currentProps.color1 : 0;
    primaryVal.innerText = primarySlider.value;
    secondarySlider.value = currentProps.color2 !== undefined ? currentProps.color2 : 0;
    secondaryVal.innerText = secondarySlider.value;
    pearlescentSlider.value = currentProps.pearlescentColor !== undefined ? currentProps.pearlescentColor : 0;
    pearlescentVal.innerText = pearlescentSlider.value;
    wheelColorSlider.value = currentProps.wheelColor !== undefined ? currentProps.wheelColor : 0;
    wheelColorVal.innerText = wheelColorSlider.value;

    const paintPresets = [
        { name: 'Preto Fosco', id: 12, color: '#111111' },
        { name: 'Branco Geladeira', id: 111, color: '#fcfcfc' },
        { name: 'Vermelho Torino', id: 39, color: '#b61717' },
        { name: 'Azul Escuro', id: 62, color: '#092147' },
        { name: 'Amarelo Corrida', id: 88, color: '#e2cf17' },
        { name: 'Cromado', id: 120, color: '#e5e5e5' },
        { name: 'Ouro Puro', id: 37, color: '#cca226' },
        { name: 'Verde Militar', id: 50, color: '#314227' }
    ];

    // Primary presets
    const primPresetsDiv = document.getElementById('primary-presets');
    primPresetsDiv.innerHTML = "";
    paintPresets.forEach(preset => {
        const btn = document.createElement('button');
        btn.className = 'preset-btn';
        btn.style.backgroundColor = preset.color;
        btn.title = preset.name;
        btn.addEventListener('click', () => {
            primarySlider.value = preset.id;
            primaryVal.innerText = preset.id;
            handlePaintChange('primaryColor', preset.id);
        });
        primPresetsDiv.appendChild(btn);
    });

    // Secondary presets
    const secPresetsDiv = document.getElementById('secondary-presets');
    secPresetsDiv.innerHTML = "";
    paintPresets.forEach(preset => {
        const btn = document.createElement('button');
        btn.className = 'preset-btn';
        btn.style.backgroundColor = preset.color;
        btn.title = preset.name;
        btn.addEventListener('click', () => {
            secondarySlider.value = preset.id;
            secondaryVal.innerText = preset.id;
            handlePaintChange('secondaryColor', preset.id);
        });
        secPresetsDiv.appendChild(btn);
    });

    const debouncedPaint = debounce(function(type, value) {
        handlePaintChange(type, value);
    }, 30);

    primarySlider.oninput = function() {
        primaryVal.innerText = this.value;
        debouncedPaint('primaryColor', this.value);
    };

    secondarySlider.oninput = function() {
        secondaryVal.innerText = this.value;
        debouncedPaint('secondaryColor', this.value);
    };

    pearlescentSlider.oninput = function() {
        pearlescentVal.innerText = this.value;
        debouncedPaint('pearlescentColor', this.value);
    };

    wheelColorSlider.oninput = function() {
        wheelColorVal.innerText = this.value;
        debouncedPaint('wheelColor', this.value);
    };
}

function handlePaintChange(type, value) {
    const val = parseInt(value);
    
    // Preview
    sendPost('previewMod', { type: type, value: val });
    
    // Cart update
    let propKey = "";
    if (type === 'primaryColor') propKey = 'color1';
    else if (type === 'secondaryColor') propKey = 'color2';
    else if (type === 'pearlescentColor') propKey = 'pearlescentColor';
    else if (type === 'wheelColor') propKey = 'wheelColor';
    
    // Update local state
    if (propKey) currentProps[propKey] = val;
    
    if (val !== originalProps[propKey]) {
        shoppingCart[type] = { label: getPaintLabel(type, val), price: pricing[type] || 0, type: type, val: val };
    } else {
        delete shoppingCart[type];
    }
    updateCart();
}

function getPaintLabel(type, id) {
    const names = {
        primaryColor: 'Pintura Primária',
        secondaryColor: 'Pintura Secundária',
        pearlescentColor: 'Perolado',
        wheelColor: 'Cor das Rodas'
    };
    return `${names[type]} (ID: ${id})`;
}

// -------------------------------------------------------------
// Wheels Section
// -------------------------------------------------------------
function setupWheelsSubmenu() {
    const typeSelect = document.getElementById('wheel-type-select');
    typeSelect.innerHTML = "";

    if (wheelCategories && wheelCategories.length > 0) {
        wheelCategories.forEach(category => {
            const option = document.createElement('option');
            option.value = category.id;
            option.innerText = `${category.label} (${category.count})`;
            typeSelect.appendChild(option);
        });
    }

    const currentWheelType = currentProps.wheelType !== undefined ? currentProps.wheelType : (wheelCategories[0] ? wheelCategories[0].id : 0);
    const hasCurrentCategory = Array.from(typeSelect.options).some(option => parseInt(option.value) === currentWheelType);
    typeSelect.value = hasCurrentCategory ? currentWheelType : (wheelCategories[0] ? wheelCategories[0].id : 0);

    typeSelect.onchange = function() {
        const cat = parseInt(this.value);
        // Reset modFrontWheels preview to original or -1
        sendPost('previewMod', { type: 'wheels', cat: cat, value: -1 }, function(resp) {
            if (resp && resp.wheelCount !== undefined) {
                wheelCount = resp.wheelCount;
            }
            // Update local state when changing category
            currentProps.wheelType = cat;
            currentProps.modFrontWheels = -1;
            generateWheelsGrid(cat);
        });
    };

    const initialCat = parseInt(typeSelect.value);
    sendPost('previewMod', { type: 'wheels', cat: initialCat, value: currentProps.modFrontWheels !== undefined ? currentProps.modFrontWheels : -1 }, function(resp) {
        if (resp && resp.wheelCount !== undefined) {
            wheelCount = resp.wheelCount;
        }
        generateWheelsGrid(initialCat);
    });
}

function generateWheelsGrid(catId) {
    const grid = document.getElementById('wheels-grid');
    grid.innerHTML = "";

    // Generate wheel list buttons based on wheelCount
    for (let i = 0; i < wheelCount; i++) {
        const btn = document.createElement('button');
        btn.className = 'wheel-option-btn';
        btn.innerText = `Roda #${i + 1}`;
        if (currentProps.wheelType === catId && currentProps.modFrontWheels === i) {
            btn.classList.add('active');
        }
        btn.addEventListener('click', function() {
            document.querySelectorAll('.wheel-option-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            handleWheelsChange(catId, i);
        });
        grid.appendChild(btn);
    }
}

// Original wheels button
document.querySelector('[data-wheel="-1"]').addEventListener('click', function() {
    document.querySelectorAll('.wheel-option-btn').forEach(b => b.classList.remove('active'));
    this.classList.add('active');
    handleWheelsChange(originalProps.wheelType || 0, -1);
});

function handleWheelsChange(catId, index) {
    sendPost('previewMod', { type: 'wheels', cat: catId, value: index }, function(resp) {
        if (resp && resp.wheelType !== undefined) currentProps.wheelType = parseInt(resp.wheelType);
        if (resp && resp.modFrontWheels !== undefined) currentProps.modFrontWheels = parseInt(resp.modFrontWheels);
    });

    // Update local state
    currentProps.wheelType = catId;
    currentProps.modFrontWheels = index;

    if (index !== originalProps.modFrontWheels || catId !== originalProps.wheelType) {
        shoppingCart['wheels'] = { 
            label: index === -1 ? 'Rodas Originais' : `Rodas (${getWheelCategoryLabel(catId)} #${index + 1})`, 
            price: pricing['wheels'] || 0, 
            type: 'wheels',
            cat: catId,
            val: index
        };
    } else {
        delete shoppingCart['wheels'];
    }
    updateCart();
}

function getWheelCategoryLabel(id) {
    const labels = ['Sport', 'Muscle', 'Lowrider', 'SUV', 'Offroad', 'Tuner', 'Bike', 'High End', 'Bennys Orig.', 'Bennys Cust.'];
    return labels[id] || 'Outro';
}

// -------------------------------------------------------------
// Visual Parts Section
// -------------------------------------------------------------
function setupVisualModsSubmenu() {
    const list = document.getElementById('visual-mods-list');
    if (!list) return;

    list.innerHTML = "";

    if ((!visualMods || visualMods.length === 0) && (!visualExtras || visualExtras.length === 0)) {
        list.innerHTML = `<div class="empty-cart-message">Este veiculo nao possui pecas visuais compativeis.</div>`;
        return;
    }

    (visualMods || []).forEach(mod => {
        const group = document.createElement('div');
        group.className = 'visual-mod-group';

        const title = document.createElement('div');
        title.className = 'visual-mod-group-title';
        title.innerHTML = `<span>${mod.label}</span><span>${mod.count} opcoes</span>`;
        group.appendChild(title);

        const options = document.createElement('div');
        options.className = 'visual-mod-options';

        const originalBtn = document.createElement('button');
        originalBtn.className = 'wheel-option-btn visual-option-btn';
        originalBtn.innerText = 'Original';
        if ((currentProps[mod.key] ?? -1) === -1) originalBtn.classList.add('active');
        originalBtn.onclick = event => selectVisualMod(event, mod, -1, options);
        options.appendChild(originalBtn);

        for (let i = 0; i < mod.count; i++) {
            const btn = document.createElement('button');
            btn.className = 'wheel-option-btn visual-option-btn';
            btn.innerText = `Opcao #${i + 1}`;
            if (currentProps[mod.key] === i) btn.classList.add('active');
            btn.onclick = event => selectVisualMod(event, mod, i, options);
            options.appendChild(btn);
        }

        group.appendChild(options);
        list.appendChild(group);
    });

    if (visualExtras && visualExtras.length > 0) {
        const group = document.createElement('div');
        group.className = 'visual-mod-group';

        const title = document.createElement('div');
        title.className = 'visual-mod-group-title';
        title.innerHTML = `<span>Extras</span><span>${visualExtras.length} itens</span>`;
        group.appendChild(title);

        const options = document.createElement('div');
        options.className = 'visual-mod-options';

        visualExtras.forEach(extra => {
            const btn = document.createElement('button');
            btn.className = 'wheel-option-btn visual-option-btn';
            btn.innerText = `Extra #${extra.id}: ${extra.enabled ? 'Ligado' : 'Desligado'}`;
            if (extra.enabled) btn.classList.add('active');
            btn.onclick = event => selectExtra(event, extra);
            options.appendChild(btn);
        });

        group.appendChild(options);
        list.appendChild(group);
    }
}

function selectVisualMod(event, mod, index, optionsContainer) {
    optionsContainer.querySelectorAll('.visual-option-btn').forEach(btn => btn.classList.remove('active'));
    event.currentTarget.classList.add('active');

    sendPost('previewMod', { type: 'visualMod', modType: mod.modType, kind: mod.kind, value: index });
    currentProps[mod.key] = index;

    const originalValue = originalProps[mod.key] !== undefined ? originalProps[mod.key] : -1;
    const cartKey = `visual_${mod.key}`;

    if (index !== originalValue) {
        shoppingCart[cartKey] = {
            label: `${mod.label}: ${index === -1 ? 'Original' : `Opcao #${index + 1}`}`,
            price: pricing.visualMod || 0,
            type: 'visualMod',
            modType: mod.modType,
            kind: mod.kind,
            val: index
        };
    } else {
        delete shoppingCart[cartKey];
    }

    updateCart();
}

function selectExtra(event, extra) {
    const wasEnabled = extra.enabled;
    const enabled = !wasEnabled;
    extra.enabled = enabled;
    event.currentTarget.classList.toggle('active', enabled);
    event.currentTarget.innerText = `Extra #${extra.id}: ${enabled ? 'Ligado' : 'Desligado'}`;

    sendPost('previewMod', { type: 'extra', extraId: extra.id, enabled: enabled });

    if (!currentProps.extras) currentProps.extras = {};
    currentProps.extras[extra.id] = enabled ? 0 : 1;

    const originalValue = originalProps.extras && originalProps.extras[extra.id] !== undefined ? originalProps.extras[extra.id] : (wasEnabled ? 0 : 1);
    const currentValue = enabled ? 0 : 1;
    const cartKey = `extra_${extra.id}`;

    if (currentValue !== originalValue) {
        shoppingCart[cartKey] = {
            label: `Extra #${extra.id}: ${enabled ? 'Ligado' : 'Desligado'}`,
            price: pricing.visualMod || 0,
            type: 'extra',
            extraId: extra.id,
            val: enabled
        };
    } else {
        delete shoppingCart[cartKey];
    }

    updateCart();
}

// -------------------------------------------------------------
// Neon Section
// -------------------------------------------------------------
function setupNeonSubmenu() {
    const neonToggle = document.getElementById('neon-toggle');
    const neonColorGroup = document.getElementById('neon-color-group');
    const rSlider = document.getElementById('neon-r');
    const gSlider = document.getElementById('neon-g');
    const bSlider = document.getElementById('neon-b');
    const rVal = document.getElementById('neon-r-val');
    const gVal = document.getElementById('neon-g-val');
    const bVal = document.getElementById('neon-b-val');
    const preview = document.getElementById('neon-preview');

    const neonEnabled = currentProps.neonEnabled ? (currentProps.neonEnabled[0] || currentProps.neonEnabled[1] || currentProps.neonEnabled[2] || currentProps.neonEnabled[3]) : false;
    neonToggle.checked = neonEnabled;
    
    if (neonEnabled) {
        neonColorGroup.style.opacity = '1';
        neonColorGroup.style.pointerEvents = 'auto';
    } else {
        neonColorGroup.style.opacity = '0.5';
        neonColorGroup.style.pointerEvents = 'none';
    }

    const currentNeonColor = currentProps.neonColor || [255, 255, 255];
    rSlider.value = currentNeonColor[0];
    gSlider.value = currentNeonColor[1];
    bSlider.value = currentNeonColor[2];
    
    rVal.innerText = rSlider.value;
    gVal.innerText = gSlider.value;
    bVal.innerText = bSlider.value;
    preview.style.backgroundColor = `rgb(${rSlider.value}, ${gSlider.value}, ${bSlider.value})`;

    neonToggle.onchange = function() {
        const checked = this.checked;
        if (checked) {
            neonColorGroup.style.opacity = '1';
            neonColorGroup.style.pointerEvents = 'auto';
        } else {
            neonColorGroup.style.opacity = '0.5';
            neonColorGroup.style.pointerEvents = 'none';
        }
        handleNeonToggleChange(checked);
    };

    const handleRGB = () => {
        rVal.innerText = rSlider.value;
        gVal.innerText = gSlider.value;
        bVal.innerText = bSlider.value;
        preview.style.backgroundColor = `rgb(${rSlider.value}, ${gSlider.value}, ${bSlider.value})`;
        handleNeonColorChange(rSlider.value, gSlider.value, bSlider.value);
    };

    rSlider.oninput = handleRGB;
    gSlider.oninput = handleRGB;
    bSlider.oninput = handleRGB;
}

function handleNeonToggleChange(enabled) {
    sendPost('previewMod', { type: 'neonToggle', enabled: enabled });

    // Update local state
    currentProps.neonEnabled = [enabled, enabled, enabled, enabled];

    const origEnabled = originalProps.neonEnabled ? (originalProps.neonEnabled[0] || false) : false;
    if (enabled !== origEnabled) {
        shoppingCart['neonToggle'] = {
            label: enabled ? 'Kit Neon Subaquático' : 'Remover Neon',
            price: pricing['neonToggle'] || 0,
            type: 'neonToggle',
            val: enabled
        };
    } else {
        delete shoppingCart['neonToggle'];
    }
    updateCart();
}

function handleNeonColorChange(r, g, b) {
    sendPost('previewMod', { type: 'neonColor', r: r, g: g, b: b });

    // Update local state
    currentProps.neonColor = [parseInt(r), parseInt(g), parseInt(b)];

    const origColor = originalProps.neonColor || [255, 255, 255];
    if (parseInt(r) !== origColor[0] || parseInt(g) !== origColor[1] || parseInt(b) !== origColor[2]) {
        shoppingCart['neonColor'] = {
            label: `Cor do Neon (RGB: ${r}, ${g}, ${b})`,
            price: pricing['neonColor'] || 0,
            type: 'neonColor',
            r: r, g: g, b: b
        };
    } else {
        delete shoppingCart['neonColor'];
    }
    updateCart();
}

// -------------------------------------------------------------
// Xenon Section
// -------------------------------------------------------------
function setupXenonSubmenu() {
    const xenonToggle = document.getElementById('xenon-toggle');
    const colorGroup = document.getElementById('xenon-color-group');
    const select = document.getElementById('xenon-color-select');

    const xenonEnabled = currentProps.modXenon || false;
    xenonToggle.checked = xenonEnabled;
    
    if (xenonEnabled) {
        colorGroup.style.opacity = '1';
        colorGroup.style.pointerEvents = 'auto';
    } else {
        colorGroup.style.opacity = '0.5';
        colorGroup.style.pointerEvents = 'none';
    }

    select.value = currentProps.xenonColor !== undefined ? currentProps.xenonColor : 255;

    xenonToggle.onchange = function() {
        const checked = this.checked;
        if (checked) {
            colorGroup.style.opacity = '1';
            colorGroup.style.pointerEvents = 'auto';
            handleXenonToggleChange(true);
        } else {
            colorGroup.style.opacity = '0.5';
            colorGroup.style.pointerEvents = 'none';
            handleXenonToggleChange(false);
        }
    };

    select.onchange = function() {
        handleXenonColorChange(this.value);
    };
}

function handleXenonToggleChange(enabled) {
    sendPost('previewMod', { type: 'xenonColor', val: enabled ? parseInt(document.getElementById('xenon-color-select').value) : -1 });
    
    // Update local state
    currentProps.modXenon = enabled;

    if (enabled !== (originalProps.modXenon || false)) {
        shoppingCart['xenonToggle'] = {
            label: enabled ? 'Ativar Xenon' : 'Desativar Xenon',
            price: enabled ? (pricing['xenonColor'] || 0) : 0,
            type: 'xenonColor',
            val: enabled
        };
    } else {
        delete shoppingCart['xenonToggle'];
    }
    updateCart();
}

function handleXenonColorChange(colorId) {
    const val = parseInt(colorId);
    sendPost('previewMod', { type: 'xenonColor', val: val });

    // Update local state
    currentProps.xenonColor = val;

    if (val !== originalProps.xenonColor) {
        shoppingCart['xenonColor'] = {
            label: `Faróis Xenon (${getXenonLabel(val)})`,
            price: pricing['xenonColor'] || 0,
            type: 'xenonColor',
            val: val
        };
    } else {
        delete shoppingCart['xenonColor'];
    }
    updateCart();
}

function getXenonLabel(id) {
    const colors = {
        255: 'Padrão', 0: 'Branco Frio', 1: 'Azul Claro', 2: 'Azul Escuro', 3: 'Turquesa',
        4: 'Verde Alface', 5: 'Verde Limão', 6: 'Amarelo', 7: 'Laranja',
        8: 'Vermelho', 9: 'Rosa Choque', 10: 'Rosa Choque Forte', 11: 'Roxo Violeta', 12: 'Roxo Escuro'
    };
    return colors[id] || 'Personalizada';
}

// -------------------------------------------------------------
// Windows Section
// -------------------------------------------------------------
function setupWindowsSubmenu() {
    const tintBtns = document.querySelectorAll('.tint-btn');
    tintBtns.forEach(btn => {
        btn.classList.remove('active');
        if (parseInt(btn.getAttribute('data-tint')) === (currentProps.windowTint || 0)) {
            btn.classList.add('active');
        }

        btn.onclick = function() {
            tintBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            handleTintChange(parseInt(this.getAttribute('data-tint')));
        };
    });
}

function handleTintChange(tintId) {
    sendPost('previewMod', { type: 'windowTint', value: tintId }, function(resp) {
        if (resp && resp.windowTint !== undefined) currentProps.windowTint = parseInt(resp.windowTint);
    });

    // Update local state
    currentProps.windowTint = tintId;

    if (tintId !== (originalProps.windowTint || 0)) {
        shoppingCart['windowTint'] = {
            label: `Película Vidros (${getTintLabel(tintId)})`,
            price: pricing['windowTint'] || 0,
            type: 'windowTint',
            val: tintId
        };
    } else {
        delete shoppingCart['windowTint'];
    }
    updateCart();
}

function getTintLabel(id) {
    const labels = { 0: 'Nenhum', 3: 'Claro (30%)', 2: 'Médio (50%)', 1: 'Escuro (75%)', 4: 'Limo (95%)' };
    return labels[id] || 'Custom';
}

// -------------------------------------------------------------
// Services Section
// -------------------------------------------------------------
document.getElementById('apply-wash-btn').onclick = function() {
    sendPost('previewMod', { type: 'wash' });
    shoppingCart['wash'] = {
        label: 'Lavagem Profissional',
        price: pricing['wash'] || 0,
        type: 'wash',
        val: true
    };
    updateCart();
};
document.getElementById('wash-price').innerText = `$${pricing['wash'] || 50}`;

// -------------------------------------------------------------
// Cart and Work Order Calculation
// -------------------------------------------------------------
function updateCart() {
    const cartList = document.getElementById('cart-items-list');
    cartList.innerHTML = "";

    let subtotal = 0;
    const items = Object.values(shoppingCart);

    if (items.length === 0) {
        cartList.innerHTML = `<div class="empty-cart-message">Nenhuma alteração selecionada.</div>`;
        document.getElementById('os-subtotal').innerText = "$0";
        document.getElementById('os-total').innerText = "$0";
        document.getElementById('btn-pay-direct').disabled = true;
        document.getElementById('btn-bill-client').disabled = true;
        document.getElementById('btn-print-os').disabled = true;
        return;
    }

    document.getElementById('btn-pay-direct').disabled = false;
    document.getElementById('btn-bill-client').disabled = false;
    document.getElementById('btn-print-os').disabled = false;

    items.forEach(item => {
        subtotal += item.price;
        const row = document.createElement('div');
        row.className = 'cart-item';
        row.innerHTML = `
            <span class="cart-item-name">${item.label}</span>
            <span class="cart-item-price">$${item.price}</span>
        `;
        cartList.appendChild(row);
    });

    let fee = 0;
    if (isMechanic) {
        const feeInput = document.getElementById('os-fee-input');
        if (feeInput && feeInput.value) {
            fee = parseInt(feeInput.value) || 0;
        }
    }

    document.getElementById('os-subtotal').innerText = `$${subtotal}`;
    document.getElementById('os-total').innerText = `$${subtotal + fee}`;
}

// -------------------------------------------------------------
// UI Actions Handlers
// -------------------------------------------------------------

// Pay and Save Direct with loading state
document.getElementById('btn-pay-direct').onclick = async function() {
    const simpleCart = {};
    for (let key in shoppingCart) {
        simpleCart[key] = true;
    }

    this.disabled = true;
    this.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Processando...';

    await sendPost('checkout', { cart: simpleCart });

    this.disabled = false;
    this.innerHTML = '<i class="fa-solid fa-credit-card"></i> Pagar e Salvar';
};

// Bill Client (Invoice) with loading state
document.getElementById('btn-bill-client').onclick = async function() {
    const clientId = document.getElementById('os-client-id-input').value;
    if (!clientId || clientId.trim() === "") {
        // Flash input red or notify
        document.getElementById('os-client-id-input').style.borderColor = 'var(--glass-danger)';
        setTimeout(() => {
            document.getElementById('os-client-id-input').style.borderColor = 'var(--glass-line)';
        }, 1500);
        return;
    }

    const feeInput = document.getElementById('os-fee-input');
    const fee = feeInput ? (parseInt(feeInput.value) || 0) : 0;

    const simpleCart = {};
    for (let key in shoppingCart) {
        simpleCart[key] = true;
    }

    this.disabled = true;
    this.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Cobrando...';

    await sendPost('billClient', {
        targetId: clientId,
        cart: simpleCart,
        plate: plate,
        fee: fee
    });

    this.disabled = false;
    this.innerHTML = '<i class="fa-solid fa-file-invoice-dollar"></i> Cobrar Cliente';
};

// Update total on fee input change
document.getElementById('os-fee-input').addEventListener('input', function() {
    updateCart();
});

// Before/After toggle: hold to see original
let showingOriginal = false;
document.getElementById('toggle-before-after').onclick = function() {
    showingOriginal = !showingOriginal;
    if (showingOriginal) {
        sendPost('toggleOriginal', { active: true });
    } else {
        // Reapply all cart items to restore "after" state
        for (let key in shoppingCart) {
            const item = shoppingCart[key];
            if (item.type === 'wheels') {
                sendPost('previewMod', { type: 'wheels', cat: item.cat, value: item.val });
            } else if (item.type === 'visualMod') {
                sendPost('previewMod', { type: 'visualMod', modType: item.modType, kind: item.kind, value: item.val });
            } else if (item.type === 'extra') {
                sendPost('previewMod', { type: 'extra', extraId: item.extraId, enabled: item.val });
            } else if (item.type === 'neonToggle') {
                sendPost('previewMod', { type: 'neonToggle', enabled: item.val });
            } else if (item.type === 'neonColor') {
                sendPost('previewMod', { type: 'neonColor', r: item.r, g: item.g, b: item.b });
            } else if (item.type === 'xenonColor') {
                sendPost('previewMod', { type: 'xenonColor', val: item.val });
            } else if (item.type === 'windowTint') {
                sendPost('previewMod', { type: 'windowTint', value: item.val });
            } else if (item.type === 'wash') {
                sendPost('previewMod', { type: 'wash' });
            } else if (item.type === 'primaryColor' || item.type === 'secondaryColor' || item.type === 'pearlescentColor' || item.type === 'wheelColor') {
                sendPost('previewMod', { type: item.type, value: item.val });
            }
        }
        sendPost('toggleOriginal', { active: false });
    }
    this.innerHTML = showingOriginal
        ? '<i class="fa-solid fa-eye-slash"></i> Ver Modificado'
        : '<i class="fa-solid fa-eye"></i> Comparar';
};

// Keyboard shortcut: SPACE for before/after
document.addEventListener('keydown', function(e) {
    if (e.key === ' ' || e.code === 'Space') {
        e.preventDefault();
        if (!showingOriginal) {
            showingOriginal = true;
            sendPost('toggleOriginal', { active: true });
            document.getElementById('toggle-before-after').innerHTML = '<i class="fa-solid fa-eye-slash"></i> Ver Modificado';
        }
    }
});
document.addEventListener('keyup', function(e) {
    if (e.key === ' ' || e.code === 'Space') {
        e.preventDefault();
        if (showingOriginal) {
            showingOriginal = false;
            sendPost('toggleOriginal', { active: false });
            document.getElementById('toggle-before-after').innerHTML = '<i class="fa-solid fa-eye"></i> Comparar';
        }
    }
});

// Print/Publish Work Order (Ordem de Serviço) in Chat
document.getElementById('btn-print-os').onclick = function() {
    const clientVal = document.getElementById('os-client-id-input').value;
    const clientNameStr = clientVal && clientVal.trim() !== "" ? `Passaporte #${clientVal}` : "Cliente Local";
    const itemsList = Object.values(shoppingCart).map(it => `- ${it.label} ($${it.price})`);
    
    let total = 0;
    Object.values(shoppingCart).forEach(it => total += it.price);

    sendPost('createWorkOrder', {
        plate: plate,
        client: clientNameStr,
        mechanic: mechanicName,
        total: total,
        items: itemsList
    });
};

// Cancel & Close UI
document.getElementById('btn-cancel-customs').onclick = function() {
    sendPost('closeUI', {});
};

// Close on Escape key
window.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        sendPost('closeUI', {});
    }
});

// Start camera rotation when clicking outside the panels (on the transparent body)
document.addEventListener('mousedown', function(e) {
    if (e.target === document.body || e.target === document.documentElement) {
        sendPost('startCameraRotation', {});
    }
});
