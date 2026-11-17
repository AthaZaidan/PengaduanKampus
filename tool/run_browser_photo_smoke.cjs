// Jalankan setelah dart compile js tool/foto_lokal_browser_smoke.dart -o build/foto_smoke/main.js
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const root = path.resolve(__dirname, '../build/foto_smoke');
const server = http.createServer((req, res) => {
  if (req.url === '/main.js') {
    res.setHeader('Content-Type', 'text/javascript');
    res.end(fs.readFileSync(path.join(root, 'main.js')));
  } else {
    res.setHeader('Content-Type', 'text/html');
    res.end('<!doctype html><html><body>RUNNING<script defer src="/main.js"></script></body></html>');
  }
});
server.listen(0, '127.0.0.1', async () => {
  const url = 'http://127.0.0.1:' + server.address().port + '/';
  const profile = path.join(root, 'profile-' + Date.now());
  const executable = process.env.CHROME_EXECUTABLE || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
  const child = spawn(executable, ['--headless', '--disable-gpu', '--no-first-run',
    '--no-default-browser-check', '--user-data-dir=' + profile,
    '--remote-debugging-port=0', url], { windowsHide: true, stdio: 'ignore' });
  let ws, interval, finished = false;
  let last = 'Chrome belum terhubung';
  const finish = (message, success) => {
    if (finished) return;
    finished = true;
    process.stdout.write(message + '\n');
    clearInterval(interval);
    clearTimeout(timer);
    if (ws) ws.close();
    child.kill();
    server.close();
    process.exitCode = success ? 0 : 1;
  };
  const timer = setTimeout(() => finish('FAIL: browser smoke timed out; ' + last, false), 30000);
  child.on('error', error => finish('FAIL: ' + error.message, false));
  let target;
  for (let i = 0; i < 100 && !finished; i++) {
    try {
      const port = fs.readFileSync(path.join(profile, 'DevToolsActivePort'), 'utf8').split('\n')[0].trim();
      const targets = await (await fetch('http://127.0.0.1:' + port + '/json/list')).json();
      target = targets.find(t => t.type === 'page' && t.url.startsWith(url));
      if (target) break;
    } catch {}
    await new Promise(r => setTimeout(r, 100));
  }
  if (!target) return finish('FAIL: Chrome tidak membuka halaman pengujian', false);
  ws = new WebSocket(target.webSocketDebuggerUrl);
  let id = 1;
  ws.onopen = () => {
    ws.send(JSON.stringify({ id: id++, method: 'Runtime.enable' }));
    ws.send(JSON.stringify({ id: id++, method: 'Log.enable' }));
    interval = setInterval(() => ws.send(JSON.stringify({ id: id++, method: 'Runtime.evaluate',
      params: { expression: 'document.body && document.body.textContent', returnByValue: true } })), 200);
  };
  ws.onerror = () => finish('FAIL: koneksi DevTools gagal', false);
  ws.onmessage = e => {
    const m = JSON.parse(e.data);
    if (m.method === 'Runtime.exceptionThrown') {
      const detail = m.params.exceptionDetails;
      return finish('FAIL: ' + (detail.exception?.description || detail.text), false);
    }
    const value = m.result?.result?.value;
    if (typeof value === 'string') {
      last = value;
      if (value.includes('PASS:') || value.includes('FAIL:')) finish(value, value.includes('PASS:'));
    }
  };
});
