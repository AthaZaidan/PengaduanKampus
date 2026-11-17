import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/laporan_repository.dart';

class KelolaLokasiPage extends StatefulWidget {
  const KelolaLokasiPage({super.key});
  @override
  State<KelolaLokasiPage> createState() => _KelolaLokasiPageState();
}

class _KelolaLokasiPageState extends State<KelolaLokasiPage> {
  final _nama = TextEditingController();
  late final _lokasi = FirebaseFirestore.instance.collection('lokasi');
  late final _stream = _lokasi.orderBy('nama').snapshots();
  bool _sibuk = false;
  String? _galat;
  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _tambah() async {
    final nama = _nama.text.trim();
    if (_sibuk || nama.isEmpty || nama.length > 200) return;
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await _lokasi.add({
        'nama': nama,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nama.clear();
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalatFirebase(e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lokasi kampus')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Daftarkan lokasi yang benar-benar tersedia. Sertakan gedung, lantai, dan ruang agar pelaporan konsisten.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nama,
          maxLength: 200,
          enabled: !_sibuk,
          decoration: const InputDecoration(
            labelText: 'Nama lokasi',
            hintText: 'Gedung — lantai — ruang',
          ),
        ),
        FilledButton(
          onPressed: _sibuk ? null : _tambah,
          child: Text(_sibuk ? 'Menyimpan…' : 'Tambah lokasi'),
        ),
        if (_galat != null)
          Text(
            _galat!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Text('Daftar lokasi belum dapat dimuat.');
            }
            if (!snap.hasData) return const LinearProgressIndicator();
            if (snap.data!.docs.isEmpty) {
              return const Text(
                'Belum ada lokasi. Pelapor tetap dapat mengetik lokasi secara manual.',
              );
            }
            return Column(
              children: [
                for (final doc in snap.data!.docs)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(doc.data()['nama'] as String),
                      trailing: IconButton(
                        tooltip: 'Hapus lokasi dari pilihan',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final yakin = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus pilihan lokasi?'),
                              content: const Text(
                                'Lokasi pada laporan yang sudah dikirim tetap tersimpan.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (yakin != true) return;
                          try {
                            await doc.reference.delete();
                          } catch (e) {
                            if (mounted) {
                              setState(() => _galat = pesanGalatFirebase(e));
                            }
                          }
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
