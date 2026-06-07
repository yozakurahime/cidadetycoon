const messagesContainer = document.getElementById('messages-container');
const inputContainer = document.getElementById('input-container');
const chatContainer = document.getElementById('chat-container');
const chatInput = document.getElementById('chat-input');

let isChatOpen = false;
const MESSAGE_LIFETIME = 15000;
const MAX_MESSAGES = 80;

// ==========================================================================
// RENDERIZAÇÃO SEGURA (TEXTCONTENT ONLY)
// ==========================================================================

function addMessage(data) {
    const msgEl = document.createElement('div');
    msgEl.className = `message-item ${data.type || 'system'}`;

    if (data.author) {
        const header = document.createElement('div');
        header.className = 'message-header';

        const author = document.createElement('span');
        author.className = 'message-author';
        author.textContent = data.author;

        header.appendChild(author);

        if (data.tag) {
            const tag = document.createElement('span');
            tag.className = 'message-tag';
            tag.textContent = data.tag.substring(0, 15);
            header.appendChild(tag);
        }

        msgEl.appendChild(header);
    }

    const body = document.createElement('div');
    body.className = 'message-body';
    body.textContent = data.message;
    msgEl.appendChild(body);

    messagesContainer.appendChild(msgEl);
    
    if (messagesContainer.children.length > MAX_MESSAGES) {
        messagesContainer.removeChild(messagesContainer.children[0]);
    }

    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    if (!isChatOpen) {
        startFading(msgEl);
    }
}

function startFading(el) {
    if (el.timeout) clearTimeout(el.timeout);
    el.timeout = setTimeout(() => {
        if (!isChatOpen) {
            el.classList.add('fading');
            setTimeout(() => { if (!isChatOpen) el.remove(); }, 2000);
        }
    }, MESSAGE_LIFETIME);
}

function openChat() {
    isChatOpen = true;
    chatContainer.classList.add('active');
    inputContainer.classList.remove('hidden');
    Array.from(messagesContainer.children).forEach(msg => {
        msg.classList.remove('fading');
        if (msg.timeout) clearTimeout(msg.timeout);
    });
    chatInput.focus();
}

function closeChat() {
    isChatOpen = false;
    chatContainer.classList.remove('active');
    inputContainer.classList.add('hidden');
    chatInput.value = '';
    Array.from(messagesContainer.children).forEach(msg => startFading(msg));
    postNUI('chat:focus', { focus: false });
}

// ==========================================
// COMUNICAÇÃO
// ==========================================

window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'addMessage') {
        addMessage(data.payload);
    } else if (data.action === 'openChat') {
        openChat();
    } else if (data.action === 'closeChat') {
        closeChat();
    } else if (data.action === 'clear') {
        messagesContainer.innerHTML = '';
    }
});

chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        const message = chatInput.value.trim();
        if (message.length > 0) postNUI('chat:submit', { message });
        closeChat();
    } else if (e.key === 'Escape') {
        closeChat();
    }
});

function postNUI(action, data = {}) {
    const res = (typeof GetParentResourceName !== 'undefined') ? GetParentResourceName() : 'cidade_chat';
    return fetch(`https://${res}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => {});
}
