import { CapacitorDevServer } from 'capacitor-dev-server';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    CapacitorDevServer.echo({ value: inputValue })
}
