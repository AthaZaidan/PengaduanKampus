import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../models/filter_laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/komponen_kampus.dart';
import 'detail_laporan_page.dart';

/// Satu tab pada daftar laporan. [status] null berarti semua status.
class TabStatus {
  final String label;
  final Set<StatusLaporan>? status;
  final Color? warna;

  const TabStatus(this.label, {this.status, this.warna});

  List<Laporan> saring(List<Laporan> sumber) => status == null
      ? sumber
      : sumber.where((l) => status!.contains(l.status)).toList();
}

class RiwayatPage extends StatefulWidget {
  final LaporanProvider provider;
  final AppUser user;
  final String judul;
  final List<TabStatus> tabs;

  const RiwayatPage({
    super.key,
    required this.provider,
    required this.user,
    required this.tabs,
    this.judul = 'Daftar Laporan',
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  FilterLaporan _pilihan = const FilterLaporan();
  List<Laporan> _filter(List<Laporan> list) => _pilihan.terapkan(list, _query);

  Future<void> _aturFilter() async {
    var kategori = _pilihan.kategori;
    var prioritas = _pilihan.prioritas;
    var urutan = _pilihan.urutan;
    DateTimeRange? tanggal = _pilihan.mulai == null
        ? null
        : DateTimeRange(start: _pilihan.mulai!, end: _pilihan.sampai!);
    final hasil = await showModalBottomSheet<FilterLaporan>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ubah) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filter laporan',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: kategori?.name ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua kategori'),
                    ),
                    for (final k in KategoriKerusakan.values)
                      DropdownMenuItem(value: k.name, child: Text(k.label)),
                  ],
                  onChanged: (v) => ubah(
                    () => kategori = v == ''
                        ? null
                        : KategoriKerusakan.values.byName(v!),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: prioritas?.name ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Prioritas'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua prioritas'),
                    ),
                    for (final p in PrioritasLaporan.values)
                      DropdownMenuItem(value: p.name, child: Text(p.label)),
                  ],
                  onChanged: (v) => ubah(
                    () => prioritas = v == ''
                        ? null
                        : PrioritasLaporan.values.byName(v!),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UrutanLaporan>(
                  initialValue: urutan,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Urutkan'),
                  items: const [
                    DropdownMenuItem(
                      value: UrutanLaporan.terbaru,
                      child: Text('Terbaru'),
                    ),
                    DropdownMenuItem(
                      value: UrutanLaporan.terlama,
                      child: Text('Terlama'),
                    ),
                    DropdownMenuItem(
                      value: UrutanLaporan.prioritas,
                      child: Text('Prioritas tertinggi'),
                    ),
                  ],
                  onChanged: (v) => ubah(() => urutan = v!),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    tanggal == null
                        ? 'Pilih rentang tanggal'
                        : '${tanggal!.start.toString().split(' ').first} - ${tanggal!.end.toString().split(' ').first}',
                  ),
                  onPressed: () async {
                    final t = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: tanggal,
                    );
                    if (t != null) ubah(() => tanggal = t);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    FilterLaporan(
                      kategori: kategori,
                      prioritas: prioritas,
                      urutan: urutan,
                      mulai: tanggal?.start,
                      sampai: tanggal?.end,
                    ),
                  ),
                  child: const Text('Terapkan'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, const FilterLaporan()),
                  child: const Text('Reset filter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (hasil != null && mounted) setState(() => _pilihan = hasil);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis setiap provider memanggil notifyListeners().
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sumber = widget.provider.untuk(widget.user);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        actions: [
          IconButton(
            tooltip: 'Filter laporan',
            icon: Icon(
              _pilihan.aktif ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: _aturFilter,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final t in widget.tabs)
              _buildTab(t.label, t.saring(sumber).length, t.warna),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari judul, lokasi, atau nomor',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_pilihan.aktif)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter tambahan aktif',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _pilihan = const FilterLaporan()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final t in widget.tabs)
                  _LaporanList(
                    list: _filter(t.saring(sumber)),
                    provider: widget.provider,
                    user: widget.user,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int count, [Color? color]) {
    final scheme = Theme.of(context).colorScheme;
    return Tab(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color != null
                  ? color.withValues(alpha: 0.25)
                  : scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color ?? scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaporanList extends StatelessWidget {
  final List<Laporan> list;
  final LaporanProvider provider;
  final AppUser user;

  const _LaporanList({
    required this.list,
    required this.provider,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: KeadaanKosong(
            judul: 'Tidak ada laporan',
            keterangan: 'Belum ada laporan pada daftar ini. Coba tab lain atau sesuaikan pencarian.',
            ikon: Icons.folder_open_outlined,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final laporan = list[index];
        return KartuLaporan(
          laporan: laporan,
          tampilkanInternal: !user.peran.isPelapor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailLaporanPage(
                laporan: laporan,
                provider: provider,
                user: user,
              ),
            ),
          ),
        );
      },
    );
  }
}
