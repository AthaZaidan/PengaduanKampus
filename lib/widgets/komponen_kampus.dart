import 'package:flutter/material.dart';

import '../models/laporan.dart';
import 'sla_chip.dart';

class JudulBagian extends StatelessWidget {
  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;
  const JudulBagian(this.judul, {super.key, this.aksi, this.onAksi});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(judul, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (aksi != null) TextButton(onPressed: onAksi, child: Text(aksi!)),
    ],
  );
}

class RingkasanAngka extends StatelessWidget {
  final String label;
  final int angka;
  final IconData ikon;
  final Color warna;
  const RingkasanAngka({
    super.key,
    required this.label,
    required this.angka,
    required this.ikon,
    required this.warna,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 21, color: warna),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('$angka', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final StatusLaporan status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: status.color,
      ),
    ),
  );
}

class KeadaanKosong extends StatelessWidget {
  final String judul;
  final String keterangan;
  final IconData ikon;
  const KeadaanKosong({
    super.key,
    required this.judul,
    required this.keterangan,
    this.ikon = Icons.inbox_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            ikon,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          judul,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          keterangan,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class KartuLaporan extends StatelessWidget {
  final Laporan laporan;
  final VoidCallback onTap;
  final bool tampilkanInternal;
  const KartuLaporan({
    super.key,
    required this.laporan,
    required this.onTap,
    this.tampilkanInternal = false,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    laporan.kategori.icon,
                    size: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                  Text(
                    laporan.kategori.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  StatusBadge(laporan.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                laporan.judul,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      laporan.lokasi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${laporan.tanggalLapor.day}/${laporan.tanggalLapor.month}/${laporan.tanggalLapor.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Prioritas ${laporan.prioritas.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: laporan.prioritas.color,
                    ),
                  ),
                  if (laporan.kodeAset != null && laporan.kodeAset!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 14,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          laporan.kodeAset!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  if (laporan.jumlahFoto > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${laporan.jumlahFoto}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                laporan.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (laporan.status == StatusLaporan.selesai)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    laporan.dikonfirmasi
                        ? 'Hasil dikonfirmasi pelapor'
                        : 'Menunggu konfirmasi pelapor',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (tampilkanInternal) ...[
                const Divider(height: 24),
                if (laporan.teknisiNama != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Teknisi: ${laporan.teknisiNama}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SlaChip(laporan: laporan),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
