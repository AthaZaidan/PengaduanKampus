import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PilihanLokasi extends StatefulWidget {
  final ValueChanged<String> onPilih;
  const PilihanLokasi({super.key, required this.onPilih});
  @override
  State<PilihanLokasi> createState() => _PilihanLokasiState();
}

class _PilihanLokasiState extends State<PilihanLokasi> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _buatStream();

  Stream<QuerySnapshot<Map<String, dynamic>>> _buatStream() {
    try {
      return FirebaseFirestore.instance
          .collection('lokasi')
          .orderBy('nama')
          .limit(200)
          .snapshots();
    } catch (_) {
      // Aman saat dijalankan di widget test tanpa inisialisasi Firebase.
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih lokasi terdaftar (opsional)',
              ),
              items: [
                for (final d in snap.data!.docs)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      d.data()['nama'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) {
                  widget.onPilih(
                    snap.data!.docs.firstWhere((d) => d.id == id).data()['nama']
                        as String,
                  );
                }
              },
            ),
          );
        },
      );
}
