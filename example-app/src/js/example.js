import { CapacitorDevServer } from 'capacitor-dev-server';

const SERVERS_KEY = 'saved_dev_servers';

window.checkServer = async () => {
    const result = await CapacitorDevServer.getServer();
    document.getElementById('result').innerText = JSON.stringify(result, null, 2);
}

window.addAndConnect = async () => {
    const input = document.getElementById('serverUrl');
    const url = input.value.trim();
    if (!url) return;

    let servers = getSavedServers();
    if (!servers.includes(url)) {
        servers.push(url);
        saveServers(servers);
    }
    input.value = '';
    await connectToServer(url);
    renderServerList();
}

window.connectToServer = async (url) => {
    try {
        const result = await CapacitorDevServer.setServer({ url, cleartext: true });
        alert(`Connected to ${url}.\n\nRestart the app (kill and open) to apply changes.`);
        checkServer();
    } catch (e) {
        alert('Failed to connect: ' + e.message);
    }
}

window.resetServer = async () => {
    if (confirm('Are you sure you want to reset to project defaults?')) {
        await CapacitorDevServer.clearServer();
        alert('Configurations cleared. Restart the app to apply defaults.');
        checkServer();
    }
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
    
    if (servers.length === 0) {
        list.innerHTML = `
            <div class="card bg-base-100 shadow-sm border border-dashed border-base-300">
                <div class="card-body p-4 text-center text-xs opacity-40 italic">
                    No saved servers yet
                </div>
            </div>
        `;
        return;
    }

    list.innerHTML = servers.map(url => `
        <div class="card bg-base-100 shadow-md group border border-transparent hover:border-primary/20 transition-all">
            <div class="card-body p-4 flex-row items-center justify-between">
                <div class="overflow-hidden mr-2">
                    <p class="font-bold text-sm truncate">${url}</p>
                </div>
                <div class="flex gap-2">
                    <button class="btn btn-primary btn-sm btn-square" onclick="connectToServer('${url}')" title="Connect">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                    </button>
                    <button class="btn btn-ghost btn-sm btn-square text-error" onclick="deleteServer('${url}')" title="Delete">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Initial render
renderServerList();
checkServer();
