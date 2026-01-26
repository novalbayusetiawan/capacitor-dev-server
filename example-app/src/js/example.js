import { DevServer } from 'capacitor-dev-server';

const SERVERS_KEY = 'saved_dev_servers';

window.checkServer = async () => {
    const result = await DevServer.getServer();
    document.getElementById('result').innerText = JSON.stringify(result, null, 2);
}

window.addAndConnect = async () => {
    const input = document.getElementById('serverUrl');
    const persistToggle = document.getElementById('persistToggle');
    const url = input.value.trim();
    if (!url) return;

    let servers = getSavedServers();
    if (!servers.includes(url)) {
        servers.push(url);
        saveServers(servers);
    }
    input.value = '';
    const persist = persistToggle.checked;
    await connectToServer(url, persist);
    renderServerList();
}

window.connectToServer = async (url, persist = false) => {
    try {
        const result = await DevServer.setServer({ url, persist });
        checkServer();
    } catch (e) {
        alert('Failed to connect: ' + e.message);
    }
}

window.resetServer = async () => {
    if (confirm('Are you sure you want to reset to project defaults?')) {
        await DevServer.clearServer();
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
            <div class="bg-base-200/30 rounded-lg p-6 border border-dashed border-base-content/10 text-center">
                <p class="text-xs text-base-content/40 italic">No history yet</p>
            </div>
        `;
        return;
    }

    list.innerHTML = servers.map(url => `
        <div class="group bg-base-100/50 hover:bg-base-100 border border-base-content/5 rounded-lg p-3 transition-all duration-200 flex items-center justify-between shadow-sm hover:shadow-md">
            <div class="flex items-center gap-3 overflow-hidden">
                <div class="bg-primary/10 p-2 rounded-md group-hover:bg-primary/20 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" /></svg>
                </div>
                <p class="font-medium text-xs truncate max-w-[120px] sm:max-w-xs opacity-70 group-hover:opacity-100 transition-opacity">${url}</p>
            </div>
            <div class="flex gap-2 opacity-80 group-hover:opacity-100 transition-opacity">
                <button class="btn btn-primary btn-xs" onclick="connectToServer('${url}')">Connect</button>
                <button class="btn btn-ghost btn-xs text-error btn-square" onclick="deleteServer('${url}')" title="Delete">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                </button>
            </div>
        </div>
    `).join('');
}

// Initial render
renderServerList();
checkServer();
refreshAssetList();

// Asset Management Logic
document.addEventListener('app:download', async () => {
    const input = document.getElementById('assetUrl');
    const overwriteToggle = document.getElementById('overwriteToggle');
    const url = input.value.trim();
    if (!url) return;
    
    try {
        await DevServer.downloadAsset({ 
            url, 
            overwrite: overwriteToggle.checked 
        });
        alert('Download complete!');
        refreshAssetList();
    } catch (e) {
        alert('Download failed: ' + e.message);
    }
});

document.addEventListener('app:restore', async () => {
    console.log('Restore event received');
    if (confirm('Restore default assets?')) {
        console.log('Confirmed restore');
        try {
           if (!DevServer.restoreDefaultAsset) {
               throw new Error('DevServer.restoreDefaultAsset is not defined');
           }
           await DevServer.restoreDefaultAsset(); 
           console.log('Restore command sent');
        } catch(e) {
            console.error('Restore error', e);
            alert('Restore failed: ' + e.message);
        }
    }
});

async function refreshAssetList() {
    const list = document.getElementById('assetList');
    try {
        const result = await DevServer.getAssetList();
        const assets = result.assets || [];
        
        if (assets.length === 0) {
            list.innerHTML = `
            <div class="bg-base-200/30 rounded-lg p-6 border border-dashed border-base-content/10 text-center">
                <p class="text-xs text-base-content/40 italic">No downloaded bundles</p>
            </div>`;
            return;
        }
        
        list.innerHTML = assets.map(asset => `
            <div class="group bg-base-100/50 hover:bg-base-100 border border-base-content/5 rounded-lg p-3 transition-all duration-200 flex items-center justify-between shadow-sm hover:shadow-md">
                <div class="flex items-center gap-3 overflow-hidden">
                    <div class="bg-secondary/10 p-2 rounded-md group-hover:bg-secondary/20 transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" /></svg>
                    </div>
                    <span class="font-medium text-xs truncate max-w-[120px] sm:max-w-xs opacity-70 group-hover:opacity-100 transition-opacity">${asset}</span>
                </div>
                <div class="flex gap-2 opacity-80 group-hover:opacity-100 transition-opacity">
                    <button class="btn btn-xs btn-primary font-normal" onclick="window.applyAsset('${asset}')">Apply</button>
                    <button class="btn btn-xs btn-ghost text-error btn-square" onclick="window.removeAsset('${asset}')">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                    </button>
                </div>
            </div>
        `).join('');
    } catch (e) {
        console.error('Failed to get assets', e);
    }
}

window.applyAsset = async (assetName) => {
    const persist = confirm(`Apply asset ${assetName} and persist across restarts?`);
    try {
        await DevServer.applyAsset({ assetName, persist });
        // The app will reload if successful, so no alert needed usually, but just in case:
        if (!persist) {
             // Maybe alert or just done. App reloads anyway.
        }
    } catch (e) {
        alert('Failed to apply: ' + e.message);
    }
}

window.removeAsset = async (assetName) => {
    if (confirm(`Delete asset ${assetName}?`)) {
        try {
            await DevServer.removeAsset({ assetName });
            refreshAssetList();
        } catch (e) {
            alert('Failed to delete: ' + e.message);
        }
    }
}
