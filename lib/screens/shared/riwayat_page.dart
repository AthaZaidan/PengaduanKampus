import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
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

  List<Laporan> _filter(List<Laporan> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((l) {
      return l.judul.toLowerCase().contains(q) ||
          l.lokasi.toLowerCase().contains(q) ||
          l.id.toLowerCase().contains(q);
    }).toList();
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
