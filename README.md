# figcraft-server di Dokploy

Server kolaborasi FigCraft (live session) untuk Rendy, dijalankan sebagai aplikasi
Dockerfile di Dokploy (app.runto.my.id, host 198.144.183.178).

## Isi repo

- `Dockerfile` — image ringan dari binary prebuilt v0.18.1 (SHA256 terverifikasi).
  Mirip stage runtime `packaging/server/Dockerfile` resmi, tapi tanpa cargo build.
- `server.toml` — listen 0.0.0.0:47900, data `/data`, `public_url`
  `wss://figcraft.runto.my.id/`, `open_publish = false` (private), `max_file_mb = 64`.

## Deploy di Dokploy

1. Push repo ini ke GitHub (mis. `rejidan/figcraft-server-dokploy`), branch `main`.
2. Dokploy → buat Application baru (provider Dockerfile), hubungkan repo ini.
3. Port: **47900**. Domain: **figcraft.runto.my.id** (Traefik Dokploy urus TLS).
4. Mount volume persisten di **/data** — server key + semua file tersimpan di sana.
   Tanpa volume ini, redeploy = server key baru dan semua file hilang.
5. DNS: A record `figcraft.runto.my.id` → 198.144.183.178 (DNS-only di Cloudflare).
6. Deploy, lalu cek `https://figcraft.runto.my.id/healthz` → `ok`.

## Editor di browser (figcraft-web)

Server kolaborasi saja tidak cukup buat join dari browser: tidak ada web build
resmi yang di-host publik, dan figcraft-server cuma menjawab `/healthz` + WebSocket.
Jadi repo ini juga meng-host editor web resmi v0.18.1:

- `web/` — isi `figcraft-web-0.18.1.zip` resmi (SHA256 `2fbeb93f5022b0a7cc9d8528f1ed7e2b54c94d213ef79e65128aa898c399f02b`),
  `index.html`-nya sudah ditambah `<meta name="figcraft-server"
  content="wss://figcraft.runto.my.id/">` supaya halaman langsung memakai
  server sendiri tanpa set di Preferences.
- `Dockerfile.web` + `nginx-figcraft.conf` — nginx:alpine, `.wasm` sebagai
  `application/wasm`, gzip, cache immutable untuk file ber-hash.
- Service `figcraft-web` di `docker-compose.yml`, domain
  **app.figcraft.runto.my.id** → port 80 (HTTPS via Traefik), DNS A ke
  198.144.183.178 (DNS-only).
- Join dari browser: `https://app.figcraft.runto.my.id/#join=<invite-link-encoded>`
  (di headless Chrome tambah `?webgl` sebelum `#join=` karena WebGPU tidak ada).

## Ambil server key (sekali, JANGAN tampilkan di chat)

Dari host Dokploy (SSH root):

```
docker exec <nama-container> /usr/local/bin/figcraft-server --config /etc/figcraft-server/server.toml key
```

Hasilnya `wss://figcraft.runto.my.id/?key=...` — ini alamat server + key yang
dimasukkan di FigCraft (Preferences → Server for online sharing, atau
Share → Advanced → Publish to another server). Key ini juga ada di backup
data `/data`, jadi jangan dibagikan sembarangan: siapa pun yang pegang key
bisa publish file ke server ini.

## Pakai dari FigCraft (Mac)

- Preferences → Server for online sharing → `wss://figcraft.runto.my.id/`
- Publish: File → Publish to server… (atau Share → Advanced → Publish to
  another server dengan alamat key di atas)
- Share → Online → Start sharing → join code muncul dari server sendiri.

## Catatan

- Server Dokploy tidak diperpanjang Jan 2027. Sebelum itu, pindahkan `/data`
  (backup volume) ke Kamal/RackNerd kalau figcraft-server mau hidup permanen.
- Server ini private (`open_publish = false`): hanya yang pegang key yang bisa
  publish. File tidak terenkripsi di server; TLS hanya melindungi transport.
