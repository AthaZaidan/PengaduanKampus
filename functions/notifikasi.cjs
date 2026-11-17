function penerima(laporan, adminIds, actor) {
  return [...new Set([...adminIds, laporan.pelaporId, laporan.teknisiId])]
    .filter(uid => typeof uid === 'string' && uid.length > 0 && uid !== actor);
}
function pesan(laporanId, eventId, komentar = false) {
  return {
    notification: { title: 'Pengaduan Kampus', body: komentar
      ? 'Ada pesan klarifikasi baru. Buka aplikasi untuk melihatnya.'
      : 'Ada pembaruan laporan. Buka aplikasi untuk melihat perkembangannya.' },
    data: { laporanId, eventId },
    android: { notification: { tag: eventId, channelId: 'laporan_kampus' }, priority: 'high', collapseKey: laporanId },
    apns: { headers: { 'apns-collapse-id': laporanId } },
  };
}
module.exports = { penerima, pesan };
