import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/sla_chip.dart';
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
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
                hintText: 'Cari laporan...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                  : Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada laporan',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final laporan = list[index];
        return _RiwayatCard(
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

class _RiwayatCard extends StatelessWidget {
  final Laporan laporan;
  final VoidCallback onTap;

  /// Admin / teknisi: tampilkan teknisi dan SLA.
  final bool tampilkanInternal;

  const _RiwayatCard({
    required this.laporan,
    required this.onTap,
    this.tampilkanInternal = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(laporan.kategori.icon,
                    size: 22, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            laporan.lokasi,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          laporan.id,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: laporan.prioritas.color
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            laporan.prioritas.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: laporan.prioritas.color,
                            ),
                          ),
                        ),
                        if (laporan.foto.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.photo_camera_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            '${laporan.foto.length}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                    if (tampilkanInternal) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (laporan.teknisiNama != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.engineering_outlined,
                                    size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(
                                  laporan.teknisiNama!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          SlaChip(laporan: laporan),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: laporan.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(laporan.status.icon,
                            size: 11, color: laporan.status.color),
                        const SizedBox(width: 3),
                        Text(
                          laporan.status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: laporan.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
