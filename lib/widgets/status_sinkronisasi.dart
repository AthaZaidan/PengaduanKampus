import 'package:flutter/material.dart';

import '../providers/laporan_provider.dart';

class StatusSinkronisasi extends StatelessWidget {
  final LaporanProvider provider;
  const StatusSinkronisasi({super.key, required this.provider});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final pesan = provider.menyimpan
          ? 'Menyimpan ke Firebase…'
          : provider.galat ??
                (provider.memuat
                    ? 'Memuat laporan…'
                    : provider.dariCache
                    ? 'Menampilkan data tersimpan di perangkat. Menunggu koneksi server.'
                    : null);
      if (pesan == null) return const SizedBox.shrink();
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (provider.menyimpan || provider.memuat)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.cloud_off_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pesan, style: const TextStyle(fontSize: 12)),
                ),
                if (provider.galat != null && !provider.menyimpan)
                  TextButton(
                    onPressed: provider.cobaLagi,
                    child: const Text('Muat ulang'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
