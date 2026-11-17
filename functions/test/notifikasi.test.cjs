const { test } = require('node:test');
const assert = require('node:assert/strict');
const { penerima, pesan } = require('../notifikasi.cjs');
test('penerima unik, tanpa pelaku dan id kosong', () => {
  assert.deepEqual(penerima({ pelaporId: 'u', teknisiId: 't' }, ['a', 'a', null], 't'), ['a', 'u']);
});
test('payload push tidak membocorkan judul atau isi laporan', () => {
  const p = pesan('id', 'event');
  assert.equal(p.data.laporanId, 'id');
  assert.equal(p.android.notification.tag, 'event');
  assert.equal(p.notification.title, 'Pengaduan Kampus');
  assert.equal(pesan('id', 'event', true).notification.body.includes('klarifikasi'), true);
});
