import { CapacitorDevServer } from 'capacitor-dev-server';

const SERVERS_KEY = 'saved_dev_servers';

window.checkServer = async () => {
    const result = await CapacitorDevServer.getServer();
    document.getElementById('result').innerText = JSON.stringify(result, null, 2);
}

window.addAndConnect = async () => {
    const url = document.getElementById('serverUrl').value.trim();
    if (!url) return;

    let servers = getSavedServers();
    if (!servers.includes(url)) {
        servers.push(url);
        saveServers(servers);
    }
    await connectToServer(url);
    renderServerList();
}

window.connectToServer = async (url) => {
    const result = await CapacitorDevServer.setServer({ url, cleartext: true });
    alert(`Connected to ${url}. Restart the app to apply.`);
    checkServer();
}

window.deleteServer = (url) => {
    let servers = getSavedServers();
    servers = servers.filter(s => s !== url);
    saveServers(servers);
    renderServerList();
}

function getSavedServers() {
    const data = localStorage.getItem(SERVERS_KEY);
    return data ? JSON.parse(data) : [];
}

function saveServers(servers) {
    localStorage.setItem(SERVERS_KEY, JSON.stringify(servers));
}

function renderServerList() {
    const list = document.getElementById('serverList');
    const servers = getSavedServers();
    list.innerHTML = servers.map(url => `
        <li style="margin-bottom: 8px; border-bottom: 1px solid #ccc; padding-bottom: 8px;">
            <div style="font-weight: bold; margin-bottom: 4px;">${url}</div>
            <button onclick="connectToServer('${url}')">Connect</button>
            <button onclick="deleteServer('${url}')">Delete</button>
        </li>
    `).join('');
}

// Initial render
renderServerList();
checkServer();
