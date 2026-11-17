// Jalankan hanya melalui Firebase Emulator Suite, tanpa akses proyek asli.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const project = 'demo-pengaduan-kampus';
const host = process.env.FIRESTORE_EMULATOR_HOST;
const storage = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
const root = `projects/${project}/databases/(default)/documents`;
const url = `http://${host}/v1/${root}`;
function token(uid) {
  const encode = x => Buffer.from(JSON.stringify(x)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    sub: uid, user_id: uid, aud: project, iss: `https://securetoken.google.com/${project}`,
    iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: { sign_in_provider: 'password' },
  })}.`;
}
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  return { mapValue: { fields: fields(v) } };
}
function fields(obj) { return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, value(v)])); }
function headers(uid) {
  return { 'Content-Type': 'application/json', ...(uid ? { Authorization: `Bearer ${uid === 'owner' ? 'owner' : token(uid)}` } : {}) };
}
async function write(path, obj, uid, transforms = []) {
  return fetch(`${url}:commit`, { method: 'POST', headers: headers(uid),
    body: JSON.stringify({ writes: [{ update: { name: `${root}/${path}`, fields: fields(obj) },
      ...(transforms.length ? { updateTransforms: transforms.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })) } : {}),
    }] }),
  });
}
async function status(response, expected) {
  const body = await response.text();
  assert.equal(response.status, expected, body);
}
function entry(status, uid, catatan = null) {
  return { status, waktu: new Date(), oleh: uid, olehId: uid, catatan };
}
function laporan(id, uid = 'pelapor') {
  return { judul: `Laporan ${id}`, deskripsi: 'Lampu mati', lokasi: 'Gedung A',
    kategori: 'listrik', prioritas: 'sedang', pelapor: uid, pelaporId: uid,
    tanggalLapor: new Date(), status: 'menunggu', catatanAdmin: null,
    teknisiId: null, teknisiNama: null, fotoPaths: [], fotoSesudahPaths: [],
    revisi: 0, riwayat: [entry('menunggu', uid)], updatedBy: uid };
}
async function perubahan(d, id, uid, berikut, extra = {}) {
  Object.assign(d, extra, { status: berikut, revisi: d.revisi + 1, updatedBy: uid });
  d.riwayat.push(entry(berikut, uid));
  return write(`laporan/${id}`, d, uid, ['updatedAt']);
}
async function upload(path, uid, contentType = 'image/png', body = Buffer.from([137, 80, 78, 71])) {
  return fetch(`http://${storage}/v0/b/${project}.appspot.com/o?name=${encodeURIComponent(path)}`, {
    method: 'POST', headers: { Authorization: `Bearer ${token(uid)}`, 'Content-Type': contentType }, body,
  });
}

test('aturan akses dan alur laporan di emulator', { skip: !host || !storage }, async t => {
  for (const [uid, role] of [['admin', 'admin'], ['teknisi', 'teknisi'], ['lain', 'mahasiswa'], ['pelapor', 'mahasiswa']]) {
    await status(await write(`users/${uid}`, { uid, role, name: uid }, 'owner'), 200);
  }
  await t.test('profil privat dan peningkatan peran ditolak', async () => {
    await status(await fetch(`${url}/users/pelapor`), 403);
    await status(await fetch(`${url}/users/pelapor`, { headers: headers('lain') }), 403);
    await status(await write('users/pelapor', { uid: 'pelapor', role: 'admin', name: 'pelapor' }, 'pelapor'), 403);
  });
  const d = laporan('utama');
  const path = 'laporan/pelapor/utama/sebelum/pelapor/foto';
  await t.test('upload privat, tipe dan pemilik divalidasi', async () => {
    await status(await upload(path, 'lain'), 403);
    await status(await upload(path, 'pelapor', 'text/plain'), 403);
    await status(await upload(path, 'pelapor'), 200);
    d.fotoPaths.push(path);
  });
  await t.test('pelapor membuat laporan, pengguna lain tidak dapat membaca', async () => {
    await status(await write('laporan/utama', d, 'pelapor', ['createdAt', 'updatedAt']), 200);
    await status(await fetch(`${url}/laporan/utama`, { headers: headers('lain') }), 403);
    await status(await fetch(`${url}/laporan/utama`, { headers: headers('pelapor') }), 200);
    const snap = await (await fetch(`${url}/laporan/utama`, { headers: headers('owner') })).json();
    d.createdAt = new Date(snap.fields.createdAt.timestampValue);
  });
  await t.test('kueri harus sesuai pemilik atau peran admin', async () => {
    const query = uid => fetch(`${url}:runQuery`, { method: 'POST', headers: headers(uid),
      body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'laporan' }] } }),
    });
    await status(await query('pelapor'), 403);
    await status(await query('admin'), 200);
    await status(await fetch(`${url}:runQuery`, { method: 'POST', headers: headers('pelapor'),
      body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'laporan' }],
        where: { fieldFilter: { field: { fieldPath: 'pelaporId' }, op: 'EQUAL', value: value('pelapor') } },
      } }),
    }), 200);
  });
  await t.test('pelapor tidak boleh verifikasi atau memalsukan pemilik', async () => {
    const palsu = structuredClone(d);
    await status(await perubahan(palsu, 'utama', 'pelapor', 'diverifikasi'), 403);
    await status(await write('laporan/palsu', laporan('palsu', 'lain'), 'pelapor', ['createdAt', 'updatedAt']), 403);
  });
  await t.test('admin verifikasi dan penugasan; teknisi hanya tugasnya', async () => {
    await status(await perubahan(d, 'utama', 'admin', 'diverifikasi'), 200);
    await status(await perubahan(d, 'utama', 'admin', 'ditugaskan', { teknisiId: 'teknisi', teknisiNama: 'Teknisi' }), 200);
    await status(await fetch(`${url}/laporan/utama`, { headers: headers('teknisi') }), 200);
    const palsu = structuredClone(d);
    await status(await perubahan(palsu, 'utama', 'lain', 'diproses'), 403);
    await status(await perubahan(d, 'utama', 'teknisi', 'diproses'), 200);
  });
  await t.test('foto sesudah dan penyelesaian tersimpan; audit lama tidak boleh diubah', async () => {
    const after = 'laporan/pelapor/utama/sesudah/teknisi/foto';
    await status(await upload(after, 'teknisi'), 200);
    const palsu = structuredClone(d);
    palsu.riwayat[0].catatan = 'Riwayat dipalsukan';
    await status(await perubahan(palsu, 'utama', 'teknisi', 'selesai'), 403);
    await status(await perubahan(d, 'utama', 'teknisi', 'selesai', { fotoSesudahPaths: [after] }), 200);
  });
  await t.test('berkas yang direferensikan tidak boleh dihapus atau dibaca pihak lain', async () => {
    const file = `http://${storage}/v0/b/${project}.appspot.com/o/${encodeURIComponent(path)}`;
    await status(await fetch(`${file}?alt=media`, { headers: { Authorization: `Bearer ${token('lain')}` } }), 403);
    await status(await fetch(`${file}?alt=media`, { headers: { Authorization: `Bearer ${token('pelapor')}` } }), 200);
    await status(await fetch(file, { method: 'DELETE', headers: { Authorization: `Bearer ${token('pelapor')}` } }), 403);
  });
  await t.test('laporan final tidak boleh diubah atau ditimpa revisi lama', async () => {
    const palsu = structuredClone(d);
    await status(await perubahan(palsu, 'utama', 'admin', 'menunggu'), 403);
    await status(await write('laporan/utama', d, 'teknisi', ['updatedAt']), 403);
  });
});
