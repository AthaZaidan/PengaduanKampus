import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/laporan.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
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
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final sumber = widget.provider.untuk(widget.user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.judul,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan judul, lokasi, atau ID...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.sageGreen,
                  size: 22,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
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
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.forestGreen,
                    width: 1.5,
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color != null
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softSage.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  size: 44,
                  color: AppColors.sageGreen,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tidak Ada Laporan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepForest,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Belum ada laporan yang sesuai dengan kategori ini.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softSage.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  laporan.kategori.icon,
                  size: 22,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.deepForest,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            laporan.lokasi,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          laporan.id,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Prioritas: dot indicator + label teks (tanpa pill latar)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: laporan.prioritas.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          laporan.prioritas.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: laporan.prioritas.color,
                          ),
                        ),
                        if (laporan.foto.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${laporan.foto.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
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
                                const Icon(
                                  Icons.engineering_outlined,
                                  size: 13,
                                  color: AppColors.sageGreen,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  laporan.teknisiNama!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepForest,
                                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: laporan.status.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: laporan.status.color.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          laporan.status.icon,
                          size: 11,
                          color: laporan.status.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          laporan.status.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: laporan.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
