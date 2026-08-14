import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_data_table.dart';

const _statusFilters = [
  (null, 'Toutes'),
  ('en_attente', 'En attente'),
  ('publiee', 'Publiées'),
  ('rejetee', 'Rejetées'),
  ('louee', 'Louées'),
  ('expiree', 'Expirées'),
];

const _statusLabels = {
  'en_attente': 'En attente',
  'publiee': 'Publiée',
  'rejetee': 'Rejetée',
  'louee': 'Louée',
  'expiree': 'Expirée',
};

(Color, Color) _statusColors(String status) => switch (status) {
  'publiee' => (AppColors.greenLight, AppColors.greenDark),
  'en_attente' => (AppColors.amberLight, AppColors.amber),
  'rejetee' => (AppColors.dangerLight, AppColors.danger),
  _ => (AppColors.line, AppColors.sub),
};

/// Onglet Annonces — modération complète : recherche, tri, filtre par
/// statut et pagination sur l'ensemble des annonces de la plateforme.
class AdminListingsTab extends StatefulWidget {
  final String? initialStatus;

  const AdminListingsTab({super.key, this.initialStatus});

  @override
  State<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends State<AdminListingsTab> {
  final _repository = AdminRepository(ApiClient());
  late String? _status = widget.initialStatus;
  String? _search;
  String _ordering = '-created_at';
  int _page = 1;
  bool _loading = true;
  AdminPage<AdminListing> _result = const AdminPage(items: [], count: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.listingsPage(
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

  void _setOrdering(String key) {
    setState(() {
      _ordering = _ordering == key ? '-$key' : key;
      _page = 1;
    });
    _load();
  }

  Future<void> _decide(int id, bool approve) async {
    if (approve) {
      await _repository.approveListing(id);
    } else {
      await _repository.rejectListing(id);
    }
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
            'Annonces',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Modération et gestion de toutes les annonces de la plateforme',
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 22),
          BcDataTable<AdminListing>(
            title: 'Annonces (${_result.count})',
            loading: _loading,
            emptyLabel: 'Aucune annonce pour ce filtre.',
            searchHint: 'Titre, quartier, annonceur…',
            onSearchChanged: _setSearch,
            sortKey: _ordering.replaceFirst('-', ''),
            sortAscending: !_ordering.startsWith('-'),
            onSortChanged: _setOrdering,
            filters: [
              for (final f in _statusFilters)
                BcChip(
                  label: f.$2,
                  selected: _status == f.$1,
                  onTap: () => _setStatus(f.$1),
                ),
            ],
            columns: const [
              BcColumn('Annonce', flex: 3, sortKey: 'title'),
              BcColumn('Annonceur', flex: 2),
              BcColumn('Quartier', flex: 2),
              BcColumn('Loyer', flex: 1, sortKey: 'rent_amount'),
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
            cellsBuilder: (listing) {
              final (bg, fg) = _statusColors(listing.status);
              return [
                Text(listing.title, overflow: TextOverflow.ellipsis),
                Text(listing.ownerDisplay, overflow: TextOverflow.ellipsis),
                Text(listing.neighborhood, overflow: TextOverflow.ellipsis),
                Text('${listing.rentAmount} F'),
                BcPill(
                  label: _statusLabels[listing.status] ?? listing.status,
                  background: bg,
                  foreground: fg,
                ),
                listing.status == 'en_attente'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BcButton(
                            label: 'Valider',
                            icon: 'check',
                            expand: false,
                            onPressed: () => _decide(listing.id, true),
                          ),
                          const SizedBox(width: 8),
                          BcButton(
                            label: 'Rejeter',
                            icon: 'close',
                            expand: false,
                            variant: BcButtonVariant.ghost,
                            onPressed: () => _decide(listing.id, false),
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
