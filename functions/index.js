const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { penerima, pesan } = require('./notifikasi.cjs');
initializeApp();
const db = getFirestore();
const opsi = { region: 'asia-southeast2', maxInstances: 3 };

async function kirim(laporanId, laporan, actor, eventId, komentar = false) {
  const admins = await db.collection('users').where('role', 'in', ['admin', 'admin_fasilitas', 'admin fasilitas']).get();
  const recipients = penerima(laporan, admins.docs.map(d => d.id), actor);
  const devices = [];
  for (const uid of recipients) {
    const akun = await db.doc(`users/${uid}`).get();
    const role = akun.data()?.role;
    const berhak = ['admin', 'admin_fasilitas', 'admin fasilitas'].includes(role) ||
      uid === laporan.pelaporId || (uid === laporan.teknisiId && role === 'teknisi');
    if (!berhak) continue;
    if (komentar) await db.doc('users/' + uid + '/pesan_masuk/' + eventId).set({
      laporanId, waktu: FieldValue.serverTimestamp(), jenis: 'komentar',
    });
    const snap = await db.collection(`users/${uid}/devices`).orderBy('updatedAt', 'desc').limit(20).get();
    for (const d of snap.docs) {
      const data = d.data();
      if (typeof data.token === 'string' && data.updatedAt?.toMillis() > Date.now() - 60 * 86400000) devices.push(d);
    }
  }
  const unik = [...new Map(devices.map(d => [d.data().token, d])).values()];
  for (let i = 0; i < unik.length; i += 500) {
    const grup = unik.slice(i, i + 500);
    const hasil = await getMessaging().sendEachForMulticast({ tokens: grup.map(d => d.data().token), ...pesan(laporanId, eventId, komentar) });
    await Promise.all(hasil.responses.map(async (r, j) => {
      if (['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(r.error?.code)) await grup[j].ref.delete();
    }));
  }
}

exports.perubahanLaporan = onDocumentWritten({ ...opsi, document: 'laporan/{id}' }, async event => {
  const sesudah = event.data?.after;
  if (!sesudah?.exists) return;
  const laporan = sesudah.data();
  const sebelum = event.data.before.data();
  if (sebelum && sebelum.riwayat?.length === laporan.riwayat?.length) return;
  await kirim(event.params.id, laporan, laporan.updatedBy, `${event.params.id}_${laporan.riwayat.length - 1}`);
});
exports.komentarLaporan = onDocumentCreated({ ...opsi, document: 'laporan/{id}/komentar/{komentarId}' }, async event => {
  const laporan = await db.doc(`laporan/${event.params.id}`).get();
  if (!laporan.exists) return;
  await kirim(event.params.id, laporan.data(), event.data.data().uid, event.id, true);
});
