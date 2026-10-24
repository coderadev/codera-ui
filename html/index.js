const ui = document.getElementById('textUI');

// key name -> icon file in html/icons (anything else gets a CSS keycap)
const ICONS = {
    E: 'keyboard_e', Q: 'keyboard_q',
    CTRL: 'keyboard_ctrl', LCTRL: 'keyboard_ctrl',
    SHIFT: 'keyboard_shift', LSHIFT: 'keyboard_shift',
    ESC: 'keyboard_escape', ESCAPE: 'keyboard_escape',
    LMB: 'mouse_left_outline', MOUSE_LEFT: 'mouse_left_outline', MOUSE1: 'mouse_left_outline',
    RMB: 'mouse_right_outline', MOUSE_RIGHT: 'mouse_right_outline', MOUSE2: 'mouse_right_outline',
    SCROLL: 'mouse_scroll_outline', MOUSE_SCROLL: 'mouse_scroll_outline', WHEEL: 'mouse_scroll_outline',
};

function keyNode(token) {
    const name = String(token).trim();
    const icon = ICONS[name.toUpperCase().replace(/[\s-]+/g, '_')];
    if (icon) {
        const img = document.createElement('img');
        img.src = `icons/${icon}.png`;
        img.alt = name;
        return img;
    }
    const cap = document.createElement('span');
    cap.className = 'keycap';
    cap.textContent = name.toUpperCase();
    return cap;
}

// "CTRL+LMB" -> [CTRL] + [LMB]
function keysNode(key) {
    const wrap = document.createElement('span');
    wrap.className = 'keys';
    String(key).split('+').filter((t) => t.trim() !== '').forEach((token, i) => {
        if (i > 0) {
            const plus = document.createElement('span');
            plus.className = 'plus';
            plus.textContent = '+';
            wrap.appendChild(plus);
        }
        wrap.appendChild(keyNode(token));
    });
    return wrap;
}

// hints: [{ key, text }]  (single prompt = one hint)
function render(hints, hideKey) {
    ui.replaceChildren();
    hints.forEach((h, i) => {
        if (i > 0) {
            const sep = document.createElement('span');
            sep.className = 'sep';
            sep.textContent = '/';
            ui.appendChild(sep);
        }
        const item = document.createElement('div');
        item.className = 'hint';
        if (!hideKey && h.key != null && h.key !== '') item.appendChild(keysNode(h.key));
        const label = document.createElement('span');
        label.innerHTML = h.text == null ? '' : h.text; // qb-core sends simple markup
        item.appendChild(label);
        ui.appendChild(item);
    });
}

function hintsFrom(ed) {
    return Array.isArray(ed.hints) ? ed.hints : [{ key: ed.key, text: ed.text }];
}

window.addEventListener('message', (event) => {
    const ed = event.data;

    if (ed.action === 'textUI') {
        if (ed.show) {
            render(hintsFrom(ed), !!ed.hide);
            ui.classList.add('visible');
        } else {
            ui.classList.remove('visible');
        }
    } else if (ed.action === 'textUIUpdate') {
        render(hintsFrom(ed), false);
    }
});
