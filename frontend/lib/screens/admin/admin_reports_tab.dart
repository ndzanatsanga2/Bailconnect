import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_data_table.dart';

const _reasonLabels = {
  'fausse_annonce': 'Fausse annonce',
  'deja_loue': 'Déjà loué',
  'contenu_inapproprie': 'Contenu inapproprié',
  'autre': 'Autre',
};

const _statusFilters = [
  (null, 'Tous'),
  ('ouvert', 'Ouverts'),
  ('traite', 'Traités'),
  ('rejete', 'Rejetés'),
];

const _statusLabels = {
  'ouvert': 'Ouvert',
  'traite': 'Traité',
  'rejete': 'Rejeté',
};

(Color, Color) _statusColors(String status) => switch (status) {
  'ouvert' => (AppColors.amberLight, AppColors.amber),
  'traite' => (AppColors.greenLight, AppColors.greenDark),
  _ => (AppColors.line, AppColors.sub),
};

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _repository = AdminRepository(ApiClient());
  String? _status = 'ouvert';
  String? _search;
  final _ordering = '-created_at';
  int _page = 1;
  bool _loading = true;
  AdminPage<AdminReport> _result = const AdminPage(items: [], count: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.reportsPage(
      status: _status,
      search: _search,
      ordering: _ordering,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _setStatus(String? status) {
    setState(() {
      _status = status;
      _page = 1;
    });
    _load();
  }

  void _setSearch(String value) {
    setState(() {
      _search = value.isEmpty ? null : value;
      _page = 1;
    });
    _load();
  }

  Future<void> _resolve(int id, String status) async {
    await _repository.resolveReport(id, status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signalements',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Annonces signalées par les utilisateurs',
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 22),
          BcDataTable<AdminReport>(
            title: 'Signalements (${_result.count})',
            loading: _loading,
            emptyLabel: 'Aucun signalement pour ce filtre.',
            searchHint: 'Annonce, signalant…',
            onSearchChanged: _setSearch,
            filters: [
              for (final f in _statusFilters)
                BcChip(
                  label: f.$2,
                  selected: _status == f.$1,
                  onTap: () => _setStatus(f.$1),
                ),
            ],
            columns: const [
              BcColumn('Annonce', flex: 2),
              BcColumn('Motif', flex: 2),
              BcColumn('Signalé par', flex: 2),
              BcColumn('Statut', flex: 1),
              BcColumn('Actions', flex: 2),
            ],
            rows: _result.items,
            page: _page,
            pageCount: (_result.count / 10).ceil().clamp(1, 999999),
            totalCount: _result.count,
            onPageChanged: (page) {
              setState(() => _page = page);
              _load();
            },
            cellsBuilder: (report) {
              final (bg, fg) = _statusColors(report.status);
              return [
                Text(report.listingTitle, overflow: TextOverflow.ellipsis),
                Text(
                  _reasonLabels[report.reason] ?? report.reason,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  report.reporterIdentifier,
                  overflow: TextOverflow.ellipsis,
                ),
                BcPill(
                  label: _statusLabels[report.status] ?? report.status,
                  background: bg,
                  foreground: fg,
                ),
                report.status == 'ouvert'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BcButton(
                            label: 'Traité',
                            icon: 'check',
                            expand: false,
                            onPressed: () => _resolve(report.id, 'traite'),
                          ),
                          const SizedBox(width: 8),
                          BcButton(
                            label: 'Rejeter',
                            icon: 'close',
                            expand: false,
                            variant: BcButtonVariant.ghost,
                            onPressed: () => _resolve(report.id, 'rejete'),
                          ),
                        ],
                      )
                    : const Text('—', style: TextStyle(color: AppColors.sub)),
              ];
            },
          ),
        ],
      ),
    );
  }
}
