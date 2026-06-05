const body = document.body;
const categoryEl = document.getElementById('category');
const countEl = document.getElementById('count');
const tabsEl = document.getElementById('tabs');
const listEl = document.getElementById('list');
const commandEl = document.getElementById('command');
const searchInput = document.getElementById('search-input');
let searchTimer = null;
let activeCategoryIndex = 2;

function nui(event, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

function commandFor(item) {
    if (!item) return '/e';
    if (item.category === 'walks') return `/walk ${item.name}`;
    if (item.category === 'expressions') return `/mood ${item.name}`;
    if (item.category === 'shared') return `/nearby ${item.name}`;
    return `/e ${item.name}`;
}

function renderTabs(categories, index) {
    tabsEl.innerHTML = '';
    categories.forEach((category, i) => {
        const span = document.createElement('span');
        span.className = `tab${i + 1 === index ? ' active' : ''}`;
        span.textContent = category.label;
        span.addEventListener('click', () => nui('category', { delta: (i + 1) - index }));
        tabsEl.appendChild(span);
    });
}

function renderList(items, selectedIndex) {
    listEl.innerHTML = '';

    const visibleRows = 8;
    const selected = Math.max(1, selectedIndex || 1);
    const start = Math.max(1, selected - Math.floor(visibleRows / 2));
    const end = Math.min(items.length, start + visibleRows - 1);

    for (let i = start; i <= end; i += 1) {
        const item = items[i - 1];
        const row = document.createElement('div');
        row.className = `item${i === selected ? ' selected' : ''}`;
        row.textContent = item.label;
        listEl.appendChild(row);
    }

    if (!items.length) {
        const row = document.createElement('div');
        row.className = 'item';
        row.textContent = 'Digite acima para pesquisar';
        listEl.appendChild(row);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'close') {
        body.classList.remove('open');
        return;
    }

    if (data.action !== 'open') return;

    const categories = Array.isArray(data.categories) ? data.categories : [];
    const items = Array.isArray(data.items) ? data.items : [];
    const categoryIndex = data.categoryIndex || 1;
    const selectedIndex = data.selectedIndex || 1;
    const selectedDisplay = items.length ? selectedIndex : 0;
    const selected = items[selectedIndex - 1];
    activeCategoryIndex = categoryIndex;

    const category = categories[categoryIndex - 1];
    categoryEl.textContent = category ? category.label : 'Emotes';
    countEl.textContent = `${selectedDisplay} / ${data.total || items.length || 0}`;
    if (document.activeElement !== searchInput) {
        searchInput.value = data.searchTerm || '';
    }
    searchInput.disabled = categoryIndex !== 1;
    searchInput.placeholder = categoryIndex === 1 ? 'Digite para filtrar' : 'Selecione Busca para digitar';
    commandEl.textContent = commandFor(selected);
    renderTabs(categories, categoryIndex);
    renderList(items, selectedIndex);
    body.classList.add('open');
    if (categoryIndex === 1) {
        searchInput.focus();
    } else {
        searchInput.blur();
    }
});

searchInput.addEventListener('input', () => {
    if (activeCategoryIndex !== 1) return;

    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
        nui('search', { term: searchInput.value });
    }, 120);
});

document.addEventListener('keydown', (event) => {
    if (!body.classList.contains('open')) return;

    if (event.key === 'ArrowUp') {
        event.preventDefault();
        nui('navigate', { delta: -1 });
    } else if (event.key === 'ArrowDown') {
        event.preventDefault();
        nui('navigate', { delta: 1 });
    } else if (event.key === 'ArrowLeft') {
        event.preventDefault();
        nui('category', { delta: -1 });
    } else if (event.key === 'ArrowRight') {
        event.preventDefault();
        nui('category', { delta: 1 });
    } else if (event.key === 'Enter') {
        event.preventDefault();
        nui('play');
    } else if (event.key === ' ') {
        event.preventDefault();
        nui('preview');
    } else if (event.key === 'Escape' || event.key === 'Backspace' && !searchInput.value) {
        event.preventDefault();
        nui('close');
    }
});
